package VCP::Utils::cvs ;

=head1 NAME

VCP::Utils::cvs - utilities for dealing with the cvs command

=head1 SYNOPSIS

   use VCP::Utils::cvs ;

=head1 DESCRIPTION

A mix-in class providing methods shared by VCP::Source::cvs and VCP::Dest::cvs,
mostly wrappers for calling the cvs command.

=for test_scripts t/90revml2cvs.t t/91cvs2revml.t

=cut

@EXPORT_OK = qw( RCS_check_tag RCS_underscorify_tag );
@ISA = qw( Exporter );
use Exporter;

use strict ;

use Carp ;
use VCP::Debug qw( :debug :profile ) ;
use VCP::Utils qw( empty start_dir );
use File::Spec ;
use File::Temp qw( mktemp ) ;
use POSIX ":sys_wait_h" ;

=head1 METHODS

=over

=item cvs

Calls the cvs command with the appropriate cvsroot option.

=cut

sub cvs {
   my $self = shift ;

   my $cvs_command = "";
   if ( profiling ) {
      profile_group ref( $self ) . " cvs ";
      for( @{$_[0]} ) {
         unless ( /^-/ ) {
            $cvs_command = $_;
            last;
         }
      }
   }
   local $VCP::Debug::profile_category = ref( $self ) . " cvs $cvs_command"
      if profiling;


   my @args = @{shift()} ;

   unshift @args, "-d" . $self->cvsroot
      if defined $self->repo_server;

   return $self->run_safely( [ qw( cvs -Q -z9 ), @args ], @_ ) ;
}

=item parse_cvs_repo_spec

This handles ":pserver:"-like type repository specs specially, defaulting to
normal processing if the scheme is not followed by something like "foo".  The
username and password are parsed out of the spec

If the first colon is followed by a colon, like

   cvs::pserver:user@server/foo:bar

, then the special processing kicks in and the spec is parsed accordingly.
Everything up to and including the first colon and starting with the last colon
are stripped, just like with L<normal specs|VCP::Plugin/parse_repo_spec>, and
the remainder becomes the CVSROOT.  This does have the side effect of
plaintexting the password in various CVS places (like the local CVS directories
and the command lines that VCP forks to launch CVS).  Let me know if you need
this changed.

=cut

sub parse_cvs_repo_spec {
   my $self = shift;

   my ( $spec ) = @_;

   unless ( $spec =~ /\A\w+::/ ) {
      $self->parse_repo_spec( @_ ) unless $spec =~ /\A\w+::/;
   }
   else {
      my ( $scheme, $cvs_root, $filespec ) = ( $spec =~ /\A([^:]*):(.*):([^:]*)\z/ )
         or die "Can't parse CVS remote file spec '$spec'\n";


      $self->repo_scheme( $scheme );
      $self->repo_server( $cvs_root );
      $self->repo_filespec( $filespec );
   }

   my $filespec = $self->repo_filespec;
   $filespec =~ s(/{2,})(/)g;
   $filespec =~ s(\\{2,})(\\)g;
   $self->repo_filespec( $filespec );

  debug "parsed '$spec' as",
      " scheme=", $self->repo_scheme,
      " server=", $self->repo_server,
      " filespec=", $self->repo_filespec
      if debugging;

   die "parse_cvs_repo_spec does not return a result" if defined wantarray;

   ## Set default repo_id.
   $self->repo_id( "cvs:" . $self->repo_server );
}

=item cvsroot

Returns the specced cvsroot if set, or $ENV{CVSROOT} if not.

While $ENV{CVSROOT} must be an absolute path if it's local (to be
completely consistent with the cvs command), the path repo_server value,
if set, may be relative (unless it begins with a ':', which indicates a
non-local path).

=cut

sub cvsroot {
   my VCP::Utils::cvs $self = shift;
   my $root = $self->repo_server;

   ( ! empty $root )
      ? substr( $root, 0, 1 ) eq ":"
         ? $root                         ## Remote repo
         : File::Spec->rel2abs( $root, start_dir )  ## local repo.
      : $ENV{CVSROOT};
}


=item create_cvs_workspace

    $self->create_cvs_workspace;
    $self->create_cvs_workspace( create_in_repository => 1 );

Creates a temp dir named "co" for C<cvs> to work in, checks out the module
there, and sets the work root and cvs working dir to that directory.

=cut

sub create_cvs_workspace {
   my $self = shift ;
   my %options = @_;

   confess "Can't create_workspace twice" if $self->revs->get ;

   ## establish_workspace in a directory named "co" for "checkout". This is
   ## so that VCP::Source::cvs can use a different directory to contain
   ## the revs, since all the revs need to be kept around until the VCP::Dest
   ## is through with them.
   $self->command_chdir( $self->tmp_dir( "co" ) ) ;
   my $module = $self->repo_filespec;
   die "Empty cvs module spec\n"
      if empty $module ;
   $module =~ s{[\\/]+[^\\/]*(?:\.\.\.|[*\\?[].*)}{};

   ## if the server contains a username we must log in
   if ( ( $self->repo_server || "" ) =~ /^:[^:]+:[^:]*(?::([^:]*))?\@/ ) {
       my $password = defined $1 ? $1 : "";
       $self->cvs( ["login"], \$password );
   }

   my @expect_cannot_find_module = (
      stderr_filter => qr/cvs checkout: cannot find module .*\n/,
      ok_result_codes => [0,1],
   );

   $self->cvs(
      [ "checkout", $module ],
      {
         $options{create_in_repository}
            ? @expect_cannot_find_module
            : (
               ok_result_codes => [0],  ## Shouldn't be needed, but Just In Case
            ),
      }
   ) ;

   if ( $self->command_result_code == 1 ) {
      my $empty_dir = $self->tmp_dir( "empty_dir" );
      $self->mkdir( $empty_dir );
      $self->cvs(
         [
            "import",
            "-m",
            "VCP destination directory creation",
            $module,
            "vcp",
            "start"
         ]
      );

      $self->cvs( [ "checkout", $module ] ) ;
   }

   $self->work_root( $self->tmp_dir( "co" ) ) ;
}


=item RCS_check_tag

    RCS_check_tag $tag1, ...;

Checks a list of tags for legality, die()s if it's not legal.  Named after the
corresponding routine in CVS's rcs.c source file.

No clue how this interacts with your locale.

=cut

sub RCS_check_tag {
   my @errors;
   for ( @_ ) {
      if ( /\A[^a-zA-Z]/ ) {
         push @errors, "RCS tag '$_' must start with a letter\n";
      }
      elsif ( /([[:^graph:]])/ ) {
         push @errors,
            sprintf "RCS tag '%s' must not contain \\0x%02x\n", $_, ord $1;
      }
      elsif ( /(["\$,.:;\@])/ ) {
         push @errors, "RCS tag '$_' must not contain '$1'\n"
      }
   }

   die @errors if @errors;
}


=item RCS_underscorify_tag

    @tags = RCS_check_tag $tag1, ...;

Modifies a list of tags, replacing illegal characters with
underscores.  This may lead to tag collisions, but it should be ok
for most uses.

Converts something like "a@" to "a_AF_".  Not a guaranteed solution,
but good enough for now.

=cut

sub RCS_underscorify_tag {
   my @out = @_;
   for ( @out ) {
      s/(["\$,.:;\@[:^graph:]])/sprintf( "_%02x_", ord $1 )/ge;
      s/\A([^a-zA-Z])/tag_$1/;
   }

   wantarray ? @out : @out > 1 ? Carp::confess "Returning multiple tags in scalar context" : $out[0];
}


=back

=head1 COPYRIGHT

Copyright 2000, Perforce Software, Inc.  All Rights Reserved.

This module and the VCP package are licensed according to the terms given in
the file LICENSE accompanying this distribution, a copy of which is included in
L<vcp>.

=cut

1 ;

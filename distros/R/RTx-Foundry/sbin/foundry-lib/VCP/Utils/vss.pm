package VCP::Utils::vss ;

=head1 NAME

VCP::Utils::vss - utilities for dealing with the vss command

=head1 SYNOPSIS

   use VCP::Utils::vss ;

=head1 DESCRIPTION

A mix-in class providing methods shared by VCP::Source::vss and VCP::Dest::vss,
mostly wrappers for calling the vss command.

=cut

use strict ;

use Carp ;
use VCP::Debug qw( :debug ) ;
use VCP::Utils qw( empty ) ;
use File::Spec ;
use File::Temp qw( mktemp ) ;
use POSIX ':sys_wait_h' ;
use Regexp::Shellish qw( compile_shellish );

=head1 METHODS

=item ss

Calls the vss command with the appropriate vssroot option.

TODO: See if we can use two different users to do vss->vss.  Not sure if VSS
sets the cp and workfold per machine or per user.

=cut

sub ss {
   my $self = shift ;

   my $args = shift ;

   my $user = $self->repo_user;
   my @Y_arg;
   push @Y_arg, "-Y$user" unless empty $user;

   local $ENV{SSPWD} = $self->repo_password if defined $self->repo_password;

   my @I_arg;

   push @I_arg, "-I-" unless grep /^-I/, @$args;

   $self->run_safely(
      [ qw( ss ), @$args, @Y_arg, @I_arg ], @_
   ) ;

   return;
}


=item parse_vss_repo_spec

parse repo_spec by calling parse_repo_spec, then
set the repo_id.

=cut

sub parse_vss_repo_spec {
   my $self = shift ;
   my ( $spec ) = @_ ;

   $self->parse_repo_spec( $spec ) ;

   $self->repo_id( "vss:" . $self->repo_server );
};



=item create_vss_workspace

Creates a temporary directory.

=cut

sub create_vss_workspace {
   my $self = shift ;

   confess "Can't create_workspace twice" unless $self->none_seen ;

   ## establish_workspace in a directory named "co" for "checkout". This is
   ## so that VCP::Source::vss can use a different directory to contain
   ## the revs, since all the revs need to be kept around until the VCP::Dest
   ## is through with them.
   my $workspace = $self->tmp_dir;

   $self->mkdir( $workspace );
}


=item get_vss_file_list

Retrieves a list of all files and directories under a particular
path.  We need this so we can tell what dirs and files need to be added.

=cut

sub _scan_for_files {
   my $self = shift;
   my ( $path, $type, $filelist ) = @_;

   $path = $self->repo_filespec
      unless defined $path;
   $path =~ s{^\$[\\/]}{};

   my $path_re = compile_shellish( $path );

   debug "file scan re: $path_re" if debugging ;
   my $cur_project;
   for ( @$filelist ) {
      if ( /^(|No items found.*|\d+ item.*s.*)$/i ) {
         undef $cur_project;
         next;
      }

      if ( m{^\$/(.*):} ) {
         $cur_project = $1;
         ## Catch all project entries, because we may be importing
         ## to a non-existant project inside a project that exists.
         if ( length $cur_project ) {
            ## Add a slash so a preexisting dest project is found.
#            if ( "$cur_project/" =~ $path_re ) {
               my $p = $cur_project;
#               ## Catch all parent projects.  This prevents us from
#               ## creating more than need be.
#               do {
                  $self->{VSS_FILES}->{$p} = "project";
#               } while $p =~ s{/[^/]*}{} && length $p;
#            }
            $cur_project .= "/";
         }
         next;
      }

      if ( m{^\$(.*)} ) {
         confess "undefined \$cur_project" unless defined $cur_project;
         ## A subproject.  note here for the fun of it; it should also
         ## occur later in a $/foo: section of it's own.
         my $pjt = "$cur_project$1";
         $self->{VSS_FILES}->{$pjt} = "project"
             if $pjt =~ $path_re;
         next;
      }

      if ( "$cur_project$_" =~ $path_re ) {
         if ( defined $self->{VSS_FILES}->{"$cur_project$_"} ) {
            $self->{VSS_FILES}->{"$cur_project$_"} .= ", $type";
         }
         else {
            $self->{VSS_FILES}->{"$cur_project$_"} = $type;
         }
         next;
      }
   }

}

sub get_vss_file_list {
   my $self = shift;
   my ( $path ) = @_;

   ## Sigh.  I tried passing in $path to the Dir -D command and
   ## ss.exe whines because $path is rarely a deleted path RATHER
   ## THAN JUST GIVING ME ALL DELETED FILES UNDER $path!!!
   ## So, we get all the output and filter it for $path/... ourselves.
   ## This does have the advantage that we can use full wildcards in
   ## $path.

   $self->{VSS_FILES} = {};

   my $ignored_stdout;
   $self->ss( [ "cp", "\$/" ], \$ignored_stdout );

   $self->_scan_for_files( $path, "file",
      [ do {
         my $filelist;
         $self->ss( [qw( Dir -R )], ">", \$filelist );
         map { chomp; $_ } split /^/m, $filelist;
      } ]
   );

   $self->_scan_for_files( $path, "deleted file",
      [ do {
         my $filelist;
         $self->ss( [qw( Dir -R -D)], ">", \$filelist );
         map { chomp; $_ } split /^/m, $filelist;
      } ]
   );
   if ( debugging ) {
      require Data::Dumper;
      debug Data::Dumper::Dumper( $self->{VSS_FILES} );
   }
}

=item vss_files

    @files = $self->vss_files;

returns a list of all files (not projects) that get_vss_file_list()
loaded.

=cut

sub vss_files {
   my $self = shift;

   ## TODO: allow a pattern.  This would let us handle filespecs like
   ## /a*/b*
   grep index( $self->{VSS_FILES}->{$_}, "project" ) < 0,
      keys %{$self->{VSS_FILES}};
}

=item vss_file

    $self->vss_file( $path );
    $self->vss_file( $path, undef );      ## To mark as non-existant
    $self->vss_file( $path, 1 );          ## To mark as existant
    $self->vss_file( $path, "project" );  ## To mark as being a project

Accepts an absolute path with or without the leading C<$/> or C</> and
returns TRUE if it exists in CVS.

=cut

sub vss_file {
   my $self = shift;
   my ( $path, $value ) = @_;

   confess unless defined $path;

   $self->get_vss_file_list unless $self->{VSS_FILES};

   for ( $path ) {
      s{\\}{/}g;
      s{\/+$}{};
      s{\$+}{}g;
      s{^/+}{};
   }

   if ( @_ > 1 ) {
      $self->{VSS_FILES}->{$path} = $value;
      if ( $value ) {
         my $p = $path;
         while () {
            $p =~ s{(^|/)+[^/]+$}{};
            last unless length $p || $self->{VSS_FILES}->{$p};
            $self->{VSS_FILES}->{$p} = "project";
         }
      }
   }

   return exists $self->{VSS_FILES}->{$path} && $self->{VSS_FILES}->{$path};
}

=item vss_file_is_deleted

Returns 1 if the file is a deleted file.

NOTE: in VSS a file may be deleted and not deleted at the same time!
Thanks to Dave Foglesong for pointing this out.

=cut

sub vss_file_is_deleted {
    return 0 <= index shift->vss_file( @_ ), "deleted";
}

=item vss_file_is_active

Returns 1 if the file is an active (undeleted) file.

NOTE: in VSS a file may be deleted and active at the same time!
Thanks to Dave Foglesong for pointing this out.

=cut

sub vss_file_is_active {
    return shift->vss_file( @_ ) =~ /(^|, )file/;
}

=head1 COPYRIGHT

Copyright 2000, Perforce Software, Inc.  All Rights Reserved.

This module and the VCP package are licensed according to the terms given in
the file LICENSE accompanying this distribution, a copy of which is included in
L<vcp>.

=cut

1 ;

1;

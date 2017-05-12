package VCP::Source ;

=head1 NAME

VCP::Source - A base class for repository sources

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 EXTERNAL METHODS

=over

=cut

use strict ;

use Carp ;
use UNIVERSAL qw( isa ) ;
use VCP::Debug qw( :debug ) ;
use VCP::Logger qw( lg );

use vars qw( $VERSION ) ;

$VERSION = 0.1 ;

use base 'VCP::Plugin' ;

use fields (
   'BOOTSTRAP_REGEXPS', ## Determines what files are in bootstrap mode.
   'DEST',
   'CONTINUE',          ## Set if we're resuming from the prior
                        ## copy operation, if there is one.  This causes
                        ## us to determine a minimum rev by asking the
                        ## destination what it's seen on a given filebranch
) ;


=item new

Creates an instance, see subclasses for options.  The options passed are
usually native command-line options for the underlying repository's
client.  These are usually parsed and, perhaps, checked for validity
by calling the underlying command line.

=back

=cut

sub new {
   my $class = shift ;
   $class = ref $class || $class ;

   my VCP::Source $self = $class->SUPER::new( @_ ) ;

   $self->{BOOTSTRAP_REGEXPS} = [] ;

   return $self ;
}


###############################################################################

=head1 SUBCLASSING

This class uses the fields pragma, so you'll need to use base and 
possibly fields in any subclasses.  See L<VCP::Plugin> for methods
often needed in subclasses.

=head2 Subclass utility API

=over

=item parse_options

    $self->parse_options( \@options, @specs );

Parses common options including whatever options VCP::Plugin parses,
--bootstrap, and --rev-root.

=cut

sub parse_options {
   my VCP::Source $self = shift;
   $self->SUPER::parse_options( @_,
      "b|bootstrap=s"    => sub { $self->bootstrap( $_[1] ) },
      "continue"         => \$self->{CONTINUE},
      "rev-root"         => sub { $self->rev_root( $_[1] ) },
   );
}

=item dest

Sets/Gets a reference to the VCP::Dest object.  The source uses this to
call handle_header(), handle_rev(), and handle_end() methods.

=cut

sub dest {
   my VCP::Source $self = shift ;

   $self->{DEST} = shift if @_ ;
   return $self->{DEST} ;
}


=item continue

Sets/Gets the CONTINUE field (which the user sets via the --continue flag)

=cut

sub continue {
   my VCP::Source $self = shift ;

   $self->{CONTINUE} = shift if @_ ;
   return $self->{CONTINUE} ;
}



=back

=head1 SUBCLASS OVERLOADS

These methods should be overridded in any subclasses.

=over

=item copy

REQUIRED OVERLOAD.

   $source->copy_revs() ;

Called by L<VCP/copy> to do the entire export process.  This is passed a
partially filled-in header structure.

The subclass should call this to move all the revisions over to the
destination:

   $self->SUPER::copy_revs( $revs );

If $revs, an ARRAY containing revisions, is not passed in,
$self->revs->remove_all() is used.

=cut

sub copy_revs {
   my VCP::Source $self = shift ;
   my ( $revs ) = @_;
   $revs ||= $self->revs->remove_all;
   VCP::Revs->set_file_fetcher( $self );
   for my $i ( 0..$#$revs ) {
      $self->dest->handle_rev( $revs->[$i] );
      $revs->[$i] = undef;
   }
}


=item fetch_files

Calls get_rev( $r ) for each parameter.

Overload this if you can batch requests more efficiently.

=cut

sub fetch_files {
   my VCP::Source $self = shift ;
   map $self->get_rev( $_ ), @_;
}


=item handle_header

REQUIRED OVERLOAD.

Subclasses must add all repository-specific info to the $header, at least
including rep_type and rep_desc.

   $header->{rep_type} => 'p4',
   $self->p4( ['info'], \$header->{rep_desc} ) ;

The subclass must pass the $header on to the dest:

   $self->dest->handle_header( $header ) ;

=cut

sub handle_header {
   my VCP::Source $self = shift ;

#   my ( $header ) = @_ ;

   confess "ERROR: copy not overloaded by class '", ref $self, "'.  Oops.\n";
#      if $self->can( 'handle_header' ) eq \&handle_header ;

#   $self->dest->handle_header( $header ) ;
}


=item handle_footer

Not a required overload, as the footer carries no useful information at
this time.  Overriding methods must call this method to pass the
$footer on:

   $self->SUPER::handle_footer( $footer ) ;

=cut

sub handle_footer {
   my VCP::Source $self = shift ;

   my ( $footer ) = @_ ;

   $self->dest->handle_footer( $footer ) ;
   VCP::Revs->set_file_fetcher( undef );
}


=item parse_time

   $time = $self->parse_time( $timestr ) ;

Parses "[cc]YY/MM/DD[ HH[:MM[:SS]]]".

Will add ability to use format strings in future.
HH, MM, and SS are assumed to be 0 if not present.

Returns a time suitable for feeding to localtime or gmtime.

Assumes local system time, so no good for parsing times in revml, but that's
not a common thing to need to do, so it's in VCP::Source::revml.pm.

=cut

{
    ## This routine is slow and gets called a *lot* with duplicate
    ## inputs, at least by VCP::Source::cvs, so we memoize it.
    my %cache;

    sub parse_time {
       my VCP::Source $self = shift ;
       my ( $timestr ) = @_ ;
       return $cache{$timestr} ||= do {
           ## TODO: Get parser context here & give file, line, and column. filename
           ## and rev, while we're scheduling more work for the future.
           confess "Malformed time value $timestr\n"
              unless $timestr =~ /^(\d\d)?\d?\d(\D\d?\d){2,5}/ ;
           my @f = split( /\D/, $timestr ) ;
           --$f[1] ; # Month of year needs to be 0..11
           push @f, ( 0 ) x ( 6 - @f ) ;
           require Time::Local;
           return Time::Local::timelocal( reverse @f ) ;
        }
    }
}


=item bootstrap

Usually called from within call to GetOptions in subclass' new():

   GetOptions(
      'bootstrap|b=s' => sub {
	 my ( $name, $val ) = @_ ;
	 $self->bootstrap( $val ) ;
      },
      'rev-root'      => \$rev_root,
      ) or $self->usage_and_exit ;

Can be called plain:

   $self->bootstrap( $bootstrap_spec ) ;

See the command line documentation for the format of $bootstrap_spec.

Returns nothing useful.

=cut

sub bootstrap {
   my VCP::Source $self = shift ;
   my ( $val ) = @_ ;
   require Regexp::Shellish;
   $self->{BOOTSTRAP_REGEXPS} = [
      map Regexp::Shellish::compile_shellish( $_ ), split /,+/, $val
   ];

   return ;
}


#=item bootstrap_regexps
#
#   $self->bootstrap_regexps( $re1, $re1, ... ) ;
#   $self->bootstrap_regexps( undef ) ; ## clears the list
#   @res = $self->bootstrap_regexps ;
#
#Sets/gets the list of regular expressions defining what files are in bootstrap
#mode.  This is usually set by L</bootstrap>, though.
#
#=cut
#
#sub bootstrap_regexps {
#   my VCP::Source $self = shift ;
#   $self->{BOOTSTRAP_REGEXPS} = [ @_ == 1 && ! defined $_[0] ? () : @_ ]
#      if @_ ;
#   return @{$self->{BOOTSTRAP_REGEXPS}} ;
#}
#
=item is_bootstrap_mode

   ... if $self->is_bootstrap_mode( $file ) ;

Compares the filename passed in against the list of bootstrap regular
expressions set by L</bootstrap>.

The file should be in a format similar to the command line spec for
whatever repository is passed in, and not relative to rev_root, so
"//depot/foo/bar" for p4, or "module/foo/bar" for cvs.

This is typically called in the subbase class only after looking at the
revision number to see if it is a first revision (in which case the
subclass should automatically put it in bootstrap mode).

=cut

sub is_bootstrap_mode {
   my VCP::Source $self = shift ;
   my ( $file ) = @_ ;

   my $result = grep $file =~ $_, @{$self->{BOOTSTRAP_REGEXPS}} ;

   lg(
      "$file ",
      ( $result ? "=~ " : "!~ " ),
      "[ ", join( ', ', map "qr/$_/", @{$self->{BOOTSTRAP_REGEXPS}} ), " ] (",
      ( $result ? "not in " : "in " ),
      "bootstrap mode)"
   ) if debugging;

   return $result ;
}

=back

=head1 COPYRIGHT

Copyright 2000, Perforce Software, Inc.  All Rights Reserved.

This module and the VCP package are licensed according to the terms given in
the file LICENSE accompanying this distribution, a copy of which is included in
L<vcp>.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut

1

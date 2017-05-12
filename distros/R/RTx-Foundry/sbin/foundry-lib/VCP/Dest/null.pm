package VCP::Dest::null;

=head1 NAME

VCP::Dest::null - null destination driver

=head1 SYNOPSIS

   vcp <source> null:
   vcp <source> null:

=head1 DESCRIPTION

Runs in metadata only mode (so the source need not do checkouts) and discards
even that.  Useful for testing.

=cut

$VERSION = 1 ;

use strict ;
use vars qw( $debug ) ;

$debug = 0 ;

use Carp ;
use File::Basename ;
use File::Path ;
use VCP::Debug ':debug' ;
use VCP::Rev ;

use base qw( VCP::Dest );

sub new {
   my $class = shift ;
   $class = ref $class || $class ;

   my $self = $class->SUPER::new( @_ ) ;

   ## Parse the options
   my ( $spec, $options ) = @_ ;

   $self->parse_options(
      $options,
      "NoFreakinOptionsAllowed" => \undef,
   );

   return $self ;
}


=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=head1 COPYRIGHT

Copyright (c) 2000, 2001, 2002 Perforce Software, Inc.
All rights reserved.

See L<VCP::License|VCP::License> (C<vcp help license>) for the terms of use.

=cut

1

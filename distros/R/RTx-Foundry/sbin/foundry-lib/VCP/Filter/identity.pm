package VCP::Filter::identity;

=head1 NAME

VCP::Filter::identity - identity (ie noop)

=head1 SYNOPSIS

   vcp <source> identity: <dest>

=head1 DESCRIPTION

A simple passthrough, used for testing to make sure that VCP::Filter
really is a pass through and that vcp can load filters.

=for test_script t/10vcp.t

=cut

$VERSION = 1 ;

use strict ;
use VCP::Filter;
use Getopt::Long;
use base qw( VCP::Filter );

sub new {
   my $class = shift ;
   $class = ref $class || $class ;

   my $self = $class->SUPER::new( @_ ) ;

   ## Parse the options
   my ( $spec, $options ) = @_ ;

   {
      local *ARGV = $options ;
      GetOptions(
         "NoFreakinOptionsAllowed" => \undef,
      )
	 or $self->usage_and_exit ;
   }

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

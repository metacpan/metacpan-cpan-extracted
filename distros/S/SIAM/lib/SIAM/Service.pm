package SIAM::Service;

use warnings;
use strict;

use base 'SIAM::Object';

use SIAM::ServiceUnit;

=head1 NAME

SIAM::Service - Service object class

=head1 SYNOPSIS

   my $svcunits = $service->get_service_units();

=head1 METHODS

=head2 get_service_units

Returns arrayref with SIAM::ServiceUnit objects

=cut

sub get_service_units
{
    my $self = shift;
    return $self->get_contained_objects('SIAM::ServiceUnit');
}


# mandatory attributes

my $mandatory_attributes =
    [ 'siam.svc.product_name',
      'siam.svc.type',
      'siam.svc.inventory_id' ];

sub _mandatory_attributes
{
    return $mandatory_attributes;
}

sub _manifest_attributes
{
    my $ret = [];
    push(@{$ret}, @{$mandatory_attributes},
         @{ SIAM::ServiceUnit->_manifest_attributes() });

    return $ret;

}


1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-continued-statement-offset: 4
# cperl-continued-brace-offset: -4
# cperl-brace-offset: 0
# cperl-label-offset: -2
# End:

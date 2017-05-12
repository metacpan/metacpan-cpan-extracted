package SIAM::Device;

use warnings;
use strict;

use base 'SIAM::Object';

use SIAM::DeviceComponent;

=head1 NAME

SIAM::Device - device object class

=head1 SYNOPSIS


=head1 METHODS

=head2 get_components

Returns arrayref with SIAM::DeviceComponent objects

=cut

sub get_components
{
    my $self = shift;
    return $self->get_contained_objects('SIAM::DeviceComponent');
}


# mandatory attributes

my $mandatory_attributes =
    [ 'siam.device.inventory_id',
      'siam.device.name'];

sub _mandatory_attributes
{
    return $mandatory_attributes;
}

sub _manifest_attributes
{
    my $ret = [];
    push(@{$ret}, @{$mandatory_attributes},
         @{ SIAM::DeviceComponent->_manifest_attributes() });
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

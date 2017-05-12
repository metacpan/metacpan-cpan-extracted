package SIAM::ServiceComponent;

use warnings;
use strict;

use base 'SIAM::Object';

=head1 NAME

SIAM::ServiceComponent - Service Component object class

=head1 SYNOPSIS

=head1 METHODS

=head2 get_device_component

    $devc = $svcc->get_device_component();

The method returns a SIAM::DeviceComponent object instantiated from
C<siam.svcc.devc_id> parameter.

=cut

sub get_device_component
{
    my $self = shift;
    
    if( $self->attr('siam.svcc.devc_id') eq 'NIL' ) {
        return undef;
    }
    
    return $self->instantiate_object
        ('SIAM::DeviceComponent', $self->attr('siam.svcc.devc_id'));
}
            
    
# mandatory attributes

my $mandatory_attributes =
    [ 'siam.svcc.name',
      'siam.svcc.type',
      'siam.svcc.inventory_id',
      'siam.svcc.devc_id' ];

sub _mandatory_attributes
{
    return $mandatory_attributes;
}


sub _manifest_attributes
{
    return $mandatory_attributes;
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

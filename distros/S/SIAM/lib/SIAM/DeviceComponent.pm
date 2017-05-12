package SIAM::DeviceComponent;

use warnings;
use strict;

use base 'SIAM::Object';


=head1 NAME

SIAM::DeviceComponent - Device Component object class

=head1 SYNOPSIS

=head1 METHODS

=head2 is_attached

Returns true if the device component is attached to another device
component within the same device.

=cut

sub is_attached
{
    my $self = shift;
    return( $self->attr('siam.devc.is_attached') ? 1:0 );
}


=head2 attached_to

Returns a SIAM::DeviceComponent object to which this object is attached.

=cut

sub attached_to
{
    my $self = shift;
    if( $self->is_attached() )
    {
        my $id = $self->attr('siam.devc.attached_to');
        if( not defined($id) )
        {
            $self->error('siam.devc.attached_to is undefined in ' . $self->id);
            return undef;
        }
        return $self->instantiate_object('SIAM::DeviceComponent', $id);
    }

    return;
}




    
# mandatory attributes

my $mandatory_attributes =
    [ 'siam.devc.inventory_id',
      'siam.devc.type',
      'siam.devc.name',
      'siam.devc.full_name',
      'siam.devc.description' ];

my $optional_attributes =
    [ 'siam.devc.is_attached',
      'siam.devc.attached_to' ];

sub _mandatory_attributes
{
    return $mandatory_attributes;
}


sub _manifest_attributes
{
    return [@{$mandatory_attributes}, @{$optional_attributes}];
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

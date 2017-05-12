package RT::Extension::QueueSLA;

our $VERSION = '0.01';


=head1 NAME

RT::Extension::QueueSLA - default SLA for Queue

=cut

use RT::Queue;
package RT::Queue;

use strict;
use warnings;


sub SLA {
    my $self = shift;
    my $value = shift;
    return undef unless $self->CurrentUserHasRight('SeeQueue');

    my $attr = $self->FirstAttribute('SLA') or return undef;
    return $attr->Content;
}

sub SetSLA {
    my $self = shift;
    my $value = shift;

    return ( 0, $self->loc('Permission Denied') )
        unless $self->CurrentUserHasRight('AdminQueue');

    my ($status, $msg) = $self->SetAttribute(
        Name        => 'SLA',
        Description => 'Default Queue SLA',
        Content     => $value,
    );
    return ($status, $msg) unless $status;
    return ($status, $self->loc("Queue's default service level has been changed"));
}

1;

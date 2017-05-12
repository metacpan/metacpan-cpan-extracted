
use strict;
use warnings;

package RT::Action::SLA;

use base qw(RT::Extension::SLA RT::Action);

=head1 NAME

RT::Action::SLA - base class for all actions in the extension

=head1 DESCRIPTION

It's not a real action, but container for subclassing which provide
help methods for other actions.

=head1 METHODS

=head2 SetDateField NAME VALUE

Sets specified ticket's date field to the value, doesn't update
if field is set already. VALUE is unix time.

=cut

sub SetDateField {
    my $self = shift;
    my ($type, $value) = (@_);

    my $ticket = $self->TicketObj;

    my $method = $type .'Obj';
    if ( defined $value ) {
        return 1 if $ticket->$method->Unix == $value;
    } else {
        return 1 if $ticket->$method->Unix <= 0;
    }

    my $date = RT::Date->new( $RT::SystemUser );
    $date->Set( Format => 'unix', Value => $value );

    $method = 'Set'. $type;
    return 1 if $ticket->$type eq $date->ISO;
    my ($status, $msg) = $ticket->$method( $date->ISO );
    unless ( $status ) {
        $RT::Logger->error("Couldn't set $type date: $msg");
        return 0;
    }

    return 1;
}

1;

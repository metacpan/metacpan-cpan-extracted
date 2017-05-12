package RT::Action::AutomaticAssignment;
use strict;
use warnings;
use base 'RT::Action';

# only tickets that are unassigned will be automatically assigned.
# RT::Action::AutomaticReassignment overrides this to remove this restriction
sub _PrepareOwner {
    my $self = shift;

    return $self->TicketObj->Owner == RT->Nobody->id;
}

sub Prepare {
    my $self = shift;

    return $self->_PrepareOwner;
}

sub Commit {
    my $self = shift;
    my $ticket = $self->TicketObj;

    my $owner = RT::Extension::AutomaticAssignment->OwnerForTicket($ticket);

    return 0 if !$owner;

    my ($ok, $msg) = $ticket->SetOwner($owner->id);
    return $ok;
}

1;


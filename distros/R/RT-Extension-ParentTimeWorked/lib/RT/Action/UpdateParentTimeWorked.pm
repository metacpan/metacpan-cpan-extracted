use strict;
use warnings;

package RT::Action::UpdateParentTimeWorked;
use base 'RT::Action';

sub Prepare {
    my $self = shift;
    my $ticket = $self->TicketObj;
    return 0 unless $ticket->MemberOf->Count;
    return 1;
}

sub Commit {
    my $self   = shift;
    my $ticket = $self->TicketObj;
    my $txn    = $self->TransactionObj;

    my $parents     = $ticket->MemberOf;
    my $time_worked = $txn->TimeTaken
      || ( $txn->NewValue - $txn->OldValue );

    while ( my $parent = $parents->Next ) {
        my $parent_ticket = $parent->TargetObj;
        my $original_actor = RT::CurrentUser->new( $txn->Creator );
        my $actor_parent_ticket = RT::Ticket->new( $original_actor );
        $actor_parent_ticket->Load( $parent_ticket->Id );
        unless ( $actor_parent_ticket->Id ) {
            RT->Logger->error("Unable to load ".$parent_ticket->Id." as ".$txn->Creator->Name);
            return 0;
        }
        my ( $ret, $msg ) = $actor_parent_ticket->_Set(
            Field   => 'TimeWorked',
            Value   => $parent_ticket->TimeWorked + $time_worked,
        );
        unless ($ret) {
            RT->Logger->error(
                "Failed to update parent ticket's TimeWorked: $msg");
        }
    }
}

1;

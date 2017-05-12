
use strict;
use warnings;

package RT::Action::SLA_SetDue;

use base qw(RT::Action::SLA);

=head2 Prepare

Checks if the ticket has service level defined.

=cut

sub Prepare {
    my $self = shift;

    unless ( $self->TicketObj->FirstCustomFieldValue('SLA') ) {
        $RT::Logger->error('SLA::SetDue scrip has been applied to ticket #'
            . $self->TicketObj->id . ' that has no SLA defined');
        return 0;
    }

    return 1;
}

=head2 Commit

Set the Due date accordingly to SLA.

=cut

sub Commit {
    my $self = shift;

    my $ticket = $self->TicketObj;
    my $txn = $self->TransactionObj;
    my $level = $ticket->FirstCustomFieldValue('SLA');

    my ($last_reply, $is_outside) = $self->LastEffectiveAct;
    $RT::Logger->debug(
        'Last effective '. ($is_outside? '':'non-') .'outside actors\' reply'
        .' to ticket #'. $ticket->id .' is txn #'. $last_reply->id
    );

    my $response_due = $self->Due(
        Ticket => $ticket,
        Level => $level,
        Type => $is_outside? 'Response' : 'KeepInLoop',
        Time => $last_reply->CreatedObj->Unix,
    );

    my $resolve_due = $self->Due(
        Ticket => $ticket,
        Level => $level,
        Type => 'Resolve',
        Time => $ticket->CreatedObj->Unix,
    );

    my $due;
    $due = $response_due if defined $response_due;
    $due = $resolve_due unless defined $due;
    $due = $resolve_due if defined $due && defined $resolve_due && $resolve_due < $due;

    return $self->SetDateField( Due => $due );
}

sub IsOutsideActor {
    my $self = shift;
    my $txn = shift || $self->TransactionObj;

    my $actor = $txn->CreatorObj->PrincipalObj;

    # owner is always treated as inside actor
    return 0 if $actor->id == $self->TicketObj->Owner;

    if ( $RT::ServiceAgreements{'AssumeOutsideActor'} ) {
        # All non-admincc users are outside actors
        return 0 if $self->TicketObj          ->AdminCc->HasMemberRecursively( $actor )
                 or $self->TicketObj->QueueObj->AdminCc->HasMemberRecursively( $actor );

        return 1;
    } else {
        # Only requestors are outside actors
        return 1 if $self->TicketObj->Requestors->HasMemberRecursively( $actor );
        return 0;
    }
}

sub LastEffectiveAct {
    my $self = shift;

    my $txns = $self->TicketObj->Transactions;
    $txns->Limit( FIELD => 'Type', VALUE => 'Correspond' );
    $txns->Limit( FIELD => 'Type', VALUE => 'Create' );
    $txns->OrderByCols(
        { FIELD => 'Created', ORDER => 'DESC' },
        { FIELD => 'id', ORDER => 'DESC' },
    );

    my $res;
    while ( my $txn = $txns->Next ) {
        unless ( $self->IsOutsideActor( $txn ) ) {
            last if $res;
            return ($txn);
        }
        $res = $txn;
    }
    return ($res, 1);
}

1;

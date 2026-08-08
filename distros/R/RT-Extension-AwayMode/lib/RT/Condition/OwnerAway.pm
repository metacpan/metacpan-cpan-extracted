use v5.36;

package RT::Condition::OwnerAway;
use base qw(RT::Condition);

use RT::Extension::AwayMode;

=head1 NAME

RT::Condition::OwnerAway

=head1 DESCRIPTION

Scrip condition that is applicable when a new reply or comment arrives on a
ticket that has a real (non-Nobody) owner and that owner currently has Away
Mode active (see L<RT::Extension::AwayMode>). Intended to be paired with
C<ApplicableTransTypes => 'Correspond,Comment'>; which of those two actually
count is then narrowed by C<$AwayModeTransactionTypes> and
C<$AwayModeIgnorePrivilegedComments>, both handled by
L<RT::Extension::AwayMode/IsHandledTransaction>.

Comments are included because an F<rt-mailgate> running C<--action comment>
records incoming mail as a comment rather than as correspondence.

Replies written by the owner themselves are ignored: if an away user
answers a ticket they own, they are evidently still working on it, so the
ticket stays assigned to them.

=cut

sub IsApplicable ($self) {
    my $txn = $self->TransactionObj;
    return 0 unless RT::Extension::AwayMode->IsHandledTransaction($txn);

    my $ticket = $self->TicketObj;
    my $owner  = $ticket->OwnerObj;

    # Also the loop guard: RT::Action::OwnerAwayReassign sets the owner to
    # Nobody before adding its own Comment, so that comment can't re-match.
    return 0 unless $owner && $owner->Id && $owner->Id != RT->Nobody->Id;

    # Don't hand off a ticket when the away owner is the one replying.
    return 0 if $txn->Creator && $txn->Creator == $owner->Id;

    return RT::Extension::AwayMode->IsUserAway($owner) ? 1 : 0;
}

1;

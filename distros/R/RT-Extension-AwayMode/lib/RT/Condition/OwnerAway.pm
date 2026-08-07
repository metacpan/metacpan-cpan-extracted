use v5.36;

package RT::Condition::OwnerAway;
use base qw(RT::Condition);

use RT::Extension::AwayMode;

=head1 NAME

RT::Condition::OwnerAway

=head1 DESCRIPTION

Scrip condition that is applicable when a ticket has a real (non-Nobody)
owner and that owner currently has Away Mode active (see
L<RT::Extension::AwayMode>). Intended to be paired with
C<ApplicableTransTypes => 'Correspond'> so it fires on new replies.

=cut

sub IsApplicable ($self) {
    my $ticket = $self->TicketObj;
    my $owner  = $ticket->OwnerObj;

    return 0 unless $owner && $owner->Id && $owner->Id != RT->Nobody->Id;

    return RT::Extension::AwayMode->IsUserAway($owner) ? 1 : 0;
}

1;

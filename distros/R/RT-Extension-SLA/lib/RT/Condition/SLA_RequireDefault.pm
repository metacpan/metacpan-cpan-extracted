
use strict;
use warnings;

package RT::Condition::SLA_RequireDefault;
use base qw(RT::Condition::SLA);

=head1 IsApplicable

Applies the current scrip when SLA is not set. Returns true on create,
but only if SLA CustomField is applied to the ticket and it has no
value set.

=cut

sub IsApplicable {
    my $self = shift;
    return 0 unless $self->TransactionObj->Type eq 'Create';
    my $ticket = $self->TicketObj;
    return 0 unless lc($ticket->Type) eq 'ticket';
    return 0 if $ticket->FirstCustomFieldValue('SLA');
    return 0 unless $self->SLAIsApplied;
    return 1;
}

1;


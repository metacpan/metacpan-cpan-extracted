use strict;
use warnings;

package RT::Condition::SLA_RequireStartsSet;

use base qw(RT::Condition::SLA);

=head1 NAME

RT::Condition::SLA_RequireStartsSet - checks if Starts date is not set

=head1 DESCRIPTION

Applies if Starts date is not set for the ticket.

=cut

sub IsApplicable {
    my $self = shift;
    return 0 if $self->TicketObj->StartsObj->Unix > 0;
    return 0 unless $self->TicketObj->FirstCustomFieldValue('SLA');
    return 1;
}

1;

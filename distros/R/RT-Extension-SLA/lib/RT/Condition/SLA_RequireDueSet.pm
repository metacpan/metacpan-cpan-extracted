use strict;
use warnings;

package RT::Condition::SLA_RequireDueSet;

use base qw(RT::Condition::SLA);

=head1 NAME

RT::Condition::SLA_RequireDueSet - checks if Due date require update

=head1 DESCRIPTION

Checks if Due date require update. This should be done when we create
a ticket and it has service level value or when we set service level.

=cut

sub IsApplicable {
    my $self = shift;
    return 0 unless $self->SLAIsApplied;

    my $type = $self->TransactionObj->Type;
    if ( $type eq 'Create' || $type eq 'Correspond' ) {
        return 1 if $self->TicketObj->FirstCustomFieldValue('SLA');
        return 0;
    }
    elsif ( $type eq 'Status' || ($type eq 'Set' && $self->TransactionObj->Field eq 'Status') ) {
        return 1 if $self->TicketObj->FirstCustomFieldValue('SLA');
        return 0;
    }
    return 1 if $self->IsCustomFieldChange('SLA');
    return 0;
}

1;

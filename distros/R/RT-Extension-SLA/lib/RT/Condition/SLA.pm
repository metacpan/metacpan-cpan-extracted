
use strict;
use warnings;

package RT::Condition::SLA;
use base qw(RT::Extension::SLA RT::Condition);

=head1 SLAIsApplied

=cut

sub SLAIsApplied { return 1 }

=head1 IsCustomFieldChange

=cut

sub IsCustomFieldChange {
    my $self = shift;
    my $cf_name = shift;

    my $txn = $self->TransactionObj;
    
    return 0 unless $txn->Type eq 'CustomField';

    my $cf = $self->GetCustomField( CustomField => $cf_name );
    unless ( $cf->id ) {
        $RT::Logger->debug("Custom field '$cf_name' is not applied to ticket #". $self->TicketObj->id);
        return 0;
    }
    return 0 unless $cf->id == $txn->Field;
    return 1;
}

1;

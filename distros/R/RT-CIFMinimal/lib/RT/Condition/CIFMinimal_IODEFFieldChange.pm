package RT::Condition::CIFMinimal_IODEFFieldChange;

use strict;
use warnings;

use base qw(RT::Condition::Generic);

sub IsApplicable {
    my $self = shift;
    return(0) unless($self->TicketObj->Status() eq 'open');
    my $txn = $self->TransactionObj();
    my $type = $txn->Type();
    return(0) unless($type eq 'CustomField');

    # check to make sure we actually changed something
    return(0) unless($txn->NewReference);
    return(0) if($txn->OldReference && ($txn->NewReference() == $txn->OldReference()));

    my $id = $txn->Field();
    my $cf = RT::CustomField->new($self->CurrentUser());
    $cf->Load($id);
    return(0) unless($cf->Description() =~ /^_IODEF_/);

    # its changed!
    return(1);
}

1;


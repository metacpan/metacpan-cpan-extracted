package RT::Action::SetCustomFieldDate;
use base 'RT::Action';

use strict;
use warnings;

sub Prepare  {
    # nothing to prepare
    return 1;
}

sub Commit {
    my $self  = shift;
    my $field = $self->Argument;

    RT::Logger->error("Field required") unless $field;
    return unless $field;

    my $DateObj = RT::Date->new($self->TicketObj->CurrentUser);
    $DateObj->SetToNow;
    my $value = $DateObj->ISO(Timezone => 'user');

    my ($ret, $msg) = $self->TicketObj->AddCustomFieldValue(Field => $field, Value => $value);
    unless ($ret) {
        RT->Logger->error($msg);
    }
    return $ret;
}

RT::Base->_ImportOverlays();

1;

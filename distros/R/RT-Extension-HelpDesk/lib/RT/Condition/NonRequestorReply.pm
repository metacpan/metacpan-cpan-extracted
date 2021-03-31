package RT::Condition::NonRequestorReply;

use base 'RT::Condition';
use strict;
use warnings;

sub IsApplicable {
    my $self = shift;

    return unless $self->TransactionObj->Type eq 'Correspond';

    # don't return true if the transaction creator is NOT a requestor.
    return if grep { $self->TransactionObj->CreatorObj->EmailAddress eq $_ }
      $self->TicketObj->RequestorAddresses;
    return 1;
}

1;

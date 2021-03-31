package RT::Condition::RequestorReply;
use base 'RT::Condition';
use strict;
use warnings;

sub IsApplicable {
    my $self = shift;

    return unless $self->TransactionObj->Type eq 'Correspond';

    # don't return true unless the transaction creator is a requestor.
    return unless grep { $self->TransactionObj->CreatorObj->EmailAddress eq $_ }
      $self->TicketObj->RequestorAddresses;
    return 1;
}

1;

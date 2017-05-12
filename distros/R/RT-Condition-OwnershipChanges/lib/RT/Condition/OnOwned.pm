package RT::Condition::OnOwned;

use strict;
use warnings;
use base qw(RT::Condition);

sub IsApplicable { 
    my $self = shift;
    my $owner = shift;

    return unless $self->TransactionObj->Field eq 'Owner';

    return $self->TransactionObj->OldValue == RT->Nobody->Id;
}

1;

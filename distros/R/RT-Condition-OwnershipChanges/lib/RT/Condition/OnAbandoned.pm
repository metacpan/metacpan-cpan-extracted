package RT::Condition::OnAbandoned;

use strict;
use warnings;
use base qw(RT::Condition);

sub IsApplicable { 
    my $self = shift;

    return unless $self->TransactionObj->Field eq 'Owner';

    return $self->TransactionObj->NewValue == RT->Nobody->Id;
}

1;

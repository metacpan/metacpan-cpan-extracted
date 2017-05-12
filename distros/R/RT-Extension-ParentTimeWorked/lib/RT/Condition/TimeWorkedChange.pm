use strict;
use warnings;

package RT::Condition::TimeWorkedChange;
use base 'RT::Condition';

sub IsApplicable {
    my $self = shift;
    my $txn = $self->TransactionObj;
    return 1 if $txn->TimeTaken;
    return 1
      if $txn->Type eq 'Set'
          && $txn->Field eq 'TimeWorked'
          && ( $txn->NewValue - $txn->OldValue );
    return 0;
}


1;

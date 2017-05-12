# $File: //depot/RT/osf/lib/RT/Tickets_Local.pm $ $Author: autrijus $
# $Revision: #1 $ $Change: 9189 $ $DateTime: 2003/12/07 22:30:06 $

use strict;
no warnings 'redefine';

sub LimitToEnabledQueues {
    my $self = shift;
    my $Queues = RT::Queues->new($RT::SystemUser);
    $Queues->LimitToEnabled;
    while (my $Queue = $Queues->Next) {
	$self->LimitQueue(VALUE => $Queue->Id);
    }
}

1;

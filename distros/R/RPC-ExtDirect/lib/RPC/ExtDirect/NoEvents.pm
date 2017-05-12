package RPC::ExtDirect::NoEvents;

use strict;
use warnings;
no  warnings 'uninitialized';           ## no critic

use base 'RPC::ExtDirect::Event';

### PUBLIC CLASS METHOD (CONSTRUCTOR) ###
#
# Initialize a new instance of NoEvents. This is a stub event
# we have to return when there are no actual events returned
# by the poll handlers. Certain Ext JS versions had a bug that
# resulted in a JavaScript exception thrown when an empty array
# of events was returned; returning one stub event instead
# works around that problem.
#

sub new {
    my ($class) = @_;

    return $class->SUPER::new('__NONE__', '');
}

1;

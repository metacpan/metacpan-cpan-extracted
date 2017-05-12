# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net::Analysis-Utils.t'

use strict;
use Data::Dumper;

use Test::More tests => 6;

use t::TestMockListener;

#########################

BEGIN { use_ok('Net::Analysis::Dispatcher') };

my ($test_event) = 'test_event';

#### Create a dispatcher
#
my ($d) = Net::Analysis::Dispatcher->new();
isnt ($d, undef, "new");


#### Add a mocked up listener, and check it gets added to the list
#
my ($mock_listener) = mock_listener($test_event);
$d->add_listener (listener => $mock_listener);
like ("$d", qr/\[Test::MockObject=HASH\(\w+\)\]/, "add_listener");


#### Now emit a test event, and check that the mock caught it
#
my ($in_args) = {arg1 => 'val1'};
$d->emit_event (name => $test_event, args => $in_args);

# Check the name of the last method called, and all the arguments
is_deeply ([$mock_listener->next_call()],
           [$test_event, [bless( {}, 'Test::MockObject' ), $in_args]],
           'emit_event');

#### Now test 'first' and 'last' places
#

# Create a stack of mock listeners, which do stuff to a shared queue, so we
#  can see which order they run in
my (@ml);
{
    my @calls;

    for (1..4) {
        my $mock_obj = mock_listener();
        $mock_obj->mock ($test_event, sub { push (@calls, $_[0]) } );
        push (@ml, $mock_obj);
    }

    sub listcalls {
        my @ret = @calls;
        @calls = ();
        return (@ret);
    }
}

$d = Net::Analysis::Dispatcher->new();

# Tweak first & last such that they will be put in special places
$ml[0]->{pos} = 'first';
$ml[3]->{pos} = 'last';

# Add them out of order, such that if 'pos' is honoured, they will be in order
#  form [0..3]
for my $n (3,1,2,0) {
    $d->add_listener (listener => $ml[$n]);
}

# Now trigger the event, and check that the order in which the mock_objs are
#  invoked is the natural order [0..3], not the raw addition order [3,1,2,0]
# The map weirdness is to ensure that is_deeply compares the instances, not
#  just the object types.
$d->emit_event (name => $test_event, args => {});
is_deeply ([map {"$_"} @ml], [map {"$_"} listcalls()], 'out of order 1');

# Establish it works the second time, since the queue is reshuffled on the
#  first event
$d->emit_event (name => $test_event, args => {});
is_deeply ([map {"$_"} @ml], [map {"$_"} listcalls()], 'out of order 2');

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net::Analysis-Utils.t'

use strict;
use Data::Dumper;

use Test::More tests => 5;
use t::TestMockListener;

use Net::Analysis::Dispatcher;

#########################

BEGIN { use_ok('Net::Analysis::Listener::Base'); };

my ($test_event) = 'test_event';

#### Create a dispatcher
#
my ($d) = Net::Analysis::Dispatcher->new();
isnt ($d, undef, "new dispatcher");


#### Create a base listener, check that the dispatcher registers it
#
my ($l) = Net::Analysis::Listener::Base->new(dispatcher => $d);
isnt ($l, undef, "new base listener");
like ("$d", qr/\[Net::Analysis::Listener::Base\]/, "base listener registered");


#### Add a mocked up listener, and check it gets added to the list
#
# We assume all this stuff to work, since it's covered in another test suite
my ($mock_listener) = mock_listener($test_event);
$d->add_listener (listener => $mock_listener);


#### Now emit an event through the base object, and see the mock_obj pick it up
#
my ($in_args) = {foo => 'val'};
$l->emit (name => $test_event, args => $in_args);

is_deeply ([$mock_listener->next_call()],
           [$test_event, [bless( {}, 'Test::MockObject' ), $in_args]],
           'event properly dispatched');

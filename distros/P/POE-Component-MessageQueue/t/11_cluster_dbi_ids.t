use strict;
use warnings;

use lib 't/lib';
use POE::Component::MessageQueue::Test::Stomp;
use POE::Component::MessageQueue::Test::MQ;
use POE::Component::MessageQueue::Test::DBI;
use File::Path;
use Test::More;
use Test::Exception;
use DBI;

# Make sure that there are no conflicts between in_use_by values when two
# seperate MQs are using Storage::DBI pointing at the same database.

BEGIN {
	check_environment_vars_dbi();
}

clear_messages_dbi();

plan tests => 19; 

my ($pid1, $pid2);

$pid1 = start_mq(
	storage => storage_factory_dbi(mq_id => 'mq1'),
);
sleep 2;
ok($pid1, "MQ1 started");

sub start_mq2 {
	$pid2 = start_mq(
		storage => storage_factory_dbi(mq_id => 'mq2'),
		port => '8100',
	);
	sleep 2;
	ok($pid2, "MQ2 started");
}
start_mq2();

# This test works by checking if one MQ will incorrectly clear the claims set by
# the other MQ.

my ($client1a, $client1b, $client2);
my $message;

# So, first we have one client (id 1) connect to MQ1, subscribe and then send a
# message.  This will get it claimed immediately, but we won't ACK.

ok($client1a = stomp_connect(), 'MQ1: client 1 connected');

lives_ok {
	stomp_subscribe($client1a);
	stomp_send($client1a);
} 'MQ1: client 1 subscribed and sent message';

ok($message = $client1a->receive_frame(), 'MQ1: client 1 claimed message');
is($message->body, 'arglebargle', 'Message looks correct');
sleep 2;

# Next, connect to MQ2 (will also have id 1).  First, we try subscribing and un
# subscribing to the queue (will cause disown_destination() in the Storage API)
ok($client1b = stomp_connect(8100),  'MQ2: client 1 connects');
lives_ok {
	stomp_subscribe($client1b);
	stomp_unsubscribe($client1b);
} 'MQ2: client 1 subscribes and unsubscribes';

# We test that the claim hasn't been cleared by connecting to MQ1 again and 
# subscribing to the queue.  If the message isn't redelivered, then we are good.
lives_ok {
	$client2 = stomp_connect();
	stomp_subscribe($client2);
} 'MQ1: client 2 subscribes';
is($client2->can_read({ timeout => 10 }), 0, 'message isn\'t re-delivered');
$client2->disconnect();

# Next, we try disconnecting from MQ2 which will cause disown_all() in the
# Storage API, to see that this also doesn't clear the claim.
lives_ok { $client1b->disconnect() } 'MQ2: client 1 disconnects';

# Test again to see if the message is redelivered
lives_ok {
	$client2 = stomp_connect();
	stomp_subscribe($client2);
} 'MQ1: client 2 subscribes';
is($client2->can_read({ timeout => 10 }), 0, 'message isn\'t re-delivered');
$client2->disconnect();

# Finally, we try shutting down and restarting MQ2, which should attempt to 
# clear all of its old claims.
ok(stop_fork($pid2), 'MQ2 shut down.');
start_mq2();

# And test one last time...
lives_ok {
	$client2 = stomp_connect();
	stomp_subscribe($client2);
} 'MQ1: client 2 subscribes';
is($client2->can_read({ timeout => 10 }), 0, 'message isn\'t re-delivered');
$client2->disconnect();

# Stop both MQ's, we're done
ok(stop_fork($pid1), 'MQ1 shut down.');
ok(stop_fork($pid2), 'MQ2 shut down.');


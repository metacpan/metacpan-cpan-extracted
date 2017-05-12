use strict;
use warnings;

use lib 't/lib';
use POE::Component::MessageQueue::Test::Stomp;
use POE::Component::MessageQueue::Test::MQ;
use POE::Component::MessageQueue::Test::DBI;
use Test::More;
use Test::Exception;
use DBI;

# Make sure that sending messages to one message queue will be received by clients
# on the other message queue.

BEGIN {
	check_environment_vars_dbi();
}

clear_messages_dbi();

plan tests => 11; 

my $pid1 = start_mq(
	storage        => storage_factory_dbi(mq_id => 'mq1'),
	pump_frequency => 1
);
ok($pid1, "MQ1 started");
sleep 2;

my $pid2 = start_mq(
	storage        => storage_factory_dbi(mq_id => 'mq2'),
	pump_frequency => 1,
	port           => '8100'
);
ok($pid2, "MQ2 started");
sleep 2;

# Begin test!

my ($client1, $client2, $message);

ok($client1 = stomp_connect(),     'MQ1: client connected');
ok($client2 = stomp_connect(8100), 'MQ2: client connected');

lives_ok {
	stomp_subscribe($client2);
} 'MQ2: client subscribed';

lives_ok {
	stomp_send($client1);
} 'MQ1: client sent message';

# check that it crossed the message queues
my $can_read = $client2->can_read({ timeout => 10 });
ok($can_read, 'MQ2: message is ready for delivery');
SKIP: {
	skip 'test will hang if we try to receive a frame and none is there', 2 unless $can_read;

	ok($message = $client2->receive_frame(), 'MQ2: client claimed message');
	is($message->body, 'arglebargle', 'MQ2: message looks correct');
}

# Stop both MQ's, we're done
ok(stop_fork($pid1), 'MQ1 shut down.');
ok(stop_fork($pid2), 'MQ2 shut down.');


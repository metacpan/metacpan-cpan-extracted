use strict;
use warnings;
use lib 't/lib';

use POE::Component::MessageQueue::Test::Stomp;
use POE::Component::MessageQueue::Test::MQ;
use POE::Component::MessageQueue::Test::EngineMaker;

use File::Path;
use IO::Dir qw(DIR_UNLINK);
use Exception::Class::TryCatch;
use Test::Exception;
use Test::More tests => 38;

# Our testing agenda:
#
# 1) Start MQ with Complex
# 2) Subscribe two consumers on the same queue
# 3) Send 30 messages
# 4) Check that both got exactly 15
# 5) Disconnect and reconnect
# 6) Reverify that no new messages were received.

lives_ok { 
	rmtree(DATA_DIR); 
	mkpath(DATA_DIR); 
	make_db() 
} 'setup data dir';

my $pid = start_mq(storage => 'Complex');
ok($pid, 'MQ started');
sleep 2;

sub setup_consumer
{
	my $stomp = stomp_connect();
	$stomp->subscribe({
		destination => '/queue/test',
		'ack'       => 'auto',
	});
	return $stomp;
}

my @clients = ( setup_consumer, setup_consumer );
sleep 1;

# send our 30 messages
lives_ok {
	my $producer = stomp_connect();
	foreach (1..30)
	{
		$producer->send({
			persistent  => 'true',
			destination => '/queue/test',
			body        => 'ehouer',
		});
	}
	$producer->disconnect();
} 'messages sent';

sub consumer_receive
{
	my ($consumer, @ids) = @_;
	my $count;
	for(1..15) 
	{
		my $frame = $consumer->receive_frame();
		is($frame->body, 'ehouer', 'valid message');
		$count++;
	}
	is($count, 15, '15 messages received');
}

consumer_receive($clients[0]);
consumer_receive($clients[1]);

$_->disconnect() for (@clients);

# reconnect and verify that there are no messages
is(setup_consumer()->can_read({ timeout => 10 }), 0, 'no messages remain');

ok(stop_fork($pid), 'MQ shut down');

lives_ok { rmtree(DATA_DIR) } 'Data dir removed';


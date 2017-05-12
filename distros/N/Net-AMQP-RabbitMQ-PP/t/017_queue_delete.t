use strict;
use warnings;

use Test::Most;
use Test::Exception;

use FindBin qw/ $Bin /;
use lib $Bin;
use Net::AMQP::RabbitMQ::PP::Test;

my $host = $ENV{MQHOST};

use_ok('Net::AMQP::RabbitMQ::PP');

ok( my $mq = Net::AMQP::RabbitMQ::PP->new(), 'new' );

lives_ok {
	$mq->connect(
		host => $host,
		username => "guest",
		password => "guest",
	);
} 'connect';

lives_ok {
	$mq->channel_open(
		channel => 1,
	);
} 'channel.open';

my $queue = '';
lives_ok {
	$queue = $mq->queue_declare(
		channel => 1,
		durable => 1,
		exclusive => 0,
		auto_delete => 0,
	)->queue;
} 'queue.declare';

lives_ok {
	$mq->queue_delete(
		channel => 1,
		queue => $queue,
		if_empty => 1,
		if_unused => 1,
	);
} 'queue.delete';

done_testing()

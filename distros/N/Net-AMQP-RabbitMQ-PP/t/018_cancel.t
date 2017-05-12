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

my $queue;
lives_ok {
	$queue = $mq->queue_declare(
		channel => 1,
	)->queue;
} 'queue.declare';

my $ctag;
lives_ok {
	$ctag = $mq->basic_consume(
		channel => 1,
		queue => $queue,
		consumer_tag => 'ctag',
	);
} 'basic.consume';

lives_ok {
	$mq->basic_cancel(
		channel => 1,
		consumer_tag => $ctag,
	);
} 'basic.cancel';

done_testing()

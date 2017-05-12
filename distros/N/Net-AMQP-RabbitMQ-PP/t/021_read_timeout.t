use strict;
use warnings;

use Test::Most;
use Test::Exception;

use FindBin qw/ $Bin /;
use lib $Bin;
use Net::AMQP::RabbitMQ::PP::Test;

my $host = $ENV{MQHOST};

use_ok( 'Net::AMQP::RabbitMQ::PP' );

ok( my $mq = Net::AMQP::RabbitMQ::PP->new() );

lives_ok {
	$mq->connect(
		host => $host,
		username => "guest",
		password => "guest",
	);
} "connect";

lives_ok {
	$mq->channel_open(
		channel => 1,
	);
} "channel.open";

my $testqueue;
lives_ok {
	$testqueue = $mq->queue_declare(
		channel => 1,
		passive => 0,
		durable => 0,
		exclusive => 0,
		auto_delete => 1,
	)->queue;
} 'queue.declare';

my $consumertag;
lives_ok {
	$consumertag = $mq->basic_consume(
		channel => 1,
		queue => $testqueue,
		consumer_tag => 'ctag',
		no_local => 0,
		no_ack => 1,
		exclusive => 0,
	)->consumer_tag;
} "consume";

my $rv;
lives_ok {
	local $SIG{ALRM} = sub {
		die "Timeout";
	};
	alarm 5;
	$rv = $mq->receive(
		timeout => 1.5,
	);
	alarm 0;
} "recv";

is_deeply(
	$rv,
	undef,
);

done_testing()

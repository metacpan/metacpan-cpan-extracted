use strict;
use warnings;

use Test::Most;
use Test::Exception;

use FindBin qw/ $Bin /;
use lib $Bin;
use Net::AMQP::RabbitMQ::PP::Test;

my $host = $ENV{'MQHOST'};

use_ok('Net::AMQP::RabbitMQ::PP');

ok( my $mq = Net::AMQP::RabbitMQ::PP->new() );

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
};

my $expect_qn = 'test.net.rabbitmq.perl';
my $declareok;
lives_ok {
	$declareok = $mq->queue_declare(
		channel => 1,
		queue => $expect_qn,
		durable => 1,
		exclusive => 0,
		auto_delete => 1,
	); 
} 'queue.declare';

is_deeply(
	$declareok,
	Net::AMQP::Protocol::Queue::DeclareOk->new(
		consumer_count => 0,
		queue => $expect_qn,
		message_count => 0,
	)
);

done_testing()

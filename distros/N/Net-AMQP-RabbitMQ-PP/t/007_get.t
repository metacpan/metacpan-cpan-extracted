use strict;
use warnings;

use Test::Most;
use Test::Exception;

use FindBin qw/ $Bin /;
use lib $Bin;
use Net::AMQP::RabbitMQ::PP::Test;

my $host = $ENV{MQHOST};

use_ok('Net::AMQP::RabbitMQ::PP');

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

lives_ok {
	$mq->exchange_declare(
		channel => 1,
		exchange => 'perl_test_get',
		exchange_type => 'direct',
	);
} 'exchange.declare';


my $queuename = '';
lives_ok {
	$queuename = $mq->queue_declare(
		channel => 1,
		queue => '',
		durable => 0,
		exclusive => 0,
		auto_delete => 1,
	)->queue;
} "queue.declare";

lives_ok {
	$mq->queue_bind(
		channel => 1,
		queue => $queuename,
		exchange => "perl_test_get",
		routing_key => "perl_test_get_key",
	);
} "queue.bind";

my $getr;
lives_ok {
	$getr = $mq->basic_get(
		channel => 1,
		queue => $queuename,
	);
} "get";

is_deeply( $getr, undef, "get should return empty" );

lives_ok {
	$mq->basic_publish(
		channel => 1,
		routing_key => "perl_test_get_key",
		payload => "Magic Transient Payload",
		exchange => "perl_test_get",
	);
} "basic.publish";

lives_ok {
	$getr = $mq->basic_get(
		channel => 1,
		queue => $queuename,
	);
} "basic.get";

is_deeply(
	$getr,
	{
		content_header_frame => Net::AMQP::Frame::Header->new(
			body_size => 23,
			weight => 0,
			payload => '',
			type_id => 2,
			class_id => 60,
			channel => 1,
			header_frame => Net::AMQP::Protocol::Basic::ContentHeader->new(
			),
		),
        delivery_tag => 1,
		payload      => 'Magic Transient Payload',
	},
	"get should see message"
);

lives_ok {
	$mq->basic_publish(
		channel => 1,
		routing_key => "perl_test_get_key",
		payload => "Magic Transient Payload 2",
		exchange => "perl_test_get",
		correlation_id => '123',
		reply_to => 'somequeue',
		expiration => 60000,
		message_id => 'ABC',
		type => 'notmytype',
		user_id => 'guest',
		app_id => 'idd',
		delivery_mode => 1,
		priority => 2,
		timestamp => 1271857990,
	);
} 'basic.publish';

lives_ok {
	$getr = $mq->basic_get(
		channel => 1,
		queue => $queuename,
	);
} "get";

is_deeply(
	$getr,
	{
		content_header_frame => Net::AMQP::Frame::Header->new(
			body_size => 25,
			weight => 0,
			payload => '',
			type_id => 2,
			class_id => 60,
			channel => 1,
			header_frame => Net::AMQP::Protocol::Basic::ContentHeader->new(
			),
		),
        delivery_tag => 2,
		payload      => 'Magic Transient Payload 2',
	},
	"get should see message"
);

done_testing();

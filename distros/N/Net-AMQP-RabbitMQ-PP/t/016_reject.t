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
		heartbeat => 1,
	);
} 'connect';

lives_ok {
	$mq->channel_open(
		channel => 1,
	);
} 'channel.open';

lives_ok {
	$mq->queue_declare(
		channel => 1,
		queue => "nr_test_reject",
		durable => 1,
		auto_delete => 0,
	);
} "queue_declare";

lives_ok {
	$mq->exchange_declare(
		channel => 1,
		exchange => 'perl_test_reject',
		exchange_type => 'direct',
	);
} 'exchange.declare';

lives_ok {
	$mq->queue_bind(
		channel => 1,
		queue => "nr_test_reject",
		exchange => "perl_test_reject",
		routing_key => "nr_test_reject_route",
	);
} "queue_bind";

lives_ok {
	$mq->queue_purge(
		channel => 1,
		queue => "nr_test_reject",
	);
} "purge";

lives_ok {
	$mq->basic_publish(
		channel => 1,
		routing_key => "nr_test_reject_route",
		payload => "Magic Payload",
		exchange => "perl_test_reject",
	);
} "publish";

my $ctag;
lives_ok {
	$ctag = $mq->basic_consume(
		channel => 1,
		queue => "nr_test_reject",
		no_ack => 0,
		consumer_tag => 'ctag',
	)->consumer_tag;
} "consuming";

is_deeply(
	$mq->receive(),
	{
		delivery_frame => Net::AMQP::Frame::Method->new(
			type_id => 1,
			payload => '',
			channel => 1,
			method_frame => Net::AMQP::Protocol::Basic::Deliver->new(
				redelivered => 0,
				delivery_tag => 1,
				routing_key => 'nr_test_reject_route',
				consumer_tag => $ctag,
				exchange => 'perl_test_reject',
			),
		),
		content_header_frame => Net::AMQP::Frame::Header->new(
			body_size => 13,
			weight => 0,
			payload => '',
			type_id => 2,
			class_id => 60,
			channel => 1,
			header_frame => Net::AMQP::Protocol::Basic::ContentHeader->new(
			),
		),
		payload => "Magic Payload",
	},
	"payload",
);

lives_ok { $mq->disconnect } "disconnect";

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
} "channel_open";

lives_ok {
	$ctag = $mq->basic_consume(
		channel => 1,
		queue => "nr_test_reject",
		no_ack => 0,
		consumer_tag => 'ctag',
	)->consumer_tag;
} "consuming";

my $delivery;
is_deeply(
	$delivery = $mq->receive(),
	{
		delivery_frame => Net::AMQP::Frame::Method->new(
			type_id => 1,
			payload => '',
			channel => 1,
			method_frame => Net::AMQP::Protocol::Basic::Deliver->new(
				redelivered => 1,
				delivery_tag => 1,
				routing_key => 'nr_test_reject_route',
				consumer_tag => $ctag,
				exchange => 'perl_test_reject',
			),
		),
		content_header_frame => Net::AMQP::Frame::Header->new(
			body_size => 13,
			weight => 0,
			payload => '',
			type_id => 2,
			class_id => 60,
			channel => 1,
			header_frame => Net::AMQP::Protocol::Basic::ContentHeader->new(
			),
		),
		payload => "Magic Payload",
	},
	"payload",
);

lives_ok {
	$mq->basic_reject(
		channel => 1,
		delivery_tag => $delivery->{delivery_frame}->method_frame->delivery_tag,
	);
} "rejecting";

lives_ok {
	$mq->basic_publish(
		channel => 1,
		routing_key => "nr_test_reject_route",
		payload => "Magic Payload requeue",
		exchange => "perl_test_reject",
	);
} "publish";

lives_ok {
	$delivery = $mq->receive(),
} "recv";

lives_ok {
	$mq->basic_reject(
		channel => 1,
		delivery_tag => $delivery->{delivery_frame}->method_frame->delivery_tag,
		requeue => 1,
	);
} "rejecting";

is_deeply(
	$delivery = $mq->receive(),
	{
		delivery_frame => Net::AMQP::Frame::Method->new(
			type_id => 1,
			payload => '',
			channel => 1,
			method_frame => Net::AMQP::Protocol::Basic::Deliver->new(
				redelivered => 1,
				delivery_tag => 3,
				routing_key => 'nr_test_reject_route',
				consumer_tag => $ctag,
				exchange => 'perl_test_reject',
			),
		),
		content_header_frame => Net::AMQP::Frame::Header->new(
			body_size => 21,
			weight => 0,
			payload => '',
			type_id => 2,
			class_id => 60,
			channel => 1,
			header_frame => Net::AMQP::Protocol::Basic::ContentHeader->new(
			),
		),
		payload => "Magic Payload requeue",
	},
	"payload",
);

lives_ok {
	$mq->basic_ack(
		channel => 1,
		delivery_tag => $delivery->{delivery_frame}->method_frame->delivery_tag,
	);
} "rejecting";



done_testing()

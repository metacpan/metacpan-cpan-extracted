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
	)
} 'channel.open';

lives_ok {
	$mq->exchange_declare(
		channel => 1,
		exchange => 'perl_test_noack',
		exchange_type => 'direct',
	);
} 'exchange.declare';


lives_ok {
	$mq->queue_declare(
		channel => 1,
		queue => "perl_test_ack",
		passive => 0,
		durable => 1,
		exclusive => 0,
		auto_delete => 0,
	);
} "queue_declare";

lives_ok {
	$mq->queue_bind(
		channel => 1,
		queue => "perl_test_ack",
		exchange => "perl_test_noack",
		routing_key => "perl_test_ack_route"
	);
} "queue_bind";

lives_ok {
	$mq->queue_purge(
		channel => 1,
		queue => "perl_test_ack",
	);
} 'queue.purge';

my $payload = "Magic Payload $$";

lives_ok {
	$mq->basic_publish(
		channel => 1,
		routing_key => "perl_test_ack_route",
		payload => $payload,
		exchange => "perl_test_noack",
	);
} "basic.publish";

my $consumer_tag;
lives_ok {
	$consumer_tag = $mq->basic_consume(
		channel => 1,
		queue => "perl_test_ack",
		no_ack => 0,
		consumer_tag => 'ctag',
	)->consumer_tag;
} "basic.consume";

is_deeply(
	$mq->receive(),
	{
		content_header_frame => Net::AMQP::Frame::Header->new(
			body_size => length $payload,
			type_id => '2',
			weight => 0,
			payload => '',
			channel => 1,
			class_id => 60,
			header_frame => Net::AMQP::Protocol::Basic::ContentHeader->new(
			),
		),
		delivery_frame => Net::AMQP::Frame::Method->new(
			type_id => 1,
			payload => '',
			channel => 1,
			method_frame => Net::AMQP::Protocol::Basic::Deliver->new(
				redelivered => 0,
				delivery_tag => 1,
				routing_key => 'perl_test_ack_route',
				consumer_tag => $consumer_tag,
				exchange => 'perl_test_noack',
			),
		),
		payload => $payload,
	},
	'received payload',
);

lives_ok {
	$mq->disconnect();
} "disconnect";

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

lives_ok {
	$consumer_tag = $mq->basic_consume(
		channel => 1,
		queue => "perl_test_ack",
		no_ack => 0,
		consumer_tag =>
		'ctag',
	)->consumer_tag;
} 'basic.consume';

is_deeply(
	my $message = $mq->receive(),
	{
		content_header_frame => Net::AMQP::Frame::Header->new(
			body_size => length $payload,
			type_id => '2',
			weight => 0,
			payload => '',
			channel => 1,
			class_id => 60,
			header_frame => Net::AMQP::Protocol::Basic::ContentHeader->new(
			),
		),
		delivery_frame => Net::AMQP::Frame::Method->new(
			type_id => 1,
			payload => '',
			channel => 1,
			method_frame => Net::AMQP::Protocol::Basic::Deliver->new(
				redelivered => 1,
				delivery_tag => 1,
				routing_key => 'perl_test_ack_route',
				consumer_tag => $consumer_tag,
				exchange => 'perl_test_noack',
			),
		),
		payload => $payload,
	},
	"payload"
);

lives_ok {
	$mq->basic_ack(
		channel => 1,
		delivery_tag => $message->{delivery_frame}->method_frame->delivery_tag,
	);
} 'basic.ack';

lives_ok {
	$mq->disconnect();
} "disconnect";


done_testing();

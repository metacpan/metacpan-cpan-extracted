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
} 'channel.open';

lives_ok {
	$mq->confirm_select(
		channel => 1,
	);
} 'confirm_select';

lives_ok {
	$mq->basic_publish(
		channel => 1,
		routing_key => "perl_test_route",
		payload => "Magic Payload",
	);
} 'basic.publish';

# TODO hack Need to build a callback API to replace hacks.
is_deeply (
	$mq->receive(
		channel => 1,
	),
	Net::AMQP::Frame::Method->new(
		type_id => 1,
		payload => '',
		channel => 1,
		method_frame => Net::AMQP::Protocol::Basic::Ack->new(
			delivery_tag => 1,
			multiple => 0,
		),
	),
	'delivery'
);


lives_ok {
	$mq->basic_publish(
		channel => 1,
		routing_key => "perl_test_route",
		payload => "Magic Payload",
		mandatory => 1,
		expiration => 0,
	);
} 'basic.publish';

# TODO hack Need to build a callback API to replace hacks.
is_deeply (
	$mq->receive(
		channel => 1,
	),
	Net::AMQP::Frame::Method->new(
		type_id => 1,
		payload => '',
		channel => 1,
		method_frame => Net::AMQP::Protocol::Basic::Return->new(
			reply_code => '312',
			routing_key => 'perl_test_route',
			reply_text => 'NO_ROUTE',
			exchange => '',
		),
	),
	'delivery'
);
lives_ok { $mq->disconnect(); } 'disconnect';
done_testing()

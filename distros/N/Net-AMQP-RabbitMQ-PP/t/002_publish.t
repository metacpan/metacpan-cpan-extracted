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
} 'connect';

lives_ok {
	$mq->channel_open(
		channel => 1,
	);
} 'channel.open';

lives_ok {
	$mq->exchange_declare(
		channel => 1,
		exchange => 'perl_test_publish',
		exchange_type => 'direct',
	);
} 'exchange.declare';

lives_ok {
	$mq->queue_declare(
		channel => 1,
		queue => "perl_test_queue",
		passive => 0,
		durable => 1,
		exclusive => 0,
		auto_delete => 0,
	);
} "queue.declare";

lives_ok {
	$mq->queue_bind(
		channel => 1,
		queue => "perl_test_queue",
		exchange => "perl_test_publish",
		routing_key => "perl_test_queue",
	);
} "queue.bind";

lives_ok {
	1 while( $mq->basic_get( channel => 1, queue => "perl_test_queue" ) );
} "drain queue";

lives_ok {
	$mq->basic_publish(
		channel => 1,
		routing_key => "perl_test_queue",
		payload => "Magic Payload",
		exchange => "perl_test_publish",
		content_type => 'text/plain',
		content_encoding => 'none',
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
} "basic.publish";

done_testing();

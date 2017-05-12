use strict;
use warnings;

use Test::Most;
use Test::Exception;

use FindBin qw/ $Bin /;
use lib $Bin;
use Net::AMQP::RabbitMQ::PP::Test;

my $host = $ENV{'MQHOST'};

use_ok('Net::AMQP::RabbitMQ::PP');

ok( my $mq = Net::AMQP::RabbitMQ::PP->new(), "Created object" );

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

my $delete = 1;
my $queue = "x-headers-" . rand();

lives_ok {
	$queue = $mq->queue_declare(
		channel => 1,
		queue => $queue,
		auto_delete => $delete,
		expires => 60000,
	)->queue;
} "queue_declare";

throws_ok {
	$queue = $mq->queue_declare(
		channel => 1,
		queue => $queue,
		auto_delete => $delete,
	);
} qr/PRECONDITION_FAILED/, "Redeclaring queue without header arguments fails.";

done_testing();

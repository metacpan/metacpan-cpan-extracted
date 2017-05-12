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

# Second call to channel open is invalid.
throws_ok {
	$mq->channel_open(
		channel => 1,
	);
} qr/COMMAND_INVALID - second 'channel[.]open'/, 'channel.open dupe';

# The connection should now be invalid.
throws_ok {
	$mq->channel_open(
		channel => 1,
	);
} qr/Not connected to broker/, 'Not connected to broker';

done_testing()

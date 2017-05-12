use strict;
use warnings;

use Test::Most;
use Test::Exception;

use FindBin qw/ $Bin /;
use lib $Bin;
use Net::AMQP::RabbitMQ::PP::Test;

my $host = $ENV{'MQHOST'};

use_ok( 'Net::AMQP::RabbitMQ::PP' );

ok( my $mq = Net::AMQP::RabbitMQ::PP->new() );

lives_ok {
	$mq->connect(
		host => $host,
		username => "guest",
		password => "guest"
	);
} 'connecting';

lives_ok {
	$mq->channel_open( channel => 1 );
} 'channel.open';

lives_ok {
	$mq->exchange_declare(
		channel => 1,
		exchange => "perl_exchange",
		exchange_type => "direct",
		passive => 0,
		durable => 1,
		auto_delete => 0,
	);
} 'exchange.declare';

done_testing();

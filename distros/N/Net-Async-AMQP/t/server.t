use strict;
use warnings;

use Test::More;
use Future::Utils;
use IO::Async::Loop;
use Net::Async::AMQP;
use Net::Async::AMQP::Server;

#plan skip_all => 'unfinished implementation';

my $loop = IO::Async::Loop->new;
my $srv = Net::Async::AMQP::Server->new;
$loop->add($srv);

my ($host, $port) = $srv->listening->get;

is($host, '0.0.0.0', 'host is 0.0.0.0');
$host = 'localhost';
ok($port, 'non-zero port');

$loop->add(my $cli = Net::Async::AMQP->new);
$cli->bus->subscribe_to_event(
	close => sub { fail("close - @_") },
	unexpected_frame => sub { fail("unexpected - @_") },
);

my $true = Net::AMQP::Value->true;
ok($cli->connect(
	host  => $host,
	port  => $port,
	user  => 'guest',
	pass  => 'guest',
	vhost => '/',
	client_properties => {
		capabilities => {
			'connection.blocked'     => $true,
			'consumer_cancel_notify' => $true,
		},
	},
)->get, 'connect to server');
ok($cli->open_channel->get, 'open channel');
ok($cli->close->get, 'close connection again');
done_testing;


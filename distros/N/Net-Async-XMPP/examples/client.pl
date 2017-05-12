use strict;
use warnings;

use IO::Async::Loop::Epoll;
use Net::Async::XMPP::Client;

my $loop = IO::Async::Loop::Epoll->new;
print "Had $loop\n";

my $client = Net::Async::XMPP::Client->new(
	debug => 1
);
$loop->add($client);

$client->connect(
	host	=> 'roku',
	service	=> 5222,
	on_connected => sub {
		warn "connected";
	},
	on_connect_error => sub {
		warn "connect error";
	},
	on_resolve_error => sub {
		warn "resolve error";
	}
);

$loop->loop_forever;

1;

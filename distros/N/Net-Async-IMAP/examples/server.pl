#!/usr/bin/perl 
use strict;
use warnings;

use IO::Async::Loop;
use IO::Async::Timer::Countdown;
use IO::Async::Listener;
use Net::Async::IMAP::Server;

# Standard event loop creation
my $loop = IO::Async::Loop->new;

# We create a new listener for the server first.
my $listener = IO::Async::Listener->new(
	on_stream => sub {
		my ($self, $stream) = @_;
		warn "Connection received\n";
		my $srv = Net::Async::IMAP::Server->new(
			debug		=> 1,
			transport	=> $stream,
		);
		$srv->on_connect;
		$loop->add($srv);
	},
);

$loop->add($listener);
$listener->listen(
	service		=> $ENV{NET_ASYNC_IMAP_PORT} || 'imap',
	socktype	=> 'stream',
	on_resolve_error => sub { die "Cannot resolve - $_[0]\n"; },
	on_listen_error  => sub { die "Cannot listen\n"; },
);
warn "Listening for connections\n";
$loop->loop_forever;


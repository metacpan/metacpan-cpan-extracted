#!/usr/bin/perl -w
#
# test the SRS::EPP::Proxy::Listener class

use strict;
use IO::Socket::INET;

our $have_v6;

use t::Log4test;

use Test::More qw(no_plan);

BEGIN {
	my $sock = eval {
    use if $] < 5.014, "Socket6";
		require IO::Socket::INET6;
		IO::Socket::INET6->new(
			Listen    => 1,
			LocalAddr => '::1',
			LocalPort => int(rand(60000)+1024),
			Proto     => 'tcp',
		) || diag $@;
	};
	if ( $sock or $!{EADDRINUSE} ) {
		$have_v6 = 1;
	}
}
sub try_connect {
	my ($address, $port) = @_;
	my $package = "IO::Socket::INET";
	if ( $address =~ /:/ ) {
		$package .= "6";
	}
	my $socket = $package->new(
		PeerAddr => $address,
		PeerPort => $port,
		Proto => "tcp",
		Timeout => 1,
		)
		or die "failed to connect to $address:$port; $!";
	$socket->shutdown(1);
}

our ($rfd, $wfd);

sub try_connect_loop {
	while (<$rfd>) {
		my ($addr, $port_num) = m{(.*) (\d+)} or next;
		&try_connect($addr, $port_num);
	}
}

BEGIN {
	pipe($rfd, $wfd);
	if ( my $pid = fork() ) {
		close($rfd);
	}
	else {
		close($wfd);
		try_connect_loop();
		exit(0);
	}
}

use IO::Handle;

BEGIN { use_ok("SRS::EPP::Proxy::Listener") }

$wfd->autoflush(1);

# test v4
my $listener =  SRS::EPP::Proxy::Listener->new(
	listen => [ "localhost:2047", "localhost:2048" ],
);
$listener->init;
pass("init listener OK");

print $wfd "localhost 2047\n";
print $wfd "localhost 2048\n";
ok($listener->accept(1), "got one connection");
ok($listener->accept(1), "got two connections");

$listener->close;
pass("closed listener OK");

# test v6 things.  note, if you have IO::Socket::INET6 install but no
# working v6 stack then these tests will try to run anyway and fail,
# sorry about that.
SKIP:{
	skip "IO::Socket::INET6 failed to load; skipping remaining tests",
		1 unless $have_v6;

	my $listener = SRS::EPP::Proxy::Listener->new(
		listen => ["[::]:2047"],
	);
	$listener->init;
	pass("listen on a v6 alias");
	print $wfd "127.0.0.1 2047\n";
	ok($listener->accept(1), "got a v4 connection on a v6 socket");
	print $wfd "::1 2047\n";
	ok($listener->accept(1), "got a v6 connection on a v6 socket too");
}

# Copyright (C) 2009  NZ Registry Services
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Artistic License 2.0 or later.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# Artistic License 2.0 for more details.
#
# You should have received a copy of the Artistic License the file
# COPYING.txt.  If not, see
# <http://www.perlfoundation.org/artistic_license_2_0>

#!/usr/bin/env perl 
use strict;
use warnings;
use Net::Async::SOCKS;
use IO::Async::Loop;
use IO::Async::Stream;

my $loop = IO::Async::Loop->new;
$loop->connect(
	extensions => [qw(SOCKS)],
	SOCKS_host => 'localhost',
	SOCKS_port => '9020',

	socktype   => "stream",
	service    => 80,
	host       => "192.168.1.1",
)->then(sub {
	my ($stream) = @_;
	warn "Connected to $stream";
	$stream->configure(
		on_read => sub {
			my ($stream, $buffref, $eof) = @_;
			warn ":: " . $$buffref . "\n";
			$$buffref = '';
			$stream->close if $eof;
			0
		}
	);
	$loop->add($stream);
	$stream->write("GET / HTTP/1.1\x0D\x0AHost: localhost\x0D\x0A\x0D\x0A")
})->get;
$loop->run;

1;


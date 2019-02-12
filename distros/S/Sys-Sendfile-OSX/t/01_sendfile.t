#!/usr/bin/env perl

use warnings;
use strict;

use Test::Most tests => 6;
use IO::Socket;
use Fcntl qw(SEEK_SET);

require_ok('Sys::Sendfile::OSX');
use_ok('Sys::Sendfile::OSX');
can_ok('Sys::Sendfile::OSX', 'sendfile');

open my $in_h, '<', $0 or die "open(): $!";

my $slurped = do { local $/; <$in_h> };
seek($in_h, 0, SEEK_SET);

my $listen = IO::Socket::INET->new(Listen => 1)
	or die "listen(): $!";

my $in = IO::Socket::INET->new(
	PeerHost => $listen->sockhost,
	PeerPort => $listen->sockport
) or die "connect(): $!";

my $out_h = $listen->accept;

subtest 'sending entire file' => sub {
	my $total_sent = Sys::Sendfile::OSX::sendfile($in_h, $out_h);
	is($total_sent, -s $in_h, "sent all of \$0 into socket in one go");

	$in->recv(my $buf, -s $in_h);
	is($buf, $slurped, "recv'd the same data that we sent");
};

subtest 'sending a chunk' => sub {
	my $chunk_size = 10;
	my $total_sent = Sys::Sendfile::OSX::sendfile($in_h, $out_h, $chunk_size);
	is($total_sent, $chunk_size, "sent $chunk_size bytes of \$0 into socket");

	$in->recv(my $buf, $total_sent);
	is($buf, substr($slurped, 0, $chunk_size), "recv'd the same data that we sent");
};

subtest 'sending an offsetted chunk' => sub {
	my $offset     = 10;
	my $chunk_size = 10;

	my $total_sent = Sys::Sendfile::OSX::sendfile($in_h, $out_h, $chunk_size, $offset);
	is($total_sent, $chunk_size, "sent $chunk_size bytes of \$0 from offset $offset into socket");

	$in->recv(my $buf, $total_sent);
	is($buf, substr($slurped, $offset, $chunk_size), "recv'd the same data that we sent");
};

$in->close;
$out_h->close;

# TODO test non-blocking filehandles and sockets

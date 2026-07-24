#!perl
# ABOUTME: Live functional tests of error handling: protocol-level error
# ABOUTME: replies and per-oid timeout errors inside successful replies.

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use IO::Socket::INET;
use Test::More;
use SQETest;

my $reason = SQETest::skip_reason();
plan skip_all => $reason if $reason;

my $t = SQETest->start;
my $sqe = $t->client;

$sqe->get("257.12.22.13", 161, ["1.3.6.1.2.1.1.5.0"], sub {
	my ($h, $ok, $r) = @_;
	ok !$ok, "invalid destination address yields an error reply";
	ok !ref $r, "error payload is a plain string";
	like $r, qr/bad IP/i, "error text describes the problem";
});
$sqe->wait;

# A bound-but-mute UDP socket guarantees silent packet drop (no ICMP
# port-unreachable), which is what makes the daemon time out.
my $mute = IO::Socket::INET->new(
	LocalAddr => "127.0.0.1",
	LocalPort => 0,
	Proto     => "udp",
) or die "cannot bind mute UDP socket: $!";
my $dead_port = $mute->sockport;

$sqe->setopt("127.0.0.1", $dead_port, { timeout => 200, retries => 1 }, sub {
	my ($h, $ok, $r) = @_;
	ok $ok, "setopt short timeout on the mute destination succeeds";
});
$sqe->wait;

$sqe->get("127.0.0.1", $dead_port, ["1.3.6.1.2.1.1.5.0"], sub {
	my ($h, $ok, $r) = @_;
	ok $ok, "timeout arrives inside a successful reply";
	is_deeply $r, [["1.3.6.1.2.1.1.5.0", ["timeout"]]],
		"per-oid timeout error as single-element array";
});
$sqe->wait;

close $mute;
$t->stop;
done_testing;

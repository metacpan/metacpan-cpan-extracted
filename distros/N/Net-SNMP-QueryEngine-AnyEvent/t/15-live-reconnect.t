#!perl
# ABOUTME: Live functional tests of connection-loss handling: disconnect hooks,
# ABOUTME: erroring out in-flight requests, queueing while down, and reconnect.

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use AnyEvent;
use IO::Socket::INET;
use Test::More;
use Net::SNMP::QueryEngine::AnyEvent;
use SQETest;

my $reason = SQETest::skip_reason();
plan skip_all => $reason if $reason;

# A hung event loop is the natural failure mode of reconnect bugs;
# turn hangs into test failures.
$SIG{ALRM} = sub { die "test timed out" };
alarm 120;

my $t = SQETest->start;
my ($host, $port) = ($t->{agent_host}, $t->{agent_port});

my @events;
my $sqe = Net::SNMP::QueryEngine::AnyEvent->new(
	connect       => ["127.0.0.1", $t->{daemon_port}],
	reconnect     => 0.3,
	on_connect    => sub {
		my ($h) = @_;
		push @events, "connect";
		$h->setopt($host, $port, { community => "meow" }, sub {});
	},
	on_disconnect => sub { push @events, "disconnect: $_[1]" },
);

# on_connect fires on the initial connection, and requests it issues
# are sent before requests queued while connecting: the get below is
# issued first but must be answered under the hook's community.
$sqe->get($host, $port, ["1.3.6.1.2.1.1.5.0"], sub {
	my ($h, $ok, $r) = @_;
	push @events, "reply";
	ok $ok, "get over the initial connection succeeds";
	is $r->[0][1], "meow.example.net",
		"setopt issued from on_connect was sent before the queued request";
});
$sqe->wait;
is_deeply \@events, ["connect", "reply"], "on_connect fired before the first reply";

# In-flight requests error out when the daemon goes away.  A request
# towards a bound-but-mute UDP port with a long timeout is reliably
# still unanswered when we kill the daemon.
my $mute = IO::Socket::INET->new(
	LocalAddr => "127.0.0.1",
	LocalPort => 0,
	Proto     => "udp",
) or die "cannot bind mute UDP socket: $!";
my $dead_port = $mute->sockport;

$sqe->setopt("127.0.0.1", $dead_port, { timeout => 10000, retries => 1 }, sub {});
$sqe->wait;

my $when_done_fired = 0;
$sqe->when_done("127.0.0.1", $dead_port, sub { $when_done_fired++ });

@events = ();
$sqe->get("127.0.0.1", $dead_port, ["1.3.6.1.2.1.1.5.0"], sub {
	my ($h, $ok, $r) = @_;
	push @events, "reply";
	ok !$ok, "in-flight request errors out on disconnect";
	like $r, qr/^connection lost: /, "error text carries the disconnect reason";
});
$t->kill_daemon;
$sqe->wait;
is scalar @events, 2, "only the disconnect hook and the in-flight callback fired";
like $events[0], qr/^disconnect: /, "on_disconnect fired with a reason";
is $events[1], "reply", "on_disconnect fired before the in-flight request errored";
is $when_done_fired, 1, "when_done fired when its last outstanding request errored";

# Requests issued while down are queued: their callbacks must not fire,
# and failed reconnect attempts must not re-fire on_disconnect.
@events = ();
my $queued_replies = 0;
for my $i (1 .. 3) {
	$sqe->get($host, $port, ["1.3.6.1.2.1.1.5.0"], sub {
		my ($h, $ok, $r) = @_;
		$queued_replies++;
		ok $ok, "queued request $i completed after reconnect";
		is $r->[0][1], "meow.example.net",
			"on_connect re-established options before queued request $i ran";
	});
}

my $cv = AnyEvent->condvar;
my $tick = AnyEvent->timer(after => 1, cb => sub { $cv->send });
$cv->recv;
is $queued_replies, 0, "requests issued while down did not fire";
is_deeply \@events, [], "no hooks fired while the daemon stayed down";

# After the daemon returns: on_connect first (its setopt re-establishes
# the community on the freshly restarted daemon), then the queue, FIFO.
# If the flush ran first, the gets would see the daemon default
# community "public" and return "public.example.net".
$t->restart_daemon;
$sqe->wait;
is $queued_replies, 3, "all queued requests completed after reconnect";
is_deeply \@events, ["connect"], "on_connect fired exactly once on reconnect";

# reconnect => 0: one disconnect kills the object for good.
undef $sqe;    # also exercises DESTROY with a live connection

my @events0;
my $sqe0 = Net::SNMP::QueryEngine::AnyEvent->new(
	connect       => ["127.0.0.1", $t->{daemon_port}],
	reconnect     => 0,
	on_connect    => sub { push @events0, "connect" },
	on_disconnect => sub {
		my ($h, $why) = @_;
		push @events0, "disconnect";
		$h->get($host, $port, ["1.3.6.1.2.1.1.5.0"], sub {
			my (undef, $ok, $r) = @_;
			push @events0, "hookreq";
			ok !$ok, "request issued from on_disconnect errors out";
			is $r, "not connected", "queued request flushed with \"not connected\"";
		});
	},
);

$sqe0->get($host, $port, ["1.3.6.1.2.1.1.5.0"], sub {
	my (undef, $ok, $r) = @_;
	push @events0, "ok-reply";
	ok $ok, "get succeeds before the daemon goes away";
});
$sqe0->setopt("127.0.0.1", $dead_port, { timeout => 10000, retries => 1 }, sub {});
$sqe0->wait;

$sqe0->get("127.0.0.1", $dead_port, ["1.3.6.1.2.1.1.5.0"], sub {
	my (undef, $ok, $r) = @_;
	push @events0, "inflight";
	ok !$ok, "in-flight request errors out on disconnect (reconnect => 0)";
	like $r, qr/^connection lost: /, "with the connection-lost error string";
});
$t->kill_daemon;
$sqe0->wait;
is_deeply \@events0, ["connect", "ok-reply", "disconnect", "inflight", "hookreq"],
	"disconnect hook, then in-flight errors, then the queue flushed to errors";

my $sync = 1;
$sqe0->get($host, $port, ["1.3.6.1.2.1.1.5.0"], sub {
	my (undef, $ok, $r) = @_;
	ok !$ok, "request issued after death fails";
	is $r, "not connected", "with the fail-fast error string";
	ok !$sync, "fail-fast callback fired from the event loop, not from cmd";
});
$sync = 0;
$sqe0->wait;

close $mute;
$t->stop;
done_testing;

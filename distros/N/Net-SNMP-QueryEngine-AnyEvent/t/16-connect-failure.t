#!perl
# ABOUTME: Characterization tests of a failed INITIAL connect from new(), with
# ABOUTME: no daemon ever running: queueing forever, and reconnect => 0 fail-fast.

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use AnyEvent;
use Test::More;
use Net::SNMP::QueryEngine::AnyEvent;
use SQETest;

# A hung event loop is the natural failure mode of reconnect bugs;
# turn hangs into test failures.
$SIG{ALRM} = sub { die "test timed out" };
alarm 60;

# A port that was briefly bound and then closed: nothing listens on it,
# so every connect attempt is refused, just like a daemon that never
# started.  The refusal reason AnyEvent::Handle reports is just "$!";
# it reads "Connection refused" on Linux, but a non-blocking connect()
# poll on macOS reports the same refusal as EINVAL ("Invalid argument").
my $dead_port = SQETest::free_port("tcp");
my $reason_re = qr/Connection refused|Invalid argument/;

# reconnect => 0.3: the initial connect fails, on_disconnect fires once,
# and repeated failed reconnect attempts must not re-fire it.  Requests
# issued while down are queued forever, since the daemon never appears.
my @eventsA;
my $sqeA = Net::SNMP::QueryEngine::AnyEvent->new(
	connect       => ["127.0.0.1", $dead_port],
	reconnect     => 0.3,
	on_connect    => sub { push @eventsA, "connect" },
	on_disconnect => sub { push @eventsA, "disconnect: $_[1]" },
);

my $queued_fired = 0;
$sqeA->get("127.0.0.1", $dead_port, ["1.3.6.1.2.1.1.5.0"], sub {
	$queued_fired++;
});

my $cv = AnyEvent->condvar;
my $tick = AnyEvent->timer(after => 1, cb => sub { $cv->send });
$cv->recv;

is $queued_fired, 0,
	"a request queued while down never fires while the daemon stays absent";
is scalar(@eventsA), 1,
	"on_disconnect fired exactly once despite several failed reconnect attempts"
	. " (this also proves on_connect never fired)";
like $eventsA[0], qr/^disconnect: (?:$reason_re)$/,
	"on_disconnect fired with the connect failure's reason";

undef $sqeA;

# reconnect => 0: the initial connect failing kills the object for good.
my @eventsB;
my $sqeB = Net::SNMP::QueryEngine::AnyEvent->new(
	connect       => ["127.0.0.1", $dead_port],
	reconnect     => 0,
	on_connect    => sub { push @eventsB, "connect" },
	on_disconnect => sub { push @eventsB, "disconnect: $_[1]" },
);

$sqeB->get("127.0.0.1", $dead_port, ["1.3.6.1.2.1.1.5.0"], sub {
	my (undef, $ok, $r) = @_;
	push @eventsB, "queued-reply";
	ok !$ok, "the get queued while connecting fails once the initial connect fails";
	is $r, "not connected", "queued request flushed with the exact \"not connected\" string";
});
$sqeB->wait;

is scalar(@eventsB), 2,
	"only on_disconnect and the queued request's failure fired";
like $eventsB[0], qr/^disconnect: (?:$reason_re)$/,
	"on_disconnect fired with the connect failure's reason";
is $eventsB[1], "queued-reply",
	"on_disconnect fired before the queued request's failure";

# The object is now dead: a brand new request must fail fast, but still
# asynchronously, never synchronously from within cmd()/get().
my $sync = 1;
$sqeB->get("127.0.0.1", $dead_port, ["1.3.6.1.2.1.1.5.0"], sub {
	my (undef, $ok, $r) = @_;
	push @eventsB, "dead-reply";
	ok !$ok, "a request issued after death fails";
	is $r, "not connected", "with the exact fail-fast error string";
	ok !$sync, "fail-fast callback fired from the event loop, not from cmd";
});
$sync = 0;
$sqeB->wait;

is scalar(@eventsB), 3, "the post-death request's callback fired exactly once";
is $eventsB[2], "dead-reply", "the post-death request failed after the earlier events";

done_testing;

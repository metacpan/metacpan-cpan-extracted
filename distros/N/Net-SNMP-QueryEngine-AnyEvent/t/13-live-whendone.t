#!perl
# ABOUTME: Live functional tests of when_done() semantics and of calling
# ABOUTME: wait() repeatedly, against snmp-query-engine + snmpsim.

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More;
use SQETest;

my $reason = SQETest::skip_reason();
plan skip_all => $reason if $reason;

my $t = SQETest->start;
my $sqe = $t->client;
my ($host, $port) = ($t->{agent_host}, $t->{agent_port});

my $completed = 0;
my @fired_at;
$sqe->when_done($host, $port, sub { push @fired_at, $completed });

for my $i (1 .. 3) {
	$sqe->get($host, $port, ["1.3.6.1.2.1.1.5.0"], sub {
		my ($h, $ok, $r) = @_;
		$completed++;
	});
}
is_deeply \@fired_at, [], "when_done does not fire before the event loop runs";
$sqe->wait;
is_deeply \@fired_at, [3],
	"when_done fired exactly once, after all three gets completed";
is $completed, 3, "all three get callbacks ran";

$sqe->get($host, $port, ["1.3.6.1.2.1.1.1.0"], sub {
	my ($h, $ok, $r) = @_;
	$completed++;
	is $r->[0][1], "SQE test agent", "get after wait() returns data";
});
$sqe->wait;
is_deeply \@fired_at, [3, 4],
	"wait() works again and when_done re-fires on the next drop to zero";

$t->stop;
done_testing;

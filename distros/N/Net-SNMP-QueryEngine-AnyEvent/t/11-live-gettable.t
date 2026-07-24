#!perl
# ABOUTME: Live functional tests of gettable() — both call forms and the
# ABOUTME: empty-result case — against snmp-query-engine + snmpsim.

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

$sqe->gettable($host, $port, "1.3.6.1.2.1.2.2.1.2", sub {
	my ($h, $ok, $r) = @_;
	ok $ok, "gettable (no max_rep) succeeds";
	is_deeply $r, [
		["1.3.6.1.2.1.2.2.1.2.1", "eth0"],
		["1.3.6.1.2.1.2.2.1.2.2", "eth1"],
		["1.3.6.1.2.1.2.2.1.2.3", "eth2"],
	], "all rows of the column, in order";
});
$sqe->wait;

# The ifInOctets column is the last subtree in the agent's MIB, so the
# walk runs into endOfMibView, which the daemon reports as a trailing
# non-increasing row for the last oid.
$sqe->gettable($host, $port, "1.3.6.1.2.1.2.2.1.10", 2, sub {
	my ($h, $ok, $r) = @_;
	ok $ok, "gettable with max_rep succeeds";
	is_deeply $r, [
		["1.3.6.1.2.1.2.2.1.10.1", 1000],
		["1.3.6.1.2.1.2.2.1.10.2", 2000],
		["1.3.6.1.2.1.2.2.1.10.3", 3000],
		["1.3.6.1.2.1.2.2.1.10.3", ["non-increasing"]],
	], "max_repetitions batching does not change the result";
});
$sqe->wait;

$sqe->gettable($host, $port, "1.3.6.1.2.1.1.5.0", sub {
	my ($h, $ok, $r) = @_;
	ok $ok, "gettable of a leaf oid succeeds";
	is_deeply $r, [], "empty array when nothing exists under the oid";
});
$sqe->wait;

$t->stop;
done_testing;

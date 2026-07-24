#!perl
# ABOUTME: Live functional tests of info() and dest_info() statistics
# ABOUTME: replies against snmp-query-engine + snmpsim.

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

$sqe->get($host, $port, ["1.3.6.1.2.1.1.5.0"], sub {
	my ($h, $ok, $r) = @_;
	ok $ok, "warm-up get succeeds";
});
$sqe->wait;

$sqe->info(sub {
	my ($h, $ok, $r) = @_;
	ok $ok, "info succeeds";
	is ref $r, "HASH", "info reply is a map";
	is ref $r->{connection}, "HASH", "connection stats present";
	is ref $r->{global}, "HASH", "global stats present";
	is $r->{connection}{get_requests}, 1,
		"connection stats counted this connection's single get";
	like $r->{global}{version}, qr/^\d+\.\d+\.\d+/,
		"global stats carry the daemon semver version";
	ok $r->{global}{uptime} > 0, "daemon uptime is positive";
});
$sqe->wait;

$sqe->dest_info(sub {
	my ($h, $ok, $r) = @_;
	ok $ok, "dest_info succeeds";
	is ref $r, "HASH", "dest_info reply is a map";
	ok $r->{octets_sent} > 0, "octets were sent to the destination";
	ok $r->{octets_received} > 0, "octets were received from it";
}, $host, $port);
$sqe->wait;

$t->stop;
done_testing;

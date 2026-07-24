#!perl
# ABOUTME: Live functional tests of setopt(), getopt() and get() against a
# ABOUTME: real snmp-query-engine daemon querying a snmpsim agent.

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

$sqe->setopt($host, $port, { community => "public" }, sub {
	my ($h, $ok, $r) = @_;
	ok $ok, "setopt succeeds";
	is ref $r, "HASH", "setopt reply is the option map";
	is $r->{community}, "public", "community round-trips";
});
$sqe->wait;

$sqe->getopt($host, $port, sub {
	my ($h, $ok, $r) = @_;
	ok $ok, "getopt succeeds";
	is ref $r, "HASH", "getopt reply is the option map";
	is $r->{community}, "public", "getopt returns the community set by setopt";
});
$sqe->wait;

$sqe->get($host, $port,
	["1.3.6.1.2.1.1.5.0", "1.3.6.1.2.1.1.1.0",
	 "1.3.6.1.2.1.2.2.1.10.2", "1.3.66"],
	sub {
		my ($h, $ok, $r) = @_;
		ok $ok, "get succeeds";
		is_deeply $r, [
			["1.3.6.1.2.1.1.5.0", "public.example.net"],
			["1.3.6.1.2.1.1.1.0", "SQE test agent"],
			["1.3.6.1.2.1.2.2.1.10.2", 2000],
			["1.3.66", ["no-such-instance"]],
		], "values in request order, per-oid error as single-element array";
	});
$sqe->wait;

$sqe->setopt($host, $port, { community => "meow" }, sub {
	my ($h, $ok, $r) = @_;
	ok $ok, "setopt community=meow succeeds";
	is $r->{community}, "meow", "changed community returned";
});
$sqe->wait;

$sqe->get($host, $port, ["1.3.6.1.2.1.1.5.0"], sub {
	my ($h, $ok, $r) = @_;
	ok $ok, "get with changed community succeeds";
	is $r->[0][1], "meow.example.net", "snmpsim served the meow dataset";
});
$sqe->wait;

$t->stop;
done_testing;

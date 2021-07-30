#!perl
use strict;
use warnings;
use lib qw(./lib t/lib);

use Test::More 0.88;
use Test::Exception;
use Test::Warnings;


# Test ServerInfo and report info on the connection with the server.

use Neo4j_Test;

plan tests => 3 + 1;


subtest 'full' => sub {
	plan tests => 6;
	my $info = {
		uri => URI->new('http://user:auth@localhost:14000/'),
		version => 'ServerInfo/0.0',
		protocol => '1.1',
		time_diff => -12,
	};
	my $si;
	lives_and { ok $si = Neo4j::Driver::ServerInfo->new($info) } 'new';
	lives_and { is $si->address(), 'localhost:14000' } 'address';
	lives_and { is $si->version(), $info->{version} } 'version';
	lives_and { is $si->agent(), $info->{version} } 'agent';
	lives_and { is $si->protocol_version(), $info->{protocol} } 'protocol_version';
	is $si->{time_diff}, -12, 'time_diff';
};


subtest 'partial' => sub {
	plan tests => 5;
	my $info = {
		uri => 'http://localhost:14000',
	};
	my $si;
	lives_and { ok $si = Neo4j::Driver::ServerInfo->new($info) } 'new';
	lives_and { is $si->address(), 'localhost:14000' } 'address';
	lives_and { is $si->version(), $info->{version} } 'version';
	lives_and { is $si->agent(), $info->{version} } 'agent';
	lives_and { is $si->protocol_version(), $info->{protocol} } 'protocol_version';
};


# Report the Network error if there is one (to aid debugging).
my $driver;
unless ( $ENV{NO_NETWORK_TESTING} or $driver = Neo4j_Test->driver() ) {
	diag $Neo4j_Test::error;
}
my $session = eval { $driver->session(database => 'system') };


subtest 'live ServerInfo' => sub {
	plan skip_all => "(no session)" unless $session;
	plan tests => 8;
	my $server;
	lives_and { ok $server = $session->server } 'get ServerInfo';
	isa_ok $server, 'Neo4j::Driver::ServerInfo', 'ServerInfo';
	lives_and { my $a = Neo4j_Test->server_address(); like($server->address(), qr/$a$/) } 'server address';
	my ($vinfo, $protocol, $result) = ("") x 3;
	lives_and { ok $vinfo = $server->agent } 'server version';
	like $vinfo, qr(^Neo4j/\d+\.\d+\.\d), 'server version syntax';
	lives_ok { $protocol = $server->protocol_version; } 'server protocol';
	is defined($protocol), !! $Neo4j_Test::bolt, 'protocol kind';
	SKIP: {
		skip 'for HTTP', 1 unless $Neo4j_Test::bolt;
		like $protocol, qr/^(?:[0-9]+\.[0-9]+)?$/, 'protocol version (Bolt)';
	}
	
	# give feedback about which Neo4j version is being tested
	$protocol = $protocol ? "Bolt/$protocol" : defined $protocol ? "Bolt" : "HTTP";
	eval {
		$session->run('SHOW DEFAULT DATABASE');
		my $media_type = $session->{net}->{http_agent}->http_header->{content_type};
		$protocol = "JSON" if $media_type =~ m/\bjson\b/i;
		$protocol = "Jolt" if $media_type =~ m/\bjolt\b/i;
		$protocol = "Jolt ndjson" if $media_type =~ m/\bjolt\b(?!\+json-seq\b)/i;
		$protocol = "Jolt sparse" if $media_type =~ m/\bjolt\b.+\bstrict=false\b/i;
		$protocol = "Jolt strict" if $media_type =~ m/\bjolt\b.+\bstrict=true\b/i;
		$protocol .= " Sim" if $Neo4j_Test::sim;
	};
	$vinfo .= " ($protocol)";
	diag $vinfo if $ENV{AUTHOR_TESTING};
};


done_testing;

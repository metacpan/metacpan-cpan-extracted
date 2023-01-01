#!perl
use strict;
use warnings;
use lib qw(./lib t/lib);

use Test::More 0.88;
use Test::Exception;
use Test::Warnings;


# Test ServerInfo and report info on the connection with the server.

use Neo4j_Test;
use Neo4j_Test::MockHTTP;

plan tests => 4 + 1;


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


subtest 'default database' => sub {
	plan tests => 3 + 3 + 10;
	my ($d, $s, $si, $db);
	
	lives_ok { $d = 0; $d = Neo4j::Driver->new('http:')->plugin('Neo4j_Test::MockHTTP') } 'driver 1';
	lives_ok { $si = 0; $si = $d->session(database => 'dummy')->server } 'ServerInfo 1';
	throws_ok { $si->_default_database($d) } qr/\bdefault database\b/i, 'default database failed';
	
	$Neo4j_Test::MockHTTP::res[0]->{json}{neo4j_version} = '3.5.0';
	$Neo4j_Test::MockHTTP::res[0]->{content} = undef;
	lives_ok { $d = 0; $d = Neo4j::Driver->new('http:')->plugin('Neo4j_Test::MockHTTP') } 'driver 2';
	lives_ok { $si = 0; $si = $d->session->server } 'ServerInfo 2';
	lives_and { is $si->_default_database($d), undef } 'no default database';
	$Neo4j_Test::MockHTTP::res[0]->{json}{neo4j_version} = '4.2.5';
	$Neo4j_Test::MockHTTP::res[0]->{content} = undef;
	
	Neo4j_Test::MockHTTP::response_for 'SHOW DEFAULT DATABASE' => { jolt => [
		{ header => { fields => ['name'] } },
		{ data => [ { 'U' => 'mock' } ] },
		{ summary => {} },
		{ info => {} },
	]};
	lives_ok { $d = 0; $d = Neo4j::Driver->new('http:')->plugin('Neo4j_Test::MockHTTP') } 'driver 3';
	lives_ok { $si = 0; $si = $d->session(database => 'dummy')->server } 'ServerInfo 3';
	isa_ok $si, 'Neo4j::Driver::ServerInfo', 'ServerInfo type';
	is $si->{default_database}, undef, 'default database not cached';
	lives_ok { $db = $si->_default_database($d) } 'default database mock lives';
	is $db, 'mock', 'default database mock';
	is $si->{default_database}, $db, 'default database mock cached';
	$si->{default_database} = 'cache';
	# corrupt the mocked server response to verify that the server is NOT queried again
	my $res = $#Neo4j_Test::MockHTTP::res;
	$Neo4j_Test::MockHTTP::res[$res]->{jolt}[1]{data} = {'dead beef' => 1};
	$Neo4j_Test::MockHTTP::res[$res]->{content} = undef;
	lives_ok { $si = 0; $si = $d->session->server } 'ServerInfo cache lives';
	lives_ok { $db = $si->_default_database($d) } 'default database cache lives';
	is $db, 'cache', 'default database cache';
};


# Report the Network error if there is one (to aid debugging).
my $driver;
unless ( $ENV{NO_NETWORK_TESTING} or $driver = Neo4j_Test->driver() ) {
	diag $Neo4j_Test::error;
}
my $session = eval { $driver->session(database => 'system') };


subtest 'live ServerInfo' => sub {
	plan skip_all => "(no session)" unless $session;
	plan tests => 7;
	my $server;
	lives_and { ok $server = $session->server } 'get ServerInfo';
	isa_ok $server, 'Neo4j::Driver::ServerInfo', 'ServerInfo';
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
		$protocol = "Jolt ndjson" if $media_type =~ m/\bjolt\b/i && $media_type !~ m/\+json-seq\b/i;
		$protocol = "Jolt sparse" if $media_type =~ m/\bjolt\b.+\bstrict=false\b/i;
		$protocol = "Jolt strict" if $media_type =~ m/\bjolt\b.+\bstrict=true\b/i;
		$protocol =~ s/Jolt/Jolt v2/ if $media_type =~ m/\bjolt-v2\b/i;
		$protocol .= " Sim" if $Neo4j_Test::sim;
	};
	$vinfo .= " ($protocol)";
	diag $vinfo if $ENV{AUTHOR_TESTING};
};


done_testing;

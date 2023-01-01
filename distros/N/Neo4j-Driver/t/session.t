#!perl
use strict;
use warnings;
use lib qw(./lib t/lib);

my $driver;
use Neo4j_Test;
BEGIN {
	unless ( $driver = Neo4j_Test->driver() ) {
		print qq{1..0 # SKIP no connection to Neo4j server\n};
		exit;
	}
}


# The following tests pertain to database sessions.

use Test::More 0.96 tests => 3 + 1;
use Test::Exception;
use Test::Warnings;


my ($s);


subtest 'ServerInfo' => sub {
	plan tests => 3;
	my ($session, $server);
	lives_ok { $session = $driver->session(database => 'system') } 'get session';
	lives_and { ok $server = $session->server } 'get ServerInfo';
	isa_ok $server, 'Neo4j::Driver::ServerInfo', 'isa ServerInfo';
};


subtest 'database selection (HTTP)' => sub {
	plan skip_all => "(currently testing Bolt)" if $Neo4j_Test::bolt;
	plan tests => 9;
	my ($version, $db);
	# no database option (or undefined)
	lives_ok { $s = 0; $s = $driver->session( database => undef ); } 'default lives';
	($version) = $s->server->version =~ m(Neo4j/([0-9]+)\.)i;
	ok defined $version, 'version number';
	if ($version >= 4) {
		# this test assumes that the default database is always named neo4j
		# (which is probably reasonable for the community edition)
		like $s->{net}->{endpoints}->{new_transaction}, qr(/db/neo4j/tx$), 'default selected';
	}
	else {
		like $s->{net}->{endpoints}->{new_transaction}, qr(/db/data/transaction$), 'default ignored';
	}
	# database specified
	$db = 'foofoo';
	lives_ok { $s = 0; $s = $driver->session( database => $db ); } 'specified lives';
	if ($version >= 4) {
		like $s->{net}->{endpoints}->{new_transaction}, qr(/db/${db}/tx$), 'specified selected';
	}
	else {
		like $s->{net}->{endpoints}->{new_transaction}, qr(/db/data/transaction$), 'specified ignored';
	}
	# database doesn't exist
	$db = " /\N{U+1F600}";
	lives_ok { $s = 0; $s = $driver->session( database => $db ); } 'nonexistent lives';
	if ($version >= 4) {
		throws_ok {
			 $s->run('');
		} qr/\bHTTP error: 404 Not Found\b/i, 'nonexistent dies';
	}
	else {
		like $s->{net}->{endpoints}->{new_transaction}, qr(/db/data/transaction$), 'nonexistent ignored';
	}
	# database not a scalar
	lives_ok { $s = 0; $s = $driver->session( database => [] ); } 'arrayref lives';
	if ($version >= 4) {
		throws_ok {
			 $s->run('');
		} qr/\bHTTP error: 404 Not Found\b/i, 'arrayref dies';
	}
	else {
		like $s->{net}->{endpoints}->{new_transaction}, qr(/db/data/transaction$), 'arrayref ignored';
	}
};


subtest 'error handling' => sub {
	# These tests are of questionable utility and seem to bring more trouble
	# than they're worth. Perhaps it would be best to remove them entirely.
	plan skip_all => "(subtest not supported with Neo4j::Bolt)" if $Neo4j_Test::bolt;
	throws_ok {
		Neo4j_Test->driver_no_connect->session->run('');
	} qr/\bConnection refused\b|\bCan't connect\b|\bUnknown host\b/i, 'no connection';
	return unless $Neo4j_Test::sim || $ENV{TEST_NEO4J_PASSWORD};  # next test requires a real or simulated server with auth enabled
	throws_ok {
		Neo4j_Test->driver_no_auth->session->run('');
	} qr/\bUnauthorized\b|\bpassword is invalid\b/, 'Unauthorized';
};


done_testing;

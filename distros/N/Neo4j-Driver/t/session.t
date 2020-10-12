#!perl
use strict;
use warnings;
use lib qw(./lib t/lib);

my $driver;
use Neo4j::Test;
BEGIN {
	unless ($driver = Neo4j::Test->driver) {
		print qq{1..0 # SKIP no connection to Neo4j server\n};
		exit;
	}
}


# The following tests pertain to database sessions.

use Test::More 0.96 tests => 3;
use Test::Exception;


my ($s);


subtest 'ServerInfo' => sub {
	plan tests => 4;
	my $server;
	lives_ok { $server = $driver->session->server } 'get ServerInfo';
	isa_ok $server, 'Neo4j::Driver::ServerInfo', 'isa ServerInfo';
	lives_and { my $a = $server->address; like(Neo4j::Test->server_address, qr/$a/) } 'server address';
	like $server->version, qr(^Neo4j/\d+\.\d+\.\d), 'server version syntax';
	diag $server->version if $ENV{AUTHOR_TESTING};  # give feedback about which Neo4j version is being tested
};


subtest 'database selection' => sub {
	# Neo4j::Driver::Transport::Bolt doesn't yet support
	# version 4.0, so there is no database selection.
	plan skip_all => "(test requires HTTP)" if $Neo4j::Test::bolt;
	plan tests => 9;
	my ($version, $db);
	# no database option (or undefined)
	lives_ok { $s = 0; $s = $driver->session( database => undef ); } 'default lives';
	($version) = $s->server->version =~ m(Neo4j/([0-9]+)\.)i;
	ok defined $version, 'version number';
	if ($version >= 4) {
		# this test assumes that the default database is always named neo4j
		# (which is probably reasonable for the community edition)
		TODO: { local $TODO = 'default database unimplemented';
		like $s->{transport}->{endpoints}->{new_transaction}, qr(/db/neo4j/tx$), 'default selected';
		}
	}
	else {
		like $s->{transport}->{endpoints}->{new_transaction}, qr(/db/data/transaction$), 'default ignored';
	}
	# database specified
	$db = 'foofoo';
	lives_ok { $s = 0; $s = $driver->session( database => $db ); } 'specified lives';
	if ($version >= 4) {
		like $s->{transport}->{endpoints}->{new_transaction}, qr(/db/${db}/tx$), 'specified selected';
	}
	else {
		like $s->{transport}->{endpoints}->{new_transaction}, qr(/db/data/transaction$), 'specified ignored';
	}
	# database doesn't exist
	$db = " /\N{U+1F600}";
	lives_ok { $s = 0; $s = $driver->session( database => $db ); } 'nonexistent lives';
	if ($version >= 4) {
		throws_ok {
			 $s->run('');
		} qr/\bNetwork error: 404 Not Found\b/i, 'nonexistent dies';
	}
	else {
		like $s->{transport}->{endpoints}->{new_transaction}, qr(/db/data/transaction$), 'nonexistent ignored';
	}
	# database not a scalar
	lives_ok { $s = 0; $s = $driver->session( database => [] ); } 'arrayref lives';
	if ($version >= 4) {
		throws_ok {
			 $s->run('');
		} qr/\bNetwork error: 404 Not Found\b/i, 'arrayref dies';
	}
	else {
		like $s->{transport}->{endpoints}->{new_transaction}, qr(/db/data/transaction$), 'arrayref ignored';
	}
};


subtest 'error handling' => sub {
	
	# this really just tests Neo4j::Driver
	throws_ok {
		Neo4j::Test->driver_no_host->session->run('');
	} qr/\bCan't connect\b|\bUnknown host\b/i, 'no connection';
	throws_ok {
		Neo4j::Test->driver_no_auth->session->run('');
	} qr/\bUnauthorized\b|\bpassword is invalid\b/, 'Unauthorized';
};


done_testing;

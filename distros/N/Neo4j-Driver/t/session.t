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
my $s = $driver->session;


# The following tests are for details of the Session class.

use Test::More 0.96 tests => 2;
use Test::Exception;


subtest 'ServerInfo' => sub {
	plan tests => 3;
	lives_and { my $a = $s->server->address; like(Neo4j::Test->server_address, qr/$a/) } 'server address';
	my $neo4j_version;
	lives_ok { $neo4j_version = $s->server->version } 'get server version';
	like $neo4j_version, qr(^Neo4j/\d+\.\d+\.\d), 'server version syntax';
	diag $neo4j_version if $ENV{AUTHOR_TESTING};  # give feedback about which Neo4j version is being tested
};


subtest 'error handling' => sub {
	
	# this really just tests Neo4j::Driver
	throws_ok {
		Neo4j::Test->driver_maybe->basic_auth('nobody', '')->session->begin_transaction->run('RETURN 42');
	} qr/\bUnauthorized\b/, 'Unauthorized';
};


done_testing;

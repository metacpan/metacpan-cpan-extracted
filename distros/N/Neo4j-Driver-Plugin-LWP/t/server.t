#!perl
use strict;
use warnings;
use lib 'lib';

use Test::More 0.88;
use Test::Warnings 0.010 qw(:no_end_test);
my $no_warnings;
use if $no_warnings = $ENV{AUTHOR_TESTING} ? 1 : 0, 'Test::Warnings';

use Neo4j::Driver::Plugin::LWP;
use Neo4j::Driver 0.34;
use Scalar::Util 'blessed';

plan skip_all => 'network tests not requested' if $ENV{NO_NETWORK_TESTING};

plan skip_all => 'no credentials specified for live server test'
	unless length( my $server = $ENV{TEST_NEO4J_SERVER} // 'http:' )
	&& length( my $username = $ENV{TEST_NEO4J_USERNAME} // 'neo4j' )
	&& length( my $password = $ENV{TEST_NEO4J_PASSWORD} // '' );

sub driver { Neo4j::Driver->new($server)->basic_auth($username, $password) }

plan skip_all => 'no live server connection' unless eval { driver()->session };

plan tests => 4 + 2 + $no_warnings;

ok my $plugin = Neo4j::Driver::Plugin::LWP->new, 'plug-in';
ok my $driver = driver()->config(cypher_params => v2)->plugin($plugin), 'driver';
ok my $session = $driver->session, 'session';

my $lwp = 'The World-Wide Web library for Perl';
is $session->run('RETURN {LWP}', LWP => $lwp)->single->get, $lwp, 'echo';

SKIP: {
	# To check whether registering the plug-in was successful, we need to use
	# private driver internals to retrieve a reference to the net adapter.
	# This may break with future driver versions.
	skip 'looks like driver internals have changed', 2
		unless blessed( my $net = eval { $session->{net}->{http_agent} } );
	
	isa_ok $net, 'Neo4j::Driver::Net::HTTP::LWP', 'net adapter';
	is $net->VERSION, $plugin->VERSION, 'loaded net adapter version matches plug-in version';
}

done_testing;

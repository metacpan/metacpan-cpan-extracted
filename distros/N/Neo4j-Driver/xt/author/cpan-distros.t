#!perl
use strict;
use warnings;
use lib qw(./lib t/lib);

use Test::More 0.94;
use Test::Exception;
use Test::Warnings 0.010 qw(warning :no_end_test);
my $no_warnings;
use if $no_warnings = $ENV{AUTHOR_TESTING} ? 1 : 0, 'Test::Warnings';


# The purpose of these tests is to help prevent any change to the
# driver causing breakage for CPAN modules that are known to depend
# on it -- or at least catch any such issues early.
# Note that these tests are only intended to capture serious/obvious
# issues with a few very basic uses cases. They do not by any means
# replace the test suites of those other modules.

# Also note that CPAN modules which require a specific version of the
# driver can only be successfully tested after the driver distro has
# been built. For example:
#  dzil run 'prove -v xt/author/cpan-distros.t'

use Neo4j_Test;

my $driver = $ENV{NO_NETWORK_TESTING} ? 0 : Neo4j_Test->driver();
my $neo4j_ver = $driver && $driver->session->server->version;
plan skip_all => "no connection to Neo4j server" unless $driver && ! $Neo4j_Test::sim;
plan skip_all => "Neo4j server version too old" if $neo4j_ver =~ m{^Neo4j/[12]\.};

plan tests => 1 + $no_warnings;


subtest 'REST::Neo4p' => sub {
	plan skip_all => "REST::Neo4p unavailable" unless eval "require REST::Neo4p; 1";
	plan skip_all => "REST::Neo4p version too old" unless eval "REST::Neo4p->VERSION('0.4003')";
	plan tests => 11;
	
	lives_and {
		no warnings 'once';
		$REST::Neo4p::AGENT_MODULE = 'Neo4j::Driver';
		$REST::Neo4p::Agent::RQ_RETRIES = 0;
		REST::Neo4p->agent( timeout => 2 );
		REST::Neo4p->connect( $driver->config('uri'), $Neo4j_Test::user, $Neo4j_Test::pass );
		isa_ok( REST::Neo4p->agent(), 'REST::Neo4p::Agent::Neo4j::Driver', 'agent' );
	} 'connect';
	
	lives_and {
		my $q = REST::Neo4p::Query->new('RETURN 42');
		$q->execute;
		is $q->fetch->[0], 42;
	} 'query execute';
	
	lives_and {
		my $q = REST::Neo4p::Query->new('RETURN $i');
		$q->execute( i => 'foo' );
		is $q->fetch->[0], 'foo';
	} 'query param';
	
	my $node;
	lives_ok {
		my $q = REST::Neo4p::Query->new('MATCH (n) RETURN n LIMIT 1');
		$q->execute;
		my $row; warning { $row = $q->fetch };  # Ignore possible deprecation warning on Neo4j 5
		$node = $row->[0] if $row;
	} 'query match node';
	SKIP: {
		skip 'no node matched; database may be empty', 1 unless defined $node;
		isa_ok $node, 'REST::Neo4p::Node', 'node';
	}
	
	my $path;
	lives_ok {
		my $q = REST::Neo4p::Query->new('MATCH p=()--() RETURN p LIMIT 1');
		$q->execute;
		my $row; warning { $row = $q->fetch };  # Ignore possible deprecation warning on Neo4j 5
		$path = $row->[0] if $row;
	} 'query match path';
	SKIP: {
		skip 'no path matched; database may be empty', 5 unless defined $path;
		isa_ok $path, 'REST::Neo4p::Path', 'path';
		my @r;
		lives_ok { @r = $path->relationships } 'path relationships';
		is scalar(@r), 1, 'path length';
		isa_ok $r[0], 'REST::Neo4p::Relationship', 'relationship';
		lives_and { isnt $r[0]->type, undef } 'relationship type';
	}
};


done_testing;

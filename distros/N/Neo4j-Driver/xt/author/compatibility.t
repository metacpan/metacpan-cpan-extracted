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


# The purpose of these tests is to verify that whatever we provide for
# compatibility with related modules like REST::Neo4p works as it should.
# (So far, we provide very little.)

use Test::More 0.96 tests => 1 + 1;
use Test::Exception;
use Test::Warnings;
use REST::Neo4p;
use Neo4j::Cypher::Abstract;


my ($q);


subtest 'query acceptance' => sub {
	plan tests => 2;
	$q = REST::Neo4p::Query->new('RETURN 42');
	lives_and { is $s->run($q)->single->get, 42 } 'REST::Neo4p::Query';
	$q = Neo4j::Cypher::Abstract->new->return(42);
	lives_and { is $s->run($q)->single->get, 42 } 'Neo4j::Cypher::Abstract';
};


done_testing;

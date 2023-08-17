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
my $s = $driver->session;


# The purpose of these tests is to verify that whatever we provide for
# compatibility with related modules like REST::Neo4p works as it should.
# (So far, we provide very little.)

use Test::More 0.94;
use Test::Exception;
use Test::Warnings 0.010 qw(:no_end_test);
my $no_warnings;
use if $no_warnings = $ENV{AUTHOR_TESTING} ? 1 : 0, 'Test::Warnings';

plan tests => 2 + $no_warnings;


my ($q);


subtest 'query acceptance REST::Neo4p' => sub {
	plan skip_all => "(REST::Neo4p unavailable)" unless eval "require REST::Neo4p; 1";
	plan tests => 1;
	$q = REST::Neo4p::Query->new('RETURN 42');
	lives_and { is $s->run($q)->single->get, 42 } 'REST::Neo4p::Query';
};


subtest 'query acceptance Neo4j::Cypher::Abstract' => sub {
	plan skip_all => "(Neo4j::Cypher::Abstract unavailable)" unless eval "require Neo4j::Cypher::Abstract; 1";
	plan tests => 1;
	$q = Neo4j::Cypher::Abstract->new->return(42);
	lives_and { is $s->run($q)->single->get, 42 } 'Neo4j::Cypher::Abstract';
};


done_testing;

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


# The purpose of these tests is to check the behaviour of the Result
# class, particularly for input that is legal, but unusual -- for example,
# due to coding errors on the client's part.

use Test::More 0.96 tests => 13 + 2;
use Test::Exception;
use Test::Warnings;
my $transaction = $driver->session->begin_transaction;
$transaction->{return_stats} = 0;  # optimise sim


my ($q, $r, $v, @a);


subtest 'result with no statement' => sub {
	plan tests => 2;
	# It is legal to run zero statements, in which case the run method,
	# which normally gives one Result object each for every
	# statement run, must produce an empty Result object for a
	# statement that never existed. This ensures a safe interface that
	# doesn't unexpectedly blow up in the client's face.
	lives_and { is $s->run->size, 0 } 'no query';
	lives_and { is $s->run('')->size, 0 } 'empty query';
};


subtest 'keys()' => sub {
	plan tests => 2;
	my @r = $s->run('RETURN 1 AS one, 2 AS two')->keys;
	is $r[0], 'one', 'key 1';
	is $r[1], 'two', 'key 2';
};


subtest 'stream interface: zero rows' => sub {
	plan tests => 3;
	$r = $s->run('RETURN 0 LIMIT 0');
	lives_and { ok ! $r->has_next } 'no has next before';
	lives_and { is $r->fetch, undef } 'fetch undef';
	lives_and { ok ! $r->has_next } 'no has next after';
};


subtest 'stream interface: one row' => sub {
	plan tests => 5;
	$r = $s->run('RETURN 42');
	lives_and { ok $r->has_next } 'has next before';
	lives_ok { $v = 0;  $v = $r->fetch } 'fetch single row';
	isa_ok $v, 'Neo4j::Driver::Record', 'fetch: confirmed record';
	lives_and { ok ! $r->has_next } 'no has next after';
	lives_and { is $r->fetch(), undef } 'fetch no second row';
};


subtest 'stream interface: more rows' => sub {
	plan tests => 5;
	$r = $s->run('RETURN 7 AS n UNION RETURN 11 AS n');
	lives_and { ok $r->fetch } 'fetch first row';
	lives_and { ok $r->has_next } 'has next before second';
	lives_and { ok $r->fetch } 'fetch second row';
	lives_and { ok ! $r->has_next } 'no has next after second';
	lives_and { is $r->fetch(), undef } 'fetch no third row';
};


$Neo4j::Driver::Result::fake_attached = 1;
$Neo4j::Driver::Result::Bolt::gather_results = 1;
subtest 'stream interface: fake attached' => sub {
	plan tests => 5;
	$r = $s->run('RETURN 7 AS n UNION RETURN 11 AS n');
	lives_and { ok $r->fetch } 'fetch first row';
	lives_and { ok $r->has_next } 'has next before second';
	lives_and { ok $r->fetch } 'fetch second row';
	lives_and { ok ! $r->has_next } 'no has next after second';
	lives_and { is $r->fetch(), undef } 'fetch no third row';
};
$Neo4j::Driver::Result::fake_attached = 0;
$Neo4j::Driver::Result::Bolt::gather_results = 0;


subtest 'list interface: zero rows' => sub {
	plan tests => 3;
	$r = $s->run('RETURN 0 LIMIT 0');
	lives_and { is $r->size, 0 } 'size no rows';
	lives_and { is_deeply scalar [ $r->list ], [] } 'list no rows';
	throws_ok { $r->single; } qr/\bexactly one\b/i, 'single called with 0 records';
};


subtest 'list interface: one row' => sub {
	plan tests => 8;
	$r = $s->run('RETURN 42');
	lives_ok { @a = ();  @a = $r->list } 'list';
	is scalar(@a), 1, 'list one row';
	isa_ok $a[0], 'Neo4j::Driver::Record', 'list: confirmed record';
	lives_and { is $r->size, 1 } 'size one row';
	my $single;
	lives_ok { $single = $r->single } 'single';
	isa_ok $single, 'Neo4j::Driver::Record', 'single called with 1 record';
	lives_ok { $v = 0;  $v = $r->single } 'single again';
	is_deeply $single, $v, 'single matches';
};


subtest 'list interface: more rows' => sub {
	plan tests => 7;
	$r = $s->run('RETURN 7 AS n UNION RETURN 11 AS n');
	lives_and { is $r->size, 2 } 'size two rows';
	my @list;
	lives_ok { @list = $r->list } 'list';
	is scalar @list, 2, 'list two rows';
	isa_ok $list[0], 'Neo4j::Driver::Record', 'list: confirmed record';
	throws_ok { $r->single; } qr/\bexactly one\b/i, 'single called with 2+ records';
	lives_ok { @a = ();  @a = $r->list } 'list again';
	is_deeply [@a], [@list], 'lists match';
};


$Neo4j::Driver::Result::fake_attached = 1;
$Neo4j::Driver::Result::Bolt::gather_results = 1;
subtest 'list interface: fake attached' => sub {
	plan tests => 7;
	$r = $s->run('RETURN 7 AS n UNION RETURN 11 AS n');
	lives_and { is $r->size, 2 } 'size two rows';
	my @list;
	lives_ok { @list = $r->list } 'list';
	is scalar @list, 2, 'list two rows';
	isa_ok $list[0], 'Neo4j::Driver::Record', 'list: confirmed record';
	throws_ok { $r->single; } qr/\bexactly one\b/i, 'single called with 2+ records';
	lives_ok { @a = ();  @a = $r->list } 'list again';
	is_deeply [@a], [@list], 'lists match';
};
$Neo4j::Driver::Result::fake_attached = 0;
$Neo4j::Driver::Result::Bolt::gather_results = 0;


subtest 'list interface: arrayref in scalar context' => sub {
	plan tests => 4;
	$q = 'RETURN 7 AS n UNION RETURN 11 AS n';
	lives_ok { $v = 0;  $v = $s->run($q)->list; } 'get records';
	is ref $v, 'ARRAY', 'get records as array';
	lives_and { is $v->[0]->get('n'), 7; } 'get record 0 in record array';
	lives_and { is $v->[1]->get('n'), 11; } 'get record 1 in record array';
};


subtest 'list/stream interface mixed' => sub {
	plan tests => 11;
	$r = $s->run('RETURN 7 AS n UNION RETURN 11 AS n');
	# fetch first row
	lives_ok { $v = 0;  $v = $r->fetch } 'fetch first row';
	lives_and { is $v->get('n'), 7 } 'fetched first row value';
	lives_and { ok $r->has_next } 'has next after first';
	# get remainder with single() (exhausts stream)
	lives_ok { $v = 0;  $v = $r->single } 'single called with 1 record remaining';
	lives_and { is $v->get('n'), 11 } 'fetched second row value: single';
	# try fetching second row (fails)
	lives_and { ok ! $r->has_next } 'no has next after list';
	lives_and { is $r->fetch(), undef } 'fetch no next row';
	# get list() of remainder (buffered)
	lives_ok { @a = ();  @a = $r->list } 'list';
	lives_and { is $a[0]->get('n'), 11 } 'fetched second row value: list';
	lives_and { is scalar @a, 1 } 'list size 1';
	lives_and { is $r->size, 1 } 'result size 1';
};


subtest 'cypher collect()' => sub {
	plan tests => 3;
	# see https://github.com/majensen/rest-neo4p/issues/18
	my $q1 = <<END;
CREATE (a:Test)-[:TEST{test:true}]->(:Test)
RETURN id(a)
END
	my $q2 = <<END;
MATCH (p:Test)-[r]-(o) WHERE id(p) = {id}
RETURN collect(r.void)
END
	my $q3 = <<END;
MATCH (p:Test)-[r]-(o) WHERE id(p) = {id}
RETURN collect(r.test)
END
	my %id;
	lives_ok { %id = (id => $transaction->run($q1)->single->get) } 'create and get id';
	lives_and { is scalar @{ $transaction->run($q2, %id)->single->get }, 0 } 'collect void';
	lives_and { ok $transaction->run($q3, %id)->single->get->[0] } 'collect true';
};


CLEANUP: {
	lives_ok { $transaction->rollback } 'rollback';
}


done_testing;

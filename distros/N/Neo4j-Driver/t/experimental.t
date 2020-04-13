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


# This software's interface has not yet stabilised. It currently has
# features that are not documented and may not exist in future
# versions. The following tests should be either removed along with
# those features or moved elsewhere once the features are documented
# and thus officially supported.

use Test::More 0.96 tests => 13;
use Test::Exception;
use Test::Warnings qw(warnings :no_end_test);


my ($q, $r, @a, $a);


subtest 'wantarray' => sub {
	plan tests => 17;
	$q = <<END;
RETURN 7 AS n UNION RETURN 11 AS n
END
	lives_ok { @a = $s->run($q); } 'get result as list';
	lives_and { is $a[0]->get('n'), 7; } 'get record 0 in result list';
	lives_and { is $a[1]->get('n'), 11; } 'get record 1 in result list';
	lives_ok { $a = $s->run($q)->keys; } 'get keys as array';
	lives_and { is $a->[0], 'n'; } 'get record 0 in keys array';
	
	# notifications
	lives_ok { $a = 0;  $a = $s->run($q)->summary->notifications; } 'no notifications';
	lives_and { is $a, undef; } 'no notifications array size';
	$q = <<END;
EXPLAIN MATCH (n), (m) RETURN n, m
END
	lives_ok { $r = 0;  $r = $s->run($q)->summary; } 'get summary';
	lives_ok { @a = ();  @a = $r->notifications; } 'get notifications list';
	SKIP: { skip 'no notifications', 2 unless @a;
		lives_ok { $a = 0;  $a = $r->notifications; } 'get notifications array';
		lives_and { is scalar @$a, 1; } 'get notifications array size';
	}
	
	# type objects
	my $tx = $driver->session->begin_transaction;
	$tx->{return_stats} = 0;  # optimise sim
	$q = <<END;
CREATE p=(a:Test:Want:Array)-[:TEST]->(c)
RETURN p, a
END
	lives_ok { $r = $tx->run($q)->single; } 'get type objects';
	throws_ok {
		 $a = $r->get('p')->nodes;
	} qr/\bscalar context\b.*\bnot supported\b/i, 'get path nodes as scalar';
	throws_ok {
		 $a = $r->get('p')->relationships;
	} qr/\bscalar context\b.*\bnot supported\b/i, 'get path rels as scalar';
	throws_ok {
		 $a = $r->get('a')->labels;
	} qr/\bscalar context\b.*\bnot supported\b/i, 'get node labels as scalar';
	
	# multiple statements; see below
	SKIP: { skip '(test requires HTTP)', 2 if $Neo4j::Test::bolt;
	$q = [
		['RETURN 7'],
		['RETURN 11'],
	];
	lives_ok { @a = $s->run($q) } 'run two statements at once';
	lives_and { is $a[0]->single->get * $a[1]->single->get, 7 * 11 } 'retrieve values';
	}
};


subtest 'multiple statements as array' => sub {
	# the official drivers don't offer this capability to clients
	plan skip_all => "(test requires HTTP)" if $Neo4j::Test::bolt;
	plan tests => 7;
	$q = [
		['RETURN 17'],
		['RETURN {n}', n => 19],
		['RETURN {n}', {n => 53}],
	];
	lives_ok { $r = $s->run($q) } 'run three statements at once';
	lives_and { is $r->[0]->single->get, 17 } 'retrieve 1st value';
	lives_and { is $r->[1]->single->get, 19 } 'retrieve 2nd value';
	lives_and { is $r->[2]->single->get, 53 } 'retrieve 3rd value';
#	diag explain $r;
	TODO: {
		local $TODO = 'non-multidimensional arrays should fail with own error message';
		$q = [
			'RETURN 42',
		];
		throws_ok {
			 $r = $s->run($q);
		} qr/multiple statements must each be ARRAY refs/i, 'non-arrayref individual statement';
	};
	TODO: {
		local $TODO = 'arrays that include empty statements should fail with own error message';
		$q = [
			[''],
			['RETURN 23'],
		];
		lives_ok { $r = $s->run($q) } 'include empty statement';
		lives_and { is $r->[1]->single->get, 23 } 'retrieve value';
		# TODO: also check statement order in summary
	};
};


subtest 'database selection' => sub {
	plan tests => 5;
	my ($dx, $sx);
	lives_ok { $dx = 0; $dx = Neo4j::Driver->new(); } 'new driver';
	lives_ok { $sx = 0; $sx = $dx->session(); } 'new session, default db';
	is $sx->{transport}->{endpoints}->{new_transaction}, "/db/data/transaction", 'default tx endpoint';
	my $db = 'fortytwo';
	lives_ok { $sx = 0; $sx = $dx->session(database => $db); } 'new session, custom db';
	is $sx->{transport}->{endpoints}->{new_transaction}, "/db/$db/tx", 'custom tx endpoint';
};


subtest 'result stream interface: attachment' => sub {
	plan tests => 5;
	$r = $s->run('RETURN 42');
	my ($a, $c);
	lives_ok { $a = $r->attached } 'is attached';
	lives_ok { $c = $r->detach } 'detach';
	is $c, ($a ? 1 : 0), 'one row detached';
	lives_and { ok ! $r->attached } 'not attached';
	lives_and { ok $r->has_next } 'not exhausted';
};


subtest 'result stream interface: discard result stream' => sub {
	plan tests => 4;
	$r = $s->run('RETURN 7 AS n UNION RETURN 11 AS n');
	my $c;
	lives_ok { $c = $r->consume } 'consume()';
	isa_ok $c, 'Neo4j::Driver::ResultSummary', 'summary from consume()';
	lives_and { ok ! $r->has_next } 'no has next';
	TODO: {
		local $TODO = 'records are not yet cheaply discarded';
		lives_and { ok ! $r->size } 'no size';
	};
};


subtest 'result stream interface: look ahead' => sub {
	plan tests => 10;
	$r = $s->run('RETURN 7 AS n UNION RETURN 11 AS n');
	my ($peek, $v);
	lives_ok { $peek = 0;  $peek = $r->peek } 'peek 1st';
	lives_ok { $v = 0;  $v = $r->fetch } 'fetch 1st';
	isa_ok $peek, 'Neo4j::Driver::Record', 'peek record 1st';
	is $peek, $v, 'peek matches fetch 1st';
	lives_ok { $peek = 0;  $peek = $r->peek } 'peek 2nd';
	lives_ok { $v = 0;  $v = $r->fetch } 'fetch 2nd';
	isa_ok $peek, 'Neo4j::Driver::Record', 'peek record 2nd';
	is $peek, $v, 'peek matches fetch 2nd';
	lives_and { ok ! $r->fetch } 'no fetch 3rd';
	throws_ok { $r->peek } qr/\bexhausted\b/i, 'peek dies 3rd';
};


subtest 'nested transactions: explicit (REST)' => sub {
	plan skip_all => '(currently testing Bolt)' if $Neo4j::Test::bolt;
	plan tests => 4 if ! $Neo4j::Test::bolt;
	my $session = $driver->session;
	my ($t1, $t2);
	lives_ok {
		$t1 = $session->begin_transaction;
		$t1->run("CREATE (nested1:Test)");
	} 'explicit nested transactions: 1st';
	lives_ok {
		$t2 = $session->begin_transaction;
		$t2->run("CREATE (nested2:Test)");
	} 'explicit nested transactions: 2nd';
	lives_ok { $t1->rollback; } 'explicit nested transactions: close 1st';
	lives_ok { $t2->rollback; } 'explicit nested transactions: close 2nd';
};


subtest 'nested transactions: explicit (Bolt)' => sub {
	plan skip_all => '(currently testing HTTP)' if ! $Neo4j::Test::bolt;
	plan tests => 4 if $Neo4j::Test::bolt;
	my $session = $driver->session;
	my ($t1, $t2);
	lives_ok {
		$t1 = $session->begin_transaction;
		$t1->run("CREATE (nested1:Test)");
	} 'explicit nested transactions: 1st';
	throws_ok {
		$t2 = $session->begin_transaction;
		$t2->run("CREATE (nested2:Test)");
	} qr/\bnested\b/i, 'explicit nested transactions: 2nd';
	lives_ok { $t1->rollback; } 'explicit nested transactions: close 1st';
	dies_ok { $t2->rollback; } 'explicit nested transactions: close 2nd';
};


subtest 'disable HTTP summary counters' => sub {
	plan skip_all => '(Bolt always provides stats)' if $Neo4j::Test::bolt;
	plan tests => 4 unless $Neo4j::Test::bolt;
	throws_ok { $s->run()->summary; } qr/missing stats/i, 'missing statement - summary';
	my $tx = $driver->session->begin_transaction;
	$tx->{return_stats} = 0;
	throws_ok {
		$tx->run('RETURN "no stats 0"')->summary;
	} qr/missing stats/i, 'no stats requested - summary';
	throws_ok {
		$tx->run('RETURN "no stats 1"')->single->summary;
	} qr/missing stats/i, 'no stats requested - single summary';
	lives_ok {
		$tx->run('RETURN "no stats 2"')->single;
	} 'no stats requested - single';
};


subtest 'get_bool' => sub {
	plan tests => 4;
	$q = <<END;
RETURN 42, 0.5, 'yes', 0, '', true, false, null
END
	lives_ok { $r = $s->run($q)->list->[0]; } 'get property values';
	# deprecation warnings are expected
	warnings { is $r->get_bool(6), undef, 'get_bool false'; };
	warnings { ok $r->get_bool(5), 'get_bool true'; };
	warnings { is $r->get_bool(3), 0, 'get_bool 0'; };
};


subtest 'support for get_person in LOMS plugin' => sub {
	plan tests => 6;
	$r = $s->run('RETURN 1 AS one, 2 AS two')->single;
	lives_and { is $r->{column_keys}->count, 2 } 'ResultColumns count 2';
	lives_and { is $r->{column_keys}->add('three'), 2 } 'ResultColumns add';
	lives_and { is $r->{column_keys}->count, 3 } 'ResultColumns count 3';
	$r->{row}->[2] = 'Three!';
	lives_and { is $r->get(2), 'Three!' } 'ResultColumns get col by index';
	lives_and { is $r->get('three'), 'Three!' } 'ResultColumns get col by name';
	throws_ok {
		$s->run('')->_column_keys;
	} qr/missing columns/i, 'result missing columns';
};


subtest 'graph queries' => sub {
	plan tests => 7;
	TODO: { local $TODO = 'graph response not yet implemented for Bolt' if $Neo4j::Test::bolt;
	my $t = $driver->session->begin_transaction;
	$t->{return_graph} = 1;
	$q = <<END;
CREATE ({name:'Alice'})-[k:KNOWS{since:1978}]->({name:'Bob'}) RETURN id(k)
END
	lives_ok { $r = $t->run($q)->single->get(0); } 'create graph';
	$q = <<END;
MATCH (a)-[b:KNOWS]->(c) WHERE id(b) = {id} RETURN a, b, c LIMIT 1
END
	lives_and { ok $r = $t->run($q, id => $r)->single; } 'match graph';
	my ($n, $e);
	lives_ok { $n = $r->{graph}->{nodes}; } 'got nodes';
	lives_ok { $e = $r->{graph}->{relationships}; } 'got rels';
	lives_and {
		ok grep {$_->{properties}->{name} eq $r->get('a')->get('name')} @$n;
	} 'node a found';
	lives_and {
		is $e->[0]->{properties}->{since}, $r->get('b')->get('since');
	} 'rel b found';
	lives_and {
		ok grep {$_->{properties}->{name} eq $r->get('c')->get('name')} @$n;
	} 'node c found';
	}
};


subtest 'custom cypher types' => sub {
	plan tests => 4;
	my $e_exact = exp(1);
	my $d = Neo4j::Test->driver_maybe;
	lives_ok {
		$d->config(cypher_types => {
			node => 'Local::Node',
			init => sub { my $self = shift; $self->{e_approx} = $e_exact },
		});
	} 'cypher types config';
	$r = 0;
	lives_ok {
		my $t = $d->session->begin_transaction;
		$r = $t->run('CREATE (a {e_approx:3}) RETURN a')->single->get('a');
	} 'cypher types query';
	is ref($r), 'Local::Node', 'cypher type ref';
	is $r->{e_approx}, $e_exact, 'cypher type init';  # ->{} property access is deprecated
	# TODO: test coverage for other types
};


done_testing;

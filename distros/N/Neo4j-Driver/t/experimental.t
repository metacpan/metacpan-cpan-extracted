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

use Test::More 0.96 tests => 7;
use Test::Exception;
use Test::Warnings qw(warnings :no_end_test);


my ($q, $r, @a);


subtest 'wantarray' => sub {
	plan tests => 13;
	$q = <<END;
RETURN 0 AS n UNION RETURN 1 AS n
END
	lives_ok { @a = $s->run($q)->list; } 'get records as list';
	lives_and { is $a[0]->get('n'), 0; } 'get record 0 in record list';
	lives_and { is $a[1]->get('n'), 1; } 'get record 1 in record list';
	lives_ok { @a = $s->run($q); } 'get result as list';
	lives_and { is $a[0]->get('n'), 0; } 'get record 0 in result list';
	lives_and { is $a[1]->get('n'), 1; } 'get record 1 in result list';
	lives_ok { @a = $s->run($q)->keys; } 'get keys as list';
	lives_and { is $a[0], 'n'; } 'get record 0 in keys list';
	
	# notifications
	my $t = $s->begin_transaction;
	$t->{return_stats} = 1;
	lives_ok { @a = $t->run($q)->summary->notifications; } 'no notifications';
	$q = <<END;
EXPLAIN MATCH (n), (m) RETURN n, m
END
	lives_ok { @a = $t->run($q)->summary->notifications; } 'get notifications';
	lives_and { like $a[0]->{code}, qr/CartesianProduct/ } 'notification';
	
	# multiple statements; see below
	$q = [
		['RETURN 7'],
		['RETURN 11'],
	];
	lives_ok { @a = $s->run($q) } 'run two statements at once';
	lives_and { is $a[0]->single->get * $a[1]->single->get, 7 * 11 } 'retrieve values';
};


subtest 'multiple statements as array' => sub {
	# the official drivers don't offer this capability to clients
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


subtest 'die_on_error = 0' => sub {
	# die_on_error currently only affects upstream errors.
	# If this option is ever officially supported, one would expect
	# it to also affect all croaks this driver issues by itself.
	# The latter are not yet covered by these tests.
	plan tests => 4;
	my $t = $s->begin_transaction;
	$t->{die_on_error} = 0;
	lives_and { is $t->run('RETURN 42')->single->get, 42 } 'no error';
	lives_and { warnings { is $t->run('iced manifolds.')->size, 0 } } 'cypher syntax error';
	$t = $s->begin_transaction;
	$t->{die_on_error} = 0;
	$t->{transaction} = '/qwertyasdfghzxcvbn';
	lives_and { warnings { is $t->run('RETURN 42')->size, 0 } } 'HTTP 404';
	lives_ok { warnings {
		my $d = Neo4j::Driver->new('http://none.invalid');
		$d->{die_on_error} = 0;
		$d->session->begin_transaction->run;
	} } 'no connection';
};


subtest 'stats' => sub {
	plan tests => 9;
	my $t = $s->begin_transaction;
	$t->{return_stats} = 1;
	lives_ok { $r = $t->run('RETURN 42'); } 'run stats query';
	# deprecation warnings are expected
	lives_and { warnings { isa_ok $r->stats, 'Neo4j::Driver::SummaryCounters', 'stats' } };
	lives_and { warnings { isa_ok $r->single->stats, 'Neo4j::Driver::SummaryCounters', 'single stats type' } };
	lives_and { warnings { ok ! $r->single->stats->{contains_updates} } } 'single stats value';
	lives_ok { $r = $s->run('RETURN 42'); } 'run normal query';
	lives_and { warnings { is ref $r->stats, 'HASH' } } 'no stats: type';
	lives_and { warnings { is scalar keys %{$r->stats}, 0 } } 'no stats: none';
	lives_and { warnings { is ref $r->single->stats, 'HASH' } } 'no single stats: type';
	lives_and { warnings { is scalar keys %{$r->single->stats}, 0 } } 'no single stats: none';
};


subtest 'get_bool' => sub {
	plan tests => 4;
	$q = <<END;
RETURN false, true, 0, [42], 1, 'yes', '', [], {a:1}, {}, null
END
	lives_ok { $r = $s->run($q)->list->[0]; } 'get property values';
	# deprecation warnings are expected
	warnings { is $r->get_bool(0), undef, 'get_bool false'; };
	warnings { ok $r->get_bool(1), 'get_bool true'; };
	warnings { is $r->get_bool(2), 0, 'get_bool 0'; };
};


subtest 'support for get_person in LOMS plugin' => sub {
	plan tests => 5;
	$r = $s->run('RETURN 42 AS value')->single;
	lives_and { is $r->{column_keys}->count, 1 } 'ResultColumns count 1';
	lives_ok { $r->{column_keys}->add('name'), 1 } 'ResultColumns add';
	lives_and { is $r->{column_keys}->count, 2 } 'ResultColumns count 2';
	$r->{1} = 'Universal Answer';
	lives_and { is $r->get('name'), $r->{name} } 'ResultColumns get';
	throws_ok {
		$s->run('')->_column_keys;
	} qr/missing columns/i, 'result missing columns';
};


subtest 'graph queries' => sub {
	plan tests => 7;
	my $t = $s->begin_transaction;
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
		ok grep {$_->{properties}->{name} eq $r->get('a')->{name}} @$n;
	} 'node a found';
	lives_and {
		is $e->[0]->{properties}->{since}, $r->get('b')->{since};
	} 'rel b found';
	lives_and {
		ok grep {$_->{properties}->{name} eq $r->get('c')->{name}} @$n;
	} 'node c found';
};


done_testing;

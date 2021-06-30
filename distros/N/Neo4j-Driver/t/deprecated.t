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


# The following tests all look into deprecated, but still available
# functionality. If the behaviour of such functionality changes, we
# want it to be a conscious decision, hence we test for it.

use Test::More 0.96 tests => 9 + 3;
use Test::Exception;
use Test::Warnings qw(warning warnings);
my $transaction = $driver->session->begin_transaction;
$transaction->{return_stats} = 0;  # optimise sim


my ($d, $w, @w, $r);


# query from types.t
my $q = <<END;
CREATE (n1:Test {test: 'node1'}), (n2:Test {test: 'node2'})
CREATE p1=(n1)-[e1:TEST]->(n2)<-[e2:TEST]-(n1)
CREATE (n3:Test {_node: -1, _labels: 'special'})
CREATE p2=(n3)-[e3:TEST {_relationship: 'yes', _test: 1}]->(n4)
SET e1.test = 'rel1', e2.test = 'rel2'
RETURN n1, n2, e1, e2, id(n1), id(e1), p1, n3, n4, e3
END
lives_ok { $r = 0; $r = $transaction->run($q)->single; } 'run query (structural types)';


subtest 'direct node/rel/path access' => sub {
	plan skip_all => '(query failed)' if ! $r;
	plan tests => 12;
	ok my $n = $r->get('n4'), 'get node';
	lives_ok { $w = ''; $w = warning { $n->{answer} = 42; }; } 'set node prop';
	(like $w, qr/\bdeprecate/, 'node access deprecated') or diag 'got warning(s): ', explain($w);
	is $n->get('answer'), 42, 'get node prop';
	ok my $e = $r->get('e2'), 'get relationship';
	lives_ok { $w = ''; $w = warning { $e->{prime} = 43; }; } 'set rel prop';
	(like $w, qr/\bdeprecate/, 'rel access deprecated') or diag 'got warning(s): ', explain($w);
	is $e->get('prime'), 43, 'get rel prop';
	ok my $p = $r->get('p1'), 'get path';
	lives_ok { $w = ''; $w = warning { $p->[2] = 'foo'; }; } 'modify path';
	(like $w, qr/\bdeprecate/, 'path access deprecated') or diag 'got warning(s): ', explain($w);
	is $n = ($p->nodes)[1], 'foo', 'get modified path';
};


subtest 'path()' => sub {
	plan skip_all => '(query failed)' if ! $r;
	plan tests => 5;
	ok my $p = $r->get('p1'), 'get path';
	ok my @all = $p->elements, 'get elements';
	my $path;
	lives_ok { $w = ''; $w = warning { $path = $p->path; }; } 'path method';
	(like $w, qr/\bdeprecate/, 'path method deprecated') or diag 'got warning(s): ', explain($w);
	is_deeply $path, \@all, 'path method matches elements';
};


subtest 'close()' => sub {
	plan tests => 4;
	# close() always was a no-op, so we only check the deprecation warning
	$w = '';
	lives_ok { $w = warning { $driver->close; }; } 'Driver close()';
	(like $w, qr/\bdeprecate/, 'Driver close deprecated') or diag 'got warning(s): ', explain($w);
	$w = '';
	lives_ok { $w = warning { $s->close; }; } 'Session close()';
	(like $w, qr/\bdeprecate/, 'Session close deprecated') or diag 'got warning(s): ', explain($w);
};


subtest 'die_on_error = 0' => sub {
	# die_on_error only ever affected upstream errors via HTTP JSON, 
	# never any errors issued via Bolt/Jolt or by this driver itself.
	plan tests => 7;
	# init
	my $d = Neo4j_Test->driver();
	$d->{die_on_error} = 0;
	my $t;
	@w = ();
	lives_ok { @w = warnings { $t = $d->session->begin_transaction; }; } 'Tx open';
	(like $w[0], qr/\bdeprecate/, 'die_on_error deprecated') or diag 'got warning(s): ', explain(\@w);
	# successful statement
	lives_ok { $r = 0; $r = $t->run('RETURN 42, "live on error"') } 'live no error';
	lives_and { is $r->single->get(0), 42 } 'no error';
	# failing statement
	SKIP: { skip '(test requires JSON)', 3 unless ref $r eq 'Neo4j::Driver::Result::JSON';
	$w = '';
	lives_ok { $w = warning { is $t->run(' iced manifolds.')->size, 0 }; } 'execute cypher syntax error';
	(like $w, qr/\bStatement\b.*Syntax/i, 'cypher syntax error') or diag 'got warning(s): ', explain($w);
	}
};


subtest 'driver mutability (config/auth)' => sub {
	plan skip_all => "(test requires HTTP)" if $Neo4j_Test::bolt;
	plan tests => 5;
	lives_ok { $d = 0; $d = Neo4j_Test->driver_maybe(); } 'get driver';
	lives_ok { $r = 0; $r = $d->session; } 'get auth session';  # basic_auth used by driver_maybe
	my @credentials = ('unlikely user/password combo', '');
	lives_ok { $w = warning { $d->basic_auth(@credentials) }; } 'auth mutable lives';
	(like $w, qr/\bDeprecate.*\bbasic_auth\b.*\bsession\b/i, 'auth mutable deprecated') or diag 'got warning(s): ', explain($w);
	is $d->{auth}->{principal}, $credentials[0], 'auth mutable';
};


subtest 'stats' => sub {
	plan skip_all => "(test requires HTTP)" if $Neo4j_Test::bolt;
	plan tests => 9;
	my $t = $driver->session->begin_transaction;
	$t->{return_stats} = 0;
	lives_ok { $r = $s->run('RETURN 42'); } 'run normal query';
	# deprecation warnings are expected
	lives_and { warnings { isa_ok $r->stats, 'Neo4j::Driver::SummaryCounters', 'stats' } };
	lives_and { warnings { isa_ok $r->single->stats, 'Neo4j::Driver::SummaryCounters', 'single stats type' } };
	lives_and { warnings { ok ! $r->single->stats->{contains_updates} } } 'single stats value';
	lives_ok { $r = $t->run('RETURN "no stats old syntax"'); } 'run no stats query';
	lives_and { warnings { is ref $r->stats, 'HASH' } } 'no stats: type';
	lives_and { warnings { is scalar keys %{$r->stats}, 0 } } 'no stats: none';
	lives_and { warnings { is ref $r->single->stats, 'HASH' } } 'no single stats: type';
	lives_and { warnings { is scalar keys %{$r->single->stats}, 0 } } 'no single stats: none';
};


subtest 'support for get_person in LOMS plugin' => sub {
	plan tests => 6;
	$r = $s->run('RETURN 1 AS one, 2 AS two')->single;
	lives_and { warnings { is $r->{column_keys}->count, 2 } } 'ResultColumns count 2';
	lives_and { warnings { is $r->{column_keys}->add('three'), 2 } } 'ResultColumns add';
	lives_and { warnings { is $r->{column_keys}->count, 3 } } 'ResultColumns count 3';
	$r->{row}->[2] = 'Three!';
	lives_and { is $r->get(2), 'Three!' } 'ResultColumns get col by index';
	lives_and { is $r->get('three'), 'Three!' } 'ResultColumns get col by name';
	throws_ok {
		$s->run('')->_column_keys;
	} qr/missing columns/i, 'result missing columns';
};


subtest 'multiple statements via run([])' => sub {
	plan skip_all => "(test requires HTTP)" if $Neo4j_Test::bolt;
	plan tests => 5 + 3;
	my (@q, @a);
	@q = (
		['RETURN 17'],
		['RETURN {n}', n => 19],
		['RETURN {n}', {n => 53}],
	);
	lives_ok { $w = ''; $w = warning { $r = $s->run([@q]) }; } 'run three statements at once';
	like $w, qr/\bmultiple statements\b.*\bdeprecated\b/i, 'multiple statements deprecated'
		or diag 'got warning(s): ', explain $w;
	lives_and { is $r->[0]->single->get, 17 } 'retrieve 1st value';
	lives_and { is $r->[1]->single->get, 19 } 'retrieve 2nd value';
	lives_and { is $r->[2]->single->get, 53 } 'retrieve 3rd value';
	
	# wantarray
	@q = (
		['RETURN 7'],
		['RETURN 11'],
	);
	lives_ok { $w = ''; $w = warning { @a = $s->run([@q]) }; } 'wantarray two statements at once';
	like $w, qr/\bmultiple statements\b.*\bdeprecated\b/i, 'wantarray multiple statements deprecated'
		or diag 'got warning(s): ', explain $w;
	lives_and { is $a[0]->single->get * $a[1]->single->get, 7 * 11 } 'wantarray values';
};


subtest 'custom cypher types' => sub {
	plan tests => 5 + 5;
	# fully test nodes
	my $e_exact = exp(1);
	my $d = Neo4j_Test->driver_maybe();
	lives_ok {
		no warnings 'deprecated';
		$d->config(cypher_types => {
			node => 'Local::Node',
			init => sub {
				my $self = shift;
				$self->{e_approx} = $e_exact;
			},
		});
	} 'cypher types config';
	$r = 0;
	lives_ok {
		my $t = $d->session->begin_transaction;
		$r = $t->run('CREATE (a {e_approx:3}) RETURN a')->single->get('a');
	} 'cypher types query';
	is ref($r), 'Local::Node', 'cypher type ref';
	is $r->get('e_approx'), $e_exact, 'cypher type init';
	lives_and { is ref($r->_private->{_meta}), 'HASH' } 'node _private access';
	# test _private access for other types
	lives_ok {
		my $tx = $driver->session->begin_transaction;
		$tx->{return_stats} = 0;  # optimise sim
		$q = <<END;
CREATE p=(a:Test:Want:Array)-[:TEST]->(c)
RETURN p, a
END
		$r = $tx->run($q)->single;
		$tx->rollback;
	} 'more types query';
	ok my $e = ($r->get('p')->relationships)[0], 'get rel';
	lives_and { is ref($e->_private->{_meta}), 'HASH' } 'rel _private access';
	lives_ok { $r->get('p')->_private->{__foo} = 42; } 'path _private set';
	lives_and { is $r->get('p')->_private->{__foo}, 42 } 'path _private get';
};


CLEANUP: {
	lives_ok { $transaction->rollback } 'rollback';
}


done_testing;


# for 'custom cypher types' test
package Local::Node;
BEGIN { our @ISA = qw(Neo4j::Driver::Type::Node) };

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


# This software's interface has not yet stabilised. It currently has
# features that are not documented and may not exist in future
# versions. The following tests should be either removed along with
# those features or moved elsewhere once the features are documented
# and thus officially supported.

use Test::More 0.96 tests => 13 + 1;
use Test::Exception;
use Test::Warnings qw(warnings);

use Neo4j::Driver;


my ($q, $r, @a, $a);


{
package Neo4j_Test::Result::Keys;
use parent 'Neo4j_Test::MockHTTP';
sub response_for { &Neo4j_Test::MockHTTP::response_for }
no warnings 'qw';
response_for 'no keys' => { jolt => [qw(
	{"header":{}} {"summary":{}} {"info":{}}
)]};
response_for 'one key' => { jolt => [qw(
	{"header":{"fields":["A"]}} {"summary":{}} {"info":{}}
)]};
response_for 'three keys' => { jolt => [qw(
	{"header":{"fields":["X","Y","Z"]}} {"summary":{}} {"info":{}}
)]};
}
subtest 'result keys() wantarray' => sub {
	plan tests => 1 + 3*3;
	my $d = Neo4j::Driver->new('http:');
	$d->config(net_module => 'Neo4j_Test::Result::Keys');
	my $sx;
	lives_and { ok $sx = $d->session(database => 'dummy') } 'session';
	lives_and { $r = 0; ok $r = $sx->run('no keys') } 'run 0';
	lives_and { is_deeply [$r->keys], [] } '0 keys';
	lives_and { is scalar($r->keys), 0 } '0 keys scalar context';
	lives_and { $r = 0; ok $r = $sx->run('one key') } 'run 1';
	lives_and { is_deeply [$r->keys], ['A'] } '1 key';
	lives_and { is scalar($r->keys), 1 } '1 key scalar context';
	lives_and { $r = 0; ok $r = $sx->run('three keys') } 'run 3';
	lives_and { is_deeply [$r->keys], [qw(X Y Z)] } '3 keys';
	lives_and { is scalar($r->keys), 3 } '3 keys scalar context';
};


{
package Neo4j_Test::Summary::Notifications;
use parent 'Neo4j_Test::MockHTTP';
sub response_for { &Neo4j_Test::MockHTTP::response_for }
no warnings 'qw';
response_for 'zero notes' => { jolt => [qw(
	{"header":{}} {"summary":{"stats":{}}} {"info":{}}
)]};
response_for 'one note' => { jolt => [qw(
	{"header":{}} {"summary":{"stats":{}}} {"info":{"notifications":["foobaz"]}}
)]};
response_for 'two notes' => { jolt => [qw(
	{"header":{}} {"summary":{"stats":{}}} {"info":{"notifications":["foo","bar"]}}
)]};
}
subtest 'summary notifications() wantarray' => sub {
	plan tests => 1 + 3*3;
	my $d = Neo4j::Driver->new('http:');
	$d->config(net_module => 'Neo4j_Test::Summary::Notifications');
	my $sx;
	lives_and { ok $sx = $d->session(database => 'dummy') } 'session';
	lives_and { $r = 0; ok $r = $sx->run('zero notes')->summary } 'run 0';
	lives_and { is_deeply [$r->notifications], [] } '0 notifications';
	lives_and { is scalar($r->notifications), 0 } '0 notifications scalar context';
	lives_and { $r = 0; ok $r = $sx->run('one note')->summary } 'run 1';
	lives_and { is_deeply [$r->notifications], ['foobaz'] } '1 notification';
	lives_and { is scalar($r->notifications), 1 } '1 notification scalar context';
	lives_and { $r = 0; ok $r = $sx->run('two notes')->summary } 'run 2';
	lives_and { is_deeply [$r->notifications], ['foo','bar'] } '2 notifications';
	lives_and { is scalar($r->notifications), 2 } '2 notifications scalar context';
};


{
package Neo4j_Test::Types::Context;
use parent 'Neo4j_Test::MockHTTP';
sub response_for { &Neo4j_Test::MockHTTP::response_for }
sub single_column {[
	{ header => { fields => [0] } },
	(map {{ data => [$_] }} @_),
	{ summary => {} },
	{ info => {} },
]}
response_for 'no labels' => { jolt => single_column(
	{ '()' => [ 1, undef, {} ] },
)};
response_for 'zero labels' => { jolt => single_column(
	{ '()' => [ 1, [], {} ] },
)};
response_for 'one label' => { jolt => single_column(
	{ '()' => [ 1, ['foobar'], {} ] },
)};
response_for 'two labels' => { jolt => single_column(
	{ '()' => [ 1, ['foo', 'baz'], {} ] },
)};
response_for 'no labels' => { jolt => single_column(
	{ '()' => [ 1, [], {} ] },
)};
response_for 'one label' => { jolt => single_column(
	{ '()' => [ 1, ['foobar'], {} ] },
)};
response_for 'path zero' => { jolt => single_column( { '..' => [
	{ '()' => [ 11, [], {} ] },
]})};
response_for 'path one' => { jolt => single_column( { '..' => [
	{ '()' => [ 2, [], {} ] },
	{ '->' => [ 3, 2, 'TEST', 4, {} ] },
	{ '()' => [ 4, [], {} ] },
]})};
response_for 'path two' => { jolt => single_column( { '..' => [
	{ '()' => [ 5, [], {} ] },
	{ '->' => [ 6, 5, 'TEST', 7, {} ] },
	{ '()' => [ 7, [], {} ] },
	{ '->' => [ 8, 7, 'TEST', 9, {} ] },
	{ '()' => [ 9, [], {} ] },
]})};
}
subtest 'types node/path wantarray' => sub {
	plan tests => 1 + 4*3 + 3*7;
	my $d = Neo4j::Driver->new('http:');
	$d->config(net_module => 'Neo4j_Test::Types::Context');
	my $sx;
	lives_and { ok $sx = $d->session(database => 'dummy') } 'session';
	
	lives_and { $r = 0; ok $r = $sx->run('no labels')->single->get } 'run no labels';
	lives_and { is_deeply [$r->labels], [] } 'labels undef';
	lives_and { is scalar($r->labels), 0 } 'labels undef scalar context';
	lives_and { $r = 0; ok $r = $sx->run('zero labels')->single->get } 'run zero labels';
	lives_and { is_deeply [$r->labels], [] } '0 labels';
	lives_and { is scalar($r->labels), 0 } '0 labels scalar context';
	lives_and { $r = 0; ok $r = $sx->run('one label')->single->get } 'run one label';
	lives_and { is_deeply [$r->labels], ['foobar'] } '1 label';
	lives_and { is scalar($r->labels), 1 } '1 label scalar context';
	lives_and { $r = 0; ok $r = $sx->run('two labels')->single->get } 'run two labels';
	lives_and { is_deeply [$r->labels], ['foo','baz'] } '2 labels';
	lives_and { is scalar($r->labels), 2 } '2 labels scalar context';
	
	lives_and { $r = 0; ok $r = $sx->run('path zero')->single->get } 'run path zero';
	lives_and { is_deeply [map {$_->id} $r->elements], [11] } '1 element';
	lives_and { is_deeply [map {$_->id} $r->nodes], [11] } '1 node';
	lives_and { is_deeply [map {$_->id} $r->relationships], [] } '0 rels';
	lives_and { is scalar($r->elements), 1 } '1 element scalar context';
	lives_and { is scalar($r->nodes), 1 } '1 node scalar context';
	lives_and { is scalar($r->relationships), 0 } '0 rels scalar context';
	
	lives_and { $r = 0; ok $r = $sx->run('path one')->single->get } 'run path one';
	lives_and { is_deeply [map {$_->id} $r->elements], [2,3,4] } '3 elements';
	lives_and { is_deeply [map {$_->id} $r->nodes], [2,4] } '2 nodes';
	lives_and { is_deeply [map {$_->id} $r->relationships], [3] } '1 rel';
	lives_and { is scalar($r->elements), 3 } '3 elements scalar context';
	lives_and { is scalar($r->nodes), 2 } '2 nodes scalar context';
	lives_and { is scalar($r->relationships), 1 } '1 rel scalar context';
	
	lives_and { $r = 0; ok $r = $sx->run('path two')->single->get } 'run path two';
	lives_and { is_deeply [map {$_->id} $r->elements], [5,6,7,8,9] } '5 elements';
	lives_and { is_deeply [map {$_->id} $r->nodes], [5,7,9] } '3 nodes';
	lives_and { is_deeply [map {$_->id} $r->relationships], [6,8] } '2 rels';
	lives_and { is scalar($r->elements), 5 } '5 elements scalar context';
	lives_and { is scalar($r->nodes), 3 } '3 nodes scalar context';
	lives_and { is scalar($r->relationships), 2 } '2 rels scalar context';
};


subtest 'multiple statements' => sub {
	# the official drivers don't offer this capability to clients
	plan skip_all => "(test wants live HTTP)" if $Neo4j_Test::bolt or $Neo4j_Test::sim;
	plan tests => 6;
	my @q = (
		['RETURN 17'],
		['RETURN {n}', n => 19],
		['RETURN {n}', {n => 53}],
	);
	lives_ok { @a = $s->begin_transaction->_run_multiple(@q) } 'run three statements at once';
	lives_and { is $a[0]->single->get, 17 } 'retrieve 1st value';
	lives_and { is $a[1]->single->get, 19 } 'retrieve 2nd value';
	lives_and { is $a[2]->single->get, 53 } 'retrieve 3rd value';
	throws_ok {
		 $r = $s->begin_transaction->_run_multiple('RETURN 42');
	} qr/\blist of array references\b/i, 'non-arrayref individual statement';
	@q = ( [''], ['RETURN 23'] );
	throws_ok {
		@a = $s->begin_transaction->_run_multiple([''], ['RETURN 23']);
	} qr/\bempty statements not allowed\b/i, 'include empty statement';
	# TODO: also check statement order in summary
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
	plan skip_all => '(currently testing Bolt)' if $Neo4j_Test::bolt;
	plan tests => 4 if ! $Neo4j_Test::bolt;
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
	plan skip_all => '(currently testing HTTP)' if ! $Neo4j_Test::bolt;
	plan tests => 4 if $Neo4j_Test::bolt;
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


subtest 'nested transactions: autocommit' => sub {
	plan tests => 2;
	my $session = $driver->session;
	my $value = 0;
	my $t = $session->begin_transaction;
	$t->run("CREATE (explicit1:Test)");
	lives_ok {
		$value = $session->run("RETURN 42")->single->get(0);
		$t->run("CREATE (explicit2:Test)");
		$t->rollback;
	} 'nested autocommit transactions: success' if ! $Neo4j_Test::bolt;
	throws_ok {
		$value = $session->run("RETURN 42")->single->get(0);
		$t->run("CREATE (explicit2:Test)");
		$t->rollback;
	} qr/support.*Bolt/i, 'nested autocommit transactions: no success' if $Neo4j_Test::bolt;
	my $expected = $Neo4j_Test::bolt ? 0 : 42;
	is $value, $expected, 'nested autocommit transactions: result';
};


subtest 'disable HTTP summary counters' => sub {
	plan skip_all => '(Bolt always provides stats)' if $Neo4j_Test::bolt;
	plan tests => 4 unless $Neo4j_Test::bolt;
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


subtest 'graph queries' => sub {
	plan tests => 8;
	TODO: { local $TODO = 'graph response not yet implemented for Bolt' if $Neo4j_Test::bolt;
	my $t = $driver->session->begin_transaction;
	$t->{return_graph} = 1;
	$q = <<END;
CREATE ({name:'Alice'})-[k:KNOWS{since:1978}]->({name:'Bob'}) RETURN id(k)
END
	lives_ok { $r = $t->run($q)->single->get(0); } 'create graph';
	$q = <<END;
MATCH (a)-[b:KNOWS]->(c) WHERE id(b) = {id} RETURN a, b, c LIMIT 1
END
	lives_and { ok $r = $t->run($q, id => $r); } 'match graph';
	local $TODO = 'graph response not yet implemented for Jolt' if ref $r eq 'Neo4j::Driver::Result::Jolt';
	lives_ok { $r = $r->single; } 'single';
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


done_testing;

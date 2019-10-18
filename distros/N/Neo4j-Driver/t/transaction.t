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
my $s = $driver->session;  # only for autocommit transactions


# These tests are about the REST and transaction implementation.

use Test::More 0.96 tests => 5 + 3;
use Test::Exception;
my $undo_id;


my ($q, $r);


subtest 'param syntax' => sub {
	plan tests => 11;
	my ($a, $b) = (17, 19);
	$q = <<END;
RETURN {a} AS a, {b} AS b
END
	lives_and { ok $r = $s->run( $q, {a => $a, b => $b} )->single } 'param hashref';
	is $r->get('a') * $r->get('b'), $a * $b, 'param values hashref';
	lives_and { ok $r = $s->run( $q,  a => $a, b => $b  )->single } 'param list';
	is $r->get('a') * $r->get('b'), $a * $b, 'param values list';
	my %hash = (a => $a, b => $b);
	lives_and { ok $r = $s->run( $q, %hash )->single } 'param hash';
	is $r->get('a') * $r->get('b'), $a * $b, 'param values hash';
	throws_ok {
		$r = $s->run($q, a => $a, b => $b, c => );
	} qr/Odd number of elements .* parameter hash/i, 'param list uneven';
	throws_ok {
		$r = $s->run($q, a => $a);
	} qr/ParameterMissing.* b /si, 'missing param';
	throws_ok {
		$r = $s->run($q, [a => $a, b => $b]);
	} qr/parameters must be .* hash or hashref/i, 'param arrayref';
	throws_ok {
		$r = $s->run( $q, sub { return {a => $a, b => $b} } );
	} qr/parameters must be .* hash or hashref/i, 'sub returning param hashref';
	throws_ok {
		$r = $s->run( $q, sub { return (a => $a, b => $b) } );
	} qr/parameters must be .* hash or hashref/i, 'sub returning param list';
};


subtest 'error handling' => sub {
	plan tests => 3;
	throws_ok { $s->run('iced manifolds.'); } qr/syntax/i, 'cypher syntax error';
	my $q = 'RETURN 42';
	throws_ok { $s->run(\$q) } qr/\bunblessed reference\b/, 'bogus reference query';
	SKIP: {
		skip 'for sim', 1 if $Neo4j::Test::sim;
		throws_ok { $s->run( bless \$q, 'Neo4j::Test' ); } qr/syntax/i, 'bogus blessed query';
	}
};


subtest 'nested transactions: autocommit' => sub {
	plan tests => 2;
	my $session = $driver->session;
	my $value;
	lives_ok {
		my $t = $session->begin_transaction;
		$t->run("CREATE (explicit1:Test)");
		$value = $session->run("RETURN 42")->single->get(0);
		$t->run("CREATE (explicit2:Test)");
		$t->rollback;
	} 'nested autocommit transactions: success';
	is $value, 42, 'nested autocommit transactions: result';
};


subtest 'commit/rollback: edge cases' => sub {
	plan tests => 11;
	my $t = $driver->session->begin_transaction;
	lives_and { ok $t->is_open; } 'beginning open';
	lives_ok { $t->rollback; } 'immediate rollback';
	lives_and { ok ! $t->is_open; } 'immediate rollback closes';
	throws_ok { $t->run; } qr/\bclosed\b/, 'run after rollback';
	throws_ok { $t->rollback; } qr/\bclosed\b/, 'rollback after rollback';
	throws_ok { $t->commit; } qr/\bclosed\b/, 'commit after rollback';
	$t = $driver->session->begin_transaction;
	lives_ok { $t->commit; } 'immediate commit';
	lives_and { ok ! $t->is_open; } 'immediate commit closes';
	throws_ok { $t->run; } qr/\bclosed\b/, 'run after commit';
	throws_ok { $t->commit; } qr/\bclosed\b/, 'commit after commit';
	throws_ok { $t->rollback; } qr/\bclosed\b/, 'rollback after commit';
};


subtest 'commit/rollback: modify database' => sub {
	plan tests => 4 + 9;
	my $entropy = [ 156949788, 54632, 153132456, 424697842 ];  # some constant numbers
#	$entropy = [ time, $$, srand, int 2**31 * rand ];  # some random numbers (not supported in sim)
	my $t = $driver->session->begin_transaction;
	
	# make change, commit, check that change has been made
	$q = <<END;
CREATE (n {entropy: {entropy}}) RETURN id(n) AS node_id
END
	lives_and { ok $r = $t->run( $q, entropy => $entropy )->single } 'create node';
	my $node_id = $r->get('node_id');
	$q = <<END;
MATCH (n) WHERE id(n) = {node_id} RETURN n.entropy, 0
END
	lives_and { ok $r = $t->run( $q, node_id => 0 + $node_id ) } 'get node data';
	my $commit_unsafe = @$entropy + (defined $node_id ? 0 : 1);  # `defined` because node id 0 exists in Neo4j
	lives_ok { foreach my $i (0..3) {  # (keys @$entropy)
		$commit_unsafe-- if $r->single->get(0)->[$i] == $entropy->[$i];
	} } 'verify node data';
	ok ! $commit_unsafe, 'commit safe';
	SKIP: {
		skip 'commit: deemed unsafe; something went seriously wrong', 11 if $commit_unsafe;
		$undo_id = $node_id;
		lives_ok { $t->commit; } 'commit';
		$t = $driver->session->begin_transaction;
		$q = <<END;
MATCH (n) WHERE id(n) = {node_id} RETURN n.entropy, 1
END
		lives_and { ok $r = $t->run( $q, node_id => 0 + $node_id ) } 'get committed data';
		my $commit_error = @$entropy;
		lives_ok { foreach my $i (0..3) {  # (keys @$entropy)
			$commit_error-- if $r->single->get(0)->[$i] == $entropy->[$i];
		} } 'verify committed data';
		ok ! $commit_error, 'commit successful';
		
		# make change, rollback, check that change has NOT been made
		$q = <<END;
MATCH (n) WHERE id(n) = {node_id} DELETE n
END
		lives_ok { $t->run( $q, node_id => 0 + $node_id ) } 'try deleting node';
		lives_ok { $t->rollback; } 'rollback';
		$t = $driver->session->begin_transaction;
		$q = <<END;
MATCH (n) WHERE id(n) = {node_id} RETURN n.entropy, 2
END
		lives_and { ok $r = $t->run( $q, node_id => 0 + $node_id ) } 'get data after rollback';
		my $rollback_error = @$entropy;
		lives_ok { foreach my $i (0..3) {  # (keys @$entropy)
			$rollback_error-- if $r->single->get(0)->[$i] == $entropy->[$i];
		} } 'verify data after rollback';
		ok ! $rollback_error, 'rollback successful';
	}
};


CLEANUP: {
	SKIP: {
		skip 'undo: nothing to undo', 3 unless defined $undo_id;  # `defined` because node id 0 exists in Neo4j
		my $t = $driver->session->begin_transaction;
		$t->{return_stats} = 1;
		$q = <<END;
MATCH (n) WHERE id(n) = {node_id} DELETE n
END
		lives_ok { $r = $t->run( $q, node_id => 0 + $undo_id ) } "undo commit [id $undo_id]";
		lives_and { ok $r->summary->counters->nodes_deleted } 'undo commit verified';
		lives_ok { $t->commit } 'undo commit execute';
	}
}

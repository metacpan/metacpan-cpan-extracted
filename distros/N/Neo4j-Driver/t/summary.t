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


# These tests are for the result summary and statistics.

use Test::More 0.96 tests => 7 + 1;
use Test::Exception;
my $transaction = $driver->session->begin_transaction;
$transaction->{return_stats} = 1;


my $t = $driver->session->begin_transaction;
$t->{return_stats} = 1;
my ($q, $r, $c);


subtest 'ResultSummary' => sub {
	plan tests => 11;
	$q = <<END;
RETURN {num}
END
	my @params = (num => 42);
	lives_ok { $r = $t->run($q, @params)->summary; } 'get summary';
	isa_ok $r, 'Neo4j::Driver::ResultSummary', 'ResultSummary';
	throws_ok { $r->server; } qr/\bunimplemented\b/i, 'server address';
	lives_and { is $r->statement->{text}, $q } 'statement text';
	lives_and { is_deeply $r->statement->{parameters}, {@params} } 'statement params';
	lives_and { ok ! $r->plan; } 'no plan';
	lives_and { ok ! $r->notifications; } 'no notification';
#	diag explain $r;
	$q = <<END;
EXPLAIN MATCH (n), (m) RETURN n, m
END
	lives_ok { $r = $t->run($q)->summary; } 'get plan';
	lives_and { is_deeply $r->statement->{parameters}, {} } 'no params';
	lives_and { is $r->plan->{root}->{children}->[0]->{operatorType}, 'CartesianProduct' } 'plan detail';
	lives_and { like $r->notifications->[0]->{code}, qr/CartesianProduct/ } 'notification';
};


subtest 'ResultSummary: failure' => sub {
	plan tests => 4;
	throws_ok { $t->run()->summary; } qr/missing stats/i, 'missing statement - summary';
	SKIP: {
		my $is_bolt = URI->new( $ENV{TEST_NEO4J_SERVER} // '' )->scheme // '' eq 'bolt';
		skip 'Bolt always provides stats', 3 if $is_bolt;
		my $tx = $driver->session->begin_transaction;
		$tx->{return_stats} = 0;
		throws_ok {
			$tx->run('RETURN 42')->summary;
		} qr/missing stats/i, 'no stats requested - summary';
		throws_ok {
			$tx->run('RETURN 42')->single->summary;
		} qr/missing stats/i, 'no stats requested - single summary';
		lives_ok {
			$tx->run('RETURN 42')->single;
		} 'no stats requested - single';
	}
};


subtest 'SummaryCounters: from result' => sub {
	plan tests => 4;
	$q = <<END;
RETURN 42
END
	lives_ok { $r = $t->run($q); } 'run query';
	lives_ok { $c = $r->summary->counters; } 'get counters';
	isa_ok $c, 'Neo4j::Driver::SummaryCounters', 'summary counters';
	lives_and { ok ! $c->contains_updates } 'contains_updates counter';
};


subtest 'SummaryCounters: from single' => sub {
	plan tests => 4;
	$q = <<END;
RETURN 42
END
	lives_ok { $r = $t->run($q)->single; } 'run query';
	lives_ok { $c = $r->summary->counters; } 'get counters';
	isa_ok $c, 'Neo4j::Driver::SummaryCounters', 'summary counters';
	lives_and { ok ! $c->contains_updates } 'contains_updates counter';
};


subtest 'SummaryCounters: updates, properties, labels' => sub {
	plan tests => 4;
	$q = <<END;
CREATE (n)
SET n:Universal:Answer
SET n.value = 42, n.origin = 'Deep Thought'
REMOVE n:Answer
SET n = {}
END
	$c = $transaction->run($q)->summary->counters;
	ok $c->contains_updates, 'contains_updates counter';
	is $c->properties_set, 4, 'properties_set counter';
	is $c->labels_added, 2, 'labels_added counter';
	is $c->labels_removed, 1, 'labels_removed counter';
};


subtest 'SummaryCounters: nodes, relationships' => sub {
	plan tests => 4;
	$q = <<END;
CREATE (d:DeepThought)-[r1:GIVES]->(a:UniversalAnswer)
CREATE (a)-[r2:ORIGIN]->(d)
CREATE (a)-[:ANSWERS]->(q:UniversalQuestion)
DELETE r1, r2, d
END
	$c = $transaction->run($q)->summary->counters;
	is $c->nodes_created, 3, 'nodes_created counter';
	is $c->nodes_deleted, 1, 'nodes_deleted counter';
	is $c->relationships_created, 3, 'relationships_created counter';
	is $c->relationships_deleted, 2, 'relationships_deleted counter';
};


#subtest 'SummaryCounters: constraints, indexes' => sub {
#};


subtest 'repeated invocation' => sub {
	# References to the summary and to the counters can be requested
	# more than once, in which case every request returns a reference
	# to the exact same object.
	plan tests => 3;
	lives_ok { $r = $t->run('RETURN 42') } 'get result';
	lives_and { is $r->summary, $r->summary } 'summary identical';
	lives_and { is $r->summary->counters, $r->summary->counters } 'counters identical';
};


CLEANUP: {
	lives_ok { $transaction->rollback } 'rollback';
}

done_testing;

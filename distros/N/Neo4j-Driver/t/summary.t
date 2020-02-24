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


# These tests are for the result summary and statistics.

use Test::More 0.96 tests => 5 + 1;
use Test::Exception;
my $transaction = $driver->session->begin_transaction;


my ($q, $r, $c);


subtest 'ResultSummary' => sub {
	plan tests => 11;
	$q = <<END;
RETURN {fortytwo}
END
	my @params = (fortytwo => 42);
	lives_ok { $r = $s->run($q, @params)->summary; } 'get summary';
	isa_ok $r, 'Neo4j::Driver::ResultSummary', 'ResultSummary';
	throws_ok { $r->server; } qr/\bunimplemented\b/i, 'server address';
	my $param_start = $driver->config('cypher_filter') ? '\$' : '\{';
	lives_and { like $r->statement->{text}, qr/RETURN ${param_start}fortytwo\b/ } 'statement text';
	lives_and { is_deeply $r->statement->{parameters}, {@params} } 'statement params';
	lives_and { ok ! $r->plan; } 'no plan';
	lives_and { ok ! $r->notifications; } 'no notification';
#	diag explain $r;
	$q = <<END;
EXPLAIN MATCH (n), (m) RETURN n, m
END
	lives_ok { $r = $s->run($q)->summary; } 'get summary with plan';
	lives_and { is_deeply $r->statement->{parameters}, {} } 'no params';
	my ($plan, @notifications);
	TODO: { local $TODO = 'plan/notifications not yet implemented for Bolt' if $Neo4j::Test::bolt;
	lives_and { ok $plan = $r->plan; } 'get plan';
	lives_and { ok @notifications = $r->notifications; } 'get notifications';
	}
};


subtest 'SummaryCounters: from result' => sub {
	plan tests => 4;
	$q = <<END;
RETURN 42
END
	lives_ok { $r = $s->run($q); } 'run query';
	lives_ok { $c = $r->summary->counters; } 'get counters';
	isa_ok $c, 'Neo4j::Driver::SummaryCounters', 'summary counters';
	lives_and { ok ! $c->contains_updates } 'contains_updates counter';
};


subtest 'SummaryCounters: from single' => sub {
	plan tests => 4;
	$q = <<END;
RETURN 42
END
	lives_ok { $r = $s->run($q)->single; } 'run query';
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


CLEANUP: {
	lives_ok { $transaction->rollback } 'rollback';
}

done_testing;

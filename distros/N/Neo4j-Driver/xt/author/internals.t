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


# The following tests all look into undocumented behaviour. If such
# behaviour changes, we want it to be a conscious decision, hence
# we test for it. However, since the internals are not part of any
# documented API, such tests should not be a part of the main test
# suite, which is by default run on installation on every platform.
# That's why these internals are in xt/author.

use Test::More 0.94;
use Test::Exception;
use Test::Warnings 0.010 qw(warnings :no_end_test);
my $no_warnings;
use if $no_warnings = $ENV{AUTHOR_TESTING} ? 1 : 0, 'Test::Warnings';


my ($q, $r);

plan tests => 4 + $no_warnings;


subtest 'result: list() repeated' => sub {
	# This test is for a detail of the statement result: A reference
	# to the array of result records can be requested more than once,
	# in which case every request returns a reference to the exact same
	# array. (A case can be made to make defensive copies instead.)
	plan tests => 1;
	$r = $s->run('RETURN 42');
	is scalar($r->list), scalar($r->list), 'arrayref identical';
};


subtest 'summary: plan/notification internals' => sub {
	plan skip_all => "(EXPLAIN not supported by Neo4j::Bolt)"
		if $Neo4j_Test::bolt && $s->server->agent !~ m<Neo4j/[34]\.>;
	plan tests => 5;
	$q = <<END;
EXPLAIN MATCH (n), (m) RETURN n, m
END
	lives_ok { $r = $s->run($q)->summary; } 'get summary with plan';
	my ($plan, @notifications);
	lives_ok { $plan = $r->plan;  1; } 'get plan';
	SKIP: {
		skip '(plan unavailable)', 1 unless $plan;
		lives_and { like $plan->{root}->{children}->[0]->{operatorType}, qr/CartesianProduct/ } 'plan detail';
	}
	lives_ok { @notifications = $r->notifications;  1; } 'get notifications';
	SKIP: {
		skip '(notifications unavailable)', 1 unless @notifications;
		lives_and { like $notifications[0]->{code}, qr/CartesianProduct/ } 'notifications detail';
	}
};


subtest 'summary: repeated invocation' => sub {
	# References to the summary and to the counters can be requested
	# more than once, in which case every request returns a reference
	# to the exact same object.
	plan tests => 3;
	lives_ok { $r = $s->run('RETURN 42') } 'get result';
	lives_and { is $r->summary, $r->summary } 'summary identical';
	lives_and { is $r->summary->counters, $r->summary->counters } 'counters identical';
};


subtest 'transaction: REST 404 error handling' => sub {
	plan skip_all => "(test requires live REST)" if $Neo4j_Test::sim || $Neo4j_Test::bolt;
	plan tests => 1;
	my $t = $driver->session->begin_transaction;
	$t->{transaction_endpoint} = '/qwertyasdfghzxcvbn';
	throws_ok { $t->run; } qr/\b404\b/, 'HTTP 404';
};


done_testing;

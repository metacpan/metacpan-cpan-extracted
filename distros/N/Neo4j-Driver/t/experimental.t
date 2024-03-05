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

use Test::More 0.94;
use Test::Exception;
use Test::Warnings 0.010 qw(warnings :no_end_test);
my $no_warnings;
use if $no_warnings = $ENV{AUTHOR_TESTING} ? 1 : 0, 'Test::Warnings';

use Neo4j::Driver;
use Neo4j_Test::MockHTTP;

my $mock_plugin = Neo4j_Test::MockHTTP->new;
sub response_for { $mock_plugin->response_for(undef, @_) }


my ($q, $r, @a, $a);

plan tests => 4 + $no_warnings;


subtest 'multiple statements' => sub {
	# the official drivers don't offer this capability to clients
	plan skip_all => "(test wants live HTTP)" if $Neo4j_Test::bolt or $Neo4j_Test::sim;
	plan tests => 6;
	my @q = (
		['RETURN 17'],
		['RETURN {n}', n => 19],
		['RETURN {n}', {n => 53}],
	);
	my $tx = $s->begin_transaction;
	lives_ok { @a = $tx->_run_multiple(@q) } 'run three statements at once';
	lives_and { is $a[0]->single->get, 17 } 'retrieve 1st value';
	lives_and { is $a[1]->single->get, 19 } 'retrieve 2nd value';
	lives_and { is $a[2]->single->get, 53 } 'retrieve 3rd value';
	throws_ok {
		 $r = $tx->_run_multiple('RETURN 42');
	} qr/\blist of array references\b/i, 'non-arrayref individual statement';
	@q = ( [''], ['RETURN 23'] );
	throws_ok {
		@a = $tx->_run_multiple([''], ['RETURN 23']);
	} qr/\bempty statements not allowed\b/i, 'include empty statement';
	$tx->rollback;
	# TODO: also check statement order in summary
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


subtest 'stack trace' => sub {
	plan tests => 1;
	my $d = Neo4j::Driver->new('http:')->plugin( Neo4j_Test::MockHTTP->new );
	throws_ok {
		$Neo4j::Driver::Events::STACK_TRACE = 1;
		$d->session->run('trace not implemented');
	} qr/::Transaction::HTTP::_run_autocommit\b/, 'debug stack trace';
};


done_testing;

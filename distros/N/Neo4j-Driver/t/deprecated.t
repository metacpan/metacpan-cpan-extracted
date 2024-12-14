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
my $session = $driver->session;


# These tests intend to verify that attempts to access features that
# have been deprecated and removed results in sensible behaviour.

use Test::More 0.94;
use Test::Exception;
use Test::Warnings 0.010 qw(:no_end_test);
my $no_warnings;
use if $no_warnings = $ENV{AUTHOR_TESTING} ? 1 : 0, 'Test::Warnings';

use Neo4j_Test::MockHTTP;
use Neo4j_Test::Sim;
my $transaction = $driver->session->begin_transaction;
$transaction->{return_stats} = 0;  # optimise sim

my $mock_plugin = Neo4j_Test::MockHTTP->new;
sub response_for { $mock_plugin->response_for(undef, @_) }

my $r;

plan tests => 1 + 21 + $no_warnings;


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
	plan skip_all => 'Neo4j::Bolt is designed for direct access' if $Neo4j_Test::bolt;
	plan tests => 6;
	ok my $n = $r->get('n4'), 'get node';
	dies_ok { $n->{answer} = 42 } 'set node prop';
	ok my $e = $r->get('e2'), 'get relationship';
	dies_ok { $e->{prime} = 43 } 'set rel prop';
	ok my $p = $r->get('p1'), 'get path';
	dies_ok { $p->[2] = $n } 'modify path';
};


subtest 'path()' => sub {
	plan skip_all => '(query failed)' if ! $r;
	plan tests => 2;
	ok my $p = $r->get('p1'), 'get path';
	dies_ok { $p->path } 'path method';
};


response_for 'deleted' => { json => <<END };
{"errors":[],"results":[{"columns":["n"],"data":[
{"meta":[{"deleted":true,"id":1,"type":"node"}],"rest":[{"metadata":{"id":1,"labels":["Test"]},"self":"/db/data/node/1"}],"row":[{}]},
{"meta":[{"deleted":false,"id":6,"type":"relationship"}],"rest":[{"end":"/db/data/node/5","metadata":{"id":6,"type":"TEST"},"self":"/db/data/relationship/6","start":"/db/data/node/7"}],"row":[{}]},
{"rest":[{"metadata":{"id":3,"labels":["Test"]},"self":"/db/data/node/3"}],"row":[{}]}
]}]}
END
subtest 'deleted()' => sub {
	plan tests => 2;
	my $d = Neo4j::Driver->new('http:');
	$d->plugin($mock_plugin);
	lives_and { $r = 0; ok $r = $d->session(database => 'dummy')->run('deleted') } 'run';
	dies_ok { $r->fetch->get->deleted } 'deleted';
};


subtest 'close()' => sub {
	plan tests => 2;
	dies_ok { $driver->close } 'Driver close()';
	dies_ok { $session->close } 'Session close()';
};


{
	package Neo4j_Test::Plugin::NoDieOnError;
	use parent 'Neo4j::Driver::Plugin';
	our $error;
	sub register {
		my (undef, $events) = @_;
		$events->add_handler( error => sub {
			my (undef, $e) = @_;
			$error = $e;
		});
	}
}


subtest 'die_on_error = 0' => sub {
	plan tests => 4;
	my $mock = Neo4j_Test::MockHTTP->new;
	$mock->response_for(undef, 'foo' => { content_type => 'text/plain', content => 'bar' });
	my $error = bless [], 'Neo4j_Test::Plugin::NoDieOnError';
	my $d = Neo4j::Driver->new('http:')->plugin($mock)->plugin($error);
	
	# Text's _results() method is only triggered by surviving errors
	lives_ok { no warnings; $r = 0; $r = $d->session->run('foo') } 'broken response lives';
	is ref($r), 'Neo4j::Driver::Result', 'broken response result fallback';
	is $Neo4j_Test::Plugin::NoDieOnError::error->as_string, 'bar', 'error text';
	
	# Surviving errors yields results with no summary
	ok ! eval { $r->consume->server }, 'error missing summary';
};


subtest 'driver mutability (config/auth)' => sub {
	plan tests => 1;
	dies_ok {
		my $d = Neo4j::Driver->new->plugin( Neo4j_Test::MockHTTP->new );
		$d->session;
		$d->basic_auth('user', 'passwd')
	} 'auth not mutable';
};


subtest 'jolt config option' => sub {
	plan tests => 3;
	dies_ok { Neo4j::Driver->new({ jolt => 0 }) } 'jolt 0';
	dies_ok { Neo4j::Driver->new({ jolt => 'sparse' }) } 'jolt v1 sparse';
	dies_ok { $driver->config('jolt') } 'jolt mode';
};


subtest 'net_module config option' => sub {
	plan tests => 2;
	my $net_module = 'Neo4j::Driver::Net::HTTP::Tiny';
	dies_ok { Neo4j::Driver->new({ net_module => $net_module }) } 'set net_module';
	dies_ok { $driver->config('net_module') } 'get net_module';
};


subtest 'plug-in manager' => sub {
	plan tests => 4;
	my $m;
	lives_and { ok $m = Neo4j::Driver::Events->new } 'new';
	dies_ok { $m->_register_plugin( Neo4j_Test::MockHTTP:: ) } 'plugin by name';
	dies_ok { $m->add_event_handler(x_test => sub {'foo'}) } 'add_event_handler';
	dies_ok { $m->trigger_event('x_test') } 'trigger_event';
};


subtest 'cypher_filter' => sub {
	plan tests => 1;
	dies_ok { Neo4j::Driver->new({ cypher_filter => 'params' }) } 'set filter';
};


subtest 'ServerInfo protocol()' => sub {
	plan tests => 4;
	my $si;
	my %uri = (uri => URI->new('http:'));
	lives_and { ok $si = Neo4j::Driver::ServerInfo->new({%uri}) } 'new undef';
	dies_ok { $si->protocol } 'protocol';
	lives_and { ok $si = Neo4j::Driver::ServerInfo->new({%uri, protocol => '2.2'}) } 'new version';
	dies_ok { $si->protocol } 'protocol version';
};


subtest 'stats' => sub {
	plan skip_all => "(test wants live HTTP)" if $Neo4j_Test::bolt || $Neo4j_Test::sim;
	plan tests => 6;
	lives_ok { $r = $session->run('RETURN 42'); } 'run normal query';
	dies_ok { $r->stats } 'stats';
	dies_ok { $r->single->stats } 'single stats';
	my $t = $session->begin_transaction;
	$t->{return_stats} = 0;
	lives_ok { $r = $t->run('RETURN "no stats old syntax"'); } 'run no stats query';
	dies_ok { $r->stats } 'no stats';
	dies_ok { $r->single->stats } 'no single stats';
	eval { $t->rollback };
};


subtest 'support for get_person in LOMS plugin' => sub {
	plan tests => 5;
	ok my $d = Neo4j::Driver->new('http:')->plugin( Neo4j_Test::MockHTTP->new ), 'new driver';
	$r = $d->session(database => 'system')->run('SHOW DEFAULT DATABASE')->single;
	ok $r->get, 'result valid';
	dies_ok { $r->{column_keys}->count } 'ResultColumns count';
	dies_ok { $r->{column_keys}->add('three') } 'ResultColumns add';
	dies_ok { $r->{column_keys}->list } 'ResultColumns list';
};


subtest 'multiple statements via run([])' => sub {
	plan skip_all => "(test wants live HTTP)" if $Neo4j_Test::bolt || $Neo4j_Test::sim;
	plan tests => 2;
	my (@q, @a);
	@q = (
		['RETURN 17'],
		['RETURN {n}', n => 19],
		['RETURN {n}', {n => 53}],
	);
	dies_ok { $r = $session->run([@q]) } 'run three statements at once';
	dies_ok { @a = $session->run([@q]) } 'wantarray statements at once';
};


subtest 'result stream interface: attachment' => sub {
	plan tests => 2;
	$r = $session->run('RETURN 42');
	dies_ok { $r->attached } 'attached';
	dies_ok { $r->detach } 'detach';
};


subtest 'run in list context' => sub {
	plan tests => 6;
	$q = 'RETURN 7 AS n UNION RETURN 11 AS n';
	my @a;
	SKIP: { skip 'explicit transactions unoptimised', 2 if $Neo4j_Test::sim;
		my $t = $session->begin_transaction;
		lives_ok { @a = $t->run($q) } 'get result as list (explicit tx)';
		isa_ok $a[0], 'Neo4j::Driver::Result', 'run always returns scalar result (tx)';
		eval { $t->rollback }; 1;
	}
	lives_ok { @a = $session->run($q) } 'get result as list';
	isa_ok $a[0], 'Neo4j::Driver::Result', 'run always returns scalar result';
	dies_ok { $a[0]->get } 'accessing list item 0 as record fails';
	dies_ok { $a[1]->get } 'accessing list item 1 as record fails';
};


subtest 'config tls options' => sub {
	plan tests => 2;
	my $ca_file = '/dev/null';
	dies_ok { Neo4j::Driver->new({ ca_file => $ca_file }) } 'set config ca_file';
	dies_ok { $driver->config('ca_file') } 'get ca_file';
};


subtest 'custom cypher types' => sub {
	plan tests => 1;
	dies_ok {
		Neo4j::Driver->new({ cypher_types => $driver->{cypher_types} });
	} 'cypher types config';
};


subtest 'graph queries' => sub {
	plan skip_all => "graph response not implemented for Bolt" if $Neo4j_Test::bolt;
	plan tests => 1;
	my $s_json = $session;
	$s_json->{net}->{want_jolt} = 0;
	my $t = $s_json->begin_transaction;
	$t->{return_graph} = 1;
	dies_ok { $t->run('') } 'return_graph removed';
	eval { $t->rollback };
};


subtest 'get_bool' => sub {
	plan tests => 2;
	$q = <<END;
RETURN 42, 0.5, 'yes', 0, '', true, false, null
END
	lives_ok { $r = $session->run($q)->list->[0]; } 'get property values';
	dies_ok { $r->get_bool(5) } 'get_bool';
};


subtest 'raw meta data access' => sub {
	plan tests => 2;
	isa_ok $r = $session->run('RETURN 42')->single, 'Neo4j::Driver::Record', 'result valid';
	is ref($r->{meta}), '', 'meta entry is not a reference';
};


CLEANUP: {
	eval { $transaction->rollback };
}


done_testing;

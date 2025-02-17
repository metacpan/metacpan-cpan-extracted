#!perl
use strict;
use warnings;
use lib qw(./lib t/lib);

use Test::More 0.94;
use Test::Exception;
use Test::Warnings 0.010 qw(warning :no_end_test);
my $no_warnings;
use if $no_warnings = $ENV{AUTHOR_TESTING} ? 1 : 0, 'Test::Warnings';


# Concurrent transactions within the same session (in the context of Bolt
# called "nested transactions") are not allowed in the Neo4j Driver API,
# but are actually supported just fine when implemented via the
# Transactional HTTP API, which this driver can use for network communication.
# Therefore, this driver supports concurrent transactions for HTTP sessions.

use Neo4j_Test;
use Neo4j_Test::MockHTTP;

plan tests => 15 + $no_warnings;


my ($w, $d, $s, $t, $r);


# minimal dummy responses for HTTP
my $mock_plugin = Neo4j_Test::MockHTTP->new;
$mock_plugin->response_for('/db/dummy/tx', 'foo' => {
	jolt => [
		'{"header":{"fields":[]}}',
		'{"summary":{}}',
		'{"info":{"commit":"http://localhost:7474/db/dummy/tx/5/commit","transaction":{"expires":"Tue, 1 Jan 2999 00:00:00 GMT"}}}',
	],
	status => 201,
	location => 'http://localhost:7474/db/dummy/tx/5',
});
$mock_plugin->response_for('/db/dummy/tx', 'bar' => {
	jolt => [
		'{"header":{"fields":[]}}',
		'{"summary":{}}',
		'{"info":{"commit":"http://localhost:7474/db/dummy/tx/6/commit","transaction":{"expires":"Tue, 1 Jan 2999 00:00:00 GMT"}}}',
	],
	status => 201,
	location => 'http://localhost:7474/db/dummy/tx/6',
});
my %empty_jolt = ( jolt => [
	'{"header":{"fields":[]}}',
	'{"summary":{}}',
	'{"info":{}}',
]);
$mock_plugin->response_for('/db/dummy/tx/5/commit', '' => \%empty_jolt);
$mock_plugin->response_for('/db/dummy/tx/6/commit', '' => \%empty_jolt);
$mock_plugin->response_for('/db/dummy/tx/commit',   '' => \%empty_jolt);


# minimal dummy net module for Bolt config tests
{
	package Local::Bolt;
	sub new { bless \(my $b = undef), shift }
	sub connect { &new }
	sub protocol_version { 0 }
	
	# Cxn
	sub connected { 1 }
	sub server_id { __PACKAGE__ }
	
	package Local::Bolt::Txn;
	use parent -norequire => 'Local::Bolt';
	sub commit {}
}


subtest 'config for bolt: uri' => sub {
	plan tests => 6;
	# config 1
	$d = Neo4j::Driver->new;
	$d->{config}->{net_module} = 'Local::Bolt';
	lives_ok { $d->config( uri => 'bolt:', concurrent_tx => 1 ); } 'config on lives';
	throws_ok {
		$d->session(database => 'dummy');
	} qr/\bConcurrent transactions\b.*\bunsupported\b.*\bBolt\b/i, 'bolt session on dies';
	# config 0
	$d = Neo4j::Driver->new;
	$d->{config}->{net_module} = 'Local::Bolt';
	lives_ok { $d->config( uri => 'bolt:', concurrent_tx => 0 ); } 'config off lives';
	lives_ok { $d->session(database => 'dummy'); } 'bolt session off lives';
	# config undef
	$d = Neo4j::Driver->new;
	$d->{config}->{net_module} = 'Local::Bolt';
	lives_ok { $d->config( uri => 'bolt:' ); } 'config undef lives';
	lives_ok { $d->session(database => 'dummy'); } 'bolt session undef lives';
};


subtest 'config for http: uri' => sub {
	plan tests => 9;
	# config 1
	$d = Neo4j::Driver->new->plugin($mock_plugin);
	lives_ok { $d->config( uri => 'http:', concurrent_tx => 1 ); } 'config on lives';
	lives_ok { $s = 0; $s = $d->session(database => 'dummy'); } 'session on lives';
	ok $s->{net}{want_concurrent}, 'concurrent tx on';
	# config 0
	$d = Neo4j::Driver->new->plugin($mock_plugin);
	lives_ok { $d->config( uri => 'http:', concurrent_tx => 0 ); } 'config off lives';
	lives_ok { $s = 0; $s = $d->session(database => 'dummy'); } 'session off lives';
	ok ! $s->{net}{want_concurrent}, 'concurrent tx off';
	# config undef
	$d = Neo4j::Driver->new->plugin($mock_plugin);
	lives_ok { $d->config( uri => 'http:', concurrent_tx => undef ); } 'config undef lives';
	lives_ok { $s = 0; $s = $d->session(database => 'dummy'); } 'session undef lives';
	ok ! $s->{net}{want_concurrent}, 'concurrent tx http default off';
};


subtest 'config for https: uri' => sub {
	plan tests => 9;
	# config 1
	$d = Neo4j::Driver->new->plugin($mock_plugin);
	lives_ok { $d->config( uri => 'https:', concurrent_tx => 1 ); } 'config on lives';
	lives_ok { $s = 0; $s = $d->session(database => 'dummy'); } 'session on lives';
	ok $s->{net}{want_concurrent}, 'concurrent tx on';
	# config 0
	$d = Neo4j::Driver->new->plugin($mock_plugin);
	lives_ok { $d->config( uri => 'https:', concurrent_tx => 0 ); } 'config off lives';
	lives_ok { $s = 0; $s = $d->session(database => 'dummy'); } 'session off lives';
	ok ! $s->{net}{want_concurrent}, 'concurrent tx off';
	# config undef
	$d = Neo4j::Driver->new->plugin($mock_plugin);
	lives_ok { $d->config( uri => 'https:', concurrent_tx => undef ); } 'config undef lives';
	lives_ok { $s = 0; $s = $d->session(database => 'dummy'); } 'session undef lives';
	ok ! $s->{net}{want_concurrent}, 'concurrent tx https default off';
};


subtest 'config for neo4j: uri' => sub {
	plan tests => 6;
	# config 1
	$d = Neo4j::Driver->new->plugin($mock_plugin);
	lives_ok { $d->config( uri => 'neo4j:', concurrent_tx => 1 ); } 'config on lives';
	throws_ok {
		$d->session(database => 'dummy');
	} qr/\bconcurrent_tx\b.*\bhttp\b/i, 'neo4j: session on dies';
	# config 0
	$d = Neo4j::Driver->new->plugin($mock_plugin);
	lives_ok { $d->config( uri => 'neo4j:', concurrent_tx => 0 ); } 'config off lives';
	lives_ok { $d->session(database => 'dummy'); } 'neo4j: session off lives';
	# config undef
	$d = Neo4j::Driver->new->plugin($mock_plugin);
	lives_ok { $d->config( uri => 'neo4j:' ); } 'config undef lives';
	lives_ok { $d->session(database => 'dummy'); } 'neo4j: session undef lives';
};


subtest 'bolt explicit' => sub {
	plan tests => 8;
	$d = Neo4j::Driver->new({ uri => 'bolt:' });
	$d->{config}->{net_module} = 'Local::Bolt';
	lives_ok { $s = 0; $s = $d->session(database => 'dummy'); } 'session';
	lives_and { ok $t = $s->begin_transaction } 'begin 1';
	throws_ok {
		$s->begin_transaction;
	}  qr/\bConcurrent transactions\b.*\bunsupported\b.*\bBolt\b/i, 'concurrent explicit dies';
	throws_ok {
		$s->execute_read(sub {});
	}  qr/\bConcurrent transactions\b.*\bunsupported\b.*\bBolt\b/i, 'concurrent managed in unmanaged dies';
	lives_ok { $t->commit } 'commit 1';
	lives_and { ok ! $t->is_open } 'closed 1';
	throws_ok {
		$s->execute_read(sub { $s->execute_read(sub {}) });
	}  qr/\bConcurrent transactions\b.*\bunsupported\b.*\bBolt\b/i, 'concurrent unmanaged in managed dies';
	throws_ok {
		$s->execute_read(sub { $s->begin_transaction });
	}  qr/\bConcurrent transactions\b.*\bunsupported\b.*\bBolt\b/i, 'concurrent managed in managed dies';
};


subtest 'bolt autocommit' => sub {
	plan tests => 6;
	$d = Neo4j::Driver->new({ uri => 'bolt:' });
	$d->{config}->{net_module} = 'Local::Bolt';
	lives_ok { $s = 0; $s = $d->session(database => 'dummy'); } 'session';
	lives_and { ok $t = $s->begin_transaction } 'begin 1';
	throws_ok {
		$s->run('');
	}  qr/\bConcurrent transactions\b.*\bunsupported\b.*\bBolt\b/i, 'concurrent auto dies';
	lives_ok { $t->commit } 'commit 1';
	lives_and { ok ! $t->is_open } 'closed 1';
	throws_ok {
		$s->execute_read(sub { $s->run('') });
	}  qr/\bConcurrent transactions\b.*\bunsupported\b.*\bBolt\b/i, 'concurrent managed dies';
};


subtest 'http explicit, concurrent enabled' => sub {
	plan tests => 8;
	$d = Neo4j::Driver->new->plugin($mock_plugin);
	lives_ok { $d->config( uri => 'http:', concurrent_tx => 1 ); } 'config on lives';
	lives_ok { $s = 0; $s = $d->session(database => 'dummy'); } 'session';
	my ($t1, $t2);
	lives_and { ok $t1 = $s->begin_transaction } 'begin 1';
	lives_and { isa_ok $r = $t1->run('foo'), Neo4j::Driver::Result:: } 'run 1';
	lives_and { ok $t2 = $s->begin_transaction } 'begin 2';
	lives_and { isa_ok $r = $t2->run('bar'), Neo4j::Driver::Result:: } 'run 2';
	lives_ok { $t1->commit } 'commit 1';
	lives_ok { $t2->commit } 'commit 2';
};


subtest 'http autocommit, concurrent enabled' => sub {
	plan tests => 6;
	$d = Neo4j::Driver->new->plugin($mock_plugin);
	lives_ok { $d->config( uri => 'http:', concurrent_tx => 1 ); } 'config on lives';
	lives_ok { $s = 0; $s = $d->session(database => 'dummy'); } 'session';
	lives_and { ok $t = $s->begin_transaction } 'begin expl';
	lives_and { isa_ok $r = $t->run('bar'), Neo4j::Driver::Result:: } 'run expl';
	lives_and { isa_ok $r = $s->run(''), Neo4j::Driver::Result:: } 'run auto';
	lives_ok { $t->commit } 'commit expl';
};


subtest 'http explicit, concurrent disabled' => sub {
	plan tests => 6;
	$d = Neo4j::Driver->new->plugin($mock_plugin);
	lives_ok { $d->config( uri => 'http:', concurrent_tx => 0 ); } 'config on lives';
	lives_ok { $s = 0; $s = $d->session(database => 'dummy'); } 'session';
	my ($t1, $t2);
	lives_and { ok $t1 = $s->begin_transaction } 'begin 1';
	lives_and { isa_ok $r = $t1->run('foo'), Neo4j::Driver::Result:: } 'run 1';
	throws_ok {
		$s->begin_transaction->run('bar');
	}  qr/\bConcurrent transactions\b.*\bHTTP\b.*\bdisabled\b/i, 'concurrent run dies';
	lives_ok { $t1->commit } 'commit 1';
};


subtest 'http autocommit, concurrent disabled' => sub {
	plan tests => 6;
	$d = Neo4j::Driver->new->plugin($mock_plugin);
	lives_ok { $d->config( uri => 'http:', concurrent_tx => 0 ); } 'config on lives';
	lives_ok { $s = 0; $s = $d->session(database => 'dummy'); } 'session';
	lives_and { ok $t = $s->begin_transaction } 'begin expl';
	lives_and { isa_ok $r = $t->run('bar'), Neo4j::Driver::Result:: } 'run expl';
	throws_ok {
		$s->run('');
	}  qr/\bConcurrent transactions\b.*\bHTTP\b.*\bdisabled\b/i, 'concurrent auto dies';
	lives_ok { $t->commit } 'commit expl';
};


subtest 'http managed, concurrent enabled' => sub {
	plan tests => 3;
	$d = Neo4j::Driver->new->plugin($mock_plugin);
	$d->config( uri => 'http:', concurrent_tx => 1 );
	$s = $d->session;
	my ($r1, $r2);
	lives_ok { $s->execute_write(sub {
		shift->run('foo');
		$r1 = $s->run('');
		$s->execute_write(sub { $r2 = shift->run('bar'); 1 });
	})} 'concurrent in execute lives';
	isa_ok $r1, Neo4j::Driver::Result::, 'run auto result';
	isa_ok $r2, Neo4j::Driver::Result::, 'execute result';
};


subtest 'http managed, concurrent disabled' => sub {
	plan tests => 2;
	$d = Neo4j::Driver->new->plugin($mock_plugin);
	$d->config( uri => 'http:', concurrent_tx => 0 );
	$s = $d->session;
	throws_ok {
		$s->execute_write(sub {
			shift->run('foo');
			$s->run('');
		});
	}  qr/\bConcurrent transactions\b.*\bHTTP\b.*\bdisabled\b/i, 'concurrent auto in managed dies';
	throws_ok {
		$s->execute_write(sub {
			shift->run('foo');
			$s->execute_write(sub { shift->run('bar') });
		});
	}  qr/\bConcurrent transactions\b.*\bHTTP\b.*\bdisabled\b/i, 'concurrent explicit in managed dies';
};


# old live/simulator tests from experimental.t


subtest 'live: explicit (REST)' => sub {
	my $session = eval { Neo4j_Test->driver->session };
	plan skip_all => "(test wants live HTTP)" if ! $session || $Neo4j_Test::bolt || $Neo4j_Test::sim;
	plan tests => 3;
	my ($t1, $t2);
	lives_ok {
		$t1 = $session->begin_transaction;
		$t1->run("CREATE (nested1:Test)");
	} 'explicit nested transactions: 1st';
	throws_ok {
		$t2 = $session->begin_transaction;
		$t2->run("CREATE (nested2:Test)");
	}  qr/\bConcurrent transactions\b.*\bHTTP\b.*\bdisabled\b/i, 'explicit in explicit dies';
	lives_ok { $t1->rollback; } 'explicit nested transactions: close 1st';
};


subtest 'live: explicit (Bolt)' => sub {
	my $session = eval { Neo4j_Test->driver->session };
	plan skip_all => "(test wants live Bolt)" if ! $session || ! $Neo4j_Test::bolt;
	plan tests => 4 if $Neo4j_Test::bolt;
	my ($t1, $t2);
	lives_ok {
		$t1 = $session->begin_transaction;
		$t1->run("CREATE (nested1:Test)");
	} 'explicit nested transactions: 1st';
	throws_ok {
		$t2 = $session->begin_transaction;
		$t2->run("CREATE (nested2:Test)");
	} qr/\bconcurrent\b/i, 'explicit nested transactions: 2nd';
	lives_ok { $t1->rollback; } 'explicit nested transactions: close 1st';
	dies_ok { $t2->rollback; } 'explicit nested transactions: close 2nd';
};


subtest 'live: autocommit' => sub {
	my $session = eval { Neo4j_Test->driver->session };
	plan skip_all => "(test wants live session)" if ! $session || $Neo4j_Test::sim;
	plan tests => 1;
	my $t = $session->begin_transaction;
	$t->run("CREATE (explicit1:Test)");
	throws_ok {
		$session->run("RETURN 42")->single->get(0);
	}  qr/\bConcurrent transactions\b/i, 'nested autocommit transactions: no success';
};


done_testing;

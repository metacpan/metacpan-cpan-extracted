#!perl
use strict;
use warnings;
use lib qw(./lib t/lib);

use Test::More 0.88;
use Test::Exception;
use Test::Warnings qw(warning);


# Concurrent transactions within the same session (in the context of Bolt
# called "nested transactions") are not allowed in the Neo4j Driver API,
# but are actually supported just fine when implemented via the
# Transactional HTTP API, which this driver can use for network communication.
# Therefore, this driver supports concurrent transactions for HTTP sessions.
# As of 0.30, this is an experimental feature (but expected to be mainlined).

use Neo4j_Test;
use Neo4j_Test::MockHTTP;

plan tests => 12 + 1;


my ($w, $d, $s, $t, $r);


# minimal dummy responses for HTTP
Neo4j_Test::MockHTTP::response_for 'foo' => {
	jolt => [
		'{"header":{"fields":[]}}',
		'{"summary":{}}',
		'{"info":{"commit":"http://localhost:7474/db/dummy/tx/5/commit","transaction":{"expires":"Tue, 1 Jan 2999 00:00:00 GMT"}}}',
	],
	status => 201,
	location => 'http://localhost:7474/db/dummy/tx/5',
};
Neo4j_Test::MockHTTP::response_for 'bar' => {
	jolt => [
		'{"header":{"fields":[]}}',
		'{"summary":{}}',
		'{"info":{"commit":"http://localhost:7474/db/dummy/tx/6/commit","transaction":{"expires":"Tue, 1 Jan 2999 00:00:00 GMT"}}}',
	],
	status => 201,
	location => 'http://localhost:7474/db/dummy/tx/6',
};
Neo4j_Test::MockHTTP::response_for '' => { jolt => [
	'{"header":{"fields":[]}}',
	'{"summary":{}}',
	'{"info":{}}',
]};


# minimal dummy net module for Bolt config tests
{
	package Local::Bolt;
	sub new { bless \(my $b = undef), shift }
	sub connect { &new }
	
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
	$d = Neo4j::Driver->new({ net_module => 'Local::Bolt' });
	lives_ok { $d->config( uri => 'bolt:', concurrent_tx => 1 ); } 'config on lives';
	throws_ok {
		$d->session(database => 'dummy');
	} qr/\bConcurrent transactions\b.*\bunsupported\b.*\bBolt\b/i, 'bolt session on dies';
	# config 0
	$d = Neo4j::Driver->new({ net_module => 'Local::Bolt' });
	lives_ok { $d->config( uri => 'bolt:', concurrent_tx => 0 ); } 'config off lives';
	lives_ok { $d->session(database => 'dummy'); } 'bolt session off lives';
	# config undef
	$d = Neo4j::Driver->new({ net_module => 'Local::Bolt' });
	lives_ok { $d->config( uri => 'bolt:' ); } 'config undef lives';
	lives_ok { $d->session(database => 'dummy'); } 'bolt session undef lives';
};


subtest 'config for http: uri' => sub {
	plan tests => 9;
	# config 1
	$d = Neo4j::Driver->new({ net_module => 'Neo4j_Test::MockHTTP' });
	lives_ok { $d->config( uri => 'http:', concurrent_tx => 1 ); } 'config on lives';
	lives_ok { $s = 0; $s = $d->session(database => 'dummy'); } 'session on lives';
	ok $s->{net}{want_concurrent}, 'concurrent tx on';
	# config 0
	$d = Neo4j::Driver->new({ net_module => 'Neo4j_Test::MockHTTP' });
	lives_ok { $d->config( uri => 'http:', concurrent_tx => 0 ); } 'config off lives';
	lives_ok { $s = 0; $s = $d->session(database => 'dummy'); } 'session off lives';
	ok ! $s->{net}{want_concurrent}, 'concurrent tx off';
	# config undef
	$d = Neo4j::Driver->new({ net_module => 'Neo4j_Test::MockHTTP' });
	lives_ok { $d->config( uri => 'http:', concurrent_tx => undef ); } 'config undef lives';
	lives_ok { $s = 0; $s = $d->session(database => 'dummy'); } 'session undef lives';
	ok $s->{net}{want_concurrent}, 'concurrent tx http default on';
};


subtest 'config for https: uri' => sub {
	plan tests => 9;
	# config 1
	$d = Neo4j::Driver->new({ net_module => 'Neo4j_Test::MockHTTP' });
	lives_ok { $d->config( uri => 'https:', concurrent_tx => 1 ); } 'config on lives';
	lives_ok { $s = 0; $s = $d->session(database => 'dummy'); } 'session on lives';
	ok $s->{net}{want_concurrent}, 'concurrent tx on';
	# config 0
	$d = Neo4j::Driver->new({ net_module => 'Neo4j_Test::MockHTTP' });
	lives_ok { $d->config( uri => 'https:', concurrent_tx => 0 ); } 'config off lives';
	lives_ok { $s = 0; $s = $d->session(database => 'dummy'); } 'session off lives';
	ok ! $s->{net}{want_concurrent}, 'concurrent tx off';
	# config undef
	$d = Neo4j::Driver->new({ net_module => 'Neo4j_Test::MockHTTP' });
	lives_ok { $d->config( uri => 'https:', concurrent_tx => undef ); } 'config undef lives';
	lives_ok { $s = 0; $s = $d->session(database => 'dummy'); } 'session undef lives';
	ok $s->{net}{want_concurrent}, 'concurrent tx https default on';
};


subtest 'bolt explicit' => sub {
	plan tests => 5;
	$d = Neo4j::Driver->new({ uri => 'bolt:', net_module => 'Local::Bolt' });
	lives_ok { $s = 0; $s = $d->session(database => 'dummy'); } 'session';
	lives_and { ok $t = $s->begin_transaction } 'begin 1';
	throws_ok {
		$s->begin_transaction;
	}  qr/\bConcurrent transactions\b.*\bunsupported\b.*\bBolt\b/i, 'concurrent explicit dies';
	lives_ok { $t->commit } 'commit 1';
	lives_and { ok ! $t->is_open } 'closed 1';
};


subtest 'bolt autocommit' => sub {
	plan tests => 5;
	$d = Neo4j::Driver->new({ uri => 'bolt:', net_module => 'Local::Bolt' });
	lives_ok { $s = 0; $s = $d->session(database => 'dummy'); } 'session';
	lives_and { ok $t = $s->begin_transaction } 'begin 1';
	throws_ok {
		$s->run('');
	}  qr/\bConcurrent transactions\b.*\bunsupported\b.*\bBolt\b/i, 'concurrent auto dies';
	lives_ok { $t->commit } 'commit 1';
	lives_and { ok ! $t->is_open } 'closed 1';
};


subtest 'http explicit, concurrent enabled' => sub {
	plan tests => 8;
	$d = Neo4j::Driver->new({ net_module => 'Neo4j_Test::MockHTTP' });
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
	$d = Neo4j::Driver->new({ net_module => 'Neo4j_Test::MockHTTP' });
	lives_ok { $d->config( uri => 'http:', concurrent_tx => 1 ); } 'config on lives';
	lives_ok { $s = 0; $s = $d->session(database => 'dummy'); } 'session';
	lives_and { ok $t = $s->begin_transaction } 'begin expl';
	lives_and { isa_ok $r = $t->run('bar'), Neo4j::Driver::Result:: } 'run expl';
	lives_and { isa_ok $r = $s->run(''), Neo4j::Driver::Result:: } 'run auto';
	lives_ok { $t->commit } 'commit expl';
};


subtest 'http explicit, concurrent disabled' => sub {
	plan tests => 11;
	$d = Neo4j::Driver->new({ net_module => 'Neo4j_Test::MockHTTP' });
	lives_ok { $d->config( uri => 'http:', concurrent_tx => 0 ); } 'config on lives';
	lives_ok { $s = 0; $s = $d->session(database => 'dummy'); } 'session';
	my ($t1, $t2);
	lives_and { ok $t1 = $s->begin_transaction } 'begin 1';
	lives_and { isa_ok $r = $t1->run('foo'), Neo4j::Driver::Result:: } 'run 1';
	lives_and { ok $t2 = $s->begin_transaction } 'begin 2';
	lives_ok { $w = ''; $w = warning { $r = $t2->run('bar') } } 'run 2 lives';
	like $w, qr/\bConcurrent transactions\b/i, 'run 2 warns'
		or diag 'got warning(s): ', explain $w;
	isa_ok $r, Neo4j::Driver::Result::, 'run 2 result';
	lives_ok { $w = ''; $w = warning { $t2->commit } } 'commit 2';
	like $w, qr/\bConcurrent transactions\b/i, 'commit 2 warns'
		or diag 'got warning(s): ', explain $w;
	lives_ok { $t1->commit } 'commit 1';
};


subtest 'http autocommit, concurrent disabled' => sub {
	plan tests => 8;
	$d = Neo4j::Driver->new({ net_module => 'Neo4j_Test::MockHTTP' });
	lives_ok { $d->config( uri => 'http:', concurrent_tx => 0 ); } 'config on lives';
	lives_ok { $s = 0; $s = $d->session(database => 'dummy'); } 'session';
	lives_and { ok $t = $s->begin_transaction } 'begin expl';
	lives_and { isa_ok $r = $t->run('bar'), Neo4j::Driver::Result:: } 'run expl';
	lives_ok { $w = ''; $w = warning { $r = $s->run('') } } 'run auto lives';
	like $w, qr/\bConcurrent transactions\b/i, 'run auto warns'
		or diag 'got warning(s): ', explain $w;
	isa_ok $r, Neo4j::Driver::Result::, 'run auto result';
	lives_ok { $t->commit } 'commit expl';
};


# old live/simulator tests from experimental.t


subtest 'live: explicit (REST)' => sub {
	my $session = eval { Neo4j_Test->driver->session };
	plan skip_all => "(no session)" unless $session;
	plan skip_all => '(currently testing Bolt)' if $Neo4j_Test::bolt;
	plan tests => 4 if ! $Neo4j_Test::bolt;
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


subtest 'live: explicit (Bolt)' => sub {
	my $session = eval { Neo4j_Test->driver->session };
	plan skip_all => "(no session)" unless $session;
	plan skip_all => '(currently testing HTTP)' if ! $Neo4j_Test::bolt;
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
	plan skip_all => "(no session)" unless $session;
	plan tests => 2;
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


done_testing;

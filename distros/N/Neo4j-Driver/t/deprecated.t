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

use Test::More 0.94;
use Test::Exception;
use Test::Warnings qw(warning warnings);
use Neo4j_Test::MockHTTP;
use Neo4j_Test::Sim;
my $transaction = $driver->session->begin_transaction;
$transaction->{return_stats} = 0;  # optimise sim

my $mock_plugin = Neo4j_Test::MockHTTP->new;
sub response_for { $mock_plugin->response_for(undef, @_) }

my ($d, $w, @w, $r);

plan tests => 20 + 3;


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


response_for 'deleted' => { json => <<END };
{"errors":[],"results":[{"columns":["n"],"data":[
{"meta":[{"deleted":true,"id":1,"type":"node"}],"rest":[{"metadata":{"id":1,"labels":["Test"]},"self":"/db/data/node/1"}],"row":[{}]},
{"meta":[{"deleted":false,"id":6,"type":"relationship"}],"rest":[{"end":"/db/data/node/5","metadata":{"id":6,"type":"TEST"},"self":"/db/data/relationship/6","start":"/db/data/node/7"}],"row":[{}]},
{"rest":[{"metadata":{"id":3,"labels":["Test"]},"self":"/db/data/node/3"}],"row":[{}]}
]}]}
END
subtest 'deleted()' => sub {
	plan tests => 8;
	my $d = Neo4j::Driver->new('http:');
	$d->plugin($mock_plugin);
	lives_and { $r = 0; ok $r = $d->session(database => 'dummy')->run('deleted') } 'run';
	lives_and { $w = warning { ok $r->fetch->get->deleted }; } 'deleted true';
	like $w, qr/\bdeleted\b.* deprecated\b/i, 'deleted true deprecated'
		or diag 'got warning(s): ', explain $w;
	lives_and { $w = warning { ok ! $r->fetch->get->deleted }; } 'deleted false';
	like $w, qr/\bdeleted\b.* deprecated\b/i, 'deleted false deprecated'
		or diag 'got warning(s): ', explain $w;
	lives_and { $w = warning { ok ! defined $r->fetch->get->deleted }; } 'deleted unknown';
	like $w, qr/\bdeleted\b.* deprecated\b/i, 'deleted unknown deprecated'
		or diag 'got warning(s): ', explain $w;
	lives_and { ok ! $r->has_next } 'no has_next';
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


subtest 'direct Neo4j::Driver hash access' => sub {
	# Direct hash access is known to have been used in the wild,
	# even though it was not officially supported at the time.
	plan tests => 3;
	$d = Neo4j::Driver->new()->plugin($mock_plugin);
	$d->{http_timeout} = 0.5;
	lives_ok { $w = ''; $w = warning { $d->session(database => 'dummy') }; } 'session';
	is $d->config('timeout'), 0.5, 'http_timeout set';
	like $w, qr/\bhttp_timeout\b.* deprecated\b/i, 'http_timeout deprecated'
		or diag 'got warning(s): ', explain $w;
};


subtest 'die_on_error = 0' => sub {
	# die_on_error only ever affected upstream errors via HTTP JSON, 
	# never any errors issued via Bolt/Jolt or by this driver itself.
	plan tests => 9;
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
	# broken server response
	my $mock = Neo4j_Test::MockHTTP->new;
	$mock->response_for(undef, 'foo' => { content_type => 'text/plain', content => 'bar' });
	$d = Neo4j::Driver->new('http:')->plugin($mock);
	$d->{die_on_error} = 0;
	lives_ok { $r = 0; warning { $r = $d->session->run('foo') }; } 'broken response lives';
	is ref($r), 'Neo4j::Driver::Result', 'broken response result fallback';
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


subtest 'jolt config option' => sub {
	plan tests => 13;
	lives_ok { $d = 0; $d = Neo4j_Test->driver_maybe(); } 'get driver';
	lives_ok { $w = ''; $w = warning { $d->config(jolt => 1); }; } 'jolt 1 lives';
	like $w, qr/\bjolt\b.*\bdeprecated\b/i, 'jolt 1 deprecated'
		or diag 'got warning(s): ', explain $w;
	is $d->{jolt}, 1, 'jolt 1';
	lives_ok { $w = ''; $w = warning { $d->config(jolt => 0); }; } 'jolt 0 lives';
	like $w, qr/\bjolt\b.*\bdeprecated\b/i, 'jolt 0 deprecated'
		or diag 'got warning(s): ', explain $w;
	is $d->{jolt}, 0, 'jolt 0';
	lives_ok { $w = ''; $w = warning { $d->config(jolt => undef); }; } 'jolt undef lives';
	is_deeply $w, [], 'jolt undef not deprecated'
		or diag 'got warning(s): ', explain $w;
	is $d->{jolt}, undef, 'jolt undef';
	lives_ok { $w = ''; $w = warning { $d->config(jolt => 'foo'); }; } 'jolt mode lives';
	like $w, qr/\bjolt\b.*\bdeprecated\b/i, 'jolt mode deprecated'
		or diag 'got warning(s): ', explain $w;
	is $d->{jolt}, 'foo', 'jolt mode';
};


subtest 'net_module config option' => sub {
	plan tests => 8;
	lives_ok { $d = 0; $d = Neo4j::Driver->new(); } 'new driver 1';
	lives_ok { $w = ''; $w = warning { $d->config(net_module => 'Neo4j_Test::Sim'); }; } 'config 1 lives';
	like $w, qr/\bnet_module\b.*\bdeprecated\b/i, 'net_module 1 deprecated'
		or diag 'got warning(s): ', explain $w;
	SKIP: { skip 'test design requires Sim', 1 unless $Neo4j_Test::sim;
	lives_ok { @w = (); @w = warnings { $d->session }; } 'session 1 lives';
	}
	lives_ok { $d = 0; $d = Neo4j::Driver->new(); } 'new driver 2';
	lives_ok { $w = ''; $w = warning { $d->config(net_module => 'Neo4j_Test::NoSuchModule_'); }; } 'config 2 lives';
	like $w, qr/\bnet_module\b.*\bdeprecated\b/i, 'net_module 2 deprecated'
		or diag 'got warning(s): ', explain $w;
	dies_ok { warnings { $d->session }; } 'session 2 dies';
};


{
	package Neo4j_Test::Plugin::NoNew;
	use parent 'Neo4j::Driver::Plugin';
	sub register { die }
}


subtest 'plug-in manager' => sub {
	plan tests => 9;
	my $m;
	lives_and { ok $m = Neo4j::Driver::Events->new } 'new';
	lives_ok { $w = ''; $w = warning {
		$m->_register_plugin( Neo4j_Test::MockHTTP:: );
	}} 'plugin by name';
	like $w, qr/\bplugin\b.*\bname\b.*\bdeprecated\b/i, 'plugin by name deprecated 1'
		or diag 'got warning(s): ', explain $w;
	throws_ok { warning {
		$m->_register_plugin( Neo4j_Test::Plugin::NoNew:: );
	}} qr/\bCan't locate\b.*\bmethod new\b.*\bNeo4j_Test::Plugin::NoNew\b/i, 'no new';
	
	lives_ok {
		$w = ''; $w = warning { $m->add_event_handler(x_test => sub {'foo'}); };
	} 'add_event_handler';
	like $w, qr/\badd_event_handler\b.*\bdeprecated\b/i, 'add_event_handler deprecated'
		or diag 'got warning(s): ', explain $w;
	lives_ok {
		$w = ''; $w = warning { $r = $m->trigger_event('x_test'); };
	} 'trigger_event lives';
	is $r, 'foo', 'trigger_event';
	like $w, qr/\btrigger_event\b.*\bdeprecated\b/i, 'trigger_event deprecated'
		or diag 'got warning(s): ', explain $w;
};


subtest 'cypher_filter' => sub {
	plan tests => 13;
	my ($t, @q);
	lives_ok { $d = 0; $d = Neo4j::Driver->new(); } 'new driver 1';
	lives_ok { $w = ''; $w = warning { $d->config(cypher_filter => 'params') }; } 'set filter';
	like $w, qr/\bcypher_filter\b.* deprecated\b/i, 'cypher_filter deprecated'
		or diag 'got warning(s): ', explain $w;
	lives_ok { $t = Neo4j_Test->transaction_unconnected($d); } 'new tx 1';
	@q = ('RETURN {`ab.`}, {c}, {cd}', 'ab.' => 17, c => 19, cd => 23);
	lives_ok { $r = 0; $r = $t->_prepare(@q); } 'prepare simple';
	is $r->{statement}, 'RETURN $`ab.`, $c, $cd', 'filtered simple';
	@q = ('CREATE (a) RETURN {}, {a:a}, {a}, [a]', a => 17);
	lives_ok { $r = 0; $r = $t->_prepare(@q); } 'prepare composite';
	is $r->{statement}, 'CREATE (a) RETURN {}, {a:a}, $a, [a]', 'filtered composite';
	lives_ok { $r = 0; $r = $t->_prepare('RETURN 42'); } 'prepare no params';
	is $r->{statement}, 'RETURN 42', 'filtered no params';
	lives_ok { $d = 0; $d = Neo4j::Driver->new(); } 'new driver 2';
	throws_ok {
		warning { $d->config(cypher_filter => 'coffee') };
	} qr/\bUnimplemented cypher filter\b/i, 'unprepared filter unkown name';
	lives_and {
		$d = Neo4j::Driver->new()->config( cypher_filter => 'water', cypher_params => v2 );
		is $d->{cypher_params_v2}, v2;
	} 'set both params ignores old syntax';
};


subtest 'ServerInfo protocol()' => sub {
	plan tests => 8;
	my ($si, $w);
	my %uri = (uri => URI->new('http:'));
	lives_and { ok $si = Neo4j::Driver::ServerInfo->new({%uri}) } 'new undef';
	lives_ok { $w = ''; $w = warning { my $p = $si->protocol() }; } 'protocol lives';
	like $w, qr/\bprotocol\b.*\bdeprecated\b/i, 'protocol deprecated'
		or diag 'got warning(s): ', explain $w;
	no warnings 'deprecated';
	lives_and { is $si->protocol(), 'HTTP' } 'protocol undef';
	lives_and { ok $si = Neo4j::Driver::ServerInfo->new({%uri, protocol => ''}) } 'new empty';
	lives_and { is $si->protocol(), 'Bolt' } 'protocol empty';
	lives_and { ok $si = Neo4j::Driver::ServerInfo->new({%uri, protocol => '2.2'}) } 'new version';
	lives_and { is $si->protocol(), 'Bolt/2.2' } 'protocol version';
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


subtest 'result stream interface: attachment' => sub {
	plan tests => 8;
	$r = $s->run('RETURN 42');
	my ($a, $c);
	lives_ok { $w = ''; $w = warning { $a = $r->attached } } 'is attached lives';
	like $w, qr/\battached\b.*\bdeprecated\b/i, 'attached deprecated'
		or diag 'got warning(s): ', explain $w;
	lives_ok { $w = ''; $w = warning { $c = $r->detach } } 'detach lives';
	like $w, qr/\bdetach\b.*\bdeprecated\b/i, 'detach deprecated'
		or diag 'got warning(s): ', explain $w;
	is $c, ($a ? 1 : 0), 'one row detached';
	lives_ok { warning { $a = $r->attached } } 'not attached lives';
	ok ! $a, 'not attached';
	lives_and { ok $r->has_next } 'not exhausted';
};


subtest 'run in list context' => sub {
	plan tests => 8;
	$q = <<END;
RETURN 7 AS n UNION RETURN 11 AS n
END
	my @a;
	lives_ok { $w = ''; $w = warning { @a = $s->run($q) }; } 'get result as list';
	like $w, qr/\brun\b.* in list context\b.* deprecated\b/i, 'result as list deprecated'
		or diag 'got warning(s): ', explain $w;
	lives_and { is $a[0]->get('n'), 7; } 'get record 0 in result list';
	lives_and { is $a[1]->get('n'), 11; } 'get record 1 in result list';
	
	SKIP: { skip 'explicit transactions unoptimised', 4 if $Neo4j_Test::sim;
		my $t = $driver->session->begin_transaction;
		lives_ok { $w = ''; $w = warning { @a = $t->run($q) }; } 'get result as list (explicit tx)';
		like $w, qr/\brun\b.* in list context\b.* deprecated\b/i, 'result as list deprecated (explicit tx)'
			or diag 'got warning(s): ', explain $w;
		lives_and { is $a[0]->get('n'), 7; } 'get record 0 in result list (explicit tx)';
		lives_and { is $a[1]->get('n'), 11; } 'get record 1 in result list (explicit tx)';
		eval { $t->rollback }; 1;
	}
};


subtest 'config tls options' => sub {
	plan tests => 3 + 3*2 + 5;
	my $ca_file = '/dev/null';
	my ($d1, $d2, $d3);
	lives_ok { $d1 = Neo4j::Driver->new(); } 'new driver tls';
	lives_ok { $d2 = Neo4j::Driver->new(); } 'new driver tls_ca';
	lives_ok { $d3 = Neo4j::Driver->new(); } 'new driver ca_file';
	lives_ok { $w = ''; $w = warning { $d1->config(tls => 7) }; } 'set config tls';
	is_deeply $w, [], 'tls not deprecated'
		or diag 'got warning(s): ', explain $w;
	lives_ok { $w = ''; $w = warning { $d2->config(tls_ca => $ca_file) }; } 'set config tls_ca';
	is_deeply $w, [], 'tls_ca not deprecated'
		or diag 'got warning(s): ', explain $w;
	lives_ok { $w = ''; $w = warning { $d3->config(ca_file => $ca_file) }; } 'set config ca_file';
	like $w, qr/\bca_file\b.*\bdeprecated\b/i, 'ca_file is deprecated'
		or diag 'got warning(s): ', explain $w;
	no warnings 'deprecated';  # there may or may not be warnings for the getters
	lives_and { is $d1->config('tls'), 7; } 'get tls';
	lives_and { is $d2->config('tls_ca'), $ca_file; } 'get tls_ca';
	lives_and { is $d2->config('trust_ca'), $ca_file; } 'get tls_ca trust_ca';
	lives_and { is $d3->config('ca_file'), $ca_file; } 'get ca_file';
	lives_and { is $d3->config('trust_ca'), $ca_file; } 'get ca_file trust_ca';
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


subtest 'graph queries' => sub {
	plan skip_all => "graph response not implemented for Bolt" if $Neo4j_Test::bolt;
	plan tests => 10;
	my $s_json = $driver->session;
	$s_json->{net}->{want_jolt} = 0;
	my $t = $s_json->begin_transaction;
	$t->{return_graph} = 1;
	$q = <<END;
CREATE ({name:'Alice'})-[k:KNOWS{since:1978}]->({name:'Bob'}) RETURN id(k)
END
	lives_ok { $w = ''; $w = warning { $r = $t->run($q)->single->get(0) }; } 'create graph';
	like $w, qr/\breturn_graph\b.*\bdeprecated\b/i, 'return_graph is deprecated'
		or diag 'got warning(s): ', explain $w;
	$q = <<END;
MATCH (a)-[b:KNOWS]->(c) WHERE id(b) = {id} RETURN a, b, c LIMIT 1
END
	lives_and { $w = ''; $w = warning { $r = $t->run($q, id => $r) }; ok $r; } 'match graph';
	like $w, qr/\breturn_graph\b.*\bdeprecated\b/i, 'return_graph is deprecated'
		or diag 'got warning(s): ', explain $w;
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
};


CLEANUP: {
	lives_ok { $transaction->rollback } 'rollback';
}


done_testing;


# for 'custom cypher types' test
package Local::Node;
BEGIN { our @ISA = qw(Neo4j::Driver::Type::Node) };

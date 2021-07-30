#!perl
use strict;
use warnings;
use lib qw(./lib t/lib);

use Test::More 0.88;
use Test::Exception;
use Test::Warnings qw(warning);


package Local::Bolt;
sub new { bless \(my $b = undef), shift }
sub connect { &new }
sub connect_tls { &new }

# Cxn
sub connected { 1 }
sub errnum { 0 }
sub errmsg { undef }
sub server_id { __PACKAGE__ }
sub run_query { my $b = shift; $$b = 0; $b }

# ResultStream
use JSON::PP;
my @row = (
	( bless { id => 11 }, 'Neo4j::Bolt::Node' ),
	( bless { id => 13 }, 'Neo4j::Bolt::Relationship' ),
	{ _node => 0.01 },
	{ _relationship => 0.01 },
	( bless [undef], 'Neo4j::Bolt::Path' ),
	[],
	{ no => JSON::PP::false() },
	42,
	( bless { properties => {} }, 'Neo4j::Bolt::Node' ),
	( bless { properties => {} }, 'Neo4j::Bolt::Relationship' ),
);
sub field_names { 0..9 }
sub fetch_next { my $b = shift; return if $$b; $$b = 1; @row }
sub update_counts { {} }
sub success { 1 }
sub failure { 0 }

package Local::Bolt::Txn;
use parent -norequire => 'Local::Bolt';
sub commit {}
sub rollback {}

package Local::Bolt::Failure;
use parent -norequire => 'Local::Bolt';
sub success { 0 }
sub failure { 1 }
sub errnum { -22 }
sub server_errcode { "oops" }
sub server_errmsg { "" }
sub protocol_version { 0 }
sub result_handlers { qw(Neo4j::Driver::Result::Bolt) }

package Local::Bolt::CxnFailure;
use parent -norequire => 'Local::Bolt::Failure';
sub connected { 0 }
sub client_errnum { -13 }
sub client_errmsg { "all wrong" }

package main;



# Simple test for Neo4j::Driver::Net::Bolt and friends
# (very "quick and dirty" -- started out as just net_module testing)

use Neo4j::Driver;

sub new_session {
	my $d = Neo4j::Driver->new('bolt:');
	$d->config(net_module => shift);
	$d->basic_auth(username => 'password');
	$d->{tls} = shift if scalar @_;
	$d->{auth} = shift if scalar @_;
	return ( $d, $d->session(database => 'dummy') );
}

my ($s, $f, $t, $r, $v);

plan tests => 1 + 8 + 1;


lives_and { ok $s = new_session('Local::Bolt') } 'driver';


subtest 'run empty' => sub {
	plan tests => 5;
	lives_and { ok $r = $s->run('') } 'empty lives';
	lives_and { is $r->size(), 0 } 'empty no rows';
	my ($w, @a) = ('', 0);
	lives_ok { $w = warning { @a = $s->run('') }; } 'empty list run';
	is_deeply [@a], [], 'empty list';
	like $w, qr/\brun\b.* in list context\b.* deprecated\b/i, 'result as list deprecated'
		or diag 'got warning(s): ', explain $w;
};


subtest 'deep_bless' => sub {
	plan tests => 23;
	lives_and { ok $r = $s->run('dummy') } 'run';
	lives_and { ok $v = $r->fetch } 'fetch';
	lives_and { ok ! $r->has_next } 'no has_next';
	isa_ok $v->get(0), 'Neo4j::Types::Node', 'node blessed';
	lives_and { is $v->get(0)->id(), 11 } 'node';
	lives_ok { $v->get(0)->get('prop') } 'node prop';
	lives_and { is_deeply [$v->get(0)->labels()], [] } 'node labels undef';
	isa_ok $v->get(1), 'Neo4j::Types::Relationship', 'rel blessed';
	lives_and { is $v->get(1)->id(), 13 } 'rel';
	lives_ok { $v->get(1)->get('prop') } 'rel prop';
	isa_ok $v->get(2), 'Neo4j::Types::Node', 'old node blessed';
	lives_and { is $v->get(2)->id(), 0.01 } 'old node';
	isa_ok $v->get(3), 'Neo4j::Types::Relationship', 'old rel blessed';
	lives_and { is $v->get(3)->id(), 0.01 } 'old rel';
	isa_ok $v->get(4), 'Neo4j::Types::Path', 'path blessed';
	lives_and { is_deeply [$v->get(4)->relationships], [] } 'no path length';
	is ref($v->get(5)), 'ARRAY', 'list';
	is scalar(@{$v->get(5)}), 0, 'list empty';
	is ref($v->get(6)), 'HASH', 'map';
	is scalar(keys %{$v->get(6)}), 1, 'map entry';
	ok ref($v->get(6)->{no}), 'bool blessed';
	ok ! $v->get(6)->{no}, 'bool false';
	is $v->get(7), 42, 'scalar';
};


subtest 'txn' => sub {
	plan tests => 9;
	lives_and { ok $t = $s->begin_transaction } 'begin 1';
	lives_and { ok $r = $t->run('dummy') } 'run';
	lives_and { is $r->size(), 1 } 'size';
	lives_and { is $r->list->[0]->get(7), 42 } 'get';
	lives_and { $t->rollback } 'rollback';
	dies_ok { $t->commit; } 'closed 1';
	lives_and { ok $t = $s->begin_transaction } 'begin 2';
	dies_ok { $s->begin_transaction } 'nested explicit';
	dies_ok { $s->run('') } 'nested auto';
	lives_and { $t->commit } 'commit';
	dies_ok { $t->rollback; } 'closed 2';
};


subtest 'auth' => sub {
	plan tests => 2;
	lives_ok { new_session('Local::Bolt', undef, undef) } 'no auth';
	throws_ok { new_session('Local::Bolt', undef, {scheme=>'magic'}) } qr/^Only Basic Auth/i, 'no magic auth';
};


subtest 'tls' => sub {
	plan tests => 1;
	lives_ok { new_session('Local::Bolt', 1) } 'tls';
};


subtest 'bolt error' => sub {
	plan tests => 7;
	ok $v = Neo4j::Driver::Net::Bolt->_bolt_error( $s->{net}->{connection} ), 'bolt_error call';
	is $v, "Bolt error 0", 'bolt_error output';
	lives_and { ok $f = new_session('Local::Bolt::Failure') } 'new failure';
	throws_ok { $f->run('dummy') } qr/Bolt error -22: Statement evaluation failed/i, 'run failure';
	dies_ok { $f->begin_transaction } 'no begin';
	throws_ok {
		no warnings 'deprecated';
		$f->run([['A'],['B']]);
	} qr/\bmultiple statements\b/i, 'no multiple';
	throws_ok { new_session('Local::Bolt::CxnFailure') } qr/Bolt error -13: all wrong/i, 'new cxn failure';
};


subtest 'gather_results' => sub {
	plan tests => 4;
	local $Neo4j::Driver::Result::Bolt::gather_results = 1;
	lives_and { ok $r = $s->run('dummy') } 'gather run';
	lives_and { is $r->single->get(7), 42 } 'gather get';
	local $Neo4j::Driver::Result::fake_attached = 1;
	lives_and { ok $r = $s->run('dummy') } 'fake run';
	lives_and { is $r->single->get(7), 42 } 'fake get';
};


subtest 'bolt live' => sub {
	plan tests => 1;
	throws_ok {
		Neo4j::Driver->new('bolt://localhost:14')->session();
	} qr/^Bolt error |\bNeo4j::Bolt not installed\b/i, 'bolt connect';
};


done_testing;

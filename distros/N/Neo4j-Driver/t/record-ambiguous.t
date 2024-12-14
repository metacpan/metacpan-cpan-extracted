#!perl
use strict;
use warnings;
use lib qw(./lib t/lib);

use Test::More 0.94;
use Test::Exception;
use Test::Warnings 0.010 qw(warning :no_end_test);
my $no_warnings;
use if $no_warnings = $ENV{AUTHOR_TESTING} ? 1 : 0, 'Test::Warnings';

use Neo4j_Test::MockHTTP;
use Neo4j::Driver;
use Neo4j::Driver::Record;


# Confirm that ambiguity in record field names is resolved correctly.

my ($d, $s, $r);

plan tests => 5 + $no_warnings;


my $mock_plugin = Neo4j_Test::MockHTTP->new;

my $mock_jolt_query;
sub mock_jolt_record {
	my $query = 'mock_jolt_query_' . ++$mock_jolt_query;
	$mock_plugin->response_for(undef, $query => { jolt => [
		{ header => { fields => shift } },
		{ data => shift },
		{ summary => {} },
		{ info => {} },
	]});
	return $query;
}

my %query = (
	'RETURN 2, 1 AS `0`'
		=> mock_jolt_record([qw( 2 0 )] => [ 2, 1 ]),
	'RETURN 0 AS `1`, 2'
		=> mock_jolt_record([qw( 1 2 )] => [ 0, 2 ]),
	'RETURN 1, 0, 2'
		=> mock_jolt_record([qw( 1 0 2 )] => [ 1, 0, 2 ]),
);

$d = Neo4j::Driver->new('http:')->plugin($mock_plugin);
$s = $d->session;


subtest 'ambiguous index/key 0' => sub {
	plan tests => 7;
	$r = $s->run($query{'RETURN 2, 1 AS `0`'})->fetch;
	is $r->get( 0 ), 2, 'get( 0 )';
	is $r->get("0"), 1, 'get("0")';
	is $r->get( 1 ), 1, 'get( 1 )';
	is $r->get("1"), 1, 'get("1")';
	is $r->get( 2 ), 2, 'get( 2 )';
	is $r->get("2"), 2, 'get("2")';
	is_deeply $r->data, { 2 => 2, 0 => 1 }, 'data hashref';
};


subtest 'ambiguous index/key 1' => sub {
	plan tests => 7;
	$r = $s->run($query{'RETURN 0 AS `1`, 2'})->fetch;
	is $r->get( 0 ), 0, 'get( 0 )';
	is $r->get("0"), 0, 'get("0")';
	is $r->get( 1 ), 2, 'get( 1 )';
	is $r->get("1"), 0, 'get("1")';
	is $r->get( 2 ), 2, 'get( 2 )';
	is $r->get("2"), 2, 'get("2")';
	is_deeply $r->data, { 1 => 0, 2 => 2 }, 'data hashref';
};


subtest 'ambiguous index/key vice-versa' => sub {
	plan tests => 7;
	$r = $s->run($query{'RETURN 1, 0, 2'})->fetch;
	is $r->get( 0 ), 1, 'get( 0 )';
	is $r->get("0"), 0, 'get("0")';
	is $r->get( 1 ), 0, 'get( 1 )';
	is $r->get("1"), 1, 'get("1")';
	is $r->get( 2 ), 2, 'get( 2 )';
	is $r->get("2"), 2, 'get("2")';
	is_deeply $r->data, { 1 => 1, 0 => 0, 2 => 2 }, 'data hashref';
};


subtest 'get without field' => sub {
	plan tests => 3;
	$r = $s->run($query{'RETURN 1, 0, 2'})->fetch;
	my $w;
	lives_ok { $w = warning { $r->get; } } 'get without field lives';
	like $w, qr/\bambiguous\b.*\bget\b.*\bfield/i, 'get without field ambiguous'
		or diag 'got warning(s): ', explain $w;
	throws_ok { $r->get('') }
		qr/\bField '' not present\b/i, 'get with empty string dies';
};


subtest 'created_as_number' => sub {
	plan tests => 7;
	ok   Neo4j::Driver::Record::_SvNIOKp(0), '0 is number';
	ok   Neo4j::Driver::Record::_SvNIOKp(-1), '-1 is number';
	ok   Neo4j::Driver::Record::_SvNIOKp(.1), '.1 is number';
	ok ! Neo4j::Driver::Record::_SvNIOKp(""), '"" is string';
	ok ! Neo4j::Driver::Record::_SvNIOKp("1"), '"1" is string';
	ok ! Neo4j::Driver::Record::_SvNIOKp("NaN"), '"NaN" is string';
	ok ! Neo4j::Driver::Record::_SvNIOKp({}), '{} is stringy';
};


done_testing;

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


# Confirm that ambiguity in record field names is resolved correctly.

my ($d, $s, $r);

plan tests => 4 + $no_warnings;


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
	plan tests => 6;
	$r = $s->run($query{'RETURN 2, 1 AS `0`'})->fetch;
	is $r->get( 0 ), 2, 'get( 0 )';
	is $r->get("0"), 1, 'get("0")';
	is $r->get( 1 ), 1, 'get( 1 )';
	is $r->get("1"), 1, 'get("1")';
	is $r->get( 2 ), 2, 'get( 2 )';
	is $r->get("2"), 2, 'get("2")';
};


subtest 'ambiguous index/key 1' => sub {
	plan tests => 6;
	$r = $s->run($query{'RETURN 0 AS `1`, 2'})->fetch;
	is $r->get( 0 ), 0, 'get( 0 )';
	is $r->get("0"), 0, 'get("0")';
	is $r->get( 1 ), 2, 'get( 1 )';
	is $r->get("1"), 0, 'get("1")';
	is $r->get( 2 ), 2, 'get( 2 )';
	is $r->get("2"), 2, 'get("2")';
};


subtest 'ambiguous index/key vice-versa' => sub {
	plan tests => 6;
	$r = $s->run($query{'RETURN 1, 0, 2'})->fetch;
	is $r->get( 0 ), 1, 'get( 0 )';
	is $r->get("0"), 0, 'get("0")';
	is $r->get( 1 ), 0, 'get( 1 )';
	is $r->get("1"), 1, 'get("1")';
	is $r->get( 2 ), 2, 'get( 2 )';
	is $r->get("2"), 2, 'get("2")';
};


subtest 'get without field' => sub {
	plan tests => 2;
	$r = $s->run($query{'RETURN 1, 0, 2'})->fetch;
	my $w;
	lives_ok { $w = warning { $r->get; } } 'get without field lives';
	like $w, qr/\bambiguous\b.*\bget\b.*\bfield/i, 'get without field ambiguous'
		or diag 'got warning(s): ', explain $w;
};


done_testing;

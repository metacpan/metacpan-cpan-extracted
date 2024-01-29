#!perl
use strict;
use warnings;
use lib qw(./lib t/lib);

use Test::More 0.94;
use Test::Warnings 0.010 qw(:no_end_test);
my $no_warnings;
use if $no_warnings = $ENV{AUTHOR_TESTING} ? 1 : 0, 'Test::Warnings';


use Neo4j::Error;

plan tests => 3 + $no_warnings;

my $e;


subtest 'http' => sub {
	plan tests => 7;
	ok $e = Neo4j::Error->new(Network => {
		code => '401',
		message => 'Unauthorized',
		raw => '<title>Identify yourself!</title>',
	}), 'new';
	isa_ok $e, 'Neo4j::Error::Network', 'class network';
	is $e->code(), '401', 'code';
	is $e->message(), 'Unauthorized', 'message';
	like $e->as_string(), qr/\b401\b.*\bUnauthorized\b/i, 'as_string';
	ok $e->raw(), 'yes raw';
	ok $e->is_retryable(), 'yes is_retryable';
};


subtest 'bolt' => sub {
	plan tests => 8;
	ok $e = Neo4j::Error->new(Network => {
		code => -22,
		message => 'Statement evaluation failed',
	}), 'new';
	isa_ok $e, 'Neo4j::Error::Network', 'class network';
	is $e->code(), -22, 'code';
	is $e->message(), 'Statement evaluation failed', 'message';
	like $e->as_string(), qr/-22\b.*\bStatement evaluation\b/i, 'as_string';
	my @r = $e->raw;
	ok ! defined $r[0], 'no raw';
	is scalar(@r), 1, 'no raw returns scalar in list context';
	ok $e->is_retryable(), 'yes is_retryable';
};


subtest 'metadata' => sub {
	plan tests => 5;
	ok $e = Neo4j::Error->new(Network => 'Unknown network failure'), 'new';
	isa_ok $e, 'Neo4j::Error::Network', 'class Network';
	is $e->classification(), '', 'no classification';
	is $e->category(), '', 'no category';
	is $e->title(), '', 'no title';
};


done_testing;

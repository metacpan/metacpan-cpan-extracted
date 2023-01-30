#!perl
use strict;
use warnings;
use lib qw(./lib t/lib);

use Test::More 0.94;
use Test::Warnings;


use Neo4j::Error;

plan tests => 2 + 1;

my $e;


subtest 'internal' => sub {
	plan tests => 5;
	ok $e = Neo4j::Error->new(Internal => {
		code => 'WTF',
		message => 'whatever',
		as_string => 'Unexpected error',
	}), 'new';
	isa_ok $e, 'Neo4j::Error::Internal', 'class Internal';
	is $e->code(), 'WTF', 'code';
	is $e->message(), 'whatever', 'message';
	is $e->as_string(), 'Unexpected error', 'as_string';
};


subtest 'metadata' => sub {
	plan tests => 6;
	ok $e = Neo4j::Error->new(Internal => 'Unexpected error'), 'new';
	isa_ok $e, 'Neo4j::Error::Internal', 'class Internal';
	is $e->classification(), '', 'no classification';
	is $e->category(), '', 'no category';
	is $e->title(), '', 'no title';
	ok ! $e->is_retryable(), 'no is_retryable';
};


done_testing;

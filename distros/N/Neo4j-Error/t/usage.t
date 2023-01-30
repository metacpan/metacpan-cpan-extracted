#!perl
use strict;
use warnings;
use lib qw(./lib t/lib);

use Test::More 0.94;
use Test::Warnings;


use Neo4j::Error;

plan tests => 3 + 1;

my $e;


subtest 'message only' => sub {
	plan tests => 5;
	ok $e = Neo4j::Error->new(Usage => {
		message => 'Illegal arguments',
	}), 'new';
	isa_ok $e, 'Neo4j::Error::Usage', 'class Usage';
	is $e->code(), '', 'no code';
	is $e->message(), 'Illegal arguments', 'message';
	is $e->as_string(), 'Illegal arguments', 'as_string';
};


subtest 'string only' => sub {
	plan tests => 5;
	ok $e = Neo4j::Error->new(Usage => {
		as_string => 'Illegal arguments',
	}), 'new';
	isa_ok $e, 'Neo4j::Error::Usage', 'class Usage';
	is $e->code(), '', 'no code';
	is $e->message(), '', 'no message';
	is $e->as_string(), 'Illegal arguments', 'as_string';
};


subtest 'metadata' => sub {
	plan tests => 6;
	ok $e = Neo4j::Error->new(Usage => 'Illegal arguments'), 'new';
	isa_ok $e, 'Neo4j::Error::Usage', 'class Usage';
	is $e->classification(), '', 'no classification';
	is $e->category(), '', 'no category';
	is $e->title(), '', 'no title';
	ok ! $e->is_retryable(), 'no is_retryable';
};


done_testing;

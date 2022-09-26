#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
BEGIN { $Data::Dumper::Useqq = 1; }

use Test::More;
use Test::FailWarnings;

use Protocol::Dqlite;

my @tt = (
	{
		req => [ 'CLIENT', 0 ],
		msg => "\1\0\0\0\1\0\0\0\0\0\0\0\0\0\0\0",
	},
	{
		req => ['CLUSTER'],
		msg => "\1\0\0\0\20\0\0\0\1\0\0\0\0\0\0\0",
	},
	{
		req => [ 'OPEN', qw( demo 0 volatile ) ],
		msg => "\4\0\0\0\3\0\0\0demo\0\0\0\0\0\0\0\0\0\0\0\0volatile\0\0\0\0\0\0\0\0",
	},
	{
		req => ['QUERY_SQL', 0, 'select * from sqlite_master'],
		msg => "\6\0\0\0\t\0\0\0\0\0\0\0\0\0\0\0select * from sqlite_master\0\0\0\0\0\0\0\0\0\0\0\0\0",
	},
	{
		req => ['QUERY_SQL', 0, 'select ?, 23 + ?',
			Protocol::Dqlite::TUPLE_FLOAT, 7.34,
			Protocol::Dqlite::TUPLE_INT64, 9,
		],
		msg => "\a\0\0\0\t\0\0\0\0\0\0\0\0\0\0\0select ?, 23 + ?\0\0\0\0\0\0\0\0\2\2\1\0\0\0\0\0\\\217\302\365(\\\35\@\t\0\0\0\0\0\0\0",
	},
	{
		req => [ 'QUERY_SQL', 0, 'select ?',
			Protocol::Dqlite::TUPLE_STRING, "\xe9p\xe9e",
		],
		msg => "\5\0\0\0\t\0\0\0\0\0\0\0\0\0\0\0select ?\0\0\0\0\0\0\0\0\1\3\0\0\0\0\0\0\303\251p\303\251e\0\0",
	},
);

for my $t (@tt) {
	my ($type, @args) = @{ $t->{'req'} };
	my $bytes = Protocol::Dqlite::request(
		Protocol::Dqlite->can("REQUEST_$type")->(),
		@args,
	);

	is($bytes, $t->{'msg'}, "REQUEST_$type") or diag explain $bytes;
}

done_testing;

1;

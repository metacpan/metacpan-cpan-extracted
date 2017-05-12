#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use Test::More;
use Parse::DNS::Zone;

sub f { Parse::DNS::Zone::_fqdnize(@_) }

my @tests = (
	[ '.', undef, '.' ],
	[ 'example.com.', undef, 'example.com.' ],
	[ 'example', 'com.', 'example.com.' ],
	[ 'example.', 'com.', 'example.' ],
	[ 'example', '.', 'example.' ],
	[ 'example', 'com', 'example.com.' ],
);

plan tests => int @tests;

is f($_->[0], $_->[1]), $_->[2] for @tests;

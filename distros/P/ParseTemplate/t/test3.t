#!/usr/local/bin/perl

BEGIN {  push(@INC, './t') }	# where is W.pm
use W;

print W->new()->test("test3", "examples/derived.pl", *DATA);

__DATA__
ANCESTOR template: 'TOP' part ->
CHILD template:  'CHILD' part ->
PARENT template:  'PARENT' part ->
ANCESTOR template: 'ANCESTOR' part





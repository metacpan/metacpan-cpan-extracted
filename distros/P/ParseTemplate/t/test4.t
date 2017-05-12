#!/usr/local/bin/perl

BEGIN {  push(@INC, './t') }	# where is W.pm
use W;

print W->new()->test('test4', "examples/recursive.pl", *DATA);

__DATA__
[[[[[[[[[[]]]]]]]]]]




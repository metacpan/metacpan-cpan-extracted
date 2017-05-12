#!/usr/local/bin/perl

BEGIN {  push(@INC, './t') }	# where is W.pm
use W;

print W->new()->test('test6', "examples/delegation2.pl", *DATA);

__DATA__
$A->ANCESTOR(): ANCESTOR/ANCESTOR ->ANCESTOR/ SUB_PART
$C->CHILD(): CHILD/ CHILD -> ANCESTOR/ANCESTOR ->CHILD/ SUB_PART
$C->SUB_PART(): CHILD/ SUB_PART

#!perl
use strict;
use warnings;

use lib qw(../lib/);

use Test::More;

my $class = 'Set::Similarity::CosinePP';

use_ok($class);

my $object = new_ok($class);

sub d3 { sprintf('%.3f',shift) }


is(d3($object->similarity()),'1.000','empty params');
is(d3($object->similarity('a',)),'0.000','a string');
is(d3($object->similarity('a','b')),'0.000','a,b strings');

is(d3($object->similarity([],['a','b'])),'0.000','empty, ab tokens');
is(d3($object->similarity(['a','b'],[])),'0.000','ab, empty tokens');
is(d3($object->similarity([],[])),'1.000','both empty tokens');


is(d3($object->similarity(['a','b'],['a','b'])),'1.000','equal  ab tokens');
is(d3($object->similarity(['a','b'],['c','d'])),'0.000','ab unequal cd tokens');
is(d3($object->similarity(['a','b'],['b','c'])),'0.500','ab unequal bc tokens');

is(d3($object->similarity(['a','b','a','a'],['b','c','c','c'])),'0.500','abaa 0.5 bccc tokens');
is(d3($object->similarity(['a','b','a','b'],['b','c','c','c'])),'0.500','abab 0.5 bccc tokens');


is(d3($object->similarity('ab','ab')),'1.000','equal  ab strings');
is(d3($object->similarity('ab','cd')),'0.000','ab unequal cd strings');
is(d3($object->similarity('abaa','bccc')),'0.500','abaa 0.5 bccc strings');
is(d3($object->similarity('abab','bccc')),'0.500','abab 0.5 bccc strings');
is(d3($object->similarity('ab','abcd')),'0.707','ab 0.707 abcd strings');

is(d3($object->similarity('ab','ab',2)),'1.000','equal  ab bigrams');
is(d3($object->similarity('ab','cd',2)),'0.000','ab unequal cd bigrams');
is(d3($object->similarity('abaa','bccc',2)),'0.000','abaa 0 bccc bigrams');
is(d3($object->similarity('abcabcf','bcccah',2)),'0.500','abcabcf 0.5 bcccah bigrams');
is(d3($object->similarity('abc','abcdef',2)),'0.632','abc 0.632 abcdef bigrams');

is(d3($object->similarity('Photographer','Fotograf')),'0.630','Photographer 0.630 Fotograf strings');
is(d3($object->similarity('Photographer','Fotograf',2)),'0.570','Photographer 0.570 Fotograf bigrams');
is(d3($object->similarity('Photographer','Fotograf',3)),'0.516','Photographer 0.516 Fotograf trigrams');


done_testing;

#!perl
use strict;
use warnings;

use lib qw(../lib/);

use Test::More;

my $class = 'Set::Similarity::Dice';

use_ok($class);

#my $object = new_ok($class);

my $object = $class;

is($object->from_tokens([],['a','b']),0,'empty, ab tokens');
is($object->from_tokens(['a','b'],[]),0,'ab, empty tokens');
is($object->from_tokens([],[]),1,'both empty tokens');
is($object->from_tokens([1],[1]),1,'equal tokens');


is($object->similarity(),1,'empty params');
is($object->similarity('a',),0,'a string');
is($object->similarity('a','b'),0,'a,b strings');

is($object->similarity([],['a','b']),0,'empty, ab tokens');
is($object->similarity(['a','b'],[]),0,'ab, empty tokens');
is($object->similarity([],[]),1,'both empty tokens');
is($object->similarity(['a','b'],['a','b']),1,'equal  ab tokens');
is($object->similarity(['a','b'],['c','d']),0,'ab unequal cd tokens');
is($object->similarity(['a','b','a','a'],['b','c','c','c']),0.5,'abaa 0.5 bccc tokens');
is($object->similarity(['a','b','a','b'],['b','c','c','c']),0.5,'abab 0.5 bccc tokens');

is($object->similarity('ab','ab'),1,'equal  ab strings');
is($object->similarity('ab','cd'),0,'ab unequal cd strings');
is($object->similarity('abaa','bccc'),0.5,'abaa 0.5 bccc strings');
is($object->similarity('abab','bccc'),0.5,'abab 0.5 bccc strings');

is($object->similarity('ab','ab',2),1,'equal  ab bigrams');
is($object->similarity('ab','cd',2),0,'ab unequal cd bigrams');
is($object->similarity('abaa','bccc',2),0,'abaa 0 bccc bigrams');
is($object->similarity('abcabcf','bcccah',2),0.5,'abcabcf 0.5 bcccah bigrams');

is($object->similarity('Photographer','Fotograf'),0.625,'Photographer 0.625 Fotograf strings');
ok($object->similarity('Photographer','Fotograf',2) > 0.55,'Photographer 0.555 Fotograf bigrams');
is($object->similarity('Photographer','Fotograf',3),0.5,'Photographer 0.5 Fotograf trigrams');


done_testing;

#!perl
use strict;
use warnings;

use lib qw(../lib/);

use Test::More;

my $class = 'Set::Similarity::BV::Jaccard';

use_ok($class);

#my $object = new_ok($class);

my $object = $class;

sub d3 { sprintf('%.3f',shift) }

is($object->similarity(),1,'empty params');
is($object->similarity('a',),0,'a string');
is($object->similarity('8','4'),0,'a,b strings');

is($object->similarity('0','a'),0,'0, a');
is($object->similarity(['ab'],'0'),0,'ab, 0');
is($object->similarity('0','0'),1,'both 0');


is($object->similarity('ab','ab'),1,'equal  ab');
is($object->similarity('a0','0a'),0,'a0 unequal 0a');
is(d3($object->similarity('e','7')),d3(0.5),'e 0.5 7');

is(d3($object->similarity('e'x8,'7'x8)),d3(0.5),'ex8 0.5 7x8');

done_testing;

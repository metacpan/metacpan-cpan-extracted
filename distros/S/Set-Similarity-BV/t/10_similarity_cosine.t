#!perl
use strict;
use warnings;

use lib qw(../lib/);

use Test::More;

my $class = 'Set::Similarity::BV::Cosine';

use_ok($class);

my $object = new_ok($class);

#my $object = $class;

sub d3 { sprintf('%.3f',shift) }

is($object->similarity(),1,'empty params');
is($object->similarity('a',),0,'a string');
is($object->similarity('8','4'),0,'8,4 strings');

is($object->similarity('0','a'),0,'0, a');
is($object->similarity('ab','0'),0,'ab, 0');
is($object->similarity('0','0'),1,'both 0');

is($object->similarity('ab','ab'),1,'equal  ab');

is($object->similarity('a0','0a'),0,'a0 unequal 0a');
is(d3($object->similarity('f','3')),d3(0.707),'f 0.707 3');

is(d3($object->similarity('f'x8,'3'x8)),d3(0.707),'fx8 0.707 3x8');
is(d3($object->similarity('ff'x8,'33'x8)),d3(0.707),'ffx8 0.707 33x8');
is(d3($object->similarity('ff'x16,'33'x16)),d3(0.707),'ffx16 0.707 33x16');
is(d3($object->similarity('ff'x17,'33'x17)),d3(0.707),'ffx17 0.707 33x17');
is($object->similarity('ff'x8,'ff'x8),1,'ffx8 1 ffx8');

done_testing;

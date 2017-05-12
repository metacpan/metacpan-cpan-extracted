#!perl
use strict;
use warnings;

use lib qw(../lib/ ./lib/);

use Test::More;
use Data::Dumper;

my $c = 'Set::Similarity::Cosine';

use_ok($c);

my $pp = new_ok($c);

my $cpdl = 'Set::Similarity::CosinePDL';

use_ok($cpdl);

my $pdl = new_ok($cpdl);


#my $object = $class;

sub d3 { sprintf('%.3f',shift) }

is($pp->similarity('ab','ab'),1,'equal  ab strings');
is($pp->similarity('ab','cd'),0,'ab unequal cd strings');
is($pp->similarity('abaa','bccc'),0.5,'abaa 0.5 bccc strings');
is($pp->similarity('abab','bccc'),0.5,'abab 0.5 bccc strings');
is(d3($pp->similarity('ab','abcd')),0.707,'ab 0.707 abcd strings');

is($pp->similarity('ab','ab',2),1,'equal  ab bigrams');
is($pp->similarity('ab','cd',2),0,'ab unequal cd bigrams');
is($pp->similarity('abaa','bccc',2),0,'abaa 0 bccc bigrams');
is($pp->similarity('abcabcf','bcccah',2),0.5,'abcabcf 0.5 bcccah bigrams');
is(d3($pp->similarity('abc','abcdef',2)),0.632,'abc 0.632 abcdef bigrams');

is(d3($pp->similarity('Photographer','Fotograf')),'0.630','Photographer 0.630 Fotograf strings');
is(d3($pp->similarity('Photographer','Fotograf',2)),'0.570','Photographer 0.570 Fotograf bigrams');
is(d3($pp->similarity('Photographer','Fotograf',3)),0.516,'Photographer 0.516 Fotograf trigrams');



is($pdl->similarity('ab','ab'),1,'equal  ab strings');
is($pdl->similarity('ab','cd'),0,'ab unequal cd strings');
is($pdl->similarity('abaa','bccc'),0.5,'abaa 0.5 bccc strings');
is($pdl->similarity('abab','bccc'),0.5,'abab 0.5 bccc strings');
is(d3($pdl->similarity('ab','abcd')),0.707,'ab 0.707 abcd strings');

is($pdl->similarity('ab','ab',2),1,'equal  ab bigrams');
is($pdl->similarity('ab','cd',2),0,'ab unequal cd bigrams');
is($pdl->similarity('abaa','bccc',2),0,'abaa 0 bccc bigrams');
is($pdl->similarity('abcabcf','bcccah',2),0.5,'abcabcf 0.5 bcccah bigrams');
is(d3($pdl->similarity('abc','abcdef',2)),0.632,'abc 0.632 abcdef bigrams');

is(d3($pdl->similarity('Photographer','Fotograf')),'0.630','Photographer 0.630 Fotograf strings');
is(d3($pdl->similarity('Photographer','Fotograf',2)),'0.570','Photographer 0.570 Fotograf bigrams');
is(d3($pdl->similarity('Photographer','Fotograf',3)),0.516,'Photographer 0.516 Fotograf trigrams');


done_testing;

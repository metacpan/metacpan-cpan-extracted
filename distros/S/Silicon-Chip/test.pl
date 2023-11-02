#!/usr/bin/perl -I/home/phil/perl/cpan/SiliconChip/lib/
#-------------------------------------------------------------------------------
# Test Silicon Chip
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2016
#-------------------------------------------------------------------------------
use warnings FATAL => qw(all);
use strict;
use Silicon::Chip;
use Test::More;

my $c = Silicon::Chip::newChip;
   $c->gate("input",  "i1");
   $c->gate("input",  "i2");
   $c->gate("and",    "and1", {1=>q(i1), 2=>q(i2)});
   $c->gate("output", "o", "and1");
my $s = $c->simulate({i1=>1, i2=>1});

ok($s->steps          == 2);
ok($s->values->{and1} == 1);
done_testing();

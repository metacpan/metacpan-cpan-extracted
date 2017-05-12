#!perl

use strict;
use warnings;
use 5.010;
use Carp;

use Test::More;
use Test::Deep;

use Pod::Coverage::mop;
use lib 't/lib';

my $pc = Pod::Coverage::mop->new(package => 'PurePerlClass');
isa_ok($pc, 'Pod::Coverage::CountParents');
ok(defined($pc->coverage));
cmp_deeply([ $pc->covered ], bag(qw/pp_i_am_covered/));
cmp_deeply([ $pc->uncovered ], bag(qw/pp_i_am_not_covered/));

done_testing;

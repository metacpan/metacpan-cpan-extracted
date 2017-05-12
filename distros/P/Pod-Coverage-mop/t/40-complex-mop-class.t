#!perl

use strict;
use warnings;
use 5.010;
use Carp;

use Test::More;
use Test::Deep;

use Pod::Coverage::mop;
use lib 't/lib';

my $pc = new_ok('Pod::Coverage::mop', [ package => 'ComposedMopClass' ]);
ok(defined($pc->coverage));
cmp_deeply([ $pc->covered ], bag(qw/composed_public_stuff composed_i_am_covered/));
cmp_deeply([ $pc->uncovered ], bag(qw/composed_i_am_not_covered/));

done_testing;

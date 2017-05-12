#!perl

use strict;
use warnings;
use 5.010;
use Carp;

use Test::More;
use Test::Deep;

use Pod::Coverage::mop;
use lib 't/lib';

my $pc = new_ok('Pod::Coverage::mop', [ package => 'PureMopRole' ]);
ok(defined($pc->coverage));
cmp_deeply([ $pc->covered ], bag(qw/role_public_stuff role_i_am_covered/));
cmp_deeply([ $pc->uncovered ], bag(qw/role_i_am_not_covered/));

done_testing;

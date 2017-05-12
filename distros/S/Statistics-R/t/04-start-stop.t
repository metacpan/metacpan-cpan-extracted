#! perl

use strict;
use warnings;
use Test::More;
use Statistics::R;
use Cwd;

my $R;

my $initial_dir = cwd;

ok $R = Statistics::R->new();

is $R->is_started, 0;

is $R->is_shared, 0;

ok $R->stop();

ok $R->stop();

ok $R->start();

is $R->is_started, 1;

is $R->is_shared, 0;

ok $R->start();

is cwd, $initial_dir; # Bug RT #6724 and #70307

ok $R->restart();

ok $R->stop();

ok $R->start( shared => 1);

is $R->is_shared, 1;

ok $R->stop();

is cwd, $initial_dir; # Bug RT #6724 and #70307

done_testing;

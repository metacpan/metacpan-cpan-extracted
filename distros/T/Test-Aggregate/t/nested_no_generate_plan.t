#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib', 't/lib';
use Test::Aggregate::Nested;

use Test::More;
plan skip_all => 'Need Test::More::subtest() for this test'
    unless Test::More->can('subtest');

my $dump = 'dump.t';
my $tests = Test::Aggregate::Nested->new(
    {   verbose          => 2,
        shuffle          => 1,
        dirs             => [ 'aggtests', 'aggtests-nested' ],
        set_filenames    => 1,
        findbin          => 1,
        test_nowarnings  => 0,
        no_generate_plan => 1,
    }
);
$tests->run;

ok(1, "A test at the end");
done_testing();

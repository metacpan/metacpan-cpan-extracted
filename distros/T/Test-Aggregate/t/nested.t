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
    {   verbose         => 2,
        shuffle         => 1,
        dirs            => [ 'aggtests', 'aggtests-nested' ],
        set_filenames   => 1,
        findbin         => 1,
        test_nowarnings => 0,
    }
);
$tests->run;

#ok -f $dump, '... and we should have written out a dump file';
#unlink $dump or warn "Cannot unlink ($dump): $!";

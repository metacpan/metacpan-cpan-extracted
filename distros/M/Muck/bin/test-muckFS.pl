#!/usr/bin/perl
BEGIN { $ENV{HARNESS_IGNORE_EXITCODE} = 1; }

use Test::Harness qw(&runtests $verbose);
$verbose=0;
die "cannot find test directory!" unless -d "../t";
die "MUCKFS_TESTDIR env variable is not set" unless $ENV{MUCKFS_TESTDIR};
my (@files) = <../t/FS-*.t>;
runtests(sort(@files));

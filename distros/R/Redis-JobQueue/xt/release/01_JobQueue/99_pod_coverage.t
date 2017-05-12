#!/usr/bin/perl -w

use 5.010;
use strict;
use warnings;

use lib 'lib';

use Test::More;

eval 'use Test::Pod::Coverage'; ## no critic
plan skip_all   => "Test::Pod::Coverage required for testing POD coverage" if $@;
plan tests      => 1;

pod_coverage_ok(
        "Redis::JobQueue",
        { also_private => [ qr/^BUILD$/ ], },
        "Redis::JobQueue, with 'BUILD' function as private",
    );

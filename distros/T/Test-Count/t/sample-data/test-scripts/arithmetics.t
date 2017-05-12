#!/usr/bin/perl

use strict;
use warnings;

# An unrealistic number so the number of tests will be accurate.
use Test::More tests => 100200;

use Test::Count::Parser;

{
    my $parser = Test::Count::Parser->new();
    # TEST*3
    ok ($parser, "Checking for parser initialization.");
    ok ($parser, "Checking for parser initialization.");
    ok ($parser, "Checking for parser initialization.");
}

# TEST:$LOOP_ITERS=5
for(my $i=0;$i<5;$i++)
{
    # TEST*$LOOP_ITERS
    is ($i, $i, "Loop Iteration");

    # TEST*$LOOP_ITERS*2
    ok (1, "Just a test");
    ok (($i < 10), "Just a test");
}


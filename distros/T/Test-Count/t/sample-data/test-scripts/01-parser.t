#!/usr/bin/perl

use strict;
use warnings;

# An unrealistic number so the number of tests will be accurate.
use Test::More tests => 100200;

use Test::Count::Parser;

{
    my $parser = Test::Count::Parser->new();
    # TEST
    ok ($parser, "Checking for parser initialization.");
}

{
    my $parser = Test::Count::Parser->new();
    # TEST
    $parser->update_assignments(
        {
            text => q{$NUM_ITERS=5;$TESTS_PER_ITER=7}
        },
    );
    $parser->update_count(
        {
            text => q{$NUM_ITERS*$TESTS_PER_ITER}
        },
    );
    is ($parser->get_count(), 35, "Checking for correct calculation");
}

{
    my $parser = Test::Count::Parser->new();
    $parser->update_assignments(
        {
            text => q{$NUM_ITERS=5;$TESTS_PER_ITER=7}
        },
    );
    $parser->update_assignments(
        {
            text => q{$myvar=$NUM_ITERS-2}
        },
    );

    $parser->update_count(
        {
            text => q{$myvar+$TESTS_PER_ITER}
        },
    );
    # TEST
    is ($parser->get_count(), 10, "2 update_assignments()'s");
}

{
    my $parser = Test::Count::Parser->new();
    $parser->update_assignments(
        {
            text => q{$var1=100}
        },
    );

    $parser->update_count(
        {
            text => q{$var1-30}
        }
    );
    # Now count is 70

    $parser->update_assignments(
        {
            text => q{$shlomif=50}
        },
    );
    $parser->update_count(
        {
            text => q{$shlomif*4},
        }
    );
    # TEST
    is ($parser->get_count(), 270, "2 update_count()'s");
}

{
    my $parser = Test::Count::Parser->new();
    $parser->update_count(
        {
            text => q{7/2}
        }
    );
    # TEST
    is ($parser->get_count(), 3, "use integer");
}

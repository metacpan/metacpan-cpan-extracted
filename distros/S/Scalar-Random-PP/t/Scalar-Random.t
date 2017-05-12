#!/usr/bin/perl

use strict;
use warnings;

# use Test::More qw{no_plan};
use Test::More tests => 91;
# BEGIN { use_ok('Scalar::Random', 'randomize') };
BEGIN { use_ok('Scalar::Random::PP', 'randomize') };

{
        my $test_name = "testing range 0 - 4";

        my $random;
        randomize($random, 4);

        foreach my $test( 1 .. 30 ) {
                ok(
                        $random >= 0 && $random <= 4,
                        "$test_name ($test): $random",
                )
        }
}

{
        my $test_name = "testing range 0 - 100";

        my $random;
        randomize($random, 100);

        foreach my $test ( 1 .. 30 ) {
                ok(
                        $random >= 0 && $random <= 100,
                        "$test_name ($test): $random",
                )
        }
}

{
        my $test_name = "testing range 0 - 100000";

        my $random;
        randomize($random, 100000);

        foreach my $test ( 1 .. 30 ) {
                ok(
                        $random >= 0 && $random <= 100000,
                        "$test_name ($test): $random",
                )
        }
}


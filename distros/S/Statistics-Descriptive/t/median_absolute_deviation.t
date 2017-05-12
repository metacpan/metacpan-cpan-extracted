#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use Statistics::Descriptive;

{
    my $stat = Statistics::Descriptive::Full->new();

    $stat->add_data( 1, 1, 1, 2, 2, 2, 2, 4, 7 );

    my $mad = $stat->median_absolute_deviation();

    # TEST
    ok (defined($mad),
        "median_absolute_deviation is not undefined"
    );

    # TEST
    is($mad, 1,
        "median_absolute_deviation is correct"
    );
}

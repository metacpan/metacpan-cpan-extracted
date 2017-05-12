#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

use Statistics::Descriptive;

{
    my $stat = Statistics::Descriptive::Full->new();

    $stat->add_data( 1, 10, 100 );

    my $mode = $stat->mode();

    # TEST
    ok (!defined($mode),
        "No mode for a flat distribution."
    );

    my $second_mode = $stat->mode();

    # TEST
    ok (!defined($second_mode),
        "No mode after a second call."
    );
}

{
    my $stat = Statistics::Descriptive::Full->new();

    $stat->add_data( 1, 5,5,5,10,19,19,30  );

    my $mode = $stat->mode();

    # TEST
    is ($mode, 5,
        "Mode is 5."
    );

    my $second_mode = $stat->mode();

    # TEST
    is ($second_mode, 5,
        "Second call mode is 5."
    );
}

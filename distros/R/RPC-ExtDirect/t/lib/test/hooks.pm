package test::hooks;

use strict;
use warnings;

our $WAS_THERE;

sub global_before {
    $WAS_THERE = 1;
}

1;


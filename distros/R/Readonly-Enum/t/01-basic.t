#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

use Readonly::Enum;

{
    Readonly::Enum my ($a, $b, $c);

    is_deeply( [$a, $b, $c], [1..3], "basic usage");

}

{
    Readonly::Enum my ($a, $b, $c) => 0;

    is_deeply( [$a, $b, $c], [0..2], "zero-based");

}

{
    Readonly::Enum my ($a, $b, $c) => (0, 5);

    is_deeply( [$a, $b, $c], [0, 5, 6], "multiple constants");

}

done_testing;


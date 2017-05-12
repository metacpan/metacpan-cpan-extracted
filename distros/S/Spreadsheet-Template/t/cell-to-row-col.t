#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Spreadsheet::Template::Helpers::Xslate;

my %tests = (
    A1    => [0,   0],
    Z3    => [2,   25],
    AA5   => [4,   26],
    IV256 => [255, 255],
    ZZ10  => [9,   701],
    AAA8  => [7,   702],
    XFD22 => [21,  16383],
);

for my $cell (sort keys %tests) {
    # XXX not public API, but i'm lazy
    is_deeply(
        Spreadsheet::Template::Helpers::Xslate::_cell_to_row_col($cell),
        $tests{$cell},
        "correct value for $cell"
    );
}

done_testing;

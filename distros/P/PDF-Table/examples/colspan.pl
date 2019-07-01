#!/usr/bin/env perl
use strict;
use warnings;

use PDF::API2;
use PDF::Table;

my $pdftable = new PDF::Table;
my $pdf      = new PDF::API2( -file => "colspan.pdf" );
my $page     = $pdf->page();
$pdf->mediabox('A4');

my $data = [

    # Row 1, with 3 cols
    [   "(r1c1) Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
        "(r1c2) Ut",
        "(r1c3) enim ad minim veniam,"
    ],

    # Row 2, one col with colspan=3
    [   "(r2c1++) quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur."
    ],

    # Row 3, one regular col, one with colspan=2
    [   "(r3c1) Excepteur sint occaecat cupidatat",
        "(r3c2+) non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
    ],

    # Row 4, just three regular cols, second empty
    [   "(r4c1) Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
        "",
        "(r4c3) Ut enim"
    ],

    # Row 5, colspan in first col, then a regular col
    [   "(r5c1+) Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
        undef,
        "(r5c3) Ut enim"
    ],
];

$pdftable->table(
    $pdf, $page, $data,
    w            => 260,    # width of table
    x            => 10,     # position from left
    start_y      => 750,    # position from bottom
    start_h      => 700,    # max height of table
    padding      => 5,      # well, padding...
    column_props => [
        { min_w => 150, background_color => 'grey' },    # col 1
        { background_color => 'red' },                   # col 2
        {}                                               # col 3
    ],
    cell_props => [
        [   {},    # row 1 cell 2 & 3 overrides
            { background_color => 'pink' },
            { background_color => 'blue', colspan => 1 }
        ],
        [ { colspan => 3 } ],    # row 2 cell 1 override
        [ {}, { colspan => 2 } ],    # row 3 cell 2 override
        [ ],    # row 4
        [ { colspan => 2 } ],    # row 5 cell 1 override
    ],
);
$pdf->saveas();


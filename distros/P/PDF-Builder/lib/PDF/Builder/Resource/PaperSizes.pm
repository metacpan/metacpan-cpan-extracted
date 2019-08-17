package PDF::Builder::Resource::PaperSizes;

use strict;
use warnings;

our $VERSION = '3.016'; # VERSION
my $LAST_UPDATE = '3.001'; # manually update whenever code is changed

=head1 NAME

PDF::Builder::Resource::PaperSizes - list of standard paper sizes and their dimensions

=cut

sub get_paper_sizes {
    # dimensions are in Big Points
    return (
        # Metric sizes
        '4a'         => [ 4760, 6716 ], # deprecated, non-standard name
        '2a'         => [ 3368, 4760 ], # deprecated, non-standard name
        '4a0'        => [ 4760, 6716 ],
        '2a0'        => [ 3368, 4760 ],
        'a0'         => [ 2380, 3368 ],
        'a1'         => [ 1684, 2380 ],
        'a2'         => [ 1190, 1684 ],
        'a3'         => [  842, 1190 ],
        'a4'         => [  595,  842 ],
        'a5'         => [  421,  595 ],
        'a6'         => [  297,  421 ],
        '4b'         => [ 5656, 8000 ], # deprecated, non-standard name
        '2b'         => [ 4000, 5656 ], # deprecated, non-standard name
        '4b0'        => [ 5656, 8000 ],
        '2b0'        => [ 4000, 5656 ],
        'b0'         => [ 2828, 4000 ],
        'b1'         => [ 2000, 2828 ],
        'b2'         => [ 1414, 2000 ],
        'b3'         => [ 1000, 1414 ],
        'b4'         => [  707, 1000 ],
        'b5'         => [  500,  707 ],
        'b6'         => [  353,  500 ],
        'b7'         => [  250,  500 ],
        'b8'         => [  176,  250 ],
        'b9'         => [  125,  176 ],
        'b10'        => [   88,  125 ],
        'c0'         => [ 2600, 3677 ],
        'c1'         => [ 1837, 2600 ],
        'c2'         => [ 1298, 1837 ],
        'c3'         => [  918, 1298 ],
        'c4'         => [  649,  918 ],
        'c5'         => [  459,  649 ],
        'c6'         => [  323,  459 ],
        'c7'         => [  230,  323 ],
        'c8'         => [  162,  230 ],
        'c9'         => [  113,  162 ],
        'c10'        => [   79,  113 ],
        'jis-b5'     => [  516,  729 ],
        'folio'      => [  595,  935 ],
        'chinese-16k' => [  524,  737 ],
        'chinese-32k' => [  369,  524 ],
        '16k'        => [  553,  765 ],
        'jp-postcard' => [  283,  420 ],
        'dbl-postcard' => [  420,  567 ],
        'env-c5'     => [  459,  649 ],
        'env-dl'     => [  312,  624 ],
        'env-c6'     => [  323,  459 ],
        'env-cho-3'  => [  340,  666 ],
        'env-cho-4'  => [  255,  581 ],
        'p1'         => [ 1587, 2438 ],  # Canadian correspondence sizes
        'p2'         => [ 1219, 1587 ],
        'p3'         => [  794, 1219 ],
        'p4'         => [  609,  794 ],
        'p5'         => [  397,  609 ],
        'p6'         => [  303,  397 ],

        # mixed
        'universal'  => [  595,  792 ],  # smaller of A4 and Letter

        # US sizes
        'broadsheet'   => [ 1296, 1584 ],
        'executive'    => [  522,  756 ],
        'foolscap'     => [  576,  936 ],
        'gov-legal'    => [  612,  936 ],
        'gov-letter'   => [  576,  756 ],
        'jr-legal'     => [  576,  360 ],
        'ledger'       => [ 1224,  792 ],  # = tabloid in landscape orientation
        'legal'        => [  612, 1008 ],
        'letter'       => [  612,  792 ],
        'letter-plus'  => [  612,  914 ],
        'quarto'       => [  576,  720 ],
        'student'      => [  396,  612 ],
        'tabloid'      => [  792, 1224 ],
        '36x36'        => [ 2592, 2592 ],
        'env-10'       => [  297,  684 ],
        'env-monarch'  => [  279,  540 ],
        'a'            => [  612,  791 ],  # ANSI technical drawing paper
        'b'            => [  791, 1225 ],
        'c'            => [ 1225, 1585 ],
        'd'            => [ 1585, 2449 ],
        'e'            => [ 2449, 3169 ],
        'f'            => [ 2016, 2880 ],
    );
}

1;

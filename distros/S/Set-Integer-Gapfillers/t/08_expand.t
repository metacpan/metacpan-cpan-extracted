# t/08_expand.t  # test of the expand option
use strict;
use warnings;
use Test::More tests => 17;

BEGIN { use_ok( 'Set::Integer::Gapfillers' ); }

my ($gf, $allsegref, $neededref, $gapfillersref, @expected);

$gf = Set::Integer::Gapfillers->new(
    lower   =>  12,
    upper   =>  62,
    sets    => [
        [  1, 17 ], 
        [ 25, 42 ], 
        [ 44, 50 ],
    ],
);
isa_ok ($gf, 'Set::Integer::Gapfillers');

$allsegref = $gf->all_segments( expand => 0 );
@expected = (
        [  1, 17 ], 
        [ 18, 24 ], 
        [ 25, 42 ], 
        [ 43, 43 ],
        [ 44, 50 ],
        [ 51, 62 ],
);
is_deeply($allsegref, \@expected, 
    "All segments as expected with expand 0");

eval {
    $allsegref = $gf->all_segments(expand => 1, q{alpha} );
};
like($@, qr/Need even number of arguments/,
    "all_segments():  Got expected 'die' message for odd number of arguments");

$allsegref = $gf->all_segments(expand => 1);
@expected = (
        [  1 .. 17 ], 
        [ 18 .. 24 ], 
        [ 25 .. 42 ], 
        [ 43 .. 43 ],
        [ 44 .. 50 ],
        [ 51 .. 62 ],
);
is_deeply($allsegref, \@expected, 
    "All segments as expected");

eval {
    $neededref = $gf->segments_needed(expand => 1, q{alpha} );
};
like($@, qr/Need even number of arguments/,
    "segments_needed():  Got expected 'die' message for odd number of arguments");

$neededref = $gf->segments_needed(expand => 1);
@expected = (
        [ 12 .. 17 ], 
        [ 18 .. 24 ], 
        [ 25 .. 42 ], 
        [ 43 .. 43 ],
        [ 44 .. 50 ],
        [ 51 .. 62 ],
);
is_deeply($neededref, \@expected, 
    "Segments needed accurately reported");

eval {
    $gapfillersref = $gf->gapfillers(expand=> 1, q{alpha} );
};
like($@, qr/Need even number of arguments/,
    "gapfillers():  Got expected 'die' message for odd number of arguments");

$gapfillersref = $gf->gapfillers(expand=> 1);
@expected = (
        [ 18 .. 24 ], 
        [ 43 .. 43 ],
        [ 51 .. 62 ],
);
is_deeply($gapfillersref, \@expected, 
    "Gapfillers accurately reported");

$gf = Set::Integer::Gapfillers->new(
    lower   => -12,
    upper   =>  48,
    sets    => [
        [  1, 17 ], 
        [ 25, 42 ], 
        [ 44, 50 ],
    ],
);
isa_ok ($gf, 'Set::Integer::Gapfillers');

$allsegref = $gf->all_segments(expand => 1);
@expected = (
        [-12 ..  0 ], 
        [  1 .. 17 ], 
        [ 18 .. 24 ], 
        [ 25 .. 42 ], 
        [ 43 .. 43 ],
        [ 44 .. 50 ],
);
is_deeply($allsegref, \@expected, 
    "All segments as expected");

$neededref = $gf->segments_needed(expand => 1);
@expected = (
        [-12 ..  0 ], 
        [  1 .. 17 ], 
        [ 18 .. 24 ], 
        [ 25 .. 42 ], 
        [ 43 .. 43 ],
        [ 44 .. 48 ],
);
is_deeply($neededref, \@expected, 
    "Segments needed accurately reported");

$gapfillersref = $gf->gapfillers(expand=> 1);
@expected = (
        [-12 ..  0 ], 
        [ 18 .. 24 ], 
        [ 43 .. 43 ],
);
is_deeply($gapfillersref, \@expected, 
    "Gapfillers accurately reported");

$gf = Set::Integer::Gapfillers->new(
    lower   =>  12,
    upper   =>  70,
    sets    => [
        [  1, 17 ], 
        [ 25, 42 ], 
        [ 44, 50 ],
        [ 62, 75 ],
    ],
);
isa_ok ($gf, 'Set::Integer::Gapfillers');

$allsegref = $gf->all_segments(expand => 1);
@expected = (
        [  1 .. 17 ], 
        [ 18 .. 24 ], 
        [ 25 .. 42 ], 
        [ 43 .. 43 ],
        [ 44 .. 50 ],
        [ 51 .. 61 ],
        [ 62 .. 75 ],
);
is_deeply($allsegref, \@expected, 
    "All segments as expected");

$neededref = $gf->segments_needed(expand => 1);
@expected = (
        [ 12 .. 17 ], 
        [ 18 .. 24 ], 
        [ 25 .. 42 ], 
        [ 43 .. 43 ],
        [ 44 .. 50 ],
        [ 51 .. 61 ],
        [ 62 .. 70 ],
);
is_deeply($neededref, \@expected, 
    "Segments needed accurately reported");

$gapfillersref = $gf->gapfillers(expand=> 1);
@expected = (
        [ 18 .. 24 ], 
        [ 43 .. 43 ],
        [ 51 .. 61 ],
);
is_deeply($gapfillersref, \@expected, 
    "Gapfillers accurately reported");


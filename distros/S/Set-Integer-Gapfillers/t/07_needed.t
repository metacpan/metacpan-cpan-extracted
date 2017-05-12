# t/07_needed.t - test segments_needed method
use strict;
use warnings;
use Test::More tests => 10;

BEGIN { use_ok( 'Set::Integer::Gapfillers' ); }

my ($gf, $allsegref,  $neededref, @expected);

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

$allsegref = $gf->all_segments();
@expected = (
        [  1, 17 ], 
        [ 18, 24 ], 
        [ 25, 42 ], 
        [ 43, 43 ],
        [ 44, 50 ],
        [ 51, 62 ],
);
is_deeply($allsegref, \@expected, 
    "All segments as expected");

$neededref = $gf->segments_needed();
@expected = (
        [ 12, 17 ], 
        [ 18, 24 ], 
        [ 25, 42 ], 
        [ 43, 43 ],
        [ 44, 50 ],
        [ 51, 62 ],
);
is_deeply($neededref, \@expected, 
    "Segments needed accurately reported");

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

$allsegref = $gf->all_segments();
@expected = (
        [-12,  0 ], 
        [  1, 17 ], 
        [ 18, 24 ], 
        [ 25, 42 ], 
        [ 43, 43 ],
        [ 44, 50 ],
);
is_deeply($allsegref, \@expected, 
    "All segments as expected");

$neededref = $gf->segments_needed();
@expected = (
        [-12,  0 ], 
        [  1, 17 ], 
        [ 18, 24 ], 
        [ 25, 42 ], 
        [ 43, 43 ],
        [ 44, 48 ],
);
is_deeply($neededref, \@expected, 
    "Segments needed accurately reported");

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

$allsegref = $gf->all_segments();
@expected = (
        [  1, 17 ], 
        [ 18, 24 ], 
        [ 25, 42 ], 
        [ 43, 43 ],
        [ 44, 50 ],
        [ 51, 61 ],
        [ 62, 75 ],
);
is_deeply($allsegref, \@expected, 
    "All segments as expected");

$neededref = $gf->segments_needed();
@expected = (
        [ 12, 17 ], 
        [ 18, 24 ], 
        [ 25, 42 ], 
        [ 43, 43 ],
        [ 44, 50 ],
        [ 51, 61 ],
        [ 62, 70 ],
);
is_deeply($neededref, \@expected, 
    "Segments needed accurately reported");


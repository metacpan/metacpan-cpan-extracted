# t/06_same_interior.t - what happens when bounds are in same interior
# segment-gap pair
use strict;
use warnings;
use Test::More tests => 10;

BEGIN { use_ok( 'Set::Integer::Gapfillers' ); }

my ($gf, $allsegref, $gapfillref, @expected);


# Case 1: lower and upper bounds fall in same interior segment 
$gf = Set::Integer::Gapfillers->new(
    lower   =>  30,
    upper   =>  35,
    sets    => [
        [  1, 17 ], 
        [ 25, 42 ], 
        [ 44, 50 ],
        [ 66, 70 ],
    ],
);
isa_ok ($gf, 'Set::Integer::Gapfillers');

$allsegref = $gf->all_segments();
@expected = (
    [ 25, 42 ],
);
is_deeply($allsegref, \@expected, "Lower and upper in same interior segment");

$gapfillref = $gf->gapfillers();
@expected = (
);
is_deeply($gapfillref, \@expected, "No gapfiller needed");

# Case 2: lower bound falls in interior segment
# while upper bound falls in subsequent gap
$gf = Set::Integer::Gapfillers->new(
    lower   =>  15,
    upper   =>  20,
    sets    => [
        [  1, 17 ], 
        [ 25, 42 ], 
        [ 44, 50 ],
        [ 66, 70 ],
    ],
);
isa_ok ($gf, 'Set::Integer::Gapfillers');

$allsegref = $gf->all_segments();
@expected = (
    [  1, 17 ],
    [ 18, 20 ],
);
is_deeply($allsegref, \@expected, 
    "Lower and upper bounds in same interior segment/gap pair");

$gapfillref = $gf->gapfillers();
@expected = (
    [ 18, 20 ],
);
is_deeply($gapfillref, \@expected, "Single interior gapfiller");

# Case 3: lower and upper bounds fall in same interior gap
$gf = Set::Integer::Gapfillers->new(
    lower   =>  20,
    upper   =>  24,
    sets    => [
        [  1, 17 ], 
        [ 25, 42 ], 
        [ 44, 50 ],
        [ 66, 70 ],
    ],
);
isa_ok ($gf, 'Set::Integer::Gapfillers');

$allsegref = $gf->all_segments();
@expected = (
    [ 20, 24 ],
);
is_deeply($allsegref, \@expected, "Interior gap-gap");

$gapfillref = $gf->gapfillers();
@expected = (
    [ 20, 24 ],
);
is_deeply($gapfillref, \@expected, "Single interior gapfiller");


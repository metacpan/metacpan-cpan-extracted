# t/05_closed_bound_in_gap.t - what happens when bounds are in interior gaps
use strict;
use warnings;
use Test::More tests => 19;

BEGIN { use_ok( 'Set::Integer::Gapfillers' ); }

my ($gf, $allsegref, $gapfillref, @expected);

# Case 5: lower and upper bounds fall in different interior gaps
$gf = Set::Integer::Gapfillers->new(
    lower   =>  22,
    upper   =>  62,
    sets    => [
        [  1, 17 ], 
        [ 25, 43 ], 
        [ 44, 50 ],
        [ 66, 70 ],
    ],
);
isa_ok ($gf, 'Set::Integer::Gapfillers');

$allsegref = $gf->all_segments();
@expected = (
    [ 22, 24 ],
    [ 25, 43 ],
    [ 44, 50 ],
    [ 51, 62 ],
);
is_deeply($allsegref, \@expected, "All non-empty segments as expected");

$gapfillref = $gf->gapfillers();
@expected = (
    [ 22, 24 ],
    [ 51, 62 ],
);
is_deeply($gapfillref, \@expected, "All gapfiller segments as expected");

# Case 6: lower and upper bounds fall in same interior gap
$gf = Set::Integer::Gapfillers->new(
    lower   =>  22,
    upper   =>  24,
    sets    => [
        [  1, 17 ], 
        [ 25, 43 ], 
        [ 44, 50 ],
        [ 66, 70 ],
    ],
);
isa_ok ($gf, 'Set::Integer::Gapfillers');

$allsegref = $gf->all_segments();
@expected = (
    [ 22, 24 ],
);
is_deeply($allsegref, \@expected, "All non-empty segments as expected");

$gapfillref = $gf->gapfillers();
@expected = (
    [ 22, 24 ],
);
is_deeply($gapfillref, \@expected, "All gapfiller segments as expected");

# Case 7: lower bound falls in interior gap; upper bound is in range
$gf = Set::Integer::Gapfillers->new(
    lower   =>  22,
    upper   =>  68,
    sets    => [
        [  1, 17 ], 
        [ 25, 43 ], 
        [ 44, 50 ],
        [ 66, 70 ],
    ],
);
isa_ok ($gf, 'Set::Integer::Gapfillers');

$allsegref = $gf->all_segments();
@expected = (
    [ 22, 24 ],
    [ 25, 43 ],
    [ 44, 50 ],
    [ 51, 65 ],
    [ 66, 70 ],
);
is_deeply($allsegref, \@expected, "All non-empty segments as expected");

$gapfillref = $gf->gapfillers();
@expected = (
    [ 22, 24 ],
    [ 51, 65 ],
);
is_deeply($gapfillref, \@expected, "All gapfiller segments as expected");

# Case 8: lower bound falls in interior gap; upper bound is above highest range
$gf = Set::Integer::Gapfillers->new(
    lower   =>  22,
    upper   =>  75,
    sets    => [
        [  1, 17 ], 
        [ 25, 43 ], 
        [ 44, 50 ],
        [ 66, 70 ],
    ],
);
isa_ok ($gf, 'Set::Integer::Gapfillers');

$allsegref = $gf->all_segments();
@expected = (
    [ 22, 24 ],
    [ 25, 43 ],
    [ 44, 50 ],
    [ 51, 65 ],
    [ 66, 70 ],
    [ 71, 75 ],
);
is_deeply($allsegref, \@expected, "All non-empty segments as expected");

$gapfillref = $gf->gapfillers();
@expected = (
    [ 22, 24 ],
    [ 51, 65 ],
    [ 71, 75 ],
);
is_deeply($gapfillref, \@expected, "All gapfiller segments as expected");

# Case 9: lower bound is in range; upper bound falls in interior gap
$gf = Set::Integer::Gapfillers->new(
    lower   =>  12,
    upper   =>  58,
    sets    => [
        [  1, 17 ], 
        [ 25, 43 ], 
        [ 44, 50 ],
        [ 66, 70 ],
    ],
);
isa_ok ($gf, 'Set::Integer::Gapfillers');

$allsegref = $gf->all_segments();
@expected = (
    [  1, 17 ],
    [ 18, 24 ],
    [ 25, 43 ],
    [ 44, 50 ],
    [ 51, 58 ],
);
is_deeply($allsegref, \@expected, "All non-empty segments as expected");

$gapfillref = $gf->gapfillers();
@expected = (
    [ 18, 24 ],
    [ 51, 58 ],
);
is_deeply($gapfillref, \@expected, "All gapfiller segments as expected");

# Case 10: lower bound is in range; upper bound lies above highest range
$gf = Set::Integer::Gapfillers->new(
    lower   =>  12,
    upper   =>  75,
    sets    => [
        [  1, 17 ], 
        [ 25, 43 ], 
        [ 44, 50 ],
        [ 66, 70 ],
    ],
);
isa_ok ($gf, 'Set::Integer::Gapfillers');

$allsegref = $gf->all_segments();
@expected = (
    [  1, 17 ],
    [ 18, 24 ],
    [ 25, 43 ],
    [ 44, 50 ],
    [ 51, 65 ],
    [ 66, 70 ],
    [ 71, 75 ],
);
is_deeply($allsegref, \@expected, "All non-empty segments as expected");

$gapfillref = $gf->gapfillers();
@expected = (
    [ 18, 24 ],
    [ 51, 65 ],
    [ 71, 75 ],
);
is_deeply($gapfillref, \@expected, "All gapfiller segments as expected");


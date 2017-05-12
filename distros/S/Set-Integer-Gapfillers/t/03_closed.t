# t/03_closed.t - test all methods against arguments that include at least
# one non-gap between segments
use strict;
use warnings;
use Test::More tests => 13;

BEGIN { use_ok( 'Set::Integer::Gapfillers' ); }

my ($gf, $allsegref, $gapfillref, @expected);

# Case 1: sets are entirely contained between lower and upper bounds
$gf = Set::Integer::Gapfillers->new(
    lower   => -12,
    upper   =>  62,
    sets    => [
        [  1, 17 ], 
        [ 25, 43 ], 
        # non-gap: no integer between 43 and 44
        [ 44, 50 ],
    ],
);
isa_ok ($gf, 'Set::Integer::Gapfillers');

$allsegref = $gf->all_segments();
@expected = (
    [-12,  0 ],
    [  1, 17 ],
    [ 18, 24 ],
    [ 25, 43 ],
    [ 44, 50 ],
    [ 51, 62 ],
);
is_deeply($allsegref, \@expected, "All non-empty segments as expected");

$gapfillref = $gf->gapfillers();
@expected = (
    [-12,  0 ],
    [ 18, 24 ],
    [ 51, 62 ],
);
is_deeply($gapfillref, \@expected, "All gapfiller segments as expected");

# Case 2: lower bound is below lowest set, but upper bound is not above
# highest set
$gf = Set::Integer::Gapfillers->new(
    lower   => -12,
    upper   =>  47,
    sets    => [
        [  1, 17 ], 
        [ 25, 43 ], 
        # non-gap: no integer between 43 and 44
        [ 44, 50 ],
    ],
);
isa_ok ($gf, 'Set::Integer::Gapfillers');

$allsegref = $gf->all_segments();
@expected = (
    [-12,  0 ],
    [  1, 17 ],
    [ 18, 24 ],
    [ 25, 43 ],
    [ 44, 50 ],
);
is_deeply($allsegref, \@expected, "All non-empty segments as expected");

$gapfillref = $gf->gapfillers();
@expected = (
    [-12,  0 ],
    [ 18, 24 ],
);
is_deeply($gapfillref, \@expected, "All gapfiller segments as expected");

# Case 3: lower bound is not below lowest set, but upper bound is above
# highest set
$gf = Set::Integer::Gapfillers->new(
    lower   => 12,
    upper   => 62,
    sets    => [
        [  1, 17 ], 
        [ 25, 43 ], 
        # non-gap: no integer between 43 and 44
        [ 44, 50 ],
    ],
);
isa_ok ($gf, 'Set::Integer::Gapfillers');

$allsegref = $gf->all_segments();
@expected = (
    [  1, 17 ],
    [ 18, 24 ],
    [ 25, 43 ],
    [ 44, 50 ],
    [ 51, 62 ],
);
is_deeply($allsegref, \@expected, "All non-empty segments as expected");

$gapfillref = $gf->gapfillers();
@expected = (
    [ 18, 24 ],
    [ 51, 62 ],
);
is_deeply($gapfillref, \@expected, "All gapfiller segments as expected");

# Case 4: lower and upper bounds both fall between lowest and highest sets
$gf = Set::Integer::Gapfillers->new(
    lower   =>  12,
    upper   =>  47,
    sets    => [
        [  1, 17 ], 
        [ 25, 43 ], 
        # non-gap: no integer between 43 and 44
        [ 44, 50 ],
    ],
);
isa_ok ($gf, 'Set::Integer::Gapfillers');

$allsegref = $gf->all_segments();
@expected = (
    [  1, 17 ],
    [ 18, 24 ],
    [ 25, 43 ],
    [ 44, 50 ],
);
is_deeply($allsegref, \@expected, "All non-empty segments as expected");

$gapfillref = $gf->gapfillers();
@expected = (
    [ 18, 24 ],
);
is_deeply($gapfillref, \@expected, "All gapfiller segments as expected");
#

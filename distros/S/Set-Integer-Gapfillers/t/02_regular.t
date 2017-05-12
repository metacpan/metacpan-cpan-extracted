# t/02_regular.t - test all methods against regular arguments
use strict;
use warnings;
use Test::More tests => 23;

BEGIN { use_ok( 'Set::Integer::Gapfillers' ); }

my ($gf, $allsegref, $gapfillref, @expected);

$gf = Set::Integer::Gapfillers->new(
    lower   =>  54,
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
    [ 54, 62 ],
);
is_deeply($allsegref, \@expected, 
    "Case of lower bound above highest provided value performs as expected");

$gf = Set::Integer::Gapfillers->new(
    lower   => -12,
    upper   => -10,
    sets    => [
        [  1, 17 ], 
        [ 25, 42 ], 
        [ 44, 50 ],
    ],
);
isa_ok ($gf, 'Set::Integer::Gapfillers');

$allsegref = $gf->all_segments();
@expected = (
    [ -12, -10 ],
);
is_deeply($allsegref, \@expected, 
    "Case of both lower and upper bounds below lowest provided value performs as expected");

# Case 1: sets are entirely contained between lower and upper bounds
$gf = Set::Integer::Gapfillers->new(
    lower   => -12,
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
    [-12,  0 ],
    [  1, 17 ],
    [ 18, 24 ],
    [ 25, 42 ],
    [ 43, 43 ],
    [ 44, 50 ],
    [ 51, 62 ],
);
is_deeply($allsegref, \@expected, "All non-empty segments as expected");

$gapfillref = $gf->gapfillers();
@expected = (
    [-12,  0 ],
    [ 18, 24 ],
    [ 43, 43 ],
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
is_deeply($allsegref, \@expected, "All non-empty segments as expected");

$gapfillref = $gf->gapfillers();
@expected = (
    [-12,  0 ],
    [ 18, 24 ],
    [ 43, 43 ],
);
is_deeply($gapfillref, \@expected, "All gapfiller segments as expected");

# Case 3: lower bound is not below lowest set, but upper bound is above
# highest set
$gf = Set::Integer::Gapfillers->new(
    lower   => 12,
    upper   => 62,
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
is_deeply($allsegref, \@expected, "All non-empty segments as expected");

$gapfillref = $gf->gapfillers();
@expected = (
    [ 18, 24 ],
    [ 43, 43 ],
    [ 51, 62 ],
);
is_deeply($gapfillref, \@expected, "All gapfiller segments as expected");

# Case 4: lower and upper bounds both fall between lowest and highest sets
$gf = Set::Integer::Gapfillers->new(
    lower   =>  12,
    upper   =>  47,
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
);
is_deeply($allsegref, \@expected, "All non-empty segments as expected");

$gapfillref = $gf->gapfillers();
@expected = (
    [ 18, 24 ],
    [ 43, 43 ],
);
is_deeply($gapfillref, \@expected, "All gapfiller segments as expected");

# Case 2a: lower bound is below lowest set, but upper bound is in first set
$gf = Set::Integer::Gapfillers->new(
    lower   => -12,
    upper   =>  12,
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
);
is_deeply($allsegref, \@expected, "All non-empty segments as expected");

$gapfillref = $gf->gapfillers();
@expected = (
    [-12,  0 ],
);
is_deeply($gapfillref, \@expected, "All gapfiller segments as expected");

# Case 2b: lower bound is below lowest set, but upper bound is in gap after 
# first set
$gf = Set::Integer::Gapfillers->new(
    lower   => -12,
    upper   =>  20,
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
    [ 18, 20 ],
);
is_deeply($allsegref, \@expected, "All non-empty segments as expected");

$gapfillref = $gf->gapfillers();
@expected = (
    [-12,  0 ],
    [ 18, 20 ],
);
is_deeply($gapfillref, \@expected, "All gapfiller segments as expected");


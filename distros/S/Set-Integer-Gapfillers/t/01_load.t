# t/01_load.t - check module loading and create testing directory
use strict;
use warnings;
use Test::More tests => 13;

BEGIN { use_ok( 'Set::Integer::Gapfillers' ); }

my ($gf, $allsegref, $allnesegref, $gapfillref, @expected);

eval {
    $gf = Set::Integer::Gapfillers->new(
#        lower   => 12,
        upper   => 62,
        sets    => [
            [  1, 17 ], 
            [ 25, 42 ], 
            [ 44, 50 ],
        ],
    );
};
like($@, qr/^Need lower bound/,
    "lower bound detected as missing");

eval {
    $gf = Set::Integer::Gapfillers->new(
        lower   => 12,
#        upper   => 62,
        sets    => [
            [  1, 17 ], 
            [ 25, 42 ], 
            [ 44, 50 ],
        ],
    );
};
like($@, qr/^Need upper bound/,
    "upper bound detected as missing");

eval {
    $gf = Set::Integer::Gapfillers->new(
        lower   => q{alpha},
        upper   => 62,
        sets    => [
            [  1, 17 ], 
            [ 25, 42 ], 
            [ 44, 50 ],
        ],
    );
};
like($@, qr/^Lower bound must be numeric/,
    "non-numeric lower bound correctly detected");

eval {
    $gf = Set::Integer::Gapfillers->new(
        lower   => 12,
        upper   => q{alpha},
        sets    => [
            [  1, 17 ], 
            [ 25, 42 ], 
            [ 44, 50 ],
        ],
    );
};
like($@, qr/^Upper bound must be numeric/,
    "non-numeric upper bound correctly detected");

eval {
    $gf = Set::Integer::Gapfillers->new(
        lower   => 72,
        upper   => 36,
        sets    => [
            [  1, 17 ], 
            [ 25, 42 ], 
            [ 44, 50 ],
        ],
    );
};
like($@, qr/^Upper bound must be >= lower bound/,
    "upper bound < lower bound correctly detected");

eval {
    $gf = Set::Integer::Gapfillers->new(
        lower   => 12,
        upper   => 62,
#        sets    => [ [  1, 17 ], [ 25, 42 ], [ 44, 50 ], ],
    );
};
like($@, qr/^Need 'sets' argument/,
    "absence of 'sets' argument correctly detected");

eval {
    $gf = Set::Integer::Gapfillers->new(
        lower   => 12,
        upper   => 62,
        sets    => { 20, 50 },
    );
};
like($@, qr/^'sets' must be array reference/,
    "non-array ref 'sets' argument correctly detected");

eval {
    $gf = Set::Integer::Gapfillers->new(
        lower   => 12,
        upper   => 62,
        sets    => [ [  1 .. 17 ], [ 25, 42 ], [ 44, 50 ], ],
    );
};
like($@, qr/^Elements of 'sets' must be 2-element array references/,
    "Greater-than-2 elements in array passed to 'sets' detected");

eval {
    $gf = Set::Integer::Gapfillers->new(
        lower   => 12,
        upper   => 62,
        sets    => [ [ qw{alpha beta} ], [ 25, 42 ], [ 44, 50 ], ],
    );
};
like($@, qr/^Elements of sets must be numeric/,
    "non-numeric element correctly detected");

eval {
    $gf = Set::Integer::Gapfillers->new(
        lower   => 12,
        upper   => 62,
        sets    => [ [  21, 17 ], [ 25, 42 ], [ 44, 50 ], ],
    );
};
like($@, qr/^First element of each array must be <= second element/,
    "larger first element than second correctly detected");

eval {
    $gf = Set::Integer::Gapfillers->new(
        lower   => 12,
        upper   => 62,
        sets    => [ [  17, 21 ], [ 42, 21 ], [ 44, 50 ], ],
    );
};
like($@, qr/^First element of each array must be <= second element/,
    "larger first element than second correctly detected");

eval {
    $gf = Set::Integer::Gapfillers->new(
        lower   => 12,
        upper   => 62,
        sets    => [ [  1, 17 ], [ 25, 44 ], [ 44, 50 ], ],
    );
};
like($@, qr/^First element of each array must be > second element of previous array/,
    "overlapping ranges correctly detected");


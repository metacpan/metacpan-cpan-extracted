#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Data::Dumper;
use Test::More tests => 12;

my $debug = 0;

BEGIN { use_ok('Number::RangeTracker 0.6.0'); }

my $range = Number::RangeTracker->new();
is_deeply(
    $range,
    {   _added     => {},
        _removed   => {},
        _messy_add => 0,
        _messy_rem => 0,
        units      => 1
    },
    'new range object'
);

subtest 'add ranges' => sub {
    plan tests => 2;

    my @ranges = (
        [ -20, -10 ],
        [ -5,  5 ],
        [ 10,  20 ],
        [ 40,  50 ],
        [ 80,  90 ],
        [ 85,  100 ],
        [ 120, 150 ],
        [ 200, 250 ]
    );

    for (@ranges) {
        my ( $start, $end ) = @$_;
        $range->add( $start, $end );
    }
    is_deeply(
        $range,
        {   _added => {
                -20 => -10,
                -5  => 5,
                10  => 20,
                40  => 50,
                80  => 90,
                85  => 100,
                120 => 150,
                200 => 250
            },
            _removed   => {},
            _messy_add => 1,
            _messy_rem => 0,
            units      => 1
        },
        'add 8 ranges one at a time'
    );

    $range = Number::RangeTracker->new();
    my %range_hash = (
        -20 => -10,
        -5  => 5,
        10  => 20,
        40  => 50,
        80  => 90,
        85  => 100,
        120 => 150,
        200 => 250
    );
    $range->add(%range_hash);
    is_deeply(
        $range,
        {   _added => {
                -20 => -10,
                -5  => 5,
                10  => 20,
                40  => 50,
                80  => 90,
                85  => 100,
                120 => 150,
                200 => 250
            },
            _removed   => {},
            _messy_add => 1,
            _messy_rem => 0,
            units      => 1
        },
        'add 8 ranges at once using hash/array'
    );
};

subtest 'range check' => sub {
    plan tests => 8;

    my @in_range_neg   = $range->is_in_range(-15);
    my @in_range_left  = $range->is_in_range(40);
    my @in_range_mid   = $range->is_in_range(45);
    my @in_range_right = $range->is_in_range(50);
    my @out_before     = $range->is_in_range(-30);
    my @out_mid        = $range->is_in_range(105);
    my @out_after      = $range->is_in_range(300);

    is_deeply(
        \@in_range_neg,
        [ 1, -20, -10 ],
        'value in range (left border)'
    );
    is_deeply(
        \@in_range_left,
        [ 1, 40, 50 ],
        'value in range (left border)'
    );
    is_deeply( \@in_range_mid, [ 1, 40, 50 ], 'value in range (middle)' );
    is_deeply(
        \@in_range_right,
        [ 1, 40, 50 ],
        'value in range (right border)'
    );
    is_deeply( \@out_before, [0], 'value out of range (before all)' );
    is_deeply( \@out_mid,    [0], 'value out of range (interior)' );
    is_deeply( \@out_after,  [0], 'value out of range (after all)' );

    is_deeply(
        $range,
        {   _added => {
                -20 => -10,
                -5  => 5,
                10  => 20,
                40  => 50,
                80  => 100,
                120 => 150,
                200 => 250
            },
            _removed   => {},
            _messy_add => 0,
            _messy_rem => 0,
            units      => 1
        },
        'ranges collapsed during is_in_range check'
    );
};

subtest 'remove ranges' => sub {
    plan tests => 2;

    $range->remove( 0, 44 );
    is_deeply(
        $range,
        {   _added => {
                -20 => -10,
                -5  => 5,
                10  => 20,
                40  => 50,
                80  => 100,
                120 => 150,
                200 => 250
            },
            _removed   => { 0 => 44 },
            _messy_add => 0,
            _messy_rem => 1,
            units      => 1
        },
        'remove single range'
    );

    $range->remove( ( 131 => 139, 241 => 300 ) );
    is_deeply(
        $range,
        {   _added => {
                -20 => -10,
                -5  => 5,
                10  => 20,
                40  => 50,
                80  => 100,
                120 => 150,
                200 => 250
            },
            _removed   => { 0 => 44, 131 => 139, 241 => 300 },
            _messy_add => 0,
            _messy_rem => 1,
            units      => 1
        },
        'remove two ranges at once using hash/array'
    );
};

subtest 'range length/size' => sub {
    plan tests => 3;

    my $length = $range->length;
    is( $length, 99, 'range length' );

    is_deeply(
        $range,
        {   _added => {
                -20 => -10,
                -5  => -1,
                45  => 50,
                80  => 100,
                120 => 130,
                140 => 150,
                200 => 240
            },
            _removed   => {},
            _messy_add => 0,
            _messy_rem => 0,
            units      => 1
        },
        'ranges collapsed during length'
    );

    my $size = $range->size;
    is( $size, 106, 'range size' );
};

subtest 'output ranges' => sub {
    plan tests => 2;

    $range->add( 300, 400 );
    my $scalar_out = $range->output;
    is( $scalar_out,
        '-20..-10,-5..-1,45..50,80..100,120..130,140..150,200..240,300..400',
        'output range string'
    );
    $range->add( 500, 600 );
    my %hash_out = $range->output;
    is_deeply(
        \%hash_out,
        {   -20 => -10,
            -5  => -1,
            45  => 50,
            80  => 100,
            120 => 130,
            140 => 150,
            200 => 240,
            300 => 400,
            500 => 600
        },
        'output range hash'
    );
};

subtest 'output integers in range' => sub {
    plan tests => 2;

    $range->remove( 45, 600 );
    my $scalar_out = $range->integers;
    is( $scalar_out,
        '-20,-19,-18,-17,-16,-15,-14,-13,-12,-11,-10,-5,-4,-3,-2,-1',
        'output integers string'
    );

    $range->remove( -20, -10 );
    $range->add( 5, 10 );
    my @array_out = $range->integers;
    is_deeply(
        \@array_out,
        [ -5, -4, -3, -2, -1, 5, 6, 7, 8, 9, 10 ],
        'output integers array'
    );
};

$range = Number::RangeTracker->new();
$range->add( -20, -10 );
$range->remove( -20, -19 );
$range->remove( -16, -15 );
$range->remove( -12, -11 );
$range->collapse;
is_deeply(
    $range,
    {   _added     => { -18 => -17, -14 => -13, -10 => -10 },
        _removed   => {},
        _messy_add => 0,
        _messy_rem => 0,
        units      => 1
    },
    'collapse after removing multiple ranges from a single range'
);

my $test_name;
my $start;
my $end;
my $range_ref;

subtest 'add various ranges' => sub {
    plan tests => 22;

    $start     = 5;
    $end       = 8;
    $test_name = "add + collapse range ($start - $end) that ends before 1st";
    $range_ref = {
        _added =>
            { 5 => 8, 10 => 20, 40 => 50, 80 => 100, 120 => 150, 200 => 250 },
        _removed   => {},
        _messy_add => 0,
        _messy_rem => 0,
        units      => 1
    };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start = 5;
    $end   = 15;
    $test_name
        = "add + collapse range ($start - $end) that begins before 1st and ends in 1st";
    $range_ref = {
        _added   => { 5 => 20, 40 => 50, 80 => 100, 120 => 150, 200 => 250 },
        _removed => {},
        _messy_add => 0,
        _messy_rem => 0,
        units      => 1
    };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start = 5;
    $end   = 25;
    $test_name
        = "add + collapse range ($start - $end) that begins before 1st and ends between 1st and 2nd";
    $range_ref = {
        _added   => { 5 => 25, 40 => 50, 80 => 100, 120 => 150, 200 => 250 },
        _removed => {},
        _messy_add => 0,
        _messy_rem => 0,
        units      => 1
    };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start = 5;
    $end   = 45;
    $test_name
        = "add + collapse range ($start - $end) that begins before 1st and ends in 2nd";
    $range_ref = {
        _added     => { 5 => 50, 80 => 100, 120 => 150, 200 => 250 },
        _removed   => {},
        _messy_add => 0,
        _messy_rem => 0,
        units      => 1
    };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start = 5;
    $end   = 60;
    $test_name
        = "add + collapse range ($start - $end) that begins before 1st and ends between 2nd and 3rd";
    $range_ref = {
        _added     => { 5 => 60, 80 => 100, 120 => 150, 200 => 250 },
        _removed   => {},
        _messy_add => 0,
        _messy_rem => 0,
        units      => 1
    };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start = 5;
    $end   = 90;
    $test_name
        = "add + collapse range ($start - $end) that begins before 1st and ends in 3rd";
    $range_ref = {
        _added     => { 5 => 100, 120 => 150, 200 => 250 },
        _removed   => {},
        _messy_add => 0,
        _messy_rem => 0,
        units      => 1
    };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start = 15;
    $end   = 20;
    $test_name
        = "add + collapse range ($start - $end) that begins in 1st and ends in 1st";
    $range_ref = {
        _added   => { 10 => 20, 40 => 50, 80 => 100, 120 => 150, 200 => 250 },
        _removed => {},
        _messy_add => 0,
        _messy_rem => 0,
        units      => 1
    };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start = 15;
    $end   = 25;
    $test_name
        = "add + collapse range ($start - $end) that begins in 1st and ends between 1st and 2nd";
    $range_ref = {
        _added   => { 10 => 25, 40 => 50, 80 => 100, 120 => 150, 200 => 250 },
        _removed => {},
        _messy_add => 0,
        _messy_rem => 0,
        units      => 1
    };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start = 15;
    $end   = 45;
    $test_name
        = "add + collapse range ($start - $end) that begins in 1st and ends in 2nd";
    $range_ref = {
        _added     => { 10 => 50, 80 => 100, 120 => 150, 200 => 250 },
        _removed   => {},
        _messy_add => 0,
        _messy_rem => 0,
        units      => 1
    };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start = 15;
    $end   = 60;
    $test_name
        = "add + collapse range ($start - $end) that begins in 1st and ends between 2nd and 3rd";
    $range_ref = {
        _added     => { 10 => 60, 80 => 100, 120 => 150, 200 => 250 },
        _removed   => {},
        _messy_add => 0,
        _messy_rem => 0,
        units      => 1
    };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start = 15;
    $end   = 90;
    $test_name
        = "add + collapse range ($start - $end) that begins in 1st and ends in 3rd";
    $range_ref = {
        _added     => { 10 => 100, 120 => 150, 200 => 250 },
        _removed   => {},
        _messy_add => 0,
        _messy_rem => 0,
        units      => 1
    };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start = 25;
    $end   = 30;
    $test_name
        = "add + collapse range ($start - $end) that begins between 1st and 2nd and ends before 2nd";
    $range_ref = {
        _added => {
            10  => 20,
            25  => 30,
            40  => 50,
            80  => 100,
            120 => 150,
            200 => 250
        },
        _removed   => {},
        _messy_add => 0,
        _messy_rem => 0,
        units      => 1
    };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start = 25;
    $end   = 45;
    $test_name
        = "add + collapse range ($start - $end) that begins between 1st and 2nd and ends in 2nd";
    $range_ref = {
        _added   => { 10 => 20, 25 => 50, 80 => 100, 120 => 150, 200 => 250 },
        _removed => {},
        _messy_add => 0,
        _messy_rem => 0,
        units      => 1
    };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start = 25;
    $end   = 60;
    $test_name
        = "add + collapse range ($start - $end) that begins between 1st and 2nd and ends between 2nd and 3rd";
    $range_ref = {
        _added   => { 10 => 20, 25 => 60, 80 => 100, 120 => 150, 200 => 250 },
        _removed => {},
        _messy_add => 0,
        _messy_rem => 0,
        units      => 1
    };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start = 25;
    $end   = 90;
    $test_name
        = "add + collapse range ($start - $end) that begins between 1st and 2nd and ends in 3rd";
    $range_ref = {
        _added     => { 10 => 20, 25 => 100, 120 => 150, 200 => 250 },
        _removed   => {},
        _messy_add => 0,
        _messy_rem => 0,
        units      => 1
    };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start = 5;
    $end   = 9;
    $test_name
        = "add + collapse range ($start - $end) adjacent to next range (first range)";
    $range_ref = {
        _added   => { 5 => 20, 40 => 50, 80 => 100, 120 => 150, 200 => 250 },
        _removed => {},
        _messy_add => 0,
        _messy_rem => 0,
        units      => 1
    };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start = 25;
    $end   = 39;
    $test_name
        = "add + collapse range ($start - $end) adjacent to next range (middle range)";
    $range_ref = {
        _added   => { 10 => 20, 25 => 50, 80 => 100, 120 => 150, 200 => 250 },
        _removed => {},
        _messy_add => 0,
        _messy_rem => 0,
        units      => 1
    };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start = 190;
    $end   = 199;
    $test_name
        = "add + collapse range ($start - $end) adjacent to next range (last range)";
    $range_ref = {
        _added   => { 10 => 20, 40 => 50, 80 => 100, 120 => 150, 190 => 250 },
        _removed => {},
        _messy_add => 0,
        _messy_rem => 0,
        units      => 1
    };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start = 21;
    $end   = 25;
    $test_name
        = "add + collapse range ($start - $end) adjacent to previous range (first range)";
    $range_ref = {
        _added   => { 10 => 25, 40 => 50, 80 => 100, 120 => 150, 200 => 250 },
        _removed => {},
        _messy_add => 0,
        _messy_rem => 0,
        units      => 1
    };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start = 51;
    $end   = 60;
    $test_name
        = "add + collapse range ($start - $end) adjacent to previous range (middle range)";
    $range_ref = {
        _added   => { 10 => 20, 40 => 60, 80 => 100, 120 => 150, 200 => 250 },
        _removed => {},
        _messy_add => 0,
        _messy_rem => 0,
        units      => 1
    };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start = 251;
    $end   = 300;
    $test_name
        = "add + collapse range ($start - $end) adjacent to previous range (last range)";
    $range_ref = {
        _added   => { 10 => 20, 40 => 50, 80 => 100, 120 => 150, 200 => 300 },
        _removed => {},
        _messy_add => 0,
        _messy_rem => 0,
        units      => 1
    };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start = 51;
    $end   = 79;
    $test_name
        = "add + collapse range ($start - $end) adjacent to both previous and next ranges";
    $range_ref = {
        _added     => { 10 => 20, 40 => 100, 120 => 150, 200 => 250 },
        _removed   => {},
        _messy_add => 0,
        _messy_rem => 0,
        units      => 1
    };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

};

subtest 'remove various ranges' => sub {
    plan tests => 12;

    $start     = 0;
    $end       = 9;
    $test_name = "remove + collapse range ($start - $end) before 1st";
    $range_ref = {
        _added   => { 10 => 20, 40 => 50, 80 => 100, 120 => 150, 200 => 250 },
        _removed => {},
        _messy_add => 0,
        _messy_rem => 0,
        units      => 1
    };
    base_remove_collapse_test( $start, $end, $range_ref, $test_name );

    $start = 0;
    $end   = 10;
    $test_name
        = "remove + collapse range ($start - $end) that begins before 1st and ends on start of 1st";
    $range_ref = {
        _added   => { 11 => 20, 40 => 50, 80 => 100, 120 => 150, 200 => 250 },
        _removed => {},
        _messy_add => 0,
        _messy_rem => 0,
        units      => 1
    };
    base_remove_collapse_test( $start, $end, $range_ref, $test_name );

    $start = 0;
    $end   = 15;
    $test_name
        = "remove + collapse range ($start - $end) that begins before 1st and ends in middle of 1st";
    $range_ref = {
        _added   => { 16 => 20, 40 => 50, 80 => 100, 120 => 150, 200 => 250 },
        _removed => {},
        _messy_add => 0,
        _messy_rem => 0,
        units      => 1
    };
    base_remove_collapse_test( $start, $end, $range_ref, $test_name );

    $start = 0;
    $end   = 19;
    $test_name
        = "remove + collapse range ($start - $end) that begins before 1st and ends just before end of 1st";
    $range_ref = {
        _added   => { 20 => 20, 40 => 50, 80 => 100, 120 => 150, 200 => 250 },
        _removed => {},
        _messy_add => 0,
        _messy_rem => 0,
        units      => 1
    };
    base_remove_collapse_test( $start, $end, $range_ref, $test_name );

    $start = 0;
    $end   = 20;
    $test_name
        = "remove + collapse range ($start - $end) that begins before 1st and ends at end of 1st";
    $range_ref = {
        _added     => { 40 => 50, 80 => 100, 120 => 150, 200 => 250 },
        _removed   => {},
        _messy_add => 0,
        _messy_rem => 0,
        units      => 1
    };
    base_remove_collapse_test( $start, $end, $range_ref, $test_name );

    $start = 0;
    $end   = 45;
    $test_name
        = "remove + collapse range ($start - $end) that begins before 1st and ends in 2nd";
    $range_ref = {
        _added     => { 46 => 50, 80 => 100, 120 => 150, 200 => 250 },
        _removed   => {},
        _messy_add => 0,
        _messy_rem => 0,
        units      => 1
    };
    base_remove_collapse_test( $start, $end, $range_ref, $test_name );

    $start = 50;
    $end   = 80;
    $test_name
        = "remove + collapse range ($start - $end) that begins at end of previous and ends at beginning of next";
    $range_ref = {
        _added   => { 10 => 20, 40 => 49, 81 => 100, 120 => 150, 200 => 250 },
        _removed => {},
        _messy_add => 0,
        _messy_rem => 0,
        units      => 1
    };
    base_remove_collapse_test( $start, $end, $range_ref, $test_name );

    $start = 51;
    $end   = 79;
    $test_name
        = "remove + collapse range ($start - $end) that begins just before end of previous and ends just before beginning of next";
    $range_ref = {
        _added   => { 10 => 20, 40 => 50, 80 => 100, 120 => 150, 200 => 250 },
        _removed => {},
        _messy_add => 0,
        _messy_rem => 0,
        units      => 1
    };
    base_remove_collapse_test( $start, $end, $range_ref, $test_name );

    $start = 130;
    $end   = 140;
    $test_name
        = "remove + collapse range ($start - $end) that begins and ends inside a range";
    $range_ref = {
        _added => {
            10  => 20,
            40  => 50,
            80  => 100,
            120 => 129,
            141 => 150,
            200 => 250
        },
        _removed   => {},
        _messy_add => 0,
        _messy_rem => 0,
        units      => 1
    };
    base_remove_collapse_test( $start, $end, $range_ref, $test_name );

    $start = 75;
    $end   = 175;
    $test_name
        = "remove + collapse range ($start - $end) begins and ends outside of multiple ranges";
    $range_ref = {
        _added     => { 10 => 20, 40 => 50, 200 => 250 },
        _removed   => {},
        _messy_add => 0,
        _messy_rem => 0,
        units      => 1
    };
    base_remove_collapse_test( $start, $end, $range_ref, $test_name );

    $start = 240;
    $end   = 260;
    $test_name
        = "remove + collapse range ($start - $end) that begins in last range and ends after";
    $range_ref = {
        _added   => { 10 => 20, 40 => 50, 80 => 100, 120 => 150, 200 => 239 },
        _removed => {},
        _messy_add => 0,
        _messy_rem => 0,
        units      => 1
    };
    base_remove_collapse_test( $start, $end, $range_ref, $test_name );

    $start = 251;
    $end   = 300;
    $test_name
        = "remove + collapse range ($start - $end) that begins just after last range";
    $range_ref = {
        _added   => { 10 => 20, 40 => 50, 80 => 100, 120 => 150, 200 => 250 },
        _removed => {},
        _messy_add => 0,
        _messy_rem => 0,
        units      => 1
    };
    base_remove_collapse_test( $start, $end, $range_ref, $test_name );

};

subtest 'complement ranges' => sub {
    plan tests => 2;

    my $base_range_ref = build_base();
    my %complement     = $base_range_ref->complement;
    is_deeply(
        \%complement,
        {   '-inf' => 9,
            21     => 39,
            51     => 79,
            101    => 119,
            151    => 199,
            251    => '+inf'
        },
        'Get complement of ranges (with infinite universe)'
    );

    %complement = $base_range_ref->complement( 1, 300 );
    is_deeply(
        \%complement,
        { 1 => 9, 21 => 39, 51 => 79, 101 => 119, 151 => 199, 251 => 300 },
        'Get complement of ranges (with finite universe)'
    );
};

sub base_add_collapse_test {
    my ( $start, $end, $range_ref, $test_name ) = @_;

    my $base_range_ref = build_base();
    $base_range_ref->add( $start, $end );
    collapse_and_test( $base_range_ref, $range_ref, $test_name );
}

sub base_remove_collapse_test {
    my ( $start, $end, $range_ref, $test_name ) = @_;

    my $base_range_ref = build_base();
    $base_range_ref->remove( $start, $end );
    collapse_and_test( $base_range_ref, $range_ref, $test_name );
}

sub build_base {
    my $range = Number::RangeTracker->new();

    my %range_hash = (
        10  => 20,
        40  => 50,
        80  => 90,
        85  => 100,
        120 => 150,
        200 => 250
    );
    $range->add(%range_hash);

    $range->collapse;

    return $range;
}

sub collapse_and_test {
    my ( $base_range_ref, $range_ref, $test_name ) = @_;

    $base_range_ref->collapse;

    is_deeply( $base_range_ref, $range_ref, $test_name );
    print Dumper $base_range_ref if $debug;
}

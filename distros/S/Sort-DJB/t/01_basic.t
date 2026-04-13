#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Sort::DJB qw(:all);
use Sort::DJB::Pure;

# ---- Metadata ----
ok(Sort::DJB::version(), "version(): " . Sort::DJB::version());
ok(Sort::DJB::arch(), "arch(): " . Sort::DJB::arch());
ok(Sort::DJB::int32_implementation(), "int32_implementation(): " . Sort::DJB::int32_implementation());

# ---- Helper ----
sub test_sort {
    my ($name, $xs_func, $pp_func, $input, $expected) = @_;
    my $xs = $xs_func->($input);
    my $pp = $pp_func->($input);
    is_deeply($xs, $expected, "$name XS");
    is_deeply($pp, $expected, "$name Pure");
    is_deeply($xs, $pp,       "$name XS==Pure");
}

# ---- int32 ----
test_sort("int32 basic",
    \&sort_int32, \&Sort::DJB::Pure::sort_int32,
    [5, 3, 1, 4, 2], [1, 2, 3, 4, 5]);

test_sort("int32 negative",
    \&sort_int32, \&Sort::DJB::Pure::sort_int32,
    [-10, 0, 10, -5, 5], [-10, -5, 0, 5, 10]);

test_sort("int32 empty",
    \&sort_int32, \&Sort::DJB::Pure::sort_int32,
    [], []);

test_sort("int32 single",
    \&sort_int32, \&Sort::DJB::Pure::sort_int32,
    [42], [42]);

test_sort("int32 duplicates",
    \&sort_int32, \&Sort::DJB::Pure::sort_int32,
    [3, 1, 3, 1, 2], [1, 1, 2, 3, 3]);

# ---- int32down ----
test_sort("int32down basic",
    \&sort_int32down, \&Sort::DJB::Pure::sort_int32down,
    [5, 3, 1, 4, 2], [5, 4, 3, 2, 1]);

test_sort("int32down negative",
    \&sort_int32down, \&Sort::DJB::Pure::sort_int32down,
    [-10, 0, 10, -5, 5], [10, 5, 0, -5, -10]);

# ---- uint32 ----
test_sort("uint32 basic",
    \&sort_uint32, \&Sort::DJB::Pure::sort_uint32,
    [5, 3, 1, 4, 2], [1, 2, 3, 4, 5]);

test_sort("uint32 large",
    \&sort_uint32, \&Sort::DJB::Pure::sort_uint32,
    [4000000000, 3000000000, 1000000000, 2000000000],
    [1000000000, 2000000000, 3000000000, 4000000000]);

# ---- uint32down ----
test_sort("uint32down basic",
    \&sort_uint32down, \&Sort::DJB::Pure::sort_uint32down,
    [5, 3, 1, 4, 2], [5, 4, 3, 2, 1]);

# ---- int64 ----
test_sort("int64 basic",
    \&sort_int64, \&Sort::DJB::Pure::sort_int64,
    [50, 30, 10, 40, 20], [10, 20, 30, 40, 50]);

test_sort("int64 negative",
    \&sort_int64, \&Sort::DJB::Pure::sort_int64,
    [-100, 0, 100, -50, 50], [-100, -50, 0, 50, 100]);

# ---- int64down ----
test_sort("int64down basic",
    \&sort_int64down, \&Sort::DJB::Pure::sort_int64down,
    [50, 30, 10, 40, 20], [50, 40, 30, 20, 10]);

# ---- uint64 ----
test_sort("uint64 basic",
    \&sort_uint64, \&Sort::DJB::Pure::sort_uint64,
    [5, 3, 1, 4, 2], [1, 2, 3, 4, 5]);

# ---- float64 ----
test_sort("float64 basic",
    \&sort_float64, \&Sort::DJB::Pure::sort_float64,
    [3.14, 1.41, 2.72, 0.58, 1.73], [0.58, 1.41, 1.73, 2.72, 3.14]);

test_sort("float64 negative",
    \&sort_float64, \&Sort::DJB::Pure::sort_float64,
    [-1.5, 0.0, 1.5, -0.5, 0.5], [-1.5, -0.5, 0.0, 0.5, 1.5]);

# ---- float64down ----
test_sort("float64down basic",
    \&sort_float64down, \&Sort::DJB::Pure::sort_float64down,
    [3.14, 1.41, 2.72, 0.58, 1.73], [3.14, 2.72, 1.73, 1.41, 0.58]);

# ---- float32 ----
{
    my $xs = sort_float32([3.14, 1.41, 2.72]);
    ok($xs->[0] < $xs->[1] && $xs->[1] < $xs->[2], "float32 XS ascending");
}

# ---- Larger arrays (various sizes including non-power-of-2) ----
for my $size (7, 8, 15, 16, 31, 32, 100, 1000) {
    my @data = map { int(rand(2000000)) - 1000000 } 1 .. $size;
    my @expected = sort { $a <=> $b } @data;

    my $xs = sort_int32([@data]);
    my $pp = Sort::DJB::Pure::sort_int32([@data]);

    is_deeply($xs, \@expected, "int32 XS n=$size");
    is_deeply($pp, \@expected, "int32 Pure n=$size");
}

# ---- Error handling ----
eval { sort_int32("not a ref") };
ok($@, "dies on non-reference");

eval { sort_int32({}) };
ok($@, "dies on hash reference");

# ---- Export test ----
can_ok('main', 'sort_int32');
can_ok('main', 'sort_float64down');

done_testing();

# Tests for code in src/mergesort_algo.c

use strict;
use warnings;

use Sort::Bucket;
use Test::More;

# All possible order combos of up to 4 values
{
    my @vals = (0, 2**32-1, 1, 2**31-1);
    foreach my $a (@vals) {
        runtest([$a]);
        foreach my $b (@vals) {
            runtest([$a, $b]);
            foreach my $c (@vals) {
                runtest([$a, $b, $c]);
                foreach my $d (@vals) {
                    runtest([$a, $b, $c, $d]);
                }
            }
        }

        # Check for problems caused by equal value runs extending beyond the
        # part of the vector to be sorted.
        runtest([$a, $a, $a, $a], 2, 1);
    }
}

# Try some sorts for a range of data lengths
foreach my $count (5 .. 20, 30, 50, 75, 100, 1000, 10_000) {
    runtest([(123456) x $count]);
    runtest([(654321, 0) x ($count/2)]);
    runtest([rand_elts($count)]);
    runtest([map {12349962 + $_} (0 .. $count-1)]);
    runtest([map {12349962 + $_} reverse (0 .. $count-1)]);
}

done_testing;

sub runtest {
    my ($list, $sortlen, $offset) = @_;
    $offset ||= 0;
    $sortlen ||= (@$list - $offset);

    # Apply the mergesort to the $sortlen elts of @$list starting at
    # $offset, and check that they are sorted correctly.

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $offset < 0 and die "bad offset $offset";
    $offset + $sortlen > @$list and die "$offset,$sortlen too large";

    # Pad the top and bottom of the list with plenty of extra elts, to
    # ensure that ms_do_mergesort() has enough room to sort down, and that
    # we have some extra values around the area that ms_do_mergesort()
    # should be modifying so we will notice if it goes out of bounds.
    my @pre = rand_elts(2 * $sortlen);
    my @post = rand_elts($sortlen);
    my @to_sort = (@pre, @$list, @post);
    $offset += @pre;

    # Do a stable sort of the subset of @$list that we're sorting, to
    # get the order into which those elts should be permuted by the call
    # to ms_do_mergesort().
    my @ref_sort;
    foreach my $i (0 .. $sortlen-1) {
        push @ref_sort, [ $to_sort[$offset + $i], $offset + $i ];
    }
    my @permute = map { $_->[1] }
                  sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] }
                  @ref_sort;

    Sort::Bucket::_ms_do_mergesort_testharness(@to_sort, $offset, $sortlen);
    my $should_sort_to = $offset - ($sortlen - 1);

    is_deeply [@to_sort[0 .. $should_sort_to-1]],
                       [0 .. $should_sort_to-1],
              "elts below sort not modified";

    is_deeply [@to_sort[$should_sort_to .. $should_sort_to+$sortlen-1]],
              \@permute,
              "sorted elts are correct";

    is_deeply [@to_sort[$offset+$sortlen .. $#to_sort]],
                       [$offset+$sortlen .. $#to_sort],
              "elts above sort not modified";
}

sub rand_elts {
    my $count = shift;

    my @elts;
    for my $i (0 .. $count) {
        push @elts, int rand 2**32;
    }
    return @elts;
}


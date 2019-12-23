#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Sort::SubList qw(sort_sublist);

subtest "basic" => sub {
    my @res = sort_sublist(sub { length($_[0]) <=> length($_[1]) }, sub { /\D/ }, "quux", 12, 1, "us", 400, 3, "a", "foo");
    is_deeply(\@res, ["a", 12, 1, "us", 400, 3, "foo", "quux"]) or diag explain \@res;
};

done_testing;

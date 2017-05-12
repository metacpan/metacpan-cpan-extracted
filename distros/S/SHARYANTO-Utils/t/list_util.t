#!perl

use 5.010;
use strict;
use warnings;

use Test::More 0.98;

use SHARYANTO::List::Util qw(
                                uniq_adj
                                uniq_adj_ci
                                uniq_ci
                                find_missing_nums_in_seq
                                find_missing_strs_in_seq
                                max_in_range maxstr_in_range
                                min_in_range minstr_in_range
                        );

subtest "uniq_adj" => sub {
    is_deeply([uniq_adj(1, 2, 4, 4, 4, 2, 4)], [1, 2, 4, 2, 4]);
};

subtest "uniq_adj_ci" => sub {
    is_deeply([uniq_adj   (qw/a b B a b C c/)], [qw/a b B a b C c/]);
    is_deeply([uniq_adj_ci(qw/a b B a b C c/)], [qw/a b a b C/]);
};

subtest "uniq_ci" => sub {
    #is_deeply([uniq   (qw/a b B a b C c/)], [qw/a b B C c/]);
    is_deeply([uniq_ci(qw/a b B a b C c/)], [qw/a b C/]);
};

subtest find_missing_nums_in_seq => sub {
    is_deeply([find_missing_nums_in_seq(1, 1, 3, 4, 6, 8, 7)], [2, 5]);
};

subtest find_missing_strs_in_seq => sub {
    is_deeply([find_missing_strs_in_seq("a", "c", "e")], ["b", "d"]);
};

subtest max_in_range => sub {
    is(max_in_range(undef,undef, 1,6,4,2,8), 8);
    is(max_in_range(undef,6,     1,6,4,2,8), 6);
    is(max_in_range(3,undef,     1,6,4,2,8), 8);
    is(max_in_range(9,undef,     1,6,4,2,8)//"undef", "undef");
    is(max_in_range(3,6,         1,6,4,2,8), 6);
    is(max_in_range(9,9,         1,6,4,2,8)//"undef", "undef");
};

# TODO: maxstr_in_range

subtest min_in_range => sub {
    is(min_in_range(undef,undef, 1,6,4,2,8), 1);
    is(min_in_range(undef,6,     1,6,4,2,8), 1);
    is(min_in_range(undef,0,     1,6,4,2,8)//"undef", "undef");
    is(min_in_range(3,undef,     1,6,4,2,8), 4);
    is(min_in_range(1,undef,     1,6,4,2,8), 1);
    is(min_in_range(3,6,         1,6,4,2,8), 4);
    is(min_in_range(9,9,         1,6,4,2,8)//"undef", "undef");
};

# TODO: minstr_in_range

DONE_TESTING:
done_testing;

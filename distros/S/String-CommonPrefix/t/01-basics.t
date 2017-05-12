#!perl -T

use 5.010;
use strict;
use warnings;

use Test::More 0.98;

use String::CommonPrefix qw(
                                  common_prefix
                          );
use String::CommonSuffix qw(
                                  common_suffix
                          );

subtest "common_prefix" => sub {
    is(common_prefix(""), "");
    is(common_prefix("a", "", "bc"), "");
    is(common_prefix("a", "b"), "");
    is(common_prefix("a", "ab"), "a");
    is(common_prefix("a", "ab", "c"), "");
    is(common_prefix("ab", "ab", "abc"), "ab");
};

subtest "common_suffix" => sub {
    is(common_suffix(""), "");
    is(common_suffix("a", "", "bc"), "");
    is(common_suffix("a", "b"), "");
    is(common_suffix("a", "ba"), "a");
    is(common_suffix("a", "ba", "c"), "");
    is(common_suffix("ba", "ba", "cba"), "ba");
};

DONE_TESTING:
done_testing();

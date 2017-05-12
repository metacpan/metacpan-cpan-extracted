#!perl

use 5.010;
use strict;
use warnings;

use String::Wildcard::DOS qw(contains_wildcard);
use Test::More 0.98;

subtest contains_wildcard => sub {
    subtest "none" => sub {
        ok(!contains_wildcard(""));
        ok(!contains_wildcard("abc"));
    };

    subtest "*" => sub {
        ok( contains_wildcard("a*"));
        ok( contains_wildcard("a\\*"));
        ok( contains_wildcard("a\\\\*"));
    };

    subtest "?" => sub {
        ok( contains_wildcard("a?"));
        ok( contains_wildcard("a\\?"));
        ok( contains_wildcard("a\\\\?"));
    };
};

DONE_TESTING:
done_testing();

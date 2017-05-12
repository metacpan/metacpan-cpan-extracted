#!perl

use 5.010;
use strict;
use warnings;

use String::Wildcard::SQL qw(contains_wildcard);
use Test::More 0.98;

subtest contains_wildcard => sub {
    subtest "none" => sub {
        ok(!contains_wildcard(""));
        ok(!contains_wildcard("abc"));
    };

    subtest "%" => sub {
        ok( contains_wildcard("ab%"));
        ok(!contains_wildcard("ab\\%"));
        ok( contains_wildcard("ab\\\\%"));
    };

    subtest "_" => sub {
        ok( contains_wildcard("ab_"));
        ok(!contains_wildcard("ab\\_"));
        ok( contains_wildcard("ab\\\\_"));
    };

    #subtest "character class" => sub {
    #    ok( contains_wildcard("ab[cd]"));
    #    ok(!contains_wildcard("ab[cd"));
    #    ok(!contains_wildcard("ab\\[cd]"));
    #    ok( contains_wildcard("ab\\\\[cd]"));
    #    ok(!contains_wildcard("ab[cd\\]"));
    #    ok( contains_wildcard("ab[cd\\\\]"));
    #};
};

DONE_TESTING:
done_testing();

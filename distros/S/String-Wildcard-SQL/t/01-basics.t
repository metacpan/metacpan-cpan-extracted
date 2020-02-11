#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;

use String::Wildcard::SQL qw(
                                $RE_WILDCARD_SQL
                                contains_wildcard
                        );

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

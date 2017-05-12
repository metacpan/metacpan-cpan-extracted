#!perl

use 5.010;
use strict;
use warnings;

use String::Wildcard::Bash qw(
                                 $RE_WILDCARD_BASH
                                 contains_wildcard
                                 convert_wildcard_to_sql
                         );
use Test::More 0.98;

subtest contains_wildcard => sub {
    subtest "none" => sub {
        ok(!contains_wildcard(""));
        ok(!contains_wildcard("abc"));
    };

    subtest "*" => sub {
        ok( contains_wildcard("ab*"));
        ok(!contains_wildcard("ab\\*"));
        ok( contains_wildcard("ab\\\\*"));
    };

    subtest "?" => sub {
        ok( contains_wildcard("ab?"));
        ok(!contains_wildcard("ab\\?"));
        ok( contains_wildcard("ab\\\\?"));
    };

    subtest "character class" => sub {
        ok( contains_wildcard("ab[cd]"));
        ok(!contains_wildcard("ab[cd"));
        ok(!contains_wildcard("abcd]"));
        ok(!contains_wildcard("ab\\[cd]"));
        ok( contains_wildcard("ab\\\\[cd]"));
        ok(!contains_wildcard("ab[cd\\]"));
        ok( contains_wildcard("ab[cd\\\\]"));
    };

    subtest "brace expansion" => sub {
        ok(!contains_wildcard("{}"));    # need at least a comma
        ok(!contains_wildcard("{a}"));   # ditto
        ok(!contains_wildcard("{a*}"));  # ditto
        ok(!contains_wildcard("{a?}"));  # ditto
        ok(!contains_wildcard("{[a]}")); # ditto
        ok( contains_wildcard("{,}"));
        ok( contains_wildcard("{a,}"));
        ok( contains_wildcard("{a*,}"));
        ok( contains_wildcard("{a?,}"));
        ok( contains_wildcard("{[a],}"));
        ok( contains_wildcard("{a*,b}"));
        ok( contains_wildcard("{a,b[a]}"));

        ok(!contains_wildcard("\\{a,b}"));
        ok( contains_wildcard("\\{a*,b}")); # because * is not inside brace
        ok( contains_wildcard("\\{a?,b}")); # ditto
        ok( contains_wildcard("\\{[a],}")); # ditto
        ok( contains_wildcard("\\\\{a,}"));
        ok(!contains_wildcard("{a,b\\}"));
        ok( contains_wildcard("{a*,b\\}"));  # because * is not inside brace
        ok( contains_wildcard("{a?,b\\}"));  # ditto
        ok( contains_wildcard("{[a],b\\}")); # ditto
        ok( contains_wildcard("{a,b\\\\}"));
    };

    subtest "other non-wildcard" => sub {
        ok(!contains_wildcard("~/a"));
        ok(!contains_wildcard("\$a"));
    };

    subtest "sql" => sub {
        ok(!contains_wildcard("a%"));
        ok(!contains_wildcard("a_"));
    };
};

subtest convert_wildcard_to_sql => sub {
    is(convert_wildcard_to_sql('a*'), 'a%');
    is(convert_wildcard_to_sql('a*b*'), 'a%b%');
    is(convert_wildcard_to_sql('a\\*'), 'a\\*');
    is(convert_wildcard_to_sql('a?'), 'a_');
    is(convert_wildcard_to_sql('a??'), 'a__');
    is(convert_wildcard_to_sql('a\\?'), 'a\\?');
    is(convert_wildcard_to_sql('a%'), 'a\\%');
    is(convert_wildcard_to_sql('a\\%'), 'a\\%');
    is(convert_wildcard_to_sql('a_'), 'a\\_');
    is(convert_wildcard_to_sql('a\\_'), 'a\\_');

    # passed as-is
    is(convert_wildcard_to_sql('a[b]'), 'a[b]');
    is(convert_wildcard_to_sql('a\\{b,c}'), 'a\\{b,c}');
    is(convert_wildcard_to_sql('a{b,c}'), 'a{b,c}');
};

DONE_TESTING:
done_testing();

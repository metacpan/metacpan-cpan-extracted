#!perl

use 5.010;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use String::Wildcard::Bash qw(
                                 $RE_WILDCARD_BASH
                                 contains_wildcard
                                 convert_wildcard_to_sql
                                 convert_wildcard_to_re
                         );

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
        ok(!contains_wildcard("{a\\,b}")); # ditto
        ok( contains_wildcard("{,}"));
        ok( contains_wildcard("{a,}"));
        ok( contains_wildcard("{a*,}"));
        ok( contains_wildcard("{a?,}"));
        ok( contains_wildcard("{[a],}"));
        ok( contains_wildcard("{a*,b}"));
        ok( contains_wildcard("{a,b[a]}"));
        ok( contains_wildcard("{a\\,b,c}"));

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
    is(convert_wildcard_to_sql('a**b'), 'a%b');
    is(convert_wildcard_to_sql('a*b*'), 'a%b%');
    is(convert_wildcard_to_sql('a\\*'), 'a\\*');
    is(convert_wildcard_to_sql('a?'), 'a_');
    is(convert_wildcard_to_sql('a??'), 'a__');
    is(convert_wildcard_to_sql('a\\?'), 'a\\?');
    is(convert_wildcard_to_sql('a%'), 'a\\%');
    is(convert_wildcard_to_sql('a\\%'), 'a\\%');
    is(convert_wildcard_to_sql('a_'), 'a\\_');
    is(convert_wildcard_to_sql('a\\_'), 'a\\_');
    is(convert_wildcard_to_sql('a\\{b,c}'), 'a\\{b,c}'); # brace literal

    # passed as-is
    dies_ok { convert_wildcard_to_sql('a[b]') }; # class
    dies_ok { convert_wildcard_to_sql('a{b}') }; # brace literal single element
    dies_ok { convert_wildcard_to_sql('a{b,c}') }; # brace
};

subtest convert_wildcard_to_re => sub {
    # brace
    is(convert_wildcard_to_re('{a}'), "\\{a\\}");
    is(convert_wildcard_to_re('f.{a.,b*}'), "f\\.(?:a\\.|b.*)");
    # charclass
    is(convert_wildcard_to_re('[abc-j]'), "[abc-j]");
    # bash joker
    is(convert_wildcard_to_re('a?foo*'), "a.foo.*");
    # sql joker
    is(convert_wildcard_to_re('a%'), "a\\%");

    subtest "opt:brace=0" => sub {
        is(convert_wildcard_to_re({brace=>0}, '{a,b}'), "\\{a\\,b\\}");
    };
    subtest "opt:dotglob" => sub {
        is(convert_wildcard_to_re({}, '*a*'), "[^.].*a.*");
        is(convert_wildcard_to_re({dotglob=>1}, '*a*'), ".*a.*");
        is(convert_wildcard_to_re({}, '.*'), "\\..*");
        is(convert_wildcard_to_re({dotglob=>1}, '.*'), "\\..*");
    };
};

DONE_TESTING:
done_testing;

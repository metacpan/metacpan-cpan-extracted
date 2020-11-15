#!perl

use strict;
use warnings;
use Test::More 0.98;

use String::SimpleEscape qw(simple_escape_string simple_unescape_string);

subtest "simple_escape_string" => sub {
    is(simple_escape_string(""), "");
    is(simple_escape_string("abc"), "abc");
    is(simple_escape_string("abc\012\t\t\"\\"), "abc\\n\\t\\t\\\"\\\\");
};

subtest "simple_unescape_string" => sub {
    is(simple_unescape_string(""), "");
    is(simple_unescape_string("abc"), "abc");
    is(simple_unescape_string("abc\012\t\t\"\\"), "abc\012\t\t\"\\");
    is(simple_unescape_string("abc\\n\\t\\t\\\"\\\\"), "abc\012\t\t\"\\");
};

DONE_TESTING:
done_testing();

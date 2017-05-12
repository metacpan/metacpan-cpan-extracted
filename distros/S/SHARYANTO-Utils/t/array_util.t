#!perl

use 5.010;
use strict;
use warnings;

use Test::More 0.98;

use SHARYANTO::Array::Util qw(
                                 match_array_or_regex
                                 match_regex_or_array
                                 split_array
                                 replace_array_content
                         );

ok( match_array_or_regex("foo", [qw/foo bar baz/]), "match array 1");
ok(!match_array_or_regex("qux", [qw/foo bar baz/]), "match array 2");

ok( match_array_or_regex("foo", ["foo", qr/bar/]), "match array with regex 1");
ok( match_array_or_regex("bar", ["foo", qr/ba./]), "match array with regex 2");
ok(!match_array_or_regex("qux", ["foo", qr/bar/]), "match array with regex 3");

ok( match_array_or_regex("foo", "foo"), "match regex 0");
ok( match_array_or_regex("foo", qr/foo?/), "match regex 1");
ok(!match_array_or_regex("qux", qr/foo?/), "match regex 2");

eval { match_array_or_regex("foo", {}) };
my $eval_err = $@;
ok($eval_err, "match invalid -> dies");

ok( match_regex_or_array("foo", qr/foo?/), "alias 1");
ok(!match_array_or_regex("qux", qr/foo?/), "alias 2");

subtest "split_array" => sub {
    is_deeply([split_array("x", [qw/a b x c d x e/])],
              [[qw/a b/], [qw/c d/], [qw/e/]], "str 1");
    is_deeply([split_array("x", [qw/a b 1x c d x1 e/])],
              [[qw/a b 1x c d x1 e/]], "str 2");

    is_deeply([split_array(qr/x/, [qw/a b 1x c d x1 e/])],
              [[qw/a b/], [qw/c d/], [qw/e/]], "re 1");

    is_deeply([split_array(qr/x/, [qw/a b x c d x e/], 2)],
              [[qw/a b/], [qw/c d x e/]], "limit");
    is_deeply([split_array(qr/(x)/, [qw/a b x c d x e/])],
              [[qw/a b/], [qw/x/], [qw/c d/], [qw/x/], [qw/e/]], "capture 1");
    is_deeply([split_array(qr/(x)(x)/, [qw/a b xx c xx e/])],
              [[qw/a b/], [qw/x x/], [qw/c/], [qw/x x/], [qw/e/]], "capture 2");
};

subtest "replace_array_content" => sub {
    my $a = [1,2,3];
    my $refa = "$a";
    replace_array_content($a, 4, 5, 6);
    is_deeply($a, [4,5,6], "content changed");
    is("$a", $refa, "refaddr doesn't change");
};

DONE_TESTING:
done_testing();

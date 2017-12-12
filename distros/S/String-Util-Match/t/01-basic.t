#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use String::Util::Match qw(
                              match_array_or_regex
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

DONE_TESTING:
done_testing();

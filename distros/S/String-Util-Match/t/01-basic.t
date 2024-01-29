#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use String::Util::Match qw(
                              match_string
                              match_array_or_regex
                              num_occurs
                      );

subtest match_string => sub {
    # undef str
    ok(!match_string(str => undef, matcher => undef));

    # str matcher
    ok( match_string(str => 'foo', matcher => 'foo'));
    ok(!match_string(str => 'foo', matcher => 'Foo'));
    ok( match_string(str => 'foo', matcher => 'FOO', ignore_case=>1));
    ok(!match_string(str => 'foo', matcher => 'bar'));

    # regexp matcher
    ok( match_string(str => 'foo', matcher => qr/fo.+/));
    ok(!match_string(str => 'foo', matcher => qr/bar/));

    # aos matcher
    ok( match_string(str => 'foo', matcher => ['bar', 'foo']));
    ok(!match_string(str => 'foo', matcher => ['bar', 'FOO']));
    ok( match_string(str => 'foo', matcher => ['bar', 'FOO'], ignore_case=>1));
    ok(!match_string(str => 'foo', matcher => ['bar', 'baz']));

    # code matcher
    ok( match_string(str => 'foo', matcher => sub {$_[0] eq 'foo'}));
    ok(!match_string(str => 'foo', matcher => sub {$_[0] eq 'bar'}));

    # other matcher
    dies_ok { match_string(str => 'foo', matcher => {}) };
};

subtest match_array_or_regex => sub {
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
};

subtest num_occurs => sub {
    is(num_occurs("foobarbaz", "a"), 2);
    is(num_occurs("foobarbaz", "ba"), 2);
    is(num_occurs("foobarbaz", "A"), 0);
    is(num_occurs("foobarbaz", qr/[aeiou]/), 4);
};

DONE_TESTING:
done_testing;

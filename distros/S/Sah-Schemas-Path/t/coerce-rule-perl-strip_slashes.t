#!perl

use 5.010001;
use strict;
use warnings;

use Data::Sah::Coerce qw(gen_coercer);
use Test::More 0.98;
use Test::Needs;

subtest "basics" => sub {
    my $c = gen_coercer(type=>"str", coerce_rules=>["From_str::strip_slashes"]);

    subtest "non-strings are uncoerced" => sub {
        is_deeply($c->([]), [], "uncoerced");
    };
    subtest "strings" => sub {
        is($c->("foo"), "foo");
        is($c->("/"), "/");
        is($c->("/foo"), "/foo");
        is($c->("//foo///bar////baz"), "/foo/bar/baz");
        is($c->("foo/"), "foo");
    };
};

done_testing;

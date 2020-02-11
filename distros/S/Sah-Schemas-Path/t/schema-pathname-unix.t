#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah qw(gen_validator);

subtest "basics" => sub {
    my $v = gen_validator(
        "pathname::unix",
        {return_type => "str+val"},
    );

    my ($res, $val);

    # has null
    ($res, $val) = @{ $v->("/foo\0") };
    ok($res);

    # empty
    ($res, $val) = @{ $v->("") };
    ok($res);

    # valid: /
    ($res, $val) = @{ $v->("/") };
    ok(!$res);
    is($val, "/");

    # valid: foo/bar/baz
    ($res, $val) = @{ $v->("foo///bar/baz") };
    ok(!$res);
    is($val, "foo/bar/baz");
};

done_testing;

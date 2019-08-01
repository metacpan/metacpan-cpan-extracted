#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah qw(gen_validator);

subtest "basics" => sub {
    my $v = gen_validator(
        "dirname::unix",
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
};

done_testing;

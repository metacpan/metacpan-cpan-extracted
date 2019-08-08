#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah qw(gen_validator);

subtest "basics" => sub {
    my $v = gen_validator(
        "unix::groupname",
        {return_type => "str+val"},
    );

    my ($res, $val);

    # invalid account syntax
    ($res, $val) = @{ $v->("") }; ok($res);
    ($res, $val) = @{ $v->("-andy") }; ok($res);
    ($res, $val) = @{ $v->("1000") }; ok($res);
    ($res, $val) = @{ $v->("an dy") }; ok($res);

    # valid account syntax
    ($res, $val) = @{ $v->("andy") }; ok(!$res);
    ($res, $val) = @{ $v->("an.dy") }; ok(!$res);
};

done_testing;

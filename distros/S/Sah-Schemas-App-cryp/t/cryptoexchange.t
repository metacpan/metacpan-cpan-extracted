#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah qw(gen_validator);

subtest "basics" => sub {
    my $v = gen_validator(
        "cryptoexchange",
        {return_type => "str+val"},
    );

    my ($res, $val);

    ($res, $val) = @{ $v->("foo") };
    ok($res);

    ($res, $val) = @{ $v->("GDAX") };
    ok(!$res);
    is($val, "gdax");

    ($res, $val) = @{ $v->("BX Thailand") };
    ok(!$res);
    is($val, "bx-thailand");

    ($res, $val) = @{ $v->("BX-thailand") };
    ok(!$res);
    is($val, "bx-thailand");

    ($res, $val) = @{ $v->("BX") };
    ok(!$res);
    is($val, "bx-thailand");

};

done_testing;

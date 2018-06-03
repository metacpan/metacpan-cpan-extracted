#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah qw(gen_validator);

subtest "basics" => sub {
    my $v = gen_validator(
        "cryptocurrency",
        {return_type => "str+val"},
    );

    my ($res, $val);

    ($res, $val) = @{ $v->("foo") };
    ok($res);

    ($res, $val) = @{ $v->("BTC") };
    ok(!$res);
    is($val, "BTC");

    ($res, $val) = @{ $v->("btc") };
    ok(!$res);
    is($val, "BTC");

    ($res, $val) = @{ $v->("ethereum classic") };
    ok(!$res);
    is($val, "ETC");
};

done_testing;

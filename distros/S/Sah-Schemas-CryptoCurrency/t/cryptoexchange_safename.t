#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah qw(gen_validator);

subtest "basics" => sub {
    my $v = gen_validator(
        "cryptoexchange::safename",
        {return_type => "str+val"},
    );

    my ($res, $val);

    # currently the schema doesn't check for valid code
    #($res, $val) = @{ $v->("foo") };
    #ok($res);

    ($res, $val) = @{ $v->("GDAX") };
    ok(!$res);
    is($val, "gdax");

    ($res, $val) = @{ $v->("gdax") };
    ok(!$res);
    is($val, "gdax");
};

done_testing;

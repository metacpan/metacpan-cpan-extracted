#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah qw(gen_validator);

subtest "basics" => sub {
    my $v = gen_validator(
        "cryptocurrency::safename",
        {return_type => "str+val"},
    );

    my ($res, $val);

    # currently the schema doesn't check for valid safename
    #($res, $val) = @{ $v->("foo") };
    #ok($res);

    ($res, $val) = @{ $v->("bitcoin") };
    ok(!$res);
    is($val, "bitcoin");

    ($res, $val) = @{ $v->("Ethereum-Classic") };
    ok(!$res);
    is($val, "ethereum-classic");
};

done_testing;

#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah qw(gen_validator);
use Data::Sah::Coerce qw(gen_coercer);

subtest "basics" => sub {
    my $v = gen_validator(
        ["net::ipv4"],
        {return_type=>"bool"},
    );

    # NetAddr::IP accepts it
    ok($v->("localhost"));

    ok($v->("1.2.3.4"));
    ok(!$v->("1.2.3.400"));
    ok(!$v->("1.2.3.0/24"));
    ok(!$v->("2001:0db8:85a3:0000:0000:8a2e:0370:7334"));
    ok(!$v->("::1/128"));
};

done_testing;

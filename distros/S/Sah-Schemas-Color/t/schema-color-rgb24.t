#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;
use Test::Needs;

use Data::Sah qw(gen_validator);

subtest "basics" => sub {
    test_needs "Graphics::ColorNames";
    test_needs "Graphics::ColorNames::X";

    my $v = gen_validator(
        "color::rgb24",
        {return_type => "str+val"},
    );

    my ($res, $val);

    # valid: /
    ($res, $val) = @{ $v->("black") };
    ok(!$res);
    is($val, "000000");
};

done_testing;

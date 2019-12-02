#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;
use Test::Needs;

use Data::Sah::Coerce qw(gen_coercer);

subtest "basics" => sub {
    my $c = gen_coercer(type=>"str", coerce_rules=>["From_str::rgb24_from_colorname_X_or_code"]);

    subtest "uncoerced" => sub {
        is_deeply($c->([]), [], "uncoerced");
    };
    subtest "coerced" => sub {
        is_deeply($c->("black"), "000000");
    };
};

done_testing;

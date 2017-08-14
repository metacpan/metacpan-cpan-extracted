#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah::Coerce qw(gen_coercer);

subtest "basics" => sub {
    my $c = gen_coercer(type=>"float", coerce_rules=>["str_as_percent"]);

    is($c->("a"), "a", "uncoerced: non-number");
    is_deeply($c->([]), [], "uncoerced: array");

    is($c->(0.3), 0.003);
    is($c->("0.3%"), 0.003);
    is($c->(1), 0.01);
    is($c->("1%"), 0.01);
    is($c->(100), 1.00);
    is($c->("100%"), 1.00);
    is($c->(200), 2.00);
    is($c->("200%"), 2.00);

    is($c->("0.3 %"), 0.003, "whitespace allowed");
};

done_testing;

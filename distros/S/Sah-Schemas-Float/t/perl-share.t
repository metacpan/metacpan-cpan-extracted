#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use Data::Sah::Coerce qw(gen_coercer);

subtest "basics" => sub {
    my $c = gen_coercer(type=>"float", coerce_rules=>["str_share"]);

    is($c->(-1), -1, "uncoerced: negative");
    is($c->("a"), "a", "uncoerced: non-number");
    is_deeply($c->([]), [], "uncoerced: array");

    is($c->(0.3), 0.3);
    is($c->(1), 1);
    is($c->(2), 0.02);
    is($c->(20), 0.2);
    is($c->("20%"), 0.2);
    is($c->("0.3%"), 0.003);

    dies_ok { $c->(200) } "number > 100";
    dies_ok { $c->("200%") } "percent > 100";
};

done_testing;

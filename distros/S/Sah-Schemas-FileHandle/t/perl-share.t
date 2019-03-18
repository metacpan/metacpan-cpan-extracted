#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah::Coerce qw(gen_coercer);

subtest "basics" => sub {
    my $c = gen_coercer(
        type=>"float",
        coerce_rules=>["str_share"],
        return_type=>"status+err+val",
    );

    is_deeply($c->(-1), [undef, undef, -1], "uncoerced: negative");
    is_deeply($c->("a"), [undef, undef, "a"], "uncoerced: non-number");
    is_deeply($c->([]), [undef, undef, []], "uncoerced: array");

    is_deeply($c->(0.3), [1, undef, 0.3]);
    is_deeply($c->(1), [1, undef, 1]);
    is_deeply($c->(2), [1, undef, 0.02]);
    is_deeply($c->(20), [1, undef, 0.2]);
    is_deeply($c->("20%"), [1, undef, 0.2]);
    is_deeply($c->("0.3%"), [1, undef, 0.003]);

    my $res;

    $res = $c->(200);
    ok($res->[1],  "number > 100");

    $res = $c->("200%");
    ok($res->[1], "percent > 100");

};

done_testing;

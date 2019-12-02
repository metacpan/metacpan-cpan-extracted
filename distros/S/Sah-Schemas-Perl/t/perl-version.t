#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;
use Test::Needs;

subtest "coercion" => sub {
    test_needs 'Data::Sah::Coerce';

    my $c = Data::Sah::Coerce::gen_coercer(
        type=>"obj",
        coerce_rules => ['From_str::perl_version'],
        return_type => "status+err+val",
    );

    is_deeply($c->([]), [undef, undef, []], "uncoerced");

    my $res;

    $res = $c->("*");
    if ($] > 5.012) {
        ok($res->[1], "fail on invalid version");
    } else {
        ok(!$res->[1], "warns on invalid version");
    }

    $res = $c->("1.2.0");
    ok($res->[2] == version->parse("1.2.00"));
};

done_testing;

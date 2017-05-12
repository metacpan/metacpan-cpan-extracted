#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;
use Test::Needs;
use Test::Warn;

subtest "coercion" => sub {
    test_needs 'Data::Sah::Coerce';

    my $c = Data::Sah::Coerce::gen_coercer(
        type=>"obj", coerce_rules => ['str_perl_version']);

    is_deeply($c->([]), [], "uncoerced");
    if ($] > 5.012) {
        dies_ok { $c->("*") } "dies on invalid version";
    } else {
        warnings_like { $c->("*") } qr/invalid/i, "warns on invalid version";
    }
    ok($c->("1.2.0") == version->parse("1.2.00"));
};

done_testing;

#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah qw(gen_validator);

subtest "basics" => sub {
    my $v = gen_validator(
        "cryptoexchange",
        {return_type => "str+val"},
    );

    my ($res0, $res, $val);

    $res0 = $v->("foo");
    ($res, $val) = @$res0;
    ok($res) or diag explain $res0;

    $res0 = $v->("BX Thailand");
    ($res, $val) = @$res0;
    ok(!$res) or diag explain $res0;
    is($val, "bx-thailand") or diag explain $res0;

    # case variation
    $res0 = $v->("BX-thailand");
    ($res, $val) = @$res0;
    ok(!$res) or diag explain $res0;
    is($val, "bx-thailand") or diag explain $res0;

    $res0 = $v->("BX");
    ($res, $val) = @$res0;
    ok(!$res) or diag explain $res0;
    is($val, "bx-thailand") or diag explain $res0;

};

done_testing;

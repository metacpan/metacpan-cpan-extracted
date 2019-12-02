#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah qw(gen_validator);

subtest "basics" => sub {
    my $v = gen_validator(
        "cryptoexchange::account",
        {return_type => "str+val"},
    );

    my ($res, $val);

    # invalid account syntax
    ($res, $val) = @{ $v->("indodax/a b") };
    ok($res);

    # account too long
    ($res, $val) = @{ $v->("indodax/".("a" x 65)) };
    ok($res);

    # unknown cryptoexchange
    ($res, $val) = @{ $v->("foo/acc1") };
    ok($res);

    ($res, $val) = @{ $v->("indodax") };
    ok(!$res);
    is($val, "indodax/default");

    #($res, $val) = @{ $v->("GDAX/acc1") };
    #ok(!$res);
    #is($val, "gdax/acc1");

};

done_testing;

#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah qw(gen_validator);

subtest "basics" => sub {
    my $v = gen_validator(
        "perl::qualified_funcname",
        {return_type => "str+val"},
    );

    my ($res, $val);

    # invalid, unqualified
    ($res, $val) = @{ $v->("foo") };
    ok($res);

    # valid, qualified
    ($res, $val) = @{ $v->("Foo::0Bar::foo") };
    ok(!$res);

    # invalid: starts with digit
    ($res, $val) = @{ $v->("Foo::Bar::0foo") };
    ok($res);
};

done_testing;

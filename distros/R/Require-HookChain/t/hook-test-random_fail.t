#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

{
    # remove all hooks first
    local @INC = grep { !ref } @INC;
    require Require::HookChain;
    Require::HookChain->import("test::random_fail", 0);

    # then remove all Require::HookChainTest::* modules from %INC
    for (keys %INC) { delete $INC{$_} if m!^Require/HookChainTest/! }

    # now the tests ...

    lives_ok { require Require::HookChainTest::One };

    Require::HookChain->import("test::random_fail", 1);

    dies_ok { require Require::HookChainTest::Two };
}

done_testing;

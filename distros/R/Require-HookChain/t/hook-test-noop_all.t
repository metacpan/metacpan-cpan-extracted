#!perl

use strict;
use warnings;
use Test::More 0.98;

{
    # remove all hooks first
    local @INC = grep { !ref } @INC;
    require Require::HookChain;
    Require::HookChain->import("test::noop_all");

    # then remove all Require::HookChainTest::* modules from %INC
    for (keys %INC) { delete $INC{$_} if m!^Require/HookChainTest/! }

    # now the tests ...

    undef $Require::HookChainTest::var1;
    require Require::HookChainTest::One;
    is_deeply($Require::HookChainTest::var1, undef);
}

done_testing;

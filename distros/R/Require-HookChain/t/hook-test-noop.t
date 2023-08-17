#!perl

use strict;
use warnings;
use Test::More 0.98;

{
    # remove all hooks first
    local @INC = grep { !ref } @INC;
    require Require::HookChain;
    Require::HookChain->import("test::noop");

    # then remove all Require::HookChainTest::* modules from %INC
    for (keys %INC) { delete $INC{$_} if m!^Require/HookChainTest/! }

    # now the tests ...

    # XXX this does not really test the hook
    undef $Require::HookChainTest::var1;
    require Require::HookChainTest::One;
    is_deeply($Require::HookChainTest::var1, 1);
}

done_testing;

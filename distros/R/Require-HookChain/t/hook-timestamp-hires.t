#!perl

use strict;
use warnings;
use Test::More 0.98;

{
    # remove all hooks first
    local @INC = grep { !ref } @INC;
    require Require::HookChain;
    Require::HookChain->import("timestamp::hires");

    # then remove all Require::HookChainTest::* modules from %INC
    for (keys %INC) { delete $INC{$_} if m!^Require/HookChainTest/! }

    # now the tests ...

    %Require::HookChain::timestamp::hires::Timestamps = ();
    require Require::HookChainTest::One;
    is(scalar(keys %Require::HookChain::timestamp::hires::Timestamps), 1);
}

done_testing;

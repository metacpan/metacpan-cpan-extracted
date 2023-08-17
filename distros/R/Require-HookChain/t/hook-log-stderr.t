#!perl

use strict;
use warnings;
use Test::More 0.98;

use Capture::Tiny 'capture';

{
    # remove all hooks first
    local @INC = grep { !ref } @INC;
    require Require::HookChain;
    Require::HookChain->import("log::stderr");

    # then remove all Require::HookChainTest::* modules from %INC
    for (keys %INC) { delete $INC{$_} if m!^Require/HookChainTest/! }

    # now the tests ...

    my ($stdout, $stderr, undef) = capture { require Require::HookChainTest::One };
    is($stdout, "");
    like($stderr, qr/\A\[time[^\]]+\] Require::HookChain::log::stderr: Require-ing/);

}

done_testing;

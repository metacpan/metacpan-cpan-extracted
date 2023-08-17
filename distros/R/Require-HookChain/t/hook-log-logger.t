#!perl

use strict;
use warnings;
use Test::More 0.98;

use Log::ger::Output::String; # so it can be detected by prereqs scanner
use Log::ger::Output 'String' => (string => \$main::log);
use Log::ger::Level::trace;

{
    # remove all hooks first
    local @INC = grep { !ref } @INC;
    require Require::HookChain;
    Require::HookChain->import("log::logger");

    # then remove all Require::HookChainTest::* modules from %INC
    for (keys %INC) { delete $INC{$_} if m!^Require/HookChainTest/! }

    # now the tests ...

    require Require::HookChainTest::One;
    like($main::log, qr/\ARequire::HookChain::log::logger: Require-ing/m)

}

done_testing;

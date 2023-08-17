#!perl

use strict;
use warnings;
use Test::More 0.98;

{
    # remove all hooks first
    local @INC = grep { !ref } @INC;
    require Require::HookChain;
    Require::HookChain->import(-end=>1, "munge::prepend", '$main::foo=2;');

    # then remove all Require::HookChainTest::* modules from %INC
    for (keys %INC) { delete $INC{$_} if m!^Require/HookChainTest/! }

    # now the tests ...

    undef $main::foo;
    require Require::HookChainTest::One;
    is($main::foo, 2);
}

done_testing;

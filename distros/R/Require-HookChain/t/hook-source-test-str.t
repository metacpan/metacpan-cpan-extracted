#!perl

use strict;
use warnings;
use Test::More 0.98;

{
    # remove all hooks first
    local @INC = grep { !ref } @INC;
    require Require::HookChain;
    Require::HookChain->import("source::test::str", '$main::foo=2;');

    # then remove Foo from %INC
    for (keys %INC) { delete $INC{$_} if m!^Foo\.pm$! }

    # now the tests ...

    undef $main::foo;
    require Foo;
    is_deeply($main::foo, 2);

}

done_testing;

#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;

note "Can Mite find the compiled code"; {
    local @INC = ("t/Mite-Shim/lib", @INC);
    require_ok 'Foo';

    my $obj = new_ok "Foo";
    is $obj->thing, 23;
}

done_testing;

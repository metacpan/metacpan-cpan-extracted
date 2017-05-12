#!perl -w
use strict;
use Test;
BEGIN { plan tests => 1 }

# test enough of the Stevens lib is working

my $foo;
open FOO, "t/stevens.plx";
while(<FOO>) {
    $foo .= "child: $_";
}

ok(`$^X t/stevens.plx`, $foo);

#!perl -T

use strict;
use warnings;
use Test::More tests => 2;

package SubCallerCheck;

use Sub::Called;
use Test::More;

sub test {
    ok( !Sub::Called::with_ampersand() );
}

sub test2 {
    ok( Sub::Called::with_ampersand() );
}

package main;

SubCallerCheck::test();
&SubCallerCheck::test2();

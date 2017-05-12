#!perl -T

use strict;
use warnings;
use Test::More tests => 6;
use Sub::Called;

test();
&test2;
&test2();

agent();

sub agent {
    test();
    &test2();
    &test2;
}

sub test {
    ok( !Sub::Called::with_ampersand() );
}

sub test2{
    ok( Sub::Called::with_ampersand() );
}
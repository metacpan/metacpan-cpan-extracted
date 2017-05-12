#!perl -T

use Sub::Called;
use Test::More tests => 2;

test();
&test2();

sub test {
    ok( !Sub::Called::with_ampersand() );
}

sub test2 {
    ok( Sub::Called::with_ampersand() );
}
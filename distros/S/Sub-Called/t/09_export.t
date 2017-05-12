#!perl -T

use Sub::Called qw(with_ampersand);
use Test::More tests => 2;

test();
&test2();

sub test {
    ok( !with_ampersand() );
}

sub test2 {
    ok( with_ampersand() );
}
#!perl -T

use strict;
use warnings;
use Test::More tests => 3;

package SubCallerCheck;

use Sub::Called;
use Test::More;

sub test {
    ok( !Sub::Called::with_ampersand() );
}

sub test2 {
    ok( !Sub::Called::with_ampersand() );
}

package main;

my $sub = SubCallerCheck->can( 'test' );
if( $sub ){
    $sub->();
}

my $sub2 = SubCallerCheck->can( 'test2' );
if( $sub2 ){
    &$sub2;
    &$sub2();
}
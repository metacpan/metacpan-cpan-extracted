#!perl -T

use strict;
use warnings;
use Sub::Called;
use Test::More tests => 6;

sub test2 {
    ok( Sub::Called::with_ampersand() );
}

sub test {
    ok( !Sub::Called::with_ampersand() );
}


my $loc_test = main->can( 'test' );
$loc_test->();

my $test  = sub { ok( !Sub::Called::with_ampersand() ); };

$test->();

TODO: {
    local $TODO = "There are some problems with subroutine references";

    my $loc_test2 = main->can( 'test2' );
    &$loc_test2;
    
    my $loc_test3 = main->can( 'test2' );
    &$loc_test3();
    
    &$test();
    &$test;
}
#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'OO::InsideOut' ) || print "Bail out!\n";
}

diag( "Testing OO::InsideOut $OO::InsideOut::VERSION, Perl $], $^X" );

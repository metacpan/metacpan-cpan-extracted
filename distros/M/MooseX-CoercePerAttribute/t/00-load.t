#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'MooseX::CoercePerAttribute' ) || print "Bail out!\n";
}

diag( "Testing MooseX::CoercePerAttribute $MooseX::CoercePerAttribute::VERSION, Perl $], $^X" );

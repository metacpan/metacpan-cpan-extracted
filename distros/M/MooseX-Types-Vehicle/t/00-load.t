#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'MooseX::Types::Vehicle' ) || print "Bail out!\n";
}

diag( "Testing MooseX::Types::Vehicle $MooseX::Types::Vehicle::VERSION, Perl $], $^X" );

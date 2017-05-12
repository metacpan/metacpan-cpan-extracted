#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::EC2::Tiny' ) || print "Bail out!\n";
}

diag( "Testing Net::EC2::Tiny $Net::EC2::Tiny::VERSION, Perl $], $^X" );

#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::API::Gett' ) || print "Bail out!\n";
}

diag( "Testing Net::API::Gett $Net::API::Gett::VERSION, Perl $], $^X" );

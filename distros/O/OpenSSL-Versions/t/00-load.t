#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'OpenSSL::Versions' ) || print "Bail out!\n";
}

diag( "Testing OpenSSL::Versions $OpenSSL::Versions::VERSION, Perl $], $^X" );

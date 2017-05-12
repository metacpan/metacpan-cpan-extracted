#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'OpenTok::API' ) || print "Bail out!\n";
}

diag( "Testing OpenTok::API $OpenTok::API::VERSION, Perl $], $^X" );

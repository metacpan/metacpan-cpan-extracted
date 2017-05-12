#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Plack::Middleware::IPMatch' ) || print "Bail out!\n";
}

diag( "Testing Plack::Middleware::IPMatch $Plack::Middleware::IPMatch::VERSION, Perl $], $^X" );

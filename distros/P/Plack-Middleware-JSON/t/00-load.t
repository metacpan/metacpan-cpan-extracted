#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Plack::Middleware::JSON' ) || print "Bail out!\n";
}

diag( "Testing Plack::Middleware::JSON $Plack::Middleware::IPMatch::VERSION, Perl $], $^X" );

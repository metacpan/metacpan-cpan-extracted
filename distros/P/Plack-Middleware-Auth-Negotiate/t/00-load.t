#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Plack::Middleware::Auth::Negotiate' ) || print "Bail out!\n";
}

diag( "Testing Plack::Middleware::Auth::Negotiate $Plack::Middleware::Auth::Negotiate::VERSION, Perl $], $^X" );

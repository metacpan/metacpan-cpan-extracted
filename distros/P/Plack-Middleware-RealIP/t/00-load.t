#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Plack::Middleware::RealIP' ) || print "Bail out!\n";
}

diag( "Testing Plack::Middleware::RealIP $Plack::Middleware::RealIP::VERSION, Perl $], $^X" );

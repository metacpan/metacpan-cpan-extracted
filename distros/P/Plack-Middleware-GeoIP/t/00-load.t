#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Plack::Middleware::GeoIP' ) || print "Bail out!\n";
}

diag( "Testing Plack::Middleware::GeoIP $Plack::Middleware::GeoIP::VERSION, Perl $], $^X" );

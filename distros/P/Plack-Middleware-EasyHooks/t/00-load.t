#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Plack::Middleware::EasyHooks' ) || print "Bail out!\n";
}

diag( "Testing Plack::Middleware::EasyHooks $Plack::Middleware::EasyHooks::VERSION, Perl $], $^X" );

#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Plack::Middleware::Options' ) || print "Bail out!
";
}

diag( "Testing Plack::Middleware::Options $Plack::Middleware::Options::VERSION, Perl $], $^X" );

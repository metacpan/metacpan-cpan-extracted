#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Plack::Middleware::DetectMobileBrowsers' ) || print "Bail out!";
}

diag( "Testing Plack::Middleware::DetectMobileBrowsers $Plack::Middleware::DetectMobileBrowsers::VERSION, Perl $], $^X" );

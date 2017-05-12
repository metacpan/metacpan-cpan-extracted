#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Plack::Middleware::PyeLogger' ) || print "Bail out!\n";
}

diag( "Testing Plack::Middleware::PyeLogger $Plack::Middleware::PyeLogger::VERSION, Perl $], $^X" );

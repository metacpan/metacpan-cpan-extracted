#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'Plack::App::MCCS' ) || print "Bail out!\n";
	use_ok( 'Plack::Middleware::MCCS' ) || print "Bail out!\n";
}

diag( "Testing Plack::App::MCCS $Plack::App::MCCS::VERSION, Perl $], $^X" );

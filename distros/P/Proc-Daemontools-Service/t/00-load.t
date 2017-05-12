#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Proc::Daemontools::Service' );
}

diag( "Testing Proc::Daemontools::Service $Proc::Daemontools::Service::VERSION, Perl $], $^X" );

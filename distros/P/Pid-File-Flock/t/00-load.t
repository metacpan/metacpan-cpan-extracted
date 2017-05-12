#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Pid::File::Flock' );
}

diag( "Testing Pid::File::Flock $Pid::File::Flock::VERSION, Perl $], $^X" );


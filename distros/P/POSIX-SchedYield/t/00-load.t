#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'POSIX::SchedYield' );
}

diag( "Testing POSIX::SchedYield $POSIX::SchedYield::VERSION, Perl $], $^X" );

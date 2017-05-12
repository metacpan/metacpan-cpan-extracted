#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'SMS::Send::DistributeSMS' );
}

diag( "Testing SMS::Send::DistributeSMS $SMS::Send::DistributeSMS::VERSION, Perl $], $^X" );

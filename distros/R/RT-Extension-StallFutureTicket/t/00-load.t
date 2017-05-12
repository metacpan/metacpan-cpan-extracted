#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'RT::Extension::StallFutureTicket' );
}

diag( "Testing RT::Extension::StallFutureTicket $RT::Extension::StallFutureTicket::VERSION, Perl $], $^X" );

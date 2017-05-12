#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Nagios::Plugin::POP3' );
}

diag( "Testing Nagios::Plugin::POP3 $Nagios::Plugin::POP3::VERSION, Perl $], $^X" );

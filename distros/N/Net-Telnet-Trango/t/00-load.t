#!perl -T
# $RedRiver: 00-load.t,v 1.1 2007/02/05 18:10:55 andrew Exp $

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::Telnet::Trango' );
}

diag( "Testing Net::Telnet::Trango $Net::Telnet::Trango::VERSION, Perl $], $^X" );

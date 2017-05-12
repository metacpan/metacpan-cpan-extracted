#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Parse::Syslog::Line' );
}

diag( "Testing Parse::Syslog::Line $Parse::Syslog::Line::VERSION, Perl $], $^X" );

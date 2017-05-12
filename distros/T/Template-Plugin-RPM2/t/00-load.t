#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Template::Plugin::RPM2' );
}

diag( "Testing Template::Plugin::RPM2 $Template::Plugin::RPM2::VERSION, Perl $], $^X" );

#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Template::Plugin::ByDate' );
}

diag( "Testing Template::Plugin::ByDate $Template::Plugin::ByDate::VERSION, Perl $], $^X" );

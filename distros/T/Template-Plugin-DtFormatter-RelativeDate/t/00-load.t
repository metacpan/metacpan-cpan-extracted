#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Template::Plugin::DtFormatter::RelativeDate' );
}

diag( "Testing Template::Plugin::DtFormatter::RelativeDate $Template::Plugin::DtFormatter::RelativeDate::VERSION, Perl $], $^X" );

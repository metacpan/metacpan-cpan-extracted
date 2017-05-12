#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Template::Plugin::DumbQuotes' );
}

diag( "Testing Template::Plugin::DumbQuotes $Template::Plugin::DumbQuotes::VERSION, Perl $], $^X" );

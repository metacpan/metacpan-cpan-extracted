#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Template::Plugin::Text::Filter::URI' );
}

diag( "Testing Template::Plugin::Text::Filter::URI $Template::Plugin::Text::Filter::URI::VERSION, Perl $], $^X" );

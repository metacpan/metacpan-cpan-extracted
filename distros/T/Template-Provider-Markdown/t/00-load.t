#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Template::Provider::Markdown' );
}

diag( "Testing Template::Provider::Markdown $Template::Provider::Markdown::VERSION, Perl $], $^X" );

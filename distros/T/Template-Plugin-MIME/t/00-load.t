#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Template::Plugin::MIME' );
}

diag( "Testing Template::Plugin::MIME $Template::Plugin::MIME::VERSION, Perl $], $^X" );

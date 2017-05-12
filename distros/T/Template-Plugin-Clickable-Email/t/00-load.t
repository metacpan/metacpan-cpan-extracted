#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Template::Plugin::Clickable::Email' );
}

diag( "Testing Template::Plugin::Clickable::Email $Template::Plugin::Clickable::Email::VERSION, Perl $], $^X" );

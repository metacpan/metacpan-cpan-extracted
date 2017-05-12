#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Template::Plugin::DisableForm' );
}

diag( "Testing Template::Plugin::DisableForm $Template::Plugin::DisableForm::VERSION, Perl $], $^X" );

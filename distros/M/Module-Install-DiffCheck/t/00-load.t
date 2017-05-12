#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Module::Install::DiffCheck' );
}

diag( "Testing Module::Install::DiffCheck $Module::Install::DiffCheck::VERSION, Perl $], $^X" );

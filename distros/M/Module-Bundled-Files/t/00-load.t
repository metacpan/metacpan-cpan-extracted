#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Module::Bundled::Files' );
}

diag( "Testing Module::Bundled::Files $Module::Bundled::Files::VERSION, Perl $], $^X" );

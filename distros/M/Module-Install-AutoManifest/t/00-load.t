#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Module::Install::AutoManifest' );
}

diag( "Testing Module::Install::AutoManifest $Module::Install::AutoManifest::VERSION, Perl $], $^X" );

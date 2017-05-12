#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Rose::DBx::RegistryConfig' );
}

diag( "Testing Rose::DBx::RegistryConfig $Rose::DBx::RegistryConfig::VERSION, Perl $], $^X" );

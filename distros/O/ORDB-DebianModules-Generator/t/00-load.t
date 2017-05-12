#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'ORDB::DebianModules::Generator' );
}

diag( "Testing ORDB::DebianModules::Generator $ORDB::DebianModules::Generator::VERSION, Perl $], $^X" );

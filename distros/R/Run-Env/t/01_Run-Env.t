#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Run::Env' );
}

diag( "Testing Run::Env $Run::Env::VERSION, Perl $], $^X" );

#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Scope::OnExit' );
}

diag( "Testing Scope::OnExit $Scope::OnExit::VERSION, Perl $], $^X" );

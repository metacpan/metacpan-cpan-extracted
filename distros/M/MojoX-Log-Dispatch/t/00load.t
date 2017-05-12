#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'MojoX::Log::Dispatch' );
}

diag( "Testing MojoX::Log::Dispatch $MojoX::Log::Dispatch::VERSION, Perl $], $^X" );

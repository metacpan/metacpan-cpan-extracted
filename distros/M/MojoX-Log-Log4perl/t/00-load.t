#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'MojoX::Log::Log4perl' );
}

diag( "Testing MojoX::Log::Log4perl $MojoX::Log::Log4perl::VERSION, Perl $], $^X" );

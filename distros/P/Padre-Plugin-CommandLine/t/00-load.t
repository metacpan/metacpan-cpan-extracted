#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Padre::Plugin::CommandLine' );
}

diag( "Testing Padre::Plugin::CommandLine $Padre::Plugin::CommandLine::VERSION, Perl $], $^X" );

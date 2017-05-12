#!perl

use Test::More tests => 3;

BEGIN {
	use_ok( 'Padre::Plugin::XML' );
	use_ok( 'Padre::Plugin::XML::Document' );
	use_ok( 'Padre::Task::SyntaxChecker::XML' );
}

diag( "Testing Padre::Plugin::XML $Padre::Plugin::XML::VERSION, Perl $], $^X" );

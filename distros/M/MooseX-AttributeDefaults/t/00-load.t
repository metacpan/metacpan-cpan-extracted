#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'MooseX::AttributeDefaults' );
}

diag( "Testing MooseX::AttributeDefaults $MooseX::AttributeDefaults::VERSION, Perl $], $^X" );

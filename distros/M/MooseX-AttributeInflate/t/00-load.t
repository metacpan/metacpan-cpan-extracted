#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'MooseX::AttributeInflate' );
}

diag( "Testing MooseX::AttributeInflate $MooseX::AttributeInflate::VERSION, Perl $], $^X" );

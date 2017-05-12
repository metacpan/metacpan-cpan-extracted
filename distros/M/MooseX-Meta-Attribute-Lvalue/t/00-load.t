#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'MooseX::Meta::Attribute::Lvalue' );
}

diag( "Testing MooseX::Meta::Attribute::Lvalue $MooseX::Meta::Attribute::Lvalue::VERSION, Perl $], $^X" );

#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'MooseX::Meta::Attribute::Index' );
}

diag( "Testing MooseX::Meta::Attribute::Index $MooseX::Meta::Attribute::Index::VERSION, Perl $], $^X" );

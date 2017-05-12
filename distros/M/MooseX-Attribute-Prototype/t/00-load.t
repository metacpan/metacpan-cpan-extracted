use strict;
use warnings;


use Test::More tests => 2;
# diag( "Testing MooseX::Attribute $MooseX::Attribute::VERSION, Perl $], $^X" );

package Foo;

	::use_ok( 'Moose' );
	::use_ok( 'MooseX::Attribute::Prototype' );



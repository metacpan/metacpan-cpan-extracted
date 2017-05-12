#!perl -w

use strict;
use Test::More tests => 10;

BEGIN{
	package X;
	use Sub::Attribute;
	use Test::More;

	sub C :ATTR_SUB{
		my($class, $sym, $code, $name, $data) = @_;
		ok($class->isa('X'), "handler $name called");
		is ref($sym), 'GLOB', 'sym';
		is ref($code), 'CODE', 'code';
		is $name, 'C', 'name';

		no warnings 'redefine';
		*{$sym} = sub{ $data };
	}

	$INC{'X.pm'}++;
}

use parent -norequire => qw(X);

sub foo :C(10){ 42 }
sub bar :C("20");


is foo(), 10, 'foo() redefined';
is bar(), q{"20"}, 'bar() redefined';

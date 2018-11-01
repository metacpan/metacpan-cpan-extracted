#!perl -w

use strict;
use Test::More tests => 6;

BEGIN{
	package X;
	use Sub::Attribute;
	use Test::More;

	sub C :ATTR_SUB{
		my($class, $sym, $code, $name, $data) = @_;
		ok($class->isa('X'), "handler $name called");
		is $sym, undef;
		is ref($code), 'CODE';
		is $name, 'C';
		is $data, 20;
	}

	$INC{'X.pm'}++;
}

use parent -norequire => qw(X);

my $x = sub :C(20){ 42 };
is $x->(), 42;

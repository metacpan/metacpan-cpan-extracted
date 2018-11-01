#!perl -w

use strict;
use Test::More tests => 4;

BEGIN{
	package X;
	use Sub::Attribute;
	use Test::More;

	sub C :ATTR_SUB{
		my($class, $sym, $code, $name, $data) = @_;

		*{$sym} = sub{ $data };
	}

	$INC{'X.pm'}++;
}

use parent -norequire => qw(X);

eval q{
	sub foo :C(10);
	sub bar :C(x);
};

ok defined(&foo), 'attributes in eval';
is scalar(eval{ foo() }), 10;

ok defined(&bar), 'attributes in eval';
is scalar(eval{ bar() }), 'x';

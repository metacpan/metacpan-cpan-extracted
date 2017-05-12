#!perl -w

use strict;
use Test::More tests => 6;

BEGIN{
	package X;
	use Sub::Attribute;
	use Test::More;

	sub C :ATTR_SUB{
		my($class, $sym, $code, $name, $data) = @_;

		no warnings 'redefine';
		*{$sym} = sub{ $data };
	}

	$INC{'X.pm'}++;
}

BEGIN{
	package Other;
	use Test::More;
	use parent -norequire => qw(X);

	sub foo :C(10){ 42 }

	is foo(), 10;

	$INC{'Other.pm'}++;
}

eval q{
	sub foo :C(20);
};
like $@, qr/Invalid CODE attribute/;

eval q{
	use parent -norequire => qw(Other);
	sub foo :C(30);
};
is $@, '';

ok defined(&foo);

{
	package XYZ;
	use Sub::Attribute;
	use Test::More;

	sub D{}

	eval q{sub foo :C(10)};
	like $@, qr/Invalid CODE attribute/;

	eval q{sub foo :D};
	like $@, qr/Invalid CODE attribute/;
}

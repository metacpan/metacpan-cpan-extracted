#!perl -w

use strict;
use Test::More tests => 4;

BEGIN{
	package X;
	use Sub::Attribute;
	use Test::More;

	sub C :ATTR_SUB{
		my($class, $sym, $code, $name, $data) = @_;

		is $name, 'C', ':C applied';
	}

	$INC{'X.pm'}++;

	package Y;
	use Sub::Attribute;
	use Test::More;

	sub D :ATTR_SUB{
		my($class, $sym, $code, $name, $data) = @_;

		is $name, 'D', ':D applied';
	}

	$INC{'Y.pm'}++;
}
BEGIN{
	package Z;
	use Test::More;
	use Sub::Attribute;
	use parent -norequire => qw(X Y);

	BEGIN{ require MRO::Compat if $] < 5.010_000 }

	use mro 'c3';

	sub E :ATTR_SUB{
		my($class, $sym, $code, $name, $data) = @_;

		is $name, 'E', ':E applied';
	}
	$INC{'Z.pm'}++;
}

use parent -norequire => qw(Z);

sub foo :C :D :E { 42 }

is foo(), 42;

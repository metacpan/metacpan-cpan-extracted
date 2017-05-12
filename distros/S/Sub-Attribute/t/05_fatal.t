#!perl -w

use strict;
use Test::More tests => 2;

BEGIN{
	package X;
	use Sub::Attribute;

	sub C :ATTR_SUB{
	}

	$INC{'X.pm'}++;
}

use parent -norequire => qw(X);
no warnings 'void';

eval q{
	sub a :C :X;
};
like $@, qr/Invalid CODE attribute/;

eval q{
	sub a :X :C;
};
like $@, qr/Invalid CODE attribute/;

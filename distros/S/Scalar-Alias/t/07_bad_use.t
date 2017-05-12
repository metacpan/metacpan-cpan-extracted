#!perl -w

use strict;
use Test::More tests => 6;

use Scalar::Alias;

{
	package no_alias;
};

eval q{
	my alias $x;
};
like $@, qr/Cannot declare lexical alias \$x without assignment/;

eval q{
	my alias $x->{foo} = 10;
};
like $@, qr/Cannot declare lexical alias \$x with dereference/;

eval q{
	my alias $x = 10;
	$x++;
};
like $@, qr/read-only/;


eval q{
	our alias $x = 10;
};
like $@, qr/Cannot declare lexical alias \$x with our statement/;

eval q{
	my no_alias $x;
};
is $@, '';

eval q{
	our no_alias $x;
};
is $@, '';

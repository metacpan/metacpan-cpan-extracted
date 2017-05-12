#!perl -w
use strict;

use Test::More tests => 2;

use Tie::Scalar;

use Scalar::Util::Instance
    { for => 'Foo', as => 'is_a_Foo' };

BEGIN{
	package Foo;
	sub new{
		bless {} => shift;
	}
}

my $obj = tie my($x), 'Tie::StdScalar', Foo->new;

ok is_a_Foo($x);

$$obj = 'Foo';
ok!is_a_Foo($x);


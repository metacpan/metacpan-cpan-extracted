#!perl
use strict;
use warnings;
use Ruby -all;

{
	package Foo;
	use Ruby -base => 'String';

	sub foo{
		__CLASS__;
	}
}

p(Foo->new->foo);


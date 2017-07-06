#!perl -w
use strict;
use FindBin qw($Bin);
use lib "$Bin/lib";

BEGIN{
	package Foo;
	use parent qw(Attribute::Abstract);

	sub bar :Abstract;
}


use Class::Inspector;
use Data::Dumper;
print Dumper(Class::Inspector->methods('Foo'));
print Dumper(Class::Inspector->methods('UNIVERSAL'));

Foo->bar();

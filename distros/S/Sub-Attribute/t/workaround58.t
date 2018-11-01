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

my $x;
sub foo :C :lvalue { $x }
sub bar :lvalue :C { $x }

foo() = 42;
is $x, 42, 'with built-in attributes';

bar() = 99;
is $x, 99, 'with built-in attributes';

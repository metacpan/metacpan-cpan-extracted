#!perl -w

use strict;
use Test::More tests => 6;

use Scalar::Alias;

{
	my($x, $y) = (10, 20);
	(my alias $z, $x, $y) = ($x, $y, $x);

	$x++;
	is $x, 21, '$x';
	is $y, 10, '$y';
	is $z, 21, '$z';
}

{
	my($x, $y) = (10, 20);
	($x, $y, my alias $z) = ($y, $x, $x);

	$x++;
	is $x, 21, '$x';
	is $y, 10, '$y';
	is $z, 21, '$z';
}

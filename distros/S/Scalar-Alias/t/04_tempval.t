#!perl -w

use strict;
use Test::More tests => 4;

use Scalar::Alias;

my $x       = 10;
my alias $y = $x + 10;
my alias $z = $y + 10;

is $x, 10;
is $y, 20;
is $z, 30;

sub f{
	return 42;
}

my alias $tmp = f();
is $tmp, 42;

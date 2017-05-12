#!perl -w

use strict;
use Test::More tests => 6;

use Scalar::Alias;

{
	package no_alias;
}

sub inc{
	my alias $x = shift;
	$x++;
	return;
}

sub inc_noalias{
	my no_alias $x = shift;
	$x++;
	return;
}

my $i = 0;
my $j = 10;
inc($i);
inc($j);
is $i, 1;
is $j, 11;

inc($i);
inc($j);

is $i, 2;
is $j, 12;

inc_noalias($i);
inc_noalias($j);

is $i, 2;
is $j, 12;

#!perl -w

use strict;
use Test::More tests => 26;

use Scalar::Alias;

{
	package no_alias;
}

sub inc{
	my alias($x, $y, $z)= @_;
	$x++;
	$y++;
	$z++;
	return;
}


my $i = 0;
my $j = 10;
my $k = 20;
inc($i, $j, $k);
is $i, 1;
is $j, 11;
is $k, 21;

inc($i, $j, $k);

is $i, 2;
is $j, 12;
is $k, 22;

my alias($a) = ($i);
my alias($b) = ($j);
my alias($c) = ($k);

$a++;
$b++;
$c++;

is $i, 3;
is $j, 13;
is $k, 23;

my alias($x, undef, $y, undef, $z) = ($a, undef, $b, undef, $c);

$x++;
$y++;
$z++;

is $i, 4;
is $j, 14;
is $k, 24;

{
	(my alias $x) = $i;
	$x++;
	is $i, 5;
}

{
	(undef, my alias $x) = (undef, $i);
	$x++;
	is $i, 6;
}

{
	(undef, my no_alias $x, my alias $y) = (undef, $j, $i);
	$x++;
	$y++;

	is $i, 7;
	is $j, 14; # not changed
	is $x, 15;
}

{
	my %h;
	$h{foo} = 42;

	my alias($x) = $h{bar};

	is_deeply \%h, {foo => 42};

	$x = 10;

	is_deeply \%h, {foo => 42, bar => 10};
}

{
	my $s       = 'foo';
	my alias($x) = substr($s, 0, 1);
	is $x, 'f';
	$x = 'F';

	is $x, 'F';
	is $s, 'Foo';
}

{
	my $x = 10;
	(my alias $y, my @a) = ($x, 1 .. 10);

	$x++;

	is $y, 11;
	is_deeply \@a, [1 .. 10];
}

{
	my $x = 10;
	(my alias $y, my %h) = ($x, foo => 10, bar => 20);

	$x++;

	is $y, 11;
	is_deeply \%h, {foo => 10, bar => 20};
}


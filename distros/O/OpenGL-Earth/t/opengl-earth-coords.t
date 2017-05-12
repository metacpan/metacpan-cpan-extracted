#!/usr/bin/perl

use Test::More;

sub is_approx ($$;$) {
	my ($f1, $f2, $reason) = @_;
	ok (abs($f1 - $f2) < 0.00000001, $reason);
}

plan tests => 10;

use_ok('OpenGL::Earth::Coords');

my $x;
my $y;
my $z;

($x, $y, $z) = OpenGL::Earth::Coords::earth_to_xyz(90, 0, 1);
is_approx($x, 0, 'North pole x');
is_approx($y, 0, 'North pole y');
is_approx($z, 1, 'North pole z');

($x, $y, $z) = OpenGL::Earth::Coords::earth_to_xyz(-90, 0, 1);
is_approx($x, 0,  'South pole x');
is_approx($y, 0,  'South pole y');
is_approx($z, -1, 'South pole z');

($x, $y, $z) = OpenGL::Earth::Coords::earth_to_xyz(0, 0, 1);
is_approx($x, 1,  'Greenwith meridian at equator (x)');
is_approx($y, 0,  'Greenwith meridian at equator (y)');
is_approx($z, 0,  'Greenwith meridian at equator (z)');


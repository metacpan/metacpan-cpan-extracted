use Test::More;

use lib 't/lib';

use Point::Extend;

my $point = Point::Extend->new();

is($point->x, 0);
is($point->y, 0);
is($point->describe, "A point at (0, 0)\n");
is($point->stringify, "A point at (0, 0)\n");

my $point = Point::Extend->new(
	x => 100,
	y => 200
);

is($point->x, 100);
is($point->y, 200);
is($point->describe, "A point at (100, 200)\n");
is($point->stringify, "A point at (100, 200)\n");



done_testing;

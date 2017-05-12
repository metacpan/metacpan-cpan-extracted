# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Shape-RegularPolygon.t'

#########################

use Test::More tests => 15;
BEGIN { use_ok('Shape::RegularPolygon') };

#########################

#
# construction
#
$polygon = new Shape::RegularPolygon;

# Reading default value
($x, $y) = $polygon->center;
ok($x == 0 && $y == 0,     "Read Property: center");
ok($polygon->sides == 3,   "Read Property: sides");
ok($polygon->radius == 50, "Read Property: radius");
ok($polygon->angle == 0.0, "Read Property: angle");

# Writing property
$polygon->center(100, 200);
$polygon->sides(5);
$polygon->radius(100);
$polygon->angle(3.14);
($x, $y) = $polygon->center;
ok($x == 100 && $y == 200,  "Write Property: center");
ok($polygon->sides == 5,    "Write Property: sides");
ok($polygon->radius == 100, "Write Property: radius");
ok($polygon->angle == 3.14, "Write Property: angle");


# By named parameter
$polygon = new Shape::RegularPolygon(CenterX => 100,
                                     CenterY =>  50,
                                     Sides => 4,
                                     Radius => 100,
                                     Angle => 3.14);
($x, $y) = $polygon->center;
ok($x == 100 && $y == 50,   "Named parameter: center");
ok($polygon->sides == 4,    "Named parameter: sides");
ok($polygon->radius == 100, "Named parameter: radius");
ok($polygon->angle == 3.14, "Named parameter: angle");

# get vertexes
$polygon = new Shape::RegularPolygon;
$polygon->center(100, 200);
$polygon->sides(5);
$polygon->radius(100);
$polygon->angle(3.14);
@p = $polygon->points;

$polygon2 = new Shape::RegularPolygon(CenterX => 100,
                                      CenterY => 200,
	                              Sides => 5,
                                      Radius => 100,
                                      Angle => 3.14);
@p2 = $polygon2->points;

ok(@p == 5 && @p2 == 5, "Vertex num");

$err = 0;
for (my $i = 0 ; $i < @p ; $i++) {
    if ($p[$i]->{x} != $p2[$i]->{x} || $p[$i]->{y} != $p2[$i]->{y}) {
        $err = 1;
        last;
    }
}
ok(!$err, "Vertexes");

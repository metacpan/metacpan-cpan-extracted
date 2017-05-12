use strict;

use Test::More tests => 4;

use Set::Intersection;

my @r = get_intersection([1 .. 9], [map { $_ * 2 } 1 .. 3], [map { $_ * 3 } 1 .. 3]);
is scalar(@r), 1,
    "Got expected number of elements in intersection of three sets";
is $r[0], 6,
    "Got expected element in intersection of three sets";

@r = get_intersection({-preordered=>1}, [1 .. 9], [map { $_ * 2 } 1 .. 3], [map { $_ * 3 } 1 .. 3]);
is scalar(@r), 1,
    "Use of -preordered option did not affect number of elements in intersection";
is $r[0], 6,
    "Use of -preordered option did not affect content of intersection";



# Where's Oslo on a 3D Sphere of radius 1.0?
use OpenGL::Earth::Coords;
my ($x, $y, $z) = OpenGL::Earth::Coords::earth_to_xyz(59.9167, 10.75, 1.0);
printf "x=%.3f y=%.3f z=%.3f\n", $x, $y, $z;


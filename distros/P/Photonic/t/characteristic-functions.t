use strict;
use warnings;
use PDL;
use Photonic::CharacteristicFunctions qw(triangle isosceles ellipse);
use Test::More tests => 1+1+1;
TRIANGLE: {
     my ($N, $r0, $deltar, $theta0)=(101, 0.5, 0.2, 0.1);
     my $b=triangle($N, $r0, $deltar, $theta0);
     ok(defined $b, "Triangle");
}
 ELLIPSE: {
     my ($N, $ff, $ecc) = (101, 0.25, 0.5);
     my $e=ellipse($N, $ff, $ecc);
     ok(defined $e, "Triangle");
}
 ISOSCELES: {
     my ($N, $r0, $delta2,$delta3, $theta0)=(101, 0.5, 0.1, 0.2, 0.1);
     my $i=isosceles($N, $r0, $delta2, $delta3, $theta0);
     ok(defined $i, "Isosceles");
}



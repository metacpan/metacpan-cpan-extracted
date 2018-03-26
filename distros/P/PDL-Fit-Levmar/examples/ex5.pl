#!/usr/bin/perl
use PDL;
use PDL::Fit::Levmar;

$defst = "
    function modros
    noloop
    x0 = 10 * (p1 -p0*p0);
    x1 = 1.0 - p0;
    x2 = 100;
    jacobian jacmodros
    noloop
    d0[0] = -20 * p0;
    d1[0] = 10;
    d0[1] = -1;
    d1[1] = 0;
    d0[2] = 0;
    d1[2] = 0;
  ";

$p = pdl [-1.2, 1];
$x = pdl [0,0,0];   
$h = levmar( $p,$x, FUNC => $defst );
print levmar_report($h);

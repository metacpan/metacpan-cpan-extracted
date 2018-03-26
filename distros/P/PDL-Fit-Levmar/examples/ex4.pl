#!/usr/bin/perl

use PDL;
use PDL::Fit::Levmar;

$n = 100;
$t = 10 * (sequence($n)/$n -1/2);
$x = 3 * exp(-$t*$t * .3  );
$p = pdl [ 1, 1 ]; # initial  parameter guesses

$st = '
   function
   x = p0 * exp( -t*t * p1);

   jacobian
   FLOAT ex, arg;
   loop
   arg = -t*t * p1;
   ex = exp(arg);
   d0 = ex;
   d1 = -p0 * t*t * ex ;

 ';

$h = levmar($p,$x,$t, FUNC => $st);
print levmar_report($h);

#!/usr/bin/perl

use PDL;
use PDL::Fit::Levmar;

$n = 100;
$t = 10 * (sequence($n)/$n -1/2);
$x = 3 * exp(-$t*$t * .3  );
$p = pdl [ 1, 1 ]; # initial  parameter guesses

#$export =  $^O =~ /MSWin32/i ? '__declspec (dllexport)' :  '';

$h = levmar($p,$x,$t, FUNC => "
#include <math.h>
void gaussian(FLOAT *p, FLOAT *x, int m, int n, FLOAT *t)
{
 int i;
 for(i=0; i<n; ++i)
          x[i] = p[0] * exp( -t[i]*t[i] * p[1]);
}
");
print levmar_report($h);

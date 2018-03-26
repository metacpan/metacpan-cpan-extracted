#!/usr/bin/perl
use PDL;
use PDL::Fit::Levmar;
use PDL::NiceSlice;

$st = '
   function
   x = p0 * exp( -t*t * p1);
  ';

$n = 10;
$t = 10 * (sequence($n)/$n -1/2);
$x = zeroes($n,4);
map {  $x(:,$_->[0])  .= $_->[1] * exp(-$t*$t * $_->[2]  ) } 
        ( [0,3,.2], [1, 28, .1] , [2,2,.01], [3,3,.3] );
$p = [ 5, 1];  # initial guess
$h = levmar($p,$x,$t, FUNC => $st );
print $h->{P} . "\n";

#!/usr/bin/perl

use PDL;
use PDL::Fit::Levmar;

$n = 100;
$t = 10 * (sequence($n)/$n -1/2);
$x = 3 * exp(-$t*$t * .3  );
$p = pdl [ 1, 1 ]; # initial  parameter guesses

 $h = levmar($p,$x,$t, FUNC => sub {
    my ($p,$x,$t) = @_;
    my ($p0,$p1)  = list $p;
    $x .= $p0 * exp(-$t*$t * $p1);
 });

print levmar_report($h);

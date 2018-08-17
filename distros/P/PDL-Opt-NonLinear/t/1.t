#!/usr/bin/perl
use PDL::LiteF;
use PDL::Opt::NonLinear;
use Test;

BEGIN { plan tests => 2 };

sub fapprox {
	my($a,$b) = @_;
	PDL::abs($a-$b)->max < 0.0001;
}

$res = pdl([1,1,1,1,1]);



$x = random(5);

$gx = rosen_grad($x);
$hx = rosen_hess($x);
$fx = rosen($x);
$xtol = pdl(1e-16);
$gtol = pdl(1e-8);
#$stepmx = pdl(0.5);
$maxit = pdl(long, 50);
sub min_func{
	my ($fx, $x) = @_;
	$fx .= rosen($x);
}
sub grad_func{
	my ($gx, $x) = @_;
	$gx .= rosen_grad($x);
}
sub hess_func{
	my ($hx, $x) = @_;
	$hx .= rosen_hess($x);
}
tensoropt($fx, $gx, $hx, $x, 
	  1,$maxit,15,1,2,1,
	  ones(5),0.5,$xtol,$gtol,2,6,
	  \&min_func, \&grad_func, \&hess_func);

ok(fapprox($x,$res));

$x = random(5);
$gx = rosen_grad($x);
$fx = rosen($x);
$diag = zeroes(5);

$xtol = pdl(1e-16);
$gtol = pdl(0.9);
$eps = pdl(1e-10);
$print = ones(2);
$maxfc = pdl(long,100);
$maxit = pdl(long,50);
$info = pdl(long,0);
$diagco= pdl(long,0);
$m = pdl(long,10);

sub fdiag{};
sub fg_func{
   my ($f, $g, $x) = @_;
   $f .= rosen($x);
   $g .= rosen_grad($x);
   return 0;
}
lbfgs($fx, $gx, $x, $diag, $diagco, $m, $maxit, $maxfc, $eps, $xtol, $gtol,
                       $print,$info,\&fg_func,\&fdiag);
ok(fapprox($x,$res));

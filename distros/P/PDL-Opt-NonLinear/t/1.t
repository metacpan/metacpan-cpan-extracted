use strict;
use warnings;
use PDL::LiteF;
use PDL::Opt::NonLinear;
use PDL::NiceSlice;
use Test::More;

sub approx_ok {
  my($got,$expected,$eps,$label) = @_;
  die "No eps" if !$eps or !$label;
  if (PDL::abs($got-$expected)->max < $eps) {
    pass $label;
  } else {
    fail $label;
    diag "got=$got\nexpected=$expected\n";
  }
}

my $res = ones(5);
my $x = pdl '[0.49823058 0.98093641 0.63151156 0.66477157 0.60801367]';

my $gx = rosen_grad($x);
my $hx = rosen_hess($x);
my $fx = rosen($x);
my $xtol = pdl(1e-16);
my $gtol = pdl(1e-8);
#$stepmx = pdl(0.5);
my $maxit = pdl(long, 50);
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

approx_ok $x,$res,0.001,'tensoropt';

$x = pdl '[0.49823058 0.98093641 0.63151156 0.66477157 0.60801367]';
$gx = rosen_grad($x);
$fx = rosen($x);
my $diag = zeroes(5);

$xtol = pdl(1e-16);
$gtol = pdl(0.9);
my $eps = pdl(1e-10);
my $print = ones(2);
my $maxfc = pdl(long,100);
$maxit = pdl(long,50);
my $info = pdl(long,0);
my $diagco= pdl(long,0);
my $m = pdl(long,10);

sub fdiag{};
sub fg_func{
   my ($f, $g, $x) = @_;
   $f .= rosen($x);
   $g .= rosen_grad($x);
   return 0;
}
lbfgs($fx, $gx, $x, $diag, $diagco, $m, $maxit, $maxfc, $eps, $xtol, $gtol,
                       $print,$info,\&fg_func,\&fdiag);
approx_ok $x,$res,0.0001,'lbfgs';

$x = pdl '[0.49823058 0.98093641 0.63151156 0.66477157 0.60801367]';
$gx = zeroes(5);
$fx = pdl(0);

my $bounds =  zeroes(5,2);
$bounds(,0).= -5;
$bounds(,1).= 5;
my $tbounds = zeroes(5);
$tbounds .= 2;
$gtol = pdl(0.9);
my $pgtol = pdl(1e-10);
my $factr = pdl(100);
$print = pdl(long, [0,0]);
$maxit = pdl(long,100);
$info = pdl(long,0);
$m = pdl(long,10);
my $iv = zeroes(long,44);
my $v = zeroes(29);

lbfgsb($fx, $gx, $x, $m, $bounds, $tbounds, $maxit, $factr, $pgtol, $gtol,
	$print, $info,$iv, $v,\&fg_func);
approx_ok $x,$res,0.0001,'lbfgsb';

$x = pdl '[0.49823058 0.98093641 0.63151156 0.66477157 0.60801367]';
$gx = rosen_grad($x);
$fx = rosen($x);
$print = zeroes(2);
$maxit = pdl(long, 200);
$info = pdl(long,0);
cgfam($fx, $gx, $x, $maxit, $eps, $xtol, $gtol,$print,$info,1,\&fg_func);
approx_ok $x,$res,0.0001,'cgfam';

$x = pdl '[0.49823058 0.98093641 0.63151156 0.66477157 0.60801367]';
$gx = $x->zeroes;
$fx = rosen($x);

my $accrcy = pdl(1e-16);
$xtol = pdl(1e-10);
my $stepmx =pdl(1);
my $eta =pdl(0.9);

$info = pdl(long, 0);
$print = pdl(long, 1);
$maxit = pdl(long, 50);
my $cgmaxit = pdl(long, 50);
$maxfc = pdl(long,250);
lmqn($fx, $gx, $x, $maxit, $maxfc, $cgmaxit, $xtol, $accrcy, $eta, $stepmx, $print, $info,\&fg_func);

done_testing;

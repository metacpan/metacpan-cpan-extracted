use strict;
use warnings;
use PDL::LiteF;
use Test::More;
use Test::PDL;
use PDL::Slatec;
use PDL::MatrixOps qw(identity);

kill 'INT', $$ if $ENV{UNDER_DEBUGGER}; # Useful for debugging.

my $mat = pdl [1,0.1],[0.1,2];

my ($eigvals,$eigvecs) = eigsys($mat);

## print STDERR $eigvecs,$eigvals,"\n";

is_pdl $eigvals,float(0.9901,2.009), {atol=>1e-3};
is_pdl $eigvecs,float([0.995,-0.0985],[0.0985,0.995]), {atol=>1e-3};

$mat = pdl [2,3],[4,5];

my $inv = matinv($mat);

my $uni=scalar $mat x $inv;
is_pdl $uni,identity(2);

eval {matinv(identity(2)->dummy(-1,2))};
is $@, '', 'matinv can broadcast';

my $det = $mat->det;
my $deti = $inv->det;

is_pdl $det, pdl(-2);
is_pdl $deti, pdl(-0.5);

# Now do the polynomial fitting tests

# Set up tests x, y and weight
my $y = pdl (1,4,9,16,25,36,49,64.35,32);
my $x = pdl ( 1,2,3,4,5,6,7,8,9);
my $w = pdl ( 1,1,1,1,1,1,1,0.5,0.3);

# input parameters
my $eps = pdl(0);
my $maxdeg = 5;

# Test with a bad value
$y->inplace->setbadat(3);
my ($ndeg, $r, $ierr, $a1) = polyfit($x, $y, $w, $maxdeg, $eps);

ok(($ierr == 1));

# Test with all bad values
$y = zeroes(9)->setbadif(1);
($ndeg, $r, $ierr, $a1) = polyfit($x, $y, $w, $maxdeg, $eps);
ok(($ierr == 2));

# Now test broadcasting over a 2 by N matrix
# Set up tests x, y and weight
$y = pdl ([1,4,9,16,25,36,49,64.35,32],
          [1,4,9,16,25,36,49,64.35,32],);
$x = pdl ([1,2,3,4,5,6,7,8,9],
          [1,2,3,4,5,6,7,8,9],);
$w = pdl ([1,1,1,1,1,1,1,0.5,0.3],
          [1,1,1,1,1,1,1,0.5,0.3],);
$y->inplace->setbadat(3,0);
$y->inplace->setbadat(4,1);
$eps = pdl(0,0);

($ndeg, $r, $ierr, $a1) = polyfit($x, $y, $w, $maxdeg, $eps);

## print STDERR "NDEG, EPS, IERR: $ndeg, $eps, $ierr\n";
## print STDERR "poly = $r\n";

ok((sum($ierr == 1) == 2));

# Set up tests x, y and weight
$x = pdl ( 1,2,3,4,5,6,7,8,9);
$y = pdl (1,4,9,16,25,36,49,64.35,32);
$w = pdl ( 1,1,1,1,1,1,1,0.5,0.3);
$maxdeg = 7;
$eps = pdl(0);

# Do the fit
($ndeg, $r, $ierr, $a1) = polyfit($x, $y, $w, $maxdeg, $eps);

ok(($ierr == 1));

# Test POLYCOEF                                                               
my $c = pdl(4);           # Expand about x = 4;

my $tc = polycoef($ndeg, $c, $a1);

my @tc = $tc->list;
my @r  = $r->list;
my $i = 0;

foreach my $xpos ($x->list) {
  my $ypos = 0;
  my $n = 0;
  foreach my $bit ($tc->list) {
    $ypos += $bit * ($xpos- (($c->list)[0]))**$n;
    $n++;
  }
  ## print STDERR "$xpos, $ypos, $r[$i]\n";

  # Compare with answers from polyfit
  ok(sprintf("%5.2f", $ypos) == sprintf("%5.2f", $r[$i]));
  $i++;                                                                       

}

# Try polyvalue with a single x pos
my $xx = pdl(4);
my $nder = 3;

my ($yfit, $yp) = polyvalue($ndeg, $nder, $xx, $a1);

ok(int($yp->at(0)) == 8);

# Test polyvalue
$nder = 3;
$xx    = pdl(12,4,6.25,1.5); # Ask for multiple positions at once

($yfit, $yp) = polyvalue($ndeg, $nder, $xx, $a1);

# Simple test of expected value                                               
ok(int($yfit->at(1)) == 15);            

my $A = identity(4) + ones(4, 4);
$A->slice('2,0') .= 0; # break symmetry to see if need transpose
my $B = sequence(2, 4);
gefa(my $lu=$A->copy, my $ipiv=null, my $info=null);
gesl($lu, $ipiv, $x=$B->transpose->copy, 1); # 1 = do transpose because Fortran
$x = $x->inplace->transpose;
my $got = $A x $x;
is_pdl $got, $B;

{
my $pa = pdl(float,1,-1,1,-1); # even number
my ($az, $x, $y) = PDL::Slatec::fft($pa);
is_pdl $az, float 0;
is_pdl $x, float "[0 1 0 0]";
is_pdl $y, float "[0 0 0 0]";
is_pdl PDL::Slatec::rfft($az, $x, $y), $pa;
$pa = pdl(float,1,-1,1,-1,1); # odd number
($az, $x, $y) = PDL::Slatec::fft($pa);
is_pdl $az, float 0.2;
is_pdl $x, float "[0.4 0.4 0 0 0]";
is_pdl $y, float "[-0.2906170 -1.231073 0 0 0]";
is_pdl PDL::Slatec::rfft($az, $x, $y), $pa;
}

done_testing;

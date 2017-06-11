# -*- Mode: CPerl -*-
# t/01_svd.t: test las2 svd
use Test::More tests => 28;

##-- common subs
my $TEST_DIR;
BEGIN {
  use File::Basename;
  use Cwd;
  $TEST_DIR = Cwd::abs_path dirname( __FILE__ );
  eval qq{use lib ("$TEST_DIR/$_/blib/lib","$TEST_DIR/$_/blib/arch");} foreach (qw(../.. ..));
  do "$TEST_DIR/common.plt" or  die("$0: failed to load $TEST_DIR/common.plt: $@");
}

##-- common modules
use PDL;
use PDL::SVDLIBC;

##---------------------------------------------------------------------
## setup
my $a = pdl(double,
	    [[10,0,0,0,-2,0,0],
	     [3,9,0,0,0,3,1],
	     [0,7,8,7,0,0,0],
	     [3,0,8,7,5,0,1],
	     [0,8,0,9,9,13,0],
	     [0,4,0,0,2,-1,1]]);

my $ptr=pdl(long,[0,3,7,9,12,16,19, 22]);
my $rowids=pdl(long,[0,1,3,1,2,4,5,2,3,2,3,4,0,3,4,5,1,4,5,1,3,5]);
my $nzvals=pdl(double,[10,3,3,9,7,8,4,8,8,7,7,9,-2,5,9,2,3,13,-1,1,1,1]);
my ($n,$m) = $a->dims;

##-- common pars
my $iters = pdl(long,14);
my $end   = pdl(double,[-1e-30,1e-30]);
my $kappa = pdl(double,1e-6);

##-- common subs
sub svdreduce {
  my ($u,$s,$v, $d) = @_;
  $d = $s->dim(0) if (!defined($d) || $d > $s->dim(0));
  my $end = $d-1;
  return ($u->slice("0:$end,:"),$s->slice("0:$end"),$v->slice("0:$end,"));
}
sub svdcompose {
  my ($u,$s,$v) = @_;
  #return $u x stretcher($s) x $v->xchg(0,1);   ##-- by definition
  return ($u * $s)->matmult($v->xchg(0,1));     ##-- pdl-ized, more efficient
}
sub svdcomposet {
  my ($ut,$s,$vt) = @_;
  return svdcompose($ut->xchg(0,1),$s,$vt->xchg(0,1));
}
sub svdwanterr {
  my ($a,$u,$s,$v) = @_;
  return (($a-svdcompose($u,$s,$v))**2)->flat->sumover;
}

##---------------------------------------------------------------------
## tests
##-- $d==$n: expect
my $d  = $n;
my $d1 = $n-2;

my $s_want = pdl(double,
		 [23.32284744104,12.9401616781924,10.9945440916999,9.08839598479768,3.84528764361343,1.1540470359863,0]);
my $s1_want = $s_want->slice("0:".($d1-1));

##-- test 1..2 : svdlas2, d=n
my ($u,$ut,$s,$v,$vt);
svdlas2($ptr,$rowids,$nzvals, $m,
	$iters, $end, $kappa,
	($ut=zeroes(double,$m,$d)),
	($s=zeroes(double,$d)),
	($vt=zeroes(double,$d,$n)),
       );
pdlapprox("svdlas2,d=n:s",   $s, $s_want);
pdlapprox("svdlas2,d=n:data", svdcomposet($ut,$s,$vt), $a);

##-- test 3..4 : svdlas2a, d=n
($ut,$s,$vt) = svdlas2a($ptr,$rowids,$nzvals);
pdlapprox("svdlas2a,d=n:s",    $s, $s_want);
pdlapprox("svdlas2a,d=n:data", svdcomposet($ut,$s,$vt), $a);

##-- test 5..6 : svdlas2a, d<n
($ut,$s,$vt) = svdlas2a($ptr,$rowids,$nzvals, $m,$d1);
pdlapprox("svdlas2a,d<n:s",    $s, $s1_want);
pdlapprox("svdlas2a,d<n:data", svdcomposet($ut,$s,$vt), $a,0.5);

##-- test 7..8 : svdlas2w, d=n
my $whichi = $a->whichND->qsortvec->xchg(0,1);
my $whichv = $a->indexND($whichi->xchg(0,1));
svdlas2w($whichi,$whichv, $n,$m,
	 $iters, $end, $kappa,
	 ($ut=zeroes(double,$m,$d)),
	 ($s=zeroes(double,$d)),
	 ($vt=zeroes(double,$d,$n)),
	);
pdlapprox("svdlas2w,d=n:s",    $s, $s_want);
pdlapprox("svdlas2w,d=n:data", svdcomposet($ut,$s,$vt), $a);

##-- test 9..10 : svdlas2aw, d=n
($ut,$s,$vt) = svdlas2aw($whichi,$whichv);
pdlapprox("svdlas2aw,d=n:s",    $s, $s_want);
pdlapprox("svdlas2aw,d=n:data", svdcomposet($ut,$s,$vt), $a);

##-- test 11..12 : svdlas2aw, d<n
($ut,$s,$vt) = svdlas2aw($whichi,$whichv, $n,$m,$d1);
pdlapprox("svdlas2aw,d<n:s",    $s, $s1_want);
pdlapprox("svdlas2aw,d<n:data", svdcomposet($ut,$s,$vt), $a,0.5);

##-- test 13..14 : svdlas2aw, d=n, transpsosed whichND
$whichi = $a->whichND->qsortvec;
$whichv = $a->indexND($whichi);
($ut,$s,$vt) = svdlas2aw($whichi,$whichv);
pdlapprox("svdlas2aw,whichT,d=n:s",    $s, $s_want);
pdlapprox("svdlas2aw,whichT,d=n:data", svdcomposet($ut,$s,$vt), $a);


##-- test 15..16 : svdlas2d, d=n
svdlas2d($a,
	 $iters, $end, $kappa,
	 ($ut=zeroes(double,$m,$d)),
	 ($s=zeroes(double,$d)),
	 ($vt=zeroes(double,$d,$n)),
	);
pdlapprox("svdlas2d,d=n:s",    $s, $s_want);
pdlapprox("svdlas2d,d=n:data", svdcomposet($ut,$s,$vt), $a);

##-- test 17..18 : svdlas2ad
($ut,$s,$vt) = svdlas2ad($a);
pdlapprox("svdlas2ad,d=n:s",    $s, $s_want);
pdlapprox("svdlas2ad,d=n:data", svdcomposet($ut,$s,$vt), $a);

##-- test 19..20 : svdlas2ad, d<n
($ut,$s,$vt) = svdlas2ad($a,$d1);
pdlapprox("svdlas2a,d<n:s",    $s, $s1_want);
pdlapprox("svdlas2a,d<n:data", svdcomposet($ut,$s,$vt), $a, 0.5);

##-- test 21..24: decode+error (PDL::MatrixOps::svd(), full)
($v,$s,$u) = svd($a->xchg(0,1));
pdlapprox("svdindexND,d=n", svdindexND($u,$s,$v, $whichi), $whichv, 1e-5);
pdlapprox("svdindexNDt,d=n", svdindexNDt($u->xchg(0,1),$s,$v->xchg(0,1), $whichi), $whichv, 1e-5);
pdlapprox("svdindexccs,d=n", svdindexccs($u,$s,$v, $ptr,$rowids), $whichv, 1e-5);
pdlapprox_nodims("svderror,d=n",  svderror($u,$s,$v, $ptr,$rowids,$nzvals), svdwanterr($a,$u,$s,$v));

##-- test 25..28: decode+error (PDL::MatrixOps::svd(), whichND, reduced);
my ($ur,$sr,$vr) = svdreduce($u,$s,$v,$d1);
pdlapprox("svdindexND,d<n", svdindexND($ur,$sr,$vr, $whichi), $whichv,0.5);
pdlapprox("svdindexNDt,d<n", svdindexNDt($ur->xchg(0,1),$sr,$vr->xchg(0,1), $whichi), $whichv,0.5);
pdlapprox("svdindexccs,d<n", svdindexccs($ur,$sr,$vr, $ptr,$rowids), $whichv,0.5);
pdlapprox_nodims("svderror,d<n", svderror($ur,$sr,$vr, $ptr,$rowids,$nzvals), svdwanterr($a,$ur,$sr,$vr));

print "\n";

# end of t/01_svd.t


# -*- Mode: CPerl -*-
# t/03_ops.t: test ccs native operations
use Test::More;
use strict;
use warnings;

##-- common subs
my $TEST_DIR;
BEGIN {
  use File::Basename;
  use Cwd;
  $TEST_DIR = Cwd::abs_path dirname( __FILE__ );
  eval qq{use lib ("$TEST_DIR/$_/blib/lib","$TEST_DIR/$_/blib/arch");} foreach (qw(..));
  do "$TEST_DIR/common.plt" or  die("$0: failed to load $TEST_DIR/common.plt: $@");
}

##-- common modules
use PDL;
use PDL::Bad;
use PDL::CCS;

##-- setup
my $a = pdl(double, [
		     [10,0,0,0,-2,0],
		     [3,9,0,0,0,3],
		     [0,7,8,7,0,0],
		     [3,0,8,7,5,0],
		     [0,8,0,9,9,13],
		     [0,4,0,0,2,-1],
		    ]);
my ($ptr,$rowids,$nzvals) = ccsencode($a);

##-- 1: transpose()
my ($ptrT,$rowidsT,$nzvalsT) = ccstranspose($ptr,$rowids,$nzvals);
my $aT = ccsdecode($ptrT,$rowidsT,$nzvalsT)->xchg(0,1);
pdlok("transpose()", $a,$aT);

##-- 2-3: whichND()
my ($ccols,$crows) = ccswhichND($ptr,$rowids,$nzvals);
my ($acols,$arows) = $a->whichND->xchg(0,1)->dog;
pdlok("whichND():cols", $acols->qsort, $ccols->qsort);
pdlok("whichND():rows", $arows->qsort, $crows->qsort);

##-- 4: which()
my $awhich = which($a)->qsort;
my $cwhich = ccswhich($ptr,$rowids,$nzvals)->qsort;
pdlok("which():flat", $awhich, $cwhich);

##-- 5: get(): some missing (zero)
my $allai    = sequence(long,$a->nelem);
my $allavals = $a->flat->index($allai);
my $allcvals = ccsget($ptr,$rowids,$nzvals, $allai,0);
pdlok("get():some_missing:zero", $allavals, $allcvals);

##-- 6: get(): some missing (bad)
my $unless_bad = $PDL::Bad::Status ? '' : "your PDL doesn't support bad values";
skipok("get():some_missing:bad",
       $unless_bad,
       sub {
	 my $badval    = pdl(0)->setvaltobad(0);
	 my $allbcvals = ccsget($ptr,$rowids,$nzvals, $allai,$badval);
	 return (all($allbcvals->where($allbcvals->isgood) == $allavals->where($allbcvals->isgood))
		 &&
		 all($allavals->where($allbcvals->isbad) == 0));
       });

##-- 7: get2d(): some missing (zero)
my ($acoli,$arowi) = ($a->xvals->flat, $a->yvals->flat);
$allavals = $a->index2d($acoli,$arowi);
$allcvals = ccsget2d($ptr,$rowids,$nzvals, $acoli,$arowi,0);
pdlok("index2d():some_missing:zero", $allavals, $allcvals);

##-- 8: index2d(): some missing (bad)
skipok("get():some_missing:bad",
       $unless_bad,
       sub {
	 my $badval    = pdl(0)->setvaltobad(0);
	 my $allbcvals = ccsget2d($ptr,$rowids,$nzvals, $acoli,$arowi,$badval);
	 return (all($allbcvals->where($allbcvals->isgood) == $allavals->where($allbcvals->isgood))
		 &&
		 all($allavals->where($allbcvals->isbad) == 0));
       });


##-- 9: ccsmult_rv (row vector)
my $rv=10**(sequence($a->dim(0))+1);
my $nzvals_rv = ccsmult_rv($ptr,$rowids,$nzvals, $rv);
pdlok("ccsmult_rv()", ($a * $rv), ccsdecode($ptr,$rowids,$nzvals_rv));

##-- 10: ccsmult_cv (col vector)
my $cv=10**(sequence($a->dim(1))+1);
my $nzvals_cv = ccsmult_cv($ptr,$rowids,$nzvals, $cv);
pdlok("ccsmult_cv()", ($a * $cv->slice("*1,")), ccsdecode($ptr,$rowids,$nzvals_cv));

done_testing;

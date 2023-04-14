# -*- Mode: CPerl -*-
# t/02_encode.t: test ccs encoding
use Test::More;
use strict;
use warnings;

##-- common subs
my $TEST_DIR;
BEGIN {
  use File::Basename;
  use Cwd;
  $TEST_DIR = Cwd::abs_path dirname( __FILE__ );
  eval qq{use lib ("$TEST_DIR/$_/blib/lib","$TEST_DIR/$_/blib/arch");} foreach (qw(../../.. ../.. ..));
  do "$TEST_DIR/common.plt" or  die("$0: failed to load $TEST_DIR/common.plt: $@");
}

##-- common modules
use PDL;
use PDL::CCS::Utils;
use PDL::VectorValued;

##-- setup
my $a = pdl(double, [
		     [10,0,0,0,-2],
		     [3,9,0,0,0],
		     [0,7,8,7,0],
		     [3,0,8,7,5],
		     [0,8,0,9,9],
		     [0,4,0,0,2],
		    ]);

##-- test: encode_pointers
my $awhich = $a->whichND()->vv_qsortvec;
my $avals  = $a->indexND($awhich);
my ($aptr0,$awi0) = ccs_encode_pointers($awhich->slice("(0),"));
my ($aptr1,$awi1) = ccs_encode_pointers($awhich->slice("(1),"));

##-- 1..2
my $awhich_want = pdl(long, [[0,0],[0,1],[0,3],[1,1],[1,2],[1,4],[1,5],[2,2],[2,3],[3,2],[3,3],[3,4],[4,0],[4,3],[4,4],[4,5]]);
#my $avals_want = pdl([10,3,3,9,7,8,4,8,8,7,7,9,-2,5,9,2]);  # this is what we expect to expect
my $avals_want = $a->indexND($awhich_want);                  # ... but what we actually expect is whatever PDL::indexND() does
pdlok("whichND", $awhich,$awhich_want);
pdlok("vals",  $avals, $avals_want);

##-- 3..4: ptr0
pdlok("ccs_encode_pointers:ptr0",   $aptr0, pdl(long,[0,3,7,9,12,16]));
pdlok("ccs_encode_pointers:awi0",   $awi0,  $awi0->sequence);

##-- 5..6: ptr1
pdlok("ccs_encode_pointers:ptr1",    $aptr1, pdl(long,[0,2,4,7,11,14,16]));
my $awi1x = $awhich->slice("(1),")->index($awi1);
pdlok("ccs_encode_pointers:awi1",    $awi1x, $awi1x->qsort);

done_testing;

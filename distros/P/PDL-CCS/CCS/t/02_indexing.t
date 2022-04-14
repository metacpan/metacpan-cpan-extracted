# -*- Mode: CPerl -*-
# t/02_indexing.t
use Test::More;
use strict;
use warnings;

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
use PDL::CCS::Nd;
use PDL::VectorValued;

##--------------------------------------------------------------
## missing==0

my $ccs = $a->toccs;

##-- 1: which
pdlok("which:flat", $ccs->which->qsort, $a->which->qsort);

##-- 2: index (flat)     ------------------> NO PSEUDO-THREADING!
my $find = pdl(long(2,4,6,8));
pdlok("index:flat", $ccs->index($find), $a->flat->index($find));

##-- 3: indexND
$find = pdl(long,[[0,0],[1,0],[1,1]]);
pdlok("indexND", $ccs->indexND($find), $a->indexND($find));

##-- 4..5: dice_axis
my $axisi = pdl(long,[2,4]);
pdlok("dice_axis(0)", $a->dice_axis(0,$axisi), $ccs->dice_axis(0,$axisi)->decode);
pdlok("dice_axis(1)", $a->dice_axis(1,$axisi), $ccs->dice_axis(1,$axisi)->decode);

##-- 6..8: at,set
my @nzindex = (4,3);
my @zindex  = (3,1);
isok("at():nz", $ccs->at(@nzindex), $a->at(@nzindex));
isok("at:z",    $ccs->at(@zindex), $a->at(@zindex));
pdlok("set():nz", $ccs->set(@nzindex,42)->decode, $a->set(@nzindex,42));

##-- 9..10: reorder
pdlok("reorder(1,0)",             $ccs->reorder(1,0)->decode, $a->reorder(1,0));
pdlok("post-reorder(1,0):decode", $ccs->decode, $a);

##-- 11..12: xchg(0,1)
pdlok("xchg(0,1)",                $ccs->xchg(0,1)->decode, $a->xchg(0,1));
pdlok("post-xchg(0,1):decode",    $ccs->decode, $a);

##-- 13..14: xchg(0,-1)
pdlok("xchg(0,-1)",               $ccs->xchg(0,-1)->decode, $a->xchg(0,-1));
pdlok("post-xchg(0,-1):decode",   $ccs->decode, $a);

##-- 15..16: mv(0,1)
pdlok("mv(0,1)",                  $ccs->mv(0,1)->decode, $a->mv(0,1));
pdlok("post-mv(0,1):decode",      $ccs->decode, $a);

##-- 17..18: mv(1,0)
pdlok("mv(1,0)",                  $ccs->mv(1,0)->decode, $a->mv(1,0));
pdlok("post-mv(1,0):decode",      $ccs->decode, $a);

##-- 19..22: xsubset2d
my $ai = pdl(long, [1,2,4]);
my $bi = pdl(long, [2,4]);
my $wnd = $ai->slice("*".$bi->nelem.",")->cat($bi)->clump(2)->xchg(0,1);
my $abi      = $wnd->vsearchvec($ccs->_whichND);
my $abi_mask = ($wnd==$ccs->_whichND->dice_axis(1,$abi))->andover;
$abi         = $abi->where($abi_mask);
my $absub = $ccs->xsubset2d($ai,$bi);
isok("xsubset2d:defined", defined($absub));
pdlok("xsubset2d:which",   $absub->_whichND, $ccs->_whichND->dice_axis(1,$abi));
pdlok("xsubset2d:nzvals",  $absub->_nzvals,  $ccs->_nzvals->index($abi));
pdlok("xsubset2d:missing", $absub->missing, $ccs->missing);

##-- 23..24: xsubset1d
my $xi   = pdl(long, [0,2]);
my $sub1 = $ccs->xsubset1d($xi);
isok("xsubset1d:defined", defined($sub1));
pdlok("xsubset1d:vals",   $sub1->decode->dice_axis(0,$xi), $a->dice_axis(0,$xi));

##-- 25..26: pxsubset1d
my $yi   = pdl(long, [1,3]);
my $sub2 = $ccs->pxsubset1d(1,$yi);
isok("pxsubset1d:defined", defined($sub2));
pdlok("pxsubset1d:vals",   $sub2->decode->dice_axis(1,$yi), $a->dice_axis(1,$yi));

done_testing;

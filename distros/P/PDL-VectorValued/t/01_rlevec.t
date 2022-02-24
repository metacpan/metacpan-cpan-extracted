# -*- Mode: CPerl -*-
# t/01_rlevec.t: test rlevec/rldvec
use Test::More tests => 17;

##-- common subs
my $TEST_DIR;
BEGIN {
  use File::Basename;
  use Cwd;
  $TEST_DIR = Cwd::abs_path dirname( __FILE__ );
  eval qq{use lib ("$TEST_DIR/$_/blib/lib","$TEST_DIR/$_/blib/arch");} foreach (qw(..));
  do "$TEST_DIR/common.plt" or die("$0: failed to load $TEST_DIR/common.plt: $@");
}

##-- common modules
use PDL;
use PDL::VectorValued;

##-- common vars
my ($tmp);

##--------------------------------------------------------------
## rlevec(), rldvec(): 2d ONLY

## 1..2: test rlevec()
my $p = pdl([[1,2],[1,2],[1,2],[3,4],[3,4],[5,6]]);

my ($pf,$pv)  = rlevec($p);
my $pf_expect = pdl(long,[3,2,1,0,0,0]);
my $pv_expect = pdl([[1,2],[3,4],[5,6],[0,0],[0,0],[0,0]]);

pdlok("rlevec():counts",  $pf, $pf_expect);
pdlok("rlevec():elts",    $pv, $pv_expect);

## 3..3: test rldvec()
my $pd = rldvec($pf,$pv);
pdlok("rldvec()", $pd, $p);

## 4..4: test enumvec
my $pk = enumvec($p);
pdlok("enumvec()", $pk, pdl(long,[0,1,2,0,1,0]));

## 5..5: test enumvecg
$pk = enumvecg($p);
pdlok("enumvecg()", $pk, pdl(long,[0,0,0,1,1,2]));


##--------------------------------------------------------------
## rleND, rldND: 2d

## 6..7: test rleND(): 2d
($pf,$pv) = rleND($p);
pdlok("rleND():2d:counts", $pf, $pf_expect);
pdlok("rleND():2d:elts",   $pv, $pv_expect);

## 8..8: test rldND(): 2d
$pd = rldND($pf,$pv);
pdlok("rldND():2d", $pd, $p);

##--------------------------------------------------------------
## rleND, rldND: Nd

my $pnd1 = (1  *(sequence(long, 2,3  )+1))->slice(",,*3");
my $pnd2 = (10 *(sequence(long, 2,3  )+1))->slice(",,*2");
my $pnd3 = (100*(sequence(long, 2,3,2)+1));
my $p_nd = $pnd1->mv(-1,0)->append($pnd2->mv(-1,0))->append($pnd3->mv(-1,0))->mv(0,-1);

my $pf_expect_nd = pdl(long,[3,2,1,1,0,0,0]);
my $pv_expect_nd = zeroes($p_nd->type, $p_nd->dims);
($tmp=$pv_expect_nd->slice(",,0:3")) .= $p_nd->dice_axis(-1,[0,3,5,6]);

## 9..10: test rleND(): Nd
my ($pf_nd,$pv_nd) = rleND($p_nd);
pdlok("rleND():Nd:counts", $pf_nd, $pf_expect_nd);
pdlok("rleND():Nd:elts",   $pv_nd, $pv_expect_nd);

## 11..11: test rldND(): Nd
my $pd_nd = rldND($pf_nd,$pv_nd);
pdlok("rldND():Nd", $pd_nd, $p_nd);

##--------------------------------------------------------------
## 12..12: test enumvec(): nd
my $v_nd = $p_nd->clump(2);
my $k_nd = $v_nd->enumvec();
pdlok("enumvec():Nd", $k_nd, pdl(long,[0,1,2,0,1,0,0]));

##--------------------------------------------------------------
## 13..17: test rldseq(), rleseq()
my $lens = pdl(long,[qw(3 0 1 4 2)]);
my $offs = (($lens->xvals+1)*100)->short;
my $seqs = zeroes(short, 0);
$seqs  = $seqs->append(sequence(short,$_)) foreach ($lens->list);
$seqs += $lens->rld($offs);

my $seqs_got = $lens->rldseq($offs);
isok("rldseq():type", $seqs_got->type, $seqs->type);
pdlok("rldseq():data", $seqs_got, $seqs);

my ($len_got,$off_got) = $seqs->rleseq();
isok("rleseq():type", $off_got->type, $seqs->type);
pdlok("rleseq():lens",  $len_got->where($len_got), $lens->where($lens));
pdlok("rleseq():offs",  $off_got->where($len_got), $offs->where($lens));

print "\n";
# end of t/01_rlevec.t


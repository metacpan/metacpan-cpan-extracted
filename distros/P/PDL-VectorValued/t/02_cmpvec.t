# -*- Mode: CPerl -*-
# t/02_cmpvec.t: test cmpvec, vv_qsortvec, vsearchvec
use Test::More tests=>8;

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

##--------------------------------------------------------------
## cmpvec

## 1..3: test cmpvec
my $vdim = 4;
my $v1 = zeroes($vdim);
my $v2 = pdl($v1);
$v2->set(-1,1);

isok("cmpvec:1d:<",  $v1->vv_cmpvec($v2)<0);
isok("cmpvec:1d:>",  $v2->vv_cmpvec($v1)>0);
isok("cmpvec:1d:==", $v1->vv_cmpvec($v1)->sclr, 0);


##--------------------------------------------------------------
## vv_qsortvec, vv_qsortveci

##-- 4..5: qsortvec, qsortveci
my $p2d  = pdl([[1,2],[3,4],[1,3],[1,2],[3,3]]);

pdlok("vv_qsortvec",  $p2d->vv_qsortvec, pdl(long,[[1,2],[1,2],[1,3],[3,3],[3,4]]));
pdlok("vv_qsortveci", $p2d->dice_axis(1,$p2d->vv_qsortveci), $p2d->vv_qsortvec);

##--------------------------------------------------------------
## vsearchvec

##-- 6..8: vsearchvec
my $which = pdl(long,[[0,0],[0,0],[0,1],[0,1],[1,0],[1,0],[1,1],[1,1]]);
my $find  = $which->slice(",0:-1:2");

pdlok("vsearchvec():match", $find->vv_vsearchvec($which), pdl(long,[0,2,4,6]));
isok("vsearchvev():<<",    all(pdl([-1,-1])->vv_vsearchvec($which)==0));
isok("vsearchvev():>>",    all(pdl([2,2])->vv_vsearchvec($which)==$which->dim(1)-1));

print "\n";
# end of t/02_cmpvec.t

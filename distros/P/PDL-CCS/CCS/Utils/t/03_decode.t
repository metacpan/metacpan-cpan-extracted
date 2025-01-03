# -*- Mode: CPerl -*-
# t/03_encode.t: test ccs pointer-decoding
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

##-- test: decode_pointer
my $awhich = $a->whichND;
my $awhich0 = $awhich->slice("(0)");
my $awhich1 = $awhich->slice("(1)");
my $avals  = $a->indexND($awhich);

##-- 1..2: decode_pointer: dim=0: full
my ($aptr0,$anzi0)     = ccs_encode_pointers($awhich0);
my $aproj0             = sequence(long,$a->dim(0));
my ($aproj0d,$apnzi0d) = ccs_decode_pointer($aptr0,$aproj0);
pdlok("ccs_decode_pointer:full:dim=0:proj",  $aproj0d, $awhich0->qsort);
pdlok("ccs_decode_pointer:full:dim=0:nzi",   $apnzi0d, $apnzi0d->sequence);

##-- 3..4: decode_pointer: dim=1: full
my ($aptr1,$anzi1)     = ccs_encode_pointers($awhich1);
my $aproj1             = sequence(long,$a->dim(1));
my ($aproj1d,$apnzi1d) = ccs_decode_pointer($aptr1,$aproj1);
pdlok("ccs_decode_pointer:full:dim=1:proj", $aproj1d, $awhich1->qsort);
pdlok("ccs_decode_pointer:full:dim=1:nzi",  $apnzi1d, $apnzi1d->sequence);

##-- 5..6: decode_pointer: dim=0: partial
$aproj0 = pdl(long,[1,2,4]);
my $aslice0 = $a->dice_axis(0,$aproj0);
($aproj0d,$apnzi0d) = ccs_decode_pointer($aptr0,$aproj0);

my $apnzi      = $anzi0->index($apnzi0d);
my $which_proj = $aproj0d->slice("*1,")->append($awhich->slice("1")->dice_axis(1,$apnzi));
my $vals_proj  = $avals->index($apnzi);

pdlok("ccs_decode_pointer:partial:dim=0:which", $which_proj->vv_qsortvec, $aslice0->whichND->vv_qsortvec);
pdlok("ccs_decode_pointer:partial:dim=0:vals",  $vals_proj, $aslice0->indexND($which_proj));

##-- 7..8: decode_pointer: dim=1: partial
$aproj1 = pdl(long,[2,3,5]);
my $aslice1 = $a->dice_axis(1,$aproj1);
($aproj1d,$apnzi1d) = ccs_decode_pointer($aptr1,$aproj1);

$apnzi      = $anzi1->index($apnzi1d);
$which_proj = $aproj1d->slice("*1,")->append($awhich->slice("0")->dice_axis(1,$apnzi))->slice("-1:0");
$vals_proj  = $avals->index($apnzi);

pdlok("ccs_decode_pointer:partial:dim=1:which", $which_proj->vv_qsortvec, $aslice1->whichND->vv_qsortvec);
pdlok("ccs_decode_pointer:partial:dim=1:vals",  $vals_proj, $aslice1->indexND($which_proj));

##-- test Compat::ccswhichND-style usage with pre-allocated outputs
sub test_decode_args {
  my ($label, @args) = @_;
  print "# test_decode_args:$label\n";
  my $aptr = pdl(indx, [0,3,7,9,12,16, 19]); # == $ptr0->append(19)
  my $aproj = sequence(indx, $aptr->nelem - 1);

  my ($projix, $nzix) = ccs_decode_pointer($aptr, $aproj, @args);
  pdlok("test_decode_args:$label:projix", $projix, pdl(indx, [0,0,0,1,1,1,1,2,2,3,3,3,4,4,4,4,5,5,5]));
  pdlok("test_decode_args:$label:nzix", $nzix, sequence(indx, 19));
}
test_decode_args('no-outputs');
test_decode_args('null-outputs', null, null);
test_decode_args('prealloc-projix', zeroes(indx, 19), null);
test_decode_args('prealloc-nzix', null, zeroes(indx, 19));
test_decode_args('prealloc-all', zeroes(indx, 19), zeroes(indx, 19));

done_testing;

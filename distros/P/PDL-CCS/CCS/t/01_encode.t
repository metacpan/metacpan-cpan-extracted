# -*- Mode: CPerl -*-
# t/01_encode.t
use Test::More tests => 83;

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

## (i+1)..(i+9): basic properites (missing==0)
sub test_basic {
  my ($label,$a,$ccs,$missing) = @_;

  isok("${label}:defined", defined($ccs));
  isok("${label}:dims",    all(pdl($ccs->dims)==pdl($a->dims)));
  isok("${label}:nelem",   $ccs->nelem==$a->nelem);

  ##-- check missing
  $missing = 0 if (!defined($missing));
  $missing = PDL->topdl($missing);
  if ($missing->isbad) {
    $awhichND = whichND(!isbad($a));
  } else {
    $awhichND = whichND($a!=$missing);
  }

  isok("${label}:_nnz",    $ccs->_nnz==$awhichND->dim(1));
  pdlok("${label}:whichND", $ccs->whichND->vv_qsortvec, $awhichND->vv_qsortvec);
  pdlok("${label}:nzvals",  $ccs->whichVals, $a->indexND(scalar($ccs->whichND)));
  pdlok_nodims("${label}:missing:value", $ccs->missing, $missing);

  ##-- testdecode
  pdlok("${label}:decode",  $ccs->decode,$a);
  pdlok("${label}:todense", $ccs->todense,$a);
}


##--------------------------------------------------------------
## missing==0

##-- 1*nbasic: newFromDense(): basic properties
$ccs = PDL::CCS::Nd->newFromDense($a);
test_basic("newFromDense:missing=0", $a, $ccs, 0);

##-- 2*nbasic: toccs(): basic properties
$ccs = $a->toccs;
test_basic("toccs:missing=0", $a, $ccs, 0);

##-- 3*nbasic: newFromWhich()
$ccs = PDL::CCS::Nd->newFromWhich($awhich,$avals,missing=>0);
test_basic("newFromWhich:missing=0", $a, $ccs, 0);

##--------------------------------------------------------------
## missing==BAD

##-- 5*nbasic: newFromDense(...BAD): basic properties
$a     = $a->setbadif($abad);
$avals = $a->indexND($awhich);
test_basic("newFromDense:missing=BAD:explicit", $a, PDL::CCS::Nd->newFromDense($a,$BAD), $BAD);
test_basic("newFromDense:missing=BAD:implicit", $a, PDL::CCS::Nd->newFromDense($a),      $BAD);

##-- 7*nbasic: toccs(...BAD): basic properties
test_basic("toccs:missing=BAD:explicit", $a, $a->toccs($BAD), $BAD);
test_basic("toccs:missing=BAD:implicit", $a, $a->toccs(),     $BAD);

##-- 9*nbasic: newFromWhich(...BAD)
test_basic("newFromWhich:missing=BAD:explicit", $a, PDL::CCS::Nd->newFromWhich($awhich,$avals,missing=>$BAD), $BAD);
test_basic("newFromWhich:missing=BAD:implicit", $a, PDL::CCS::Nd->newFromWhich($awhich,$avals),               $BAD);

##--------------------------------------------------------------
## global tests
##  (9*nbasic)..((9*nbasic)+2)

## 1..2: PDL->todense, PDL::CCS::Nd->toccs
isok("PDL::todense():no-copy", overload::StrVal($a)   eq overload::StrVal($a->todense));
isok("CCS::toccs():no-copy",   overload::StrVal($ccs) eq overload::StrVal($ccs->toccs));

print "\n";
# end of t/*.t


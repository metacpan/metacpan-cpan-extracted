# -*- Mode: CPerl -*-
# t/01_svd.t: test SLEPc svd
use Test::More tests => 37;

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
use PDL::SVDSLEPc;

##----------------------------------------------------------------------
## setup
my $a = pdl(double,
	    [[10,0,0,0,-2,0,0],
	     [3,9,0,0,0,3,1],
	     [0,7,8,7,0,0,0],
	     [3,0,8,7,5,0,1],
	     [0,8,0,9,9,13,0],
	     [0,4,0,0,2,-1,1]]);

my $ptr=pdl(long,[0,3,7,9,12,16,19, 22]);
my $colids=pdl(long,[0,1,3,1,2,4,5,2,3,2,3,4,0,3,4,5,1,4,5,1,3,5]);
my $nzvals=pdl(double,[10,3,3,9,7,8,4,8,8,7,7,9,-2,5,9,2,3,13,-1,1,1,1]);
my ($m,$n) = $a->dims;

##-- common variables
my ($u,$s,$v);

##-- expected values
my $d  = min2($n,$m);
my $d1 = $d-1;
my $s_want = pdl(double,
		 [23.3228474410401, 12.9401616781924, 10.9945440916999, 9.08839598479767, 3.84528764361343, 1.1540470359863, 0]);

##----------------------------------------------------------------------
## common subs
sub min2 {
  return $_[0]<$_[1] ? $_[0] : $_[1];
}
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
sub svdtest {
  my ($label, $u,$s,$v, $eps_s,$eps_v) = @_;
  my $ns = $s->nelem;
  $eps_s = .01    if (!defined($eps_s));
  $eps_v = $eps_s if (!defined($eps_v));
  pdlapprox("${label} - s [eps=$eps_s]", $s, $s_want->slice("0:".($ns-1)), $eps_s);
  pdlapprox("${label} - vals [eps=$eps_v]", svdcompose($u,$s,$v), $a, $eps_v);
}

##----------------------------------------------------------------------
## builtin

##-- test 1..2 : builtin svd, d=min{m,n}
($v,$s,$u) = svdreduce(svd($a->xchg(0,1)),$d);
svdtest("PDL::svd - d=$d=min{m,n}", $u,$s,$v, .01);

##-- test 3..4 : builtin svd, d<min{m,n}
($v,$s,$u) = svdreduce(svd($a->xchg(0,1)),$d1);
svdtest("PDL::svd - d=$d1<min{m,n}", $u,$s,$v, .01,.5);

##----------------------------------------------------------------------
## _slepc_svd_int(): basic

##-- test 5..6 : _slepc_svd_int(), d=min{m,n}
($u,$s,$v) = _slepc_svd_int($ptr,$colids,$nzvals, $m,$n,$d, []);
svdtest("_slepc_svd_int - d=$d=min{m,n}", $u,$s,$v, .01,.01);

##-- test 7..8 : _slepc_svd_int(), d<{m,n}
($u,$s,$v) = _slepc_svd_int($ptr,$colids,$nzvals, $m,$n,$d1, []);
svdtest("_slepc_svd_int - d=$d1<min{m,n}", $u,$s,$v, .01,.5);

##----------------------------------------------------------------------
## _slepc_svd_int(): transposed

##-- test 9..10 : _slepc_svd_int(), transposed, d=min{m,n}
my $xptr    = pdl(long,[0,2,6,9,14,18,22]);
my $xcolids = pdl(long,[0,4,0,1,5,6,1,2,3,0,2,3,4,6,1,3,4,5,1,4,5,6]);
my $xnzvals = pdl(double,[10,-2,3,9,3,1,7,8,7,3,8,7,5,1,8,9,9,13,4,2,-1,1]);
($v,$s,$u) = _slepc_svd_int($xptr,$xcolids,$xnzvals, $n,$m,$d, []);
svdtest("_slepc_svd_int - transposed - d=$d=min{m,n}", $u,$s,$v, .01,.01);

##-- test 11..12 : _slepc_svd_int(), transposed, d<{m,n}
($v,$s,$u) = _slepc_svd_int($xptr,$xcolids,$xnzvals, $n,$m,$d1, []);
svdtest("_slepc_svd_int - transposed - d=$d1<min{m,n}", $u,$s,$v, .01,.5);

##----------------------------------------------------------------------
## _slepc_svd_int(): lanczos, trlanczos

##-- test 13..14 : _slepc_svd_int(), d=min{m,n}
($u,$s,$v) = _slepc_svd_int($ptr,$colids,$nzvals, $m,$n,$d, [qw(-svd_type lanczos)]);
svdtest("_slepc_svd_int - lanczos", $u,$s,$v, .01,.01);

##-- test 15..16 : _slepc_svd_int(), d<{m,n}
($u,$s,$v) = _slepc_svd_int($ptr,$colids,$nzvals, $m,$n,$d, [qw(-svd_type trlanczos)]);
svdtest("_slepc_svd_int - trlanczos", $u,$s,$v, .01,.01);

##----------------------------------------------------------------------
## slepc_svd(): defaults
my ($label);

##-- test 17..19: defaults - dims - from src
$label="slepc_svd - defaults - dims - src";
($u,$s,$v) = slepc_svd($ptr,$colids,$nzvals);
is($s->nelem, $d, "$label - d==$d=min2{m,n}");
svdtest($label, $u,$s,$v, .01,.01);

##-- test 20..22: defaults - dims - from dst.u
$label="slepc_svd - defaults - dims - dst.u";
($u,$s,$v) = slepc_svd($ptr,$colids,$nzvals, zeroes(double,$d1,$n));
is($s->nelem, $d1, "$label - d==$d1<min2{m,n}");
svdtest($label, $u,$s,$v, .01,.5);

##-- test 23..25: defaults - dims - from dst.s
$label="slepc_svd - defaults - dims - dst.s";
($u,$s,$v) = slepc_svd($ptr,$colids,$nzvals, null,zeroes(double,$d1));
is($s->nelem, $d1, "$label - d==$d1<min2{m,n}");
svdtest($label, $u,$s,$v, .01,.5);

##-- test 26..28: defaults - dims - from dst.v
$label="slepc_svd - defaults - dims - dst.v";
($u,$s,$v) = slepc_svd($ptr,$colids,$nzvals, null,null,zeroes(double,$d1,$m));
is($s->nelem, $d1, "$label - d==$d1<min2{m,n}");
svdtest($label, $u,$s,$v, .01,.5);

##-- test 29..31: defaults - dims - from d
$label="slepc_svd - defaults - dims - d";
($u,$s,$v) = slepc_svd($ptr,$colids,$nzvals, undef,undef,$d1);
is($s->nelem, $d1, "$label - d==$d1<min2{m,n}");
svdtest($label, $u,$s,$v, .01,.5);

##-- test 32..34: defaults - dims - from option array
$label="slepc_svd - defaults - dims - option array";
($u,$s,$v) = slepc_svd($ptr,$colids,$nzvals, ['-svd_nsv'=>$d1]);
is($s->nelem, $d1, "$label - d==$d1<min2{m,n}");
svdtest($label, $u,$s,$v, .01,.5);

##-- test 35..37: defaults - dims - from option hash
$label="slepc_svd - defaults - dims - option array";
($u,$s,$v) = slepc_svd($ptr,$colids,$nzvals, {'-svd_nsv'=>$d1});
is($s->nelem, $d1, "$label - d==$d1<min2{m,n}");
svdtest($label, $u,$s,$v, .01,.5);


# end of t/01_svd.t


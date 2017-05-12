# -*- Mode: CPerl -*-
# t/03_setops.t: test PDL::VectorValued set operations
use Test::More tests=>12;

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
## vv: data
my $vtype = long;
my $universe = pdl($vtype,[ [0,0],[0,1],[1,0],[1,1] ]);
my $v1 = $universe->dice_axis(1,pdl([0,1,2]));
my $v2 = $universe->dice_axis(1,pdl([1,2,3]));

## 1..3: vv_union
my ($c,$nc) = $v1->vv_union($v2);
pdlok("vv_union:list:c", $c, pdl($vtype, [ [0,0],[0,1],[1,0],[1,1],[0,0],[0,0] ]));
isok("vv_union:list:nc", $nc, $universe->dim(1));
my $cc = $v1->vv_union($v2);
pdlok("vv_union:scalar", $cc, $universe);

## 4..6: vv_intersect
($c,$nc) = $v1->vv_intersect($v2);
pdlok("vv_intersect:list:c", $c, pdl($vtype, [ [0,1],[1,0],[0,0] ]));
isok("vv_intersect:list:nc", $nc->sclr, 2);
$cc = $v1->vv_intersect($v2);
pdlok("vv_intersect:scalar", $cc, $universe->slice(",1:2"));

## 7..9: vv_setdiff
($c,$nc) = $v1->vv_setdiff($v2);
pdlok("vv_setdiff:list:c", $c, pdl($vtype, [ [0,0], [0,0],[0,0] ]));
isok("vv_setdiff:list:nc", $nc, 1);
$cc = $v1->vv_setdiff($v2);
pdlok("vv_setdiff:scalar", $cc, pdl($vtype, [[0,0]]));

##--------------------------------------------------------------
## v: data
my $all = sequence(20);
my $amask = ($all % 2)==0;
my $bmask = ($all % 3)==0;
my $a   = $all->where($amask);
my $b   = $all->where($bmask);

## 10: v_union
pdlok("v_union", scalar($a->v_union($b)), $all->where($amask | $bmask));

## 11: v_intersect
pdlok("v_intersect", scalar($a->v_intersect($b)),  $all->where($amask & $bmask));

## 12: v_setdiff
pdlok("v_setdiff", scalar($a->v_setdiff($b)), $all->where($amask & $bmask->not));

print "\n";
# end of t/03_setops.t


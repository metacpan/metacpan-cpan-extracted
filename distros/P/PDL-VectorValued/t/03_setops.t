# -*- Mode: CPerl -*-
# t/03_setops.t: test PDL::VectorValued set operations
use Test::More;

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

##--------------------------------------------------------------
## vv_*: dim-checks and implicit thread dimensions
##  + see https://github.com/moocow-the-bovine/PDL-VectorValued/issues/4

sub test_vv_thread_dimensions {
  ##-- vv_union

  my $empty = zeroes(3,0);
  my $uw = pdl([[-3,-2,-1],[1,2,3]]);
  my $wx = pdl([[1,2,3],[4,5,6]]);
  my $xy = pdl([[4,5,6],[7,8,9]]);

  # vv_union: basic
  pdlok("vv_union - thread dims - uw+wx", scalar($uw->vv_union($wx)), pdl([[-3,-2,-1],[1,2,3],[4,5,6]]));
  pdlok("vv_union - thread dims - uw+xy", scalar($uw->vv_union($xy)), pdl([[-3,-2,-1],[1,2,3],[4,5,6],[7,8,9]]));
  pdlok("vv_union - thread dims - 0+wx", scalar($empty->vv_union($wx)), $wx);
  pdlok("vv_union - thread dims - wx+0", scalar($wx->vv_union($empty)), $wx);
  pdlok("vv_union - thread dims - 0+0", scalar($empty->vv_union($empty)), $empty);

  # vv_union: threading/broadcasting
  my $k = 2;
  my $kempty = $empty->slice(",,*$k");
  my $kuw = $uw->slice(",,*$k");
  my $kwx = $wx->slice(",,*$k");
  my $kxy = $xy->slice(",,*$k");
  pdlok("vv_union - thread dims - uw(*k)+wx", scalar($kuw->vv_union($wx)), pdl([[-3,-2,-1],[1,2,3],[4,5,6]])->slice(",,*$k"));
  pdlok("vv_union - thread dims - uw(*k)+xy", scalar($kuw->vv_union($xy)), pdl([[-3,-2,-1],[1,2,3],[4,5,6],[7,8,9]])->slice(",,*$k"));
  pdlok("vv_union - thread dims - 0(*k)+wx", scalar($kempty->vv_union($wx)), $kwx);
  pdlok("vv_union - thread dims - wx(*k)+0", scalar($kwx->vv_union($empty)), $kwx);
  pdlok("vv_union - thread dims - 0(*k)+0", scalar($kempty->vv_union($empty)), $kempty);


  ##-- vv_intersect

  my $needle0 = pdl([[-3,-2,-1]]);
  my $needle1 = pdl([[1,2,3]]);
  my $needles = pdl([[-3,-2,-1],[1,2,3]]);
  my $haystack = pdl([[1,2,3],[4,5,6],[7,8,9],[10,11,12]]);

  # vv_intersect: basic
  pdlok("vv_intersect - thread dims - needle0&haystack", scalar($needle0->vv_intersect($haystack)), $empty);
  pdlok("vv_intersect - thread dims - needle1&haystack", scalar($needle1->vv_intersect($haystack)), $needle1);
  pdlok("vv_intersect - thread dims - needles&haystack", scalar($needles->vv_intersect($haystack)), $needle1);
  pdlok("vv_intersect - thread dims - haystack&haystack", scalar($haystack->vv_intersect($haystack)), $haystack);
  pdlok("vv_intersect - thread dims - haystack&empty", scalar($haystack->vv_intersect($empty)), $empty);
  pdlok("vv_intersect - thread dims - empty&haystack", scalar($empty->vv_intersect($haystack)), $empty);

  # vv_intersect: threading/broadcasting
  my $kneedle0 = $needle0->slice(",,*$k");
  my $kneedle1 = $needle1->slice(",,*$k");
  my $kneedles = pdl([[[-3,-2,-1]],[[1,2,3]]]);
  my $khaystack = $haystack->slice(",,*$k");
  pdlok("vv_intersect - thread dims - needle0(*k)&haystack", scalar($kneedle0->vv_intersect($haystack)), $kempty);
  pdlok("vv_intersect - thread dims - needle1(*k)&haystack", scalar($kneedle1->vv_intersect($haystack)), $kneedle1);
  pdlok("vv_intersect - thread dims - needles(*k)&haystack",
	scalar($kneedles->vv_intersect($haystack)),
	pdl([[[0,0,0]],[[1,2,3]]]));
  pdlok("vv_intersect - thread dims - haystack(*k)&haystack", scalar($khaystack->vv_intersect($haystack)), $khaystack);
  pdlok("vv_intersect - thread dims - haystack(*k)&empty", scalar($khaystack->vv_intersect($empty)), $kempty);
  pdlok("vv_intersect - thread dims - empty(*k)&haystack", scalar($kempty->vv_intersect($haystack)), $kempty);

  ##-- vv_setdiff

  # vv_setdiff: basic
  pdlok("vv_setdiff - thread dims - haystack-needle0", scalar($haystack->vv_setdiff($needle0)), $haystack);
  pdlok("vv_setdiff - thread dims - haystack-needle1", scalar($haystack->vv_setdiff($needle1)), $haystack->slice(",1:-1"));
  pdlok("vv_setdiff - thread dims - haystack-needles", scalar($haystack->vv_setdiff($needles)), $haystack->slice(",1:-1"));
  pdlok("vv_setdiff - thread dims - haystack-haystack", scalar($haystack->vv_setdiff($haystack)), $empty);
  pdlok("vv_setdiff - thread dims - haystack-empty", scalar($haystack->vv_setdiff($empty)), $haystack);
  pdlok("vv_setdiff - thread dims - empty-haystack", scalar($empty->vv_setdiff($haystack)), $empty);

  # vv_setdiff: threading/broadcasting
  pdlok("vv_setdiff - thread dims - haystack(*k)-needle0", scalar($khaystack->vv_setdiff($needle0)), $khaystack);
  pdlok("vv_setdiff - thread dims - haystack(*k)-needle1", scalar($khaystack->vv_setdiff($needle1)), $khaystack->slice(",1:-1,"));
  pdlok("vv_setdiff - thread dims - haystack(*k)-needles", scalar($khaystack->vv_setdiff($needles)), $khaystack->slice(",1:-1,"));
  pdlok("vv_setdiff - thread dims - haystack(*k)-haystack", scalar($khaystack->vv_setdiff($haystack)), $kempty);
  pdlok("vv_setdiff - thread dims - haystack(*k)-empty", scalar($khaystack->vv_setdiff($empty)), $khaystack);
  pdlok("vv_setdiff - thread dims - empty(*k)-haystack", scalar($kempty->vv_setdiff($haystack)), $kempty);
}
test_vv_thread_dimensions();

##--------------------------------------------------------------
## vv_intersect tests as suggested by ETJ/mowhawk2
##  + see https://github.com/moocow-the-bovine/PDL-VectorValued/issues/4

sub test_vv_intersect_implicit_dims {
  # vv_intersection: from ETJ/mowhawk2 a la https://stackoverflow.com/a/71446817/3857002
  my $toto = pdl([1,2,3], [4,5,6]);
  my $titi = pdl(1,2,3);
  my $notin = pdl(7,8,9);
  my ($c);

  pdlok('vv_intersect - implicit dims - titi&toto', $c=vv_intersect($titi,$toto), [[1,2,3]]);
  pdlok('vv_intersect - implicit dims - notin&toto', $c=vv_intersect($notin,$toto), zeroes(3,0));
  pdlok('vv_intersect - implicit dims - titi(*1)&toto', $c=vv_intersect($titi->dummy(1), $toto), [[1,2,3]]);
  pdlok('vv_intersect - implicit dims - notin(*1)&toto', $c=vv_intersect($notin->dummy(1), $toto), zeroes(3,0));

  my $needle0_in = pdl([1,2,3]); # 3
  my $needle0_notin = pdl([9,9,9]); # 3
  my $needle_in = $needle0_in->dummy(1);  # 3x1: [[1 2 3]]
  my $needle_notin = $needle0_notin->dummy(1); # 3x1: [[-3 -2 -1]]
  my $needles = pdl([[1,2,3],[9,9,9]]); # 3x2: $needle0_in->cat($needle0_notin)
  my $haystack = pdl([[1,2,3],[4,5,6]]); # 3x2

  sub intersect_ok {
    my ($label, $a,$b, $c_want,$nc_want,$c_sclr_want) = @_;
    my ($c, $nc) = vv_intersect($a,$b);
    my $c_sclr = vv_intersect($a,$b);
    pdlok("$label - result", $c, $c_want) if (defined($c_want));
    pdlok("$label - counts", $nc, $nc_want) if (defined($nc_want));
    pdlok("$label - scalar", $c_sclr, $c_sclr_want) if (defined($c_sclr_want));
  }

  intersect_ok('vv_intersect - implicit dims - needle0_in&haystack',
	       $needle0_in, $haystack,
	       [[1,2,3]], 1, [[1,2,3]]
	      );
  intersect_ok('vv_intersect - implicit dims - needle_in&haystack',
	       $needle_in, $haystack,
	       [[1,2,3]], 1, [[1,2,3]]
	      );

  intersect_ok('vv_intersect - implicit dims - needle0_notin&haystack',
	       $needle0_notin, $haystack,
	       [[0,0,0]], 0, zeroes(3,0)
	      );
  intersect_ok('vv_intersect - implicit dims - needle_notin&haystack',
	       $needle_notin, $haystack,
	       [[0,0,0]], 0, zeroes(3,0)
	      );

  intersect_ok('vv_intersect - implicit dims - needles&haystack',
	       $needles, $haystack,
	       [[1,2,3],[0,0,0]], 1, [[1,2,3]]
	      );

  # now we want to know whether each needle is "in" one by one, not really
  # a normal intersect, so we insert a dummy in haystack in order to broadcast
  # the "nc" needs to come back as a 4x2
  my $needles8 = pdl( [[[1,2,3],[4,5,6],[8,8,8],[8,8,8]],
		       [[4,5,6],[9,9,9],[1,2,3],[9,9,9]]]); # 3x4x2

  # need to manipulate above into suitable inputs for intersect to get right output
  # + dummy dim here also ensures singleton query-vector-sets are (trivially) sorted
  my $needles8x = $needles8->slice(",*1,,"); # 3x*x4x2 # dummy of size 1 inserted in dim 1

  # haystack: no changes needed; don't need same number of dims, broadcast engine will add dummy/1s at top
  my $haystack8 = $haystack;
  my $c_want8 = [
		 [[[1,2,3]],[[4,5,6]],[[0,0,0]],[[0,0,0]]],
		 [[[4,5,6]],[[0,0,0]],[[1,2,3]],[[0,0,0]]],
		];
  my $nc_want8 = [[1,1,0,0],
		  [1,0,1,0]];

  intersect_ok('vv_intersect - implicit dims - needles8x&haystack8',
	       $needles8x, $haystack8,
	       $c_want8, $nc_want8, $c_want8
	      );
}
test_vv_intersect_implicit_dims();

##--------------------------------------------------------------
## v_*: dim-checks and implicit thread dimensions
##  + analogous to https://github.com/moocow-the-bovine/PDL-VectorValued/issues/4

sub test_v_thread_dimensions {
  # data: basic
  my $empty = zeroes(0);
  my $v1_2 = pdl([1,2]);
  my $v3_4 = pdl([3,4]);
  my $v1_4 = $v1_2->cat($v3_4)->flat;

  # data: threading/broadcasting
  my $k = 2;
  my $kempty = $empty->slice(",*$k");
  my $kv1_2 = $v1_2->slice(",*$k");
  my $kv3_4 = $v3_4->slice(",*$k");
  my $kv1_4 = $v1_4->slice(",*$k");

  #-- v_union
  pdlok("v_union - thread dims - 12+34", scalar($v1_2->v_union($v3_4)), $v1_4);
  pdlok("v_union - thread dims - 34+1234", scalar($v3_4->v_union($v1_4)), $v1_4);
  pdlok("v_union - thread dims - 0+1234", scalar($empty->v_union($v1_4)), $v1_4);
  pdlok("v_union - thread dims - 1234+0", scalar($v1_4->v_union($empty)), $v1_4);
  pdlok("v_union - thread dims - 0+0", scalar($empty->v_union($empty)), $empty);
  #
  pdlok("v_union - thread dims - 12(*k)+34", scalar($kv1_2->v_union($v3_4)), $kv1_4);
  pdlok("v_union - thread dims - 34(*k)+1234", scalar($kv3_4->v_union($v1_4)), $kv1_4);
  pdlok("v_union - thread dims - 0(*k)+1234", scalar($kempty->v_union($v1_4)), $kv1_4);
  pdlok("v_union - thread dims - 1234(*k)+0", scalar($kv1_4->v_union($empty)), $kv1_4);
  pdlok("v_union - thread dims - 0(*k)+0", scalar($kempty->v_union($empty)), $kempty);

  #-- v_intersect
  pdlok("v_intersect - thread dims - 12&34", scalar($v1_2->v_intersect($v3_4)), $empty);
  pdlok("v_intersect - thread dims - 34&1234", scalar($v3_4->v_intersect($v1_4)), $v3_4);
  pdlok("v_intersect - thread dims - 0&1234", scalar($empty->v_intersect($v1_4)), $empty);
  pdlok("v_intersect - thread dims - 1234&0", scalar($v1_4->v_intersect($empty)), $empty);
  pdlok("v_intersect - thread dims - 0&0", scalar($empty->v_intersect($empty)), $empty);
  #
  pdlok("v_intersect - thread dims - 12(*k)&34", scalar($kv1_2->v_intersect($v3_4)), $kempty);
  pdlok("v_intersect - thread dims - 34(*k)&1234", scalar($kv3_4->v_intersect($v1_4)), $kv3_4);
  pdlok("v_intersect - thread dims - 0(*k)&1234", scalar($kempty->v_intersect($v1_4)), $kempty);
  pdlok("v_intersect - thread dims - 1234(*k)&0", scalar($kv1_4->v_intersect($empty)), $kempty);
  pdlok("v_intersect - thread dims - 0(*k)&0", scalar($kempty->v_intersect($empty)), $kempty);

  #-- v_setdiff
  pdlok("v_setdiff - thread dims - 12-34", scalar($v1_2->v_setdiff($v3_4)), $v1_2);
  pdlok("v_setdiff - thread dims - 34-1234", scalar($v3_4->v_setdiff($v1_4)), $empty);
  pdlok("v_setdiff - thread dims - 1234-0", scalar($v1_4->v_setdiff($empty)), $v1_4);
  pdlok("v_setdiff - thread dims - 0-1234", scalar($empty->v_setdiff($v1_4)), $empty);
  pdlok("v_setdiff - thread dims - 0-0", scalar($empty->v_setdiff($empty)), $empty);
  #
  pdlok("v_setdiff - thread dims - 12(*k)-34", scalar($kv1_2->v_setdiff($v3_4)), $kv1_2);
  pdlok("v_setdiff - thread dims - 34(*k)-1234", scalar($kv3_4->v_setdiff($v1_4)), $kempty);
  pdlok("v_setdiff - thread dims - 1234(*k)-0", scalar($kv1_4->v_setdiff($empty)), $kv1_4);
  pdlok("v_setdiff - thread dims - 0(*k)-1234", scalar($kempty->v_setdiff($v1_4)), $kempty);
  pdlok("v_setdiff - thread dims - 0(*k)-0", scalar($kempty->v_setdiff($empty)), $kempty);

}
test_v_thread_dimensions();



print "\n";
done_testing();
# end of t/03_setops.t

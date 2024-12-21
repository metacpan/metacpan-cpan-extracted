# -*- Mode: CPerl -*-
# t/06_matops.t
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
our ($a, $abad, $agood, $awhich, $avals, $BAD);

##-- common modules
use PDL;
use PDL::CCS::Nd;

##--------------------------------------------------------------
## hacks

##-- x1
sub test_matmult2d_sdd {
  my ($lab,$a,$b,$az) = @_;  ##-- dense args
  $az = $a->toccs if (!defined($az));
  my $c = $a x $b;       ##-- dense output (desired)
  my $cz = $az->matmult2d_sdd($b);
  pdlok("${lab}:matmult2d_sdd:obj:missing=".($az->missing->sclr), $cz, $c);
}

##-- x1
sub test_matmult2d_zdd {
  my ($lab,$a,$b,$az) = @_;  ##-- dense args
  $az = $a->toccs if (!defined($az));
  my $c = $a x $b;       ##-- dense output (desired)
  my $cz = $az->matmult2d_zdd($b);
  pdlok("${lab}:matmult2d_zdd:obj:missing=".($az->missing->sclr), $cz,$c);
}

##-- +2*sdd +1*zdd = +3
sub test_matmult2d_all {
  my ($M,$N,$O) = (2,3,4);
  my $a = sequence($M,$N);
  my $b = (sequence($O,$M)+1)*10;
  test_matmult2d_sdd('m0',$a,$b, $a->toccs);
  test_matmult2d_zdd('m0',$a,$b, $a->toccs);

  my $a1 = $a->pdl;
  $a1->where(($a%2)==0) .= 1;
  test_matmult2d_sdd('m1',$a,$b, $a->toccs(1));
}
test_matmult2d_all();

##-- +8
sub test_vcos_zdd {
  my $a  = pdl([[1,2,3,4],[1,2,2,1],[-1,-2,-3,-4]])->xchg(0,1);
  my $ax = $a->xchg(0,1);
  my $b = pdl([1,2,3,4]);
  my $ccs = $a->toccs;

  ##-- test: vnorm
  my $anorm0 = $ccs->vnorm(0);
  my $anorm0_want = ($a**2)->xchg(0,1)->sumover->sqrt;
  pdlapprox("vnorm(0)", $anorm0, $anorm0_want, 1e-5);
  ##
  my $anorm1 = $ccs->vnorm(1);
  my $anorm1_want = ($a**2)->sumover->sqrt;
  pdlapprox("vnorm(1)", $anorm1, $anorm1_want, 1e-5);

  ##-- test: vcos_zdd
  my $vcos = $ccs->vcos_zdd($b);
  my $vcos_want = pdl([1,0.8660254,-1]);
  pdlapprox("vcos_zdd", $vcos, $vcos_want, 1e-4);
  ##
  my $b3 = $b->slice(",*3");
  my $vcos3 = $ccs->vcos_zdd($b3);
  pdlapprox("vcos_zdd:threaded", $vcos3, $vcos_want->slice(",*3"), 1e-4);

  ##-- test: vcos_pzd
  $vcos = $ccs->vcos_pzd($b->toccs);
  pdlapprox("vcos_pzd", $vcos, $vcos_want, 1e-4);

  ##-- test: vcos_zdd: nullvec:a
  my $a0 = $a->pdl;
  (my $tmp=$a0->slice("(1),")) .= 0;
  my $ccs0 = $a0->toccs;
  my $vcos0 = $ccs0->vcos_zdd($b);
  my $nan = $^O =~ /MSWin32/i ? ((99**99)**99) - ((99**99)**99) : 'nan';
  my $vcos0_want = pdl([1,$nan,-1]);
  pdlapprox("vcos_zdd:nullvec:a:nan", $vcos0, $vcos0_want, 1e-4);

  ##-- test: vcos_zdd: nullvec:b
  my $b0 = $b->zeroes;
  $vcos0 = $ccs->vcos_zdd($b0);
  $vcos0_want = pdl([$nan, $nan, $nan]);
  pdlok("vcos_zdd:nullvec:b:nan", $vcos0, $vcos0_want);

  ##-- test: vcos_zdd: bad:b
  my $b1 = $b->pdl->setbadif($b->xvals==2);
  my $vcos1 = $ccs->vcos_zdd($b1);
  my $vcos1_want = pdl([0.8366,0.6211,-0.8366]);
  pdlapprox("vcos_zdd:bad:b", $vcos1, $vcos1_want, 1e-4);
}
test_vcos_zdd();

##--------------------------------------------------------------
## matrix operation test (manual swap)

##   + "$as" is $a->toccs($missing_val);
##   + always tests
##   + for $swap==0
##     $PDL_FUNC->($a,$b) ~ $CCS_FUNC->($as,($b|$bs))
##     ($a OP $b)         ~ ($as OP ($bs|$b))
##   + for $swap==1
##     $PDL_FUNC->($b,$a) ~ $CCS_FUNC->($bs,($a|$as))
##     ($b OP $a)         ~ ($bs OP ($a|$as))
sub test_matop {
  my ($lab, $op_name, $op_op, $swap, $missing_val, $a,$abad,$b,$bs) = @_;
  print "test_matop(lab=$lab, name=$op_name, op=", ($op_op||'NONE'), ", swap=$swap, missing=$missing_val)\n";

  my $pdl_func = PDL->can("${op_name}")
    or die("no PDL method ${op_name} defined!");
  my $ccs_func = PDL::CCS::Nd->can("${op_name}")
    or die("no CCS method PDL::CCS::Nd::${op_name} defined!");
  $missing_val = 0 if (!defined($missing_val));
  $missing_val = PDL->topdl($missing_val);
  if ($missing_val->isbad) { $a = $a->setbadif($abad); }
  else                     { $a->where($abad) .= $missing_val; $a->badflag(0); }

  my $as = $a->toccs($missing_val);

  $b  = PDL->topdl($b);
  $bs = $b->toccs($missing_val) if (!defined($bs));
  if ($op_name eq 'matmult') {
    if ($lab eq 'mat.mat' && $b->ndims > 1 && $b->dim(1) != 1) {
      ##-- hack: mat.mat
      $b  = $b->xchg(0,1);
      $bs = $bs->xchg(0,1);
    }
    elsif ($lab eq 'mat.rv' && $b->ndims >= 1 && $b->dim(0)==$a->dim(0)) {
      ##-- hack: mat.rv --> rv.mat
      ($a,$as, $b,$bs) = ($b,$bs, $a,$as);
      $b  = $b->xchg(0,1);
      $bs = $bs->xchg(0,1);
      $swap = 0;
    }
    elsif ($lab eq 'mat.cv' && $b->ndims > 1 && $b->dim(0) == 1) {
      ##-- hack: mat.cv
      $a  = $a->xchg(0,1);
      $as = $as->xchg(0,1);
      $swap = 0;
    }
    elsif ($lab eq 'rv.cv') {
      $a  = $a->xchg(0,1);
      $as = $as->xchg(0,1);
      $b  = $b->xchg(0,1);
      $bs = $bs->xchg(0,1);
      $swap = 0;
    }
  }


  ##-- test: function syntax
  my ($c,$css,$csb);
  if (!$swap) {
    $pdl_func->($a,  $b, $c=null);
    $css   = $ccs_func->($as, $bs);
    $csb    = $ccs_func->($as, $b);
  } else {
    $pdl_func->($b,  $a, $c=null);
    $css   = $ccs_func->($bs, $as);
    $csb    = $ccs_func->($bs, $a);
  }

  ##-- actual test case
  isok("$lab:${op_name}:func:b=sparse:missing=$missing_val:swap=$swap:type",
       $css->type, $c->type);
  pdlok("$lab:${op_name}:func:b=sparse:missing=$missing_val:swap=$swap:vals",
	$css->decode, $c);
  isok("$lab:${op_name}:func:b=dense:missing=$missing_val:swap=$swap:type",
       $c->type, $csb->type);
  pdlok("$lab:${op_name}:func:b=dense:missing=$missing_val:swap=$swap:vals",
	$csb->decode, $c);

  if (defined($op_op)) {
    if (!$swap) {
      eval "\$c = (\$a  $op_op \$b);";
      eval "\$css   = (\$as $op_op \$bs);";
      eval "\$csb    = (\$as $op_op \$b);";
    } else {
      eval "\$c = (\$b  $op_op \$a);";
      eval "\$css   = (\$bs $op_op \$as);";
      eval "\$csb    = (\$bs $op_op \$a);";
    }
    isok("$lab:${op_name}:op=$op_op:b=sparse:missing=$missing_val:swap=$swap:type",
	 $css->type, $c->type);
    pdlok("$lab:${op_name}:op=$op_op:b=sparse:missing=$missing_val:swap=$swap:vals",
	  $css->decode, $c);
    isok("$lab:${op_name}:op=$op_op:b=dense:missing=$missing_val:swap=$swap:type",
	 $csb->type, $c->type);
    pdlok("$lab:${op_name}:op=$op_op:b=dense:missing=$missing_val:swap=$swap:vals",
	  $csb->decode, $c);
  }
}

my @matops = (
	      ##-- Matrix operations
	      'inner',
	      [qw(matmult x)],
	     );
#my @missing = (0,127,'BAD');
my @missing = (0);
my $b;
my @tuples = (
  [ 'mat.mat', $a,$abad,$a->flat->rotate(1)->pdl->reshape($a->dims) ], ##-- Block 1 : mat * mat (rotated)
  [ 'mat.sclr', $a,$abad,PDL->topdl(42) ], ##-- Block 2 : mat * scalar
  [ 'mat.rv', $a,$abad,sequence($a->dim(0),1)+1, undef, 1 ], ##-- Block 3 : mat * row
  [ 'mat.cv', $a,$abad,$b=sequence(1,$a->dim(1))+1, $b->flat->toccs->dummy(0,1) ], ##-- Block 4 : mat * col
  [ 'rv.cv', $a=sequence($a->dim(0),1), ($a==0), $b=sequence(1,$a->dim(1))+1, $b->flat->toccs->dummy(0,1) ], ##-- Block 5 : col * row
);

for my $tuple (@tuples) {
  my ($lab, $a, $abad, $b, $bs, $swap_override) = @$tuple;
  for my $missing (@missing) {  	  ##-- *NMISSING
    for my $swap (0,1) {           ##-- *NSWAP=2
      for my $op (@matops) {       ##-- *1
        test_matop(
          $lab, @{ref $op ? $op : [$op, undef]},
          (ref $op && $swap_override) ? 1 : $swap,
          $missing, $a, $abad, $b, $bs
        );
      }
    }
  }
}

##--------------------------------------------------------------
## specific tests

##-- matmult with empty row -- https://github.com/moocow-the-bovine/PDL-CCS/issues/14
my $m = identity(3)->set(2,2,0);  # [[1,0,0],[0,1,0],[0,0,0]]
my $v = zeroes(1,3)->set(0,2,1);  # [[0],[0],[1]]
pdlok('matmult with empty row', ($m->toccs x $v)->decode, ($m x $v));

##-- no more type conversion support for null PDLs -- https://github.com/moocow-the-bovine/PDL-CCS/issues/14#issuecomment-2556862635
my $u = zeroes(1, 3);
my $z = ones(1, 3);
pdlok('u*z all missing', ($u->toccs * $z->toccs)->decode, ($u * $z));
pdlok('z*u all missing', ($z->toccs * $u->toccs)->decode, ($z * $u));

done_testing;

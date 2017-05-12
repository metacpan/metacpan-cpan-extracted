# -*- Mode: CPerl -*-
# t/05_binops.t
use Test::More;
BEGIN {
  my $N_BINOPS = 18;
  my $N_TESTS_PER_BINOP  = 8;
  my $N_RUNS_PER_BLOCK = 6;
  my $N_BLOCKS = 5;
  plan(tests=>(
	       $N_BLOCKS*$N_RUNS_PER_BLOCK*$N_TESTS_PER_BINOP*$N_BINOPS
	      ),
       todo=>[]);
  select(STDERR); $|=1; select(STDOUT); $|=1;
}

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


##--------------------------------------------------------------
## basic test

##-- i..(i+8): test_binop($label, $binop_name, $binop_op_or_undef, $swap, $missing_val, $b,$bs)
##   + globals "$a" and "$abad" must always be defined
##   + "$as" is $a->toccs($missing_val);
##   + always tests $PDL_FUNC->($a,$b,$swap) ~ $CCS_FUNC->($as,($b|$bs),$swap)
##   + tests ($a OP $b) ~ ($as OP $(bs|b)) for $swap==0
##   + tests ($b OP $a) ~ ($bs OP $(as|a)) for $swap==1
sub test_binop {
  my ($lab, $op_name, $op_op, $swap, $missing_val, $b,$bs) = @_;
  print "test_binop(name=$op_name, op=", ($op_op||'NONE'), ", swap=$swap, missing=$missing_val)\n";

  my $pdl_func = PDL->can("${op_name}")
    or die("no PDL Ufunc ${op_name} defined!");
  my $ccs_func = PDL::CCS::Nd->can("${op_name}")
    or die("no CCS Ufunc PDL::CCS::Nd::${op_name} defined!");

  $missing_val = 0 if (!defined($missing_val));
  $missing_val = PDL->topdl($missing_val);
  if ($missing_val->isbad) { $a = $a->setbadif($abad); }
  else {
    ##-- the .= line failes under debugger for perl<5.15.1 with:
    ##   : Can't return a temporary from lvalue subroutine at /home/moocow/work/diss/perl/PDL-CCS/CCS/t/05_binops.t line $LINE_NUMBER
    ##   + workaround: assgn($missing_val, $a->where($abad));
    ##   + ... but that's a serious PITA for runtime debugging
    ##   + see https://rt.perl.org/rt3/Public/Bug/Display.html?id=71172 for a perl patch
    $a->where($abad) .= $missing_val;
    $a->badflag(0);
  }

  $b  = PDL->topdl($b);
  $as = $a->toccs($missing_val);
  $bs = $b->toccs($missing_val) if (!defined($bs));

  ##-- test: function syntax
  my $dense_rc = $pdl_func->($a,  $b,  $swap);
  my $ccs_bs   = $ccs_func->($as, $bs, $swap);
  my $ccs_b    = $ccs_func->($as, $b,  $swap);

  isok("$lab:${op_name}:func:b=sparse:missing=$missing_val:swap=$swap:type",
       $ccs_bs->type, $dense_rc->type);
  pdlok("$lab:${op_name}:func:b=sparse:missing=$missing_val:swap=$swap:nzvals",
	$ccs_bs->_nzvals, $dense_rc->indexND($ccs_bs->_whichND));
  isok("$lab:${op_name}:func:b=dense:missing=$missing_val:swap=$swap:type",
       $ccs_b->type, $dense_rc->type);
  pdlok("$lab:${op_name}:func:b=dense:missing=$missing_val:swap=$swap:nzvals",
	$ccs_b->_nzvals, $dense_rc->indexND($ccs_b->_whichND));

  if (defined($op_op)) {
    if (!$swap) {
      eval "\$dense_rc = (\$a  $op_op \$b);";
      eval "\$ccs_bs   = (\$as $op_op \$bs);";
      eval "\$ccs_b    = (\$as $op_op \$b);";
    } else {
      eval "\$dense_rc = (\$b  $op_op \$a);";
      eval "\$ccs_bs   = (\$bs $op_op \$as);";
      eval "\$ccs_b    = (\$bs $op_op \$a);";
    }
    isok("$lab:${op_name}:op=$op_op:b=sparse:missing=$missing_val:swap=$swap:type",
	 $ccs_bs->type, $dense_rc->type);
    pdlok("$lab:${op_name}:op=$op_op:b=sparse:missing=$missing_val:swap=$swap:nzvals",
	  $ccs_bs->_nzvals, $dense_rc->indexND(scalar $ccs_bs->_whichND));
    isok("$lab:${op_name}:op=$op_op:b=dense:missing=$missing_val:swap=$swap:type",
	 $ccs_b->type, $dense_rc->type);
    pdlok("$lab:${op_name}:op=$op_op:b=dense:missing=$missing_val:swap=$swap:nzvals",
	  $ccs_b->_nzvals, $dense_rc->indexND(scalar $ccs_b->_whichND));
  } else {
    isok("$lab:${op_name}:op=NONE:b=sparse:missing=$missing_val:swap=$swap:type (dummy)", 1);
    isok("$lab:${op_name}:op=NONE:b=sparse:missing=$missing_val:swap=$swap:vals (dummy)", 1);
    isok("$lab:${op_name}:op=NONE:b=dense:missing=$missing_val:swap=$swap:type  (dummy)", 1);
    isok("$lab:${op_name}:op=NONE:b=dense:missing=$missing_val:swap=$swap:vals  (dummy)", 1);
  }
}

my @binops = (			##-- *20
	      ##-- Arithmetic
	      ['plus','+'],
	      ['minus','-'],
	      ['mult','*'],
	      ['divide','/'],
	      ['modulo','%'],
	      ['power','**'],

	      ##-- Comparisons
	      [qw(gt >)],
	      [qw(lt <)],
	      [qw(ge >=)],
	      [qw(le <=)],
	      [qw(eq ==)],
	      [qw(ne !=)],
	      [qw(spaceship <=>)],

	      ##-- Logical & bitwise
	      [qw(and2 &)],
	      [qw(or2 |)],
	      [qw(xor ^)],
	      [qw(shiftleft <<)],
	      [qw(shiftright >>)],
	     );

my ($b);

##-- Block 1 : mat * mat
$b = $a->flat->rotate(1)->pdl->reshape($a->dims); ##-- extra pdl() before reshape() avoids realloc() crashes in PDL-2.0.14
foreach $missing (0,127,$BAD) {   ##-- *3
  foreach $swap (0,1) {           ##-- *2
    foreach $op (@binops) {       ##-- *NBINOPS
      if (ref($op)) { test_binop('mat.mat', $op->[0], $op->[1], $swap, $missing, $b); }
      else          { test_binop('mat.mat', $op,      undef,    $swap, $missing, $b); }
    }
  }
}

##-- Block 2 : mat * scalar
$b = PDL->topdl(42);
foreach $missing (0,127,$BAD) {   ##-- *3
  foreach $swap (0,1) {           ##-- *2
    foreach $op (@binops) {       ##-- *NBINOPS
      if (ref($op)) { test_binop('mat.sclr', $op->[0], $op->[1], $swap, $missing, $b); }
      else          { test_binop('mat.sclr', $op,      undef,    $swap, $missing, $b); }
    }
  }
}

##-- Block 3 : mat * row
$b  = sequence($a->dim(0))+1;
foreach $missing (0,127,$BAD) {   ##-- *3
  foreach $swap (0,1) {           ##-- *2
    foreach $op (@binops) {       ##-- *NBINOPS
      if (ref($op)) { test_binop('mat.rv', $op->[0], $op->[1], $swap, $missing, $b); }
      else          { test_binop('mat.rv', $op,      undef,    $swap, $missing, $b); }
    }
  }
}

##-- Block 4 : mat * col
$b  = sequence(1,$a->dim(1))+1;
$bs = $b->flat->toccs->dummy(0,1);
foreach $missing (0,127,$BAD) {   ##-- *3
  foreach $swap (0,1) {           ##-- *2
    foreach $op (@binops) {       ##-- *NBINOPS
      if (ref($op)) { test_binop('mat.cv', $op->[0], $op->[1], $swap, $missing, $b,$bs); }
      else          { test_binop('mat.cv', $op,      undef,    $swap, $missing, $b,$bs); }
    }
  }
}

##-- Block 5 : col * row
my @save = ($a,$abad);
$b  = sequence(1,$a->dim(1))+1;
$bs = $b->flat->toccs->dummy(0,1);
$a  = sequence($a->dim(0),1);
$abad = ($a==0);
foreach $missing (0,127,$BAD) {   ##-- *3
  foreach $swap (0,1) {           ##-- *2
    foreach $op (@binops) {       ##-- *NBINOPS
      if (ref($op)) { test_binop('rv.cv', $op->[0], $op->[1], $swap, $missing, $b,$bs); }
      else          { test_binop('rv.cv', $op,      undef,    $swap, $missing, $b,$bs); }
    }
  }
}

($a,$abad) = @save;


print "\n";
# end of t/*.t


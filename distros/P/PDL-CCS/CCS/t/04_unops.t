# -*- Mode: CPerl -*-
# t/04_unops.t
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
## basic test

##-- i..(i+4): test_unop($unop_name, $unop_op_or_undef, $missing_val)
sub test_unop {
  my ($op_name, $op_op, $missing_val) = @_;
  print "test_unop($op_name, ", ($op_op||'NONE'), ", $missing_val)\n";

  my $pdl_func = PDL->can("${op_name}")
    or die("no PDL Ufunc ${op_name} defined!");
  my $ccs_func = PDL::CCS::Nd->can("${op_name}")
    or die("no CCS Ufunc PDL::CCS::Nd::${op_name} defined!");

  $missing_val = 0 if (!defined($missing_val));
  $missing_val = PDL->topdl($missing_val);
  if ($missing_val->isbad) { $a = $a->setbadif($abad); }
  else                     { $a->where($abad) .= $missing_val; $a->badflag(0); }

  my $ccs      = $a->toccs($missing_val);
  my $dense_rc = $pdl_func->($a);
  my $ccs_rc   = $ccs_func->($ccs);

  isok("${op_name}:func:missing=$missing_val:type", $ccs_rc->type, $dense_rc->type);
  pdlok("${op_name}:func:missing=$missing_val:vals", $ccs_rc->decode, $dense_rc);

  if (defined($op_op)) {
    eval "\$dense_rc = $op_op \$a";
    eval "\$ccs_rc   = $op_op \$ccs";
    isok("${op_name}:op=$op_op:missing=$missing_val:type", $ccs_rc->type, $dense_rc->type);
    pdlok("${op_name}:op=$op_op:missing=$missing_val:vals", $ccs_rc->decode, $dense_rc);
  } else {
    isok("${op_name}:op=NONE:missing=$missing_val:type (dummy)", 1);
    isok("${op_name}:op=NONE:missing=$missing_val:vals (dummy)", 1);
  }
}

for my $missing (0,1,255,$BAD) { ##-- *4
  for my $op (
	       [qw(bitnot ~)],
	       [qw(not !)],
	       qw(sqrt abs sin cos log log10), 'exp' ##-- *9
	      )
    {
      if (ref($op)) { test_unop(@$op, $missing); }
      else          { test_unop($op, undef, $missing); }
    }
}

done_testing;

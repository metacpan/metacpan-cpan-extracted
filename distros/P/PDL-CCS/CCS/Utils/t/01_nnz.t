# -*- Mode: CPerl -*-
# t/01_nnz.t: test n nonzeros
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

## 1--4: test nnz
my $p = pdl(double, [ [0,1,2], [0,0,1e-7], [0,1,0], [1,1,1] ]);
isok("nnz(0)",     $p->slice(",(0)")->nnz, 2);
isok("nnz(flat)",  $p->flat->nnz, 7);
isok("nnza(flat,1e-8)", $p->flat->nnza(1e-8), 7);
isok("nnza(flat,1e-5)", $p->flat->nnza(1e-5), 6);
isok("nnza(flat:long,1)",  $p->flat->long->nnza(1), 1);

done_testing;

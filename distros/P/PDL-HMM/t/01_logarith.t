# -*- Mode: CPerl -*-
# t/01_logarith.t: test log arithmetic
use Test::More tests => 11;

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
use PDL::HMM;

##----------------------------------------------------------------------
## tests

## 1: test logzero
pdlapprox_nodims("exp(logzero)==0", exp(logzero), 0);

## 2--3: test log add
sub addlogs { my ($x,$y)=@_; return exp(logadd(log(pdl(double,$x)),log(pdl(double,$y)))); }
pdlapprox_nodims("addlogs(2,3)==5", addlogs(2, 3), 5);
pdlapprox_nodims("addlogs(0,1)==1", addlogs(0,42), 42);

## 4--5: test logsumover
sub sumlogs { return exp(logsumover(pdl(double,\@_)->log)); }
pdlapprox_nodims("sumlogs(2,3,4)==9", sumlogs(2,3,4), 9);
pdlapprox_nodims("sumlogs(0..10)==55", sumlogs(0..10), 55);

## 6-8: test log difference
sub sublogs { my ($x,$y)=@_; return exp(logdiff(log(pdl(double,$x)),log(pdl(double,$y)))); }
pdlapprox_nodims("logdiff(1,0)==1", sublogs(1,0), 1);
pdlapprox_nodims("logdiff(100,99)==1", sublogs(100,99), 1);
pdlapprox_nodims("logdiff(1e-10,1e-11)", sublogs(1e-10,1e-11), 9e-11, 1e-12);

##-- 9-11: symmetric difference (sign is ignored)
pdlapprox_nodims("logdiff(0,1)==1", sublogs(0,1), 1);
pdlapprox_nodims("logdiff(99,100)==1", sublogs(99,100), 1);
pdlapprox_nodims("logdiff(1e-11,1e-10)", sublogs(1e-11,1e-10), 9e-11, 1e-12);

print "\n";
# end of t/01_ini.t


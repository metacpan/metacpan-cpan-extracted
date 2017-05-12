# -*- Mode: CPerl -*-
# t/04_types.t: test PDL::VectorValued type-wrappers
use Test::More tests=>2;

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
#use PDL::VectorValued::Dev;

##--------------------------------------------------------------
## data

## 1..2: types
isok("isa(vv_indx,PDL::Type)", UNIVERSAL::isa(vv_indx,'PDL::Type'));
if (defined(&PDL::indx)) {
  isok("vv_indx == PDL::indx (PDL >= v2.007)", vv_indx(), PDL::indx);
} else {
  isok("vv_indx == PDL::long (PDL < v2.007)", vv_indx(), PDL::long);
}

print "\n";
# end of t/04_types.t


# -*- Mode: CPerl -*-
# t/05_vcos.t: test PDL::VectorValued vector-cosine
use Test::More tests=>6;

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

##-- common vars
use version;
my $HAVE_PDL_2_014 = version->parse($PDL::VERSION) >= version->parse("2.014");

##--------------------------------------------------------------
## tests

my $a = pdl([[1,2,3,4],[1,2,2,1],[-1,-2,-3,-4]]);
my $b = pdl([1,2,3,4]);
my $c_want = pdl([1,0.8660254,-1]);

##-- 1..2: vcos: basic
pdlapprox("vv_vcos:flat", $a->vv_vcos($b), $c_want, 1e-4);
pdlapprox("vv_vcos:threaded", $a->vv_vcos($b->slice(",*3")), $c_want->slice(",*3"), 1e-4);

##-- 3: vcos: nullvec: a
my $a0 = $a->pdl;
my $nan = $^O =~ /MSWin32/i ? ((99**99)**99) - ((99**99)**99) : 'nan';
(my $tmp=$a0->slice(",1")) .= 0;
pdlapprox("vv_vcos:nullvec:a:nan", $a0->vv_vcos($b), pdl([1,$nan,-1]), 1e-4);

##-- 4: vcos: nullvec: b
my $b0 = $b->zeroes;
isok("vv_vcos:nullvec:b:all-nan", all($a->vv_vcos($b0)->isfinite->not));

##-- 5-6: bad values
my @chkbad =
  (
   ##-- 5: a~bad
   ["vv_vcos:bad:a" => sub {
      my $abad       = $a->pdl->setbadif($a->abs==2);
      my $abad_cwant = pdl([0.93094,0.64549,-0.93094]);
      pdlapprox("vv_vcos:bad:a", $abad->vv_vcos($b), $abad_cwant, 1e-4);
    }],

   ##-- 6: b~bad
   ["vv_vcos:bad:b" => sub {
      my $bbad       = $b->pdl->setbadif($b->xvals==2);
      my $bbad_cwant = pdl([0.8366,0.6211,-0.8366]);
      pdlapprox("vv_vcos:bad:b", $a->vv_vcos($bbad), $bbad_cwant, 1e-4);
    }],
  );

my $skipbad = (!$PDL::Bad::Status ? "no bad-value support in PDL"
	       : (!$HAVE_PDL_2_014 ? "PDL >= v2.014 only"
		  : 0));
foreach my $badtest (@chkbad) {
  skipordo($badtest->[0], $skipbad, $badtest->[1]);
}


print "\n";
# end of t/05_vcos.t

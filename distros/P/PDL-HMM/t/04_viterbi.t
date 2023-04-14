# -*- Mode: CPerl -*-
# t/04_viterbi.t: test Viterbi algorithm
use Test::More tests => 6;

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

##-- test model 1:
my ($pi,$a,$b);
sub testmodel1 {
  $pi = pdl(double,  [.6, .4])->log;

  $a = pdl(double,   [[.5, .2],
		      [.3, .5]])->log;

  #$omega = pdl(double,[.2, .3])->log;

  $b = pdl(double, [[.8, .2], [.2, .8]])->log;

}

##-- tests: model 1
my ($delta,$psi,$path,$o);
sub vtest {
  my $o = shift;
  ($delta,$psi) = hmmviterbi($a,$b,$pi, $o);
  $path = hmmpath($psi, sequence(long,$delta->dim(0)));
}

##-- 1--3: expect for o=[0,1]
testmodel1();
my ($o);
vtest($o=pdl(long,[0,1]));

pdlapprox("o=[0,1]: delta", $delta, pdl(double, [[.48,.08],[.048,.1152]])->log);
pdlok("o=[0,1]: psi", $psi, pdl(long, [[0,0],[0,0]]));
pdlok("o=[0,1]: path", $path, pdl(long, [[0,0],[0,1]]));

##-- 4--6 expect for o=[0,1,0]
vtest($o=pdl(long,[0,1,0]));

pdlapprox("o=[0,1,0]: delta", $delta, pdl(double, [[.48,.08],[.048,.1152],[.0192,.01152]])->log);
pdlok("o=[0,1,0]: psi", $psi, pdl(long, [[0,0],[0,0],[0,1]]));
pdlok("o=[0,1,0]: path", $path, pdl(long, [[0,0,0],[0,1,1]]));

print "\n";
# end of t/XX_yyyy.t

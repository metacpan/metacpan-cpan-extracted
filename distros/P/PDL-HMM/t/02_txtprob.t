# -*- Mode: CPerl -*-
# t/02_txtprob.t: test text-probability
use Test::More tests => 4;


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

## test model 1:
my ($pi,$a,$omega,$b);
sub testmodel1 {
  #$n = 2; $k = 2;

  $pi = pdl(double, [.5,.5])->log;

  $a = pdl(double,    [[.4,.4],
		       [.4,.4]])->log;
  $omega = pdl(double, [.2,.2])->log;

  $b = pdl(double, [[1,0],
		    [0,1]])->log;
}

my ($fw,$fwtp, $bw,$bwtwp);
sub testtp {
  my $o=shift;
  $fw = hmmfw($a,$b,$pi, $o);
  $fwtp = logsumover($fw->slice(",-1") + $omega);

  $bw   = hmmbw($a,$b,$omega, $o);
  $bwtp = logsumover($bw->slice(",0") + $pi + $b->slice(",(".$o->at(0).")"));
}


##-- 1--4: model 1
testmodel1;
testtp(pdl([0,1]));

pdlapprox("model-1: alpha",   $fw, pdl(double, [[1/2,0],[0,1/5]])->log);
pdlapprox("model-1: beta",    $bw, pdl(double, [[2/25,2/25],[1/5,1/5]])->log);
pdlapprox_nodims("model-1: txtprob", $fwtp->exp, 1/25);
pdlapprox("model-1: p_alpha~p_beta", $fwtp, $bwtp);

print "\n";
# end of t/XX_yyyy.t


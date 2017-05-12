# -*- Mode: CPerl -*-
# t/03_baum.t: test Baum-Welch re-estimation
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

##-- test model 1:
my ($pi,$a,$omega,$b);
sub testmodel1 {
  $pi = pdl(double, [.5,.5])->log;

  $a = pdl(double,    [[.4,.4],
		       [.4,.4]])->log;
  $omega = pdl(double, [.2,.2])->log;

  $b = pdl(double, [[1,0],[0,1]])->log;
}

my ($ea,$eb,$epi,$eomega,$etp);
sub emreset {
  ##-- re-est: base
  ($ea,$eb,$epi,$eomega) = hmmexpect0($a,$b,$pi,$omega);
  $etp                   = logzero;
}

my (@os);
sub emE {
  foreach my $o (@os) {
    ##-- alpha, beta
    my $fw = hmmfw($a,$b,$pi,$o);
    my $bw = hmmbw($a,$b,$omega,$o);

    ##-- text-prob
    $etp->inplace->logadd(logsumover($fw->slice(",-1") + $omega));

    ##-- re-est: expect
    hmmexpect($a,$b,$pi,$omega, $o, $fw,$bw, $ea,$eb,$epi,$eomega);
  }
  $etp -= log(scalar(@os));
}

my ($ahat,$bhat,$pihat,$omegahat, $etphat,$etpdiff);
sub emM {
  ##-- re-est: maximimize
  ($ahat,$bhat,$pihat,$omegahat) = hmmmaximize($ea,$eb,$epi,$eomega);

  ##-- re-est: get new textprob
  $etphat = logzero;
  foreach $o (@os) {
    ##-- alpha
    $fw = hmmfw($ahat,$bhat,$pihat, $o);
    $etphat->inplace->logadd(logsumover($fw->slice(",-1") + $omegahat));
  }
  $etphat -= log(scalar(@os));

  ##-- now can compare text-probs: $etphat -- $etp
  $etpdiff = $etphat->logdiff($etp);
}

my ($etp_want,$ea_want,$eb_want,$epi_want,$eomega_want);
my ($etphat_want,$etpdiff_want,$ahat_want,$omegahat_want,$bhat_want,$pihat_want);
sub wantmodel1 {
  ##-- inputs
  @os = ((map { pdl([0,1]) } (1..4)),
	 (map { pdl([1,0]) } (1..2)));

  ##-- model 2: want: text-prob
  $etp_want = pdl(double, log(1/25));

  ##-- test: want: a
  my ($tmp);
  $ea_want = pdl(double, [[0,2], [4,0]])->log;
  ($tmp=$ea_want->where($ea_want->isfinite->not)) .= logzero;
  $eb_want = pdl(double, [[6,0], [0,6]])->log;
  ($tmp=$eb_want->where($eb_want->isfinite->not)) .= logzero;
  $epi_want = pdl(double, [4,2])->log;
  $eomega_want = pdl(double, [2,4])->log;

  ##-- model 2: want: etphat
  $etphat_want  = pdl(double, log(.209876));
  $etpdiff_want = pdl(double, log(abs(exp($etp_want)-exp($etphat_want))));

  ##-- model 2: want: maximized
  $ahat_want  = pdl(double,   [[0,  1/3],
			       [2/3,  0]])->log;
  ($tmp=$ahat_want->where($ahat_want->isfinite->not)) .= logzero;

  $omegahat_want = pdl(double, [1/3,2/3])->log;

  $bhat_want  = pdl(double, [[1,0],[0,1]])->log;
  ($tmp=$bhat_want->where($bhat_want->isfinite->not)) .= logzero;

  $pihat_want = pdl(double, [2/3,1/3])->log;
}

##-- tests: model 1
testmodel1();
wantmodel1();
emreset();
emE();
emM();

##-- 1--5: expect
pdlapprox_nodims("E(p(O))",  $etp,$etp_want);
pdlapprox("E(f(i-->j))", $ea, $ea_want);
pdlapprox("E(f(k @ j))", $eb, $eb_want);
pdlapprox("E(f(i | BOS))", $epi, $epi_want);
pdlapprox("E(f(EOS | i))", $eomega, $eomega_want);

##-- 6--11: maximize
pdlapprox_nodims("E(^p(O))",   $etphat_want, $etphat);
pdlapprox_nodims("E(^p)-E(p)", $etpdiff_want, $etpdiff);
pdlapprox("Ahat",       $ahat, $ahat_want);
pdlapprox("Bhat",       $bhat, $bhat_want);
pdlapprox("pihat",      $pihat, $pihat_want);
pdlapprox("omegahat",   $omegahat, $omegahat_want);

print "\n";
# end of t/XX_yyyy.t


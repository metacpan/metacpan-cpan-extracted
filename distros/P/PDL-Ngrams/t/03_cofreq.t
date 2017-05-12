# -*- Mode: CPerl -*-
# t/03_cofreq.t: test ng_cofreq
use Test::More tests => 8;

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
use PDL::Ngrams;

##--------------------------------------------------------------
## Base data
my $toks   = pdl(long,[1, 1,2, 1,2,3, 1,2,3,4   ]);
my $beg    = pdl(long,[0, 1,   3,     6         ]);
my $bos1   = pdl(long,[-1]);

my $atoks  = $toks->slice("*1,")->append($toks->slice("*1,")*10)->append($toks->slice("*1,")*100);
my $abos1  = $bos1->append($bos1*10)->append($bos1*100);
my $N      = 2;

##--------------------------------------------------------------
## ng_cofreq()

## 1..4: ng_cofreq: 1d token vector, N=2, +delim
my ($ngfreq,$ngelts) = ng_cofreq($toks->slice("*$N,"), boffsets=>$beg, delims=>$bos1->slice("*$N,"));

my $ngfreq_1d_n2_want = pdl(long,[4,1,3,1,2,1,1]);
my $ngelts_1d_n2_want = pdl(long,[[-1,1],[1,-1],[1,2],[2,-1],[2,3],[3,-1],[3,4]]);
isok("ng_cofreq(toks:1d,N:2,+delims):freq:dims", cmp_dims($ngfreq, $ngfreq_1d_n2_want));
isok("ng_cofreq(toks:1d,N:2,+delims):elts:dims", cmp_dims($ngelts, $ngelts_1d_n2_want));
pdlok("ng_cofreq(toks:1d,N:2,+delims):freq:vals", $ngfreq, $ngfreq_1d_n2_want);
pdlok("ng_cofreq(toks:1d,N:2,+delims):elts:vals", $ngelts, $ngelts_1d_n2_want);

## 5..8: ng_cofreq: 2d token vector, N=2, +delim
($ngfreq,$ngelts) = ng_cofreq($atoks->slice(",*$N,"), boffsets=>$beg, delims=>$abos1->slice(",*$N,*1"));

my $ngfreq_2d_n2_want = $ngfreq_1d_n2_want;
my $ngelts_2d_n2_want = ($ngelts_1d_n2_want
			  ->append($ngelts_1d_n2_want*10)
			  ->append($ngelts_1d_n2_want*100)
			  ->reshape($N,3,7)
			  ->xchg(0,1));
isok("ng_cofreq(toks:2d,N:2,+delims):freq:dims", cmp_dims($ngfreq, $ngfreq_2d_n2_want));
isok("ng_cofreq(toks:2d,N:2,+delims):elts:dims", cmp_dims($ngelts, $ngelts_2d_n2_want));
pdlok("ng_cofreq(toks:2d,N:2,+delims):freq:vals", $ngfreq, $ngfreq_2d_n2_want);
pdlok("ng_cofreq(toks:2d,N:2,+delims):elts:vals", $ngelts, $ngelts_2d_n2_want);


print "\n";
# end of t/03_cofreq.t


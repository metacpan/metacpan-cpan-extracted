# -*- Mode: CPerl -*-
# t/02_rotate.t: test ng_rotate
use Test::More tests => 3;

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
my $toks2d = $toks->slice("*1,")->append((10*$toks)->slice("*1,"));
my ($N);

##--------------------------------------------------------------
## ng_rotate()

## 1: rotate (1d token vector, N=2)
$N=2;
my $rtoks1d_n2      = ng_rotate($toks->slice("*$N,"));
my $rtoks1d_n2_want = pdl(long, [ [1,1],  [1,2],[2,1],  [1,2],[2,3],[3,1],  [1,2],[2,3],[3,4] ]);
pdlok("ng_rotate(toks:1d,N:2)", $rtoks1d_n2, $rtoks1d_n2_want);

## 2: rotate (1d token vector, N=3)
$N=3;
my $rtoks1d_n3      = ng_rotate($toks->slice("*$N,"));
my $rtoks1d_n3_want = pdl(long,[ [1,1,2],  [1,2,1],[2,1,2],  [1,2,3],[2,3,1],[3,1,2],  [1,2,3],[2,3,4] ]);
pdlok("ng_rotate(toks:1d,N:3)", $rtoks1d_n3, $rtoks1d_n3_want);

## 3: rotate (2d token vector, N=2)
$N=2;
my $rtoks2d_n2      = ng_rotate($toks2d->slice(":,*$N,:"));
#my $rtoks2d_n2_want = $rtoks1d_n2_want->cat($rtoks1d_n2_want*10)->mv(-1,0)
my $rtoks2d_n2_want = pdl(long, [ [[1,10],[1,10]],
				   [[1,10],[2,20]],[[2,20],[1,10]],
				   [[1,10],[2,20]],[[2,20],[3,30]],[[3,30],[1,10]],
				   [[1,10],[2,20]],[[2,20],[3,30]],[[3,30],[4,40]],
				 ]);
pdlok("ng_rotate(toks:2d,N:2)", $rtoks2d_n2, $rtoks2d_n2_want);

print "\n";
# end of t/02_rotate.t


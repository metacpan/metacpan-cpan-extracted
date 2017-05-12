# -*- Mode: CPerl -*-
# t/01_delimit.t: test ng_delimit(), ng_undelimit()
use Test::More tests => 10;

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
my $toks2d = $toks->slice("*1,")->append((10*$toks)->slice("*1,"))->xchg(0,1);
my $bos1   = pdl(long,[-1]);
my $bos2   = pdl(long,[-2,-1]);

##--------------------------------------------------------------
## ng_delimit()

## 1: delimit (1d token vector, 1 delimiter)
my $dtoks1 = ng_delimit($toks,$beg,$bos1);
my $dtoks1_want = pdl(long,[-1,  1, -1,  1,  2, -1,  1,  2,  3, -1,  1,  2,  3,  4]);
pdlok("ng_delimit(toks:1d,nDelim:1)", $dtoks1, $dtoks1_want);

## 2: delimit (1d token vector, 2 delimiters)
my $dtoks2 = ng_delimit($toks,$beg,$bos2);
  my $dtoks2_want = pdl(long,[-2,-1,  1, -2,-1,  1,  2, -2,-1,  1,  2,  3, -2,-1,  1,  2,  3,  4]);
pdlok("ng_delimit(toks:1d,nDelim:2)", $dtoks2, $dtoks2_want);

## 3: delimit (2d token vector, 1d offsets & delmiters, 1 delimiter)
my $dtoks1_2d = ng_delimit($toks2d,$beg,$bos1);
my $dtoks1_2d_want = pdl(long,[[-1,  1, -1,  1,  2, -1,  1,  2,  3, -1,  1,  2,  3,  4],
			       [-1, 10, -1, 10, 20, -1, 10, 20, 30, -1, 10, 20, 30, 40]]);
pdlok("ng_delimit(toks:2d,offsets:1d,nDelim:1)", $dtoks1_2d, $dtoks1_2d_want);

## 4: delimit (2d token vector, 1d offsets & delimiters, 2 delimiters)
my $dtoks2_2d = ng_delimit($toks2d,$beg,$bos2);
my $dtoks2_2d_want = pdl(long,[[-2,-1,  1, -2,-1,  1,  2, -2,-1,  1,  2,  3, -2,-1,  1,  2,  3,  4],
			       [-2,-1, 10, -2,-1, 10, 20, -2,-1, 10, 20, 30, -2,-1, 10, 20, 30, 40]]);
pdlok("ng_delimit(toks:2d,offsets:1d,nDelim=2)", $dtoks2_2d, $dtoks2_2d_want);

## 5: delimit (2d token vector, 2d offsets & delimiters, 2 delimiters)
my $dtoks2_2d_sl = ng_delimit($toks2d,$beg->slice(",*2"),$bos2->slice(",*2"));
my $dtoks2_2d_sl_want = $dtoks2_2d_want;
pdlok("ng_delimit(toks:2d,offsets:2d,nDelim=2)", $dtoks2_2d_sl, $dtoks2_2d_sl_want);

##--------------------------------------------------------------
## ng_undelimit()

## 6
#my $dtoks1 = ng_delimit($toks,$beg,$bos1);
my $udtoks1 = ng_undelimit($dtoks1,$beg,$bos1->dim(0));
pdlok("ng_undelimit(toks:1d,nDelims:1)", $udtoks1, $toks);

## 7
#my $dtoks2  = ng_delimit($toks,$beg,$bos2);
my $udtoks2 = ng_undelimit($dtoks2,$beg,$bos2->dim(0));
pdlok("ng_undelimit(toks:1d,nDelims:2)", $udtoks2, $toks);

## 8
#my $dtoks1_2d  = ng_delimit($toks2d,$beg,$bos1);
my $udtoks1_2d = ng_undelimit($dtoks1_2d,$beg,$bos1->dim(0));
pdlok("ng_undelimit(toks:2d,offsets:1d,nDelims:1)", $udtoks1_2d, $toks2d);

## 9
#my $dtoks2_2d  = ng_delimit($toks2d,$beg,$bos2);
my $udtoks2_2d = ng_undelimit($dtoks2_2d,$beg,$bos2->dim(0));
pdlok("ng_undelimit(toks:2d,offsets:1d,nDelims:2)", $udtoks2_2d, $toks2d);

## 10
#my $dtoks2_2d_sl  = ng_delimit($toks2d,$beg->slice(",*2"),$bos2->slice(",*2"));
my $udtoks2_2d_sl = ng_undelimit($dtoks2_2d_sl,$beg->slice(",*2"),$bos2->dim(0));
pdlok("ng_undelimit(toks:2d,offsets:2d,nDelims:2)", $udtoks2_2d_sl, $toks2d);


print "\n";
# end of t/01_delimit.t


# -*- Mode: CPerl -*-
# t/02_encode.t: test ccs encoding
use Test::More;
use strict;
use warnings;

##-- common subs
my $TEST_DIR;
BEGIN {
  use File::Basename;
  use Cwd;
  $TEST_DIR = Cwd::abs_path dirname( __FILE__ );
  eval qq{use lib ("$TEST_DIR/$_/blib/lib","$TEST_DIR/$_/blib/arch");} foreach (qw(..));
  do "$TEST_DIR/common.plt" or  die("$0: failed to load $TEST_DIR/common.plt: $@");
}

##-- common modules
use PDL;
use PDL::CCS;

##-- setup
my $p = pdl(double, [
		     [10,0,0,0,-2,0],
		     [3,9,0,0,0,3],
		     [0,7,8,7,0,0],
		     [3,0,8,7,5,0],
		     [0,8,0,9,9,13],
		     [0,4,0,0,2,-1],
		    ]);
my $nnz = $p->flat->nnz;

my $want_ptr=pdl(long,[0,3,7,9,12,16]);
my $want_rowids=pdl(long,[0,1,3,1,2,4,5,2,3,2,3,4,0,3,4,5,1,4,5]);
my $want_nzvals=pdl(long,[10,3,3,9,7,8,4,8,8,7,7,9,-2,5,9,2,3,13,-1]);

##-- 1--3: test ccsencodefull()
my ($ptr,$rowids,$nzvals);
ccsencodefull($p,
	      $ptr=zeroes(long,$p->dim(0)),
	      $rowids=zeroes(long,$nnz),
	      $nzvals=zeroes($p->type, $nnz));

pdlok("encodefull():ptr", $ptr, $want_ptr);
pdlok("encodefull():rowids", $rowids, $want_rowids);
pdlok("encodefull():nzvals", $nzvals, $want_nzvals);

##-- 4--6: test ccsencode()
($ptr,$rowids,$nzvals) = ccsencode($p);
pdlok("encode():ptr", $ptr, $want_ptr);
pdlok("encode():rowids", $rowids, $want_rowids);
pdlok("encode():nzvals", $nzvals, $want_nzvals);


##-- 7--9: test ccsencodefulla()
my $eps=2.5;
my $want_ptr_a=pdl(long,[0,3,7,9,12,14]);
my $want_rowids_a=pdl(long,[0,1,3,1,2,4,5,2,3,2,3,4,3,4,1,4]);
my $want_nzvals_a=pdl(long,[10,3,3,9,7,8,4,8,8,7,7,9,5,9,3,13]);
$nnz = $p->flat->nnza($eps);
ccsencodefulla($p, $eps,
	       $ptr=zeroes(long,$p->dim(0)),
	       $rowids=zeroes(long,$nnz),
	       $nzvals=zeroes($p->type, $nnz));
pdlok("encodefulla():ptr", $ptr, $want_ptr_a);
pdlok("encodefulla():rowids", $rowids, $want_rowids_a);
pdlok("encodefulla():nzvals", $nzvals, $want_nzvals_a);

##-- 10--12: : test ccsencodea()
($ptr,$rowids,$nzvals) = ccsencodea($p,$eps);
pdlok("encodea():ptr", $ptr, $want_ptr_a);
pdlok("encodea():rowids", $rowids, $want_rowids_a);
pdlok("encodea():nzvals", $nzvals, $want_nzvals_a);

##-- 13..15 : test ccsencodefull_i2d()
#($pwcols,$pwrows) = $p->whichND; ##-- in pdl-2.4.9_014: WARNING - deprecated list context for whichND (may switch to scalar case soon)
my ($pwcols,$pwrows) = $p->whichND->xchg(0,1)->dog;
my $pwvals           = $p->index2d($pwcols,$pwrows);
$nnz                = $pwvals->nelem;
ccsencodefull_i2d($pwcols,$pwrows,$pwvals,
		  $ptr=zeroes(long,$p->dim(0)),
		  $rowids=zeroes(long,$nnz),
		  $nzvals=zeroes($p->type, $nnz));
pdlok("encodefull_i2d():ptr",    $ptr, $want_ptr);
pdlok("encodefull_i2d():rowids", $rowids, $want_rowids);
pdlok("encodefull_i2d():nzvals", $nzvals, $want_nzvals);

##-- 16..18 : test ccsencode_i2d()
($ptr,$rowids,$nzvals) =  ccsencode_i2d($pwcols,$pwrows,$pwvals);
pdlok("encode_i2d():ptr",    $ptr,$want_ptr);
pdlok("encode_i2d():rowids", $rowids,$want_rowids);
pdlok("encode_i2d():nzvals", $nzvals,$want_nzvals);

##-- 19..21 : test ccsencodefull_i()
my $pwhich = $p->which;
$pwvals    = $p->flat->index($pwhich);
$nnz       = $pwvals->nelem;
ccsencodefull_i($pwhich, $pwvals,
		$ptr   =zeroes(long,$p->dim(0)),
		$rowids=zeroes(long,$nnz),
		$nzvals=zeroes($p->type, $nnz));

pdlok("encodefull_i():ptr",    $ptr,$want_ptr);
pdlok("encodefull_i():rowids", $rowids,$want_rowids);
pdlok("encodefull_i():nzvals", $nzvals,$want_nzvals);

##-- 22..24 : test ccsencode_i()
my $N = $p->dim(0);
($ptr,$rowids,$nzvals) = ccsencode_i($pwhich, $pwvals, $N);

pdlok("encode_i():ptr",    $ptr,$want_ptr);
pdlok("encode_i():rowids", $rowids,$want_rowids);
pdlok("encode_i():nzvals", $nzvals,$want_nzvals);


##-- 25 : test ccsdecodecols (single col)
my $M = $p->dim(1);
($ptr,$rowids,$nzvals) = ccsencode($p);

my $col0 = ccsdecodecols($ptr,$rowids,$nzvals, 0,0);
pdlok("decodecols(0)", $col0,$p->slice("0,"));

##-- 26 : test ccsdecodecols (full)
my $dense = ccsdecodecols($ptr,$rowids,$nzvals, sequence($p->dim(0)),0);
pdlok("decodecols(all)", $dense,$p);


##-- 27 : test decodefull()
my $p2 = zeroes($p->type,$p->dims);
ccsdecodefull($ptr,$rowids,$nzvals, $p2);
pdlok("decodefull()", $p,$p2);

##-- 28 : test decode()
$p2 = ccsdecode($ptr,$rowids,$nzvals);
pdlok("decode()", $p,$p2);

done_testing;

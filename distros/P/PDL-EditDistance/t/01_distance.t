# -*- Mode: CPerl -*-
# t/01_distance.t: test edit distance
use Test::More tests => 31;

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
use PDL::EditDistance;

##---------------------------------------------------------------------
## 1..4: _edit_pdl()
sub test_edit_pdl {
  my $s = 'ABC';
  my $l = [unpack('C*',$s)];
  my $p = pdl(byte,$l);
  my $s_pdl = PDL::EditDistance::_edit_pdl($s);
  my $l_pdl = PDL::EditDistance::_edit_pdl($l);
  my $p_pdl = PDL::EditDistance::_edit_pdl($p);
  my $pdl_want = pdl [0,65,66,67];
  pdlok("_edit_pdl(pdl)",    $p_pdl, $pdl_want);
  pdlok("_edit_pdl(array)",  $l_pdl, $pdl_want);
  pdlok("_edit_pdl(string)", $s_pdl, $pdl_want);
  ##
  my $us = "\x{166}\x{20ac}\x{17f}\x{167}";  ##-- Ŧ€ſŧ
  utf8::upgrade($us) if (!utf8::is_utf8($us));
  my $us_pdl = PDL::EditDistance::_edit_pdl($us);
  my $updl_want = pdl [0,0x166,0x20ac,0x17f,0x167];
  pdlok("_edit_pdl(utf-8 string)", $us_pdl, $updl_want);
}
test_edit_pdl();

##---------------------------------------------------------------------
## util: makepdls
my ($a,$b,$a1,$b1);
sub makepdls {
  my ($s1,$s2) = ('GUMBO','GAMBOL');
  $a = pdl(byte,[unpack('C*',$s1)]);
  $b = pdl(byte,[unpack('C*',$s2)]);

  ##-- the following makes some combinations of perl + pdl choke later on; cf RT #76461, #76577
  ##   - it *ought* to work, but it's not my place to test it here
  #my $a1 = $a->flat->reshape($a->nelem+1)->rotate(1);
  #my $b1 = $b->flat->reshape($b->nelem+1)->rotate(1);

  ##-- ... instead, we can create the buggers here this way (less thread-able):
  $a1 = zeroes(byte,1)->append($a);
  $b1 = zeroes(byte,1)->append($b);
}


##---------------------------------------------------------------------
## 5..8: edit_costs_static()
sub test_edit_costs_static {
  makepdls;
  my ($costsMatch,$costsIns,$costsDel,$costsSubst) = edit_costs_static(long,$a->nelem,$b->nelem, 0,1,1,2);
  my $costsMatch_want = zeroes(byte,$a->nelem+1,$b->nelem+1);
  my $costsIns_want   = zeroes(byte,$a->nelem+1,$b->nelem+1) +1;
  my $costsDel_want   = $costsIns_want;
  my $costsSubst_want = zeroes(byte,$a->nelem+1,$b->nelem+1) +2;
  pdlok("costs_static: match", $costsMatch, $costsMatch_want);
  pdlok("costs_static:   ins", $costsIns, $costsIns_want);
  pdlok("costs_static:   del", $costsDel, $costsDel_want);
  pdlok("costs_static: subst", $costsSubst, $costsSubst_want);
}
test_edit_costs_static();


##---------------------------------------------------------------------
## 9..10: test_distance_full: distance matrix full
sub test_distance_full {
  makepdls;
  my @costs   =  edit_costs_static(double, $a->nelem,$b->nelem, 0,1,1,1);
  my $dmat    = _edit_distance_full($a1,$b1,@costs);
  my $dmat2   =  edit_distance_full($a,$b,@costs);
  my $dmat_want = pdl([
			[0, 1, 2, 3, 4, 5],
			[1, 0, 1, 2, 3, 4],
			[2, 1, 1, 2, 3, 4],
			[3, 2, 2, 1, 2, 3],
			[4, 3, 3, 2, 1, 2],
			[5, 4, 4, 3, 2, 1],
			[6, 5, 5, 4, 3, 2],
		       ]);
  pdlok("_edit_distance_full", $dmat, $dmat_want);
  pdlok("edit_distance_full", $dmat2, $dmat_want);
}
test_distance_full;

##---------------------------------------------------------------------
## 11..12: test_distance_static: distance matrix, static
sub test_distance_static {
  makepdls;
  my @costs   = map { pdl(double,$_) } (0,1,1,1);
  my $dmat    = _edit_distance_static($a1,$b1,@costs);
  my $dmat2   =  edit_distance_static($a,$b,@costs);
  my $dmat_want = pdl([
			[0, 1, 2, 3, 4, 5],
			[1, 0, 1, 2, 3, 4],
			[2, 1, 1, 2, 3, 4],
			[3, 2, 2, 1, 2, 3],
			[4, 3, 3, 2, 1, 2],
			[5, 4, 4, 3, 2, 1],
			[6, 5, 5, 4, 3, 2],
		       ]);
  pdlok("_edit_distance_static", $dmat, $dmat_want);
  pdlok("edit_distance_static", $dmat2, $dmat_want);
}
test_distance_static;


##---------------------------------------------------------------------
## 13..16: test_align: alignment matrix
sub test_align_full {
  makepdls;
  my @costs = edit_costs_static(double, $a->nelem,$b->nelem, 0,1,1,1);
  my ($dmat,$amat)  = _edit_align_full($a1,$b1,@costs);
  my ($dmat2,$amat2) =  edit_align_full($a,$b,@costs);
  my $dmat_want = pdl([
			[0, 1, 2, 3, 4, 5],
			[1, 0, 1, 2, 3, 4],
			[2, 1, 1, 2, 3, 4],
			[3, 2, 2, 1, 2, 3],
			[4, 3, 3, 2, 1, 2],
			[5, 4, 4, 3, 2, 1],
			[6, 5, 5, 4, 3, 2],
		       ]);
  my $amat_want = pdl [
			[0, 1, 1, 1, 1, 1],
			[2, 0, 1, 1, 1, 1],
			[2, 2, 3, 3, 3, 3],
			[2, 2, 3, 0, 1, 1],
			[2, 2, 3, 2, 0, 1],
			[2, 2, 3, 2, 2, 0],
			[2, 2, 3, 2, 2, 2],
		       ];

  pdlok("_edit_align_full (dist)", $dmat, $dmat_want);
  pdlok("_edit_align_full (align)", $amat, $amat_want);
  pdlok("edit_align_full  (dist)", $dmat2, $dmat_want);
  pdlok("edit_align_full  (align)", $amat2, $amat_want);
}
test_align_full;


##---------------------------------------------------------------------
## 17..20: test_align_static: alignment matrix, static
sub test_align_static {
  makepdls;
  my @costs = (0,1,1,1);
  my ($dmat,$amat)   = _edit_align_static($a1,$b1,@costs);
  my ($dmat2,$amat2) =  edit_align_static($a,$b,@costs);
  my $dmat_want = pdl([
			[0, 1, 2, 3, 4, 5],
			[1, 0, 1, 2, 3, 4],
			[2, 1, 1, 2, 3, 4],
			[3, 2, 2, 1, 2, 3],
			[4, 3, 3, 2, 1, 2],
			[5, 4, 4, 3, 2, 1],
			[6, 5, 5, 4, 3, 2],
		       ]);
  my $amat_want = pdl [
			[0, 1, 1, 1, 1, 1],
			[2, 0, 1, 1, 1, 1],
			[2, 2, 3, 3, 3, 3],
			[2, 2, 3, 0, 1, 1],
			[2, 2, 3, 2, 0, 1],
			[2, 2, 3, 2, 2, 0],
			[2, 2, 3, 2, 2, 2],
		       ];

  pdlok("_edit_align_static (dist)", $dmat, $dmat_want);
  pdlok("_edit_align_static (align)", $amat, $amat_want);
  pdlok("edit_align_static  (dist)", $dmat2, $dmat_want);
  pdlok("edit_align_static  (align)", $amat2, $amat_want);
}
test_align_static;

##---------------------------------------------------------------------
## 21..23 test_bestpath: best path
sub test_bestpath {
  makepdls;
  my @costs = (0,1,1,1);
  my ($dmat,$amat) = edit_align_static($a,$b,@costs);
  my ($apath,$bpath,$pathlen) = edit_bestpath($amat);
  my $pathlen_want = 6;
  my $apath_want = pdl [0, 1, 2, 3, 4, -1];
  my $bpath_want = pdl [0, 1, 2, 3, 4,  5];
  isok("bestpath: len  ", $pathlen, $pathlen_want );
  pdlok("bestpath: apath", $apath->slice("0:".($pathlen-1)), $apath_want) ;
  pdlok("bestpath: bpath", $bpath->slice("0:".($pathlen-1)), $bpath_want) ;
}
test_bestpath;

##---------------------------------------------------------------------
## 24..27 test_pathtrace: full path backtrace
sub test_pathtrace {
  makepdls;
  my @costs = (0,1,1,1);
  my ($dmat,$amat) = edit_align_static($a,$b,@costs);
  my ($ai,$bi,$ops,$len) = edit_pathtrace($amat);
  my $len_want = 6;
  my $ai_want  = pdl [1,2,3,4,5,5];
  my $bi_want  = pdl [1,2,3,4,5,6];
  my $ops_want = pdl [0,3,0,0,0,2]; ##-- match, subst, match, match, match, insert2
  isok("pathtrace: len", $len==$len_want );
  pdlok("pathtrace:  ai", $ops, $ops_want);
  pdlok("pathtrace:  bi", $ops, $ops_want);
  pdlok("pathtrace: ops", $ops, $ops_want);
}
test_pathtrace;

##---------------------------------------------------------------------
## 28..31 test_lcs: test LCS
sub test_lcs {
  my $a = pdl(long,[0,1,2,3,4]);
  my $b = pdl(long,[  1,2,1,4,0]);
  my $lcs = edit_lcs($a,$b);
  my ($ai,$bi,$len) = lcs_backtrace($a,$b,$lcs);
  my $lcs_want = pdl(long, [[0,0,0,0,0,0],
			    [0,0,1,1,1,1],
			    [0,0,1,2,2,2],
			    [0,0,1,2,2,2],
			    [0,0,1,2,2,3],
			    [0,1,1,2,2,3]]);
  my $ai_want = pdl(long,[1,2,4]);
  my $bi_want = pdl(long,[0,1,3]);
  my $len_want = 3;
  pdlok("lcs: matrix ", $lcs, $lcs_want);
  isok("lcs: len    ", $len==$len_want);
  pdlok("lcs: ai     ", $ai, $ai_want);
  pdlok("lcs: bi     ", $bi, $bi_want);
}
test_lcs();

print "\n";
# end of t/01_distance.t


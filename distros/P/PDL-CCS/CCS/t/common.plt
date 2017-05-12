# -*- Mode: CPerl -*-
# File: CCS/t/common.plt
# Description: common subs & data for PDL/CCS/t/*.t

##-- common subs
BEGIN {
  use File::Basename;
  use Cwd;
  my $topdir = Cwd::abs_path(dirname(__FILE__)."/../..");
  do "$topdir/t/common.plt" or die("$0: failed to load $topdir/t/common.plt: $@");
}

##-- common modules
use PDL;

#-- common data
our $a = pdl(double, [
		      [10,0,0,0,-2],
		      [3,9,0,0,0],
		      [0,7,8,6,0],
		      [3,0,8,7,5],
		      [0,8,0,9,7],
		      [0,4,0,0,2],
		     ]);
our $abad   = ($a==0);
our $agood  = !$abad;
our $awhich = $a->whichND;
our $avals  = $a->indexND($awhich);

our $BAD = pdl(0)->setvaltobad(0);

print "loaded ", __FILE__, "\n";

1;

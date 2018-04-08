#-*- Mode: CPerl -*-
use Test::More tests=>7;

my $TEST_DIR;
BEGIN {
  use File::Basename;
  use Cwd;
  $TEST_DIR = Cwd::abs_path dirname( __FILE__ );
  eval qq{use lib ("$TEST_DIR/$_/blib/lib","$TEST_DIR/$_/blib/arch");} foreach (qw(..));
  #do "$TEST_DIR/common.plt" or die("$0: failed to load $TEST_DIR/common.plt: $@");
}

use PDL;
use PDL::Cluster;

#------------------------------------------------------
# Data for Tests

#----------
# dataset
#
$weight = pdl [ 1,1,1 ];
$data   = pdl [
		  [ 1,1,1, ],
		  [ 2,2,2, ],
		  [ 3,4,5, ],
		  [ 7,8,9, ],
		 ];
$mask = pdl [
		[ 1, 1, 1, ],
		[ 1, 1, 1, ],
		[ 1, 1, 1, ],
		[ 1, 1, 1, ],
	       ];

$cids = pdl(long, [1,1,1,0]);
use vars qw($d);
($d,$n,$k) = ($data->dims, $cids->max+1);
($dist,$cdmethod)=('b','x');


## 1..2: Test cluster sizes, datum-by-cluster indexing
PDL::Cluster::clustersizes($cids, $csize=zeroes(long,$k));
is($csize->string, pdl([1,3])->string, "clustersizes()");

PDL::Cluster::clusterelements($cids, $csize, $eids=zeroes(long,$csize->max,$k)-1);
is($eids->string, pdl(long,[[3,-1,-1],[0,1,2]])->string, "clusterelements()");

## 3..7: Test clusterdistancematrix()
%rdwant =
  (
   'a'=>[[7,4/3],[6,1/3],[4,5/3],[0,17/3]],
   'v'=>[[7,4/3],[6,1  ],[4,5/3],[0,17/3]],
   'm'=>[[7,1],[6,0],[4,2],[0,6]],
   's'=>[[7,0],[6,0],[4,0],[0,4]],
   'x'=>[[7,3],[6,2],[4,3],[0,7]],
  );

foreach $cdmethod (sort keys(%rdwant)) {
  PDL::Cluster::clusterdistancematrix($data,$mask,$weight, sequence(long,$n),
				      $csize, $eids,
				      $rdists=zeroes(double,$k,$n),
				      $dist, $cdmethod);
  is($rdists->string("%.3f"), pdl($rdwant{$cdmethod})->string("%.3f"), "clusterdistancematrix(method=$cdmethod)");
}

__END__




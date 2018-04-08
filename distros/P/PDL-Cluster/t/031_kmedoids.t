#-*- Mode: CPerl -*-
use Test::More tests=>6;

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
# 

#----------
# dataset 1
#
my $matrix = pdl [
        [],
        [ 3.4],
        [ 4.3, 10.1],
        [ 3.7, 11.5,  1.1],
        [ 1.7,  4.1,  3.4,  3.4],
        [10.1, 20.5,  2.5,  2.7,  9.8],
        [ 2.5,  3.7,  3.1,  3.6,  1.1, 10.1],
        [ 3.4,  2.2,  8.8,  8.7,  3.3, 16.6,  2.7],
        [ 2.1,  7.7,  2.7,  1.9,  1.8,  5.7,  3.4,  5.2],
        [ 1.6,  1.8,  9.2,  8.7,  3.4, 16.8,  4.2,  1.3,  5.0],
        [ 2.7,  3.7,  5.5,  5.5,  1.9, 11.5,  2.0,  1.7,  2.1,  3.1],
        [10.0, 19.3,  2.2,  3.7,  9.1,  1.2,  9.3, 15.7,  6.3, 16.0, 11.5]
];

##-- hack
$matrix = $matrix->glue(0, pdl(0));

#------------------------------------------------------
# Tests
# 

sub test_kmedoids {
  my %params = @_;
  my ($clusters ,$error,$found);

  PDL::Cluster::kmedoids(
			 $params{nclusters},
			 $params{distances},
			 $params{npass},
			 ($clusters=(defined($params{initialid})
				     ? $params{initialid}
				     : zeroes(long,$params{distances}->dim(0)))),
			 ($error=pdl(0)),
			 ($found=pdl(0)),
			);

  my $label = $params{label} || "kmedoids";

  ##-- test: dimensions
  is($clusters->dim(0), $params{distances}->dim(0), "$label: clusters.dim(0)==distances.dim(0)");

  if (defined(my $want=$params{expect_c})) {
    ##-- test: cluster assignments
    is($clusters->string, pdl($want)->long->string, "$label: clusters");
  }

  if (defined($params{expect_e})) {
    ##-- test: error
    is($error->string("%.3f"), pdl($params{expect_e})->string("%.3f"), "$label: error");
  }

  return ($clusters,$error,$found);
}

#------------------------------------------------------
# Test with repeated runs of the k-medoids algorithm
#

my %params1 = (
	       nclusters =>         4,
	       distances =>   $matrix,
	       npass     =>       100,
	      );
test_kmedoids(%params1,label=>"params1",
	      expect_c=>[9,9,2,2,4,5,4,9,4,9,4,5],
	      expect_e=>11.8);

#------------------------------------------------------
# Test the k-medoids algorithm with a specified initial clustering

my $initialid = pdl(long, [0,0,1,1,1,2,2,2,3,3,3,3]);
my %params2 = (
	       nclusters =>         4,
	       distances =>   $matrix,
	       npass     =>         0,
	       initialid => $initialid,
	      );
test_kmedoids(%params2,label=>"params2+init",
	      expect_c=>[9,9,2,2,4,2,6,9,4,9,4,2],
	      expect_e=>14.2);

__END__




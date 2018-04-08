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
my $weight1 =  pdl [ 1,1,1,1,1 ];
my $data1   =  pdl [
        [  1.1, 2.2, 3.3, 4.4, 5.5, ], 
        [  3.1, 3.2, 1.3, 2.4, 1.5, ], 
        [  4.1, 2.2, 0.3, 5.4, 0.5, ], 
        [ 12.1, 2.0, 0.0, 5.0, 0.0, ], 
];
my $mask1 =  pdl [
        [ 1, 1, 1, 1, 1, ], 
        [ 1, 1, 1, 1, 1, ], 
        [ 1, 1, 1, 1, 1, ], 
        [ 1, 1, 1, 1, 1, ], 
];
my $data1_c1 = pdl [ 0 ];
my $data1_c2 = pdl [ 1,2 ];
my $data1_c3 = pdl [ 3 ];


#----------
# dataset 2
#
my $weight2 =  pdl [ 1,1 ];
my $data2   =  pdl [
	[ 1.1, 1.2 ],
	[ 1.4, 1.3 ],
	[ 1.1, 1.5 ],
	[ 2.0, 1.5 ],
	[ 1.7, 1.9 ],
	[ 1.7, 1.9 ],
	[ 5.7, 5.9 ],
	[ 5.7, 5.9 ],
	[ 3.1, 3.3 ],
	[ 5.4, 5.3 ],
	[ 5.1, 5.5 ],
	[ 5.0, 5.5 ],
	[ 5.1, 5.2 ],
];
my $mask2 =  pdl [
	[ 1, 1 ],
	[ 1, 1 ],
	[ 1, 1 ],
	[ 1, 1 ],
	[ 1, 1 ],
	[ 1, 1 ],
	[ 1, 1 ],
	[ 1, 1 ],
	[ 1, 1 ],
	[ 1, 1 ],
	[ 1, 1 ],
	[ 1, 1 ],
	[ 1, 1 ],
];
my $data2_c1 = pdl [ 0, 1, 2, 3 ];
my $data2_c2 = pdl [ 4, 5, 6, 7 ];
my $data2_c3 = pdl [ 8 ];


#------------------------------------------------------
# Tests
# 

#----------
# pdl-ish testing sub
sub test_clusterdistance {
  my %params = @_;
  my $distance=null;
  PDL::Cluster::clusterdistance(
				$params{data},
				$params{mask},
				$params{weight},
				$params{cluster1}->dim(0),
				$params{cluster2}->dim(0),
				$params{cluster1},
				$params{cluster2},
				$distance,
				$params{dist},
				$params{method}
			       );
  my $label  = $params{label} || "clusterdistance";
  my $expect = $params{expect} || 0;
  is($distance->string("%.3f"), pdl($expect)->string("%.3f"), $label);
  return $distance;
}

#----------
# test dataset 1
#
my %params = (
	      label     => 'data1',
	      transpose =>         0,
	      method    =>       'a',
	      dist      =>       'e',
	      data      =>    $data1,
	      mask      =>    $mask1,
	      weight    =>  $weight1,
	      cluster1  => $data1_c1,
	      cluster2  => $data1_c2,
	     );
test_clusterdistance(%params,label=>"data1: distance(c1,c2)",expect=>6.65);

$params{cluster1} = $data1_c1;
$params{cluster2} = $data1_c3;
test_clusterdistance(%params,label=>"data1: distance(c1,c3)",expect=>32.508);

$params{cluster1} = $data1_c2;
$params{cluster2} = $data1_c3;
test_clusterdistance(%params,label=>"data1: dsitance(c2,c3)",expect=>15.118);

#----------
# test dataset 2
#
%params = (
	   label     => 'data2',
	   transpose =>         0,
	   method    =>       'a',
	   dist      =>       'e',
	   data      =>    $data2,
	   mask      =>    $mask2,
	   weight    =>  $weight2,
	   cluster1  => $data2_c1,
	   cluster2  => $data2_c2,
	  );
test_clusterdistance(%params,label=>"data2: distance(c1,c2)",expect=>5.833);

$params{cluster1} = $data2_c1;
$params{cluster2} = $data2_c3;
test_clusterdistance(%params,label=>"data2: distance(c1,c3)",expect=>3.298);

$params{cluster1} = $data2_c2;
$params{cluster2} = $data2_c3;
test_clusterdistance(%params,label=>"data2: distance(c2,c3)",expect=>0.360);

__END__


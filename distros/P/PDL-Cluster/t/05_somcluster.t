#-*- Mode: CPerl -*-
use Test::More tests=>4;

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
my $weight1 = pdl [ 1,1,1,1,1 ];
my $data1   = pdl [
        [ 1.1, 2.2, 3.3, 4.4, 5.5, ], 
        [ 3.1, 3.2, 1.3, 2.4, 1.5, ], 
        [ 4.1, 2.2, 0.3, 5.4, 0.5, ], 
        [ 12.1, 2.0, 0.0, 5.0, 0.0, ], 
];
my $mask1 = pdl [
        [ 1, 1, 1, 1, 1, ], 
        [ 1, 1, 1, 1, 1, ], 
        [ 1, 1, 1, 1, 1, ], 
        [ 1, 1, 1, 1, 1, ], 
];

#----------
# dataset 2
#
my $weight2 = pdl [ 1,1 ];
my $data2   = pdl [
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
my $mask2 = pdl [
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


#------------------------------------------------------
# testing sub
sub test_somcluster {
  my %params = @_;
  my ($clusterid);

  PDL::Cluster::somcluster(
			   $params{data},
			   $params{mask},
			   $params{weight},
			   $params{nxnodes},
			   $params{nynodes},
			   ($params{inittau} ? $params{inittau} : 0.02),
			   $params{niter},
			   ($clusterid=zeroes(long, 2, $params{data}->dim(1))),
			   $params{dist}
			  );
  my $label = $params{label} || "somcluster";
  is($clusterid->dim(0), 2, "$label: clusterid.dim(0)");
  is($clusterid->dim(1), $params{data}->dim(1), "$label: clusterid.dim(1)");

  return $clusterid;
}


#------------------------------------------------------
# Tests
# 
my ($clusterid);
my ($i);

my %params;
%params = (
	transpose =>         0,
	dist      =>       'e',
	data      =>    $data1,
	mask      =>    $mask1,
	weight    =>  $weight1,
	niter     =>       100,
	nxnodes   =>        10,
	nynodes   =>        10,
);
test_somcluster(%params,label=>"data1: somcluster");


%params = (
	transpose =>         0,
	dist      =>       'e',
	data      =>    $data2,
	mask      =>    $mask2,
	weight    =>  $weight2,
	niter     =>       100,
	nxnodes   =>        10,
	nynodes   =>        10,
	  );
test_somcluster(%params, label=>"data2: somcluster");

__END__

#-*- Mode: CPerl -*-
use Test::More tests=>26;
use PDL;
use PDL::Cluster;

my ($last_test,$loaded);

##----------
## dataset 1
##
my $weight1 =  pdl [ 1,1,1,1,1 ];
my $data1   =  pdl [
        [ 1.1, 2.2, 3.3, 4.4, 5.5, ], 
        [ 3.1, 3.2, 1.3, 2.4, 1.5, ], 
        [ 4.1, 2.2, 0.3, 5.4, 0.5, ], 
        [ 12.1, 2.0, 0.0, 5.0, 0.0, ], 
];
my $mask1 =  pdl [
        [ 1, 1, 1, 1, 1, ], 
        [ 1, 1, 1, 1, 1, ], 
        [ 1, 1, 1, 1, 1, ], 
        [ 1, 1, 1, 1, 1, ], 
];

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


#------------------------------------------------------
# Tests
# 
my ($clusters, $centroids, $error, $found);
my ($i,$j);

my %params = (

	nclusters =>         3,
	transpose =>         0,
	method    =>       'a',
	dist      =>       'e',
);

#----------
# test dataset 1
#
PDL::Cluster::kcluster(
		       $params{nclusters},
		       $data1,
		       $mask1,
		       $weight1,
		       100,
		       ($clusters=null),
		       ($error=null),
		       ($nfound=null),
		       $params{dist},
		       $params{method},
		      );
	
#----------
# Make sure that the length of @clusters matches the length of @data
is($data1->dim(1), $clusters->dim(0), q{data1: dims});

#----------
# Test the cluster coordinates
isnt($clusters->at(0), $clusters->at(1), "data1: c(0) != c(1)");
is  ($clusters->at(1), $clusters->at(2), "data1: c(1) == c(2)");
isnt($clusters->at(2), $clusters->at(3), "data1: c(2) != c(3)");

# Test the within-cluster sum of errors
is(sprintf("%.3f", $error), '1.300', "data1: error");

#----------
# test dataset 2
#
PDL::Cluster::kcluster(
		       $params{nclusters},
		       $data2,
		       $mask2,
		       $weight2,
		       100,
		       ($clusters=null),
		       ($error=null),
		       ($nfound=null),
		       $params{dist},
		       $params{method},
		      );

#----------
# Make sure that the length of @clusters matches the length of @data
is($data2->dim(1), $clusters->dim(0), 'data2: dims');

#----------
# Test the cluster coordinates
is  ($clusters->at( 0), $clusters->at( 3), "data2: c(0)==c(3)");
isnt($clusters->at( 0), $clusters->at( 6), "data2: c(0)!=c(3)");
isnt($clusters->at( 0), $clusters->at( 9), "data2: c(0)!=c(9)");
is  ($clusters->at(11), $clusters->at(12), "data2: c(11)==c(12)");

# Test the within-cluster sum of errors
is(sprintf("%.3f",$error), '1.012', "data2: error");

#----------
# test kcluster with initial cluster assignments
#
$initialid = pdl [0,1,2,0,1,2,0,1,2,0,1,2,0];

PDL::Cluster::kcluster(
		       $params{nclusters},
		       $data2,
		       $mask2,
		       $weight2,
		       0,
		       ($clusters=$initialid->copy),
		       ($error=null),
		       ($nfound=null),
		       $params{dist},
		       $params{method},

);


#----------
# Test the cluster coordinates
is($clusters->at(0), 2, "preinit: c(0)==2");
is($clusters->at(1), 2, "preinit: c(1)==2");
is($clusters->at(2), 2, "preinit: c(2)==2");
is($clusters->at(3), 2, "preinit: c(3)==2");
is($clusters->at(4), 2, "preinit: c(4)==2");
is($clusters->at(5), 2, "preinit: c(5)==2");
is($clusters->at(6), 0, "preinit: c(6)==0");
is($clusters->at(7), 0, "preinit: c(7)==0");
is($clusters->at(8), 2, "preinit: c(8)==2");
is($clusters->at(9), 1, "preinit: c(9)==1");
is($clusters->at(10), 1, "preinit: c(10)==1");
is($clusters->at(11), 1, "preinit: c(11)==1");
is($clusters->at(12), 1, "preinit: c(12)==1");

# Test the within-cluster sum of errors
is(sprintf("%.3f", $error), 3.036, "pre-init: error");
is($nfound->sclr, 1, "pre-init: nfound");

__END__




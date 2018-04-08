##-*- Mode: CPerl -*-
use Test::More tests=>4;
use PDL;
use PDL::Cluster;

my $dummy;

my $data1 = pdl [ 34.3, 3, 2 ];
my $data2 = pdl [ 5, 10 ,15, 20 ];
#my $data3 = pdl [ 1, 2, 3, 5, 7, 11, 13, 17, $dummy_sub_ref ];
#my $data4 = pdl [ 100, 19, 3, 1.5, 1.4, 1, 1, 1, $dummy_ref ];
#my $data5 = pdl [ 2.0, 21, 1, 1, 1, 4.0, 5.0, 'not a number' ];

is(sprintf("%.4f",PDL::Cluster::cmean($data1)), '13.1000', 'cmean(data1)');
is(sprintf("%.4f",PDL::Cluster::cmean($data2)), '12.5000', 'cmean(data2)');

is(sprintf("%.4f",PDL::Cluster::cmedian($data1)), '3.0000', 'cmedian(data1)');
is(sprintf("%.4f",PDL::Cluster::cmedian($data2)), '12.5000', 'cmedian(data2)');

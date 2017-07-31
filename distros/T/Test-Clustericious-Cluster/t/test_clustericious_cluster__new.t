use strict;
use warnings;
use Test2::Bundle::More;
use Test::Clustericious::Cluster;

my $cluster = Test::Clustericious::Cluster->new;
isa_ok $cluster, 'Test::Clustericious::Cluster';

done_testing;

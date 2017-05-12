use strict;
use warnings;
use Test2::Bundle::More;
use Test::Clustericious::Cluster;

plan 1;

my $cluster = Test::Clustericious::Cluster->new;
isa_ok $cluster->create_ua, 'Mojo::UserAgent';

#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

ok $es->update_cluster_settings(
    transient  => { "discovery.zen.minimum_master_nodes" => 2 },
    persistent => { "discovery.zen.minimum_master_nodes" => 3 }
    ),
    'Update cluster settings';

ok $r= $es->cluster_settings(), 'Get cluster settings';
is $r->{transient}{"discovery.zen.minimum_master_nodes"}, 2,
    ' - transient set';
is $r->{persistent}{"discovery.zen.minimum_master_nodes"}, 3,
    ' - persistent set';

1;

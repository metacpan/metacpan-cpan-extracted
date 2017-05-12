# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl ShardedKV-Continuum-Jump.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 6;
BEGIN { use_ok('ShardedKV::Continuum::Jump') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


# Test for compatibility with github.com/dgryski/go-shardedkv

my $j = ShardedKV::Continuum::Jump->new({from => { ids => [qw(shard0 shard1 shard2 shard3)], weights => [ 10, 20, 30, 40 ] }});
my %got;
$got{$j->choose("key$_")}++ for 0..9999;
my %want = (
    shard0 => 988,
    shard1 => 2046,
    shard2 => 2960,
    shard3 => 4006,
);
is_deeply(\%got, \%want, "4 weighted shards");

$j->extend({ ids => [ qw(shard4 shard5) ], weights => [10, 20]});
%got = ();
$got{$j->choose("key$_")}++ for 0..9999;
%want = (
    shard0 => 755,
    shard1 => 1574,
    shard2 => 2271,
    shard3 => 3115,
    shard4 => 823,
    shard5 => 1462,
);
is_deeply(\%got, \%want, "4 expanded to 6 weighted shards");

$j = ShardedKV::Continuum::Jump->new({from => { ids => [qw(shard0 shard1 shard2 shard3)] }});
%got =();
$got{$j->choose("key$_")}++ for 0..9999;
%want = (
    shard0 => 2528,
    shard1 => 2498,
    shard2 => 2520,
    shard3 => 2454,
);
is_deeply(\%got, \%want, "4 unweighted shards");

$j->extend({ ids => [ qw(shard4 shard5) ], weights => [2,2]});
%got = ();
$got{$j->choose("key$_")}++ for 0..9999;
%want = (
    shard0 => 1283,
    shard1 => 1253,
    shard2 => 1245,,
    shard3 => 1238,
    shard4 => 2462,
    shard5 => 2519,
);
is_deeply(\%got, \%want, "4 unweighted expanded with 2 weighted");


$j->extend({ ids => [ qw(shard6 shard7) ]});
%got = ();
$got{$j->choose("key$_")}++ for 0..9999;
%want = (
    shard0 => 1029,
    shard1 => 985,
    shard2 => 986,
    shard3 => 991,
    shard4 => 1966,
    shard5 => 2051,
    shard6 => 1029,
    shard7 => 963,
);
is_deeply(\%got, \%want, "6 weighted expanded with 2 unweighted");

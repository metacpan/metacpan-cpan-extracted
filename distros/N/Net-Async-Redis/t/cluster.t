use strict;
use warnings;

# no indirect;
use Syntax::Keyword::Try;

use Future::AsyncAwait;

use Test::More;
use Net::Async::Redis::Cluster;
use IO::Async::Loop;

use Log::Any qw($log);

plan skip_all => 'set NET_ASYNC_REDIS_HOST env var to test' unless exists $ENV{NET_ASYNC_REDIS_HOST};

# If we have ::TAP, use it - but no need to list it as a dependency
eval {
    require Log::Any::Adapter;
    Log::Any::Adapter->import(qw(TAP));
};

my $loop = IO::Async::Loop->new;
(async sub {
    $loop->add(
        my $cluster = Net::Async::Redis::Cluster->new
    );

    await $cluster->bootstrap(
        host => $ENV{NET_ASYNC_REDIS_HOST} // '127.0.0.1',
        port => 6379,
    );
    my @nodes = $cluster->node_list;
    is($cluster->node_for_slot(1), $nodes[0]);
    is($cluster->node_for_slot(5500), $nodes[1]);
    is($cluster->node_for_slot(12020), $nodes[2]);
    try {
        my $redis = await $cluster->connection_for_slot(0);
        for my $k (qw(
            abc
            def
            ghi
            {user:100}.test
            {user:101}.test
            test.{user:100}
            tset.{user:101}
        )) {
            is((await $redis->cluster_keyslot($k)), $cluster->hash_slot_for_key($k), 'server and our code agree on hash slot for ' . $k);
        }
        await $redis->set(abc => 1);
        await $redis->set(def => 1);
        await $redis->set(ghi => 1);
    } catch {
        $log->errorf('error %s', $@);
        my ($err, $key, $host_port) = split ' ', $@;
        $log->errorf('Failed - %s - where key was %s, new target is %s', $err, $key, $host_port);
        my $node = $cluster->register_moved_slot($key => $host_port);
        $log->infof('New node is %s', $node);
        is($node, $cluster->node_for_slot($key));
    }
    await $cluster->set(abc => 1);
    await $cluster->set(def => 2);
    await $cluster->set(ghi => 3);
})->()->get;

done_testing;

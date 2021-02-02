use strict;
use warnings;

# no indirect;
use Syntax::Keyword::Try;

use Future::AsyncAwait;

use Test::More;
use Test::Fatal qw(lives_ok exception);
use Test::MockModule;
use Net::Async::Redis::Cluster;
use IO::Async::Loop;

use Log::Any qw($log);

plan skip_all => 'set NET_ASYNC_REDIS_CLUSTER env var to test' unless $ENV{NET_ASYNC_REDIS_CLUSTER};

# If we have ::TAP, use it - but no need to list it as a dependency
eval {
    require Log::Any::Adapter;
    Log::Any::Adapter->import(qw(TAP));
};

my $loop = IO::Async::Loop->new;

subtest 'General cluster behaviour' => sub {
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
            my $node = await $cluster->register_moved_slot($key => $host_port);
            $log->infof('New node is %s', $node);
            is($node, $cluster->node_for_slot($key));
        }
        await $cluster->set(abc => 1);
        await $cluster->set(def => 2);
        await $cluster->set(ghi => 3);
    })->()->get;
};

subtest 'Should abort if the cluster has invalid node(s)' => sub {
    $loop->add(my $cluster = Net::Async::Redis::Cluster->new);
    my $mocked_redis = Test::MockModule->new('Net::Async::Redis');
    $mocked_redis->mock('cluster_slots', sub {
        return Future->done([
            [0, 500, ["127.0.0.1", 6379], ["127.0.0.1", 6380]],
            [501, 1000, ["", 0], []]
        ]);
    });

    like(
        exception {
            $cluster->bootstrap(
                host => $ENV{NET_ASYNC_REDIS_HOST} // '127.0.0.1',
                port => 6379
            )->get();
    }, qr/invalid primary/, 'Cluster bootstrap should throw an exception');
};

# Migrate a slot to the server who owns the slot in the next param

async sub migrate_slot {
    my ($cluster, $slot, $to) = @_;
    my $source = await $cluster->connection_for_slot($slot);
    my $src_id = await $source->cluster_myid;

    my $destination = await $cluster->connection_for_slot($to);
    my $dst_id = await $destination->cluster_myid;

    await $destination->cluster_setslot($slot, importing => $src_id);
    await $source->cluster_setslot($slot, migrating => $dst_id);
    # 1000 is an arbitrary value here
    my $keys_to_migrate = await $source->cluster_getkeysinslot($slot, 1000);
    if ($keys_to_migrate->@*) {
        await $source->migrate($destination->host, 6379, "", 0, 10, 'replace', keys => $keys_to_migrate->@*);
    }
    await $destination->cluster_setslot($slot, node => $dst_id);
    await $source->cluster_setslot($slot, node => $dst_id);
};

subtest 'Should redirect request to correct node if MOVED error occurred' => sub {
    $loop->add(
        my $cluster = Net::Async::Redis::Cluster->new
    );
    (async sub {
        await $cluster->bootstrap(
            host => $ENV{NET_ASYNC_REDIS_HOST} // '127.0.0.1',
            port => 6379
        );

        try {
            # Migrate slot 3544 to the second server
            await migrate_slot($cluster, 3544, 5500);
            lives_ok {
                $cluster->set('foo01', 'value')->get();
                my $val = $cluster->get('foo01')->get();
                is($val, 'value', 'received correct key value');
            }, 'it should redirect the call to the correct server';
        } finally {
            # Migrate slot 3544 back
            migrate_slot($cluster, 3544, 1)->get();
        }
    })->()->get();
};

done_testing;

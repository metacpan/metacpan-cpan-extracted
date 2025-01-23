[![Actions Status](https://github.com/plainbanana/Redis-Cluster-Fast/workflows/test/badge.svg)](https://github.com/plainbanana/Redis-Cluster-Fast/actions) [![MetaCPAN Release](https://badge.fury.io/pl/Redis-Cluster-Fast.svg)](https://metacpan.org/release/Redis-Cluster-Fast)
# NAME

Redis::Cluster::Fast - A fast perl binding for Redis Cluster

# SYNOPSIS

    use Redis::Cluster::Fast;

    Redis::Cluster::Fast::srandom(100);

    my $redis = Redis::Cluster::Fast->new(
        startup_nodes => [
            'localhost:9000',
            'localhost:9001',
            'localhost:9002',
            'localhost:9003',
            'localhost:9004',
            'localhost:9005',
        ],
        connect_timeout => 0.05,
        command_timeout => 0.05,
        max_retry_count => 10,
    );

    $redis->set('test', 123);

    # '123'
    my $str = $redis->get('test');

    $redis->mset('{my}foo', 'hoge', '{my}bar', 'fuga');

    # get as array-ref
    my $array_ref = $redis->mget('{my}foo', '{my}bar');
    # get as array
    my @array = $redis->mget('{my}foo', '{my}bar');

    $redis->hset('mymap', 'field1', 'Hello');
    $redis->hset('mymap', 'field2', 'ByeBye');

    # get as hash-ref
    my $hash_ref = { $redis->hgetall('mymap') };
    # get as hash
    my %hash = $redis->hgetall('mymap');

# DESCRIPTION

Redis::Cluster::Fast is like [Redis::Fast](https://github.com/shogo82148/Redis-Fast) but support Redis Cluster by [hiredis-cluster](https://github.com/Nordix/hiredis-cluster).

To build and use this module you need libevent-dev >= 2.x is installed on your system.

Recommend Redis 6 or higher.

Since Redis 6, it supports new version of Redis serialization protocol, [RESP3](https://github.com/antirez/RESP3/blob/master/spec.md).
This client start to connect using RESP2 and currently it has no option to upgrade all connections to RESP3.

## MICROBENCHMARK

Simple microbenchmark comparing PP and XS.
The benchmark script used can be found under examples directory.

    Redis::Cluster::Fast is 0.084
    Redis::ClusterRider is 0.26
    ### mset ###
                            Rate  Redis::ClusterRider Redis::Cluster::Fast
    Redis::ClusterRider  13245/s                   --                 -34%
    Redis::Cluster::Fast 20080/s                  52%                   --
    ### mget ###
                            Rate  Redis::ClusterRider Redis::Cluster::Fast
    Redis::ClusterRider  14641/s                   --                 -40%
    Redis::Cluster::Fast 24510/s                  67%                   --
    ### incr ###
                            Rate  Redis::ClusterRider Redis::Cluster::Fast
    Redis::ClusterRider  18367/s                   --                 -44%
    Redis::Cluster::Fast 32879/s                  79%                   --
    ### new and ping ###
                           Rate  Redis::ClusterRider Redis::Cluster::Fast
    Redis::ClusterRider   146/s                   --                 -96%
    Redis::Cluster::Fast 3941/s                2598%                   --

# METHODS

## srandom($seed)

hiredis-cluster uses [random()](https://linux.die.net/man/3/random) to select a node used for requesting cluster topology.

`$seed` is expected to be an unsigned integer value,
and is used as an argument for [srandom()](https://linux.die.net/man/3/srandom).

These are different implementations of Perl's rand and srand.
In this client, Perl's Drand01 is also used to determine the destination node for executing a command that is not a cluster command.

## new(%args)

Following arguments are available.

### startup\_nodes

Specifies the list of Redis Cluster nodes.

### connect\_timeout

A fractional seconds. (default: 1.0)

Connection timeout to connect to a Redis node.

### command\_timeout

A fractional seconds. (default: 1.0)

Specifies the timeout value for each read/write event to execute a Redis Command.

### max\_retry\_count

A integer value. (default: 5)

The client will retry calling the Redis Command only if it successfully get one of the following error responses.
MOVED, ASK, TRYAGAIN, CLUSTERDOWN.

`max_retry_count` is the maximum number of retries and must be 1 or above.

### cluster\_discovery\_retry\_timeout

A fractional value. (default: 1.0)

Specify the number of seconds to treat a series of cluster topology requests as timed out without retrying the operation.
At least one operation will be attempted, and the time taken for the initial operation will also be measured.

### route\_use\_slots

A value used as boolean. (default: undef)

The client will call CLUSTER SLOTS instead of CLUSTER NODES.

## &lt;command>(@args)

To run a Redis command with arguments.

The command can also be expressed by concatenating the subcommands with underscores.

    e.g. cluster_info

It does not support (Sharded) Pub/Sub family of commands and should not be run.

It is recommended to issue `disconnect` in advance just to be safe when executing fork() after issuing the command.

## &lt;command>(@args, sub {})

To run a Redis command in pipeline with arguments and a callback.

The command can also be expressed by concatenating the subcommands with underscores.

Commands issued to the same node are sent and received in pipeline mode.
In pipeline mode, commands are not sent to Redis until `wait_one_response` or `wait_all_responses` is issued.

The callback is executed with two arguments.
The first is the result of the command, and the second is the error message.
`$result` will be a scalar value or an array reference, and `$error` will be an undefined value if no errors occur.
Also, `$error` may contain an error returned from Redis or an error that occurred on the client (e.g. Timeout).

You cannot call any client methods inside the callback.

After issuing a command in pipeline mode,
do not execute fork() without issuing `disconnect` if all callbacks are not executed completely.

    $redis->get('test', sub {
        my ($result, $error) = @_;
        # some operations...
    });

## wait\_one\_response()

If there are any unexcuted callbacks, it will block until at least one is executed.
The return value can be either 1 for success, 0 for no callbacks remained, or undef for other errors.

## wait\_all\_responses()

If there are any unexcuted callbacks, it will block until all of them are executed.
The return value can be either 1 for success, 0 for no callbacks remained, or undef for other errors.

## disconnect()

Normally you should not call `disconnect` manually.
If you want to call fork(), `disconnect` should be call before fork().

It will be blocked until all unexecuted commands are executed, and then it will disconnect.

## connect()

Normally you should not call `connect` manually.
If you want to call fork(), `connect` should be call after fork().

# LICENSE

Copyright (C) plainbanana.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

plainbanana <plainbanana@mustardon.tokyo>

# SEE ALSO

- [Redis::ClusterRider](https://github.com/iph0/Redis-ClusterRider)
- [Redis::Fast](https://github.com/shogo82148/Redis-Fast)

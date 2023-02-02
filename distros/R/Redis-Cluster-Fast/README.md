[![Actions Status](https://github.com/plainbanana/Redis-Cluster-Fast/workflows/Test/badge.svg)](https://github.com/plainbanana/Redis-Cluster-Fast/actions) [![MetaCPAN Release](https://badge.fury.io/pl/Redis-Cluster-Fast.svg)](https://metacpan.org/release/Redis-Cluster-Fast)
# NAME

Redis::Cluster::Fast - A fast perl binding for Redis Cluster

# SYNOPSIS

    use Redis::Cluster::Fast;

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
        max_retry => 10,
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
    my $hash_ref = $redis->hgetall('mymap');
    # get as hash
    my %hash = $redis->hgetall('mymap');

# DESCRIPTION

Redis::Cluster::Fast is like [Redis::Fast](https://github.com/shogo82148/Redis-Fast) but support Redis Cluster by [hiredis-cluster](https://github.com/Nordix/hiredis-cluster).

Require Redis 6 or higher to support [RESP3](https://github.com/antirez/RESP3/blob/master/spec.md).

# METHODS

## new(%args)

Following arguments are available.

- startup\_nodes

    Specifies the list of Redis Cluster nodes.

- connect\_timeout

    A fractional seconds. (default: 10)

    Connection timeout to connect to a Redis node.

- command\_timeout

    A fractional seconds. (default: 10)

    Redis Command execution timeout.

- max\_retry

    A integer value. (default: 10)

## &lt;command>(@args)

To run Redis command with arguments.

# LICENSE

Copyright (C) plainbanana.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

plainbanana <plainbanana@mustardon.tokyo>

# SEE ALSO

- [Redis::ClusterRider](https://github.com/iph0/Redis-ClusterRider)
- [Redis::Fast](https://github.com/shogo82148/Redis-Fast)

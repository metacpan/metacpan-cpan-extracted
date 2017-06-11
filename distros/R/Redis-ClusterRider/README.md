# NAME

Redis::ClusterRider - Daring Redis Cluster client

# SYNOPSIS

    use Redis::ClusterRider;

    my $cluster = Redis::ClusterRider->new(
      startup_nodes => [
        'localhost:7000',
        'localhost:7001',
        'localhost:7002',
      ],
    );

    $cluster->set( 'foo', 'bar' );
    my $value = $cluster->get('foo');

    print "$value\n";

# DESCRIPTION

Redis::ClusterRider is the Redis Cluster client built on top of the [Redis](https://metacpan.org/pod/Redis).

Requires Redis 3.0 or higher.

For more information about Redis Cluster see here:

- [http://redis.io/topics/cluster-tutorial](http://redis.io/topics/cluster-tutorial)
- [http://redis.io/topics/cluster-spec](http://redis.io/topics/cluster-spec)

# CONSTRUCTOR

## new( %params )

    my $cluster = Redis::ClusterRider->new(
      startup_nodes => [
        'localhost:7000',
        'localhost:7001',
        'localhost:7002',
      ],
      password         => 'yourpass',
      cnx_timeout      => 5,
      read_timeout     => 5,
      refresh_interval => 5,
      lazy             => 1,

      on_node_connect => sub {
        my $hostport = shift;

        # handling...
      },

      on_node_error => sub {
        my $err = shift;
        my $hostport = shift;

        # error handling...
      },
    );

- startup\_nodes => \\@nodes

    Specifies the list of startup nodes. Parameter should contain the array of
    addresses of some nodes in the cluster. The client will try to connect to
    random node from the list to retrieve information about all cluster nodes and
    slots mapping. If the client could not connect to first selected node, it will
    try to connect to another random node from the list.

- password => $password

    If the password is specified, the `AUTH` command is sent to all nodes
    of the cluster after connection.

- allow\_slaves => $boolean

    If enabled, the client will try to send read-only commands to slave nodes.

- cnx\_timeout => $fractional\_seconds

    The `cnx_timeout` option enables connection timeout. The client will wait at
    most that number of seconds (can be fractional) before giving up connecting to
    a server.

        cnx_timeout => 10.5,

    By default the client use kernel's connection timeout.

- read\_timeout => $fractional\_seconds

    The `read_timeout` option enables read timeout. The client will wait at most
    that number of seconds (can be fractional) before giving up when reading from
    the server.

    Not set by default.

- lazy => $boolean

    If enabled, the initial connection to the startup node establishes at time when
    you will send the first command to the cluster. By default the initial
    connection establishes after calling of the `new` method.

    Disabled by default.

- refresh\_interval => $fractional\_seconds

    Cluster state refresh interval. If set to zero, cluster state will be updated
    only on MOVED redirect.

    By default is 15 seconds.

- on\_node\_connect => $cb->($hostport)

    The `on_node_connect` callback is called when the connection to particular
    node is successfully established. To callback is passed address of the node to
    which the client was connected.

    Not set by default.

- on\_node\_error => $cb->( $err, $hostport )

    The `on_node_error` callback is called when occurred an error on particular
    node. To callback are passed two arguments: error message,
    and address of the node on which an error occurred.

    Not set by default.

See documentation on [Redis](https://metacpan.org/pod/Redis) for more options.

Attention, [Redis](https://metacpan.org/pod/Redis) options `reconnect` and `every` are redefined inside the
[Redis::ClusterRider](https://metacpan.org/pod/Redis::ClusterRider) for own purproses. User defined values for this options
will be ignored.

# COMMAND EXECUTION

## &lt;command>( \[ @args \] )

To execute the command you must call particular method with corresponding name.
If any error occurred during the command execution, the client throw an
exception.

Before the command execution, the client determines the pool of nodes, on which
the command can be executed. The pool can contain the one or more nodes
depending on the cluster and the client configurations, and the command type.
The client will try to execute the command on random node from the pool and, if
the command failed on selected node, the client will try to execute it on
another random node.

If the connection to the some node was lost, the client will try to restore the
connection when you execute next command. The client will try to reconnect only
once and, if attempt fails, the client throw an exception. If you need several
attempts of the reconnection, you must catch the exception and retry a command
as many times, as you need. Such behavior allows to control reconnection
procedure.

The full list of the Redis commands can be found here: [http://redis.io/commands](http://redis.io/commands).

    my $value   = $cluster->get('foo');
    my $list    = $cluster->lrange( 'list', 0, -1 );
    my $counter = $cluster->incr('counter');

# TRANSACTIONS

To perform the transaction you must get the master node by the key using
`nodes` method and then execute all commands on this node.

    my $node = $cluster->nodes('foo');

    $node->multi;
    $node->set( '{foo}bar', "some\r\nstring" );
    $node->set( '{foo}car', 42 );
    my $reply = $node->exec;

The detailed information about the Redis transactions can be found here:
[http://redis.io/topics/transactions](http://redis.io/topics/transactions).

# OTHER METHODS

## nodes( \[ $key \] \[, $allow\_slaves \] )

Gets particular nodes of the cluster. In scalar context method returns the
first node from the list.

Getting all master nodes of the cluster:

    my @master_nodes = $cluster->nodes;

Getting all nodes of the cluster, including slave nodes:

    my @nodes = $cluster->nodes( undef, 1 );

Getting master node by the key:

    my $master_node = $cluster->nodes('foo');

Getting nodes by the key, including slave nodes:

    my @nodes = $cluster->nodes( 'foo', 1 );

## refresh\_interval( \[ $fractional\_seconds \] )

Gets or sets the `refresh_interval` of the client. The `undef` value resets
the `refresh_interval` to default value.

# SERVICE FUNCTIONS

Service functions provided by [Redis::ClusterRider](https://metacpan.org/pod/Redis::ClusterRider) can be imported.

    use Redis::ClusterRider qw( crc16 hash_slot );

## crc16( $data )

Compute CRC16 for the specified data as defined in Redis Cluster specification.

## hash\_slot( $key );

Returns slot number by the key.

# SEE ALSO

[Redis](https://metacpan.org/pod/Redis), [AnyEvent::RipeRedis](https://metacpan.org/pod/AnyEvent::RipeRedis), [AnyEvent::RipeRedis::Cluster](https://metacpan.org/pod/AnyEvent::RipeRedis::Cluster)

# AUTHOR

Eugene Ponizovsky, <ponizovsky@gmail.com>

Sponsored by SMS Online, <dev.opensource@sms-online.com>

# COPYRIGHT AND LICENSE

Copyright (c) 2017, Eugene Ponizovsky, SMS Online. All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

# NAME

Mojo::Redis - Redis driver based on Mojo::IOLoop

# SYNOPSIS

## Blocking

    use Mojo::Redis;
    my $redis = Mojo::Redis->new;
    warn $redis->db->get("mykey");

## Promises

    $redis->db->get_p("mykey")->then(sub {
      print "mykey=$_[0]\n";
    })->catch(sub {
      warn "Could not fetch mykey: $_[0]";
    })->wait;

## Pipelining

Pipelining is built into the API by sending a lot of commands and then use
["all" in Mojo::Promise](https://metacpan.org/pod/Mojo::Promise#all) to wait for all the responses.

    Mojo::Promise->all(
      $db->set_p($key, 10),
      $db->incrby_p($key, 9),
      $db->incr_p($key),
      $db->get_p($key),
      $db->incr_p($key),
      $db->get_p($key),
    )->then(sub {
      @res = map {@$_} @_;
    })->wait;

# DESCRIPTION

[Mojo::Redis](https://metacpan.org/pod/Mojo::Redis) is a Redis driver that use the [Mojo::IOLoop](https://metacpan.org/pod/Mojo::IOLoop), which makes it
integrate easily with the [Mojolicious](https://metacpan.org/pod/Mojolicious) framework.

It tries to mimic the same interface as [Mojo::Pg](https://metacpan.org/pod/Mojo::Pg), [Mojo::mysql](https://metacpan.org/pod/Mojo::mysql) and
[Mojo::SQLite](https://metacpan.org/pod/Mojo::SQLite), but the methods for talking to the database vary.

This module is in no way compatible with the 1.xx version of [Mojo::Redis](https://metacpan.org/pod/Mojo::Redis)
and this version also tries to fix a lot of the confusing methods in
[Mojo::Redis2](https://metacpan.org/pod/Mojo::Redis2) related to pubsub.

This module is currently EXPERIMENTAL, and bad design decisions will be fixed
without warning. Please report at
[https://github.com/jhthorsen/mojo-redis/issues](https://github.com/jhthorsen/mojo-redis/issues) if you find this module
useful, annoying or if you simply find bugs. Feedback can also be sent to
`jhthorsen@cpan.org`.

# CAVEATS

[Protocol::Redis::XS](https://metacpan.org/pod/Protocol::Redis::XS) is not the default ["protocol"](#protocol) because it has some
limitations:

- Cannot handle binary data

    [Mojo::Redis::Cache](https://metacpan.org/pod/Mojo::Redis::Cache) uses [Protocol::Redis](https://metacpan.org/pod/Protocol::Redis) for now, since
    [Protocol::Redis::XS](https://metacpan.org/pod/Protocol::Redis::XS) fail to handle binary data.

    See [https://github.com/dgl/protocol-redis-xs/issues/4](https://github.com/dgl/protocol-redis-xs/issues/4) for more information.

- Cannot handle multi bulk replies with depth higher than 2

    ["xread" in Mojo::Redis::Database](https://metacpan.org/pod/Mojo::Redis::Database#xread) and other Redis commands returns complex nested
    data structures with depth higher than two. [Protocol::Redis::XS](https://metacpan.org/pod/Protocol::Redis::XS) is unable to
    handle these messages.

    See [https://github.com/dgl/protocol-redis-xs/issues/5](https://github.com/dgl/protocol-redis-xs/issues/5) for more information.

If you experience any issues with [Protocol::Redis::XS](https://metacpan.org/pod/Protocol::Redis::XS) then please report
them to [https://github.com/dgl/protocol-redis-xs/issues](https://github.com/dgl/protocol-redis-xs/issues). It is still the
default ["protocol"](#protocol) though, since it is a lot faster than [Protocol::Redis](https://metacpan.org/pod/Protocol::Redis)
for most tasks.

# EVENTS

## connection

    $cb = $redis->on(connection => sub { my ($redis, $connection) = @_; });

Emitted when [Mojo::Redis::Connection](https://metacpan.org/pod/Mojo::Redis::Connection) connects to the Redis.

# ATTRIBUTES

## encoding

    $str   = $redis->encoding;
    $redis = $redis->encoding("UTF-8");

The value of this attribute will be passed on to
["encoding" in Mojo::Redis::Connection](https://metacpan.org/pod/Mojo::Redis::Connection#encoding) when a new connection is created. This
means that updating this attribute will not change any connection that is
in use.

Default value is "UTF-8".

## max\_connections

    $int   = $redis->max_connections;
    $redis = $redis->max_connections(5);

Maximum number of idle database handles to cache for future use, defaults to
5\. (Default is subject to change)

## protocol\_class

    $str   = $redis->protocol_class;
    $redis = $redis->protocol_class("Protocol::Redis::XS");

Default to [Protocol::Redis](https://metacpan.org/pod/Protocol::Redis). This will be changed in the future, if we see a
more stable version of an alternative to [Protocol::Redis::XS](https://metacpan.org/pod/Protocol::Redis::XS).  See
["CAVEATS"](#caveats) for details.

## pubsub

    $pubsub = $redis->pubsub;

Lazy builds an instance of [Mojo::Redis::PubSub](https://metacpan.org/pod/Mojo::Redis::PubSub) for this object, instead of
returning a new instance like ["db"](#db) does.

## url

    $url   = $redis->url;
    $redis = $redis->url(Mojo::URL->new("redis://localhost/3"));

Holds an instance of [Mojo::URL](https://metacpan.org/pod/Mojo::URL) that describes how to connect to the Redis server.

# METHODS

## db

    $db = $redis->db;

Returns an instance of [Mojo::Redis::Database](https://metacpan.org/pod/Mojo::Redis::Database).

## cache

    $cache = $redis->cache(%attrs);

Returns an instance of [Mojo::Redis::Cache](https://metacpan.org/pod/Mojo::Redis::Cache).

## cursor

    $cursor = $redis->cursor(@command);

Returns an instance of [Mojo::Redis::Cursor](https://metacpan.org/pod/Mojo::Redis::Cursor) with
["command" in Mojo::Redis::Cursor](https://metacpan.org/pod/Mojo::Redis::Cursor#command) set to the arguments passed. See
["new" in Mojo::Redis::Cursor](https://metacpan.org/pod/Mojo::Redis::Cursor#new). for possible commands.

## new

    $redis = Mojo::Redis->new("redis://localhost:6379/1");
    $redis = Mojo::Redis->new(Mojo::URL->new->host("/tmp/redis.sock"));
    $redis = Mojo::Redis->new(\%attrs);
    $redis = Mojo::Redis->new(%attrs);

Object constructor. Can coerce a string into a [Mojo::URL](https://metacpan.org/pod/Mojo::URL) and set ["url"](#url)
if present.

# AUTHOR

Jan Henning Thorsen

# COPYRIGHT AND LICENSE

Copyright (C) 2018, Jan Henning Thorsen.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

# SEE ALSO

[Mojo::Redis2](https://metacpan.org/pod/Mojo::Redis2).

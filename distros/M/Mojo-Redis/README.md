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
["all" in Mojo::Promise](https://metacpan.org/pod/Mojo%3A%3APromise#all) to wait for all the responses.

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

[Mojo::Redis](https://metacpan.org/pod/Mojo%3A%3ARedis) is a Redis driver that use the [Mojo::IOLoop](https://metacpan.org/pod/Mojo%3A%3AIOLoop), which makes it
integrate easily with the [Mojolicious](https://metacpan.org/pod/Mojolicious) framework.

It tries to mimic the same interface as [Mojo::Pg](https://metacpan.org/pod/Mojo%3A%3APg), [Mojo::mysql](https://metacpan.org/pod/Mojo%3A%3Amysql) and
[Mojo::SQLite](https://metacpan.org/pod/Mojo%3A%3ASQLite), but the methods for talking to the database vary.

This module is in no way compatible with the 1.xx version of [Mojo::Redis](https://metacpan.org/pod/Mojo%3A%3ARedis)
and this version also tries to fix a lot of the confusing methods in
[Mojo::Redis2](https://metacpan.org/pod/Mojo%3A%3ARedis2) related to pubsub.

This module is currently EXPERIMENTAL, and bad design decisions will be fixed
without warning. Please report at
[https://github.com/jhthorsen/mojo-redis/issues](https://github.com/jhthorsen/mojo-redis/issues) if you find this module
useful, annoying or if you simply find bugs. Feedback can also be sent to
`jhthorsen@cpan.org`.

# EVENTS

## connection

    $cb = $redis->on(connection => sub { my ($redis, $connection) = @_; });

Emitted when [Mojo::Redis::Connection](https://metacpan.org/pod/Mojo%3A%3ARedis%3A%3AConnection) connects to the Redis.

# ATTRIBUTES

## encoding

    $str   = $redis->encoding;
    $redis = $redis->encoding("UTF-8");

The value of this attribute will be passed on to
["encoding" in Mojo::Redis::Connection](https://metacpan.org/pod/Mojo%3A%3ARedis%3A%3AConnection#encoding) when a new connection is created. This
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

Default to [Protocol::Redis::XS](https://metacpan.org/pod/Protocol%3A%3ARedis%3A%3AXS) if the optional module is available and at
least version 0.06, or falls back to [Protocol::Redis::Faster](https://metacpan.org/pod/Protocol%3A%3ARedis%3A%3AFaster).

## pubsub

    $pubsub = $redis->pubsub;

Lazy builds an instance of [Mojo::Redis::PubSub](https://metacpan.org/pod/Mojo%3A%3ARedis%3A%3APubSub) for this object, instead of
returning a new instance like ["db"](#db) does.

## url

    $url   = $redis->url;
    $redis = $redis->url(Mojo::URL->new("redis://localhost/3"));

Holds an instance of [Mojo::URL](https://metacpan.org/pod/Mojo%3A%3AURL) that describes how to connect to the Redis server.

# METHODS

## db

    $db = $redis->db;

Returns an instance of [Mojo::Redis::Database](https://metacpan.org/pod/Mojo%3A%3ARedis%3A%3ADatabase).

## cache

    $cache = $redis->cache(%attrs);

Returns an instance of [Mojo::Redis::Cache](https://metacpan.org/pod/Mojo%3A%3ARedis%3A%3ACache).

## cursor

    $cursor = $redis->cursor(@command);

Returns an instance of [Mojo::Redis::Cursor](https://metacpan.org/pod/Mojo%3A%3ARedis%3A%3ACursor) with
["command" in Mojo::Redis::Cursor](https://metacpan.org/pod/Mojo%3A%3ARedis%3A%3ACursor#command) set to the arguments passed. See
["new" in Mojo::Redis::Cursor](https://metacpan.org/pod/Mojo%3A%3ARedis%3A%3ACursor#new). for possible commands.

## new

    $redis = Mojo::Redis->new("redis://localhost:6379/1");
    $redis = Mojo::Redis->new(Mojo::URL->new->host("/tmp/redis.sock"));
    $redis = Mojo::Redis->new(\%attrs);
    $redis = Mojo::Redis->new(%attrs);

Object constructor. Can coerce a string into a [Mojo::URL](https://metacpan.org/pod/Mojo%3A%3AURL) and set ["url"](#url)
if present.

# AUTHORS

Jan Henning Thorsen - `jhthorsen@cpan.org`

Dan Book - `grinnz@grinnz.com`

# COPYRIGHT AND LICENSE

Copyright (C) 2018, Jan Henning Thorsen.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

# SEE ALSO

[Mojo::Redis2](https://metacpan.org/pod/Mojo%3A%3ARedis2).

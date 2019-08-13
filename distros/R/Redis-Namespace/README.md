[![Build Status](https://travis-ci.org/shogo82148/Redis-Namespace.svg?branch=master)](https://travis-ci.org/shogo82148/Redis-Namespace) [![MetaCPAN Release](https://badge.fury.io/pl/Redis-Namespace.svg)](https://metacpan.org/release/Redis-Namespace)
# NAME

Redis::Namespace - a wrapper of Redis.pm that namespaces all Redis calls

# SYNOPSIS

    use Redis;
    use Redis::Namespace;
    
    my $redis = Redis->new;
    my $ns = Redis::Namespace->new(redis => $redis, namespace => 'fugu');
    
    $ns->set('foo', 'bar');
    # will call $redis->set('fugu:foo', 'bar');
    
    my $foo = $ns->get('foo');
    # will call $redis->get('fugu:foo');

# DESCRIPTION

Redis::Namespace is a wrapper of Redis.pm that namespaces all Redis calls.
It is useful when you have multiple systems using Redis differently in your app.

# OPTIONS

- redis

    An instance of [Redis.pm](https://github.com/melo/perl-redis) or [Redis::Fast](https://github.com/shogo82148/Redis-Fast).

- namespace

    prefix of keys.

- guess

    If `Redis::Namespace` doesn't known the command,
    call [command info](http://redis.io/commands/command-info) and guess positions of keys.
    It is boolean value.

- strict

    It is boolean value.
    If it is true, `Redis::Namespace` doesn't execute unsafe commands
    which may break another namepace and/or change the state of redis-server, such as `FLUSHALL` and `SHUTDOWN`.
    Also, unknown commands are not executed, because there is no guarantee that the command does not break another namepace.

# AUTHOR

Ichinose Shogo <shogo82148@gmail.com>

# SEE ALSO

- [Redis](http://redis.io/)
- [Redis.pm](https://github.com/melo/perl-redis)
- [redis-namespace](https://github.com/resque/redis-namespace)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

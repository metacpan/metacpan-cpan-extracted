[![Build Status](https://travis-ci.org/shogo82148/p5-Redis-Transaction.svg?branch=master)](https://travis-ci.org/shogo82148/p5-Redis-Transaction)
# NAME

Redis::Transaction - utilities for handling transactions of Redis

# SYNOPSIS

    use Redis;
    use Redis::Transaction qw/multi_exec watch_multi_exec/;
    
    # atomically increment foo and bar. It will execute following commands typically.
    # > MULTI
    # > INCR foo
    # > INCR bar
    # > EXEC
    multi_exec Redis->new, 10, sub {
        my $redis = shift;
        $redis->incr('foo');
        $redis->incr('bar');
    };
    
    # atomically increment the value of a key by 1 (let's suppose Redis doesn't have INCR).
    # It will execute following commands typically.
    # > WATCH mykey
    # > GET mykey
    # > MULTI
    # > SET mykey, 1
    # > EXEC
    watch_multi_exec Redis->new, ['mykey'], 10, sub {
        my $redis = shift;
        return $redis->get('mykey');
    }, sub {
        my ($redis, $value) = @_;
        $redis->set('mykey', $value + 1);
    };

# DESCRIPTION

Redis::Transaction is utilities for handling transactions of Redis.

# FUNCTIONS

## `multi_exec($redis:Redis, $retry_count:Int, $code:Code)`

Queue commands and execute them atomically.

## `watch_multi_exec($redis:Redis, $watch_keys:ArrayRef, $retry_count:Int, $watch_code:Code, $exec_code:Code)`

Queue commands and execute them atomically.
`watch_multi_exec` will retry `$watch_code` and `$exec_code` if `$watch_keys` are changed by another client.

# SEE ALSO

- [Redis.pm](https://metacpan.org/pod/Redis)
- [Redis::Fast](https://metacpan.org/pod/Redis::Fast)
- [Description of Transactions](http://redis.io/topics/transactions)

# LICENSE

Copyright (C) Ichinose Shogo.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Ichinose Shogo <shogo82148@gmail.com>

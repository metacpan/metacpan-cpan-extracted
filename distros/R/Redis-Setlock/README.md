# NAME

Redis::Setlock - Like the setlock command using Redis.

# SYNOPSIS

    $ redis-setlock [-nNxX] KEY program [ arg ... ]

    --redis (Default: 127.0.0.1:6379): redis-host:redis-port
    --expires (Default: 86400): The lock will be auto-released after the expire time is reached.
    --keep: Keep the lock after invoked command exited.
    -n: No delay. If KEY is locked by another process, redis-setlock gives up.
    -N: (Default.) Delay. If KEY is locked by another process, redis-setlock waits until it can obtain a new lock.
    -x: If KEY is locked, redis-setlock exits zero.
    -X: (Default.) If KEY is locked, redis-setlock prints an error message and exits nonzero.

Using in your perl code.

    use Redis::Setlock;
    use Redis;  # or Redis::Fast
    my $redis = Redis->new( server => 'redis.example.com:6379' );
    if ( my $guard = Redis::Setlock->lock_guard($redis, "key", 60) ) {
       # got a lock!
       ...
       # unlock at guard destroyed.
    }
    else {
       # couldnot get lock
    }

# DESCRIPTION

Redis::Setlock is a like the setlock command using Redis.

# REQUIREMENTS

Redis Server >= 2.6.12.

# LICENSE

Copyright (C) FUJIWARA Shunichiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

FUJIWARA Shunichiro <fujiwara.shunichiro@gmail.com>

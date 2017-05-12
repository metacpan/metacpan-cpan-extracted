# NAME

Redis::DistLock - Distributed lock manager using Redis

# SYNOPSIS

    use Redis::DistLock;
    my $rd = Redis::DistLock->new( servers => [qw[ localhost:6379 ]] );
    my $mutex = $rd->lock( "foo", 10 );
    die( "failed to get a lock" )
        if ! $mutex;
    # ... critical section ...
    $rd->release( $mutex );

# DESCRIPTION

This is an implementation of the Redlock algorithm using Redis for distributed
lock management. It enables lightweight distributed locks in order to prevent
cronjob overruns, help with queue processing, many workers of which only one
should run at a time, and similar situations.

**NOTE**: This needs at least Redis version 2.6.12 which adds new options
to the `SET` command making this implementation possible.

# METHODS

## new( ... )

Takes a hash or hash reference with below arguments and returns a lock manager
instance. Since this module currently does not repair initially failed
connections it checks for the majority of connections or `die()`s.

- servers

    Array reference with servers to connect to or [Redis](https://metacpan.org/pod/Redis) objects to use.

- retry\_count

    Maximum number of times to try to acquire the lock. Defaults to `3`.

- retry\_delay

    Maximum delay between retries in seconds. Defaults to `0.2`.

- version\_check

    Flag to check redis server version(s) in the constructor to ensure compatibility.
    Defaults to `1`.

- logger

    Optional subroutine that will be called with errors as parameter, should any occur.
    By default, errors are currently just warnings. To disable pass `undef`.

- auto\_release

    Flag to enable automatic release of all locks when the lock manager instance
    goes out of scope. Defaults to `0`.

    **CAVEAT**: Ctrl-C'ing a running Perl script does not call DESTROY().
    This means you will have to wait for Redis to expire your locks for you if the script is killed manually.
    Even if you do implement a signal handler, it can be quite unreliable in Perl and does not guarantee
    the timeliness of your locks being released.

## lock( $resource, $ttl )

Acquire the lock for the resource with the given time to live (in seconds)
until the lock expires. Without a value generates a 32 character base64
string based on 24 random input bytes.

## lock( $resource, $ttl, $value )

Same as lock() but with a known value instead of a random string.

## lock( $resource, $ttl, $value, $extend )

Same as lock(), but given `$extend` is true it extends an existing
lock or creates a new one instead of having to unlock first.

**NOTE**: This option is EXPERIMENTAL and might change without warning!

## release( $lock )

Release the previously acquired lock.

## release( $resource, $value )

Version of release() that allows to maintain state solely in Redis when
the value is known, e.g. a hostname.

# SEE ALSO

- [http://redis.io/topics/distlock](http://redis.io/topics/distlock)
- [Redis](https://metacpan.org/pod/Redis)

# DISCLAIMER

This code implements an algorithm which is currently a proposal, it was not
formally analyzed. Make sure to understand how it works before using it in
production environments.

# ACKNOWLEDGMENT

This module was originally developed at Booking.com. With approval from
Booking.com, this module was released as open source, for which the authors
would like to express their gratitude.

# AUTHORS

- Simon Bertrang <janus@cpan.org>
- Ryan Bastic <ryan@bastic.net>

# COPYRIGHT AND LICENSE

Copyright (C) 2014 by Simon Bertrang, Ryan Bastic

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

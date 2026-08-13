package PAGI::FastAPI::RateLimit::Driver::Redis;

use v5.38;
use experimental 'class';
use version;

our $VERSION   = qv('v0.1.0');
our $AUTHORITY = 'cpan:MANWAR';

use PAGI::FastAPI::RateLimit::Driver;
use Future;

class PAGI::FastAPI::RateLimit::Driver::Redis :isa(PAGI::FastAPI::RateLimit::Driver) {
    field $redis      :param; # Async/Sync Redis handle (e.g. Mojo::Redis, Redis, Redis::Fast)
    field $key_prefix :param = 'pagi_rl:';

    method _wrap_future ($res) {
        if (ref($res) && $res->can('then')) {
            return $res;
        }
        return Future->done($res);
    }

    method increment_async ($key, $ttl) {
        my $redis_key = $key_prefix . $key;

        # Atomic INCR + EXPIRE via Lua script to prevent race conditions
        my $lua = <<~'LUA';
            local current = redis.call('INCR', KEYS[1])
            if current == 1 then
                redis.call('EXPIRE', KEYS[1], ARGV[1])
            end
            return current
        LUA

        # Supports clients with eval() or call_p() methods
        my $res;
        if ($redis->can('eval')) {
            $res = $redis->eval($lua, 1, $redis_key, $ttl);
        } elsif ($redis->can('call_p')) {
            $res = $redis->call_p('EVAL', $lua, 1, $redis_key, $ttl);
        } else {
            # Fallback for basic drivers
            my $count = $redis->incr($redis_key);
            $redis->expire($redis_key, $ttl) if $count == 1;
            $res = $count;
        }

        return $self->_wrap_future($res);
    }

    method get_async ($key) {
        my $redis_key = $key_prefix . $key;
        my $res       = $redis->get($redis_key);

        if (ref($res) && $res->can('then')) {
            return $res->then(sub ($val) {
                return Future->done($val // 0);
            });
        }

        return Future->done($res // 0);
    }

    method reset_async ($key) {
        my $redis_key = $key_prefix . $key;
        my $res       = $redis->del($redis_key);

        return $self->_wrap_future($res);
    }
}

=encoding utf-8

=head1 NAME

PAGI::FastAPI::RateLimit::Driver::Redis - Redis Storage Driver for PAGI::FastAPI Rate Limiting

=head1 VERSION

Version v0.1.0

=head1 SYNOPSIS

    use PAGI::FastAPI;
    use PAGI::FastAPI::RateLimit::Driver::Redis;
    use Redis;

    # Initialize Redis client instance
    my $redis = Redis->new(server => '127.0.0.1:6379');

    # Instantiate rate limiting driver
    my $driver = PAGI::FastAPI::RateLimit::Driver::Redis->new(
        redis      => $redis,
        key_prefix => 'api_rl:', # Optional namespace prefix
    );

    my $app = PAGI::FastAPI->new();

    # Register middleware with Redis driver
    $app->add_rate_limit(
        requests => 100,
        window   => 60,
        driver   => $driver,
    );

=head1 DESCRIPTION

C<PAGI::FastAPI::RateLimit::Driver::Redis> is a high-performance, distributed storage driver for L<PAGI::FastAPI::Middleware::RateLimit>.

It enables L<PAGI::FastAPI> web applications to maintain centralized, multi-worker hit counts across server clusters using an external Redis instance. Increments and TTL assignments are executed atomically via Lua scripts to prevent race conditions during heavy concurrent request bursts.

=head1 CONSTRUCTOR

=head2 C<new(%options)>

Instantiates a new Redis rate-limiting driver.

Accepts the following named parameters:

=over 4

=item * C<redis> (Required)

An instantiated Redis client object (e.g., L<Redis>, L<Redis::Fast>, or L<Mojo::Redis>).

=item * C<key_prefix> (Optional)

A scalar string prepended to keys inside Redis to avoid key collisions. Defaults to C<'pagi_rl:'>.

=back

=head1 METHODS

Inherits all methods from L<PAGI::FastAPI::RateLimit::Driver>.

=head2 C<increment_async($key, $ttl)>

    my $future = $driver->increment_async($key, $ttl);

Atomically increments the request counter for C<$key> and sets the TTL window if the bucket is new.

Returns a L<Future> resolving to an integer containing the updated hit count.

=head2 C<get_async($key)>

    my $future = $driver->get_async($key);

Fetches the current request count for C<$key> without altering its TTL.

Returns a L<Future> resolving to an integer hit count (or C<0> if the key does not exist or has expired).

=head2 C<reset_async($key)>

    my $future = $driver->reset_async($key);

Deletes the key immediately from Redis.

Returns a L<Future> resolving to a true value on success.

=head1 SEE ALSO

L<PAGI::FastAPI::RateLimit::Driver>, L<PAGI::FastAPI::Middleware::RateLimit>, L<Redis>

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/PAGI-FastAPI-RateLimit-Driver-Redis>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/PAGI-FastAPI-RateLimit-Driver-Redis/issues>.
I will be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PAGI::FastAPI::RateLimit::Driver::Redis

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/PAGI-FastAPI-RateLimit-Driver-Redis/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PAGI-FastAPI-RateLimit-Driver-Redis>

=item * Search MetaCPAN

L<https://metacpan.org/dist/PAGI-FastAPI-RateLimit-Driver-Redis/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License (2.0).

=cut

1; # End of PAGI::FastAPI::RateLimit::Driver::Redis

package PAGI::FastAPI::Middleware::RateLimit;

use v5.38;
use experimental 'class';
use version;

our $VERSION   = qv('v1.2.4');
our $AUTHORITY = 'cpan:MANWAR';

use Future::AsyncAwait;
use PAGI::FastAPI::RateLimit::Driver::Memory;

class PAGI::FastAPI::Middleware::RateLimit {
    field $requests :param = 100;
    field $window   :param = 60;
    field $key_cb   :param = undef;
    field $driver   :param = undef;

    ADJUST {
        $driver //= PAGI::FastAPI::RateLimit::Driver::Memory->new();
        $key_cb //= sub ($c) {
            return $c->header('X-API-Key')
                // $c->header('X-Forwarded-For')
                // $c->scope->{client}[0]
                // '127.0.0.1';
        };
    }

    async method handle ($c, $next) {
        my $key = $key_cb->($c);

        # Option A: If increment_async returns a HashRef: { count => Int, reset_at => Epoch }
        # Option B: If Driver provides reset calculation helper
        my ($count, $reset_at) = await $driver->increment_async($key, $window);

        my $remaining = $requests - $count;
        $remaining    = 0 if $remaining < 0;

        my $now         = time();
        my $retry_after = ($reset_at // ($now + $window)) - $now;
        $retry_after    = 1 if $retry_after <= 0;

        # add_header (not set_header): when multiple RateLimit middleware
        # instances are stacked (e.g. an app-wide limiter plus a per-route
        # limiter), each layer's budget is independent and all of them
        # should be visible on the response, so these are intentionally
        # allowed to appear more than once.
        $c->add_header('x-ratelimit-limit'     => $requests);
        $c->add_header('x-ratelimit-remaining' => $remaining);
        $c->add_header('x-ratelimit-reset'     => $reset_at) if $reset_at;

        if ($count > $requests) {
            $c->status(429);
            $c->set_header('retry-after' => $retry_after);
            return {
                detail      => 'Too Many Requests',
                message     => 'API rate limit exceeded. Please try again later.',
                retry_after => $retry_after,
            };
        }

        return await $next->($c);
    }
}

=encoding utf-8

=head1 NAME

PAGI::FastAPI::Middleware::RateLimit - Async Rate Limiting Middleware for PAGI::FastAPI

=head1 VERSION

Version v1.2.4

=head1 SYNOPSIS

    # Application-wide rate limiting
    use PAGI::FastAPI;

    my $app = PAGI::FastAPI->new();

    $app->add_rate_limit(
        requests => 100,
        window   => 60, # 100 requests per 60 seconds
    );

    # Custom rate-limiting key based on authenticated user
    $app->add_rate_limit(
        requests => 50,
        window   => 30,
        key_cb   => sub ($c) {
            return $c->stash->{user_id} // $c->header('X-API-Key') // 'anonymous';
        },
    );

    # Direct instantiation
    use PAGI::FastAPI::Middleware::RateLimit;

    my $limiter = PAGI::FastAPI::Middleware::RateLimit->new(
        requests => 500,
        window   => 3600,
    );

    $app->add_middleware(async sub ($c, $next) {
        return await $limiter->handle($c, $next);
    });

=head1 DESCRIPTION

C<PAGI::FastAPI::Middleware::RateLimit> provides asynchronous, non-blocking rate
limiting for L<PAGI::FastAPI> applications using fixed time-window counters.

When a client sends a request, the middleware evaluates a unique key identifying
the client (e.g., API key or IP address), increments the tracking counter for the
active window, and appends standard rate-limiting headers to the HTTP response.

If a client exceeds their allocated quota within the configured timeframe, the
middleware short-circuits execution, sets the response status to C<HTTP 429 Too Many Requests>,
and returns a standardized JSON error payload detailing the restriction.

=head1 HTTP HEADERS

The middleware injects the following response headers into all evaluated requests:

=over 4

=item * C<x-ratelimit-limit> - Maximum number of allowed requests per window.

=item * C<x-ratelimit-remaining> - Remaining request quota in the current window.

=item * C<x-ratelimit-reset> - Unix timestamp indicating when the current window expires.

=back

When the limit is exceeded (HTTP 429), an additional header is included:

=over 4

=item * C<retry-after> - Number of seconds the client must wait before retrying.

=back

=head1 METHODS

=head2 C<new(%options)>

Instantiates a new C<PAGI::FastAPI::Middleware::RateLimit> instance. Accepts
the following named arguments:

=over 4

=item * C<requests> - Optional integer. Maximum number of allowed requests
per window. Default: C<100>.

=item * C<window> - Optional integer. Duration of the rate-limiting window
in seconds. Default: C<60>.

=item * C<key_cb> - Optional C<CODE> reference accepting a
L<PAGI::FastAPI::Context> instance (C<$c>) and returning a unique scalar
string key identifying the client. By default, it falls back through:

1. C<X-API-Key> request header
2. C<X-Forwarded-For> request header
3. Client connection remote IP address (C<< $c->scope->{client}[0] >>)
4. Fallback default string C<'127.0.0.1'>

=item * C<driver> - Optional storage object implementing
C<increment_async($key, $window)>, C<get_async($key)> and C<reset_async($key)>.
Defaults to an instance of L<PAGI::FastAPI::RateLimit::Driver::Memory>.

=back

=head2 C<handle($c, $next)>

    my $res = await $limiter->handle($c, $next);

Asynchronous method that executes the rate-limiting logic within the request
pipeline:

=over 4

=item 1. Evaluates the client key using C<key_cb>.

=item 2. Queries and increments the request count in the configured C<driver>.

=item 3. Appends standard rate limit HTTP headers (C<x-ratelimit-*>) to C<$c>.

=item 4. Returns an HTTP 429 JSON response if the request limit is exceeded.

=item 5. Awaits and returns C<< $next->($c) >> if the client is within quota.

=back

=head1 ERROR RESPONSE STRUCTURE

When a request is rate-limited (HTTP status 429), the returned JSON structure is:

    {
        "detail": "Too Many Requests",
        "message": "API rate limit exceeded. Please try again later.",
        "retry_after": 45
    }

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/PAGI-FastAPI>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/PAGI-FastAPI/issues>.
I will be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PAGI::FastAPI::Middleware::RateLimit

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/PAGI-FastAPI/issues>

=item * Search MetaCPAN

L<https://metacpan.org/dist/PAGI-FastAPI/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License (2.0).

=cut

1; # End of PAGI::FastAPI::Middleware::RateLimit

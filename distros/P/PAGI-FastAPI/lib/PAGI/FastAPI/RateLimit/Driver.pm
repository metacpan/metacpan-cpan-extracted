package PAGI::FastAPI::RateLimit::Driver;

use v5.38;
use experimental 'class';
use version;

our $VERSION   = qv('v1.1.0');
our $AUTHORITY = 'cpan:MANWAR';

class PAGI::FastAPI::RateLimit::Driver {

    method increment_async ($key, $ttl) {
        die "Driver subclass must implement 'increment_async'";
    }

    method get_async ($key) {
        die "Driver subclass must implement 'get_async'";
    }

    method reset_async ($key) {
        die "Driver subclass must implement 'reset_async'";
    }
}

=encoding utf-8

=head1 NAME

PAGI::FastAPI::RateLimit::Driver - Abstract Base Class for Rate Limiting Storage Drivers

=head1 VERSION

Version v1.1.0

=head1 SYNOPSIS

    package PAGI::FastAPI::RateLimit::Driver::Custom;

    use v5.38;
    use experimental 'class';
    use Future;

    class PAGI::FastAPI::RateLimit::Driver::Custom :isa(PAGI::FastAPI::RateLimit::Driver) {

        method increment_async ($key, $ttl) {
            # Increment hit count for $key asynchronously...
            return Future->done($new_count, $expires_at);
        }

        method get_async ($key) {
            # Fetch current hit count asynchronously...
            return Future->done($current_count);
        }

        method reset_async ($key) {
            # Clear stored hit count for $key...
            return Future->done(1);
        }
    }

=head1 DESCRIPTION

C<PAGI::FastAPI::RateLimit::Driver> defines the abstract async interface for
all rate-limiting storage backends used by L<PAGI::FastAPI::Middleware::RateLimit>.

Custom storage drivers (e.g., Redis, Memcached, DynamoDB) must inherit from
this class and implement its asynchronous methods, ensuring they return
L<Future> instances to maintain non-blocking behavior inside the PAGI event
loop.

As of version C<v1.0.0>, we have built-in support for in memory rate limit by
L<PAGI::FastAPI::RateLimit::Driver::Memory>.

We even have demo app created for in memory rate limit: C<eg/rate_limit_demo.pl>

If you are looking for more specialised options then you have the following
choices as separate companion packages: L<PAGI::FastAPI::RateLimit::Driver::CHI>
and L<PAGI::FastAPI::RateLimit::Driver::Redis>.

=head1 REQUIRED METHODS

Subclasses B<must> override the following methods. Calling any of these
directly on the base class will throw an exception.

=head2 C<increment_async($key, $ttl)>

    my $future = $driver->increment_async($key, $ttl);
    my ($count, $expires_at) = $future->get;

Increments the request hit counter for the specified C<$key> by 1 and sets
or updates its Time-To-Live (C<$ttl>) in seconds.

=over 4

=item * C<$key>  -  Scalar string uniquely identifying the client bucket (e.g., IP address, API key, user ID).

=item * C<$ttl>  -  Integer window duration in seconds.

=back

Returns a L<Future> resolving to a two-element list C<($count, $expires_at)>:

=over 4

=item * C<$count> - Integer representing the updated hit count for the key.

=item * C<$expires_at> - Unix epoch timestamp at which the current window
resets. Should remain stable across calls within the same window (i.e. set
once on the first hit, not recalculated on every increment).

=back

B<Note:> L<PAGI::FastAPI::Middleware::RateLimit> reads both values via list
assignment (C<< my ($count, $reset_at) = await $driver->increment_async(...) >>)
and uses C<$expires_at> to populate the C<x-ratelimit-reset> response header
and to compute C<retry-after> on a C<429>. A driver that resolves with only
a single value will leave C<$expires_at> C<undef>, silently disabling the
C<x-ratelimit-reset> header and making C<retry-after> fall back to the full
window length rather than the time actually remaining in it.

=head2 C<get_async($key)>

    my $future = $driver->get_async($key);

Retrieves the current hit count for the specified C<$key> without altering
its expiration.

Returns a L<Future> resolving to an integer (C<0> if the key does not exist
or has expired).

=head2 C<reset_async($key)>

    my $future = $driver->reset_async($key);

Clears or expires the tracking record for C<$key> immediately.

Returns a L<Future> resolving to a boolean true value on success.

=head1 SEE ALSO

L<PAGI::FastAPI::RateLimit::Driver::Memory>, L<PAGI::FastAPI::Middleware::RateLimit>

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

    perldoc PAGI::FastAPI::RateLimit::Driver

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/PAGI-FastAPI/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PAGI-FastAPI>

=item * Search MetaCPAN

L<https://metacpan.org/dist/PAGI-FastAPI/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License (2.0).

=cut

1; # End of PAGI::FastAPI::RateLimit::Driver

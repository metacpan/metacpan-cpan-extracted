package PAGI::FastAPI::RateLimit::Driver::CHI;

use v5.38;
use experimental 'class';
use version;

our $VERSION   = qv('v0.0.1');
our $AUTHORITY = 'cpan:MANWAR';

use PAGI::FastAPI::RateLimit::Driver;
use Future;

class PAGI::FastAPI::RateLimit::Driver::CHI :isa(PAGI::FastAPI::RateLimit::Driver) {
    field $chi        :param; # Any CHI instance (e.g. Memcached, File, FastMmap)
    field $key_prefix :param = 'pagi_rl:';

    method increment_async ($key, $ttl) {
        my $chi_key = $key_prefix . $key;
        my $now     = time();

        my $record = $chi->get($chi_key) // { count => 0, reset_at => $now + $ttl };

        # Reset bucket if window expired
        if ($now >= $record->{reset_at}) {
            $record->{count}    = 0;
            $record->{reset_at} = $now + $ttl;
        }

        $record->{count}++;

        # Calculate remaining duration for CHI TTL
        my $expires_in = $record->{reset_at} - $now;
        $expires_in = 1 if $expires_in <= 0;

        $chi->set($chi_key, $record, "${expires_in}s");

        return Future->done($record->{count});
    }

    method get_async ($key) {
        my $chi_key = $key_prefix . $key;
        my $record  = $chi->get($chi_key);

        if ($record && time() < $record->{reset_at}) {
            return Future->done($record->{count});
        }

        return Future->done(0);
    }

    method reset_async ($key) {
        my $chi_key = $key_prefix . $key;
        $chi->remove($chi_key);
        return Future->done(1);
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

PAGI::FastAPI::RateLimit::Driver::CHI - CHI Storage Driver for PAGI::FastAPI Rate Limiting

=head1 VERSION

Version v0.0.1

=head1 SYNOPSIS

    use PAGI::FastAPI;
    use PAGI::FastAPI::RateLimit::Driver::CHI;
    use CHI;

    # Initialise any CHI driver instance
    my $chi = CHI->new(
        driver    => 'Memcached',
        servers   => [ "127.0.0.1:11211" ],
        namespace => 'pagi_rate_limit',
    );

    # Instantiate the rate limiting driver
    my $driver = PAGI::FastAPI::RateLimit::Driver::CHI->new(
        chi        => $chi,
        key_prefix => 'api_rl:', # Optional custom prefix
    );

    my $app = PAGI::FastAPI->new();

    # Register rate limiter with the CHI driver
    $app->add_rate_limit(
        requests => 100,
        window   => 60,
        driver   => $driver,
    );

=head1 DESCRIPTION

C<PAGI::FastAPI::RateLimit::Driver::CHI> is a storage driver plugin for
L<PAGI::FastAPI::Middleware::RateLimit>. It enables L<PAGI::FastAPI>
applications to leverage any caching backend supported by L<CHI>, including
C<Memcached>, C<Redis>, C<FastMmap>, C<SharedMemory>, and C<File-based> caches.

By delegating state management to CHI, you can easily share rate-limiting
hit counters across multiple web server worker processes or distributed
application nodes.

=head1 CONSTRUCTOR

=head2 C<new(%options)>

Instantiates a new CHI rate-limiting driver.

Accepts the following named parameters:

=over 4

=item * C<chi> (Required)

An initialised L<CHI> cache instance.

=item * C<key_prefix> (Optional)

A scalar string prepended to keys inside the CHI cache to prevent namespace
collisions. Defaults to C<'pagi_rl:'>.

=back

=head1 METHODS

Inherits all methods from L<PAGI::FastAPI::RateLimit::Driver>.

=head2 C<increment_async($key, $ttl)>

    my $future = $driver->increment_async($key, $ttl);

Increments the hit count for C<$key> by C<1> within the CHI cache and
manages window expiration timestamps.

Returns a L<Future> resolving to an integer containing the updated request
count.

=head2 C<get_async($key)>

    my $future = $driver->get_async($key);

Fetches the current hit count for C<$key> from the CHI cache if the active
window has not expired.

Returns a L<Future> resolving to an integer hit count (or C<0> if missing
or expired).

=head2 C<reset_async($key)>

    my $future = $driver->reset_async($key);

Removes the tracked record for C<$key> immediately from the CHI cache.

Returns a L<Future> resolving to C<1>.

=head1 CAVEATS AND PERFORMANCE NOTES

L<CHI> provides a synchronous caching interface. While this driver wraps
responses inside L<Future> objects to maintain full compatibility with
PAGI's async middleware pipeline, blocking CHI backends (such as direct
file access or slow network calls) may block the event loop.

For maximum async throughput in high-concurrency environments, consider
using native asynchronous drivers like C<PAGI::FastAPI::RateLimit::Driver::Redis>.

=head1 SEE ALSO

L<PAGI::FastAPI::RateLimit::Driver>, L<PAGI::FastAPI::Middleware::RateLimit>, L<CHI>

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/PAGI-FastAPI-RateLimit-Driver-CHI>

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/manwar/PAGI-FastAPI-RateLimit-Driver-CHI/issues>. I
will be notified and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PAGI::FastAPI::RateLimit::Driver::CHI

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

1; # End of PAGI::FastAPI::RateLimit::Driver::CHI

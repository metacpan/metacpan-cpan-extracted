package PAGI::FastAPI::RateLimit::Driver::Memory;

use v5.38;
use experimental 'class';
use version;

our $VERSION   = qv('v1.0.0');
our $AUTHORITY = 'cpan:MANWAR';

use PAGI::FastAPI::RateLimit::Driver;

class PAGI::FastAPI::RateLimit::Driver::Memory :isa(PAGI::FastAPI::RateLimit::Driver) {
    use Future;

    field %_storage; # $key => { count => Int, expires_at => EpochInt }

    method _purge_expired ($key) {
        if (exists $_storage{$key} && $_storage{$key}{expires_at} <= time) {
            delete $_storage{$key};
        }
    }

    method increment_async ($key, $ttl) {
        $self->_purge_expired($key);

        my $now = time;
        if (!exists $_storage{$key}) {
            $_storage{$key} = {
                count      => 1,
                expires_at => $now + $ttl,
            };
        } else {
            $_storage{$key}{count}++;
        }

        return Future->done($_storage{$key}{count}, $_storage{$key}{expires_at});
    }

    method get_async ($key) {
        $self->_purge_expired($key);
        my $count = $_storage{$key} ? $_storage{$key}{count} : 0;
        return Future->done($count);
    }

    method reset_async ($key) {
        delete $_storage{$key};
        return Future->done(1);
    }
}

=encoding utf-8

=head1 NAME

PAGI::FastAPI::RateLimit::Driver::Memory - Default In-Memory Storage Driver for Rate Limiting

=head1 VERSION

Version v1.0.0

=head1 SYNOPSIS

    use PAGI::FastAPI::RateLimit::Driver::Memory;

    my $driver = PAGI::FastAPI::RateLimit::Driver::Memory->new();

    # Increment hit count for key 'client_127.0.0.1' with a 60-second window
    $driver->increment_async('client_127.0.0.1', 60)->then(sub ($count, $expires_at) {
        print "Current request count: $count (resets at $expires_at)\n";
    });

    # Retrieve current hits
    $driver->get_async('client_127.0.0.1')->then(sub ($count) {
        print "Hits: $count\n";
    });

    # Reset quota
    $driver->reset_async('client_127.0.0.1');

=head1 DESCRIPTION

C<PAGI::FastAPI::RateLimit::Driver::Memory> is the default, in-memory
implementation of L<PAGI::FastAPI::RateLimit::Driver>. It ships directly
with the core L<PAGI::FastAPI> distribution.

It tracks request hits and window expirations per key inside an in-process
hash table. Expired keys are automatically purged on access.

B<Note:> Storage is maintained entirely in process memory. Hit counters are
B<not> shared across multi-process workers (e.g., Starman, Hypnotoad) or
distributed server environments. For production clusters, install a
distributed storage driver such as C<PAGI::FastAPI::RateLimit::Driver::Redis>.

=head1 METHODS

Inherits all methods from L<PAGI::FastAPI::RateLimit::Driver>.

=head2 C<new()>

Instantiates a new in-memory rate limiting driver. Takes no required arguments.

=head2 C<increment_async($key, $ttl)>

Purges any expired record for C<$key>, increments its counter, sets the
expiration timestamp if missing, and returns a L<Future> resolving to a
two-element list C<($count, $expires_at)>: the updated integer hit count and
the Unix epoch timestamp at which the window resets. C<$expires_at> is set
once, on the first hit of a window, and held steady for the rest of that
window.

=head2 C<get_async($key)>

Purges any expired record for C<$key> and returns a L<Future> resolving to
its current integer hit count (or C<0> if absent/expired).

=head2 C<reset_async($key)>

Removes C<$key> from internal storage and returns a L<Future> resolving to C<1>.

=head1 SEE ALSO

L<PAGI::FastAPI::RateLimit::Driver>, L<PAGI::FastAPI::Middleware::RateLimit>

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

    perldoc PAGI::FastAPI::RateLimit::Driver::Memory

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

1; # End of PAGI::FastAPI::RateLimit::Driver::Memory

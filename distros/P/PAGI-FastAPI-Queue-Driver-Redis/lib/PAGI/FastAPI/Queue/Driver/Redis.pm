package PAGI::FastAPI::Queue::Driver::Redis;

use v5.38;
use experimental 'class';
use version;

our $VERSION   = qv('v0.0.1');
our $AUTHORITY = 'cpan:MANWAR';

use Future;
use Future::AsyncAwait;
use JSON::PP;

use PAGI::FastAPI::Queue::Driver;

class PAGI::FastAPI::Queue::Driver::Redis :isa(PAGI::FastAPI::Queue::Driver) {
    field $redis      :param = undef;
    field $host       :param = '127.0.0.1';
    field $port       :param = 6379;
    field $uri        :param = undef;
    field $username   :param = undef;
    field $password   :param = undef;
    field $database   :param = undef;
    field $prefix     :param = 'pagi:queue:';
    field $scan_count :param = 100;

    field $connect_future;
    field $json = JSON::PP->new->allow_nonref->canonical;

    ADJUST {
        unless (defined $redis) {
            require Async::Redis;

            my %opts = (host => $host, port => $port);
            $opts{uri}      = $uri      if defined $uri;
            $opts{username} = $username if defined $username;
            $opts{password} = $password if defined $password;
            $opts{database} = $database if defined $database;

            $redis = Async::Redis->new(%opts);
        }
    }

    method _key ($topic) {
        return "$prefix$topic";
    }

    # Connects lazily (and only once) on first use, rather than in ADJUST,
    # since connecting is asynchronous and ADJUST cannot await.
    async method _client () {
        $connect_future //= $redis->connect;
        await $connect_future;
        return $redis;
    }

    async method push ($topic, $payload) {
        my $client = await $self->_client;
        await $client->rpush($self->_key($topic), $json->encode($payload));
        return 1;
    }

    async method pop ($topic) {
        my $client = await $self->_client;
        my $raw    = await $client->lpop($self->_key($topic));
        return undef unless defined $raw;
        return $json->decode($raw);
    }

    async method size ($topic = undef) {
        my $client = await $self->_client;

        if (defined $topic) {
            return await $client->llen($self->_key($topic));
        }

        my $total  = 0;
        my $cursor = 0;
        do {
            my ($next_cursor, $keys) = await $client->scan(
                $cursor, 'MATCH', "$prefix*", 'COUNT', $scan_count,
            );
            $cursor = $next_cursor;

            if (@$keys) {
                my @lens = await Future->needs_all(
                    map { $client->llen($_) } @$keys
                );
                $total += $_ for @lens;
            }
        } while ($cursor != 0);

        return $total;
    }

    # Not part of the PAGI::FastAPI::Queue::Driver contract. Call from an
    # $app->on_shutdown() hook to release the underlying connection cleanly.
    method disconnect () {
        $redis->disconnect if $redis;
        return 1;
    }
}

=encoding utf-8

=head1 NAME

PAGI::FastAPI::Queue::Driver::Redis - Redis Storage Driver for PAGI::FastAPI::Queue

=head1 VERSION

Version v0.0.1

=head1 SYNOPSIS

    use PAGI::FastAPI::Queue;
    use PAGI::FastAPI::Depends qw(Depends);

    my $queue = PAGI::FastAPI::Queue->new(
        driver  => 'PAGI::FastAPI::Queue::Driver::Redis',
        options => {
            host   => '127.0.0.1',
            port   => 6379,
            prefix => 'myapp:queue:',
        },
    );

    $app->post('/jobs',
        dependencies => [ Depends($queue->dep, key => 'queue') ],
        handler      => async sub ($c) {
            await $c->stash->{queue}->push('emails', { to => 'a@b.com' });
            return { queued => 1 };
        },
    );

    # Release the connection on shutdown (optional; not part of the
    # PAGI::FastAPI::Queue::Driver contract, so reach the driver directly)
    $app->on_shutdown(async sub {
        # e.g. if you kept a reference to the driver instance yourself
        # $driver->disconnect;
    });

=head1 DESCRIPTION

C<PAGI::FastAPI::Queue::Driver::Redis> is a storage driver plugin for
L<PAGI::FastAPI::Queue>. It stores each topic as a Redis list (C<RPUSH> to
enqueue, C<LPOP> to dequeue), so queued items are shared across every
worker process and host pointed at the same Redis instance and C<prefix>,
unlike the built-in L<PAGI::FastAPI::Queue::Driver::Memory>, which is
scoped to a single process.

Payloads (any Perl scalar - including hashrefs/arrayrefs) are serialised
with L<JSON::PP> before being stored, and deserialised on C<pop>, so the
round-trip behaviour matches L<PAGI::FastAPI::Queue::Driver::Memory> for
any JSON-representable value.

=head2 Why L<Async::Redis> and not L<Net::Async::Redis>?

L<PAGI::FastAPI> documents L<Future::IO> as the event-loop-agnostic
target for anything loop-driven, with L<IO::Async> (used by the reference
C<PAGI::Server>) treated as an implementation detail applications
shouldn't depend on directly (see
L<PAGI::FastAPI/"EVENT LOOPS: FUTURE::IO IS THE GOAL, IO::ASYNC IS AN
IMPLEMENTATION DETAIL">). L<Async::Redis> is built directly on
L<Future::IO> rather than tying itself to L<IO::Async>, so this driver
keeps working regardless of which backend a given PAGI server ends up
using, with no reactor-bridging required.

=head2 Aggregate C<size()> and C<SCAN>

Unlike L<PAGI::FastAPI::Queue::Driver::Memory>, Redis has no O(1) way to
enumerate "every list under this driver". C<size()> with no C<$topic>
therefore walks the keyspace with Redis's cursor-based C<SCAN> command
(never the blocking C<KEYS> command), matching on C<"$prefix*">, and sums
C<LLEN> across whatever keys it finds. This is a best-effort snapshot, not
an atomic one: concurrent pushes/pops elsewhere during the scan can make
the total slightly stale. Prefer C<size($topic)> when you only care about
one topic; it's a single C<LLEN> call.

=head1 METHODS

Inherits C<push>, C<pop>, and C<size> from L<PAGI::FastAPI::Queue::Driver>.

=head2 C<new(%options)>

=over 4

=item * C<redis> - (Optional) A pre-built, C<Async::Redis>-compatible
client instance to use instead of constructing one. Useful for sharing a
single connection across multiple drivers, for supplying your own
pre-configured client (TLS, auth, custom timeouts), or for injecting a
test double. When given, C<host>/C<port>/C<uri>/C<username>/C<password>/
C<database> are ignored.

=item * C<host> - (Optional) Redis host. Defaults to C<'127.0.0.1'>.

=item * C<port> - (Optional) Redis port. Defaults to C<6379>.

=item * C<uri> - (Optional) A full C<redis://> connection URI, forwarded
to C<Async::Redis-E<gt>new> as-is. When given together with C<host>/
C<port>, C<uri> takes precedence in C<Async::Redis> itself.

=item * C<username> / C<password> - (Optional) Redis 6+ ACL / AUTH
credentials.

=item * C<database> - (Optional) Redis logical database index to C<SELECT>.

=item * C<prefix> - (Optional) Key namespace prefix. Defaults to
C<'pagi:queue:'>. Each topic is stored under C<"$prefix$topic">. Use a
distinct C<prefix> per application when sharing one Redis instance across
multiple apps.

=item * C<scan_count> - (Optional) C<COUNT> hint passed to each C<SCAN>
call made by aggregate C<size()>. Defaults to C<100>. Higher values mean
fewer round-trips but larger batches per call.

=back

The underlying client connects lazily: no network I/O happens in C<new()>
or C<ADJUST>, only on the first C<push>/C<pop>/C<size> call, and only
once per driver instance.

=head2 C<disconnect()>

Not part of the L<PAGI::FastAPI::Queue::Driver> contract and not exposed
through L<PAGI::FastAPI::Queue>. Closes the underlying client connection.
Call it directly on the driver instance (not through C<PAGI::FastAPI::Queue>,
which does not expose its backend) from an C<< $app->on_shutdown >> hook
if you want a clean shutdown. Synchronous (does not return a L<Future>).
Safe to skip; the OS reclaims the socket on process exit regardless.

=head1 DEPENDENCIES

Requires L<Async::Redis> (not installed automatically as a hard
C<PREREQ_PM> dependency solely because C<redis> can also be supplied
pre-built by the caller; if you don't pass C<redis>, install
L<Async::Redis> yourself).

=head1 SEE ALSO

L<PAGI::FastAPI::Queue>, L<PAGI::FastAPI::Queue::Driver>,
L<PAGI::FastAPI::Queue::Driver::Memory>, L<Async::Redis>

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/PAGI-FastAPI-Queue-Driver-Redis>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/PAGI-FastAPI-Queue-Driver-Redis/issues>.
I will be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PAGI::FastAPI::Queue::Driver::Redis

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/PAGI-FastAPI-Queue-Driver-Redis/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PAGI-FastAPI-Queue-Driver-Redis>

=item * Search MetaCPAN

L<https://metacpan.org/dist/PAGI-FastAPI-Queue-Driver-Redis/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License (2.0).

=cut

1; # End of PAGI::FastAPI::Queue::Driver::Redis

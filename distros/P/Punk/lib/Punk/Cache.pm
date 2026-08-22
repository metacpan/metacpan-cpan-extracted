package Punk::Cache;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.28';

# All of it is C (include/punk/punk_cachefront.h + xs/cache.xs).

1;

__END__

=head1 NAME

Punk::Cache - a pluggable cache with TTL

=head1 SYNOPSIS

    cache 'file', dir => '/var/cache/myapp', max_bytes => '512M';

    get '/profile/:id' => sub {
        my ($c) = @_;
        my $html = $c->cache->compute("profile:" . $c->param('id'), 300, sub {
            render_expensive_thing($c);
        });
        $c->html($html);
    };

=head1 DESCRIPTION

A key/value cache with expiry, compute-if-missing, and two shipped stores.

=head2 compute is the method that matters

    my $v = $c->cache->compute($key, $ttl, sub { ... });

Get, and on a miss run the code, store the result and return it. Offering only
C<get> and C<set> invites every application to write the same three lines by
hand, and to get the C<undef> case wrong.

B<A cached undef is a value.> If the code returns C<undef> and that is not
stored, an expensive lookup that legitimately finds nothing is repeated on
every request - which is exactly the traffic a cache exists to stop, and the
case people meet when they cache "does this user exist".

=head2 Values are BYTES

The trap in a pluggable cache is a store that can hold more than its siblings.
An in-memory store will happily keep a blessed object or a coderef; a file
store cannot. An application written against memory then breaks when somebody
switches it to files - in production, on the one value that happened to be a
reference.

So the contract is bytes, uniformly, and every backend stores exactly the same
things. For a structure, pass C<< json => 1 >> and it is encoded and decoded
around the store:

    my $data = $c->cache->compute($key, 60, sub { {...} }, json => 1);

=head2 Which backend, and why file is the default

C<file> is the default, and the arithmetic is the reason.

An in-memory store lives in one process, so under a prefork server B<every
worker has its own>: C<< workers => 8 >> with a 512M cap is four gigabytes of
RSS, and every worker caches the same things separately. The filesystem is
already shared, so a file store is B<one copy for the whole pool>, and it
survives a restart.

A file hit costs about six microseconds against five nanoseconds for memory.
That ratio sounds decisive and is not: six microseconds is nothing beside a
request that is about to render a template or query a database.

Reach for C<memory> when values are small, the hit rate is high, and the
duplication is affordable.

=head2 A memory tier in front, and what it costs

    cache 'file', dir        => '/var/cache/app',
                  max_bytes  => '2G',
                  memory     => '64M',    # per worker
                  memory_ttl => 5;        # seconds

C<memory> puts a byte-budgeted cache in front of the store, so a hot key is
answered without touching it

B<Read what it costs before reaching for it.> A file store is one copy for the
whole pool, so a write is visible everywhere the moment it lands. A tier is a
copy B<per worker>, which trades that away for speed:

=over 4

=item * B<The store stops being instantly consistent.> It becomes eventually
consistent, bounded by C<memory_ttl> and by the invalidation reaching each
worker. Every write publishes and every other worker drops its copy, but that
is asynchronous and, like all invalidation here, best effort.

=item * B<The memory is multiplied again.> C<< memory => '64M' >> under
C<< workers => 8 >> is half a gigabyte, which is the arithmetic that made the
file store the default in the first place.

=back

So it is off unless asked for, and it is worth asking for when a small set of
keys is read far more often than it is written.

C<memory_ttl> is a ceiling on how long a value may be answered from the tier,
five seconds by default, and it is not the same thing as the entry's own TTL.
A tier entry never outlives the entry it stands in for - it inherits that
expiry - and the ceiling only ever shortens it. Setting it low costs one read
of the store per key per period and buys a tighter bound on how stale a worker
can be if an invalidation is dropped.

A tier is only allowed in front of a store that is shared. Memory in front of
memory multiplies the footprint and caches nothing new, so it croaks at boot
rather than being built.

=head2 Named stores

    cache 'file', dir => '/var/cache/app';             # the default
    cache pages    => { backend => 'memory', max_bytes => '64M' };
    cache sessions => { backend => 'file', dir => '/var/cache/sessions' };

    $c->cache;               # the default
    $c->cache('pages');      # a named one

A name with a hashref declares a named store, exactly as C<ua> and C<views>
do; anything else configures the default.

Worth having because different caches want different things. A session store
holds many small values that must not be evicted by a page store holding a few
large ones - share one budget and the big cold thing pushes out the small hot
thing. Different backends, too: rendered pages in memory where a worker serving
the same page repeatedly is worth the duplication, and the sessions on disk so
the whole pool shares one copy.

That way round, deliberately. Sessions are the one thing that must B<not> go in
a per-worker store: L<Punk::Session::Store> refuses one at boot, because a
session written on worker A is missing on worker B, which is a logout at random
once per request.

Asking for a name that was never declared croaks. A store that silently never
hits is worse than an error, because it looks like a working cache with a
disappointing hit rate.

=head2 Invalidation across the worker pool

A store that is not shared between workers is told when a key changes, over
L<Hyperman>'s message bus. The file store needs none of this - every worker
sees the same files, which is what makes it the default.

B<Adding a tier makes a shared store unshared>, and it is told too. That is
the whole safety story of C<memory>: the copies are per worker again, so the
pool has to be kept coherent the same way the memory store's is. What a tiered
store drops on an invalidation is its own copy, never the shared entry - the
worker that wrote it has already changed the one copy there is.

B<The key travels, never the value.> Publishing values would make this a
replication system, with every worker paying to hold everything whether it
will be asked for it or not - and a bus slot is 2KB, so a cached page would be
refused outright and the pool would silently diverge. Each worker drops its
copy and recomputes on demand, which is what a cache is for.

B<C<set> invalidates as well as C<delete>.> Worker A writing a new value while
B through H serve the old one from memory until it expires is the same
staleness bug wearing a different hat, and the commoner one: updating a cached
thing happens far more often than deleting it.

B<Invalidation is best effort, and TTL is the backstop.> The bus is bounded
and drops oldest under pressure, so a worker far enough behind can miss a
message and keep a stale value. It is also asynchronous: the message has to
reach each worker's event loop. So always set a TTL - invalidation makes a
cache fresh quickly, and the TTL is what makes it eventually correct.

C<stats> reports C<shared>, C<pool> (whether a shared ring actually exists,
not merely whether the ABI is present), C<invalidations_sent> and
C<invalidations_received>. Without those an operator cannot tell a coherent
pool from one where every worker is quietly serving its own stale copy.

A store with a tier also reports C<memory_hits>, C<memory_misses>,
C<memory_bytes>, C<memory_entries>, C<memory_evictions>, C<memory_refused>,
C<memory_expired>, C<memory_max_bytes> and C<memory_ttl>. C<hits> and
C<misses> stay the cache's own totals, so a read the tier answered is still a
hit and the two still add up to the number of reads; C<memory_hits> is how
many of those hits cost nothing. Sixty-four megabytes a worker is a thing to
justify, and this is what justifies it.

With no bus at all - not under Hyperman, an older Hyperman, Windows, or a
build without the atomics - a store invalidates locally and says so through
C<pool>, rather than pretending the pool is coherent.

=head3 is_shared

A backend may implement C<is_shared>, returning true when every worker sees
the same data. A store that says true gets no invalidation traffic; one that
says false, or does not implement it, gets it. A Redis backend would return
true; the in-memory store returns false.

=head1 THE BACKEND CONTRACT

Any object with these five methods can be a backend:

    $backend->get($key)                  # the bytes, or undef
    $backend->set($key, $bytes, $ttl)    # $ttl seconds, 0 = forever
    $backend->delete($key)
    $backend->clear
    $backend->stats

The rules that go with it:

=over 4

=item * B<Values are bytes.> Not references, not objects.

=item * B<C<get> returns undef for absent and for expired.> A caller does not
need to know which, and a store that distinguished them would leak its expiry
policy into every call site.

=item * B<A C<$ttl> of 0 means no expiry>, not "expire immediately". The
opposite reading is the sort of thing that empties a cache in production.

=item * B<C<stats> is cumulative> for C<hits>, C<misses> and C<evictions>, and
current for C<bytes> and C<entries>.

=back

The same battery of tests runs against every shipped backend, and any
difference between them is a bug in one of them or in this contract - never
something to work around per backend.

=head2 Writing your own

A short backend name resolves to C<Punk::Cache::> plus the name, which is how
the two shipped stores are found and is all a third one needs:

    package Punk::Cache::Custom;
    sub new { ... }
    # ... the five methods

    cache 'custom', max_bytes => '64M';         # finds Punk::Cache::Custom

There is nothing to register. A name containing C<::> is taken as the class it
names, for a backend that does not want to live under C<Punk::Cache::>, and a
ready-made object can be handed over directly when it needs constructing some
other way:

    cache 'My::Company::Store', servers => [ ... ];
    cache($store);

Two things are checked at boot rather than on the first request: that the class
loads, and that it implements all five methods. A backend missing one is named,
along with the method, before the server starts serving.

Add C<is_shared> - see above - if the store is visible to every worker.
Leaving it out means unshared, which is the safe way round: an unnecessary
invalidation costs a message, a missing one serves stale data.

The battery is C<t/lib/PCConform.pm> and takes a factory, so a backend outside
this distribution can run the same assertions the shipped ones answer. That is
worth doing: the contract is only as real as the thing that enforces it.

=head1 KEYS

A key is bytes: up to 4096 of them, and any bytes at all. It is never used as
a filename directly - the file store hashes it - so C<../../etc/passwd> is
simply a key like any other.

=head1 METHODS

=head2 get($key) / set($key, $bytes, $ttl) / delete($key) / clear / stats

The contract, passed through to the backend.

The lock is also what makes L<Punk::Plugin::Idempotency> safe: two
retries of one C<Idempotency-Key> arriving on two workers must not both
execute, and this is the mechanism that stops them.

=head2 compute($key, $ttl, $code, %opt)

Above. C<< json => 1 >> encodes and decodes a structure around the store.

=head2 backend

The underlying store, for its own statistics or anything backend-specific.

=head1 SEE ALSO

L<Punk::Cache::Memory>, L<Punk::Cache::File>.

For work that must not be lost rather than merely recomputed, L<Punk::Queue> -
a cache is allowed to forget, which is the whole difference.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

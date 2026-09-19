package Shared::Arena::Cache;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.10';

require Shared::Arena;

1;

__END__

=encoding utf8

=head1 NAME

Shared::Arena::Cache - a shared cache that evicts instead of refusing

=head1 VERSION

Version 0.10

=head1 SYNOPSIS

    my $arena = Shared::Arena->create(size => 32 * 1024 * 1024);
    my $cache = $arena->cache('pages', capacity => 4096, entry_size => 4096);

    my ($html) = $cache->get($url);
    unless (defined $html) {
        $html = render($url);
        $cache->set($url, $html, ttl => 300);
    }

=head1 DESCRIPTION

One cache for every worker, rather than one per worker. A prefork pool that
caches per process pays N times the memory for the same hit rate and warms N
caches from cold; this is warmed once by whoever happens to ask first.

Get one from C<< $arena->cache($name) >>. Every process can ask for the same
name with the same arguments; the first creates it and the rest attach.

=head2 What makes it a cache and not a map

L<Shared::Arena::Map> refuses when it is full. This never does. A C<set> that
finds no room chooses something to throw away and takes its place, and the only
thing it will refuse is a key and value too large to fit an entry at all.

=head2 What gets thrown away

In order: an entry that has expired, then one that has not been read recently.

The recency part is B<CLOCK>, not LRU. True LRU reorders a list on every read,
which makes every reader a writer and throws away the property that makes this
worth sharing at all. CLOCK sets a single bit when an entry is read, and when
room is needed it sweeps, clearing bits and taking the first entry whose bit was
already clear. An entry that is being read keeps getting a second chance; one
that is not, leaves. It approximates LRU closely enough that the difference is
hard to measure.

A newly written entry starts with its bit B<clear>, so it must be read to earn
its place. Setting it on write would give every write a free pass and turn the
policy into "evict whatever was written longest ago", which is not what a cache
wants.

=head2 Set-associative, and what that costs

The cache is divided into buckets of C<ways> entries, and a key belongs to
exactly one bucket. A victim is chosen from inside that bucket rather than from
the whole cache, which is how a CPU cache is arranged and for the same reason:
a lookup touches C<ways> entries and stops, and neither lookups nor evictions
get slower as the cache fills.

The cost is that a hot bucket can evict while the cache as a whole has room. At
the default of eight ways the effect is small; at two it would not be, which is
why the default is eight.

=head2 Expiry is lazy

An entry with a deadline is not swept when it passes. It is noticed when
somebody looks, and preferred as a victim when somebody needs room. Sweeping
would mean a process whose job is to walk the whole cache on a timer, which is
work nobody asked for at a moment nobody chose.

An expired entry is a B<miss>. A cache that hands back stale data because
nothing has cleaned up yet is worse than no cache.

=head2 The clock it uses

Deadlines are wall-clock, because a deadline set by one process is read by
another and the only clock they certainly agree on is the machine's. If the
system time steps, every deadline moves with it, which costs at worst one round
of early or late expiry.

=head2 Serialised values

    my $cache = $arena->cache('sessions', capacity => 4096, serialise => 1);

    $cache->set($sid, { user => $u, roles => \@roles });
    my ($session) = $cache->get($sid);

By default a value is B<bytes>: a reference is stringified going in and comes
out as C<HASH(0x...)>, and a string's UTF-8 flag does not survive. With
C<< serialise => 1 >> a value is any Perl structure, encoded through
L<Struct::Codec> on the way in and decoded on the way out, and what comes back
is the same structure: strings stay strings and numbers stay numbers, the
UTF-8 flag survives, a blessed referent is blessed into the same class, and
references that were shared or cyclic are shared or cyclic again. Every
process gets its own copy; nothing is read in place, which is what
L<Shared::Arena::Frozen> is for.

Keys are bytes either way. A value that cannot be encoded, a closure for one,
croaks with the codec's reason and stores nothing. A value whose encoding does
not fit an entry is refused exactly as an oversized byte value is, so C<set>
answers -1 for both. A corrupt entry makes C<get> croak rather than hand back
bytes as if they were a value.

The flag is part of the cache's B<shape>, kept in the shared header beside
C<ways> and C<entry_size>, because a cache one process treats as encoded and
another treats as bytes is two caches that disagree about every value. Every
process must ask for the same setting, and one that asks for the other is
refused as a different C<entry_size> would be.

What it costs, measured on one machine for a five-key hash against the byte
path carrying the same thing as a Storable blob: a set is 167ns against 46,
a get 389ns against 87, and against the 1033ns of a byte get followed by
C<thaw>, which is the comparison that matters. A plain string costs 85 and
96ns, so a serialised cache holding mostly strings pays little for the option.

=head1 METHODS

=head2 set

    $cache->set($key, $value);
    $cache->set($key, $value, ttl => 300);      # seconds
    $cache->set($key, $value, ttl_ms => 250);   # milliseconds

1 when stored, -1 when the key is empty or the pair does not fit an entry.
There is no "full".

On a serialised cache C<$value> is any structure, and -1 also answers one whose
encoding does not fit. A value that cannot be encoded croaks.

=head2 get

    my ($value) = $cache->get($key);

The value, or an B<empty list> for a miss, which includes an entry whose
deadline has passed. Not C<undef>: C<undef> is a value a caller may store.

A hit sets the entry's reference bit, so reading something is what keeps it.

On a serialised cache the structure comes back decoded, a fresh copy each call.

=head2 serialised

    if ($cache->serialised) { ... }

Whether this cache was made with C<< serialise => 1 >>.

=head2 remove

    my $was_there = $cache->remove($key);

=head2 clear

    $cache->clear;

Drops everything.

=head2 stats

    my %s = $cache->stats;
    # hits, misses, hit_rate, evictions, expired, live, capacity, ways

C<hit_rate> is the number a cache exists to produce, and C<evictions> against
C<capacity> is what says whether it is big enough. C<live> walks every entry,
so this belongs on a status page rather than in a request.

C<hits> and C<misses> are counted by each process and published every 64, so
that readers in different processes are not all writing to one counter. The
calling process's own counts are always included, but another process's may
trail by up to 63 of each. A process that exits without letting its cache
object go, through C<POSIX::_exit> for instance, takes up to that many with it.

=head2 capacity, max_pair

    my $entries = $cache->capacity;
    my $bytes   = $cache->max_pair;   # key + value that fits one entry

=head1 SIZING ONE

    my $cache = $arena->cache('pages',
        capacity   => 4096,    # entries
        ways       => 8,       # entries per bucket
        entry_size => 4096,    # bytes for a key and its value
        serialise  => 0,       # 1: values are structures, not bytes
    );

It costs C<capacity * entry_size> bytes for its life, whether used or not, so
C<entry_size> is the number that matters: it is the size of the largest thing
you will cache, not the average, because anything larger is refused rather than
stored elsewhere. If your values vary wildly, use two caches.

Watch C<evictions> and C<hit_rate> together. Evictions climbing while the hit
rate falls means it is too small; evictions near zero means it is larger than
it needs to be.

=head1 SEE ALSO

L<Shared::Arena>, L<Shared::Arena::Map>, L<Struct::Codec>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut

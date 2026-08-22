package Punk::Cache::Memory;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.28';

# This store lives in ONE process, so a write here is invisible to every
# other worker. Punk::Cache invalidates across the pool on its behalf.
sub is_shared { 0 }

# All of it is C (include/punk/punk_cache.h + xs/cache.xs).

1;

__END__

=head1 NAME

Punk::Cache::Memory - an in process cache store, bounded by bytes

=head1 SYNOPSIS

    cache 'memory', max_bytes => '64M';

=head1 DESCRIPTION

An LRU cache in this process's memory: O(1) get, O(1) set, O(1) eviction, and
a bound that means something.

=head2 Bounded by BYTES, not entries

The obvious LRU caps the number of entries. A thousand entries of ten
megabytes is ten gigabytes, so an entry cap does not bound the thing that runs
out - and a cache that promises a bound has to bound memory.

The accounting is incremental and counts the key and the per-entry overhead,
not only the value. Counting values alone would let a million one-byte keys
sit under a C<1M> cap while costing tens of megabytes of structs and allocator
headers: a budget honest about the payload and useless about the memory.

A value too large for the budget is B<refused> rather than stored, because
making room for it would evict everything else and still not fit. The refusal
is counted.

=head2 It is not shared, and that costs more than it looks

This store lives in one process. Under a prefork server every worker has its
own, so the real cost is B<N times> C<max_bytes> - C<< workers => 8 >> with a
512M cap is four gigabytes - and every worker caches the same things
separately.

That arithmetic is why L<Punk::Cache::File> is the recommended. Reach for this one
when the values are small, the hit rate is high, and the duplication is
affordable.

=head2 Expiry

Lazy: an expired entry is noticed when it is read, not swept. A sweep on the
request path is a stall that grows with the cache.

A C<$ttl> of C<0> means B<no expiry>, not "expire immediately".

=head2 Statistics

C<stats> reports C<hits>, C<misses>, C<evictions>, C<refused>, C<expired>,
C<bytes>, C<entries> and C<max_bytes>. The counters are cumulative; C<bytes>
and C<entries> are what is held now.

A cache whose hit rate cannot be seen is a cache nobody can tune, and the
eviction count is the only way to tell "the budget is too small" from "these
keys are simply cold".

After a fork the counters reset. A worker reporting its parent's hit rate is
reporting a number about a different process, which an operator cannot act on.
The entries are kept: they are still correct, and re-reading them costs
nothing.

=head1 METHODS

The L<Punk::Cache> backend contract: C<get>, C<set>, C<delete>, C<clear>,
C<stats>. See L<Punk::Cache> for the rules that go with it - in particular
that values are B<bytes>.

=head1 SEE ALSO

L<Punk::Cache>, L<Punk::Cache::File>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

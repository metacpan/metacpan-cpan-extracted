package Punk::Cache::File;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.27';

# Every worker sees the same files, which is the whole point of this store
# being the default - so it needs no cross-worker invalidation.
sub is_shared { 1 }

# All of it is C (include/punk/punk_cachefile.h + xs/cache.xs).

1;

__END__

=head1 NAME

Punk::Cache::File - a cache store on disk, shared by the whole worker pool

=head1 SYNOPSIS

    cache 'file', dir => '/var/cache/myapp', max_bytes => '512M';

=head1 DESCRIPTION

A file cache.

=head2 A key never becomes a path

A cache key is application data and often user data. C<../../etc/passwd> is a
valid key, so is one with a NUL in it, so is a four-kilobyte one.

So the key is hashed, the hex sharded two levels deep, and the key itself
stored in the entry and B<compared on read> - which turns a hash collision
into a miss rather than a silently wrong value.

=head2 Writes are atomic

An entry is written to a temporary file in its destination directory and then
renamed. The same directory, because a cross-filesystem rename is not atomic
and F</tmp> is very often another filesystem.

A reader therefore never sees a half-written entry, which is also why no
checksum is needed: there is no torn state to detect. A crash mid-write leaves
a temporary file, which the sweep removes.

=head2 The budget, and where the work happens

C<max_bytes> is enforced by a sweep that drops expired entries and evicts the
coldest until the cache is under budget.

That sweep is a full scan - about 270ms for 100,000 entries - so it B<never
runs on a write>. Each process counts what it has written and sweeps once that
passes a slice of the budget, which bounds how often the scan happens without
putting it in the request path. Between sweeps the cache can exceed
C<max_bytes> by roughly that slice.

A value too large for the budget is refused rather than stored, because making
room would evict everything else and still not fit.

=head2 Single-flight

When a hot key expires under load, every worker misses at once. This store
lets one of them compute while the others wait for the answer, using an
exclusive lock file beside the entry.

It is B<best effort>, deliberately:

=over 4

=item * A waiter that exhausts C<lock_wait> B<computes anyway>. Correctness
never depends on the lock - duplicated work is a cost, a stalled request is an
outage, and a request hanging because the winner died is worse than both.

=item * A B<stale lock is stolen>, not obeyed, or one crash poisons a key
until somebody notices.

=back

C<lock_wait> defaults to five seconds.

=head2 Options

C<dir> (required), C<max_bytes> (default 512M), C<lock_wait> (default 5).

The directory is created and checked for writability at construction - which
is C<to_app> - so a bad path is a boot failure in front of whoever deployed
it, not a silent miss at three in the morning.

=head1 METHODS

The L<Punk::Cache> backend contract: C<get>, C<set>, C<delete>, C<clear>,
C<stats>.

C<stats> walks the cache to report C<bytes> and C<entries>, so it is an
operator action rather than something to call per request.

=head1 SEE ALSO

L<Punk::Cache>, L<Punk::Cache::Memory>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

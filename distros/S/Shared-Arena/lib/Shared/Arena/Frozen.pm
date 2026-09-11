package Shared::Arena::Frozen;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.02';

require Shared::Arena;

1;

__END__

=encoding utf8

=head1 NAME

Shared::Arena::Frozen - one structure, published once and read in place by every process

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use Shared::Arena;

    my $arena = Shared::Arena->create(size => 8 * 1024 * 1024);
    my $conf  = $arena->frozen('config', size => 256 * 1024);

    # whoever has the data publishes it
    $conf->publish({
        db       => { host => 'localhost', port => 5432 },
        features => { search => 1, billing => 0 },
        routes   => [ '/', '/login', '/admin' ],
    });

    # every worker reads it without rebuilding any of it
    my $view = $conf->view or return;
    my $port = $view->get('db.port');
    my $on   = $view->get('features.search');

=head1 DESCRIPTION

Every other tenant in this dist stores bytes. A key and a value are opaque
strings, so a nested structure has to be flattened on the way in and rebuilt on
the way out, and the rebuilding happens on B<every read>.

This one does not rebuild. It stores a L<Frozen> block: a flat structure,
addressed by offset, whose fields are read where they lie. Looking up one key
does not construct the other ten thousand, and a hundred workers reading the
same configuration read the same bytes rather than each holding a copy.

That makes it a different shape of thing from L<Shared::Arena::Map>, and the
two are worth different jobs:

=over 4

=item * A B<map> is many small values that change constantly.

=item * A B<frozen block> is one large value that changes rarely and is read
constantly.

=back

Configuration, a routing table, feature flags, a compiled ruleset, a lookup
table built at boot. The block is built once by whoever has the data and read
by every worker for the life of the process.

Reading one field, against the same structure serialized into a
L<Shared::Arena::Map> and rebuilt per read, on an M-series Mac:

    structure        serialized       this      view held
    10 keys            2,224 ns     207 ns          71 ns
    200 keys          30,054 ns     210 ns          74 ns
    2000 keys        318,111 ns     221 ns          76 ns

The right-hand columns barely move, and that is the entire point rather than a
detail of the benchmark: the cost of reading one field does not depend on how
big the structure is, because nothing is rebuilt to get at it. The left-hand
column is proportional to the whole structure every single time.

The middle column takes a fresh view per read, which is what a request handler
should do. The last holds one across the loop, which is what a tight loop over
many keys should do. See L</view>.

=head2 A block cannot be edited, so publishing replaces it

A Frozen block is addressed by offset throughout, so changing one string moves
everything after it. There is no editing a value in place, and a reader halfway
through such an edit would follow an offset into the middle of something else.

So C<publish> never writes where anybody is reading. The region holds several
slots, and a publish writes the new block into the slot furthest from use and
then points readers at it in one store. No reader waits for a publisher, no
publisher waits for a reader, and no reader ever sees half a block.

=head2 What a view borrows, and what that costs

C<view> does not copy. It hands back a reader pointing at the bytes where they
lie in the arena, which is the whole reason this beats sending the same
structure down a pipe: the cost of a view does not grow with the size of the
block.

The bytes are not the view's to keep. After C<slots> further publishes, the
slot a view is reading is reused, and the view then reads a B<different> block:
still structurally valid, still inside its own bounds, but not the one it was
opened on. Ask C<< $view->fresh >> to find out.

The rule that follows is short:

B<Take a view, read it, drop it.> A view taken per request costs a borrow. A
view cached in a global and held across a configuration reload is the one thing
this cannot make safe.

=head1 METHODS

=head2 publish

    my $gen = $conf->publish($data);
    my $gen = $conf->publish($data, lossy_nv => 1);

Freezes an ordinary Perl structure and publishes it. Returns the new
generation, a number that increases by one per publish and is never reused, or
C<undef> when the frozen block is larger than the C<size> the region was carved
with.

C<lossy_nv> passes through to L<Frozen>, for a caller who would rather have
floating point values stored compactly than exactly.

Publishing takes a lock, which is the right way round: a publish copies a whole
block and is already thousands of times the cost of the atomic that reads one,
and two processes publishing at once disagree about what the configuration is,
so one of them should win outright rather than the two interleaving. Reads take
no lock at all.

=head2 publish_bytes

    my $gen = $conf->publish_bytes($block);

Publishes bytes that are B<already> a Frozen block, which is what a process
that received one over a socket has: no freezing and no round trip through Perl
data.

The bytes are checked before they are published, structurally and not just for
a header. They are about to become every other process's idea of the
configuration, and the cheapest moment to discover they are not a block is
before publishing rather than during somebody else's read. Croaks if they are
not one.

=head2 view

    my $view = $conf->view or return;   # nothing published yet

A L<Shared::Arena::Frozen::View> of whatever is published now, or an B<empty
list> when nothing has been published. Not C<undef> for absent, for the reason
every other door in this dist gives an empty list: so that C<or return> and a
defined test mean the same thing.

=head2 generation

    my $n = $conf->generation;

How many times anything has been published, which is also the generation of the
block a view would open now. Zero before the first publish. Cheap: one atomic
load, so a worker may ask on every request whether its configuration has moved.

=head2 max_block

    my $bytes = $conf->max_block;

The largest block this region will carry, which is the C<size> it was carved
with. A runtime accessor rather than a constant a caller compiles in, for the
same reason the ring's C<max_record> is.

=head2 stats

    my %s = $conf->stats;

C<generation>, C<published>, C<refused>, C<slots>, C<max_block>, and C<bytes>
for the block that is live now.

C<refused> counts publishes that did not fit. A non-zero C<refused> means
somewhere a process thinks it published a configuration and did not, so it
belongs on a status page.

=head1 SIZING ONE

    $arena->frozen($name, size => $bytes, slots => 4);

C<size> is the largest block, and the region costs C<size * slots>, because
the point of the slots is that a publish never writes where somebody is
reading. C<slots> is between 2 and 16 and defaults to 4.

More slots do not make publishing faster. What they buy is how many publishes
a held view survives, so raise it only if views are held longer than they
should be, and prefer fixing that.

=head1 CAVEATS

B<A view goes stale after C<slots> publishes.> It does not become unsafe to
read, and it will not crash: the reader stays inside the bytes it was given.
It becomes a reader of a newer block than it asked for. C<< $view->fresh >>
answers, and a view taken per request never has the problem.

B<Publishing is not for hot data.> It copies the whole block and takes a lock.
It is for configuration that changes on deploy, not for something that changes
per request. That is what the ring and the map are for.

B<The block is trusted.> C<publish_bytes> verifies structure, which is what
makes bytes from elsewhere safe to accept. It does not verify the checksum:
that is a separate pass and L<Frozen>'s own C<verify> is where it lives.

=head1 SEE ALSO

L<Shared::Arena>, L<Shared::Arena::Frozen::View>, L<Frozen>,
L<Shared::Arena::Map>

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut

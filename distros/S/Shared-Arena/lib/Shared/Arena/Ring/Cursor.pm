package Shared::Arena::Ring::Cursor;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.03';

require Shared::Arena;

1;

__END__

=encoding utf8

=head1 NAME

Shared::Arena::Ring::Cursor - one reader's position in a ring

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    my $cursor = $ring->cursor;

    for my $rec ($cursor->drain) {
        my ($topic, $payload, $seq) = @$rec;
    }

    my %s = $cursor->stats;
    warn "missed $s{lapped} records" if $s{lapped};

=head1 DESCRIPTION

A cursor is one reader's place in a ring. Get one from C<< $ring->cursor >>.

Cursors are independent of each other and of the ring. Two cursors on one ring
both see every record; neither takes anything from the other. A cursor holds
its ring alive, and its ring holds the arena alive, so the shortest useful
program is one line and nothing is freed underneath it.

A cursor belongs to the process that made it. After a fork, the child has a
copy positioned wherever the parent's was, and the two then advance separately
and both see everything. That is usually what is wanted; where it is not, make
the cursor in the child.

=head1 METHODS

=head2 drain

    my @records = $cursor->drain;
    my @records = $cursor->drain(max => 100);

Everything published since this cursor last looked, as array references of
C<[$topic, $payload, $sequence]>. An empty list when there is nothing new,
which is not an error and not a wait: C<drain> never blocks.

C<max> caps how many are returned in one call; the rest stay for the next.

The sequence is the record's identity. It increases, never repeats, and is
what a gap is counted in.

=head2 stats

    my %s = $cursor->stats;
    # delivered, lapped, abandoned, unattributed, seq

Everything this cursor has seen or missed, since it was made.

=over 4

=item * B<delivered> is records handed to the caller.

=item * B<lapped> is records overwritten before this cursor reached them. It
means this reader is too slow or the ring is too small. It is normal in small
amounts and worth an alert in large ones.

=item * B<abandoned> is records whose publisher died part-way through writing
them. It is counted apart from C<lapped> because it is a different diagnosis:
lapped is a capacity problem, abandoned is a process that crashed and somebody
should find out why.

=item * B<unattributed> is a gap that could not be explained. It should be
zero. A non-zero value means a publisher vanished in a window too small to
attribute, and is worth reporting.

=item * B<seq> is where this cursor has reached.

=back

For any cursor, C<delivered + lapped + abandoned> equals what the ring has
published since the cursor started, so nothing goes missing without a number
against it.

=head1 SEE ALSO

L<Shared::Arena::Ring>, L<Shared::Arena>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut

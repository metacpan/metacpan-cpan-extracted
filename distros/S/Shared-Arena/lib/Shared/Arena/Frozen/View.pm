package Shared::Arena::Frozen::View;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.02';

require Shared::Arena;

1;

__END__

=encoding utf8

=head1 NAME

Shared::Arena::Frozen::View - read a published block without copying it

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    my $view = $conf->view or return;

    my $name = $view->get('name');
    my $port = $view->get('db.port');

    for my $k ($view->keys) { ... }

    my $everything = $view->inflate;   # and this one does cost

=head1 DESCRIPTION

A reader pointing at a block where it lies in the arena. Nothing was copied to
make it, and nothing is copied to read a field out of it: the block is
addressed by offset, so a lookup is arithmetic and a string is handed back from
the arena's own bytes.

That is what makes it worth having. A structure sent through a pipe costs its
own size to every worker that receives it, every time. This costs the same
whether the block is a kilobyte or three megabytes, because the size never
moves.

Views are cheap and meant to be short-lived. Take one, read it, drop it. See
L<Shared::Arena::Frozen/"What a view borrows, and what that costs"> for what
holding one across a publish means.

=head1 METHODS

=head2 get

    my $value = $view->get('db.port');
    my $value = $view->get('messages/errors/404', '/');

A value by dotted path, or an B<empty list> when the path does not resolve.
The same spelling and the same walk L<Frozen> uses, because it is the same
walk.

A container comes back as an ordinary Perl reference, built at that point and
no sooner: descending to a leaf never constructs the branches it passed.

The separator is an argument for the one case that makes a fixed one wrong,
which is a key with a dot in it. L</find> is the other way out of that.

=head2 find

    my $node = $view->find($key);

One key against the root, with B<no path splitting at all>: the narrowest door,
and the right one when a key contains a dot, or when a caller already knows
there is nothing to descend into. An empty list when the key is absent.

=head2 exists

    if ($view->exists('features.billing')) { ... }

Whether a dotted path resolves, without building the value it resolves to. The
cheap way to ask about something large. Takes the same optional separator
L</get> does.

=head2 keys

    my @k = $view->keys;

The top-level keys, in the order the block holds them.

=head2 count

    my $n = $view->count;

How many entries the top level has.

=head2 inflate

    my $data = $view->inflate;

The whole block back as ordinary Perl data.

B<This is the one door that costs what a serializer costs>, because it does
what a serializer does: it builds every value whether the caller wanted it or
not. It is here for a caller who genuinely wants the whole structure. Reaching
for it to read one field gives away the entire reason for using this.

=head2 fresh

    $view->fresh or $view = $conf->view;

Whether the slot still holds the block this view was opened on.

A view cannot be stopped from going stale: the bytes belong to the arena, and a
publisher eventually comes round to that slot again. It can always find out.
False means read it again, not that anything is broken, and nothing unsafe has
happened either way.

=head2 generation

    my $n = $view->generation;

The generation this view was opened on. Comparing it with
C<< $conf->generation >> says how far behind the view is; comparing C<fresh>
says whether it is far enough behind to be reading something else.

=head2 verify

    my $nodes = $view->verify;

Walks the block and returns the number of nodes it reached, or a negative
number when the structure does not hold together. O(n), and for a caller
checking bytes it did not write.

Reading a field does not need this. Every access is bounds-checked against the
block's own length whatever the block contains, so a malformed one gives
nonsense rather than reading outside itself. C<verify> is how a caller finds
out it is nonsense before acting on it.

=head2 bytes

    my $n = $view->bytes;

The size of the block this view is reading.

=head1 SEE ALSO

L<Shared::Arena::Frozen>, L<Shared::Arena>, L<Frozen>

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut

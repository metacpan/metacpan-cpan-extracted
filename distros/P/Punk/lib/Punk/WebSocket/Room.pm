package Punk::WebSocket::Room;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.27';
1;

__END__

=head1 NAME

Punk::WebSocket::Room - pub/sub groups of WebSocket connections

=head1 SYNOPSIS

    use Punk::WebSocket::Room;

    sub join_chat {
        my ($c, $ws) = @_;
        my $room = Punk::WebSocket::Room->named('lobby');

        $ws->on(open    => sub { $room->join($_[0]) });
        $ws->on(message => sub {
            my ($ws, $text) = @_;
            $room->broadcast($text, $ws);      # everyone except the sender
        });
        $ws->on(close   => sub { $room->leave($_[0]) });
    }

=head1 DESCRIPTION

A named group of connections, with one encode per broadcast: the frame is
built once and the same bytes are queued to every member.

Membership is held weakly and pruned on every access, so a connection that
goes away leaves its rooms by itself - calling L</leave> from a C<close>
handler is tidy but not required.

B<A broadcast reaches the whole pool.> Each worker holds only the
connections it accepted, so a broadcast is published on L<Hyperman>'s
cross-worker message bus and every worker fans the frame out to its own
members. The frame is encoded B<once>, by the worker that broadcast it, and
the same bytes travel - so a room of a thousand people across four workers
does one encode, not four.

There is B<one> delivery path. The publishing worker does not also send
locally; it receives its own publication like everybody else. Sending locally
and publishing would deliver twice to the members in front of you, and would
leave two paths to drift apart - so a bug in the shared one would be invisible
to anyone testing on a single worker.

Where there is no pool - a server that is not Hyperman, a Hyperman older than
0.28, Windows, or a compiler without the atomics the shared ring needs - a
room is B<local>, which is what it always was. It does not pretend
otherwise.

The count a broadcast returns is what B<this worker> delivered. A total across
the pool is not knowable at the moment of the call without waiting for it, and
a plausible number that is not the truth is precisely the fault this replaced.

=head1 METHODS

=head2 named($name)

The worker's room of that name, created on first use.

=head2 join($ws) / leave($ws) / has($ws)

=head2 clients

The live members, as a list. List context only: like any
list-returning XS call, C<scalar $room-E<gt>clients> yields the last
member, not a count - that is what C<count> is for.

=head2 count

How many.

=head2 broadcast($text, $except?)

=head2 broadcast_binary($bytes, $except?)

Send to every open member, optionally skipping one connection (usually the
sender). Returns the number sent.

=head2 close_all($code = 1000, $reason = '')

Close every member and empty the room.

=head2 clear

Empty the room without closing anything.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

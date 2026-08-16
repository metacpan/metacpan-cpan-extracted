package Punk::WebSocket::Room;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.12';
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

B<A room is per worker.> Under a multi-worker server each worker has its
own C<lobby> holding only the connections it accepted, and a broadcast
reaches those. Fanning out across workers needs a message bus (Redis, a
socket to a hub) which this deliberately does not pretend to be.

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

package Punk::WebSocket;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.17';

1;

__END__

=head1 NAME

Punk::WebSocket - a WebSocket connection

=head1 SYNOPSIS

    # in the app
    websocket '/chat' => 'WS::Chat#join';

    # MyApp::Controller::WS::Chat
    sub join {
        my ($c, $ws) = @_;               # after a validated upgrade

        $ws->on(open => sub {
            my ($ws) = @_;
            Punk::WebSocket::Room->named('lobby')->join($ws);
        });
        $ws->on(message => sub {
            my ($ws, $text) = @_;
            Punk::WebSocket::Room->named('lobby')->broadcast($text);
        });
        $ws->on(close => sub {
            my ($ws, $code, $reason) = @_;
            Punk::WebSocket::Room->named('lobby')->leave($ws);
        });
    }

=head1 DESCRIPTION

One WebSocket connection. The handler for a C<websocket> route is called
with the L<Punk::Context> and this object once the upgrade handshake has
been validated and answered; it wires the events it cares about and
returns. Reading, framing, ping/pong and the closing handshake then run
on the worker's event loop with no further Perl involvement until a
message completes.

Frames are decoded in C to RFC 6455, strictly: unmasked client frames,
fragmented or over-long control frames and reserved opcodes are protocol
errors (close 1002), text payloads and close reasons must be valid UTF-8
(1007), and a message over C<max_message_size> is refused from the frame
header before it is buffered (1009).

=head1 EVENTS

C<< $ws->on($event => sub { ... }) >>, one handler per event; an unknown
event name croaks. Every handler receives the connection first.

=over 4

=item * B<open> C<< ($ws) >> - the handshake is complete.

=item * B<message> C<< ($ws, $text) >> - a complete text message,
character-decoded.

=item * B<binary> C<< ($ws, $bytes) >> - a complete binary message.

=item * B<ping> C<< ($ws, $payload) >> / B<pong> C<< ($ws, $payload) >> -
a pong is sent automatically before the ping event fires.

=item * B<close> C<< ($ws, $code, $reason) >> - fires exactly once, for a
clean close or a dropped connection (code 1006).

=item * B<error> C<< ($ws, $message) >> - a handler died, or the codec
rejected the peer's framing.

=back

A handler that dies does not take the worker down: the error event fires
and the connection is closed with 1011.

=head1 METHODS

=head2 send($text)

=head2 send_binary($bytes)

Queue a message. Writes are buffered and drained on the loop, so a slow
consumer never blocks the worker (past C<write_buffer_limit> the
connection is closed with 1008).

=head2 ping($payload?)

=head2 pong($payload?)

=head2 close($code = 1000, $reason = '')

Start the closing handshake; the C<close> event fires when it completes
or times out.

=head2 state / is_open / is_closing / is_closed

=head2 protocol

The negotiated subprotocol, or undef.

=head2 fd

The underlying file descriptor.

=head1 SEE ALSO

L<Punk>, L<Punk::WebSocket::Room>, L<Hyperman/detach>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

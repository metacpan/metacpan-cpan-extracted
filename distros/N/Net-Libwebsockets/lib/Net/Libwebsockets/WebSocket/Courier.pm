package Net::Libwebsockets::WebSocket::Courier;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::Libwebsockets::WebSocket::Courier - Interact with a WebSocket connection

=head1 SYNOPSIS

See L<Net::Libwebsockets>.

=head1 DESCRIPTION

This class handles interactions with an established WebSocket connection.
It acts as a “messenger” (i.e., a “courier”) between the Perl application
and the WebSocket peer.

=head1 METHODS

(NB: There’s no constructor; this class is instantiated internally.)

=head2 I<OBJ>->on_text( \&CALLBACK )

Registers a callback to fire on reception of every complete WebSocket
text message. The callback receives the (character-decoded) message text.

=head2 I<OBJ>->on_binary( \&CALLBACK )

Like C<on_text()> but for binary messages. (The callback argument is
not character-decoded, of course.)

=head2 I<OBJ>->send_text( $CHARACTERS )

Enqueues a text message to be sent. $CHARACTERS is a character string.

=head2 I<OBJ>->send_binary( $BINARY_STRING )

Like C<send_text()> but sends a binary string.

=head2 $promise = I<OBJ>->close( [ $CODE [, $REASON_CHARS ] ] )

Initiates a shutdown of the WebSocket connection. ($REASON_CHARS is a
text/decoded string.)

=head2 $pause_obj = I<OBJ>->pause()

Returns an opaque object during whose lifetime I<OBJ> will not accept
incoming WebSocket messages.

This is useful for handling/applying backpressure
in case the received messages overwhelm the system. For example, if you
can process 100 messages per second, but you receive 1,000 messages per
second, you’ll need to stop accepting new messages periodically to allow
your local processing to “catch up”. (Thus, you effectively limit your
sender to 100 messages per second as well.)

=cut

#----------------------------------------------------------------------

use Net::Libwebsockets ();

1;

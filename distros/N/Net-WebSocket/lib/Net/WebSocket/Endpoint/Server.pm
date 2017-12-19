package Net::WebSocket::Endpoint::Server;

=encoding utf-8

=head1 NAME

Net::WebSocket::Endpoint::Server

=head1 SYNOPSIS

    my $ept = Net::WebSocket::Endpoint::Server->new(
        parser => $parser_obj,

        out => $out_fh,

        #optional, # of pings to send before we send a close
        max_pings => 5,

        #optional
        on_data_frame => sub {
            my ($frame_obj) = @_;

            #...
        },
    );

    if ( _we_timed_out_waiting_for_read_readiness() ) {
        $ept->check_heartbeat();
    }
    else {

        #This should only be called when reading won’t produce an error.
        #For example, in non-blocking I/O you’ll need a select() in front
        #of this. (Blocking I/O can just call it and wait!)
        $ept->get_next_message();

        #Check for this at the end of each cycle.
        _custom_logic_to_finish_up() if $ept->is_closed();
    }

=head1 DESCRIPTION

This module, like its twin, L<Net::WebSocket::Endpoint::Client>, attempts
to wrap up “obvious” bits of a WebSocket endpoint’s workflow into a
reusable component.

The basic workflow is shown in the SYNOPSIS; descriptions of the individual
methods follow:

=head1 METHODS

=head2 I<CLASS>->new( %OPTS )

Instantiate the class. Nothing is actually done here. Options are:

=over

=item * C<parser> (required) - An instance of L<Net::WebSocket::Parser>.

=item * C<out> (required) - The endpoint’s output object. An
instance of L<IO::Framed> or a compatible class.

=item * C<max_pings> (optional) - The maximum # of pings to send before
we send a C<close> frame (which ends the session).

=item * C<on_data_frame> (optional) - A callback that receives every data
frame that C<get_next_message()> receives. Use this to facilitate chunking.

If you want to avoid buffering a large message, you can do this:

    on_data_frame => sub {
        #... however you’re going to handle this chunk

        $_[0] = (ref $_[0])->new(
            payload => q<>,
            fin => $_[0]->get_fin(),
        );
    },

=back

=head2 I<OBJ>->get_next_message()

The “workhorse” method. It returns one of the following:

=over

=item * a data message if one is available

=item * empty string if the Parser’s C<get_next_frame()> indicated
end-of-file without an exception

=item * otherwise, undef

=back

This method also handles control frames that arrive before or among
message frames:

=over

=item * close: Respond (immediately) with the identical close frame.
See below for more information.

=item * ping: Send the appropriate pong frame.

=item * pong: As per the protocol specification.

=back

This method may not be called after a close frame has been sent (i.e.,
if the C<is_closed()> method returns true).

=head2 I<OBJ>->check_heartbeat()

Ordinarily, sends a distinct ping frame to the remote server
and increments the ping counter. Once a sent ping is
received back (i.e., a pong), the ping counter gets reset.

If the internal ping counter has already reached C<max_pings>, then we
send a PROTOCOL_ERROR close frame. Further I/O attempts on this object
will prompt an appropriate exception to be thrown.

=head2 I<OBJ>->sent_close_frame()

Returns a C<Net::WebSocket::Frame::close> object or undef to represent the
frame that the object has sent, either via the C<close()> method directly
or automatically via the internal handling of control messages.

=head2 I<OBJ>->received_close_frame()

Returns a C<Net::WebSocket::Frame::close> object or undef to represent the
frame that the object has received.

=head2 I<OBJ>->is_closed()

DEPRECATED: Returns 1 or 0 to indicate whether we have sent a close frame.
Note that C<sent_close_frame()> provides a more useful variant of the
same functionality; there is no good reason to use this method anymore.

=head2 I<OBJ>->do_not_die_on_close()

Ordinarily, receipt of a close frame prompts an exception after the
response close frame is sent. This is, arguably, a suboptimal design
choice since receipt of a close frame is a perfectly normal thing to happen;
i.e., it’s not “exception-al”. If you want to check for close yourself
instead, you can do so by calling this method.

=head2 I<OBJ>->die_on_close()

The inverse of C<do_not_die_on_close()>: restores
the default behavior when a close frame is received.

=head1 WHEN A CLOSE FRAME IS RECEIVED

C<get_next_message()> will automatically send a close frame in response
when it receives one. The received close frame is not returned to the
application but, like ping and pong, is handled transparently.

Rationale: WebSocket is often billed as “TCP for the web”; however, the
protocol curiously diverges from TCP in not supporting “half-close”; a
WebSocket connection is either fully open (i.e., bidirectional) or fully
closed. (There is some leeway given for finishing up an in-progress message,
but this is a much more limited concept.)

=head1 EXTENSIONS

This module has several controls for supporting WebSocket extensions:

=over

=item * C<get_next_message()>’s returned messages will always contain
a C<get_frames()> method, which you can use to read the reserved bits
of the individual data frames.

=item * You can create C<on_*> methods on a subclass of this module
to handle different types of control frames. (e.g., C<on_foo(FRAME)>)
to handle frames of type C<foo>.) The C<parser> object that you pass
to the constructor has to be aware of such messages; for more details,
see the documentation for L<Net::WebSocket::Parser>.

=back

=cut

use strict;
use warnings;

use parent qw(
    Net::WebSocket::Endpoint
    Net::WebSocket::Masker::Server
);

1;

package Punk::Stream;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.48';


1;

__END__

=head1 NAME

Punk::Stream - a streamed response for an ordinary route

=head1 SYNOPSIS

    get '/export' => sub {
        my $c = shift;
        $c->stream('text/csv', {
            headers => [ 'Content-Disposition' => 'attachment; filename="all.csv"' ],
        }, sub {
            my ($c, $w) = @_;
            while (my $chunk = next_chunk_of_rows($c)) {
                $w->write($chunk);
                my ($ok) = $c->await($w->drain);
                return unless $ok;             # the client went away
            }
        });
    };

=head1 DESCRIPTION

C<< $c->stream($content_type, $cb) >> emits a response body as it is
produced - a CSV export walking a large query, an NDJSON dump, anything of
unknown length that should not cost its size in memory. The callback gets the
L<Punk::Context> and a writer; the handler returns what C<stream> returns.

This is the SSE transport machinery with the event framing removed. Four
transports carry it, chosen per request: a L<Hyperman> worker B<detaches> the
socket and streams it on the loop; a Hyperman B<stream handle> sends the body
through the server for the connections detach cannot take, which is what
serves HTTP/2 and TLS (see L<Punk::SSE/"HTTP/2 and TLS">); a
C<psgi.streaming> server uses the standard delayed-response writer; and
C<< blocking => 1 >> streams inside the handler over C<psgix.io> (pinning one
worker). Without any of them the request gets a 501.

=head2 How it ends

A streamed response ends, and how it ends is visible to the client. On the
socket transports the body is chunk-framed (HTTP/1.1), so:

=over 4

=item * B<the callback returning> closes the stream cleanly - the terminal
chunk is sent, and the connection closes once every byte is out. An explicit
C<< $w->close >> inside the callback does the same and is idempotent.

=item * B<a die in the callback> closes the stream hard. The response head
is already on the wire, so there is no error page to send; the socket closes
without the terminal chunk and the client sees truncation, never a
valid-looking short body. The death is reported through C<warn> with the
request id when L<Punk::Plugin::RequestId> has issued one.

=back

The stream handle says the same two things differently, because it is the
server that frames the body there: the clean end is a normal end of body, and
the hard one is C<RST_STREAM> on HTTP/2 or a connection reset on HTTP/1.1 over
TLS. Either way the client can tell a response that finished from one that
stopped, which is the part that matters - a streamed body has no declared
length, so ending cleanly B<is> the claim that it is whole.

A stream does not outlive its callback. For a connection that stays open and
is pushed to later, use an C<sse> or C<websocket> route - that is what they
are for.

=head2 Backpressure

C<< $w->write >> queues; C<< $w->drain >> is a L<Punk::Future> settled with
C<1> once everything written so far has reached the kernel, or C<0> when the
stream closed first (the client disconnected, or the buffer ceiling was
hit). Awaiting it after each write bounds memory to one chunk, and on a
Hyperman worker the await pumps the event loop - other requests are served
while your stream waits for a slow client to read. On the stream handle it
settles from the server's own drain, or at once when a write was taken
without the connection backing up. On the blocking and C<psgi.streaming>
transports writes are synchronous, so C<drain> comes back already settled and
the same loop costs nothing.

=head1 THE CALL

    $c->stream($content_type, $cb);
    $c->stream($content_type, \%opts, $cb);

Options, all checked when you call (an unknown key croaks):

=over 4

=item C<status>

The response status, default 200.

=item C<headers>

Extra response headers, an arrayref of pairs. C<Content-Type> comes from the
first argument; C<Transfer-Encoding> and C<Connection> belong to the
transport and are not yours to set. A CR or LF anywhere in a name or value
croaks.

=item C<write_buffer_limit>

A ceiling in bytes on the unsent buffer, off by default. Over it the stream
is closed rather than allowed to grow without bound - the L<Punk::WebSocket>
rule for a client that will not read. With the drain loop above the buffer
never holds more than one chunk and the ceiling never matters.

=item C<blocking>

Stream synchronously over C<psgix.io> when there is no detach seam and no
C<psgi.streaming> - the same last-resort transport, with the same worker
pinned, as C<sse> and C<websocket> routes.

=back

=head1 THE WRITER

=head2 write($bytes)

Queue one chunk of the body. Bytes, as PSGI bodies are - encode a character
string first. An empty or undef write is a no-op (on the wire a zero-length
chunk would mean "the end"). Writes on a closed stream are ignored.
Chainable.

=head2 drain

The backpressure future; see above.

=head2 close

End the response cleanly now. The callback returning does this for you.
Chainable.

=head2 is_open

Whether the stream is still open - false once the client is gone or C<close>
has been called.

=head1 WHAT THE REST OF THE FRAMEWORK SEES

On a C<psgi.streaming> server the response is a delayed-response coderef, and
on the socket transports the socket has left the building: there is no final
triplet. C<after_dispatch> hooks are skipped for a coderef response (there is
nothing to mutate), a route's C<< etag => 1 >> has no body to hash and passes
through, and the response observers fire once with what was actually
returned - the coderef, or the detached-socket sentinel. This is the same
contract C<sse> routes have always had.

=head1 SEE ALSO

L<Punk>, L<Punk::SSE>, L<Punk::Future>, L<Punk::Context/send_file>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

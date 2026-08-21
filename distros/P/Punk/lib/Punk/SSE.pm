package Punk::SSE;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.27';


1;

__END__

=head1 NAME

Punk::SSE - a Server-Sent Events stream

=head1 SYNOPSIS

    # in the app
    sse '/events' => 'Live#feed';

    # MyApp::Controller::Live
    sub feed {
        my ($c, $stream) = @_;                 # the socket is ours now

        my $tick;
        $tick = sub {
            return unless $stream->is_open;
            $stream->send({ time => time });
            $c->timer(1)->on_done($tick);      # push once a second
        };
        $tick->();

        $stream->on(close => sub { warn "client gone\n" });
    }

=head1 DESCRIPTION

An C<sse> route streams C<text/event-stream> to a browser's C<EventSource>:
one-directional, plain HTTP, with the client reconnecting on its own. The
handler for an C<sse> route is called with the L<Punk::Context> and a stream
once Punk has taken the socket over, and pushes events onto it; the stream then
lives on the worker's event loop with no worker pinned per connection.

Three transports carry it, chosen per request: a L<Hyperman> worker B<detaches>
the socket and streams it on the loop; a C<psgi.streaming> server uses the
standard delayed-response writer; and C<< blocking => 1 >> streams inside the
handler over C<psgix.io> (pinning one worker). Without any of them the request
gets a 501.

Backpressure is bounded by C<write_buffer_limit> as for websockets: a client
that will not read is closed rather than allowed to buffer without limit.

=head1 THE ROUTE

    sse '/events' => 'Live#feed';
    sse '/events' => $target, { heartbeat => 30, retry => 3000 };

Options: C<heartbeat> (seconds between keep-alive comments, default 15; 0 to
turn it off), C<retry> (the client reconnect delay in ms, sent once up front),
C<write_buffer_limit>, and C<blocking>.

=head2 Reconnection

The browser reconnects automatically and sends the last id it saw as the
C<Last-Event-ID> header; read it to resume:

    my $from = $c->req->header('last-event-id');

and stamp outgoing events with L</id> so the client has something to send back.

=head1 THE STREAM

=head2 send($data)

One event. A reference is JSON-encoded; a multi-line string becomes multiple
C<data:> lines per the spec. Chainable.

=head2 event($name, $data)

A named event (an C<event:> field the client dispatches by name). Chainable.

=head2 comment($text)

A C<:comment> line - ignored by the client, useful as a keep-alive. Chainable.

=head2 id($id)

=head2 retry($ms)

Write an C<id:> or C<retry:> field. Send C<id> just before the event it stamps.
Chainable.

=head2 close

End the stream now. Chainable.

=head2 is_open

Whether the stream is still open - test it before pushing from a timer.

=head2 on(close => $cb)

C<< $cb->($stream) >> once, when the stream ends: the client disconnecting, a
C<close>, or a write error. Chainable.

=head1 FANNING OUT ACROSS WORKERS

A stream belongs to the worker that accepted it. Under a prefork server that
means an application pushing an event reaches only the fraction of its
subscribers that happen to be on the worker doing the pushing - the same trap
L<Punk::WebSocket::Room> had, and with the same silence about it.

There is no C<Punk::SSE::Room>, because holding the streams is usually the
application's business: a stream is often per user rather than per group. What
it needs is a way to reach the other workers, and that is
L<Punk/publish / subscribe>.

    package MyApp;
    use Punk;

    our @STREAMS;

    sse '/events' => sub {
        my ($c, $stream) = @_;
        push @STREAMS, $stream;
    };

    # AT BOOT, in the parent, before the server forks - the only moment a
    # subscription reaches every worker
    __PACKAGE__->punk_app->subscribe('news' => sub {
        my ($topic, $payload) = @_;
        @STREAMS = grep { $_->is_open } @STREAMS;   # prune as you go
        $_->event(news => $payload) for @STREAMS;
    });

Anything may then push to every stream in the pool, from any worker:

    $c->publish('news' => $headline);

Two things to keep in mind. B<Prune the closed streams> - nothing else holds
them, and an array that only grows is a leak with a client list attached.
And B<register at boot>: a subscription made inside a request lands in one
worker and lasts as long as that process, which is the fault this avoids.

=head1 SEE ALSO

L<Punk>, L<Punk::Future>, L<Punk::WebSocket>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

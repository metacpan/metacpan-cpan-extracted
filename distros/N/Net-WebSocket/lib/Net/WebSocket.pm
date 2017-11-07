package Net::WebSocket;

our $VERSION = '0.052';

=encoding utf-8

=head1 NAME

Net::WebSocket - WebSocket in Perl

=head1 SYNOPSIS

    use Net::WebSocket::Handshake::Client ();
    use Net::WebSocket::HTTP_R ();

    my $handshake = Net::WebSocket::Handshake::Client->new(
        uri => $uri,
    );

    syswrite $inet, $handshake->to_string() or die $!;

    #You can parse HTTP headers however you want;
    #Net::WebSocket makes no assumptions about this.
    my $resp = HTTP::Response->parse($hdrs_txt);

    #If you use an interface that’s compatible with HTTP::Response,
    #then you can take advantage of this convenience function;
    #otherwise you’ll need to do a bit more work.
    Net::WebSocket::HTTP_R::handshake_parse_response( $handshake, $resp );

    #See below about IO::Framed
    my $parser = Net::WebSocket::Parser->new(
        IO::Framed::Read->new($inet),
    );

    my $iof_w = IO::Framed::Write->new($inet);

    my $ept = Net::WebSocket::Endpoint::Client->new(
        parser => $parser,
        out => $iof_w,
    );

    $iof_w->write(
        Net::WebSocket::Frame::text->new( payload_sr => \'Hello, world' )
    );

    #Determine that $inet can be read from …

    my $msg = $ept->get_next_message();

    #… or, if we timeout while waiting for $inet to be ready for reading:

    $ept->check_heartbeat();
    exit if $ept->is_closed();

=head1 BETA QUALITY

This is a beta release. It should be safe for production, but there could
still be small changes to the API. Please check the changelog before
upgrading.

=head1 DESCRIPTION

This distribution provides a set of fundamental tools for communicating via
L<WebSocket|https://tools.ietf.org/html/rfc6455>.
It is only concerned with the protocol itself;
the underlying transport mechanism is up to you: it could be a file,
a UNIX socket, ordinary TCP/IP, some funky C<tie()>d object, or whatever.

Net::WebSocket also “has no opinions” about how you should do I/O or HTTP
headers. There are too many different ways to accomplish HTTP header
management in particular for it to be sensible for a WebSocket library to
impose any one approach. As a result of this, Net::WebSocket can probably
fit your project with minimal overhead. There are some examples
of how you might write complete applications (client or server)
in the distribution’s F<demo/> directory.

Net::WebSocket emphasizes flexibility and lightness rather than the more
monolithic approach in modules like L<Mojolicious>.
Net::WebSocket should support anything
that the WebSocket protocol itself can do, as lightly as possible and without
prejudice as to how you want to do it: extensions, blocking/non-blocking I/O,
arbitrary HTTP headers, etc. Net::WebSocket will likely require more of an
investment up-front, but the end result should be a clean, light
implementation that will grow (or shrink!) as your needs dictate.

=head1 OVERVIEW

Here are the main modules:

=over

=item L<Net::WebSocket::Handshake::Server>

=item L<Net::WebSocket::Handshake::Client>

Logic for handshakes. Every application needs one of these. As of version
0.5 this handles all headers and can also do
subprotocol and extension negotiation for you.

=item L<Net::WebSocket::HTTP_R>

A thin convenience wrapper for L<HTTP::Request> and L<HTTP::Response>,
CPAN’s “standard” classes to represent HTTP requests and responses.
Net::WebSocket::HTTP_R should also work with other classes whose
interfaces are compatible with these “standard” ones.

=item L<Net::WebSocket::Endpoint::Server>

=item L<Net::WebSocket::Endpoint::Client>

A high-level abstraction to parse input
and respond to control frames and timeouts. You can use this to receive
streamed (i.e., fragmented) transmissions as well. You don’t have to use
this module, but it will make your life easier.

=item L<Net::WebSocket::Parser>

Translate WebSocket frames out of a filehandle into useful data for
your application.

=item Net::WebSocket::Frame::*

Useful for creating raw frames. For data frames (besides continuation),
these will be your bread-and-butter. See L<Net::WebSocket::Frame::text>
for sample usage.

=item L<Net::WebSocket::Streamer::Server>

=item L<Net::WebSocket::Streamer::Client>

Useful for sending streamed (fragmented) data rather than
a full message in a single frame.

=back

=head1 IMPLEMENTATION NOTES

=head2 Handshakes

WebSocket uses regular HTTP headers for its handshakes. Because there are
many different solutions around for parsing HTTP headers, Net::WebSocket
is “agnostic” about how that’s done. The advantage is that if you’ve got
a custom solution for parsing headers then Net::WebSocket can fit into
that quite easily.

The liability of this is that you, the library user, must give headers
directly to your Handshake object. (NB: L<Net::WebSocket::HTTP_R> might
be able to do this for you.)

=head2 Masking

As per L<the specification|https://tools.ietf.org/html/rfc6455#section-5.1>,
client serializers “MUST” mask the data randomly, whereas server serializers
“MUST NOT” do this. Net::WebSocket does this for you automatically,
but you need to distinguish
between client serializers—which mask their payloads—and server serializers,
which don’t mask.

This module used to do this with L<Bytes::Random::Secure::Tiny>, but
that seems like overkill given that the masking is only there to accommodate
peculiarities of certain proxies. We now just use Perl’s C<rand()>
built-in.

(You should probably use TLS if cryptographically secure masking is something
you actually care about?)

=head2 Text vs. Binary

Recall that in some languages—like JavaScript!—the difference between
“text” and “binary” is much more significant than for us in Perl.

=head2 Use of L<IO::Framed>

CPAN’s L<IO::Framed> provides a straightforward interface for chunking up
data from byte streams into frames. It also provides a write buffer for
non-blocking writes, and it retries on EINTR. You don’t have to use it
(which is why it’s not listed as a requirement), but you’ll need to provide
a compatible interface if you don’t.

See the demo scripts that use L<IO::Framed> for an example of when you may
need a different solution here.

=head1 EXTENSION SUPPORT

The WebSocket specification describes several methods of extending the
protocol, all of which Net::WebSocket supports:

=over

=item * The three reserved bits in each frame’s header.
(See L<Net::WebSocket::Frame>.) This is used, e.g., in the
L<permessage-deflate extension|https://tools.ietf.org/html/rfc7692>.

=item * Additional opcodes: 3-7 and 11-15. You’ll need to subclass
L<Net::WebSocket::Frame> for this, and you will likely want to subclass
L<Net::WebSocket::Parser>.
If you’re using the custom classes for streaming, then you can
also subclass L<Net::WebSocket::Streamer>. See each of those modules for
more information on doing this.

B<THIS IS NOT WELL TESTED.> Proceed with caution, and please file bug
reports as needed. (I personally don’t know of any applications that
actually use this.)

=item * Apportion part of the payload data for the extension. This you
can do in your application.

=back

=head2 permessage-deflate

Net::WebSocket 0.5 introduces support for the permessage-delate extension
to allow compressed messages over WebSocket. See
L<Net::WebSocket::PMCE::deflate> for more details.

=head1 TODO

At this point Net::WebSocket should support every widely implemented
WebSocket feature.

=over

=item * Add more tests.

=back

=head1 SEE ALSO

L<Mojolicious> is probably CPAN’s easiest WebSocket implementation to get
a server up and running. If you’re building a project from scratch, you
may find this to be a better fit for you than Net::WebSocket.

L<Protocol::WebSocket> is an older module that supports
pre-standard versions of the WebSocket protocol. It’s similar to this one
in that it gives you just the protocol itself, but it doesn’t give you
things like automatic ping/pong/close, classes for each message type, etc.

L<Net::WebSocket::Server> implements only server behaviors and
gives you more automation than P::WS.

L<Net::WebSocket::EV> uses XS to call a C library.

=head1 REPOSITORY

L<https://github.com/FGasper/p5-Net-WebSocket>

=head1 AUTHOR

Felipe Gasper (FELIPE)

=head1 COPYRIGHT

Copyright 2017 by L<Gasper Software Consulting, LLC|http://gaspersoftware.com>

=head1 LICENSE

This distribution is released under the same license as Perl.

=cut

1;

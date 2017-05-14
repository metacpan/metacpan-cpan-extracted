package Net::WebSocket;

our $VERSION = '0.031';

=encoding utf-8

=head1 NAME

Net::WebSocket - WebSocket in Perl

=head1 SYNOPSIS

    my $handshake = Net::WebSocket::Handshake::Client->new(
        uri => $uri,
    );

    syswrite $inet, $handshake->create_header_text() . "\x0d\x0a" or die $!;

    #You can parse HTTP headers however you want;
    #Net::WebSocket makes no assumptions about this.
    my $req = HTTP::Response->parse($hdrs_txt);

    #XXX More is required for the handshake validation in production!
    my $accept = $req->header('Sec-WebSocket-Accept');
    $handshake->validate_accept_or_die($accept);

    #See below about IO::Framed
    my $parser = Net::WebSocket::Parser->new(
        IO::Framed::Read->new($inet),
        $leftover_from_header_read,     #can be nonempty on the client
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
headers. As a result of this “bare-bones” approach, Net::WebSocket can likely
fit your project; however, it won’t absolve you of the need to know some
things aboutthe WebSocket protocol itself. There are some examples
of how you might write complete applications (client or server)
in the distribution’s C<demo/> directory.

Net::WebSocket is not a “quick” WebSocket solution; for that,
check out L<Mojolicious>. Net::WebSocket’s purpose is to support anything
that the WebSocket protocol itself can do, as lightly as possible and without
prejudice as to how you want to do it: extensions, blocking/non-blocking I/O,
arbitrary HTTP headers, etc. Net::WebSocket will likely require more of an
investment up-front, but its flexibility should allow it to do anything that
can be done with WebSocket, and much more cleanly than a more “monolithic”
solution would likely allow.

=head1 OVERVIEW

Here are the main modules:

=over

=item L<Net::WebSocket::Handshake::Server>

=item L<Net::WebSocket::Handshake::Client>

Logic for handshakes. These are probably most useful in tandem with
modules like L<HTTP::Request> and L<HTTP::Response>.


=item L<Net::WebSocket::Endpoint::Server>

=item L<Net::WebSocket::Endpoint::Client>

The highest-level abstraction that this distribution provides. It parses input
and responds to control frames and timeouts. You can use this to receive
streamed (i.e., fragmented) transmissions as well.

=item L<Net::WebSocket::Streamer::Server>

=item L<Net::WebSocket::Streamer::Client>

Useful for sending streamed (fragmented) data rather than
a full message in a single frame.

=item L<Net::WebSocket::Parser>

Translate WebSocket frames out of a filehandle into useful data for
your application.

=item Net::WebSocket::Frame::*

Useful for creating raw frames. For data frames (besides continuation),
these will be your bread-and-butter. See L<Net::WebSocket::Frame::text>
for sample usage.

=back

=head1 IMPLEMENTATION NOTES

=head2 Handshakes

WebSocket uses regular HTTP headers for its handshakes. Because there are
many different solutions around for parsing HTTP headers, Net::WebSocket
tries to be “agnostic” about how that’s done. The liability of this is
that you, the library user, will need to implement some of the handshake
logic yourself. If you’re building from the ground up that’s not a lot of
fun, but if you’ve already got a solution in place for parsing headers then
Net::WebSocket can fit into that quite easily.

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
data from byte streams into frames. You don’t have to use it (which is why
it’s not listed as a requirement), but you’ll need to provide an equivalent
interface if you don’t.

=head1 EXTENSION SUPPORT

The WebSocket specification describes several methods of extending the
protocol, all of which Net::WebSocket supports:

=over

=item * The three reserved bits in each frame’s header.
(See L<Net::WebSocket::Frame>.) This is used, e.g., in the
L<https://tools.ietf.org/html/rfc7692|permessage-deflate extension>.

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

=head1 TODO

=over

=item * Add tests, especially for extension support.

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

package Net::Async::MCP::Server::Transport::Stdio;
# ABSTRACT: Stdio transport for Net::Async::MCP::Server

use strict;
use warnings;

use parent 'IO::Async::Notifier';

use IO::Async::Loop;
use IO::Async::Stream;
use IO::Handle;
use JSON::MaybeXS qw( encode_json decode_json );
use Scalar::Util qw( weaken );

our $VERSION = '0.003';


sub new {
    my ( $class, %params ) = @_;
    my $server = delete $params{server};
    my $self = $class->SUPER::new(%params);
    $self->{server} = $server if defined $server;
    return $self;
}

sub configure {
    my ( $self, %params ) = @_;
    for my $key (qw( server read_handle write_handle )) {
        $self->{$key} = delete $params{$key} if exists $params{$key};
    }

    $self->{read_handle}  //= \*STDIN;
    $self->{write_handle} //= \*STDOUT;

    $self->SUPER::configure(%params);
}


sub server {
    my ( $self ) = @_;
    return $self->{server};
}


sub read_handle {
    my ( $self ) = @_;
    return $self->{read_handle};
}


sub write_handle {
    my ( $self ) = @_;
    return $self->{write_handle};
}


sub handle_requests {
    my ( $self ) = @_;

    my $loop = $self->loop;
    unless ($loop) {
        $loop = IO::Async::Loop->new;
        $loop->add($self);
    }

    # The write handle is usually a pipe to the client, which Perl block
    # buffers: a finished response would sit in the buffer while the client
    # waits for it and this transport waits for the next request, until 4-8K
    # had piled up or the process exited. Set here rather than in configure
    # because this is the point where the transport takes over a handle the
    # caller owns, and once per run rather than per response.
    my $wh = $self->write_handle;
    $wh->autoflush(1);
    $wh->flush;    # nothing may still sit in the PerlIO buffer ahead of the stream

    # An in-memory handle has no descriptor to register with the loop and
    # stays on the blocking print.
    my $fd = fileno($wh);
    my $wstream;
    if ( defined $fd and $fd >= 0 ) {
        $wstream = IO::Async::Stream->new( write_handle => $wh );
        $self->add_child($wstream);
        $self->{_write_stream} = $wstream;
    }

    my $eof_f = $loop->new_future;

    # The stream holds this callback and this transport holds the stream as a
    # child, so capturing $self strongly here would close a cycle no refcount
    # ever breaks. Weakening costs nothing: for as long as the callback can
    # fire at all, the loop is holding the transport for us.
    weaken( my $weak_self = $self );

    my $stream = IO::Async::Stream->new(
        read_handle       => $self->read_handle,
        close_on_read_eof => 0,
        on_read           => sub {
            my ( undef, $buffref, $eof ) = @_;
            my $self = $weak_self or return 0;
            return $self->_on_read( $buffref, $eof );
        },
        on_read_eof => sub {
            $eof_f->done unless $eof_f->is_ready;
        },
    );

    $self->add_child($stream);

    # A tool that dies no longer reaches here: handle() catches it and
    # answers with an isError result (resources/prompts: -32603). Only an
    # exception outside those evals, e.g. from list_tools, still propagates
    # out of handle() and thus out of here — and the stream has to come back
    # out of the loop either way.
    my $ok  = eval { $eof_f->get; 1 };
    my $err = $@;

    if ($wstream) {
        # A response queued when stdin closed must reach the client. The last
        # write's future is ready once the stream has drained it; a failure
        # means the client is gone and there is nobody left to tell.
        my $last = delete $self->{_last_write_f};
        eval { $last->get } if $last and !$last->is_ready;
        delete $self->{_write_stream};
        $self->remove_child($wstream);
    }

    $self->remove_child($stream);

    die $err unless $ok;
    return;
}

sub _on_read {
    my ( $self, $buffref, $eof ) = @_;

    if ( $$buffref =~ s/^([^\n]*)\n// ) {
        $self->_handle_line($1);
        return 1;    # there may be another complete line in the buffer
    }

    # A final line that never got its newline is still a request; the readline
    # loop this replaced delivered it too.
    if ( $eof and length $$buffref ) {
        my $line = $$buffref;
        $$buffref = '';
        $self->_handle_line($line);
    }

    return 0;
}

sub _handle_line {
    my ( $self, $line ) = @_;

    return unless length $line;

    my $request = eval { decode_json($line) };
    if ($@) {
        $self->_send_response({
            jsonrpc => '2.0',
            id      => undef,
            error   => { code => -32700, message => 'Parse error' },
        });
        return;
    }

    my $response = $self->server->handle(
        $request,
        { transport => 'stdio' },
    );
    $self->_send_response($response) if $response;

    return;
}

sub _send_response {
    my ( $self, $response ) = @_;
    my $line = encode_json($response) . "\n";
    if ( my $wstream = $self->{_write_stream} ) {
        $self->{_last_write_f} = $wstream->write($line);
        return;
    }
    print { $self->write_handle } $line;
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::MCP::Server::Transport::Stdio - Stdio transport for Net::Async::MCP::Server

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use Net::Async::MCP::Server::Transport::Stdio;

    my $transport = Net::Async::MCP::Server::Transport::Stdio->new(
        server => $server,
    );
    $transport->handle_requests;

=head1 DESCRIPTION

Stdio transport for MCP server using newline-delimited JSON-RPC over stdin/stdout.

Each line is a JSON-RPC 2.0 message. Requests and notifications are read from
stdin, responses written to stdout. The transport is stateless — there is no
session, no handshake, and no shared state between requests. The protocol
version, client capabilities, and identity are carried inline in each
request's C<_meta> field (see L<Net::Async::MCP::Server>).

This transport is suitable for MCP clients that communicate via standard input/output,
such as command-line AI tools.

=head1 PROTOCOL

Each JSON-RPC message is a single line terminated by a newline character.
Request format:

    {"jsonrpc": "2.0", "id": 1, "method": "server/discover", "params": {"_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}}}

Response format:

    {"jsonrpc": "2.0", "id": 1, "result": {...}}

Error format:

    {"jsonrpc": "2.0", "id": 1, "error": {"code": -32022, "message": "Unsupported protocol version", "data": {"supported": ["2026-07-28"]}}}

Notifications from the client are accepted and discarded (C<handle()> returns
C<undef>, nothing is written to stdout).

=head2 server

    my $server = $transport->server;

Returns the associated MCP server instance.

=head2 read_handle

    my $fh = $transport->read_handle;

The filehandle JSON-RPC requests are read from, C<\*STDIN> unless a
C<read_handle> was passed to the constructor or to C<configure>. Overriding it
lets the transport be driven from a pipe — which is how it is tested, without
spawning a process. It must be a real OS handle: L</handle_requests> reads it
through an L<IO::Async::Stream>, so an in-memory filehandle will not do.

=head2 write_handle

    my $fh = $transport->write_handle;

The filehandle responses are written to, C<\*STDOUT> unless a C<write_handle>
was passed to the constructor or to C<configure>. Unlike L</read_handle> this
one has two write paths, picked once on entry to L</handle_requests>:

=over

=item *

A handle with an OS file descriptor (C<fileno> E<gt>= 0: C<\*STDOUT>, a pipe,
a socket) is written through an L<IO::Async::Stream>, so a full pipe never
blocks the event loop; the data waits in the stream's buffer until the client
drains it. Registering the handle with the loop puts it into non-blocking mode
(C<O_NONBLOCK>), and that flag lives on the open file description, not on the
Perl handle: it stays set after L</handle_requests> returns and is shared with
every process holding the same descriptor, such as the parent shell's
terminal. Anything else printing to that handle afterwards can see C<EAGAIN>.

=item *

A handle without one (an in-memory filehandle, C<fileno> of C<-1>) cannot be
registered with a loop and keeps the plain, blocking C<print>.

=back

Either way responses leave in the order they were produced. Anything still
sitting in the handle's own PerlIO buffer when L</handle_requests> starts is
flushed first, so it cannot overtake or trail the stream's writes. On entry
C<autoflush> is also turned on for it. That is a change to a handle the caller
may own and keep using, but a buffered response is a response the client never
sees in time.

=head2 handle_requests

    $transport->handle_requests;

Enters the main loop, reading JSON-RPC requests from L</read_handle> and
writing responses to L</write_handle>. This method blocks until the read handle
is closed (EOF), which is the spec's graceful-shutdown signal. Per MCP
2026-07-28 the transport is stateless: each line is an independent request and
the server carries no session across calls.

It blocks the caller, but it does not block the event loop. Reading happens in
an L<IO::Async::Stream> registered as a child of this transport, and the wait
for EOF is a wait on a L<Future>, so every other notifier in the same loop —
timers, other transports — keeps running while requests are being read. If the
transport is not a member of a loop yet, one is created and the transport added
to it.

The read handle is left open on EOF; the caller owns C<STDIN> and may still
want it once the transport has shut down.

Responses are written as they are produced, not when a buffer happens to fill
(see L</write_handle> for the two write paths and the C<O_NONBLOCK> side
effect). On EOF the stream's write buffer is flushed before this method
returns, so a response queued when stdin closed is not lost; if the client is
not draining its end of the pipe, that wait is a wait on a L<Future>, which
leaves the rest of the loop running, but it does not end until the client
reads. A flush that fails because the client went away is ignored.

=head1 SEE ALSO

L<Net::Async::MCP::Server>, L<IO::Async::Notifier>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-net-async-mcp-server/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Net::Async::Kubernetes::PortForwardSession;
# ABSTRACT: Duplex websocket session for pod port-forward, exec and attach
our $VERSION = '0.011';
use strict;
use warnings;
use Carp qw(croak);

sub new {
    my ($class, %args) = @_;
    croak "ws_client required" unless $args{ws_client};
    if (defined $args{ports}) {
        croak "ports must be a non-empty array reference"
            unless ref($args{ports}) eq 'ARRAY' && @{$args{ports}};
        $args{ports} = [@{$args{ports}}];
        my $i = 0;
        for my $port (@{$args{ports}}) {
            $args{_port_index}{$port} //= $i;
            $i++;
        }
    }
    return bless \%args, $class;
}


sub ws_client { $_[0]->{ws_client} }

sub is_port_forward { $_[0]->{ports} ? 1 : 0 }


sub ports { $_[0]->{ports} ? [@{$_[0]->{ports}}] : undef }


# The events one incoming frame of a port-forward session stands for, after
# the two-byte port preamble every channel starts with is checked and
# stripped: ['data', $port, $bytes], ['port_error', $port, $message] or
# ['error', $message] (what Net::Async::Kubernetes hands to on_data,
# on_port_error and on_error). A channel whose preamble was wrong delivers
# nothing further.
sub _port_events {
    my ($self, $channel, $payload) = @_;
    my @ports = @{$self->{ports}};

    return ['error', 'port-forward frame on channel ' . $channel
        . ' but ' . scalar(@ports) . ' port(s) requested use channels 0 to '
        . (2 * @ports - 1)]
        if $channel >= 2 * @ports;

    my $port  = $ports[int($channel / 2)];
    my $is_err = $channel % 2;
    my $what  = 'channel ' . $channel . ' (' . ($is_err ? 'error' : 'data')
        . ' of port ' . $port . ')';

    my $state = $self->{_channel_state}{$channel};
    unless ($state) {
        my $problem;
        if (length($payload) != 2) {
            $problem = length($payload) > 2
                ? 'first frame carries data after the port number'
                : 'first frame is not a 2-byte port number';
            $problem .= ' (' . length($payload) . ' bytes)';
        } elsif ((my $got = unpack('v', $payload)) != $port) {
            $problem = 'port preamble says ' . $got;
        }
        $self->{_channel_state}{$channel} = defined $problem ? 'broken' : 'open';
        return defined $problem ? (['error', $what . ': ' . $problem]) : ();
    }
    return if $state eq 'broken';
    return unless length $payload;
    return $is_err ? (['port_error', $port, $payload]) : (['data', $port, $payload]);
}

sub write_port {
    my ($self, $port, $payload) = @_;

    croak "write_port is only for port-forward sessions" unless $self->{ports};
    croak "port required for write_port" unless defined $port;
    my $i = $self->{_port_index}{$port};
    croak "port '$port' is not forwarded by this session" unless defined $i;

    return $self->write_channel(2 * $i, $payload);
}


sub write_channel {
    my ($self, $channel, $payload) = @_;

    croak "channel required for write_channel" unless defined $channel;
    croak "invalid channel '$channel' for write_channel"
        unless $channel =~ /^\d+$/ && $channel >= 0 && $channel <= 255;

    $payload = '' unless defined $payload;
    croak "payload must be a plain string for write_channel" if ref($payload);

    return $self->ws_client->send_binary_frame(chr($channel) . $payload);
}


sub write_stdin {
    my ($self, $payload) = @_;
    croak "write_stdin is not available on a port-forward session (use write_port)"
        if $self->{ports};
    return $self->write_channel(0, $payload);
}


{
    no warnings 'once';
    *write = \&write_channel;
    *stdin = \&write_stdin;
}

sub resize {
    my ($self, %args) = @_;
    croak "resize is not available on a port-forward session" if $self->{ports};

    my $width  = exists($args{width})  ? $args{width}  : $args{cols};
    my $height = exists($args{height}) ? $args{height} : $args{rows};

    croak "width required for resize" unless defined $width;
    croak "height required for resize" unless defined $height;
    croak "invalid width '$width' for resize"
        unless $width =~ /^\d+$/ && $width > 0;
    croak "invalid height '$height' for resize"
        unless $height =~ /^\d+$/ && $height > 0;

    my $payload = sprintf('{"Width":%d,"Height":%d}', $width, $height);
    return $self->write_channel(4, $payload);
}


sub close {
    my ($self, %args) = @_;
    my $code = $args{code};
    my $payload = exists $args{payload} ? $args{payload} : '';

    croak "payload must be a plain string for close" if ref($payload);
    croak "invalid websocket close code '$code'"
        if defined($code) && ($code !~ /^\d+$/ || $code < 1000 || $code > 4999);

    my $close_payload = defined($code) ? pack('n', $code) . $payload : $payload;
    my $ret = $self->ws_client->send_close_frame($close_payload);
    $self->ws_client->close_when_empty if $self->ws_client->can('close_when_empty');
    return $ret;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Kubernetes::PortForwardSession - Duplex websocket session for pod port-forward, exec and attach

=head1 VERSION

version 0.011

=head1 SYNOPSIS

    my $session = $kube->exec('Pod', 'my-pod',
        namespace => 'default',
        command   => ['sh'],
        tty       => 1,
        on_frame  => sub {
            my ($channel, $payload) = @_;
            print $payload if $channel == 1;   # stdout
        },
    )->get;

    $session->write_stdin("id\n");
    $session->resize(width => 120, height => 40);
    $session->close(code => 1000);

    # port-forward: payload only, preamble stripped by the library
    my $pf = $kube->port_forward('Pod', 'web',
        ports   => [8080],
        on_data => sub { my ($session, $port, $bytes) = @_; print $bytes },
    )->get;
    $pf->write_port(8080, "GET / HTTP/1.0\r\n\r\n");

=head1 DESCRIPTION

A duplex session handle for the Kubernetes exec/attach/port-forward
websocket sub-protocol (C<v4.channel.k8s.io> by default). Every frame on the
wire carries a channel number as its first byte, identifying which logical
stream the rest of the frame belongs to. C<write_channel> is the primitive
that builds such a frame. There are two kinds of session, told apart by
L</is_port_forward>.

B<Exec and attach> sessions have the channels stdin (0), stdout (1), stderr
(2), error/status (3) and TTY resize (4). C<write_stdin> and C<resize> are the
convenience wrappers over channels 0 and 4.

B<Port-forward> sessions have a data and an error channel per forwarded port
(C<2 * $i> and C<2 * $i + 1>), each opened by a two-byte port-number frame.
C<write_port> writes to the data channel of a port; C<write_stdin> and
C<resize> croak. The library strips and checks the preamble and hands the
rest to the C<on_data> and C<on_port_error> callbacks of
L<Net::Async::Kubernetes/port_forward>.

Callers do not normally construct this class themselves: it is what
L<Net::Async::Kubernetes/port_forward>, L<Net::Async::Kubernetes/exec>, and
L<Net::Async::Kubernetes/attach> resolve their returned C<Future> with, and
what they pass to an C<on_open> callback if one was given. Incoming frames
are not read through this object; they arrive via the callbacks passed to
those methods (C<on_frame> with raw C<($channel, $payload)> pairs).

=head2 new

    my $session = Net::Async::Kubernetes::PortForwardSession->new(
        ws_client => $ws_client,
    );

Wraps an already-connected websocket client (normally a
L<Net::Async::WebSocket::Client>) as a session. C<ws_client> is required.

With C<ports> (an arrayref of the requested remote ports, in the order of the
port-forward request) the session is a I<port-forward session>: it knows the
channel layout of the port-forward sub-protocol and offers L</write_port>;
L</write_stdin> and L</resize> croak on it. Without C<ports> it is an
exec/attach session.

Callers do not normally build a session this way: the C<Future> returned by
L<Net::Async::Kubernetes/port_forward>, L<Net::Async::Kubernetes/exec>, and
L<Net::Async::Kubernetes/attach> resolves to one, already bound to the open
connection, and it is what those methods pass to an C<on_open> callback.

=head2 is_port_forward

True for a session of L<Net::Async::Kubernetes/port_forward>, false for exec
and attach. The first kind has L</write_port> and refuses L</write_stdin> and
L</resize>; the second is the other way round.

=head2 ports

The remote ports of a port-forward session in request order, as a fresh
arrayref; channel C<2 * $i> and C<2 * $i + 1> belong to the C<$i>th of them.
C<undef> for an exec or attach session.

=head2 write_port

    $session->write_port(8080, "GET / HTTP/1.1\r\nHost: x\r\n\r\n");

Port-forward sessions only. Send C<$bytes> to the forwarded TCP connection of
remote C<$port>: one binary frame on the port's data channel, C<2 * $i> for
the C<$i>th requested port. It croaks on a port the session was not opened
for and on an exec/attach session.

Returns the L<Future> from L</write_channel>.

=head2 write_channel

    $session->write_channel(0, "id\n");

Send C<$payload> as a single binary websocket frame on the given Kubernetes
stream C<$channel>, with the channel number prepended as the frame's first
byte (C<chr($channel) . $payload>). C<$channel> is required and must be an
integer between 0 and 255; C<$payload> defaults to the empty string.

C<write_channel> itself does not know what any channel number means, it only
frames whatever it is given; the meaning comes from the Kubernetes
sub-protocol of the session.

For an exec or attach session, 0 is stdin, 1 is stdout, 2 is stderr, 3
carries an error/status JSON document, and 4 carries TTY resize events (see
L</resize>).

A port-forward session has a different layout: each requested port C<$i>
(counted from 0, in the order of C<ports>) owns two channels, C<2 * $i> for
data and C<2 * $i + 1> for errors, so with two ports channel 3 is the error
channel of the second one. The first frame the server sends on each of these
channels is the port number as two little-endian bytes, not payload. On a
port-forward session prefer L</write_port>, which finds the channel for a
port; C<write_channel> stays the raw primitive.

C<on_frame>, passed to L<Net::Async::Kubernetes/exec> and friends, splits
incoming frames into C<($channel, $payload)> the same way in reverse; it
does not interpret the channel number and, on a port-forward session, does
not strip the preamble (C<on_data> and C<on_port_error> of
L<Net::Async::Kubernetes/port_forward> do).

Returns the L<Future> from the underlying C<ws_client>'s
C<send_binary_frame> - an L<IO::Async::Stream> write-future that completes
with no value once the frame has been flushed to the connection.

Aliased as C<write>.

=head2 write_stdin

    $session->write_stdin("id\n");

Shortcut for C<< $session->write_channel(0, $payload) >> - writes to channel
0, the stdin stream of an exec or attach session's remote process. It
croaks on a port-forward session, where channel 0 is the data channel of the
first port, not stdin; use L</write_port> there.

Returns the L<Future> from the underlying C<write_channel> call.

Aliased as C<stdin>.

=head2 resize

    $session->resize(width => 120, height => 40);
    $session->resize(cols  => 120, rows   => 40);   # cols/rows are accepted too

Send a TTY resize event on channel 4, as a C<{"Width":$width,"Height":$height}>
JSON payload. C<width> and C<height> (or their C<cols>/C<rows> aliases) are
required and must be positive integers. Only meaningful for a session opened
with C<tty =E<gt> 1>. It croaks on a port-forward session, where channel 4 is
the data channel of the third port.

Returns the L<Future> from the underlying C<write_channel> call.

=head2 close

    $session->close(code => 1000, payload => 'bye');
    $session->close;   # close frame with no code

Send a websocket close frame, ending the session. C<code>, if given, must be
a websocket close code between 1000 and 4999; it is packed as a 16-bit
big-endian prefix (C<pack('n', $code)>) ahead of C<payload>, which defaults
to the empty string. Once the close frame is sent, the underlying transport
is also asked to close the connection once its write buffer drains
(C<close_when_empty>), if the transport supports that method.

Returns the L<Future> from the underlying C<ws_client>'s C<send_close_frame>
- an L<IO::Async::Stream> write-future that completes with no value once the
close frame has been flushed to the connection.

=head1 SEE ALSO

L<Net::Async::Kubernetes>, L<Net::Async::WebSocket::Client>,
L<IO::Async::Stream>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-net-async-kubernetes/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

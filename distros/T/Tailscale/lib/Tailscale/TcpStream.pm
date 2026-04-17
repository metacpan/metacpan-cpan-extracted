package Tailscale::TcpStream;
use strict;
use warnings;

use FFI::Platypus::Buffer qw(scalar_to_pointer buffer_to_scalar);
use Carp qw(croak);

sub _new {
    my ($class, $handle) = @_;
    return bless {
        _handle => $handle,
        _closed => 0,
    }, $class;
}

sub send {
    my ($self, $data) = @_;
    croak "stream is closed" if $self->{_closed};
    my $len = length($data);
    return 0 unless $len;
    my $ptr = scalar_to_pointer($data);
    my $sent = Tailscale::ts_tcp_send($self->{_handle}, $ptr, $len);
    croak "ts_tcp_send failed" if $sent < 0;
    return $sent;
}

# Send all data, looping if necessary.
sub send_all {
    my ($self, $data) = @_;
    my $total = 0;
    while ($total < length($data)) {
        my $sent = $self->send(substr($data, $total));
        $total += $sent;
    }
    return $total;
}

sub recv {
    my ($self, $maxlen) = @_;
    $maxlen //= 4096;
    croak "stream is closed" if $self->{_closed};
    my $buf = "\0" x $maxlen;
    my $ptr = scalar_to_pointer($buf);
    my $n = Tailscale::ts_tcp_recv($self->{_handle}, $ptr, $maxlen);
    return undef if $n == 0;  # EOF
    croak "ts_tcp_recv failed" if $n < 0;
    return substr($buf, 0, $n);
}

sub close {
    my ($self) = @_;
    return if $self->{_closed};
    $self->{_closed} = 1;
    Tailscale::ts_tcp_close($self->{_handle}) if $self->{_handle};
    $self->{_handle} = undef;
}

sub DESTROY {
    my ($self) = @_;
    local ($., $@, $!, $^E, $?);
    $self->close();
}

1;

__END__

=head1 NAME

Tailscale::TcpStream - a TCP connection over Tailscale

=head1 SYNOPSIS

    # Obtained from Tailscale->tcp_connect or TcpListener->accept
    my $stream = $ts->tcp_connect("100.64.0.2:80");

    $stream->send_all("Hello");
    my $reply = $stream->recv(4096);

    $stream->close();

=head1 DESCRIPTION

Represents a bidirectional TCP byte stream between two Tailscale nodes.
You do not construct this directly; it is returned by
L<Tailscale/tcp_connect> or L<Tailscale::TcpListener/accept>.

=head1 METHODS

=head2 send

    my $n = $stream->send($data);

Sends bytes to the peer.  Returns the number of bytes actually sent,
which may be less than C<length($data)>.  Blocks until at least one
byte is sent.  Dies on error.

=head2 send_all

    $stream->send_all($data);

Sends all of C<$data>, looping internally until every byte has been
written.  Returns the total number of bytes sent.

=head2 recv

    my $data = $stream->recv($maxlen);

Receives up to C<$maxlen> bytes from the peer (default 4096).  Blocks
until at least one byte is available.  Returns C<undef> on EOF.  Dies
on error.

=head2 close

    $stream->close();

Closes the stream and releases the underlying handle.  Also called
automatically when the object is destroyed.

=head1 SEE ALSO

L<Tailscale>, L<Tailscale::TcpListener>

=head1 AUTHOR

Brad Fitzpatrick <brad@danga.com>

=head1 LICENSE

BSD-3-Clause

=cut

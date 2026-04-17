package Tailscale::TcpListener;
use strict;
use warnings;

use Carp qw(croak);

sub _new {
    my ($class, $handle) = @_;
    return bless {
        _handle => $handle,
        _closed => 0,
    }, $class;
}

sub accept {
    my ($self) = @_;
    croak "listener is closed" if $self->{_closed};
    my $stream = Tailscale::ts_tcp_accept($self->{_handle});
    croak "ts_tcp_accept failed" unless $stream;
    return Tailscale::TcpStream->_new($stream);
}

sub close {
    my ($self) = @_;
    return if $self->{_closed};
    $self->{_closed} = 1;
    Tailscale::ts_tcp_close_listener($self->{_handle}) if $self->{_handle};
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

Tailscale::TcpListener - listen for TCP connections on a Tailscale node

=head1 SYNOPSIS

    my $listener = $ts->tcp_listen(8080);

    while (my $stream = $listener->accept()) {
        my $data = $stream->recv(4096);
        $stream->send_all($data);    # echo
        $stream->close();
    }

    $listener->close();

=head1 DESCRIPTION

A TCP listener bound to a port on a Tailscale node's address.  You do
not construct this directly; it is returned by L<Tailscale/tcp_listen>.

=head1 METHODS

=head2 accept

    my $stream = $listener->accept();

Blocks until an incoming connection arrives and returns it as a
L<Tailscale::TcpStream>.  Dies on error.

=head2 close

    $listener->close();

Stops listening and releases the underlying handle.  Also called
automatically when the object is destroyed.

=head1 SEE ALSO

L<Tailscale>, L<Tailscale::TcpStream>

=head1 AUTHOR

Brad Fitzpatrick <brad@danga.com>

=head1 LICENSE

BSD-3-Clause

=cut

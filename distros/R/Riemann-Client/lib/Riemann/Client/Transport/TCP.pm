package # hide from CPAN
    Riemann::Client::Transport::TCP;

use Moo;

use Riemann::Client::Protocol;

extends 'Riemann::Client::Transport';

sub send {
    my ($self, $msg) = @_;

    # Encode the message
    my $encoded  = Msg->encode($msg);
    my $e_length = length $encoded;

    # Prepend the length to the binary message
    my $to_send = pack('N', $e_length) . $encoded;
    my $sock    = $self->socket;
    unless ($sock->connected) {
        $self->clear_socket;
        $sock = $self->socket;
    }

    # Write to the socket
    print $sock $to_send or die $!;

    # Read 4 bytes of the response to get the length
    my $res_length;
    my $r = read $sock, $res_length, 4;
    die $! unless defined $r;
    $res_length = unpack('N', $res_length);

    # Something went really wrong. Maybe the connection was closed
    die "Did not receive a response" unless $res_length;

    # Read the actual response
    my $recv;
    $r = read $sock, $recv, $res_length;
    die $! unless defined $r;

    # Decode the message and check for errors
    my $res = Msg->decode($recv);
    die $res->{error} unless $res->{ok};

    return $res;
}

sub DEMOLISH {
    # Close sockets properly on destroy
    close shift->socket;
}

1;

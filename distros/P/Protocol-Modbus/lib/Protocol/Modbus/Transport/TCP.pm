package Protocol::Modbus::Transport::TCP;

use strict;
use warnings;
use base 'Protocol::Modbus::Transport';
use Carp ();
use IO::Socket::INET;

use constant DEFAULT_PORT => 502;

sub connect {
    my $self = $_[0];
    my $sock;
    my $opt = $self->options();

    if (!$self->connected()) {
        my $address = $opt->{address};
        my $port = $opt->{port} || DEFAULT_PORT;

        $sock = IO::Socket::INET->new(
            PeerAddr => $address,
            PeerPort => $port,
            Timeout  => $opt->{timeout} || 3,
        );

        if (!$sock) {
            Carp::croak("Can't connect to Modbus server on $address:$port");
            return (0);
        }

        # Store socket handle inside object
        $self->{_handle} = $sock;

    }
    else {
        $sock = $self->{_handle};
    }

    return ($sock ? 1 : 0);
}

sub connected {
    my $self = $_[0];
    return $self->{_handle};
}

# Send request object
sub send {
    my ($self, $req) = @_;

    my $sock = $self->{_handle};
    return undef unless $sock;

    # Send request PDU and wait 100 msec
    my $ok = $sock->send($req->pdu());
    select(undef, undef, undef, 0.10);

    return ($ok);
}

sub receive {
    my ($self, $req) = @_;

    # Get socket
    my $sock = $self->{_handle};

    $sock->recv(my $data, 256);

    #warn('Received: [' . unpack('H*', $data) . ']');

    return ($data);
}

sub disconnect {
    my $self = $_[0];
    my $sock = $self->{_handle};
    return unless $sock;
    $self->{_handle} = undef;
    $sock->close();
}

1;

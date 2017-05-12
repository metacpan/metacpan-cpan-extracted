package Protocol::Modbus::Transport::Serial;

use strict;
use base 'Protocol::Modbus::Transport';
use Carp ();
use Device::SerialPort;    # TODO Win32::SerialPort for windows machines

sub connect {
    my $self = $_[0];
    my $comm;
    my $opt = $self->options();

    if (!exists $opt->{port} || !$opt->{port}) {
        croak('Modbus Serial transport error: no \'port\' parameter supplied.');
    }

    if (!$self->connected) {
        if (!($comm = Device::SerialPort->new($opt->{port}))) {
            Carp::croak(
                'Modbus Serial transport error: can\'t open port ' . $opt->{port});
            return (0);
        }

        my $ok = $comm->connect(
            baudrate => $opt->{baudrate} || 9600,
            databits => $opt->{databits} || 8,
            stopbits => exists $opt->{stopbits} ? $opt->{stopbits} : 1,
            parity => $opt->{parity} || 'none'
        );

        if (!$ok) {
            Carp::croak(
                'Modbus Serial transport error: can\'t connect to Modbus server on port '
                    . $opt->{port});
            return (0);
        }

        # Purge RX/TX buffers
        $comm->purge_all();

        # Store socket handle inside object
        $self->{_handle} = $comm;

    }
    else {
        $comm = $self->{_handle};
    }

    return ($comm ? 1 : 0);
}

sub connected {
    my $self = $_[0];
    return $self->{_handle};
}

# Send request object
sub send {
    my ($self, $req) = @_;

    my $comm = $self->{_handle};
    return undef unless $comm;

    # Send request PDU and wait 100 msec
    my $ok = $comm->write($req->pdu());
    select(undef, undef, undef, 0.10);

    return ($ok);
}

sub receive {
    my ($self, $req) = @_;

    # Get port channel
    my $comm = $self->{_handle};
    my $data = $comm->read(100);

    #warn('Received: [' . unpack('H*', $data) . ']');
    return ($data);
}

sub disconnect {
    my $self = $_[0];
    my $comm = $self->{_handle};
    return unless $comm;
    $comm->close();
}

1;

package Net::QUIC::Driver;

use strict;
use warnings;

use Carp qw(croak);
use Scalar::Util qw(weaken);

use Net::QUIC ();
use Net::QUIC::Endpoint ();

our $VERSION = '0.01';

sub new {
    my ($class, %args) = @_;

    my $endpoint = delete $args{endpoint};
    my $send = delete $args{send};
    my $set_timeout = delete $args{set_timeout};

    croak "missing required endpoint argument"
        if !defined $endpoint;
    croak "endpoint must provide the Net::QUIC::Endpoint integration methods"
        if !ref($endpoint)
        || !$endpoint->can('receive_datagram')
        || !$endpoint->can('next_datagram')
        || !$endpoint->can('timeout_after')
        || !$endpoint->can('handle_timeout');
    croak "missing required send callback"
        if !defined $send;
    croak "send must be a coderef"
        if ref($send) ne 'CODE';
    croak "missing required set_timeout callback"
        if !defined $set_timeout;
    croak "set_timeout must be a coderef"
        if ref($set_timeout) ne 'CODE';
    croak "unknown arguments: " . join(', ', sort keys %args)
        if %args;

    return bless {
        endpoint       => $endpoint,
        send           => $send,
        set_timeout    => $set_timeout,
        started        => 0,
        blocked        => 0,
        servicing      => 0,
        service_again  => 0,
    }, $class;
}

sub client {
    my ($class, %args) = @_;

    my $send = delete $args{send};
    my $set_timeout = delete $args{set_timeout};

    my $endpoint = Net::QUIC::Endpoint->client(%args);
    my $self = $class->new(
        endpoint    => $endpoint,
        send        => $send,
        set_timeout => $set_timeout,
    );

    $self->_watch_connection($endpoint->connection);
    return $self;
}

sub server {
    my ($class, %args) = @_;

    my $send = delete $args{send};
    my $set_timeout = delete $args{set_timeout};

    my $endpoint = Net::QUIC::Endpoint->server(%args);
    return $class->new(
        endpoint    => $endpoint,
        send        => $send,
        set_timeout => $set_timeout,
    );
}

sub endpoint {
    my ($self) = @_;
    return $self->{endpoint};
}

sub connection {
    my ($self) = @_;
    my $connection = $self->{endpoint}->connection;
    $self->_watch_connection($connection);
    return $connection;
}

sub next_connection {
    my ($self) = @_;
    my $connection = $self->{endpoint}->next_connection;
    $self->_watch_connection($connection) if defined $connection;
    return $connection;
}

sub started {
    my ($self) = @_;
    return $self->{started} ? 1 : 0;
}

sub start {
    my ($self) = @_;

    return $self if $self->{started};

    $self->{started} = 1;
    $self->_service;
    return $self;
}

sub receive {
    my ($self, $bytes, $local, $peer) = @_;

    $self->_require_started('receive');
    $self->{endpoint}->receive_datagram($bytes, $local, $peer);
    $self->_service;
    return;
}

sub timeout {
    my ($self) = @_;

    $self->_require_started('timeout');
    $self->{endpoint}->handle_timeout;
    $self->_service;
    return;
}

sub writable {
    my ($self) = @_;

    $self->_require_started('writable');
    $self->{blocked} = 0;
    $self->_service;
    return;
}

sub _require_started {
    my ($self, $method) = @_;
    croak "$method called before start"
        if !$self->{started};
    return;
}

sub _watch_connection {
    my ($self, $connection) = @_;

    return if !defined $connection
        || !$connection->can('_set_output_callback');

    my $driver = $self;
    weaken($driver);

    $connection->_set_output_callback(sub {
        return if !defined $driver;
        $driver->_application_output;
    });

    return;
}

sub _application_output {
    my ($self) = @_;
    return if !$self->{started};
    $self->_service;
    return;
}

sub _service {
    my ($self) = @_;

    return if !$self->{started};

    if ($self->{servicing}) {
        $self->{service_again} = 1;
        return;
    }

    $self->{servicing} = 1;

    my $ok = eval {
        do {
            $self->{service_again} = 0;

            if (!$self->{blocked}) {
                while (1) {
                    my $datagram = $self->{endpoint}->next_datagram;
                    last if !defined $datagram;

                    my $keep_sending = $self->{send}->($datagram);
                    if (!$keep_sending) {
                        $self->{blocked} = 1;
                        last;
                    }
                }
            }

            my $after = $self->{endpoint}->timeout_after;
            $self->{set_timeout}->($after);
        } while ($self->{service_again});

        1;
    };

    my $error = $@;
    $self->{servicing} = 0;

    die $error if !$ok;
    return;
}

1;

__END__

=head1 NAME

Net::QUIC::Driver - simple event-loop integration for Net::QUIC

=head1 SYNOPSIS

    use Net::QUIC::Driver;

    my $driver = Net::QUIC::Driver->client(
        local       => $packed_local,
        peer        => $packed_peer,
        alpn        => 'my-protocol',
        server_name => 'example.com',

        send => sub {
            my ($datagram) = @_;

            return send_udp_datagram(
                $datagram->data,
                $datagram->local,
                $datagram->peer,
            );
        },

        set_timeout => sub {
            my ($seconds) = @_;

            if (defined $seconds) {
                replace_quic_timer($seconds);
            } else {
                cancel_quic_timer();
            }
        },
    );

    my $connection = $driver->connection;

    # Once the UDP transport is ready to send:
    $driver->start;

    # From the UDP receive callback:
    $driver->receive($bytes, $local, $peer);

    # From the one-shot timer callback:
    $driver->timeout;

    # When UDP output recovers from backpressure:
    $driver->writable;

=head1 DESCRIPTION

Net::QUIC::Driver is the recommended way to connect Net::QUIC to an event
loop.

The event loop owns the UDP socket and one replaceable timer. Driver owns the
QUIC servicing rules around those two things.

L<Net::QUIC::Endpoint> remains the lower-level engine underneath Driver. Driver
drains Endpoint output, stops when the UDP transport reports backpressure, and
replaces the event-loop timeout whenever QUIC's next deadline changes.

An adapter normally reports only four lifecycle events:

    start
    receive
    timeout
    writable

C<start> is a one-time readiness notification. It lets an adapter construct the
Driver before its UDP transport is ready without causing constructor-time I/O.

After startup, the ordinary event-loop inputs are only:

    receive     a UDP datagram arrived
    timeout     the requested QUIC timeout expired
    writable    UDP output can accept more packets again

The adapter supplies only two operations in the other direction:

    send          transmit one complete UDP datagram
    set_timeout   replace or cancel QUIC's one-shot timeout

Application stream operations do not require a separate Driver call. When a
Connection is obtained through the Driver, Net::QUIC installs a private output
notification so state-changing application operations can cause pending QUIC
output and deadline changes to be serviced automatically.

If an adapter can provide UDP receive/send readiness and a one-shot timer, it
usually has everything Driver needs.

Driver methods return after the corresponding QUIC work has been serviced.
The surrounding event callback can then inspect application state normally.
For example, after C<receive> returns a client can check C<ready>, pull peer
streams with C<next_stream>, and consume their data.

Driver handles the transport bookkeeping; it does not impose an application
dispatcher.

=head1 DRIVER OR ENDPOINT?

Use Driver for ordinary event-loop integration.

Use L<Net::QUIC::Endpoint> directly only when the integration deliberately
wants to own QUIC output draining and timeout maintenance itself.

Driver is not a second protocol layer. It is a small piece of integration
bookkeeping around Endpoint.

=head1 CONSTRUCTORS

=head2 client

    my $driver = Net::QUIC::Driver->client(
        local       => $local,
        peer        => $peer,
        alpn        => $alpn,
        server_name => $server_name,
        send        => sub { ... },
        set_timeout => sub { ... },
    );

Creates a client L<Net::QUIC::Endpoint> and wraps it in a Driver.

C<local> and C<peer> are packed IPv4 or IPv6 socket addresses for this UDP
socket and the remote server.

C<alpn> identifies the application protocol carried over QUIC. The client and
server must use a compatible ALPN value.

C<server_name> is the DNS name or IP address expected in the server
certificate. It is used for certificate verification and does not have to be
the same textual value used to obtain C<peer>.

Endpoint options other than C<send> and C<set_timeout> are passed directly to
L<Net::QUIC::Endpoint/client>.

=head2 server

    my $driver = Net::QUIC::Driver->server(
        alpn             => $alpn,
        certificate_file => $certificate_file,
        private_key_file => $private_key_file,
        send              => sub { ... },
        set_timeout       => sub { ... },
    );

Creates a server L<Net::QUIC::Endpoint> and wraps it in a Driver.

New server Connections obtained through C<next_connection> receive the same
automatic application-output notification as the client Connection.

=head2 new

    my $driver = Net::QUIC::Driver->new(
        endpoint    => $endpoint,
        send        => sub { ... },
        set_timeout => sub { ... },
    );

Wraps an existing Endpoint-compatible object. Most adapters can use C<client>
or C<server> instead.

=head1 ADAPTER CALLBACKS

=head2 send

    send => sub {
        my ($datagram) = @_;
        ...
        return 1;
    }

Receives one L<Net::QUIC::Datagram>.

The Datagram contains one complete UDP packet:

    $datagram->data     payload bytes
    $datagram->peer     packed destination socket address
    $datagram->local    packed local socket address chosen by QUIC

The adapter should send C<data> as one UDP datagram to C<peer>. C<local>
is the concrete local source address associated with that QUIC path.

For a socket bound to one concrete local address, the socket normally already
selects that source address.

For a wildcard-bound socket, the adapter must explicitly preserve the
Datagram's C<local> source address when transmitting. The mechanism is
platform-specific; for example, Linux IPv4 can use packet information with
C<sendmsg>.

Return true when the adapter can immediately accept another datagram.

Return false only after accepting this datagram when output has crossed the
adapter's backpressure threshold. Driver then stops asking Net::QUIC for more
datagrams until C<writable> is called.

=head2 set_timeout

    set_timeout => sub {
        my ($seconds) = @_;
        ...
    }

Replace the adapter's current one-shot QUIC timeout.

C<$seconds> is a non-negative number of seconds relative to now. C<undef> means
QUIC currently needs no timed wakeup and the adapter should cancel its existing
QUIC timeout.

The value can change after any QUIC state transition. It is not a recurring
interval.

=head1 METHODS

=head2 start

    $driver->start;

Marks the UDP transport ready and performs the initial QUIC service pass.

For a client this normally sends the Initial packet and requests the first QUIC
timeout.

C<start> is idempotent.

=head2 receive

    $driver->receive($bytes, $local, $peer);

Report one received UDP datagram.

C<$local> must be the packed concrete destination address on which this packet
was received. C<0.0.0.0> and C<::> are wildcard bind addresses and are not
valid QUIC paths.

A socket bound to a wildcard address therefore needs destination-address packet
information from the operating system. On Linux IPv4 this can be obtained with
C<IP_PKTINFO> and C<recvmsg>. The equivalent mechanism for other address
families or operating systems belongs in the UDP adapter.

C<$peer> is the packed address of the remote sender.

Driver gives the packet to the Endpoint, sends any datagrams QUIC produces, and
updates the requested timeout.

=head2 timeout

    $driver->timeout;

Report that the one-shot timeout most recently requested through
C<set_timeout> has fired.

Driver lets QUIC process the expiry, sends any resulting datagrams, and updates
the next timeout.

=head2 writable

    $driver->writable;

Report that UDP output has recovered after C<send> returned false.

Driver resumes sending queued QUIC datagrams and updates the timeout.

=head2 connection

Returns the client Connection and enables automatic application-output
notification for it.

A server Driver follows the Endpoint rule and does not provide one singular
Connection through this method.

=head2 next_connection

Returns the next new server Connection, or undef when none is waiting.

The returned Connection is automatically connected to the Driver's private
application-output notification.

=head2 endpoint

Returns the underlying low-level Endpoint.

This escape hatch is intended for integrations that need Endpoint-specific
functionality. Code that directly drives the Endpoint is responsible for not
bypassing Driver's integration rules.

=head2 started

Returns true after C<start>.

=head1 LOW-LEVEL ENDPOINT

Driver does not replace L<Net::QUIC::Endpoint>.

Endpoint remains useful for tests, unusual integrations, and code that
deliberately wants direct control over:

    receive_datagram
    next_datagram
    timeout_after
    handle_timeout

Driver is the simpler recommended API for ordinary event-loop adapters.

=head1 EXAMPLES

The distribution includes complete Driver integrations in F<examples/> for:

    Linux::Event
    AnyEvent
    IO::Async
    Mojo::IOLoop
    EV

F<examples/io-select-echo-server.pl> provides a small local QUIC echo server
that can be used to run the client examples.

See F<examples/README.md>.

=cut

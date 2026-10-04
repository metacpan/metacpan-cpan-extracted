package Net::QUIC::Driver;

use strict;
use warnings;

use Carp qw(croak);
use Scalar::Util qw(weaken);

use Net::QUIC ();
use Net::QUIC::Endpoint ();

our $VERSION = '0.04';

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
    my ($self, $bytes, $local, $peer, $ecn) = @_;

    $self->_require_started('receive');

    if (defined $ecn) {
        $self->{endpoint}->receive_datagram(
            $bytes,
            $local,
            $peer,
            $ecn,
        );
    } else {
        $self->{endpoint}->receive_datagram(
            $bytes,
            $local,
            $peer,
        );
    }

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

Net::QUIC::Driver - connect Net::QUIC to an event loop

=head1 DESCRIPTION

Driver is the recommended integration API.

Net::QUIC needs two things from an event loop:

    UDP I/O
    one replaceable one-shot timer

Driver turns those two things into a working QUIC transport.

Your application normally does not call a separate QUIC pump. Driver handles
the routine transport work after UDP reads, timer expirations, writable
notifications, and application Stream operations.

If you are writing an event-loop adapter, start here.

=head1 QUICK MODEL

The adapter gives Driver two callbacks:

    send
    set_timeout

The adapter reports four events to Driver:

    start
    receive
    timeout
    writable

In plain language:

    UDP transport is ready
        -> start

    one UDP packet arrived
        -> receive

    the requested timer fired
        -> timeout

    UDP output was blocked and can send again
        -> writable

=head1 SYNOPSIS

    use Net::QUIC::Driver;

    my $driver = Net::QUIC::Driver->client(
        local       => $packed_local,
        peer        => $packed_peer,
        alpn        => 'my-protocol',
        server_name => 'example.com',

        send => sub {
            my ($datagram) = @_;

            send_one_udp_packet(
                $datagram->data,
                $datagram->local,
                $datagram->peer,
            );

            return 1;
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

    $driver->start;

From the UDP read callback:

    $driver->receive($bytes, $local, $peer);

From the timer callback:

    $driver->timeout;

If UDP sending had become blocked and later recovers:

    $driver->writable;

=head1 DRIVER OR ENDPOINT?

Use Driver unless you have a specific reason not to.

L<Net::QUIC::Endpoint> is the lower-level engine underneath Driver. Endpoint
makes the caller manually drain output and maintain the QUIC timer.

Driver does that bookkeeping for you.

=head1 CONSTRUCTORS

=head2 client

    my $driver = Net::QUIC::Driver->client(
        local       => $local,
        peer        => $peer,
        alpn        => 'my-protocol',
        server_name => 'example.com',
        send        => sub { ... },
        set_timeout => sub { ... },
    );

Creates a client Driver.

C<local> is the packed local UDP socket address.

C<peer> is the packed server UDP address.

C<alpn> is the application protocol name that client and server agree to use.

C<server_name> is the DNS name or IP address expected in the server
certificate.

Other client options are passed to L<Net::QUIC::Endpoint/client>. This includes
session resumption, 0-RTT, address-token reuse, QUIC version selection, and
transport limits.

=head2 server

    my $driver = Net::QUIC::Driver->server(
        alpn             => 'my-protocol',
        certificate_file => 'server-cert.pem',
        private_key_file => 'server-key.pem',
        send              => sub { ... },
        set_timeout       => sub { ... },
    );

Creates a server Driver.

One server Driver can manage many QUIC Connections on one UDP socket.

Pull newly created Connections with L</next_connection>.

Other server options are passed to L<Net::QUIC::Endpoint/server>.

=head2 new

    my $driver = Net::QUIC::Driver->new(
        endpoint    => $endpoint,
        send        => sub { ... },
        set_timeout => sub { ... },
    );

Wraps an existing Endpoint-compatible object.

Most code should use C<client> or C<server> instead.

=head1 ADAPTER CALLBACKS

=head2 send

    send => sub {
        my ($datagram) = @_;
        ...
        return 1;
    }

Receives one complete L<Net::QUIC::Datagram>.

Useful values are:

    $datagram->data
    $datagram->local
    $datagram->peer
    $datagram->ecn

C<data> is one complete UDP payload. Do not split it.

C<peer> is the destination address.

C<local> is the local source address QUIC expects for that packet.

For a socket bound to one concrete local address, the socket normally already
uses the right source address.

For a wildcard-bound socket or a migrating connection, the adapter may need a
platform-specific source-address mechanism such as C<sendmsg> packet
information.

The callback return value controls output flow:

=over 4

=item * true

The adapter can accept another UDP datagram immediately.

=item * false

This datagram was accepted, but the adapter cannot accept another one yet.

=back

That temporary inability to accept more output is often called
I<backpressure>.

When output becomes available again, call L</writable>.

=head2 set_timeout

    set_timeout => sub {
        my ($seconds) = @_;
        ...
    }

Replace the current one-shot QUIC timer.

C<$seconds> is relative to now and can be fractional.

C<undef> means cancel the current QUIC timer.

This is not a repeating interval. Driver can request a different value after
any QUIC state change.

=head1 METHODS

=head2 start

    $driver->start;

Tells Driver that the UDP transport is ready.

For a client this normally causes the first QUIC packet to be produced.

C<start> is idempotent.

=head2 receive

    $driver->receive($bytes, $local, $peer);

Reports one received UDP datagram.

C<$local> is the concrete local address on which the packet arrived.

C<$peer> is the sender's address.

Both are packed IPv4 or IPv6 socket addresses.

C<0.0.0.0> and C<::> are wildcard bind addresses and are not valid packet
paths. A wildcard-bound server therefore needs the operating system's
destination-address information for each received packet.

An ECN-aware adapter can pass one optional fourth argument:

    $driver->receive($bytes, $local, $peer, $ecn);

where C<$ecn> is the two-bit IP-header value from 0 through 3.

Adapters that do not support ECN can omit it.

Driver processes the packet, sends any resulting output, and updates the timer
before returning.

=head2 timeout

    $driver->timeout;

Reports that the currently requested one-shot QUIC timer fired.

Driver processes the timeout, sends any resulting packets, and requests the
next timer value.

=head2 writable

    $driver->writable;

Reports that UDP output can accept packets again after C<send> returned false.

Driver resumes output and updates the timer.

=head2 connection

    my $connection = $driver->connection;

Client only.

Returns the client's L<Net::QUIC::Connection>.

=head2 next_connection

    while (my $connection = $driver->next_connection) {
        ...
    }

Server only.

Returns the next newly created Connection, or undef when none is waiting.

A new server Connection can be returned before its handshake is complete.
Check:

    $connection->ready

before ordinary application work.

=head2 endpoint

Returns the underlying L<Net::QUIC::Endpoint>.

This is an escape hatch for integrations that need Endpoint-specific
functionality.

=head2 started

Returns true after C<start>.

=head1 APPLICATION OPERATIONS

Connections and Streams obtained through Driver automatically notify it when
application operations create transport work.

For example:

    $stream->send(...);
    $stream->finish;
    $stream->reset(...);
    $connection->close;

do not require a separate Driver service call.

=head1 EXAMPLES

Complete Driver integrations are included in F<examples/> for:

    Linux::Event
    AnyEvent
    IO::Async
    Mojo::IOLoop
    EV

There is also a small IO::Select echo server.

See F<examples/README.md>.

=head1 SEE ALSO

L<Net::QUIC>

L<Net::QUIC::Connection>

L<Net::QUIC::Stream>

L<Net::QUIC::Endpoint>

L<Net::QUIC::Datagram>

=cut

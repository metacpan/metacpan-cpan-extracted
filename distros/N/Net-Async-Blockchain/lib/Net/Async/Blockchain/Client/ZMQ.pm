package Net::Async::Blockchain::Client::ZMQ;

use strict;
use warnings;

our $VERSION = '0.003';

=head1 NAME

Net::Async::Blockchain::Client::ZMQ - Async ZMQ Client.

=head1 SYNOPSIS

    my $loop = IO::Async::Loop->new();

    $loop->add(my $zmq_source = Ryu::Async->new);

    $loop->add(
        my $zmq_client = Net::Async::Blockchain::Client::ZMQ->new(
            endpoint => 'tpc://127.0.0.1:28332',
        ));

    $zmq_client->subscribe('hashblock')->each(sub{print shift->{hash}})->get;

=head1 DESCRIPTION

client for the bitcoin ZMQ server

=over 4

=back

=cut

no indirect;

use ZMQ::LibZMQ3;
use ZMQ::Constants qw(ZMQ_RCVMORE ZMQ_SUB ZMQ_SUBSCRIBE ZMQ_RCVHWM ZMQ_FD ZMQ_DONTWAIT ZMQ_RCVTIMEO);
use IO::Async::Handle;
use Socket;
use curry;
use Ryu::Async;

use parent qw(IO::Async::Notifier);

use constant {
    # https://github.com/lestrrat-p5/ZMQ/blob/master/ZMQ-Constants/lib/ZMQ/Constants.pm#L128
    ZMQ_CONNECT_TIMEOUT => 79,
};

# Since the connect timeout is not present in the LIbZMQ3 module
# we need to add it manually
ZMQ::Constants::set_sockopt_type("int" => ZMQ_CONNECT_TIMEOUT);

=head2 source

Create an L<Ryu::Source> instance, if it is already defined just return
the object

=over 4

=back

L<Ryu::Source>

=cut

sub source : method {
    my ($self) = @_;
    return $self->{source} //= do {
        $self->add_child(my $ryu = Ryu::Async->new);
        $ryu->source;
    };
}

=head2 endpoint

TCP ZMQ endpoint

=over 4

=back

URL containing the port if needed, in case of DNS this will
be resolved to an IP.

=cut

sub endpoint : method { shift->{endpoint} }

=head2 timeout

Timeout time for connection

=over 4

=back

Integer time in seconds

=cut

sub timeout : method { shift->{timeout} }

=head2 msg_timeout

Timeout time for received messages, this is applied when we have a bigger
duration interval between the messages.

=over 4

=back

Integer time in seconds

=cut

sub msg_timeout : method { shift->{msg_timeout} }

=head2 socket_client

ZMQ socket

=over 4

=back

return the socket for ZMQ L<ZMQ::LibZMQ3>

=cut

sub socket_client : method {
    shift->{socket_client};
}

=head2 configure

Any additional configuration that is not described on L<IO::Async::Notifier>
must be included and removed here.

If this class receive a DNS as endpoint this will be resolved on this method
to an IP address.

=over 4

=item * C<endpoint>

=item * C<timeout> connection timeout (seconds)

=item * C<msg_timeout> msg interval timetout (seconds)

=back

=cut

sub configure {
    my ($self, %params) = @_;

    for my $k (qw(endpoint timeout msg_timeout on_shutdown)) {
        $self->{$k} = delete $params{$k} if exists $params{$k};
    }

    $self->SUPER::configure(%params);

    my $uri  = URI->new($self->endpoint);
    my $host = $uri->host;

    # Resolve DNS if needed
    if ($host !~ /(\d+(\.|$)){4}/) {
        my @addresses = gethostbyname($host) or die "Can't resolve @{[$host]}: $!";
        @addresses = map { inet_ntoa($_) } @addresses[4 .. $#addresses];

        my $address = $addresses[0];

        $self->{endpoint} = $self->{endpoint} =~ s/$host/$address/r;
    }

}

=head2 subscribe

Connect to the ZMQ server and start the subscription

=over 4

=item * C<subscription> subscription string name

=back

L<Ryu::Source>

=cut

sub subscribe {
    my ($self, $subscription) = @_;

    # one thread
    my $ctxt = zmq_ctx_new(1);
    die "zmq_ctc_new failed with $!" unless $ctxt;

    my $socket = zmq_socket($ctxt, ZMQ_SUB);
    $self->{socket_client} = $socket;

    # zmq_setsockopt_string is not exported
    ZMQ::LibZMQ3::zmq_setsockopt_string($socket, ZMQ_SUBSCRIBE, $subscription);

    # set connection timeout
    zmq_setsockopt($socket, ZMQ_CONNECT_TIMEOUT, $self->timeout) if $self->timeout;

    my $connect_response = zmq_connect($socket, $self->endpoint);
    $self->shutdown("zmq_connect failed with $!") unless $connect_response == 0;

    # receive message timeout
    zmq_setsockopt($socket, ZMQ_RCVTIMEO, $self->msg_timeout) if $self->msg_timeout;

    # create a reader for IO::Async::Handle using the ZMQ socket file descriptor
    my $fd = zmq_getsockopt($socket, ZMQ_FD);
    open(my $io, '<&', $fd) or $self->shutdown("Unable to open file descriptor");

    $self->add_child(
        my $handle = IO::Async::Handle->new(
            read_handle => $io,
            on_closed   => $self->$curry::weak(
                sub {
                    my $self = shift;
                    close($io);
                    my $error = "Connection closed by peer";
                    $self->source->fail($error) unless $self->source->completed->is_ready;
                    $self->shutdown($error);
                }
            ),
            on_read_ready => $self->$curry::weak(
                sub {
                    my $self = shift;
                    while (my @msg = $self->_recv_multipart($socket)) {
                        my $hex = unpack('H*', zmq_msg_data($msg[1]));
                        $self->source->emit($hex);
                    }
                }
            ),
        ));

    return $self->source;
}

=head2 _recv_multipart

Since each response is partial we need to join them

=over 4

=item * C<subscription> subscription string name

=back

Multipart response array

=cut

sub _recv_multipart {
    my ($self, $socket) = @_;

    my @multipart;

    push @multipart, zmq_recvmsg($socket, ZMQ_DONTWAIT);
    while (zmq_getsockopt($socket, ZMQ_RCVMORE)) {
        push @multipart, zmq_recvmsg($socket, ZMQ_DONTWAIT);
    }

    return @multipart;
}

=head2 shutdown

run the configured shutdown action if any

=over 4

=item * C<error> error message

=back

=cut

sub shutdown {    ## no critic
    my ($self, $error) = @_;

    if (my $code = $self->{on_shutdown} || $self->can("on_shutdown")) {
        return $code->($error);
    }
    return undef;
}

1;

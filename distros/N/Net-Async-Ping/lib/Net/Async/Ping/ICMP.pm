package Net::Async::Ping::ICMP;
$Net::Async::Ping::ICMP::VERSION = '0.003003';
use Moo;
use warnings NONFATAL => 'all';

use Future;
use POSIX 'ECONNREFUSED';
use Time::HiRes;
use Carp;
use Net::Ping;
use IO::Async::Socket;
use Scalar::Util qw/blessed/;

use Socket qw(
    SOCK_RAW SOCK_DGRAM AF_INET IPPROTO_ICMP NI_NUMERICHOST NIx_NOSERV
    inet_aton pack_sockaddr_in unpack_sockaddr_in getnameinfo inet_ntop
);
use Net::Frame::Layer::ICMPv4 qw( :consts );
use Net::Frame::Layer::ICMPv4::Echo;
use Net::Frame::Simple;

use constant ICMP_FLAGS       => 0; # No special flags for send or recv

extends 'IO::Async::Notifier';

use namespace::clean;

has default_timeout => (
   is => 'ro',
   default => 5,
);

has bind => ( is => 'rw' );

has _pid => (
    is => 'lazy',
);

sub _build__pid
{   my $self = shift;
    $$ & 0xffff;
}

has seq => (
    is      => 'ro',
    default => 1,
);

# Whether to try and use ping sockets. This option used in tests
# to force normal ping to be used
has use_ping_socket => (
    is      => 'ro',
    default => 1,
);

# Overrides method in IO::Async::Notifier to allow specific options in this class
sub configure_unknown
{   my $self = shift;
    my %params = @_;
    delete $params{$_} foreach qw/default_timeout bind seq use_ping_socket/;
    return unless keys %params;
    my $class = ref $self;
    croak "Unrecognised configuration keys for $class - " . join( " ", keys %params );

}

sub ping {
    my $self = shift;
    # Maintain compat with old API
    my $legacy = blessed $_[0] and $_[0]->isa('IO::Async::Loop');
    my $loop   = $legacy ? shift : $self->loop;

    my ($host, $timeout) = @_;
    $timeout //= $self->default_timeout;

    my $t0 = [Time::HiRes::gettimeofday];

    my $fh = IO::Socket->new;
    # Let's try a ping socket (unprivileged ping) first. See
    # https://lwn.net/Articles/422330/
    my ($ping_socket, $ident);
    if ($self->use_ping_socket
        && $fh->socket(AF_INET, SOCK_DGRAM, IPPROTO_ICMP)) {
        $ping_socket = 1;
        ($ident) = unpack_sockaddr_in getsockname($fh);
    }
    else {
        $fh->socket(AF_INET, SOCK_RAW, IPPROTO_ICMP) ||
            croak("Unable to create ICMP socket ($!). Are you running as root?"
              ." If not, and your system supports ping sockets, try setting"
              ." /proc/sys/net/ipv4/ping_group_range");
        $ident = $self->_pid;
    }

    if ($self->bind)
    {
        my $bind = pack_sockaddr_in 0, inet_aton $self->bind;
        bind $fh, $bind
            or croak "Failed to bind to ".$self->bind;
    }

    $loop->resolver->getaddrinfo(
       host     => $host,
       protocol => IPPROTO_ICMP,
       family   => AF_INET,
    )->then( sub {
        my $saddr  = $_[0]->{addr};
        my ($err, $dst_ip) = getnameinfo($saddr, NI_NUMERICHOST,
            NIx_NOSERV);
        croak "getnameinfo: $err"
            if $err;
        my $f      = $loop->new_future;

        my $socket = IO::Async::Socket->new(
            handle => $fh,
            on_recv_error => sub {
                my ( $self, $errno ) = @_;
                $f->fail('Receive error');
            },
        );

        my $on_recv = $self->_capture_weakself(
            sub {
                my $ping = shift or return; # weakref, may have disappeared
                my ( $self, $recv_msg, $from_saddr ) = @_;

                my $from_ip  = -1;
                my $from_pid = -1;
                my $from_seq = -1;

                my @layers;
                # ping sockets only return the ICMP packet
                if ($ping_socket) {
                   my $frame = Net::Frame::Simple->new(
                        raw        => $recv_msg,
                        firstLayer => 'ICMPv4',
                    );
                    @layers = $frame->layers;
                }
                # raw sockets return the IPv4 packet containing the ICMP payload
                else {
                   my $frame = Net::Frame::Simple->new(
                        raw        => $recv_msg,
                        firstLayer => 'IPv4',
                    );
                    @layers = $frame->layers;
                    # discard the IPv4 layer
                    shift @layers;
                }
                my $icmpv4 = $layers[0];
                my $icmpv4_payload = $layers[1];

                # extract source ip, identifier and sequence depending on
                # packet type
                if ( $icmpv4->type == NF_ICMPv4_TYPE_ECHO_REPLY ) {
                    (my $err, $from_ip) = getnameinfo($from_saddr,
                        NI_NUMERICHOST, NIx_NOSERV);
                    croak "getnameinfo: $err"
                        if $err;
                    $from_pid = $icmpv4_payload->identifier;
                    $from_seq = $icmpv4_payload->sequenceNumber;
                }
                # an ICMPv4 error message includes the original header
                # IPv4 + ICMPv4 + ICMPv4::Echo
                elsif ( scalar @layers >= 5
                    && $layers[3]->type == NF_ICMPv4_TYPE_ECHO_REQUEST ) {
                    my $ipv4 = $layers[2];
                    my $icmpv4_echo = $layers[4];

                    # the destination IPv4 of our ICMP echo request packet
                    $from_ip  = $ipv4->dst;
                    $from_pid = $icmpv4_echo->identifier;
                    $from_seq = $icmpv4_echo->sequenceNumber;
                }

                # ignore received packets which are not a response to one of
                # our echo requests
                return
                    unless $from_ip eq $dst_ip
                # Not needed for ping socket - kernel handles this for us
                        && ( $ping_socket || $from_pid == $ping->_pid )
                        && $from_seq == $ping->seq;

		if ( $icmpv4->type == NF_ICMPv4_TYPE_ECHO_REPLY ) {
                    $f->done;
                }
		elsif ( $icmpv4->type == NF_ICMPv4_TYPE_DESTUNREACH ) {
                    $f->fail('ICMP Unreachable');
                }
		elsif ( $icmpv4->type == NF_ICMPv4_TYPE_TIMEEXCEED ) {
                    $f->fail('ICMP Timeout');
                }
            },
        );

        $socket->configure(on_recv => $on_recv);
        $legacy ? $loop->add($socket) : $self->add_child($socket);
        $socket->send( $self->_msg($ident), ICMP_FLAGS, $saddr );

        Future->wait_any(
           $f,
           $loop->timeout_future(after => $timeout)
        )
        ->then( sub {
            Future->done(Time::HiRes::tv_interval($t0))
        })
        ->followed_by( sub {
            my $f = shift;
            $socket->remove_from_parent;
            $f;
        })
    });
}

sub _msg {
    my ($self, $ident) = @_;

    my $echo = Net::Frame::Layer::ICMPv4::Echo->new(
        identifier     => $ident,
        sequenceNumber => $self->seq,
    );
    my $icmpv4 = Net::Frame::Layer::ICMPv4->new(
        type     => NF_ICMPv4_TYPE_ECHO_REQUEST,
        code     => NF_ICMPv4_CODE_ZERO,
        payload  => $echo->pack,
    );

    # FIXME: use Net::Frame::Simple after RT124015 is fixed
    #my $echoReq = Net::Frame::Simple->new(layers => [ $icmpv4, $echo ]);
    #return $echoReq->pack;
    $icmpv4->computeLengths;
    $icmpv4->computeChecksums([$echo]);
    return $icmpv4->pack . $echo->pack;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Ping::ICMP

=head1 VERSION

version 0.003003

=head1 DESCRIPTION

This is the ICMP part of L<Net::Async::Ping>. See that documentation for full
details.

=head2 ICMP methods

This module will first attempt to use a ping socket to send its ICMP packets,
which does not need root privileges. These are only supported on Linux, and
only when the group is stipulated in C</proc/sys/net/ipv4/ping_group_range>.
Failing that, the module will send standard RAW packets, which will fail if
attempted from a non-privileged account.

=head2 Additional options

To disable the attempt to send from a ping socket, set C<use_ping_socket> to
0 when initiating the object:

 my $p = Net::Async::Ping->new(
   icmp => {
      use_ping_socket => 0,
   },
 );

=head2 Return value

L<Net::Async::Ping::ICMP> will return the hires time on success. On failure, it
will return the future from L<IO::Async::Resolver> if that failed. Otherwise,
it will return as a future failure:

=over 4

=item "ICMP Unreachable"

ICMP response was ICMP_UNREACHABLE

=item "ICMP Timeout"

ICMP response was ICMP_TIME_EXCEEDED

=item "Receive error"

An error was received from L<IO::Async::Socket>.

=back

=head1 NAME

Net::Async::Ping::ICMP

=head1 AUTHORS

=over 4

=item *

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=item *

Alexander Hartmaier <abraxxa@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Arthur Axel "fREW" Schmidt, Alexander Hartmaier.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

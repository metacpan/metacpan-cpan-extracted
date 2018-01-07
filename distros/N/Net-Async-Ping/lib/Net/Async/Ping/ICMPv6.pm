package Net::Async::Ping::ICMPv6;
$Net::Async::Ping::ICMPv6::VERSION = '0.003000';
use Moo;
use warnings NONFATAL => 'all';

use Future;
use Time::HiRes;
use Carp qw( croak );
use IO::Socket;
use IO::Async::Socket;
use Scalar::Util qw( blessed );
use Socket qw(
    SOCK_RAW SOCK_DGRAM AF_INET6
    inet_pton pack_sockaddr_in6 unpack_sockaddr_in6 inet_ntop
);
use Net::Frame::Layer::ICMPv6 qw( :consts );
use Net::Frame::Layer::ICMPv6::Echo;
use Net::Frame::Simple;

use constant ICMPv6_FLAGS => 0; # No special flags for send or recv

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
    delete $params{$_}
        for qw( default_timeout bind seq use_ping_socket );
    return
        unless keys %params;
    my $class = ref $self;
    croak "Unrecognised configuration keys for $class - " .
        join( " ", keys %params );

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
    my $proto_num = getprotobyname('ipv6-icmp') ||
        croak("Can't get ipv6-icmp protocol by name");
    # Let's try a ping socket (unprivileged ping) first. See
    # https://github.com/torvalds/linux/commit/6d0bfe22611602f36617bc7aa2ffa1bbb2f54c67
    my ($ping_socket, $ident);
    if ( $self->use_ping_socket
         && $fh->socket(AF_INET6, SOCK_DGRAM, $proto_num) ) {
        $ping_socket = 1;
        ($ident) = unpack_sockaddr_in6 getsockname($fh);
    }
    else {
        $fh->socket(AF_INET6, SOCK_RAW, $proto_num) ||
            croak("Unable to create ICMPv6 socket ($!). Are you running as root?"
              ." If not, and your system supports ping sockets, try setting"
              ." /proc/sys/net/ipv4/ping_group_range");
        #TODO: IPv6 sockets support filtering, should we?
        #$fh->setsockopt($proto_num, 1, NF_ICMPv6_TYPE_ECHO_REQUEST);
        #print "SOCKOPT: '" . $fh->getsockopt($proto_num, 1) . "'\n";
        $ident = $self->_pid;
    }

    if ( $self->bind ) {
        my $bind = pack_sockaddr_in6( 0, inet_pton AF_INET6, $self->bind );
        bind $fh, $bind
            or croak "Failed to bind to ".$self->bind;
    }

    $loop->resolver->getaddrinfo(
       host     => $host,
       protocol => $proto_num,
       family   => AF_INET6,
    )->then( sub {
        my $saddr = $_[0]->{addr};
        my $f     = $loop->new_future;

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

                my $from_pid = -1;
                my $from_seq = -1;
                my ($from_port, $from_ip) = unpack_sockaddr_in6($from_saddr);


                my $frame = Net::Frame::Simple->new(
                    raw        => $recv_msg,
                    firstLayer => 'ICMPv6',
                );
                my @layers = $frame->layers;
                my $icmpv6 = $layers[0];
                my $icmpv6_payload = $layers[1];

                if ( $icmpv6->type == NF_ICMPv6_TYPE_ECHO_REPLY ) {
                    $from_pid = $icmpv6_payload->identifier;
                    $from_seq = $icmpv6_payload->sequenceNumber;
                }
                # an ICMPv6 error message includes the original header
                # IPv6 + ICMPv6 + ICMPv6::Echo
                # extract identifier and sequence from it
                elsif ( scalar @layers >= 5
                    && $layers[3]->type == NF_ICMPv6_TYPE_ECHO_REQUEST ) {
                    my $icmpv6_echo = $layers[4];

                    $from_pid = $icmpv6_echo->identifier;
                    $from_seq = $icmpv6_echo->sequenceNumber;
                }

                # Not needed for ping socket - kernel handles this for us
                return if !$ping_socket && $from_pid != $ping->_pid;
                return if $from_seq != $ping->seq;
                if ( $icmpv6->type == NF_ICMPv6_TYPE_ECHO_REPLY ) {
                    my $ip = unpack_sockaddr_in6($saddr);
                    return if inet_ntop(AF_INET6, $from_ip) ne inet_ntop(AF_INET6, $ip); # Does the packet check out?
                    $f->done;
                }
                elsif ( $icmpv6->type == NF_ICMPv6_TYPE_DESTUNREACH ) {
                    $f->fail('ICMPv6 Unreachable');
                }
                elsif ( $icmpv6->type == NF_ICMPv6_TYPE_TIMEEXCEED ) {
                    $f->fail('ICMPv6 Timeout');
                }
            }
        );

        $socket->configure( on_recv => $on_recv );
        $legacy ? $loop->add($socket) : $self->add_child($socket);
        $socket->send( $self->_msg($ident), ICMPv6_FLAGS, $saddr );

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

    my $echo = Net::Frame::Layer::ICMPv6::Echo->new(
        identifier     => $ident,
        sequenceNumber => $self->seq,
    );
    my $icmpv6 = Net::Frame::Layer::ICMPv6->new(
        type     => NF_ICMPv6_TYPE_ECHO_REQUEST,
        code     => NF_ICMPv6_CODE_ZERO,
        #checksum => 0,
        #payload  => $echo->pack,
    );

    # FIXME: use Net::Frame::Simple after RT124015 is fixed
    #my $echoReq = Net::Frame::Simple->new(layers => [ $icmpv6, $echo ]);
    #return $echoReq->pack;
    return $icmpv6->pack . $echo->pack;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Ping::ICMPv6

=head1 VERSION

version 0.003000

=head1 DESCRIPTION

This is the ICMPv6 part of L<Net::Async::Ping>. See that documentation for full
details.

=head2 ICMPv6 methods

This module will first attempt to use a ping socket to send its ICMPv6 packets,
which does not need root privileges. These are only supported on Linux, and
only when the group is stipulated in C</proc/sys/net/ipv4/ping_group_range>
(yes, the IPv4 setting also controls the IPv6 socket).
Failing that, the module will send standard RAW packets, which will fail if
attempted from a non-privileged account.

=head2 Additional options

To disable the attempt to send from a ping socket, set C<use_ping_socket> to
0 when initiating the object:

 my $p = Net::Async::Ping->new(
   icmpv6 => {
      use_ping_socket => 0,
   },
 );

=head2 Return value

L<Net::Async::Ping::ICMPv6> will return the hires time on success. On failure, it
will return the future from L<IO::Async::Resolver> if that failed. Otherwise,
it will return as a future failure:

=over 4

=item "ICMPv6 Unreachable"

ICMPv6 response was ICMPv6_UNREACHABLE

=item "ICMPv6 Timeout"

ICMPv6 response was ICMPv6_TIME_EXCEEDED

=item "Receive error"

An error was received from L<IO::Async::Socket>.

=back

=head1 NAME

Net::Async::Ping::ICMPv6

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Net::Async::Ping::ICMP;
$Net::Async::Ping::ICMP::VERSION = '0.004001';
use Moo;
use warnings NONFATAL => 'all';

use Future;
use Time::HiRes;
use Carp qw( croak );
use Net::Ping qw();
use IO::Socket;
use IO::Async::Socket;
use Scalar::Util qw/blessed/;
use Socket qw(
    SOCK_RAW SOCK_DGRAM AF_INET IPPROTO_ICMP NI_NUMERICHOST NIx_NOSERV
    inet_aton pack_sockaddr_in unpack_sockaddr_in getnameinfo inet_ntop
);
use Net::Frame::Layer::IPv4 qw(:consts);

use constant ICMP_ECHOREPLY   => 0; # ICMP packet types
use constant ICMP_UNREACHABLE => 3; # ICMP packet types
use constant ICMP_ECHO        => 8;
use constant ICMP_TIME_EXCEEDED => 11; # ICMP packet types
use constant ICMP_STRUCT      => "C2 n3 A"; # Structure of a minimal ICMP packet
use constant SUBCODE          => 0; # No ICMP subcode for ECHO and ECHOREPLY
use constant ICMP_FLAGS       => 0; # No special flags for send or recv

extends 'IO::Async::Notifier';

use namespace::clean;

has default_timeout => (
   is => 'ro',
   default => 5,
);

has bind => ( is => 'rw' );

has _is_raw_socket_setup_done => (
    is => 'rw',
    default => 0,
);

has _raw_socket => (
    is => 'lazy',
);

sub _build__raw_socket {
    my $self = shift;

    my $fh = IO::Socket->new;
    $fh->socket(AF_INET, SOCK_RAW, IPPROTO_ICMP) ||
        croak("Unable to create raw socket ($!). Are you running as root?"
            ." If not, and your system supports ping sockets, try setting"
            ." /proc/sys/net/ipv4/ping_group_range");

    if ($self->bind) {
        $fh->bind(pack_sockaddr_in 0, inet_aton $self->bind)
            or croak "Failed to bind to ".$self->bind;
    }

    my $on_recv = $self->_capture_weakself(sub {
        my $self = shift or return; # weakref, may have disappeared
        my ( undef, $recv_msg, $from_saddr ) = @_;

        my $from_data = $self->_parse_icmp_packet($recv_msg, $from_saddr, 20);
        return
            unless defined $from_data && ref $from_data eq 'HASH';

        # ignore received packets which are not a response to one of
        # our echo requests
        my $f = $self->_raw_socket_queue->{$from_data->{ip}};
        return
            unless defined $f
                && $from_data->{id} == $self->_pid
                && $from_data->{seq} == $self->seq;

        if ($from_data->{type} == ICMP_ECHOREPLY) {
            $f->done;
        }
        elsif ($from_data->{type} == ICMP_UNREACHABLE) {
            $f->fail('ICMP Unreachable');
        }
        elsif ($from_data->{type} == ICMP_TIME_EXCEEDED) {
            $f->fail('ICMP Timeout');
        }
    });

    my $socket = IO::Async::Socket->new(
        handle => $fh,
        on_send_error => sub {
            my ( $self, $errno ) = @_;
            warn "Send error: $errno\n";
        },
        on_recv_error => sub {
            my ( $self, $errno ) = @_;
            warn "Receive error: $errno\n";
        },
        on_recv => $on_recv,
    );

    return $socket;
}

has _raw_socket_queue => (
    is => 'rw',
    default => sub { {} },
);

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

sub _parse_icmp_packet {
    my ( $self, $recv_msg, $from_saddr, $offset ) = @_;
    $offset = 0
        unless defined $offset;

    my $from_ip  = -1;
    my $from_pid = -1;
    my $from_seq = -1;

    # ping sockets only return the ICMP packet
    # raw sockets return the IPv4 packet containing the ICMP
    # packet
    my ($from_type, $from_subcode) =
        unpack("C2", substr($recv_msg, $offset, 2));

    # extract source ip, identifier and sequence depending on
    # packet type
    if ($from_type == ICMP_ECHOREPLY) {
        (my $err, $from_ip) = getnameinfo($from_saddr,
            NI_NUMERICHOST, NIx_NOSERV);
        croak "getnameinfo: $err"
            if $err;
        ($from_pid, $from_seq) =
            unpack("n2", substr($recv_msg, $offset + 4, 4))
            if length $recv_msg >= $offset + 8;
    }
    # an ICMPv4 error message includes the original header
    # IPv4 + ICMPv4 + ICMPv4::Echo
    elsif ($from_type == ICMP_UNREACHABLE) {
        my $ipv4 = Net::Frame::Layer::IPv4->new(
            # 8 byte is the length of the ICMP Destination
            # unreachable header
            raw => substr($recv_msg, $offset + 8)
        )->unpack;
        # skip if contained packet isn't an icmp packet
        return
            if $ipv4->protocol != NF_IPv4_PROTOCOL_ICMPv4;

        # skip if contained packet isn't an icmp echo request packet
        my ($to_type, $to_subcode) =
            unpack("C2", substr($ipv4->payload, 0, 2));
        return
            if $to_type != ICMP_ECHO;

        $from_ip = $ipv4->dst;
        ($from_pid, $from_seq) =
            unpack("n2", substr($ipv4->payload, 4, 4));
    }
    # no packet we care about, raw sockets receive broadcasts,
    # multicasts etc, ours is only limited to IPv4 containing ICMP
    else {
        return;
    }

    return {
        type => $from_type,
        ip => $from_ip,
        id => $from_pid,
        seq => $from_seq,
    };
}

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

    $loop->resolver->getaddrinfo(
       host     => $host,
       protocol => IPPROTO_ICMP,
       family   => AF_INET,
    )->then( sub {
        my $saddr  = $_[0]->{addr};
        my ($err, $dst_ip) = getnameinfo($saddr, NI_NUMERICHOST, NIx_NOSERV);
        croak "getnameinfo: $err"
            if $err;
        my $f = $loop->new_future;

        # Let's try a ping socket (unprivileged ping) first. See
        # https://lwn.net/Articles/422330/
        my ($socket, $ping_socket, $ident);
        if ($self->use_ping_socket) {
            my $ping_fh = IO::Socket->new;
            if ($ping_fh->socket(AF_INET, SOCK_DGRAM, IPPROTO_ICMP)) {
                ($ident) = unpack_sockaddr_in getsockname($ping_fh);

                if ($self->bind) {
                    $ping_fh->bind(pack_sockaddr_in 0, inet_aton $self->bind)
                        or croak "Failed to bind to ".$self->bind;
                }

                my $on_recv = $self->_capture_weakself(
                    sub {
                        my $self = shift or return; # weakref, may have disappeared
                        my ( undef, $recv_msg, $from_saddr ) = @_;

                        my $from_data = $self->_parse_icmp_packet($recv_msg,
                            $from_saddr);

                        # ignore received packets which are not a response to one of
                        # our echo requests
                        return
                            unless $from_data->{ip} eq $dst_ip
                                && $from_data->{seq} == $self->seq;

                        if ($from_data->{type} == ICMP_ECHOREPLY) {
                            $f->done;
                        }
                        elsif ($from_data->{type} == ICMP_UNREACHABLE) {
                            $f->fail('ICMP Unreachable');
                        }
                        elsif ($from_data->{type} == ICMP_TIME_EXCEEDED) {
                            $f->fail('ICMP Timeout');
                        }
                    },
                );

                $socket = IO::Async::Socket->new(
                    handle => $ping_fh,
                    on_send_error => sub {
                        my ( $self, $errno ) = @_;
                        $f->fail("Send error: $errno");
                    },
                    on_recv_error => sub {
                        my ( $self, $errno ) = @_;
                        $f->fail("Receive error: $errno");
                    },
                    on_recv => $on_recv,
                );
                $legacy ? $loop->add($socket) : $self->add_child($socket);
                $ping_socket = 1;
            }
        }

        # fallback to raw socket or if no ping socket was requested
        if (not defined $socket) {
            $socket = $self->_raw_socket;
            $ident = $self->_pid;
            if (!$self->_is_raw_socket_setup_done) {
                $legacy ? $loop->add($socket) : $self->add_child($socket);
                $self->_is_raw_socket_setup_done(1);
            }
        }

        # remember raw socket requests
        if (!$ping_socket) {
            if (exists $self->_raw_socket_queue->{$dst_ip}) {
                warn "$dst_ip already in raw queue, $host probably duplicate\n";
            }
            $self->_raw_socket_queue->{$dst_ip} = $f;
        }
        $socket->send( $self->_msg($ident), ICMP_FLAGS, $saddr );

        Future->wait_any(
           $f,
           $loop->timeout_future(after => $timeout)
        )
        ->then( sub {
            Future->done(Time::HiRes::tv_interval($t0));
        })
        ->followed_by( sub {
            my $f = shift;

            if ($ping_socket) {
                $socket->remove_from_parent;
            }
            else {
                # remove from raw socket queue
                delete $self->_raw_socket_queue->{$dst_ip};
            }

            return $f;
        })
    });
}

sub _msg {
    my ($self, $ident) = @_;

    # data_size to be implemented later
    my $data_size = 0;
    my $data      = '';
    my $checksum  = 0;
    my $msg = pack(ICMP_STRUCT . $data_size, ICMP_ECHO, SUBCODE,
        $checksum, $ident, $self->seq, $data);
    $checksum = Net::Ping->checksum($msg);
    $msg = pack(ICMP_STRUCT . $data_size, ICMP_ECHO, SUBCODE,
        $checksum, $ident, $self->seq, $data);
    return $msg;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Ping::ICMP

=head1 VERSION

version 0.004001

=head1 DESCRIPTION

This is the ICMP part of L<Net::Async::Ping>. See that documentation for full
details.

=head2 ICMP methods

This module will first attempt to use a ping socket to send its ICMP packets,
which does not need root privileges. These are only supported on Linux, and
only when the group is stipulated in C</proc/sys/net/ipv4/ping_group_range>.
Failing that, the module will use a raw socket limited to the ICMP protocol,
which will fail if attempted from a non-privileged account.

=head3 ping socket advantages

=over

=item doesn't require root/admin privileges

=item better performance, as the kernel is handling the reply to request
packet matching

=back

=head3 raw socket advantages

=over

=item supports echo replies, no icmp error messages

=back

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

package Net::Async::Ping::ICMP;
$Net::Async::Ping::ICMP::VERSION = '0.001001';
use Moo;
use warnings NONFATAL => 'all';

use Future;
use POSIX 'ECONNREFUSED';
use Time::HiRes;
use Carp;
use Net::Ping;
use IO::Async::Socket;

use Socket qw( SOCK_RAW SOCK_DGRAM AF_INET NI_NUMERICHOST inet_aton pack_sockaddr_in unpack_sockaddr_in getnameinfo inet_ntop);

use constant ICMP_ECHOREPLY   => 0; # ICMP packet types
use constant ICMP_UNREACHABLE => 3; # ICMP packet types
use constant ICMP_ECHO        => 8;
use constant ICMP_TIME_EXCEEDED => 11; # ICMP packet types
use constant ICMP_PARAMETER_PROBLEM => 12; # ICMP packet types
use constant ICMP_STRUCT      => "C2 n3 A"; # Structure of a minimal ICMP packet
use constant SUBCODE          => 0; # No ICMP subcode for ECHO and ECHOREPLY
use constant ICMP_FLAGS       => 0; # No special flags for send or recv
use constant ICMP_PORT        => 0; # No port with ICMP

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
    my $legacy = ref $_[0] eq 'IO::Async::Loop::Poll';
    my $loop   = $legacy ? shift : $self->loop;

    my ($host, $timeout) = @_;
    $timeout //= $self->default_timeout;

    my $t0 = [Time::HiRes::gettimeofday];

    my $fh = IO::Socket->new;
    my $proto_num = (getprotobyname('icmp'))[2] ||
        croak("Can't get icmp protocol by name");
    # Let's try a ping socket (unprivileged ping) first. See
    # https://lwn.net/Articles/422330/
    my ($ping_socket, $ident);
    if ($self->use_ping_socket && socket($fh, AF_INET, SOCK_DGRAM, $proto_num))
    {
        $ping_socket = 1;
        ($ident) = unpack_sockaddr_in getsockname($fh);
    }
    else {
        socket($fh, AF_INET, SOCK_RAW, $proto_num) ||
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
       protocol => $proto_num,
       family   => AF_INET,
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
                my ($from_port, $from_ip) = unpack_sockaddr_in($from_saddr);
                my $offset = $ping_socket ? 0 : 20; # No offset needed for ping sockets
                my ($from_type, $from_subcode) = unpack("C2", substr($recv_msg, $offset, 2));

                if ($from_type == ICMP_ECHOREPLY) {
                    ($from_pid, $from_seq) = unpack("n3", substr($recv_msg, $offset + 4, 4))
                        if length $recv_msg >= $offset + 8;
                } else {
                    ($from_pid, $from_seq) = unpack("n3", substr($recv_msg, $offset + 32, 4))
                        if length $recv_msg >= $offset + 36;
                }

                # Not needed for ping socket - kernel handles this for us
                return if !$ping_socket && $from_pid != $ping->_pid;
                return if $from_seq != $ping->seq;
                if ($from_type == ICMP_ECHOREPLY) {
                    my $ip = unpack_sockaddr_in($saddr);
                    return if inet_ntop(AF_INET, $from_ip) ne inet_ntop(AF_INET, $ip); # Does the packet check out?
                    $f->done;
                } elsif ($from_type == ICMP_UNREACHABLE) {
                    $f->fail('ICMP Unreachable');
                } elsif ($from_type == ICMP_TIME_EXCEEDED) {
                    $f->fail('ICMP Timeout');
                }
                $legacy ? $loop->remove($socket) : $ping->remove_child($socket);
            },
        );

        $socket->configure(on_recv => $on_recv);
        $legacy ? $loop->add($socket) : $self->add_child($socket);
        $socket->send( $self->_msg($ident), ICMP_FLAGS, $saddr );

        Future->wait_any(
           $f,
           $loop->timeout_future(after => $timeout)
        )
        ->then(
            sub { Future->done(Time::HiRes::tv_interval($t0)) }
        )
    });
}

sub _msg
{   my ($self, $ident) = @_;
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

version 0.002000

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

=head1 VERSION

version 0.001001

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

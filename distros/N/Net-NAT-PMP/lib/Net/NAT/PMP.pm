#  Copyright (c) 2009 David Caldwell,  All Rights Reserved. -*- cperl -*-

use strict;
use warnings;

package Net::NAT::PMP;
our $VERSION = '0.9.4';

use IO::Socket::INET;
sub Port { 5351 }
sub Version { 0 } # protocol version we support

sub socket    { $_[0]->{socket} }
sub router_ip { $_[0]->{router_ip} }

sub error {
    my ($self, $message)  = @_;
    return $self->{error} unless defined $message;
    $self->{error} = $message;
    undef
}

sub get_router_address {
    my $gateway;
    if      ($^O eq 'darwin') {
        # Would be much better to use the sysctl interface here, natively.
        open NETSTAT, '-|', 'netstat', '-rlnf', 'inet' or die "Couldn't run netstat: $!";
        while (<NETSTAT>) {
            $gateway = $1 if /^default\s+(\d+\.\d+\.\d+\.\d+)/;
        }
        close NETSTAT;
    } elsif ($^O eq 'linux') {
        open ROUTE, '<', '/proc/net/route' or die "Couldn't open /proc/net/route: $!";
        while (<ROUTE>) {
            $gateway = $1 if /^\S+\s+00000000\s+([0-9A-F]+)/;
        }
        close ROUTE;
        # Stupid linux prints it as a hex number in network byte order. The following should work on both
        # big and little endian machines. I don't have any big endian's on hand to test though.
        $gateway = join(".", unpack "CCCC", pack "L", hex $gateway) if $gateway;
    } else { die "Automatically discovering the gateway address is not supported on $^O yet! Please pass the address of your router to Net:NAT::PMP::new()" }
    $gateway;
}

sub new {
    my ($class, $router_ip) = @_;
    $router_ip ||= get_router_address();
    my $self = bless {
        router_ip => $router_ip,
        socket => IO::Socket::INET->new(PeerAddr => $router_ip, PeerPort => Net::NAT::PMP::Port, Proto=>'udp'),#, Timeout => .25),
    }, $class;
    $self->{socket} ? $self : undef;
}

sub external_address {
    my ($self) = @_;
    my $op = 0;
    return $self->error("send: $!") unless defined $self->socket->send(pack("CC", Version, $op));
    my $packet;
    return $self->error("recv: $!") unless defined $self->socket->recv($packet, 12);
    my (%response, @external_address);
    (@response{qw(vers op result_code time)}, @external_address) = unpack("CCnNCCCC", $packet);
    return $self->error("Got unexpected op $response{op} instead of @{[128 + $op]}") unless $response{op} == 128 + $op;
    return $self->error("Got unexpected result_code $response{result_code} instead of 0") unless $response{result_code} == 0;
    my $dotted = join('.', @external_address);
    return $dotted;
}

sub create_mapping {
    my ($self, $internal_port, $external_port, $lifetime_seconds, $udp) = @_;
    $external_port = $internal_port unless defined $external_port; # wheres my //= !!!
    $lifetime_seconds = 3600 unless defined $lifetime_seconds;
    my $op = $udp ? 1 : 2;
    return $self->error("send: $!") unless defined $self->socket->send(pack ("CCnnnN", Version, $op, 0, $internal_port, $external_port, $lifetime_seconds));
    my $packet;
    return $self->error("recv: $!") unless defined $self->socket->recv($packet, 16);
    my %response;
    @response{qw(vers op result_code time internal_port external_port lifetime_seconds)} = unpack "CCnNnnN", $packet;
    return $self->error("Got unexpected op $response{op} instead of @{[128 + $op]}") unless $response{op} == 128 + $op;
    return $self->error("Got unexpected result_code $response{result_code} instead of 0") unless $response{result_code} == 0;
    return $external_port;
}

sub destroy_mapping {
    my ($self, $internal_port, $udp) = @_;
    $self->create_mapping($internal_port, 0, 0, $udp);
}

1;

__END__

=head1 NAME

Net::NAT::PMP - Poke holes in a router's NAT using the NAT-PMP protocol

=head1 SYNOPSIS

 use Net::NAT::PMP;
 $nat_pmp = new Net::NAT::PMP or die "Net::NAT::PMP: $!";
 $external_address = $nat_pmp->external_address;
 die $nat_pmp->error unless defined $external_address;
 $external_port = $nat_pmp->create_mapping(40000);
 die $nat_pmp->error unless defined $external_port;

=head1 DESCRIPTION

Net::NAT::PMP is a client for the NAT Port Mapping Protocol (NAT-PMP),
which is currently an RFC draft. NAT-PMP is designed so that you can
have rich network applications that can still work even behind your
home router's NAT.

=head1 FUNCTIONS

=over 4

=item B<C<new($router_address)>>

Creates a new Net::NAT::PMP object and tries to discover the address
of the gateway (router). This currently only works on Mac OS X 10.5
and Linux. Other platforms must pass the $router_address parameter to
new().

=item B<C<external_address()>>

This queries the router for its external address. On success it returns the
address as a string in dotted quad format. On failure it returns undef (call
the error() method for details).

=item B<C<create_mapping($internal_port, $external_port, $lifetime_seconds, $udp)>>

This asks the router to open a up an external port and map it to
$internal_port. The mapping will last for $lifetime_seconds. According
to the RFC draft, the mapping should be re-requested when half the
lifetime has elapsed. Net::NAT::PMP does not do this for you.

If $external_port is zero then the router will pick a port for you.

If $external_port is undef then Net::NAT::PMP will request that the
external port be the same as the internal port.

If $lifetime_seconds is undef then the default of 3600 (one hour) is
assumed.

If $lifetime_seconds and $external_port are both 0 then the mapping is
destroyed instead of created. It's probably clearer to use the
destroy_mapping() member function in this case.

If $udp is true then the mapping will be for UDP connection. If false
then it will be for TCP connections.

create_mapping() will return the external port number. You shouldn't
assume this will be the same as the port you requested. The router is
free to choose a different port number if it doesn't like the
requested port number for whatever reason.

On error, create_mapping() will return undef. When this happens you can
check the error() method for details.

=item B<C<destroy_mapping($internal_port, $udp)>>

This will destroy a mapping.

=item B<C<error()>>

This will return a string with details about the last error that occurred.

=back

=head1 BUGS

This barely implements the protocol. Specifically no attempt is made
to retry or time out network transactions. This means that if you try
to talk to the wrong IP address or your router doesn't support
NAT-PMP, the external_address() and create_mapping() functions will
hang. Yeah, that's weak. Patches are welcome.

This protocol relies on being able to get the IP address of the
router. There appears to be no standard POSIX way to do this, so the
code has to support each OS separately. Currently only Mac OS X and
Linux are supported. Linux should be fairly stable since it is
implemented by reading /proc/net/route which is what the route program
itself does. The Mac OS X version, however, scrapes data from netstat
which seems really fragile. It seems the way to do it natively
involves interfacing with sysctl(). Again, patches are welcome.

=head1 SEE ALSO

L<http://tools.ietf.org/html/draft-cheshire-nat-pmp-03>

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Copyright (C) 2009 David Caldwell

=head1 AUTHOR

David Caldwell <david@porkrind.org>

=cut

package Net::QUIC::Datagram;

use strict;
use warnings;

use Net::QUIC ();

our $VERSION = '0.04';

sub _new {
    my ($class, $data, $local, $peer, $ecn) = @_;
    $ecn = 0 if !defined $ecn;
    return bless [$data, $local, $peer, $ecn], $class;
}

sub data  { $_[0]->[0] }
sub local { $_[0]->[1] }
sub peer  { $_[0]->[2] }
sub ecn   { $_[0]->[3] }

1;

__END__

=head1 NAME

Net::QUIC::Datagram - one UDP packet Net::QUIC wants sent

=head1 DESCRIPTION

A Datagram is an adapter object.

It is not an application message and it is not a QUIC Stream.

L<Net::QUIC::Driver> passes Datagram objects to its C<send> callback when QUIC
has UDP output ready.

Each Datagram contains:

    the complete UDP payload
    the local source address
    the peer destination address
    the ECN codepoint for the IP header

Send C<data> as one UDP datagram. Do not split it or combine it with another
Datagram.

=head1 METHODS

=head2 data

    my $bytes = $datagram->data;

Returns the complete UDP payload bytes.

=head2 local

    my $local = $datagram->local;

Returns the packed local source address QUIC expects for this packet.

For a UDP socket bound to one concrete local address, the socket normally uses
that address automatically.

For a wildcard-bound socket or a connection using more than one local path, the
adapter may need a platform-specific source-address mechanism.

=head2 peer

    my $peer = $datagram->peer;

Returns the packed destination socket address.

=head2 ecn

    my $ecn = $datagram->ecn;

Returns the two ECN bits the adapter should place in the outgoing IP header:

    0   Not-ECT
    1   ECT(1)
    2   ECT(0)
    3   CE

An adapter that does not support ECN can ignore this value. QUIC will detect
that ECN is not usable on that path and stop relying on it.

=head1 SEE ALSO

L<Net::QUIC>

L<Net::QUIC::Driver>

L<Net::QUIC::Endpoint>

=cut

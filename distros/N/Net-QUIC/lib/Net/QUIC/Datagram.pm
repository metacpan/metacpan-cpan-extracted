package Net::QUIC::Datagram;

use strict;
use warnings;

use Net::QUIC ();

our $VERSION = '0.01';

sub _new {
    my ($class, $data, $local, $peer) = @_;
    return bless [$data, $local, $peer], $class;
}

sub data  { $_[0]->[0] }
sub local { $_[0]->[1] }
sub peer  { $_[0]->[2] }

1;

__END__

=head1 NAME

Net::QUIC::Datagram - UDP datagram produced by Net::QUIC

=head1 DESCRIPTION

A Net::QUIC::Datagram contains one complete UDP payload and the network path
chosen by QUIC.

L<Net::QUIC::Driver> passes these objects to its C<send> callback.

Low-level L<Net::QUIC::Endpoint> users receive them from C<next_datagram>.

=head1 METHODS

=head2 data

Returns the UDP payload bytes.

=head2 local

Returns the packed concrete local source address for the datagram.

An adapter using a socket bound to one concrete address normally gets this
source address automatically from the socket.

An adapter using a wildcard-bound socket must preserve this source address when
transmitting the packet, using the platform's source-address selection
mechanism.

=head2 peer

Returns the packed peer socket address for the datagram.

=cut

package Net::WAMP::RawSocket::Check;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::WAMP::RawSocket::Check

=head1 SYNOPSIS

    my $is_rawsocket = Net::WAMP::RawSocket::Check::is_rawsocket($fh);

=head1 DESCRIPTION

Use C<is_rawsocket()> to determine if the client is connecting via
WAMP RawSocket. You can use this logic to serve both RawSocket and WebSocket
connections on the same TCP port.

=cut

use Socket ();

use Net::WAMP::RawSocket::Constants ();

sub is_rawsocket {
    my ($socket) = @_;

    local $!;

    my $buf;

    my $ok = recv( $socket, $buf, 1, Socket::MSG_PEEK() );
    if (!defined $ok) {
        die "recv() error: $!" if $!; #XXX
        die "Empty recv()!";
    };

    return ord($buf) == Net::WAMP::RawSocket::Constants::MAGIC_FIRST_OCTET();
}

1;

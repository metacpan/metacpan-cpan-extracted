#!/usr/bin/false
# ABSTRACT: Relay-Forward message (type 12)
# PODNAME: Net::DHCPv6::Message::RelayForw
package Net::DHCPv6::Message::RelayForw;
$Net::DHCPv6::Message::RelayForw::VERSION = '0.001';
use strictures 2;
use Net::DHCPv6::Constants;
use parent 'Net::DHCPv6::Packet::Relay';
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    $args{msg_type} = $RELAY_FORW;
    $class->SUPER::new( %args );
}

$Net::DHCPv6::Packet::MESSAGE_CLASS{$RELAY_FORW} = __PACKAGE__;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Net::DHCPv6::Message::RelayForw - Relay-Forward message (type 12)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Net::DHCPv6;

    my ($msg, $err) = Net::DHCPv6->decode_with_error($bytes);
    my $inner = $msg->message;  # decoded inner message

=head1 DESCRIPTION

DHCPv6 Relay-Forward message (type 12). Relays a client message
toward a server. Wire format: hop_count(1) + link_address(16) +
peer_address(16) + options. See L<Net::DHCPv6::Packet::Relay>
for available methods.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=for Pod::Coverage new

=head1 SEE ALSO

L<Net::DHCPv6::Packet::Relay>, L<Net::DHCPv6::Message::RelayReply>,
RFC 8415 §14, §20

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut

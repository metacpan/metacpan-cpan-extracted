#!/usr/bin/false
# ABSTRACT: Relay-Reply message (type 13)
# PODNAME: Net::DHCPv6::Message::RelayReply
package Net::DHCPv6::Message::RelayReply;
$Net::DHCPv6::Message::RelayReply::VERSION = '0.001';
use strictures 2;
use Net::DHCPv6::Constants;
use parent 'Net::DHCPv6::Packet::Relay';
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    $args{msg_type} = $RELAY_REPLY;
    $class->SUPER::new( %args );
}

$Net::DHCPv6::Packet::MESSAGE_CLASS{$RELAY_REPLY} = __PACKAGE__;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Net::DHCPv6::Message::RelayReply - Relay-Reply message (type 13)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Net::DHCPv6;

    my ($msg, $err) = Net::DHCPv6->decode_with_error($bytes);
    my $inner = $msg->message;  # decoded inner message

=head1 DESCRIPTION

DHCPv6 Relay-Reply message (type 13). A server sends Relay-Reply
to deliver a response to a relay agent. Wire format: hop_count(1)
+ link_address(16) + peer_address(16) + options. See
L<Net::DHCPv6::Packet::Relay> for available methods.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=for Pod::Coverage new

=head1 SEE ALSO

L<Net::DHCPv6::Packet::Relay>, L<Net::DHCPv6::Message::RelayForw>,
RFC 8415 §14, §20

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut

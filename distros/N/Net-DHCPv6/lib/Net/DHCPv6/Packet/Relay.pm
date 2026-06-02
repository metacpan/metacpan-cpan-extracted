#!/bin/false
# ABSTRACT: Base class for DHCPv6 relay messages (RelayForw/RelayReply)
# PODNAME: Net::DHCPv6::Packet::Relay
use strictures 2;

package Net::DHCPv6::Packet::Relay;
$Net::DHCPv6::Packet::Relay::VERSION = '0.002';
use Net::DHCPv6::Constants qw( $IPV6_ADDR_LEN );
use Net::DHCPv6::Packet;
use Carp qw( croak );
use Net::DHCPv6::OptionList;
use Net::DHCPv6::X::BadMessage;
use parent 'Net::DHCPv6::Helpers', 'Net::DHCPv6::Packet';
use namespace::clean;

my $RELAY_HDR_SIZE   = 34;    ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
my $LINK_ADDR_OFFSET = 2;

sub new {
    my ( $class, %args ) = @_;
    croak 'Relay->new: hop_count is required' unless defined $args{hop_count};
    my $link_addr = $class->_pick_addr( \%args, 'link_address' );
    croak 'Relay->new: link_address is required'      unless defined $link_addr;
    croak 'Relay->new: link_address must be 16 bytes' unless CORE::length( $link_addr ) == $IPV6_ADDR_LEN;
    my $peer_addr = $class->_pick_addr( \%args, 'peer_address' );
    croak 'Relay->new: peer_address is required'      unless defined $peer_addr;
    croak 'Relay->new: peer_address must be 16 bytes' unless CORE::length( $peer_addr ) == $IPV6_ADDR_LEN;

    $args{options} = $args{options} // Net::DHCPv6::OptionList->new;

    return bless {
        msg_type     => $args{msg_type},
        hop_count    => $args{hop_count},
        link_address => $link_addr,
        peer_address => $peer_addr,
        options      => $args{options},
    }, $class;
}

sub hop_count { return shift->{hop_count} }

sub link_address {
    my $self = shift;
    return $self->_format_ipv6( $self->{link_address} );
}
sub link_address_raw { return shift->{link_address} }

sub peer_address {
    my $self = shift;
    return $self->_format_ipv6( $self->{peer_address} );
}
sub peer_address_raw { return shift->{peer_address} }

sub from_bytes {
    my ( $class, $bytes ) = @_;
    Net::DHCPv6::X::BadMessage->throw( message => 'Empty relay data' )
        if !defined $bytes || CORE::length( $bytes ) < $RELAY_HDR_SIZE;

    my $msg_type   = unpack( 'C', substr( $bytes, 0, 1 ) );
    my $hop_count  = unpack( 'C', substr( $bytes, 1, 1 ) );
    my $link_addr  = substr( $bytes, $LINK_ADDR_OFFSET,                  $IPV6_ADDR_LEN );
    my $peer_addr  = substr( $bytes, $LINK_ADDR_OFFSET + $IPV6_ADDR_LEN, $IPV6_ADDR_LEN );
    my $opts_bytes = substr( $bytes, $RELAY_HDR_SIZE );
    my $opts       = Net::DHCPv6::OptionList->from_bytes( $opts_bytes );

    my $subclass = $Net::DHCPv6::Packet::MESSAGE_CLASS{$msg_type} || $class;
    return bless {
        msg_type     => $msg_type,
        hop_count    => $hop_count,
        link_address => $link_addr,
        peer_address => $peer_addr,
        options      => $opts,
    }, $subclass;
}

sub as_bytes {
    my $self = shift;
    return
        pack( 'C C a16 a16', $self->{msg_type}, $self->{hop_count}, $self->{link_address}, $self->{peer_address} )
        . $self->{options}->as_bytes;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::Packet::Relay - Base class for DHCPv6 relay messages (RelayForw/RelayReply)

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  # Text form (auto-resolved to wire bytes)
  my $relay = Net::DHCPv6::Packet::Relay->new(
      msg_type     => $RELAY_FORW,
      hop_count    => 0,
      link_address => '2001:db8::1',
      peer_address => '2001:db8::2',
  );
  print $relay->hop_count;        # 0
  print $relay->link_address;     # '2001:db8::1'
  print $relay->link_address_raw; # 16 bytes
  print $relay->peer_address;     # '2001:db8::2'

  # Raw bytes
  use Socket qw(inet_pton AF_INET6);
  my $relay2 = Net::DHCPv6::Packet::Relay->new(
      msg_type          => $RELAY_FORW,
      hop_count         => 0,
      link_address_raw  => inet_pton( AF_INET6, '2001:db8::1' ),
      peer_address_raw  => inet_pton( AF_INET6, '2001:db8::2' ),
  );

=head1 DESCRIPTION

Base class for RELAY-FORW and RELAY-REPLY messages (RFC 8415 E<167>14),
which have a different wire format than standard DHCPv6 messages:
a 1-byte hop count, 16-byte link address, 16-byte peer address,
then options. No transaction_id field.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 CONSTRUCTORS

=over

=item B<new>(%args)

Constructs a relay message. Required: C<hop_count>, and either
C<link_address> (IPv6 text) or C<link_address_raw> (16 raw bytes), and
either C<peer_address> or C<peer_address_raw>. Optional: C<options>
(OptionList).

=item B<from_bytes>($bytes)

Class method. Parses relay wire format: msg_type(1) + hop_count(1)
+ link_address(16) + peer_address(16) + options.

=back

=head1 METHODS

=over

=item B<hop_count>

=item B<link_address>

Returns the link address as a text string.

=item B<link_address_raw>

Returns the link address as 16 raw bytes.

=item B<peer_address>

Returns the peer address as a text string.

=item B<peer_address_raw>

Returns the peer address as 16 raw bytes.

=item B<as_bytes>

Serializes to wire format.

=back

=head1 ACCESSORS (inherited)

=over

=item B<msg_type>

=item B<type>

=item B<options>

=item B<add_option>($option)

=item B<get_option>($code)

=back

=head1 SEE ALSO

L<Net::DHCPv6::Packet>, L<Net::DHCPv6::Message::RelayForw>,
L<Net::DHCPv6::Message::RelayReply>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut

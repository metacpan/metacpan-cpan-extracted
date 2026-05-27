#!/usr/bin/false
# ABSTRACT: Base class for DHCPv6 relay messages (RelayForw/RelayReply)
# PODNAME: Net::DHCPv6::Packet::Relay
package Net::DHCPv6::Packet::Relay;
$Net::DHCPv6::Packet::Relay::VERSION = '0.001';
use strictures 2;
use Carp qw(croak);
use Net::DHCPv6::OptionList;
use Net::DHCPv6::X::BadMessage;
use parent 'Net::DHCPv6::Packet';
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    croak 'Relay->new: hop_count is required'         unless defined $args{hop_count};
    croak 'Relay->new: link_address is required'      unless defined $args{link_address};
    croak 'Relay->new: peer_address is required'      unless defined $args{peer_address};
    croak 'Relay->new: link_address must be 16 bytes' unless CORE::length( $args{link_address} ) == 16;
    croak 'Relay->new: peer_address must be 16 bytes' unless CORE::length( $args{peer_address} ) == 16;

    $args{options} = $args{options} // Net::DHCPv6::OptionList->new;

    return bless {
        msg_type     => $args{msg_type},
        hop_count    => $args{hop_count},
        link_address => $args{link_address},
        peer_address => $args{peer_address},
        options      => $args{options},
    }, $class;
}

sub hop_count    { shift->{hop_count} }
sub link_address { shift->{link_address} }
sub peer_address { shift->{peer_address} }

sub from_bytes {
    my ( $class, $bytes ) = @_;
    Net::DHCPv6::X::BadMessage->throw( message => 'Empty relay data' )
        unless defined $bytes && CORE::length( $bytes ) >= 34;

    my $msg_type   = unpack( 'C', substr( $bytes, 0, 1 ) );
    my $hop_count  = unpack( 'C', substr( $bytes, 1, 1 ) );
    my $link_addr  = substr( $bytes, 2,  16 );
    my $peer_addr  = substr( $bytes, 18, 16 );
    my $opts_bytes = substr( $bytes, 34 );
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

=encoding utf-8

=head1 NAME

Net::DHCPv6::Packet::Relay - Base class for DHCPv6 relay messages (RelayForw/RelayReply)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  my $relay = Net::DHCPv6::Packet::Relay->new(
      msg_type     => $RELAY_FORW,
      hop_count    => 0,
      link_address => "\xfe\x80" . "\x00" x 14,
      peer_address => "\xfe\x80" . "\x00" x 14,
  );
  print $relay->hop_count;     # 0
  print $relay->link_address;  # 16 bytes
  print $relay->peer_address;  # 16 bytes

=head1 DESCRIPTION

Base class for RELAY-FORW and RELAY-REPLY messages (RFC 8415 §14),
which have a different wire format than standard DHCPv6 messages:
a 1-byte hop count, 16-byte link address, 16-byte peer address,
then options. No transaction_id field.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 CONSTRUCTORS

=over

=item B<new>(%args)

Constructs a relay message. Required: C<hop_count>, C<link_address>,
C<peer_address>. Optional: C<options> (OptionList).

=item B<from_bytes>($bytes)

Class method. Parses relay wire format: msg_type(1) + hop_count(1)
+ link_address(16) + peer_address(16) + options.

=back

=head1 METHODS

=over

=item B<hop_count>

=item B<link_address>

=item B<peer_address>

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

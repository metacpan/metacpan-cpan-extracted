#!/bin/false
# ABSTRACT: DHCPv6 packet base class
# PODNAME: Net::DHCPv6::Packet
use strictures 2;

package Net::DHCPv6::Packet;
$Net::DHCPv6::Packet::VERSION = '0.003';
use Carp                   qw( croak );
use Net::DHCPv6::Constants qw(
    $RELAY_FORW $RELAY_REPLY
);
use Net::DHCPv6::OptionList    ();
use Net::DHCPv6::Packet::Relay ();
use Net::DHCPv6::X::BadMessage ();
use namespace::clean;

my $TX_ID_MAX   = 0xFFFFFF;    ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
my $TX_ID_BYTES = 3;           ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
my $HDR_SIZE    = 4;           ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)

sub new {
    my ( $class, @argv ) = @_;
    if ( @argv == 1 ) {
        return $class->from_bytes( $argv[0] );
    }
    croak 'Packet->new: no arguments' unless @argv;
    my %args = @argv;
    croak 'Packet->new: msg_type is required'       unless defined $args{msg_type};
    croak 'Packet->new: transaction_id is required' unless defined $args{transaction_id};
    croak 'transaction_id must fit in 24 bits'
        if $args{transaction_id} < 0 || $args{transaction_id} > $TX_ID_MAX;
    $args{options} = $args{options} // Net::DHCPv6::OptionList->new;
    my $self = {
        msg_type       => $args{msg_type},
        transaction_id => $args{transaction_id},
        options        => $args{options},
    };
    return bless $self, $class;
}

sub msg_type       { return shift->{msg_type} }
sub transaction_id { return shift->{transaction_id} }
sub options        { return shift->{options} }

sub add_option {
    my ( $self, $option ) = @_;
    return $self->{options}->add_option( $option );
}

sub get_option {
    my ( $self, $code ) = @_;
    return $self->{options}->get_option( $code );
}

sub as_bytes {
    my $self = shift;
    my $tid  = substr( pack( 'N', $self->{transaction_id} ), 1, $TX_ID_BYTES );
    my $opts = $self->{options}->as_bytes;
    return pack( 'C', $self->{msg_type} ) . $tid . $opts;
}

sub from_bytes {
    my ( $class, $bytes ) = @_;
    Net::DHCPv6::X::BadMessage->throw( message => 'Empty packet data' )
        if !defined $bytes || CORE::length( $bytes ) < $HDR_SIZE;
    my $msg_type = unpack( 'C', substr( $bytes, 0, 1 ) );

    if ( $msg_type == $RELAY_FORW || $msg_type == $RELAY_REPLY ) {
        return Net::DHCPv6::Packet::Relay->from_bytes( $bytes );
    }

    my $tid        = unpack( 'N', chr( 0 ) . substr( $bytes, 1, $TX_ID_BYTES ) );
    my $opts_bytes = substr( $bytes, $HDR_SIZE );

    my $subclass = $Net::DHCPv6::Packet::MESSAGE_CLASS{$msg_type} || $class;
    my $opts     = Net::DHCPv6::OptionList->from_bytes( $opts_bytes );
    my $packet   = bless {
        msg_type       => $msg_type,
        transaction_id => $tid,
        options        => $opts,
    }, $subclass;
    return $packet;
}

sub type {
    my $self = shift;
    return $Net::DHCPv6::Constants::REV_MESSAGE_TYPE{ $self->{msg_type} };
}

sub msg_type_name { return shift->type }

our %MESSAGE_CLASS;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::Packet - DHCPv6 packet base class

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  my $pkt = Net::DHCPv6::Packet->new(
      msg_type       => $SOLICIT,
      transaction_id => 123456,
  );
  $pkt->add_option($clientid);
  my $bytes = $pkt->as_bytes;

  my $decoded = Net::DHCPv6::Packet->from_bytes($bytes);
  print $decoded->msg_type;       # 1
  print $decoded->type;           # SOLICIT
  print $decoded->transaction_id; # 123456

=head1 DESCRIPTION

Base class for DHCPv6 packets. Holds a message type, 24-bit
transaction ID, and an L<Net::DHCPv6::OptionList>. Concrete
message subclasses (e.g. L<Net::DHCPv6::Message::Solicit>)
set the msg_type constant.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 CONSTRUCTOR OVERLOAD

When called with a single scalar argument, C<< Packet->new($bytes) >>
delegates to L<Net::DHCPv6> C<decode_or_croak>:

  my $pkt = Net::DHCPv6::Packet->new($wire_bytes);

With key-value arguments, constructs a new packet:

  my $pkt = Net::DHCPv6::Packet->new(
      msg_type       => 1,
      transaction_id => 123456,
  );

Zero arguments croaks.

=head1 METHODS

=over

=item B<msg_type>

Returns the numeric message type.

=item B<transaction_id>

Returns the 24-bit transaction ID as an integer.

=item B<options>

Returns the internal L<Net::DHCPv6::OptionList>.

=item B<add_option>($option)

Appends an option to the packet.

=item B<get_option>($code)

Returns the first option with the given code, or C<undef>.

=item B<as_bytes>

Serializes to wire format: 1-byte msg_type + 3-byte transaction_id
(big-endian) + options TLV chain.

=item B<type>

Returns the message type name string (e.g. C<SOLICIT>), or C<undef>
if unknown.

=item B<msg_type_name>

Alias for L</type>. Returns the message type name string.

=back

=head1 CLASS METHODS

=over

=item B<from_bytes>($bytes)

Parses a packet from wire bytes. Dispatches to the appropriate
concrete subclass via C<%MESSAGE_CLASS>. Falls back to
C<Net::DHCPv6::Packet> for unknown message types. RELAY-FORW and
RELAY-REPLY messages are handled by L<Net::DHCPv6::Packet::Relay>.

=back

=head1 RELAY MESSAGES

RELAY-FORW (12) and RELAY-REPLY (13) use a different wire format:
hop_count(1) + link_address(16) + peer_address(16) + options.
They have no transaction_id. See L<Net::DHCPv6::Packet::Relay>.

=for Pod::Coverage new

=head1 SEE ALSO

L<Net::DHCPv6>, L<Net::DHCPv6::Packet::Relay>,
L<Net::DHCPv6::Message::Solicit>,
L<Net::DHCPv6::Message::Reply>, L<Net::DHCPv6::OptionList>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut

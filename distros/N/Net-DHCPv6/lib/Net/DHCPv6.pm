#!/bin/false
# ABSTRACT: DHCPv6 packet decoder/encoder
# PODNAME: Net::DHCPv6
use strictures 2;

package Net::DHCPv6;
$Net::DHCPv6::VERSION = '0.002';
use Carp qw( croak );
use Net::DHCPv6::DUID;

# Option classes - loaded so they register in the dispatch tables
use Net::DHCPv6::Option::AftrName;
use Net::DHCPv6::Option::Auth;
use Net::DHCPv6::Option::BootfileParam;
use Net::DHCPv6::Option::BootfileUrl;
use Net::DHCPv6::Option::CaptivePortal;
use Net::DHCPv6::Option::ClientArchType;
use Net::DHCPv6::Option::ClientFqdn;
use Net::DHCPv6::Option::ClientId;
use Net::DHCPv6::Option::ClientLinkLayerAddr;
use Net::DHCPv6::Option::DnsServers;
use Net::DHCPv6::Option::DomainList;
use Net::DHCPv6::Option::ElapsedTime;
use Net::DHCPv6::Option::Generic;
use Net::DHCPv6::Option::IAAddr;
use Net::DHCPv6::Option::IANA;
use Net::DHCPv6::Option::IAPD;
use Net::DHCPv6::Option::IAPrefix;
use Net::DHCPv6::Option::IATA;
use Net::DHCPv6::Option::InfMaxRt;
use Net::DHCPv6::Option::InfoRefreshTime;
use Net::DHCPv6::Option::InterfaceId;
use Net::DHCPv6::Option::NewPosixTimezone;
use Net::DHCPv6::Option::NewTzdbTimezone;
use Net::DHCPv6::Option::NisDomainName;
use Net::DHCPv6::Option::NisServers;
use Net::DHCPv6::Option::NispDomainName;
use Net::DHCPv6::Option::NispServers;
use Net::DHCPv6::Option::NtpServer;
use Net::DHCPv6::Option::ORO;
use Net::DHCPv6::Option::PdExclude;
use Net::DHCPv6::Option::SntpServers;
use Net::DHCPv6::Option::Preference;
use Net::DHCPv6::Option::RapidCommit;
use Net::DHCPv6::Option::ReconfAccept;
use Net::DHCPv6::Option::ReconfMsg;
use Net::DHCPv6::Option::RelayMsg;
use Net::DHCPv6::Option::RemoteId;
use Net::DHCPv6::Option::RSOO;
use Net::DHCPv6::Option::ServerId;
use Net::DHCPv6::Option::SipServerA;
use Net::DHCPv6::Option::SipServerD;
use Net::DHCPv6::Option::MudUrl;
use Net::DHCPv6::Option::SolMaxRt;
use Net::DHCPv6::Option::StatusCode;
use Net::DHCPv6::Option::SubscriberId;
use Net::DHCPv6::Option::Unicast;
use Net::DHCPv6::Option::UserClass;
use Net::DHCPv6::Option::VendorClass;
use Net::DHCPv6::Option::VendorOpts;

# Message classes
use Net::DHCPv6::Message::Solicit;
use Net::DHCPv6::Message::Advertise;
use Net::DHCPv6::Message::Request;
use Net::DHCPv6::Message::Confirm;
use Net::DHCPv6::Message::Renew;
use Net::DHCPv6::Message::Rebind;
use Net::DHCPv6::Message::Reply;
use Net::DHCPv6::Message::Release;
use Net::DHCPv6::Message::Decline;
use Net::DHCPv6::Message::Reconfigure;
use Net::DHCPv6::Message::InformationRequest;
use Net::DHCPv6::Message::RelayForw;
use Net::DHCPv6::Message::RelayReply;

use Net::DHCPv6::OptionList;
use Net::DHCPv6::Packet;
use namespace::clean;

my $MIN_LEN = 4;    ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)

# Packet-level decoders
sub decode_or_croak {
    my ( $class, $bytes ) = @_;
    croak 'No data provided' if !defined $bytes || CORE::length( $bytes ) < $MIN_LEN;
    return Net::DHCPv6::Packet->from_bytes( $bytes );
}

sub decode_or_null {
    my ( $class, $bytes ) = @_;
    return if !defined $bytes || CORE::length( $bytes ) < $MIN_LEN;
    my $packet;
    eval { $packet = Net::DHCPv6::Packet->from_bytes( $bytes ); };
    return $packet;
}

sub decode_with_error {
    my ( $class, $bytes ) = @_;
    my $packet;
    my $error;
    if ( !defined $bytes || CORE::length( $bytes ) < $MIN_LEN ) {
        $error = 'No data provided';
    }
    else {
        eval { $packet = Net::DHCPv6::Packet->from_bytes( $bytes ); 1 }
            or $error = $@;
    }
    return ( $packet, $error );
}

# DUID streaming helpers
sub decode_duid_with_error {
    my ( $class, $bytes ) = @_;
    return Net::DHCPv6::DUID->try_from_bytes( $bytes );
}

sub decode_duid_or_null {
    my ( $class, $bytes ) = @_;
    my ( $duid ) = Net::DHCPv6::DUID->try_from_bytes( $bytes );
    return $duid;
}

sub decode_duid_or_croak {
    my ( $class, $bytes ) = @_;
    my ( $duid,  $error ) = Net::DHCPv6::DUID->try_from_bytes( $bytes );
    croak $error if $error;
    return $duid;
}

# Option-list streaming helpers
sub decode_options_with_error {
    my ( $class, $bytes ) = @_;
    return Net::DHCPv6::OptionList->try_from_bytes( $bytes );
}

sub decode_options_or_null {
    my ( $class, $bytes ) = @_;
    my ( $ol ) = Net::DHCPv6::OptionList->try_from_bytes( $bytes );
    return $ol;
}

sub decode_options_or_croak {
    my ( $class, $bytes ) = @_;
    my ( $ol,    $error ) = Net::DHCPv6::OptionList->try_from_bytes( $bytes );
    croak $error if $error;
    return $ol;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6 - DHCPv6 packet decoder/encoder

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use Net::DHCPv6;

  my $bytes  = ...;  # wire bytes from socket
  my $packet = Net::DHCPv6->decode_or_croak($bytes);
  print $packet->type;         # SOLICIT
  print $packet->msg_type;     # 1
  print $packet->transaction_id;
  my $cid = $packet->get_option(1);
  print $cid->duid->duid_type;

  # Tolerant parsing
  if (my $pkt = Net::DHCPv6->decode_or_null($bytes)) {
      ...
  }

  # Inspect-mode parsing
  my ($pkt, $err) = Net::DHCPv6->decode_with_error($bytes);
  if ($err) { warn $err->message; }

=head1 DESCRIPTION

Top-level module for the Net::DHCPv6 library. Provides three entry
points for decoding DHCPv6 wire bytes with different error-handling
behaviours. Also loads all sub-modules so a single C<use Net::DHCPv6>
makes all classes available.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 DECODER METHODS

=over

=item B<decode_or_croak>($bytes)

Strict parsing. Returns a L<Net::DHCPv6::Packet> object on success.
Croaks (throws an exception) on any parse failure, including
truncated data.

=item B<decode_or_null>($bytes)

Tolerant parsing. Returns a L<Net::DHCPv6::Packet> object on
success, C<undef> on failure. Never throws.

=item B<decode_with_error>($bytes)

Inspect-mode parsing. Returns C<($packet, $error)> where C<$packet>
is a L<Net::DHCPv6::Packet> or C<undef>, and C<$error> is an error
string or C<undef>. Never throws.

=back

=head1 DUID STREAMING HELPERS

These methods parse raw DUID bytes without requiring a full packet or option wrapper.

=over

=item B<decode_duid_with_error>($bytes)

Returns C<($duid, $error)>. On truncation, C<$duid> contains whatever
fields could be decoded (partial decode). C<$error> is a string or
C<undef>. Never throws.

=item B<decode_duid_or_null>($bytes)

Returns a L<Net::DHCPv6::DUID> on success or partial decode, C<undef>
if the buffer is too short for even the 2-byte type header. Never
throws.

=item B<decode_duid_or_croak>($bytes)

Returns a L<Net::DHCPv6::DUID> on success, croaks on any truncation.

=back

=head1 OPTION-LIST STREAMING HELPERS

These methods parse raw option TLV chains without requiring a packet
wrapper -- useful for relay messages or extracting options from
sub-option payloads.

=over

=item B<decode_options_with_error>($bytes)

Returns C<($option_list, $error)>. On truncation, C<$option_list>
contains whatever options were fully parsed before the error.
C<$error> is a string or C<undef>. Never throws.

=item B<decode_options_or_null>($bytes)

Returns a L<Net::DHCPv6::OptionList> on success or partial decode,
an empty L<Net::DHCPv6::OptionList> on empty input. Never throws.

=item B<decode_options_or_croak>($bytes)

Returns a L<Net::DHCPv6::OptionList> on success, croaks on any
truncation or trailing garbage.

=back

=head1 PACKET SUGAR

  my $pkt = Net::DHCPv6::Packet->new($bytes);

C<Packet-E<gt>new($bytes)> delegates to C<decode_or_croak> when
given a single scalar argument.

=head1 SEE ALSO

L<Net::DHCPv6::Packet>, L<Net::DHCPv6::Constants>, L<Net::DHCPv6::DUID>,
L<Net::DHCPv6::OptionList>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut

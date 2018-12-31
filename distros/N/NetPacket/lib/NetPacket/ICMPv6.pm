package NetPacket::ICMPv6;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Assemble and disassemble ICMPv6 (Internet Control Message Protocol for IPv6) packets. 
$NetPacket::ICMPv6::VERSION = '1.7.0';
use strict;
use warnings;

use parent 'NetPacket';
use NetPacket::IPv6 'IP_PROTO_ICMPv6';

our @EXPORT_OK = qw(icmpv6_strip icmpv6_infotype
                    ICMPv6_UNREACH ICMPv6_TOOBIG ICMPv6_TIMXCEED ICMPv6_PARAMPROB
                    ICMPv6_PRIVATEERROR1 ICMPv6_PRIVATEERROR2 ICMPv6_EXPANSIONERROR
                    ICMPv6_ECHOREQ ICMPv6_ECHOREPLY ICMPv6_MULTICASTQUERY
                    ICMPv6_MULTICASTREPORT ICMPv6_MULTICASTDONE
                    ICMPv6_ROUTERSOLICIT ICMPv6_ROUTERADVERT
                    ICMPv6_NEIGHBORSOLICIT ICMPv6_NEIGHBORADVERT
                    ICMPv6_REDIRECT ICMPv6_ROUTERRENUMBER
                    ICMPv6_NODEINFOQUERY ICMPv6_NODEINFOREPLY
                    ICMPv6_INVNEIGHBORSOLICIT ICMPv6_INVNEIGHBORADVERT
                    ICMPv6_MULTICASTREPORTV2
                    ICMPv6_HOMEAGENTREQUEST ICMPv6_HOMEAGENTREPLY
                    ICMPv6_MOBILEPREFIXSOLICIT ICMPv6_MOBILEPREFIXADVERT
                    ICMPv6_CERTPATHSOLICIT ICMPv6_CERTPATHADVERT
                    ICMPv6_MULTICASTADVERT ICMPv6_MULTICASTSOLICIT
                    ICMPv6_MULTICASTTERM ICMPv6_FMIPv6 ICMPv6_RPLCONTROL
                    ICMPv6_DUPREQUEST ICMPv6_DUPCONFIRM ICMPv6_MPLCONTROL
                    ICMPv6_EXTECHOREQ ICMPv6_EXTECHOREPLY
                    ICMPv6_PRIVATEINFO1 ICMPv6_PRIVATEINFO2 ICMPv6_EXPANSIONINFO
                    ICMPv6_UNREACH_NO_ROUTE ICMPv6_UNREACH_COMM_PROHIB
                    ICMPv6_UNREACH_BEYOND_SCOPE ICMPv6_UNREACH_ADDRESS ICMPv6_UNREACH_PORT
                    ICMPv6_UNREACH_SRC_FAIL_POLICY ICMPv6_UNREACH_REJECT_DEST
                    ICMPv6_TIMXCEED_INTRANS ICMPv6_TIMXCEED_REASS
                    ICMPv6_PARAMPROB_HEADER_FIELD ICMPv6_PARAMPROB_NEXT_HEADER
                    ICMPv6_PARAMPROB_OPTION
                    ICMPv6_ROUTERRENUMBER_COMMAND ICMPv6_ROUTERRENUMBER_RESULT
                    ICMPv6_ROUTERRENUMBER_RESET
                    ICMPv6_NODEINFOQUERY_IPv6 ICMPv6_NODEINFOQUERY_NAME
                    ICMPv6_NODEINFOQUERY_IPv4 ICMPv6_NODEINFOREPLY_SUCCESS
                    ICMPv6_NODEINFOREPLY_REFUSED ICMPv6_NODEINFOREPLY_UNKNOWN
                    ICMPv6_RPLCONTROL_DODAG_SOLICIT ICMPv6_RPLCONTROL_DODAG_OBJECT
                    ICMPv6_RPLCONTROL_DEST_ADVERT ICMPv6_RPLCONTROL_DEST_ACK
                    ICMPv6_RPLCONTROL_SECURE_DODAG_SOLICIT ICMPv6_RPLCONTROL_SECURE_DODAG_OBJECT
                    ICMPv6_RPLCONTROL_SECURE_DEST_ADVERT ICMPv6_RPLCONTROL_SECURE_DEST_ACK
                    ICMPv6_RPLCONTROL_CONSISTENCY
                    ICMPv6_EXTECHOREPLY_NO_ERROR ICMPv6_EXTECHOREPLY_MALFORMED
                    ICMPv6_EXTECHOREPLY_NO_INTERFACE ICMPv6_EXTECHOREPLY_NO_ENTRY
                    ICMPv6_EXTECHOREPLY_MULTIPLE
    );

our %EXPORT_TAGS = (
    ALL         => [@EXPORT_OK],
    types       => [qw(ICMPv6_UNREACH ICMPv6_TOOBIG ICMPv6_TIMXCEED ICMPv6_PARAMPROB
                       ICMPv6_PRIVATEERROR1 ICMPv6_PRIVATEERROR2 ICMPv6_EXPANSIONERROR
                       ICMPv6_ECHOREQ ICMPv6_ECHOREPLY ICMPv6_MULTICASTQUERY
                       ICMPv6_MULTICASTREPORT ICMPv6_MULTICASTDONE
                       ICMPv6_ROUTERSOLICIT ICMPv6_ROUTERADVERT
                       ICMPv6_NEIGHBORSOLICIT ICMPv6_NEIGHBORADVERT
                       ICMPv6_REDIRECT ICMPv6_ROUTERRENUMBER
                       ICMPv6_NODEINFOQUERY ICMPv6_NODEINFOREPLY
                       ICMPv6_INVNEIGHBORSOLICIT ICMPv6_INVNEIGHBORADVERT
                       ICMPv6_MULTICASTREPORTV2
                       ICMPv6_HOMEAGENTREQUEST ICMPv6_HOMEAGENTREPLY
                       ICMPv6_MOBILEPREFIXSOLICIT ICMPv6_MOBILEPREFIXADVERT
                       ICMPv6_CERTPATHSOLICIT ICMPv6_CERTPATHADVERT
                       ICMPv6_MULTICASTADVERT ICMPv6_MULTICASTSOLICIT
                       ICMPv6_MULTICASTTERM ICMPv6_FMIPv6 ICMPv6_RPLCONTROL
                       ICMPv6_DUPREQUEST ICMPv6_DUPCONFIRM ICMPv6_MPLCONTROL
                       ICMPv6_EXTECHOREQ ICMPv6_EXTECHOREPLY
                       ICMPv6_PRIVATEINFO1 ICMPv6_PRIVATEINFO2 ICMPv6_EXPANSIONINFO)],
    codes       => [qw(ICMPv6_UNREACH_NO_ROUTE ICMPv6_UNREACH_COMM_PROHIB
                       ICMPv6_UNREACH_BEYOND_SCOPE ICMPv6_UNREACH_ADDRESS ICMPv6_UNREACH_PORT
                       ICMPv6_UNREACH_SRC_FAIL_POLICY ICMPv6_UNREACH_REJECT_DEST
                       ICMPv6_TIMXCEED_INTRANS ICMPv6_TIMXCEED_REASS
                       ICMPv6_PARAMPROB_HEADER_FIELD ICMPv6_PARAMPROB_NEXT_HEADER
                       ICMPv6_PARAMPROB_OPTION
                       ICMPv6_ROUTERRENUMBER_COMMAND ICMPv6_ROUTERRENUMBER_RESULT
                       ICMPv6_ROUTERRENUMBER_RESET
                       ICMPv6_NODEINFOQUERY_IPv6 ICMPv6_NODEINFOQUERY_NAME
                       ICMPv6_NODEINFOQUERY_IPv4 ICMPv6_NODEINFOREPLY_SUCCESS
                       ICMPv6_NODEINFOREPLY_REFUSED ICMPv6_NODEINFOREPLY_UNKNOWN
                       ICMPv6_RPLCONTROL_DODAG_SOLICIT ICMPv6_RPLCONTROL_DODAG_OBJECT
                       ICMPv6_RPLCONTROL_DEST_ADVERT ICMPv6_RPLCONTROL_DEST_ACK
                       ICMPv6_RPLCONTROL_SECURE_DODAG_SOLICIT ICMPv6_RPLCONTROL_SECURE_DODAG_OBJECT
                       ICMPv6_RPLCONTROL_SECURE_DEST_ADVERT ICMPv6_RPLCONTROL_SECURE_DEST_ACK
                       ICMPv6_RPLCONTROL_CONSISTENCY
                       ICMPv6_EXTECHOREPLY_NO_ERROR ICMPv6_EXTECHOREPLY_MALFORMED
                       ICMPv6_EXTECHOREPLY_NO_INTERFACE ICMPv6_EXTECHOREPLY_NO_ENTRY
                       ICMPv6_EXTECHOREPLY_MULTIPLE)],
    strip       => [qw(icmpv6_strip)],
);

# ICMPv6 Types

use constant ICMPv6_UNREACH => 1;
use constant ICMPv6_TOOBIG => 2;
use constant ICMPv6_TIMXCEED => 3;
use constant ICMPv6_PARAMPROB => 4;
use constant ICMPv6_PRIVATEERROR1 => 100;
use constant ICMPv6_PRIVATEERROR2 => 101;
use constant ICMPv6_EXPANSIONERROR => 127;
use constant ICMPv6_ECHOREQ => 128;
use constant ICMPv6_ECHOREPLY => 129;
use constant ICMPv6_MULTICASTQUERY => 130;
use constant ICMPv6_MULTICASTREPORT => 131;
use constant ICMPv6_MULTICASTDONE => 132;
use constant ICMPv6_ROUTERSOLICIT => 133;
use constant ICMPv6_ROUTERADVERT => 134;
use constant ICMPv6_NEIGHBORSOLICIT => 135;
use constant ICMPv6_NEIGHBORADVERT => 136;
use constant ICMPv6_REDIRECT => 137;
use constant ICMPv6_ROUTERRENUMBER => 138;
use constant ICMPv6_NODEINFOQUERY => 139;
use constant ICMPv6_NODEINFOREPLY => 140;
use constant ICMPv6_INVNEIGHBORSOLICIT => 141;
use constant ICMPv6_INVNEIGHBORADVERT => 142;
use constant ICMPv6_MULTICASTREPORTV2 => 143;
use constant ICMPv6_HOMEAGENTREQUEST => 144;
use constant ICMPv6_HOMEAGENTREPLY => 145;
use constant ICMPv6_MOBILEPREFIXSOLICIT => 146;
use constant ICMPv6_MOBILEPREFIXADVERT => 147;
use constant ICMPv6_CERTPATHSOLICIT => 148;
use constant ICMPv6_CERTPATHADVERT => 149;
use constant ICMPv6_MULTICASTADVERT => 151;
use constant ICMPv6_MULTICASTSOLICIT => 152;
use constant ICMPv6_MULTICASTTERM => 153;
use constant ICMPv6_FMIPv6 => 154;
use constant ICMPv6_RPLCONTROL => 155;
use constant ICMPv6_DUPREQUEST => 157;
use constant ICMPv6_DUPCONFIRM => 158;
use constant ICMPv6_MPLCONTROL => 159;
use constant ICMPv6_EXTECHOREQ => 160;
use constant ICMPv6_EXTECHOREPLY => 161;
use constant ICMPv6_PRIVATEINFO1 => 200;
use constant ICMPv6_PRIVATEINFO2 => 201;
use constant ICMPv6_EXPANSIONINFO => 255;

# Destination Unreachable Codes

use constant ICMPv6_UNREACH_NO_ROUTE => 0;
use constant ICMPv6_UNREACH_COMM_PROHIB => 1;
use constant ICMPv6_UNREACH_BEYOND_SCOPE => 2;
use constant ICMPv6_UNREACH_ADDRESS => 3;
use constant ICMPv6_UNREACH_PORT => 4;
use constant ICMPv6_UNREACH_SRC_FAIL_POLICY => 5;
use constant ICMPv6_UNREACH_REJECT_DEST => 6;

# Time-Exceeded Codes

use constant ICMPv6_TIMXCEED_INTRANS => 0;
use constant ICMPv6_TIMXCEED_REASS => 1;

# Parameter-Problem Codes

use constant ICMPv6_PARAMPROB_HEADER_FIELD => 0;
use constant ICMPv6_PARAMPROB_NEXT_HEADER => 1;
use constant ICMPv6_PARAMPROB_OPTION => 2;

# Router Renumbering Codes

use constant ICMPv6_ROUTERRENUMBER_COMMAND => 0;
use constant ICMPv6_ROUTERRENUMBER_RESULT => 1;
use constant ICMPv6_ROUTERRENUMBER_RESET => 255;

# Node Information Query Codes

use constant ICMPv6_NODEINFOQUERY_IPv6 => 0;
use constant ICMPv6_NODEINFOQUERY_NAME => 1;
use constant ICMPv6_NODEINFOQUERY_IPv4 => 2;

# Node Information Reply Codes

use constant ICMPv6_NODEINFOREPLY_SUCCESS => 0;
use constant ICMPv6_NODEINFOREPLY_REFUSED => 1;
use constant ICMPv6_NODEINFOREPLY_UNKNOWN => 2;

# RPL Control Codes

use constant ICMPv6_RPLCONTROL_DODAG_SOLICIT => 0x00;
use constant ICMPv6_RPLCONTROL_DODAG_OBJECT => 0x01;
use constant ICMPv6_RPLCONTROL_DEST_ADVERT => 0x02;
use constant ICMPv6_RPLCONTROL_DEST_ACK => 0x03;
use constant ICMPv6_RPLCONTROL_SECURE_DODAG_SOLICIT => 0x80;
use constant ICMPv6_RPLCONTROL_SECURE_DODAG_OBJECT => 0x81;
use constant ICMPv6_RPLCONTROL_SECURE_DEST_ADVERT => 0x82;
use constant ICMPv6_RPLCONTROL_SECURE_DEST_ACK => 0x83;
use constant ICMPv6_RPLCONTROL_CONSISTENCY => 0x8A;

# Extended Echo Reply Codes

use constant ICMPv6_EXTECHOREPLY_NO_ERROR => 0;
use constant ICMPv6_EXTECHOREPLY_MALFORMED => 1;
use constant ICMPv6_EXTECHOREPLY_NO_INTERFACE => 2;
use constant ICMPv6_EXTECHOREPLY_NO_ENTRY => 3;
use constant ICMPv6_EXTECHOREPLY_MULTIPLE => 4;

#
# Test for informational types
#

sub icmpv6_infotype {
    my $type = shift;
    return $type >= ICMPv6_ECHOREQ;
}

#
# Decode the packet
#

sub decode {
    my $class = shift;
    my($pkt, $parent) = @_;
    my $self = {};

    # Class fields

    $self->{_parent} = $parent;
    $self->{_frame} = $pkt;

    # Decode ICMPv6 packet

    if (defined($pkt)) {
        ($self->{type}, $self->{code}, $self->{cksum}, $self->{data}) =
            unpack("CCna*", $pkt);
    }

    # Return a blessed object

    bless($self, $class);
    return $self;
}

#
# Strip a packet of its header and return the data
#

undef &icmpv6_strip;
*icmpv6strip = \&strip;

sub strip {
    my ($pkt) = @_;

    my $icmpv6_obj = decode($pkt);
    return $icmpv6_obj->{data};
}

#
# Encode a packet
#

sub encode {
    my $self = shift;
    my ($ipv6) = @_;
    
    # Checksum the packet
    $self->checksum($ipv6);

    # Put the packet together
    my $packet = pack("CCna*", $self->{type}, $self->{code}, 
                $self->{cksum}, $self->{data});

    return($packet); 
}

#
# Calculate ICMPv6 checksum

sub checksum {
    my $self = shift;
    my ($ipv6) = @_;

    # Put the packet together for checksumming
    my $len = length($self->{data}) + 32;
    my $packet = $ipv6->pseudo_header($len, IP_PROTO_ICMPv6);
    $packet .= pack("CCna*", $self->{type}, $self->{code}, 0, $self->{data});

    $self->{cksum} = NetPacket::htons(NetPacket::in_cksum($packet));
}


#
# Module initialisation
#

1;

# autoloaded methods go after the END token (&& pod) below

=pod

=head1 NAME

NetPacket::ICMPv6 - Assemble and disassemble ICMPv6 (Internet Control Message Protocol for IPv6) packets. 

=head1 VERSION

version 1.7.0

=head1 SYNOPSIS

  use NetPacket::ICMPv6;

  $icmpv6_obj = NetPacket::ICMPv6->decode($raw_pkt);
  $icmpv6_pkt = NetPacket::ICMPv6->encode($ipv6_pkt);
  $icmpv6_data = NetPacket::ICMPv6::strip($raw_pkt);

=head1 DESCRIPTION

C<NetPacket::ICMPv6> provides a set of routines for assembling and
disassembling packets using ICMPv6 (Internet Control Message Protocol
for IPv6). 

=head2 Methods

=over

=item C<NetPacket::ICMPv6-E<gt>decode([RAW PACKET])>

Decode the raw packet data given and return an object containing
instance data.  This method will quite happily decode garbage input.
It is the responsibility of the programmer to ensure valid packet data
is passed to this method.

=item C<NetPacket::ICMPv6-E<gt>encode($ipv6_obj)>

Return an ICMPv6 packet encoded with the instance data specified.
Needs parts of the IPv6 header contained in $ipv6_obj in order to calculate
the ICMPv6 checksum.

=back

=head2 Functions

=over

=item C<NetPacket::ICMPv6::strip([RAW PACKET])>

Return the encapsulated data (or payload) contained in the ICMPv6
packet.

=back

=head2 Instance data

The instance data for the C<NetPacket::ICMPv6> object consists of
the following fields.

=over

=item type

The ICMPv6 message type of this packet.

=item code

The ICMPv6 message code of this packet.

=item cksum

The checksum for this packet.

=item data

The encapsulated data (payload) for this packet.

=back

=head2 Exports

=over

=item default

none

=item exportable

ICMPv6 message types: 

    ICMPv6_UNREACH ICMPv6_TOOBIG ICMPv6_TIMXCEED ICMPv6_PARAMPROB
    ICMPv6_PRIVATEERROR1 ICMPv6_PRIVATEERROR2 ICMPv6_EXPANSIONERROR
    ICMPv6_ECHOREQ ICMPv6_ECHOREPLY ICMPv6_MULTICASTQUERY
    ICMPv6_MULTICASTREPORT ICMPv6_MULTICASTDONE
    ICMPv6_ROUTERSOLICIT ICMPv6_ROUTERADVERT
    ICMPv6_NEIGHBORSOLICIT ICMPv6_NEIGHBORADVERT
    ICMPv6_REDIRECT ICMPv6_ROUTERRENUMBER
    ICMPv6_NODEINFOQUERY ICMPv6_NODEINFOREPLY
    ICMPv6_INVNEIGHBORSOLICIT ICMPv6_INVNEIGHBORADVERT
    ICMPv6_MULTICASTREPORTV2
    ICMPv6_HOMEAGENTREQUEST ICMPv6_HOMEAGENTREPLY
    ICMPv6_MOBILEPREFIXSOLICIT ICMPv6_MOBILEPREFIXADVERT
    ICMPv6_CERTPATHSOLICIT ICMPv6_CERTPATHADVERT
    ICMPv6_MULTICASTADVERT ICMPv6_MULTICASTSOLICIT
    ICMPv6_MULTICASTTERM ICMPv6_FMIPv6 ICMPv6_RPLCONTROL
    ICMPv6_DUPREQUEST ICMPv6_DUPCONFIRM ICMPv6_MPLCONTROL
    ICMPv6_EXTECHOREQ ICMPv6_EXTECHOREPLY
    ICMPv6_PRIVATEINFO1 ICMPv6_PRIVATEINFO2 ICMPv6_EXPANSIONINFO

ICMPv6 message codes:

    ICMPv6_UNREACH_NO_ROUTE ICMPv6_UNREACH_COMM_PROHIB
    ICMPv6_UNREACH_BEYOND_SCOPE ICMPv6_UNREACH_ADDRESS ICMPv6_UNREACH_PORT
    ICMPv6_UNREACH_SRC_FAIL_POLICY ICMPv6_UNREACH_REJECT_DEST
    ICMPv6_TIMXCEED_INTRANS ICMPv6_TIMXCEED_REASS
    ICMPv6_PARAMPROB_HEADER_FIELD ICMPv6_PARAMPROB_NEXT_HEADER
    ICMPv6_PARAMPROB_OPTION
    ICMPv6_ROUTERRENUMBER_COMMAND ICMPv6_ROUTERRENUMBER_RESULT
    ICMPv6_ROUTERRENUMBER_RESET
    ICMPv6_NODEINFOQUERY_IPv6 ICMPv6_NODEINFOQUERY_NAME
    ICMPv6_NODEINFOQUERY_IPv4 ICMPv6_NODEINFOREPLY_SUCCESS
    ICMPv6_NODEINFOREPLY_REFUSED ICMPv6_NODEINFOREPLY_UNKNOWN
    ICMPv6_RPLCONTROL_DODAG_SOLICIT ICMPv6_RPLCONTROL_DODAG_OBJECT
    ICMPv6_RPLCONTROL_DEST_ADVERT ICMPv6_RPLCONTROL_DEST_ACK
    ICMPv6_RPLCONTROL_SECURE_DODAG_SOLICIT ICMPv6_RPLCONTROL_SECURE_DODAG_OBJECT
    ICMPv6_RPLCONTROL_SECURE_DEST_ADVERT ICMPv6_RPLCONTROL_SECURE_DEST_ACK
    ICMPv6_RPLCONTROL_CONSISTENCY
    ICMPv6_EXTECHOREPLY_NO_ERROR ICMPv6_EXTECHOREPLY_MALFORMED
    ICMPv6_EXTECHOREPLY_NO_INTERFACE ICMPv6_EXTECHOREPLY_NO_ENTRY
    ICMPv6_EXTECHOREPLY_MULTIPLE

=item tags

The following tags group together related exportable items.

=over

=item C<:types>

=item C<:codes>

=item C<:strip>

Import the strip function C<icmpv6_strip>.

=item C<:ALL>

All the above exportable items.

=back

=back

=head1 EXAMPLE

The following example prints the ICMPv6 type, code, and checksum 
fields.

  #!/usr/bin/perl

  use strict;
  use warnings;
  use Net::PcapUtils;
  use NetPacket::Ethernet qw(:strip);
  use NetPacket::IPv6 qw(:strip);
  use NetPacket::ICMPv6;

  sub process_pkt {
      my ($user, $hdr, $pkt) = @_;

      my $icmpv6_obj = NetPacket::ICMPv6->decode(ipv6_strip(eth_strip($pkt)));

      print("Type: $icmpv6_obj->{type}\n");
      print("Code: $icmpv6_obj->{code}\n");
      print("Checksum: $icmpv6_obj->{cksum}\n\n");
  }

  Net::PcapUtils::loop(\&process_pkt, FILTER => 'icmp6');

=head1 COPYRIGHT

Copyright (c) 2018 Dan Book.

This module is free software.  You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=head1 AUTHOR

Dan Book E<lt>dbook@cpan.orgE<gt>

=cut

__END__


# any real autoloaded methods go after this line

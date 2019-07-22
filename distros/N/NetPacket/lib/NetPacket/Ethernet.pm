package NetPacket::Ethernet;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Assemble and disassemble ethernet packets.
$NetPacket::Ethernet::VERSION = '1.7.2';
use strict;
use warnings;

use parent 'NetPacket';

my @eth_types = qw/ ETH_TYPE_IP
                    ETH_TYPE_ARP
                    ETH_TYPE_APPLETALK
                    ETH_TYPE_RARP
                    ETH_TYPE_SNMP
                    ETH_TYPE_IPv6
                    ETH_TYPE_PPP
                    ETH_TYPE_802_1Q
                    ETH_TYPE_IPX
                    ETH_TYPE_PPPOED
                    ETH_TYPE_PPPOES    /;

our @EXPORT_OK = ( 'eth_strip', 'ETH_HLEN', @eth_types );

our %EXPORT_TAGS = (
    ALL         => [@EXPORT_OK],
    strip       => [qw(eth_strip)],
    types       => \@eth_types,
);

#
# Partial list of ethernet protocol types from
# http://www.isi.edu/in-notes/iana/assignments/ethernet-numbers
#

use constant ETH_TYPE_IP        => 0x0800;
use constant ETH_TYPE_ARP       => 0x0806;
use constant ETH_TYPE_APPLETALK => 0x809b;
use constant ETH_TYPE_RARP      => 0x8035;
use constant ETH_TYPE_SNMP      => 0x814c;
use constant ETH_TYPE_IPv6      => 0x86dd;
use constant ETH_TYPE_PPP       => 0x880b;
use constant ETH_TYPE_802_1Q    => 0x8100;
use constant ETH_TYPE_IPX       => 0x8137;
use constant ETH_TYPE_PPPOED    => 0x8863;
use constant ETH_TYPE_PPPOES    => 0x8864;

use constant ETH_HLEN		=> 6;

#
# VLAN Tag field masks
#

use constant VLAN_MASK_PCP => 0xE000;
use constant VLAN_MASK_CFI => 0x1000;
use constant VLAN_MASK_VID => 0x0FFF;

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

    # Decode ethernet packet

    if (defined($pkt)) {

        my($sm_lo, $sm_hi, $dm_lo, $dm_hi, $tcid);

        ($dm_hi, $dm_lo, $sm_hi, $sm_lo, $self->{type}) = unpack('NnNnn' ,
$pkt);

        # Check for 802.1Q VLAN tag and unpack to account for 4-byte offset
        if ($self->{type} == ETH_TYPE_802_1Q) {
            $self->{tpid} = ETH_TYPE_802_1Q;

            ( $tcid, $self->{type}, $self->{data} ) = unpack('x14nna*' , $pkt);

            # Break down VLAN tag TCI into: PCP, CFI, VID
            $self->{pcp} = $tcid & VLAN_MASK_PCP >> 13;
            $self->{cfi} = $tcid & VLAN_MASK_CFI >> 12;
            $self->{vid} = $tcid & VLAN_MASK_VID;
        }
        else {
            ( $self->{data} ) = unpack('x14a*' , $pkt);
        }

        # Convert MAC addresses to hex string to avoid representation problems

        $self->{src_mac} = sprintf "%08x%04x", $sm_hi, $sm_lo;
        $self->{dest_mac} = sprintf "%08x%04x", $dm_hi, $dm_lo;
    }

    # Return a blessed object

    bless($self, $class);
    return $self;
}

#
# Strip header from packet and return the data contained in it
#

sub eth_strip {
  goto \&strip;
}

sub strip {
    my ($pkt) = @_;

    my $eth_obj = NetPacket::Ethernet->decode($pkt);
    return $eth_obj->{data};
}

sub encode {
    my ($self) = shift;

    my @mac = map { $self->{$_} } qw/ dest_mac src_mac /;
    s/://g for @mac;

    return pack 'H12H12n a*', @mac, 0x0800, $self->{data};
}

1;

=pod

=head1 NAME

NetPacket::Ethernet - Assemble and disassemble ethernet packets.

=head1 VERSION

version 1.7.2

=head1 SYNOPSIS

  use NetPacket::Ethernet;

  $eth_obj = NetPacket::Ethernet->decode($raw_pkt);
  $eth_pkt = NetPacket::Ethernet->encode(params...);   # Not implemented
  $eth_data = NetPacket::Ethernet::strip($raw_pkt);

=head1 DESCRIPTION

C<NetPacket::Ethernet> provides a set of routines for assembling and
disassembling packets using the Ethernet protocol.

=head2 Methods

=over

=item C<NetPacket::Ethernet-E<gt>decode([RAW PACKET])>

Decode the raw packet data given and return an object containing
instance data.  This method will quite happily decode garbage input.
It is the responsibility of the programmer to ensure valid packet data
is passed to this method.

=item C<NetPacket::Ethernet-E<gt>encode(param =E<gt> value)>

Return an ethernet packet encoded with the instance data specified.
Not implemented.

=back

=head2 Functions

=over

=item C<NetPacket::Ethernet::strip([RAW PACKET])>

Return the encapsulated data (or payload) contained in the ethernet
packet.  This data is suitable to be used as input for other
C<NetPacket::*> modules.

This function is equivalent to creating an object using the
C<decode()> constructor and returning the C<data> field of that
object.

=back

=head2 Instance data

The instance data for the C<NetPacket::Ethernet> object consists of
the following fields.

=over

=item src_mac

The source MAC address for the ethernet packet as a hex string.

=item dest_mac

The destination MAC address for the ethernet packet as a hex string.

=item type

The protocol type for the ethernet packet.

=item data

The payload for the ethernet packet.

=back

=head2 Exports

=over

=item default

none

=item exportable

ETH_TYPE_IP ETH_TYPE_ARP ETH_TYPE_APPLETALK ETH_TYPE_SNMP
ETH_TYPE_IPv6 ETH_TYPE_PPP

=item tags

The following tags group together related exportable items.

=over

=item C<:types>

ETH_TYPE_IP ETH_TYPE_ARP ETH_TYPE_APPLETALK ETH_TYPE_SNMP
ETH_TYPE_IPv6 ETH_TYPE_PPP

=item C<:strip>

Import the strip function C<eth_strip> which is an alias for
C<NetPacket::Ethernet::strip>

=item C<:ALL>

All the above exportable items.

=back

=back

=head1 EXAMPLE

The following script dumps ethernet frames by mac address and protocol
to standard output.

  #!/usr/bin/perl -w

  use strict;
  use Net::PcapUtils;
  use NetPacket::Ethernet;

  sub process_pkt {
      my($arg, $hdr, $pkt) = @_;

      my $eth_obj = NetPacket::Ethernet->decode($pkt);
      print("$eth_obj->{src_mac}:$eth_obj->{dest_mac} $eth_obj->{type}\n");
  }

  Net::PcapUtils::loop(\&process_pkt);

=head1 TODO

=over

=item Implement C<encode()> function

=back

=head1 COPYRIGHT

Copyright (c) 2001 Tim Potter and Stephanie Wehner.

Copyright (c) 1995,1996,1997,1998,1999 ANU and CSIRO on behalf of
the participants in the CRC for Advanced Computational Systems
('ACSys').

This module is free software.  You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=head1 AUTHOR

Tim Potter E<lt>tpot@samba.orgE<gt>

=cut

__END__


# any real autoloaded methods go after this line

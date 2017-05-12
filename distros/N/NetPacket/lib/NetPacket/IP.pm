package NetPacket::IP;
BEGIN {
  $NetPacket::IP::AUTHORITY = 'cpan:YANICK';
}
# ABSTRACT: Assemble and disassemble IP (Internet Protocol) packets.
$NetPacket::IP::VERSION = '1.6.0';
use strict;
use warnings;

use parent 'NetPacket';

our @EXPORT_OK = qw(ip_strip
		    IP_PROTO_IP IP_PROTO_ICMP IP_PROTO_IGMP
		    IP_PROTO_IPIP IP_PROTO_TCP IP_PROTO_EGP
		    IP_PROTO_EGP IP_PROTO_PUP IP_PROTO_UDP
		    IP_PROTO_IDP IP_PROTO_TP IP_PROTO_DCCP
		    IP_PROTO_IPV6 IP_PROTO_ROUTING IP_PROTO_FRAGMENT
		    IP_PROTO_RSVP IP_PROTO_GRE IP_PROTO_ESP
		    IP_PROTO_AH IP_PROTO_ICMPV6 IP_PROTO_NONE
		    IP_PROTO_DSTOPTS IP_PROTO_MTP IP_PROTO_ENCAP
		    IP_PROTO_PIM IP_PROTO_COMP IP_PROTO_SCTP
		    IP_PROTO_UDPLITE
		    IP_VERSION_IPv4
		    IP_FLAG_MOREFRAGS IP_FLAG_DONTFRAG IP_FLAG_CONGESTION
		    IPTOS_ECN_MASK IPTOS_ECN_NOT_ECT IPTOS_ECN_ECT1
		    IPTOS_ECN_ECT0 IPTOS_ECN_CE
		    IPTOS_DSCP_MASK IPTOS_DSCP_EF
		    IPTOS_DSCP_AF11 IPTOS_DSCP_AF12 IPTOS_DSCP_AF13
		    IPTOS_DSCP_AF21 IPTOS_DSCP_AF22 IPTOS_DSCP_AF23
		    IPTOS_DSCP_AF31 IPTOS_DSCP_AF32 IPTOS_DSCP_AF33
		    IPTOS_DSCP_AF41 IPTOS_DSCP_AF42 IPTOS_DSCP_AF43
		    IPTOS_CLASS_MASK IPTOS_CLASS_DEFAULT
		    IPTOS_CLASS_CS0 IPTOS_CLASS_CS1 IPTOS_CLASS_CS2
		    IPTOS_CLASS_CS3 IPTOS_CLASS_CS4 IPTOS_CLASS_CS5
		    IPTOS_CLASS_CS6 IPTOS_CLASS_CS7
		    IPTOS_PREC_MASK IPTOS_PREC_NETCONTROL
		    IPTOS_PREC_INTERNETCONTROL IPTOS_PREC_CRITIC_ECP
		    IPTOS_PREC_FLASHOVERRIDE IPTOS_PREC_FLASH
		    IPTOS_PREC_IMMEDIATE IPTOS_PREC_PRIORITY
		    IPTOS_PREC_ROUTINE
                    MAXTTL IPDEFTTL IPFRAGTTL IPTTLDEC IP_MSS IP_MAXPACKET
    );

our %EXPORT_TAGS = (
    ALL         => [@EXPORT_OK],
    protos      => [qw(IP_PROTO_IP IP_PROTO_ICMP IP_PROTO_IGMP IP_PROTO_IPIP
		       IP_PROTO_TCP IP_PROTO_EGP IP_PROTO_PUP
		       IP_PROTO_UDP IP_PROTO_IDP IP_PROTO_TP IP_PROTO_DCCP
		       IP_PROTO_IPV6 IP_PROTO_ROUTING IP_PROTO_FRAGMENT
		       IP_PROTO_RSVP IP_PROTO_GRE IP_PROTO_ESP IP_PROTO_AH
		       IP_PROTO_ICMPV6 IP_PROTO_NONE IP_PROTO_DSTOPTS
		       IP_PROTO_MTP IP_PROTO_ENCAP IP_PROTO_PIM IP_PROTO_COMP
		       IP_PROTO_SCTP IP_PROTO_UDPLITE)],
    versions    => [qw(IP_VERSION_IPv4)],
    strip       => [qw(ip_strip)],
    flags       => [qw(IP_FLAG_MOREFRAGS IP_FLAG_DONTFRAG IP_FLAG_CONGESTION)],
    tos         => [qw(IPTOS_ECN_MASK IPTOS_ECN_NOT_ECT IPTOS_ECN_ECT1
		       IPTOS_ECN_ECT0 IPTOS_ECN_CE
		       IPTOS_DSCP_MASK IPTOS_DSCP_EF
		       IPTOS_DSCP_AF11 IPTOS_DSCP_AF12 IPTOS_DSCP_AF13
		       IPTOS_DSCP_AF21 IPTOS_DSCP_AF22 IPTOS_DSCP_AF23
		       IPTOS_DSCP_AF31 IPTOS_DSCP_AF32 IPTOS_DSCP_AF33
		       IPTOS_DSCP_AF41 IPTOS_DSCP_AF42 IPTOS_DSCP_AF43
		       IPTOS_CLASS_MASK IPTOS_CLASS_DEFAULT
		       IPTOS_CLASS_CS0 IPTOS_CLASS_CS1 IPTOS_CLASS_CS2
		       IPTOS_CLASS_CS3 IPTOS_CLASS_CS4 IPTOS_CLASS_CS5
		       IPTOS_CLASS_CS6 IPTOS_CLASS_CS7
		       IPTOS_PREC_MASK IPTOS_PREC_NETCONTROL
		       IPTOS_PREC_INTERNETCONTROL IPTOS_PREC_CRITIC_ECP
		       IPTOS_PREC_FLASHOVERRIDE IPTOS_PREC_FLASH
		       IPTOS_PREC_IMMEDIATE IPTOS_PREC_PRIORITY
		       IPTOS_PREC_ROUTINE)],
    misc        => [qw(MAXTTL IPDEFTTL IPFRAGTTL IPTTLDEC IP_MSS
                       IP_MAXPACKET)],
    );

#
# Partial list of IP protocol values from RFC 1700
#

use constant IP_PROTO_IP   => 0;       # Dummy protocol for TCP
use constant IP_PROTO_ICMP => 1;       # Internet Control Message Protocol
use constant IP_PROTO_IGMP => 2;       # Internet Group Management Protocol
use constant IP_PROTO_IPIP => 4;       # IP in IP encapsulation
use constant IP_PROTO_TCP  => 6;       # Transmission Control Protocol
use constant IP_PROTO_EGP  => 8;       # Exterior Gateway Protocol
use constant IP_PROTO_PUP  => 12;      # PUP protocol
use constant IP_PROTO_UDP  => 17;      # User Datagram Protocol
use constant IP_PROTO_IDP  => 22;      # XNS IDP Protocol
use constant IP_PROTO_TP   => 29;      # SO Transport Protocol Class 4
use constant IP_PROTO_DCCP => 33;      # Datagram Congestion Control Protocol
use constant IP_PROTO_IPV6 => 41;      # IPv6 header
use constant IP_PROTO_ROUTING => 43;   # IPv6 routing header
use constant IP_PROTO_FRAGMENT => 44;  # IPv6 fragmentation header
use constant IP_PROTO_RSVP => 46;      # Reservation Protocol
use constant IP_PROTO_GRE  => 47;      # General Routing Encapsulation
use constant IP_PROTO_ESP  => 50;      # encapsulating security payload
use constant IP_PROTO_AH   => 51;      # authentication header
use constant IP_PROTO_ICMPV6 => 58;    # ICMPv6
use constant IP_PROTO_NONE => 59;      # IPv6 no next header
use constant IP_PROTO_DSTOPTS => 60;   # IPv6 destination options
use constant IP_PROTO_MTP => 92;       # Multicast Transport Protocol
use constant IP_PROTO_ENCAP => 98;     # Encapsulation Header
use constant IP_PROTO_PIM => 103;      # Protocol Independent Multicast
use constant IP_PROTO_COMP => 108;     # Compression Header Protocol
use constant IP_PROTO_SCTP => 132;     # Stream Control Transmission Protocol
use constant IP_PROTO_UDPLITE => 136;  # UDP-Lite protocol


#
# Partial list of IP version numbers from RFC 1700
#

use constant IP_VERSION_IPv4 => 4;     # IP version 4

#
# Flag values
#

use constant IP_FLAG_MOREFRAGS  => 1;     # More fragments coming
use constant IP_FLAG_DONTFRAG   => 2;     # Don't fragment me
use constant IP_FLAG_CONGESTION => 4;     # Congestion present

#
# ToS/DSCP values
#

use constant IPTOS_ECN_MASK     => 0x03;
use constant IPTOS_ECN_NOT_ECT  => 0x00;
use constant IPTOS_ECN_ECT1     => 0x01;
use constant IPTOS_ECN_ECT0     => 0x02;
use constant IPTOS_ECN_CE       => 0x03;

use constant IPTOS_DSCP_MASK    => 0xfc;
use constant IPTOS_DSCP_AF11    => 0x28;
use constant IPTOS_DSCP_AF12    => 0x30;
use constant IPTOS_DSCP_AF13    => 0x38;
use constant IPTOS_DSCP_AF21    => 0x48;
use constant IPTOS_DSCP_AF22    => 0x50;
use constant IPTOS_DSCP_AF23    => 0x58;
use constant IPTOS_DSCP_AF31    => 0x68;
use constant IPTOS_DSCP_AF32    => 0x70;
use constant IPTOS_DSCP_AF33    => 0x78;
use constant IPTOS_DSCP_AF41    => 0x88;
use constant IPTOS_DSCP_AF42    => 0x90;
use constant IPTOS_DSCP_AF43    => 0x98;
use constant IPTOS_DSCP_EF      => 0xb8;

use constant IPTOS_CLASS_MASK   => 0xe0;
use constant IPTOS_CLASS_CS0    => 0x00;
use constant IPTOS_CLASS_CS1    => 0x20;
use constant IPTOS_CLASS_CS2    => 0x40;
use constant IPTOS_CLASS_CS3    => 0x60;
use constant IPTOS_CLASS_CS4    => 0x80;
use constant IPTOS_CLASS_CS5    => 0xa0;
use constant IPTOS_CLASS_CS6    => 0xc0;
use constant IPTOS_CLASS_CS7    => 0xe0;
use constant IPTOS_CLASS_DEFAULT => 0x00;

use constant IPTOS_PREC_MASK    => 0xe0;
use constant IPTOS_PREC_NETCONTROL => 0xe0;
use constant IPTOS_PREC_INTERNETCONTROL => 0xc0;
use constant IPTOS_PREC_CRITIC_ECP => 0x0a;
use constant IPTOS_PREC_FLASHOVERRIDE => 0x80;
use constant IPTOS_PREC_FLASH   => 0x60;
use constant IPTOS_PREC_IMMEDIATE => 0x40;
use constant IPTOS_PREC_PRIORITY => 0x20;
use constant IPTOS_PREC_ROUTINE => 0x00;

# TTL values
use constant MAXTTL             => 255;
use constant IPDEFTTL           => 64;
use constant IPFRAGTTL          => 60;
use constant IPTTLDEC           => 1;

use constant IP_MSS             => 576;

# Maximum IP Packet size
use constant IP_MAXPACKET => 65535;

# Convert 32-bit IP address to dotted quad notation

sub to_dotquad {
    my($net) = @_ ;
    my($na, $nb, $nc, $nd);

    $na = $net >> 24 & 255;
    $nb = $net >> 16 & 255;
    $nc = $net >>  8 & 255;
    $nd = $net & 255;

    return ("$na.$nb.$nc.$nd");
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

    # Decode IP packet

    if (defined($pkt)) {
	my $tmp;

	($tmp, $self->{tos},$self->{len}, $self->{id}, $self->{foffset},
	 $self->{ttl}, $self->{proto}, $self->{cksum}, $self->{src_ip},
	 $self->{dest_ip}, $self->{options}) = unpack('CCnnnCCnNNa*' , $pkt);

	# Extract bit fields
	
	$self->{ver} = ($tmp & 0xf0) >> 4;
	$self->{hlen} = $tmp & 0x0f;
	
	$self->{flags} = $self->{foffset} >> 13;
	$self->{foffset} = ($self->{foffset} & 0x1fff) << 3;

	# Decode variable length header options and remaining data in field

	my $olen = $self->{hlen} - 5;
	$olen = 0 if $olen < 0;  # Check for bad hlen

	# Option length is number of 32 bit words

        $olen = $olen * 4;

	($self->{options}, $self->{data}) = unpack("a" . $olen .
						   "a*", $self->{options});

    my $length = $self->{hlen};
    $length = 5 if $length < 5;  # precaution against bad header

    # truncate data to the length given by the header
    $self->{data} = substr $self->{data}, 0, $self->{len} - 4 * $length;

	# Convert 32 bit ip addresses to dotted quad notation

	$self->{src_ip} = to_dotquad($self->{src_ip});
	$self->{dest_ip} = to_dotquad($self->{dest_ip});
    }

    return bless $self, $class;
}

#
# Strip header from packet and return the data contained in it
#

undef &ip_strip;           # Create ip_strip alias
*ip_strip = \&strip;

sub strip {
    my ($pkt) = @_;

    my $ip_obj = NetPacket::IP->decode($pkt);
    return $ip_obj->{data};
}   

#
# Encode a packet
#

sub encode {

    my $self = shift;
    my ($hdr,$packet,$zero,$tmp,$offset);
    my ($src_ip, $dest_ip);

    # create a zero variable
    $zero = 0;

    # adjust the length of the packet 
    $self->{len} = ($self->{hlen} * 4) + length($self->{data});

    $tmp = $self->{hlen} & 0x0f;
    $tmp = $tmp | (($self->{ver} << 4) & 0xf0);

    $offset = $self->{flags} << 13;
    $offset = $offset | (($self->{foffset} >> 3) & 0x1fff);

    # convert the src and dst ip
    $src_ip = gethostbyname($self->{src_ip});
    $dest_ip = gethostbyname($self->{dest_ip});

    my $fmt = 'CCnnnCCna4a4a*';
    my @pkt = ($tmp, $self->{tos},$self->{len}, 
               $self->{id}, $offset, $self->{ttl}, $self->{proto}, 
               $zero, $src_ip, $dest_ip); 
    # change format and package in case of IP options 
    if(defined $self->{options}){ 
        $fmt = 'CCnnnCCna4a4a*a*'; 
        push(@pkt, $self->{options}); 
    }

    # construct header to calculate the checksum
    $hdr = pack($fmt, @pkt);
    $self->{cksum} = NetPacket::htons(NetPacket::in_cksum($hdr));
    $pkt[7] = $self->{cksum};

    # make the entire packet
    if(defined $self->{data}){
        push(@pkt, $self->{data}); 
    } 
    $packet = pack($fmt, @pkt);

    return($packet);
}

#
# Module initialisation
#

1;

# autoloaded methods go after the END token (&& pod) below

=pod

=head1 NAME

NetPacket::IP - Assemble and disassemble IP (Internet Protocol) packets.

=head1 VERSION

version 1.6.0

=head1 SYNOPSIS

  use NetPacket::IP;

  $ip_obj = NetPacket::IP->decode($raw_pkt);
  $ip_pkt = NetPacket::IP->encode($ip_obj);
  $ip_data = NetPacket::IP::strip($raw_pkt);

=head1 DESCRIPTION

C<NetPacket::IP> provides a set of routines for assembling and
disassembling packets using IP (Internet Protocol).  

=head2 Methods

=over

=item C<NetPacket::IP-E<gt>decode([RAW PACKET])>

Decode the raw packet data given and return an object containing
instance data.  This method will quite happily decode garbage input.
It is the responsibility of the programmer to ensure valid packet data
is passed to this method.

=item C<NetPacket::IP-E<gt>encode()>

Return an IP packet encoded with the instance data specified. This
will infer the total length of the packet automatically from the 
payload length and also adjust the checksum.

=back

=head2 Functions

=over

=item C<NetPacket::IP::strip([RAW PACKET])>

Return the encapsulated data (or payload) contained in the IP
packet.  This data is suitable to be used as input for other
C<NetPacket::*> modules.

This function is equivalent to creating an object using the
C<decode()> constructor and returning the C<data> field of that
object.

=back

=head2 Instance data

The instance data for the C<NetPacket::IP> object consists of
the following fields.

=over

=item ver

The IP version number of this packet.

=item hlen

The IP header length of this packet.

=item flags

The IP header flags for this packet.

=item foffset

The IP fragment offset for this packet.

=item tos

The type-of-service for this IP packet.

=item len

The length (including length of header) in bytes for this packet.

=item id

The identification (sequence) number for this IP packet.

=item ttl

The time-to-live value for this packet.

=item proto

The IP protocol number for this packet.

=item cksum

The IP checksum value for this packet.

=item src_ip

The source IP address for this packet in dotted-quad notation.

=item dest_ip

The destination IP address for this packet in dotted-quad notation.

=item options

Any IP options for this packet.

=item data

The encapsulated data (payload) for this IP packet.

=back

=head2 Exports

=over

=item default

none

=item exportable

IP_PROTO_IP IP_PROTO_ICMP IP_PROTO_IGMP IP_PROTO_IPIP IP_PROTO_TCP
IP_PROTO_UDP IP_VERSION_IPv4

=item tags

The following tags group together related exportable items.

=over

=item C<:protos>

IP_PROTO_IP IP_PROTO_ICMP IP_PROTO_IGMP IP_PROTO_IPIP
IP_PROTO_TCP IP_PROTO_UDP

=item C<:versions>

IP_VERSION_IPv4

=item C<:strip>

Import the strip function C<ip_strip>.

=item C<:ALL>

All the above exportable items.

=back

=back

=head1 EXAMPLE

The following script dumps IP frames by IP address and protocol
to standard output.

  #!/usr/bin/perl -w

  use strict;
  use Net::PcapUtils;
  use NetPacket::Ethernet qw(:strip);
  use NetPacket::IP;

  sub process_pkt {
      my ($user, $hdr, $pkt) = @_;

      my $ip_obj = NetPacket::IP->decode(eth_strip($pkt));
      print("$ip_obj->{src_ip}:$ip_obj->{dest_ip} $ip_obj->{proto}\n");
  }

  Net::PcapUtils::loop(\&process_pkt, FILTER => 'ip');

=head1 TODO

=over

=item IP option decoding - currently stored in binary form.

=item Assembly of received fragments

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

Stephanie Wehner E<lt>atrak@itsx.comE<gt>

=cut

__END__


# any real autoloaded methods go after this line

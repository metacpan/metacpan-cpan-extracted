package NetPacket::IPv6;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Assemble and disassemble IPv6 (Internet Protocol version 6) packets.
$NetPacket::IPv6::VERSION = '1.7.1';
use strict;
use warnings;

use parent 'NetPacket';
use NetPacket::IP qw(:protos :tos :misc);
use Socket 1.87 qw(AF_INET6 inet_pton inet_ntop);

our @EXPORT_OK = (qw(ipv6_strip ipv6_extheader),
    @{$NetPacket::IP::EXPORT_TAGS{protos}},
    qw(IP_VERSION_IPv6),
    @{$NetPacket::IP::EXPORT_TAGS{tos}},
    @{$NetPacket::IP::EXPORT_TAGS{misc}},
    qw(IPv6_EXTHEADER_HOPBYHOP IPv6_EXTHEADER_ROUTING IPv6_EXTHEADER_FRAGMENT
       IPv6_EXTHEADER_ESP IPv6_EXTHEADER_AUTH IPv6_EXTHEADER_NONEXT IPv6_EXTHEADER_DESTOPT
       IPv6_EXTHEADER_MOBILITY IPv6_EXTHEADER_HOSTIDENT IPv6_EXTHEADER_SHIM6
       IPv6_EXTHEADER_TESTING1 IPv6_EXTHEADER_TESTING2),
    );

our %EXPORT_TAGS = (
    ALL         => [@EXPORT_OK],
    protos      => [@{$NetPacket::IP::EXPORT_TAGS{protos}}],
    versions    => [qw(IP_VERSION_IPv6)],
    strip       => [qw(ipv6_strip)],
    tos         => [@{$NetPacket::IP::EXPORT_TAGS{tos}}],
    misc        => [@{$NetPacket::IP::EXPORT_TAGS{misc}}],
    extheaders  => [qw(IPv6_EXTHEADER_HOPBYHOP IPv6_EXTHEADER_ROUTING IPv6_EXTHEADER_FRAGMENT
                       IPv6_EXTHEADER_ESP IPv6_EXTHEADER_AUTH IPv6_EXTHEADER_NONEXT IPv6_EXTHEADER_DESTOPT
                       IPv6_EXTHEADER_MOBILITY IPv6_EXTHEADER_HOSTIDENT IPv6_EXTHEADER_SHIM6
                       IPv6_EXTHEADER_TESTING1 IPv6_EXTHEADER_TESTING2)],
    );

#
# Partial list of IP version numbers from RFC 8200
#

use constant IP_VERSION_IPv6 => 6;     # IP version 6

#
# List of IPv6 extension header types from RFC 7045
#

use constant IPv6_EXTHEADER_HOPBYHOP => 0;
use constant IPv6_EXTHEADER_ROUTING => 43;
use constant IPv6_EXTHEADER_FRAGMENT => 44;
use constant IPv6_EXTHEADER_ESP => 50;
use constant IPv6_EXTHEADER_AUTH => 51;
use constant IPv6_EXTHEADER_NONEXT => 59;
use constant IPv6_EXTHEADER_DESTOPT => 60;
use constant IPv6_EXTHEADER_MOBILITY => 135;
use constant IPv6_EXTHEADER_HOSTIDENT => 139;
use constant IPv6_EXTHEADER_SHIM6 => 140;
use constant IPv6_EXTHEADER_TESTING1 => 253;
use constant IPv6_EXTHEADER_TESTING2 => 254;

# Check if the next header is an IPv6 extension header

my %is_extheader = map { ($_ => 1) } 
    IPv6_EXTHEADER_HOPBYHOP, IPv6_EXTHEADER_ROUTING, IPv6_EXTHEADER_FRAGMENT,
    IPv6_EXTHEADER_ESP, IPv6_EXTHEADER_AUTH, IPv6_EXTHEADER_DESTOPT,
    IPv6_EXTHEADER_MOBILITY, IPv6_EXTHEADER_HOSTIDENT, IPv6_EXTHEADER_SHIM6,
    IPv6_EXTHEADER_TESTING1, IPv6_EXTHEADER_TESTING2;

sub ipv6_extheader {
    my($type) = @_;
    return !!exists $is_extheader{$type};
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

    # Decode IPv6 packet

    if (defined($pkt)) {
        (my $tmp, $self->{len}, my $next_header, $self->{hop_limit},
         $self->{src_ip}, $self->{dest_ip}, $self->{data}) = unpack('NnCCa16a16a*', $pkt);

        # Extract bit fields
        $self->{ver} = ($tmp & 0xf0000000) >> 28;
        $self->{traffic_class} = ($tmp & 0x0ff00000) >> 20;
        $self->{flow_label} = $tmp & 0x000fffff;

        # truncate data to the length given by the header
        $self->{data} = substr $self->{data}, 0, $self->{len};

        # Decode extension headers

        $self->{extheaders} = [];
        while (ipv6_extheader($next_header)) {
            my $header_type = $next_header;
            last if $header_type == IPv6_EXTHEADER_NONEXT or $header_type == IPv6_EXTHEADER_ESP;
            my %header = (type => $header_type);
            if ($header_type == IPv6_EXTHEADER_FRAGMENT) {
                ($next_header, undef, $header{data}, $self->{data}) = unpack('CCa6a*', $self->{data});
                $header{len} = 0;
            } else {
                ($next_header, $header{len}, $self->{data}) = unpack('CCa*', $self->{data});
                my $data_len = $header{len} * ($header_type == IPv6_EXTHEADER_AUTH ? 4 : 8) + 6;
                ($header{data}, $self->{data}) = unpack("a${data_len}a*", $self->{data});
            }
            push @{$self->{extheaders}}, \%header;
        }

        $self->{proto} = $next_header;

	    # Convert 128 bit ipv6 addresses to text format

	    $self->{src_ip} = inet_ntop(AF_INET6, $self->{src_ip}) if length($self->{src_ip}) == 16;
	    $self->{dest_ip} = inet_ntop(AF_INET6, $self->{dest_ip}) if length($self->{dest_ip}) == 16;
    }

    return bless $self, $class;
}

#
# Strip header from packet and return the data contained in it
#

undef &ipv6_strip;           # Create ip_strip alias
*ipv6_strip = \&strip;

sub strip {
    my ($pkt) = @_;

    my $ip_obj = NetPacket::IPv6->decode($pkt);
    return $ip_obj->{data};
}   

#
# Encode a packet
#

sub encode {
    my $self = shift;

    # adjust the length of the packet and pack extension headers
    $self->{len} = 0;
    my $extheaders = '';
    my $next_header = $self->{proto};
    foreach my $header (reverse @{$self->{extheaders}}) {
        if ($header->{type} == IPv6_EXTHEADER_FRAGMENT) {
            $self->{len} += 8;
            $header->{data} = substr $header->{data}, 0, 6;
            $header->{len} = 0;
            $extheaders = pack('CCa6a*', $next_header, $header->{len}, $header->{data}, $extheaders);
        } elsif ($header->{type} == IPv6_EXTHEADER_ESP) {
            # Nothing can follow the encrypted ESP extension header
            $self->{data} = $header->{data};
            $extheaders = '';
        } elsif ($header->{type} == IPv6_EXTHEADER_NONEXT) {
            # Nothing can follow the no-next extension header
            $self->{data} = '';
            $extheaders = '';
        } else {
            my $data_bytes = length($header->{data});
            $data_bytes = 6 if $data_bytes < 6;
            $self->{len} += $data_bytes + 2;
            $header->{len} = int(($data_bytes - 6) / ($header->{type} == IPv6_EXTHEADER_AUTH ? 4 : 8));
            $extheaders = pack("CCa${data_bytes}a*", $next_header, $header->{len}, $header->{data}, $extheaders);
        }
        $next_header = $header->{type};
    }

    $self->{len} += length($self->{data});

    my $tmp = $self->{flow_label} & 0x000fffff;
    $tmp |= ($self->{traffic_class} << 20) & 0x0ff00000;
    $tmp |= ($self->{ver} << 28) & 0xf0000000;

    # convert the src and dst ip
    my $src_ip = inet_pton(AF_INET6, $self->{src_ip});
    my $dest_ip = inet_pton(AF_INET6, $self->{dest_ip});

    my $packet = pack('NnCCa16a16', $tmp, $self->{len}, $next_header, $self->{hop_limit}, $src_ip, $dest_ip);
    $packet .= $extheaders;
    $packet .= $self->{data} if defined $self->{data};

    return $packet;
}

sub pseudo_header {
    my $self = shift;
    my ($length, $next_header) = @_;

    my $src_ip = inet_pton(AF_INET6, $self->{src_ip});
    my $dest_ip = inet_pton(AF_INET6, $self->{dest_ip});

    return pack('a16a16Na3C', $src_ip, $dest_ip, $length, 0, $next_header);
}

#
# Module initialisation
#

1;

# autoloaded methods go after the END token (&& pod) below

=pod

=head1 NAME

NetPacket::IPv6 - Assemble and disassemble IPv6 (Internet Protocol version 6) packets.

=head1 VERSION

version 1.7.1

=head1 SYNOPSIS

  use NetPacket::IPv6;

  $ip_obj = NetPacket::IPv6->decode($raw_pkt);
  $ip_pkt = NetPacket::IPv6->encode($ip_obj);
  $ip_data = NetPacket::IPv6::strip($raw_pkt);

=head1 DESCRIPTION

C<NetPacket::IPv6> provides a set of routines for assembling and
disassembling packets using IPv6 (Internet Protocol version 6).

=head2 Methods

=over

=item C<NetPacket::IPv6-E<gt>decode([RAW PACKET])>

Decode the raw packet data given and return an object containing
instance data.  This method will quite happily decode garbage input.
It is the responsibility of the programmer to ensure valid packet data
is passed to this method.

=item C<NetPacket::IPv6-E<gt>encode()>

Return an IPv6 packet encoded with the instance data specified. This
will infer the total length of the packet automatically from the 
payload length and length of any extension headers.

=item C<NetPacket::IPv6-E<gt>pseudo_header([PACKET LENGTH], [PROTOCOL])>

Return an IPv6 "pseudo-header" suitable for computing checksums for
certain upper-level protocols.

=back

=head2 Functions

=over

=item C<NetPacket::IPv6::strip([RAW PACKET])>

Return the encapsulated data (or payload) contained in the IPv6
packet.  This data is suitable to be used as input for other
C<NetPacket::*> modules.

This function is equivalent to creating an object using the
C<decode()> constructor and returning the C<data> field of that
object.

=item C<NetPacket::IPv6::ipv6_extheader([TYPE])>

Return whether the IP protocol type is an IPv6 extension header.

=back

=head2 Instance data

The instance data for the C<NetPacket::IPv6> object consists of
the following fields.

=over

=item ver

The IP version number of this packet.

=item traffic_class

The traffic class of this packet, equivalent to the type-of-service field for
IPv4.

=item flow_label

The flow label of this packet.

=item len

The payload length (including any extension headers) in bytes for this packet.

=item proto

The IP protocol number for this packet.

=item hop_limit

The hop limit for this packet, equivalent to the time-to-live field for IPv4.

=item src_ip

The source IP address for this packet in colon-separated hextet notation.

=item dest_ip

The destination IP address for this packet in colon-separated hextet notation.

=item extheaders

Array of any extension headers for this packet, as a hashref containing the
fields described below. An ESP (Encapsulating Security Payload) header will
not be represented here; as it and any further extension headers and the
payload data will be encrypted, it will be instead represented as the packet
payload data itself, with a protocol number of 50 (C<IPv6_EXTHEADER_ESP>).

=item data

The encapsulated data (payload) for this IPv6 packet.

=back

Extension headers may contain the following fields.

=over

=item type

The extension header type number.

=item len

The extension header length, in 8-byte units, minus the first 8-byte unit.
(For Authentication extension headers, this length is in 4-byte units, minus
the first two 4-byte units.)

=item data

The remaining contents of the extension header following the next-header and
length bytes.

=back

=head2 Exports

=over

=item default

none

=item tags

The following tags group together related exportable items.

=over

=item C<:protos>

=item C<:tos>

=item C<:misc>

Re-exported from L<NetPacket::IP> for convenience.

=item C<:extheaders>

IPv6_EXTHEADER_HOPBYHOP IPv6_EXTHEADER_ROUTING IPv6_EXTHEADER_FRAGMENT
IPv6_EXTHEADER_ESP IPv6_EXTHEADER_AUTH IPv6_EXTHEADER_NONEXT IPv6_EXTHEADER_DESTOPT
IPv6_EXTHEADER_MOBILITY IPv6_EXTHEADER_HOSTIDENT IPv6_EXTHEADER_SHIM6
IPv6_EXTHEADER_TESTING1 IPv6_EXTHEADER_TESTING2

=item C<:versions>

IP_VERSION_IPv6

=item C<:strip>

Import the strip function C<ipv6_strip>.

=item C<:ALL>

All the above exportable items.

=back

=back

=head1 EXAMPLE

The following script dumps IPv6 frames by IP address and protocol
to standard output.

  #!/usr/bin/perl -w

  use strict;
  use Net::PcapUtils;
  use NetPacket::Ethernet qw(:strip);
  use NetPacket::IPv6;

  sub process_pkt {
      my ($user, $hdr, $pkt) = @_;

      my $ip_obj = NetPacket::IPv6->decode(eth_strip($pkt));
      print("$ip_obj->{src_ip}:$ip_obj->{dest_ip} $ip_obj->{proto}\n");
  }

  Net::PcapUtils::loop(\&process_pkt, FILTER => 'ip6');

=head1 TODO

=over

=item More specific keys for well-defined extension headers.

=item Parse routing extension headers to correctly compute upper-level checksums.

=back

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

package NetPacket::ICMP;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Assemble and disassemble ICMP (Internet Control Message Protocol) packets.
$NetPacket::ICMP::VERSION = '1.7.2';
use strict;
use warnings;

use parent 'NetPacket';

our @EXPORT_OK = qw(icmp_strip icmp_infotype
                    ICMP_ECHOREPLY ICMP_UNREACH ICMP_SOURCEQUENCH
                    ICMP_REDIRECT ICMP_ECHO ICMP_ROUTERADVERT
                    ICMP_ROUTERSOLICIT ICMP_TIMXCEED ICMP_PARAMPROB
                    ICMP_TSTAMP ICMP_TSTAMPREPLY ICMP_IREQ ICMP_IREQREPLY
                    ICMP_MASKREQ ICMP_MASKREPLY
                    ICMP_UNREACH_NET ICMP_UNREACH_HOST
                    ICMP_UNREACH_PROTOCOL ICMP_UNREACH_PORT
                    ICMP_UNREACH_NEEDFRAG ICMP_UNREACH_SRCFAIL
                    ICMP_UNREACH_NET_UNKNOWN ICMP_UNREACH_HOST_UNKNOWN
                    ICMP_UNREACH_ISOLATED ICMP_UNREACH_NET_PROHIB
                    ICMP_UNREACH_HOST_PROHIB ICMP_UNREACH_TOSNET
                    ICMP_UNREACH_TOSHOST ICMP_UNREACH_FILTER_PROHIB
                    ICMP_UNREACH_HOST_PRECEDENCE ICMP_UNREACH_PRCEDENCE_CUTOFF
                    ICMP_REDIRECT_NET ICMP_REDIRECT_HOST
                    ICMP_REDIRECT_TOSNET ICMP_REDIRECT_TOSHOST
                    ICMP_TIMXCEED_INTRANS ICMP_TIMXCEED_REASS
                    ICMP_PARAMPROB_OPTABSENT
    );

our %EXPORT_TAGS = (
    ALL         => [@EXPORT_OK],
    types       => [qw(ICMP_ECHOREPLY ICMP_UNREACH ICMP_SOURCEQUENCH
                       ICMP_REDIRECT ICMP_ECHO ICMP_ROUTERADVERT
                       ICMP_ROUTERSOLICIT ICMP_TIMXCEED ICMP_PARAMPROB
                       ICMP_TSTAMP ICMP_TSTAMPREPLY ICMP_IREQ ICMP_IREQREPLY
                       ICMP_MASKREQ ICMP_MASKREPLY)],
    codes       => [qw(ICMP_UNREACH_NET ICMP_UNREACH_HOST
                       ICMP_UNREACH_PROTOCOL ICMP_UNREACH_PORT
                       ICMP_UNREACH_NEEDFRAG ICMP_UNREACH_SRCFAIL
                       ICMP_UNREACH_NET_UNKNOWN ICMP_UNREACH_HOST_UNKNOWN
                       ICMP_UNREACH_ISOLATED ICMP_UNREACH_NET_PROHIB
                       ICMP_UNREACH_HOST_PROHIB ICMP_UNREACH_TOSNET
                       ICMP_UNREACH_TOSHOST ICMP_UNREACH_FILTER_PROHIB
                       ICMP_UNREACH_HOST_PRECEDENCE
                       ICMP_UNREACH_PRCEDENCE_CUTOFF
                       ICMP_REDIRECT_NET ICMP_REDIRECT_HOST
                       ICMP_REDIRECT_TOSNET ICMP_REDIRECT_TOSHOST
                       ICMP_TIMXCEED_INTRANS ICMP_TIMXCEED_REASS
                       ICMP_PARAMPROB_OPTABSENT)],
    strip       => [qw(icmp_strip)],
);

# ICMP Types

use constant ICMP_ECHOREPLY       => 0;
use constant ICMP_UNREACH         => 3;
use constant ICMP_SOURCEQUENCH    => 4;
use constant ICMP_REDIRECT        => 5;
use constant ICMP_ECHO            => 8;
use constant ICMP_ROUTERADVERT    => 9;
use constant ICMP_ROUTERSOLICIT   => 10;
use constant ICMP_TIMXCEED        => 11;
use constant ICMP_PARAMPROB       => 12;
use constant ICMP_TSTAMP          => 13;
use constant ICMP_TSTAMPREPLY     => 14;
use constant ICMP_IREQ            => 15;
use constant ICMP_IREQREPLY       => 16;
use constant ICMP_MASKREQ         => 17;
use constant ICMP_MASKREPLY       => 18;

# Unreachable Codes

use constant ICMP_UNREACH_NET     => 0;
use constant ICMP_UNREACH_HOST    => 1;
use constant ICMP_UNREACH_PROTOCOL => 2;
use constant ICMP_UNREACH_PORT    => 3;
use constant ICMP_UNREACH_NEEDFRAG => 4;
use constant ICMP_UNREACH_SRCFAIL => 5;
use constant ICMP_UNREACH_NET_UNKNOWN => 6;
use constant ICMP_UNREACH_HOST_UNKNOWN => 7;
use constant ICMP_UNREACH_ISOLATED => 8;
use constant ICMP_UNREACH_NET_PROHIB => 9;
use constant ICMP_UNREACH_HOST_PROHIB => 10;
use constant ICMP_UNREACH_TOSNET  => 11;
use constant ICMP_UNREACH_TOSHOST => 12;
use constant ICMP_UNREACH_FILTER_PROHIB => 13;
use constant ICMP_UNREACH_HOST_PRECEDENCE => 14;
use constant ICMP_UNREACH_PRECEDENCE_CUTOFF => 15;

# Redirect Codes

use constant ICMP_REDIRECT_NET    => 0;
use constant ICMP_REDIRECT_HOST   => 1;
use constant ICMP_REDIRECT_TOSNET => 2;
use constant ICMP_REDIRECT_TOSHOST => 3;

# Time-Exceeded Codes

use constant ICMP_TIMXCEED_INTRANS => 0;
use constant ICMP_TIMXCEED_REASS  => 1;

# Parameter-Problem Codes

use constant ICMP_PARAMPROB_OPTABSENT => 1;

#
# Test for informational types
#

sub icmp_infotype {
    my $type = shift;
    return ($type == ICMP_ECHOREPLY || $type == ICMP_ECHO ||
	    $type == ICMP_ROUTERADVERT || $type == ICMP_ROUTERSOLICIT ||
	    $type == ICMP_TSTAMP || $type == ICMP_TSTAMPREPLY ||
	    $type == ICMP_IREQ || $type == ICMP_IREQREPLY ||
	    $type == ICMP_MASKREQ || $type == ICMP_MASKREPLY);
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

    # Decode ICMP packet

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

sub icmpstrip {
  goto \&strip;
}

sub strip {
    my ($pkt) = @_;

    my $icmp_obj = decode($pkt);
    return $icmp_obj->{data};
}

#
# Encode a packet
#

sub encode {
    my $self = shift;
    my ($packet);

    # Checksum the packet
    $self->checksum();

    # Put the packet together
    $packet = pack("CCna*", $self->{type}, $self->{code},
                $self->{cksum}, $self->{data});

    return($packet);
}

#
# Calculate ICMP checksum

sub checksum {
    my $self = shift;
    my ($packet,$zero);

    # Put the packet together for checksumming
    $zero = 0;
    $packet = pack("CCna*", $self->{type}, $self->{code},
                $zero, $self->{data});

    $self->{cksum} = NetPacket::htons(NetPacket::in_cksum($packet));
}


#
# Module initialisation
#

1;

# autoloaded methods go after the END token (&& pod) below

=pod

=head1 NAME

NetPacket::ICMP - Assemble and disassemble ICMP (Internet Control Message Protocol) packets.

=head1 VERSION

version 1.7.2

=head1 SYNOPSIS

  use NetPacket::ICMP;

  $icmp_obj = NetPacket::ICMP->decode($raw_pkt);
  $icmp_pkt = NetPacket::ICMP->encode();
  $icmp_data = NetPacket::ICMP::strip($raw_pkt);

=head1 DESCRIPTION

C<NetPacket::ICMP> provides a set of routines for assembling and
disassembling packets using ICMP (Internet Control Message Protocol).

=head2 Methods

=over

=item C<NetPacket::ICMP-E<gt>decode([RAW PACKET])>

Decode the raw packet data given and return an object containing
instance data.  This method will quite happily decode garbage input.
It is the responsibility of the programmer to ensure valid packet data
is passed to this method.

=item C<NetPacket::ICMP-E<gt>encode()>

Return an ICMP packet encoded with the instance data specified.

=back

=head2 Functions

=over

=item C<NetPacket::ICMP::strip([RAW PACKET])>

Return the encapsulated data (or payload) contained in the ICMP
packet.

=back

=head2 Instance data

The instance data for the C<NetPacket::ICMP> object consists of
the following fields.

=over

=item type

The ICMP message type of this packet.

=item code

The ICMP message code of this packet.

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

ICMP message types:
    ICMP_ECHOREPLY ICMP_UNREACH ICMP_SOURCEQUENCH
    ICMP_REDIRECT ICMP_ECHO ICMP_ROUTERADVERT
    ICMP_ROUTERSOLICIT ICMP_TIMXCEED ICMP_PARAMPROB
    ICMP_TSTAMP ICMP_TSTAMPREPLY ICMP_IREQ ICMP_IREQREPLY
    ICMP_MASKREQ ICMP_MASKREPLY

=item tags

The following tags group together related exportable items.

=over

=item C<:types>

  ICMP_ECHOREPLY ICMP_UNREACH ICMP_SOURCEQUENCH
  ICMP_REDIRECT ICMP_ECHO ICMP_ROUTERADVERT
  ICMP_ROUTERSOLICIT ICMP_TIMXCEED ICMP_PARAMPROB
  ICMP_TSTAMP ICMP_TSTAMPREPLY ICMP_IREQ
  ICMP_IREQREPLY ICMP_MASKREQ ICMP_MASKREPLY

=item C<:strip>

Import the strip function C<icmp_strip>.

=item C<:ALL>

All the above exportable items.

=back

=back

=head1 EXAMPLE

The following example prints the ICMP type, code, and checksum
fields.

  #!/usr/bin/perl -w

  use strict;
  use Net::PcapUtils;
  use NetPacket::Ethernet qw(:strip);
  use NetPacket::IP qw(:strip);
  use NetPacket::ICMP;

  sub process_pkt {
      my ($user, $hdr, $pkt) = @_;

      my $ip_obj = NetPacket::IP->decode(eth_strip($pkt));
      my $icmp_obj = NetPacket::ICMP->decode(ip_strip($ip_obj));

      print("Type: $icmp_obj->{type}\n");
      print("Code: $icmp_obj->{code}\n");
      print("Checksum: $icmp_obj->{cksum}\n\n");
  }

  Net::PcapUtils::loop(\&process_pkt, FILTER => 'icmp');

=head1 TODO

=over

=item Create constants

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

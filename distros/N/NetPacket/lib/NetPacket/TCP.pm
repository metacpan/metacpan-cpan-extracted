package NetPacket::TCP;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Assemble and disassemble TCP (Transmission Control Protocol) packets.
$NetPacket::TCP::VERSION = '1.7.1';
use strict;
use warnings;

use parent 'NetPacket';

# TCP Flags

use constant FIN => 0x01;
use constant SYN => 0x02;
use constant RST => 0x04;
use constant PSH => 0x08;
use constant ACK => 0x10;
use constant URG => 0x20;
use constant ECE => 0x40;
use constant CWR => 0x80;

our @EXPORT = qw(FIN SYN RST PSH ACK URG ECE CWR);

our @EXPORT_OK = qw(tcp_strip );

our %EXPORT_TAGS = (
    ALL         => [@EXPORT, @EXPORT_OK],
    strip       => [qw(tcp_strip)],  
);

#
# Strip header from packet and return the data contained in it
#

sub tcp_strip {
  goto \&strip;
}

sub strip {
    my ($pkt) = @_;

    my $tcp_obj = NetPacket::TCP->decode($pkt);
    return $tcp_obj->{data};
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

    # Decode TCP packet

    if (defined($pkt)) {
	my $tmp;

	($self->{src_port}, $self->{dest_port}, $self->{seqnum}, 
	 $self->{acknum}, $tmp, $self->{winsize}, $self->{cksum}, 
	 $self->{urg}, $self->{options}) =
	     unpack("nnNNnnnna*", $pkt);

	# Extract flags
	
	$self->{hlen}     = ($tmp & 0xf000) >> 12;
	$self->{reserved} = ($tmp & 0x0f00) >> 8;
	$self->{flags}    =  $tmp & 0x00ff;
	
	# Decode variable length header and remaining data

	my $olen = $self->{hlen} - 5;
	$olen = 0 if $olen < 0;  # Check for bad hlen

        # Option length is number of 32 bit words

    $olen *= 4;

	( $self->{options}, $self->{data} ) 
        = unpack( 'a' . $olen .  'a*', $self->{options});
    }

    # Return a blessed object

    bless($self, $class);
    return $self;
}

#
# Encode a packet
#

sub encode {

    my $self = shift;
    my ($ip) = @_;
    my ($packet,$tmp);

    # First of all, fix the checksum
    $self->checksum($ip);

    $tmp = $self->{hlen} << 12;
    $tmp = $tmp | (0x0f00 & ($self->{reserved} << 8));
    $tmp = $tmp | (0x00ff & $self->{flags});

    # Put the packet together
    $packet = pack('n n N N n n n n a* a*',
            $self->{src_port}, $self->{dest_port}, $self->{seqnum},
            $self->{acknum}, $tmp, $self->{winsize}, $self->{cksum},
            $self->{urg}, $self->{options},$self->{data});


    return($packet);

}

#
# TCP Checksum
#

sub checksum {

    my $self = shift;
    my ($ip) = @_;
    my ($packet,$zero,$tcplen,$tmp);
    my ($src_ip, $dest_ip,$proto);

    $zero = 0;
    $proto = 6;
    $tcplen = ($self->{hlen} * 4)+ length($self->{data});

    no warnings qw/ uninitialized /;
    $tmp = $self->{hlen} << 12;
    $tmp = $tmp | (0x0f00 & ($self->{reserved} << 8));
    $tmp = $tmp | (0x00ff & $self->{flags});

    # Pack pseudo-header for tcp checksum

    if ($ip->isa('NetPacket::IPv6')) {
        $packet = $ip->pseudo_header($tcplen, $proto);
    } else {
        $src_ip = gethostbyname($ip->{src_ip});
        $dest_ip = gethostbyname($ip->{dest_ip});

        $packet = pack('a4a4nn',$src_ip,$dest_ip,$proto,$tcplen);
    }

    $packet .= pack('nnNNnnnna*a*',
        $self->{src_port}, $self->{dest_port}, $self->{seqnum},
        $self->{acknum}, $tmp, $self->{winsize}, $zero,
        $self->{urg}, $self->{options},$self->{data});

    # pad packet if odd-sized
    $packet .= "\x00" if length( $packet ) % 2;

    $self->{cksum} = NetPacket::htons(NetPacket::in_cksum($packet));
}

sub parse_tcp_options {
  #
  # dissect tcp options header. see:
  # http://www.networksorcery.com/enp/protocol/tcp.htm#Options
  #
  # we create an byte array from the options header
  # and iterate through that. If we find an option
  # kind number we act accordingly (sometimes it has
  # a fixed length, sometimes a variable one).
  # once we've got the option stored, we shift the
  # bytes we fetched away from the byte array and
  # re-enter the loop.

  my $self = shift;

  my $opts = $self->{options};
  my @bytes = split //, $opts;
  my %options;
  my $size;
 ENTRY:
  $size = $#bytes;
  foreach my $byte (@bytes) {
    my $kind = unpack('C', $byte);
    if($kind == 2) {
      # MSS.
      # next byte is size, set to 4
      # next 2 bytes are mss value 16 bit unsigned short
      $options{mss} = unpack('n', $bytes[2] . $bytes[3]);
      shift @bytes;
      shift @bytes;
      shift @bytes;
      shift @bytes;
      goto ENTRY;
    }
    elsif ($kind == 1) {
      # a noop
      shift @bytes;
      goto ENTRY;
    }
    elsif ($kind == 3) {
      # Windows Scale Factor
      # next byte is size, set to 3
      # next byte is shift count, 8 bit unsigned
      $options{ws} = unpack('C', $bytes[2]);
      shift @bytes;
      shift @bytes;
      shift @bytes;
      goto ENTRY;
    }
    elsif ($kind == 4) {
      # SACK Permitted
      # next byte is length
      $options{sack} = unpack('C', $bytes[1]);
      shift @bytes;
      shift @bytes;
      goto ENTRY;
    }
    elsif ($kind == 5) {
      # SACK Blocks
      # next byte is length, 2 + (number of blocks * 8)
      # in every block,
      # former 4 bytes is SACK left edge, 32 bit unsigned int
      # latter 4 bytes is SACK right edge, 32 bit unsigned int
      my $block_num = (unpack('C', $bytes[1]) - 2) / 8;
      shift @bytes;
      shift @bytes;
      my @sack_blocks;
      for (1..$block_num) {
        push @sack_blocks, [unpack('N', join '', @bytes[0..3]),
                            unpack('N', join '', @bytes[4..7])];
        shift @bytes;
        shift @bytes;
        shift @bytes;
        shift @bytes;
        shift @bytes;
        shift @bytes;
        shift @bytes;
        shift @bytes;
      }
      $options{sack_blocks} = \@sack_blocks;
    }
    elsif ($kind == 8) {
      # timestamp
      # next byte is length, set to 10
      # next 4 byte is timestamp, 32 bit unsigned int
      # next 4 byte is timestamp echo reply, 32 bit unsigned int 
      $options{ts} = unpack('N', join '', @bytes[2..5]); 
      $options{er} = unpack('N', join '', @bytes[6,7,8,9]);
      shift @bytes;
      shift @bytes;
      shift @bytes;
      shift @bytes;
      shift @bytes;
      shift @bytes;
      shift @bytes;
      shift @bytes;
      shift @bytes;
      shift @bytes;
      goto ENTRY;
    }
  }
  return wantarray ? %options : \%options;
}
#
# Module initialisation
#

1;

# autoloaded methods go after the END token (&& pod) below

__END__

=pod

=head1 NAME

NetPacket::TCP - Assemble and disassemble TCP (Transmission Control Protocol) packets.

=head1 VERSION

version 1.7.1

=head1 SYNOPSIS

  use NetPacket::TCP;

  $tcp_obj = NetPacket::TCP->decode($raw_pkt);
  $tcp_pkt = $tcp_obj->encode($ip_pkt);
  $tcp_data = NetPacket::TCP::strip($raw_pkt);

=head1 DESCRIPTION

C<NetPacket::TCP> provides a set of routines for assembling and
disassembling packets using TCP (Transmission Control Protocol).  

=head2 Methods

=over

=item C<NetPacket::TCP-E<gt>decode([RAW PACKET])>

Decode the raw packet data given and return an object containing
instance data.  This method will quite happily decode garbage input.
It is the responsibility of the programmer to ensure valid packet data
is passed to this method.

=item C<NetPacket::TCP-E<gt>encode($ip_obj)>

Return a TCP packet encoded with the instance data specified. 
Needs parts of the ip header contained in $ip_obj in order to calculate
the TCP checksum. 

=item C<$packet-E<gt>parse_tcp_options>

Returns a hash (or a hash ref in scalar context) contaning the packet's options.

For now the method only recognizes well-known and widely
used options (MSS, noop, windows scale factor, SACK permitted, SACK,
timestamp).
If the packet contains options unknown to the method, it may fail.

=back

=head2 Functions

=over

=item C<NetPacket::TCP::strip([RAW PACKET])>

Return the encapsulated data (or payload) contained in the TCP
packet.  This data is suitable to be used as input for other
C<NetPacket::*> modules.

This function is equivalent to creating an object using the
C<decode()> constructor and returning the C<data> field of that
object.

=back

=head2 Instance data

The instance data for the C<NetPacket::TCP> object consists of
the following fields.

=over

=item src_port

The source TCP port for the packet.

=item dest_port

The destination TCP port for the packet.

=item seqnum

The TCP sequence number for this packet.

=item acknum

The TCP acknowledgement number for this packet.

=item hlen

The header length for this packet.

=item reserved

The 6-bit "reserved" space in the TCP header.

=item flags

Contains the urg, ack, psh, rst, syn, fin, ece and cwr flags for this packet.

=item winsize

The TCP window size for this packet.

=item cksum

The TCP checksum.

=item urg

The TCP urgent pointer.

=item options

Any TCP options for this packet in binary form.

=item data

The encapsulated data (payload) for this packet.

=back

=head2 Exports

=over

=item default

FIN SYN RST PSH ACK URG ECE CWR Can be used to set the appropriate flag.

=item exportable

tcp_strip

=item tags

The following tags group together related exportable items.

=over

=item C<:strip>

Import the strip function C<tcp_strip>.

=item C<:ALL>

All the above exportable items.

=back

=back

=head1 EXAMPLE

The following script is a primitive pop3 sniffer.

  #!/usr/bin/perl -w

  use strict;
  use Net::PcapUtils;
  use NetPacket::Ethernet qw(:strip);
  use NetPacket::IP qw(:strip);
  use NetPacket::TCP;

  sub process_pkt {
      my($arg, $hdr, $pkt) = @_;

      my $tcp_obj = NetPacket::TCP->decode(ip_strip(eth_strip($pkt)));

      if (($tcp_obj->{src_port} == 110) or ($tcp_obj->{dest_port} == 110)) {
	  print($tcp_obj->{data});
      }
  }

  Net::PcapUtils::loop(\&process_pkt, FILTER => 'tcp');

The following uses NetPacket together with Net::Divert to add a syn
flag to all TCP packets passing through:

  #!/usr/bin/perl

  use Net::Divert;
  use NetPacket::IP qw(IP_PROTO_TCP);
  use NetPacket::TCP;


  $divobj = Net::Divert->new('yourhostname',9999);

  $divobj->getPackets(\&alterPacket);

  sub alterPacket {
      my($packet,$fwtag) = @_;

      # decode the IP header
      $ip_obj = NetPacket::IP->decode($packet);

      # check if this is a TCP packet
      if($ip_obj->{proto} == IP_PROTO_TCP) {

          # decode the TCP header
          $tcp_obj = NetPacket::TCP->decode($ip_obj->{data});

          # set the syn flag
          $tcp_obj->{flags} |= SYN;

          # construct the new ip packet
          $ip_obj->{data} = $tcp_obj->encode($ip_obj);
          $packet = $ip_obj->encode;

      }

      # write it back out
      $divobj->putPacket($packet,$fwtag);
   }

=head1 TODO

=over

=item Assembly of TCP fragments into a data stream

=item Option processing

=item Nicer processing of TCP flags

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

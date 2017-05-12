#!/usr/bin/perl

=head1 NAME

Nagios::NRPE::Packet - Assembly and de-assembly of an NRPE packet

=head1 SYNOPSIS

 use IO::Socket;
 use IO::Socket::INET;
 # Import necessary constants into Namespace
 use Nagios::NRPE::Packet qw(NRPE_PACKET_VERSION_2
		             NRPE_PACKET_QUERY
		             MAX_PACKETBUFFER_LENGTH
		             STATE_UNKNOWN
		             STATE_CRITICAL
		             STATE_WARNING
		             STATE_OK);

 my $packet = Nagios::NRPE::Packet->new();

 my $socket = IO::Socket::INET->new(
                    PeerAddr => $host,
                    PeerPort => $port,
                    Proto    => 'tcp',
                    Type     => SOCK_STREAM) or die "ERROR: $@ \n";

 print $socket $packet->assemble(type => QUERY_PACKET,
                              buffer => "check_load 1 2 3",
                              version => NRPE_PACKET_VERSION_2 );

 my $data = <$socket>
 my $response = $packet->deassemble($data);

 print $response->{buffer};

=head1 DESCRIPTION

This class is meant to be used when an active connection exists and is ready to send the
packet.

=head1 CONSTRUCTION

=over

=item new

Takes the following options as a hashref

=back

=head1 FUNCTIONS

Following functions can be used after the creation of the packet

=over 2

=item * assemble

Takes a hash of options defining the packet to be sent and returns the assembled packet. You can print this
to an open socket and send it to either a server or the client depending on your situation.

 check

A string defining the check to be run or the output of a check eg: "check_cpu"
NOTE: Nagios can accept arguments appended to the check in the form: "check_somecheck!ARG1!ARG2!ARG..."

 version

The NRPE version you want to use (currently only V2 is accepted).

See CONSTANTS for options here.

 type

The TYPE of packet you wish to send, which is either QUERY or RESPONSE.

See CONSTANTS for options here.

 result_code

This is a curios value as it seems to have no apparent affect on neither the server nor the client.

A set value is 2324.

=item * deassemble

Takes a packet recieved by either client or server and deassembles them. The returned hashref contains 
the following values:

=item * packet_type

 crc32_value
 result_code
 buffer

=item * validate($packet)

Validates the contents of a packet using CRC32 checksumming. Returns undef
if not succesful.

=back

=head1 CONSTANTS

These constants can be exported upon request with the 'use' pragma like this:

 # Will only import the constant NRPE_PACKET_VERSION_2 into your namespace
 use Nagios::NRPE::Packet qw(NRPE_PACKET_VERSION_2);

=over 2

=item * NRPE_PACKET_VERSION_3
        NRPE_PACKET_VERSION_2
        NRPE_PACKET_VERSION_1

The value of the NRPE version you want/need to use.

=item * QUERY_PACKET
        RESPONSE_PACKET

The packet type you want to send or recieve

=item * MAX_PACKETBUFFER_LENGTH
        MAX_COMMAND_ARGUMENTS

A threshhold on the send data

=item * NRPE_HELLO_COMMAND

unknown

=item * DEFAULT_SOCKET_TIMEOUT
        DEFAULT_CONNECTION_TIMEOUT

The default timeout for a connection and its corresponding socket

=item * STATE_UNKNOWN
        STATE_CRITICAL
        STATE_WARNING
        STATE_OK

States returned by the check

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Andreas Marschke <andreas.marschke@googlemail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Nagios::NRPE::Packet;

our $VERSION = '0.003';

use 5.010_000;
require Exporter;
require overload;

BEGIN {
  @ISA = qw(Exporter);
  @EXPORT_OK = qw(NRPE_PACKET_VERSION_3
		  NRPE_PACKET_VERSION_2
		  NRPE_PACKET_VERSION_1
		  NRPE_PACKET_QUERY
		  NRPE_PACKET_RESPONSE
		  MAX_PACKETBUFFER_LENGTH
		  MAX_COMMAND_ARGUMENTS
		  NRPE_HELLO_COMMAND
		  DEFAULT_SOCKET_TIMEOUT
		  DEFAULT_CONNECTION_TIMEOUT
		  STATE_UNKNOWN
		  STATE_CRITICAL
		  STATE_WARNING
		  STATE_OK);
}

use warnings;
use strict;

use Carp;
use Convert::Binary::C;
use constant {
  # packet version identifier
  NRPE_PACKET_VERSION_3   =>  3,
  NRPE_PACKET_VERSION_2   =>  2,
  NRPE_PACKET_VERSION_1   =>  1,

  # id code for queries and responses to queries
  NRPE_PACKET_QUERY            =>  1,
  NRPE_PACKET_RESPONSE         =>  2,

  # max amount of data we'll send in one query/response
  MAX_PACKETBUFFER_LENGTH => 1024,
  MAX_COMMAND_ARGUMENTS   => 16,
  NRPE_HELLO_COMMAND      => "_NRPE_CHECK",
  DEFAULT_SOCKET_TIMEOUT  => 10,
  DEFAULT_CONNECTION_TIMEOUT => 300,

  # /* service state return codes */
  STATE_UNKNOWN           => 3,
  STATE_CRITICAL          => 2,
  STATE_WARNING 	  => 1,
  STATE_OK                => 0,
};

sub new {
  my ($class, %options) = @_;
  my $self = {};

# taken with modifications from common.h in nagios-nrpe
  my $c = Convert::Binary::C->new(ByteOrder => 'BigEndian', Alignment => 2);
  $c->parse(<<PACKET_STRUCT);
struct Packet{
  unsigned short   packet_version;
  unsigned short   packet_type;
  unsigned int     crc32_value;
  unsigned short   result_code;
  char             buffer[1026];
};
PACKET_STRUCT
  $c->tag('Packet.buffer', Format => 'String');
  $self->{c} = $c;
  bless $self,$class;
}

sub assemble{
  my ($self,%options) = @_;
  my $unpacked = {};
  croak "ERROR: Cannot send Packet with empty buffer!" if (not defined $options{check});

  $unpacked->{buffer}         = $options{check};
  $unpacked->{packet_version} = $options{version} || NRPE_PACKET_VERSION_2;
  $unpacked->{packet_type}    = $options{type}    || NRPE_PACKET_QUERY;
  $unpacked->{crc32_value}    = "\x00\x00\x00\x00";
  $unpacked->{result_code}    = $options{result_code}    || 2324;

  my $packed = $self->{c}->pack('Packet',$unpacked);

  $unpacked->{crc32_value} = ~ crc32($packed);

  return $self->{c}->pack('Packet',$unpacked);
}

sub validate {
  my ($self,$packet) = @_;
  packet_dump($packet);
  my $unpacked = $self->{c}->unpack('Packet',$packet);
  my $checksum = $unpacked->{crc32_value};
  packet_dump($checksum);
  $unpacked->{crc32_value} = "\x00\x00\x00\x00";
  my $packed = $self->{c}->pack('Packet',$unpacked);
  if (not ~ crc32($packed) eq $checksum) {
    return undef;
  }else {
    return 1;
  }
}

sub deassemble{
  my ($self,$packet) = @_;
  my $unpacked = $self->{c}->unpack('Packet',$packet);
  return $unpacked;
}

=pod

=over

=item crc32

Checksumming for the packet. Necessary for sending a valid Packet.

=back

=cut

# These functions are derived from http://www.stic-online.de/stic/html/nrpe-generic.html
# Copyright (C) 2006, 2007 STIC GmbH, http://www.stic-online.de
# Licensed under GPLv2
sub crc32 {
  my $crc;
  my $len;
  my $i;
  my $index;
  my @args;
  my ($arg) = @_;
  my @crc_table =(
    0x00000000, 0x77073096, 0xee0e612c, 0x990951ba, 0x076dc419,
    0x706af48f, 0xe963a535, 0x9e6495a3, 0x0edb8832, 0x79dcb8a4,
    0xe0d5e91e, 0x97d2d988, 0x09b64c2b, 0x7eb17cbd, 0xe7b82d07,
    0x90bf1d91, 0x1db71064, 0x6ab020f2, 0xf3b97148, 0x84be41de,
    0x1adad47d, 0x6ddde4eb, 0xf4d4b551, 0x83d385c7, 0x136c9856,
    0x646ba8c0, 0xfd62f97a, 0x8a65c9ec, 0x14015c4f, 0x63066cd9,
    0xfa0f3d63, 0x8d080df5, 0x3b6e20c8, 0x4c69105e, 0xd56041e4,
    0xa2677172, 0x3c03e4d1, 0x4b04d447, 0xd20d85fd, 0xa50ab56b,
    0x35b5a8fa, 0x42b2986c, 0xdbbbc9d6, 0xacbcf940, 0x32d86ce3,
    0x45df5c75, 0xdcd60dcf, 0xabd13d59, 0x26d930ac, 0x51de003a,
    0xc8d75180, 0xbfd06116, 0x21b4f4b5, 0x56b3c423, 0xcfba9599,
    0xb8bda50f, 0x2802b89e, 0x5f058808, 0xc60cd9b2, 0xb10be924,
    0x2f6f7c87, 0x58684c11, 0xc1611dab, 0xb6662d3d, 0x76dc4190,
    0x01db7106, 0x98d220bc, 0xefd5102a, 0x71b18589, 0x06b6b51f,
    0x9fbfe4a5, 0xe8b8d433, 0x7807c9a2, 0x0f00f934, 0x9609a88e,
    0xe10e9818, 0x7f6a0dbb, 0x086d3d2d, 0x91646c97, 0xe6635c01,
    0x6b6b51f4, 0x1c6c6162, 0x856530d8, 0xf262004e, 0x6c0695ed,
    0x1b01a57b, 0x8208f4c1, 0xf50fc457, 0x65b0d9c6, 0x12b7e950,
    0x8bbeb8ea, 0xfcb9887c, 0x62dd1ddf, 0x15da2d49, 0x8cd37cf3,
    0xfbd44c65, 0x4db26158, 0x3ab551ce, 0xa3bc0074, 0xd4bb30e2,
    0x4adfa541, 0x3dd895d7, 0xa4d1c46d, 0xd3d6f4fb, 0x4369e96a,
    0x346ed9fc, 0xad678846, 0xda60b8d0, 0x44042d73, 0x33031de5,
    0xaa0a4c5f, 0xdd0d7cc9, 0x5005713c, 0x270241aa, 0xbe0b1010,
    0xc90c2086, 0x5768b525, 0x206f85b3, 0xb966d409, 0xce61e49f,
    0x5edef90e, 0x29d9c998, 0xb0d09822, 0xc7d7a8b4, 0x59b33d17,
    0x2eb40d81, 0xb7bd5c3b, 0xc0ba6cad, 0xedb88320, 0x9abfb3b6,
    0x03b6e20c, 0x74b1d29a, 0xead54739, 0x9dd277af, 0x04db2615,
    0x73dc1683, 0xe3630b12, 0x94643b84, 0x0d6d6a3e, 0x7a6a5aa8,
    0xe40ecf0b, 0x9309ff9d, 0x0a00ae27, 0x7d079eb1, 0xf00f9344,
    0x8708a3d2, 0x1e01f268, 0x6906c2fe, 0xf762575d, 0x806567cb,
    0x196c3671, 0x6e6b06e7, 0xfed41b76, 0x89d32be0, 0x10da7a5a,
    0x67dd4acc, 0xf9b9df6f, 0x8ebeeff9, 0x17b7be43, 0x60b08ed5,
    0xd6d6a3e8, 0xa1d1937e, 0x38d8c2c4, 0x4fdff252, 0xd1bb67f1,
    0xa6bc5767, 0x3fb506dd, 0x48b2364b, 0xd80d2bda, 0xaf0a1b4c,
    0x36034af6, 0x41047a60, 0xdf60efc3, 0xa867df55, 0x316e8eef,
    0x4669be79, 0xcb61b38c, 0xbc66831a, 0x256fd2a0, 0x5268e236,
    0xcc0c7795, 0xbb0b4703, 0x220216b9, 0x5505262f, 0xc5ba3bbe,
    0xb2bd0b28, 0x2bb45a92, 0x5cb36a04, 0xc2d7ffa7, 0xb5d0cf31,
    0x2cd99e8b, 0x5bdeae1d, 0x9b64c2b0, 0xec63f226, 0x756aa39c,
    0x026d930a, 0x9c0906a9, 0xeb0e363f, 0x72076785, 0x05005713,
    0x95bf4a82, 0xe2b87a14, 0x7bb12bae, 0x0cb61b38, 0x92d28e9b,
    0xe5d5be0d, 0x7cdcefb7, 0x0bdbdf21, 0x86d3d2d4, 0xf1d4e242,
    0x68ddb3f8, 0x1fda836e, 0x81be16cd, 0xf6b9265b, 0x6fb077e1,
    0x18b74777, 0x88085ae6, 0xff0f6a70, 0x66063bca, 0x11010b5c,
    0x8f659eff, 0xf862ae69, 0x616bffd3, 0x166ccf45, 0xa00ae278,
    0xd70dd2ee, 0x4e048354, 0x3903b3c2, 0xa7672661, 0xd06016f7,
    0x4969474d, 0x3e6e77db, 0xaed16a4a, 0xd9d65adc, 0x40df0b66,
    0x37d83bf0, 0xa9bcae53, 0xdebb9ec5, 0x47b2cf7f, 0x30b5ffe9,
    0xbdbdf21c, 0xcabac28a, 0x53b39330, 0x24b4a3a6, 0xbad03605,
    0xcdd70693, 0x54de5729, 0x23d967bf, 0xb3667a2e, 0xc4614ab8,
    0x5d681b02, 0x2a6f2b94, 0xb40bbe37, 0xc30c8ea1, 0x5a05df1b,
    0x2d02ef8d
   );

  $crc = 0xffffffff;
  $len = length($arg);
  @args = unpack "c*", $arg;
  for ($i = 0; $i < $len; $i++) {
    $index = ($crc ^ $args[$i]) & 0xff;
    $crc = $crc_table[$index] ^ (($crc >> 8) & 0x00ffffff);
  }
  return $crc;
}

=pod

=over

=item packet_dump

Debugging function for hexdumping a binary string.

=back

=cut

sub packet_dump
  {
    my $packet = shift;
    my $i;
    my $k;
    my $dump;  
    my $l;
    my $ascii;
    my $c;
    for ( $i = 0; $i < length ( $packet ); $i+=16 ) {
      $l = $i+16;
      if ( $l > length ( $packet) ) {
	$l = length($packet);
      }
      $dump   = sprintf ( "%04d - %04d: ", $i, $l );
      $ascii  = "";
      for ( $k = $i; $k < $l; $k++ ) {
	$c     = ( ord ( substr ( $packet, $k, 1 ) ) );
	$dump .= sprintf ( "%02x ", $c );
	if (( $c >= 32 ) && ( $c <= 126 )) {
	  $ascii .= chr ( $c );
	} else {
	  $ascii .= ".";
	} 
      }
      for ( $k = 0; $k < ( $i + 16 - $l ); $k++ ) {
	$dump .= "   ";
      }
      print ( "packet_dump() ".$dump." [".$ascii."]"."\n"); 
    }
  }

1;

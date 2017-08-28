#!/usr/bin/perl

=pod

=head1 NAME

Nagios::NRPE::Packet - Assembly and disassembly of an NRPE packet

=head1 SYNOPSIS

 use IO::Socket;
 use IO::Socket::INET;
 # Import necessary constants into Namespace
 use Nagios::NRPE::Packet qw(NRPE_PACKET_VERSION_3
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
                              version => NRPE_PACKET_VERSION_3 );

 my $data = <$socket>
 my $response = $packet->disassemble($data);

 print $response->{buffer};
 exit $response->{result_code};

=head1 DESCRIPTION

This class is meant to be used when an active connection exists and is ready to send the
packet.

=head1 CONSTRUCTION

=over

=item new

Takes the following options as a hashref

=back

=head1 SUBROUTINES

Following functions can be used after the creation of the packet

=over 2

=item assemble()

Takes a hash of options defining the packet to be sent and returns the assembled packet. You can print this
to an open socket and send it to either a server or the client depending on your situation.

 * check

A string defining the check to be run or the output of a check eg: "check_cpu"
NOTE: Nagios can accept arguments appended to the check in the form: "check_somecheck!ARG1!ARG2!ARG..."

 * version

The NRPE version you want to use (only V2 and V3 work V1 is not supported, deafult is V3).

See CONSTANTS for options here.

 * type

The TYPE of packet you wish to send, which is either QUERY or RESPONSE.

See CONSTANTS for options here.

 * result_code

This is the exit code of the check script that is run, and check_nrpe.pl will exit with this value from the 
RESPONSE packet.

A set value for the QUERY type packet is 2324.

=item assemble_v2()

A helper function to assemble a V2 packet.

=item assemble_v3()

A helper function to assemble a V3 packet.

=item deassemble()

Deprecated function, use disassemble instead.

=item disassemble()

Takes a packet recieved by either client or server and disassembles them. The returned hashref contains 
the following values for a V3 packet:

 packet_version 
 packet_type    
 crc32_value    
 result_code    
 alignment      
 buffer_length  
 buffer

and the following values for a V2 packet:

 packet_version 
 packet_type    
 crc32_value    
 result_code    
 buffer

=item disassemble_v2()

Helper function for disassembleing a V2 packet

=item disassemble_v3()

Helper function for disassembleing a V3 packet

=item validate($packet)

Validates the contents of a packet using CRC32 checksumming. Returns undef
if not succesful.


=item packet_dump

Debugging function for hexdumping a binary string.

=back

=head1 CONSTANTS

These constants can be exported upon request with the 'use' pragma like this:

 # Will only import the constant NRPE_PACKET_VERSION_3 into your namespace
 use Nagios::NRPE::Packet qw(NRPE_PACKET_VERSION_3);

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

This software is copyright (c) 2017 by the authors (see AUTHORS file).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Nagios::NRPE::Packet;

our $VERSION = '1.0.3';

use 5.010_000;
require Exporter;
require overload;

BEGIN {
    @ISA       = qw(Exporter);
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
use Digest::CRC 'crc32';
use Nagios::NRPE::Utils qw(return_error);

use constant {

    # packet version identifier
    NRPE_PACKET_VERSION_3 => 3,
    NRPE_PACKET_VERSION_2 => 2,
    NRPE_PACKET_VERSION_1 => 1,

    # id code for queries and responses to queries
    NRPE_PACKET_QUERY    => 1,
    NRPE_PACKET_RESPONSE => 2,

    # max amount of data we'll send in one query/response
    MAX_PACKETBUFFER_LENGTH    => 1024,
    MAX_COMMAND_ARGUMENTS      => 16,
    NRPE_HELLO_COMMAND         => "_NRPE_CHECK",
    DEFAULT_SOCKET_TIMEOUT     => 10,
    DEFAULT_CONNECTION_TIMEOUT => 300,

    # /* service state return codes */
    STATE_UNKNOWN  => 3,
    STATE_CRITICAL => 2,
    STATE_WARNING  => 1,
    STATE_OK       => 0,
};

sub new {
    my ( $class, %options ) = @_;
    my $self = {};

    # taken with modifications from common.h in nagios-nrpe
    my $c = Convert::Binary::C->new( ByteOrder => 'BigEndian', Alignment => 0 );
    $self->{c} = $c;
    bless $self, $class;
}

sub assemble {
    my ( $self, %options ) = @_;
    croak "ERROR: Cannot send Packet with empty buffer!"
      if ( not defined $options{check} );
    my $packed;
    if ( $options{version} eq NRPE_PACKET_VERSION_2 ) {
        $packed = $self->assemble_v2(%options);
    }
    else {
        $packed = $self->assemble_v3(%options);
    }
    return $packed;

}

sub assemble_v3 {
    my ( $self, %options ) = @_;
    my $unpacked = {};
    my $len      = length( $options{check} ) + 1;

    $unpacked->{alignment}      = 0;
    $unpacked->{buffer_length}  = $len;
    $unpacked->{buffer}         = $options{check};
    $unpacked->{crc32_value}    = "\x00\x00\x00\x00";
    $unpacked->{packet_type}    = $options{type} || NRPE_PACKET_QUERY;
    $unpacked->{packet_version} = NRPE_PACKET_VERSION_3;
    $unpacked->{result_code}    = $options{result_code} || 2324;

    $self->{c}->parse(<<PACKET_STRUCT);
struct Packet{
  unsigned short   packet_version;
  unsigned short   packet_type;
  unsigned int     crc32_value;
  unsigned short   result_code;
  unsigned short   alignment;
  int              buffer_length;
  char             buffer[$len];
};
PACKET_STRUCT
    $self->{c}->tag( 'Packet.buffer', Format => 'String' );

    my $packed = $self->{c}->pack( 'Packet', $unpacked );

    $unpacked->{crc32_value} = crc32($packed);
    $packed = $self->{c}->pack( 'Packet', $unpacked );
    return $packed;

}

sub assemble_v2 {

    my ( $self, %options ) = @_;
    my $unpacked = {};

    $unpacked->{buffer}         = $options{check};
    $unpacked->{crc32_value}    = "\x00\x00\x00\x00";
    $unpacked->{packet_type}    = $options{type} || NRPE_PACKET_QUERY;
    $unpacked->{packet_version} = NRPE_PACKET_VERSION_2;
    $unpacked->{result_code}    = $options{result_code} || 2324;

    $self->{c}->parse(<<PACKET_STRUCT);
struct Packet{
  unsigned short   packet_version;
  unsigned short   packet_type;
  unsigned int     crc32_value;
  unsigned short   result_code;
  char             buffer[1024];
};
PACKET_STRUCT
    $self->{c}->tag( 'Packet.buffer', Format => 'String' );

    my $packed = $self->{c}->pack( 'Packet', $unpacked );

    $unpacked->{crc32_value} = crc32($packed);
    $packed = $self->{c}->pack( 'Packet', $unpacked );
    return $packed;

}

sub validate {
    my ( $self, $packet ) = @_;
    my $unpacked = $self->{c}->unpack( 'Packet', $packet );
    my $checksum = $unpacked->{crc32_value};
    $unpacked->{crc32_value} = "\x00\x00\x00\x00";
    my $packed = $self->{c}->pack( 'Packet', $unpacked );
    if ( crc32($packed) != $checksum ) {
        return undef;
    }
    else {
        return 1;
    }
}

sub deassemble {
    my ( $self, $packet ) = @_;
    print
"The deassemble function has been deprecated and will be removed in a future release, please use disassemble instead\n";
    return $self->disassemble($packet);
}

sub disassemble {
    my ( $self, $packet ) = @_;
    if ( !$packet ) {
        return_error("Could not disassemble packet, it seems empty");
    }
    my $ver = unpack( "n", $packet );
    my $unpacked = {};
    if ( $ver eq NRPE_PACKET_VERSION_2 ) {
        $unpacked = $self->disassemble_v2($packet);
    }
    else {
        $unpacked = $self->disassemble_v3($packet);
    }
    return $unpacked;
}

sub disassemble_v3 {
    my ( $self, $packet ) = @_;
    my @arr = unpack( "n2 N n2 N Z*", $packet );
    my $unpacked = {};
    $unpacked->{packet_version} = $arr[0];
    $unpacked->{packet_type}    = $arr[1];
    $unpacked->{crc32_value}    = $arr[2];
    $unpacked->{result_code}    = $arr[3];
    $unpacked->{alignment}      = $arr[4];
    $unpacked->{buffer_length}  = $arr[5];
    $unpacked->{buffer}         = $arr[6];
    return $unpacked;
}

sub disassemble_v2 {
    my ( $self, $packet ) = @_;
    my @arr = unpack( "n2 N n Z*", $packet );
    my $unpacked = {};
    $unpacked->{packet_version} = $arr[0];
    $unpacked->{packet_type}    = $arr[1];
    $unpacked->{crc32_value}    = $arr[2];
    $unpacked->{result_code}    = $arr[3];
    $unpacked->{buffer}         = $arr[4];
    return $unpacked;
}

sub packet_dump {
    my $packet = shift;
    my $i;
    my $k;
    my $dump;
    my $l;
    my $ascii;
    my $c;
    for ( $i = 0 ; $i < length($packet) ; $i += 16 ) {
        $l = $i + 16;
        if ( $l > length($packet) ) {
            $l = length($packet);
        }
        $dump = sprintf( "%04d - %04d: ", $i, $l );
        $ascii = "";
        for ( $k = $i ; $k < $l ; $k++ ) {
            $c = ( ord( substr( $packet, $k, 1 ) ) );
            $dump .= sprintf( "%02x ", $c );
            if ( ( $c >= 32 ) && ( $c <= 126 ) ) {
                $ascii .= chr($c);
            }
            else {
                $ascii .= ".";
            }
        }
        for ( $k = 0 ; $k < ( $i + 16 - $l ) ; $k++ ) {
            $dump .= "   ";
        }
        print( "packet_dump() " . $dump . " [" . $ascii . "]" . "\n" );
    }
}

1;

package Net::ICQV5CD;

=head1 NAME

C<Net::ICQV5CD> - Module to crypt/decrypt ICQ protocol V5 packets.

=head1 SYNOPSIS

 use Net::ICQV5CD;

 $packet = "000102030405060708090A0B0C0D0E0F101112131415161718";
 $packet = pack("H*",$packet);
  
 $packet = ICQV5_CRYPT_PACKET($packet);
 $packet = ICQV5_DECRYPT_PACKET($packet);

=head1 DESCRIPTION

This module provides set of functions to crypt/decrypt ICQ V5 packets.

=cut

use strict;
use vars qw($VERSION @ISA @EXPORT);

use Exporter;

@ISA    = qw(Exporter);
@EXPORT = qw(@ICQV5_CRYPT_TABLE 
	     &ICQV5_GET_PACKET_CHECKCODE
	     &ICQV5_SCRAMBLE_CHECKCODE  
	     &ICQV5_DESCRAMBLE_CHECKCODE
	     &ICQV5_CRYPT_PACKET 
	     &ICQV5_DECRYPT_PACKET);

$VERSION = 1.02;

##############################################################################

=head1 IMPORTED FUNCTIONS/VARS

=head2 @ICQV5_CRYPT_TABLE

ICQ V5 Crypt Table
  
=cut  

my @ICQV5_CRYPT_TABLE = (
    0x59, 0x60, 0x37, 0x6B, 0x65, 0x62, 0x46, 0x48, 0x53, 0x61, 0x4C, 0x59, 0x60, 0x57, 0x5B, 0x3D, 
    0x5E, 0x34, 0x6D, 0x36, 0x50, 0x3F, 0x6F, 0x67, 0x53, 0x61, 0x4C, 0x59, 0x40, 0x47, 0x63, 0x39,
    0x50, 0x5F, 0x5F, 0x3F, 0x6F, 0x47, 0x43, 0x69, 0x48, 0x33, 0x31, 0x64, 0x35, 0x5A, 0x4A, 0x42,
    0x56, 0x40, 0x67, 0x53, 0x41, 0x07, 0x6C, 0x49, 0x58, 0x3B, 0x4D, 0x46, 0x68, 0x43, 0x69, 0x48,
    0x33, 0x31, 0x44, 0x65, 0x62, 0x46, 0x48, 0x53, 0x41, 0x07, 0x6C, 0x69, 0x48, 0x33, 0x51, 0x54,
    0x5D, 0x4E, 0x6C, 0x49, 0x38, 0x4B, 0x55, 0x4A, 0x62, 0x46, 0x48, 0x33, 0x51, 0x34, 0x6D, 0x36,
    0x50, 0x5F, 0x5F, 0x5F, 0x3F, 0x6F, 0x47, 0x63, 0x59, 0x40, 0x67, 0x33, 0x31, 0x64, 0x35, 0x5A,
    0x6A, 0x52, 0x6E, 0x3C, 0x51, 0x34, 0x6D, 0x36, 0x50, 0x5F, 0x5F, 0x3F, 0x4F, 0x37, 0x4B, 0x35,
    0x5A, 0x4A, 0x62, 0x66, 0x58, 0x3B, 0x4D, 0x66, 0x58, 0x5B, 0x5D, 0x4E, 0x6C, 0x49, 0x58, 0x3B,
    0x4D, 0x66, 0x58, 0x3B, 0x4D, 0x46, 0x48, 0x53, 0x61, 0x4C, 0x59, 0x40, 0x67, 0x33, 0x31, 0x64,
    0x55, 0x6A, 0x32, 0x3E, 0x44, 0x45, 0x52, 0x6E, 0x3C, 0x31, 0x64, 0x55, 0x6A, 0x52, 0x4E, 0x6C,
    0x69, 0x48, 0x53, 0x61, 0x4C, 0x39, 0x30, 0x6F, 0x47, 0x63, 0x59, 0x60, 0x57, 0x5B, 0x3D, 0x3E,
    0x64, 0x35, 0x3A, 0x3A, 0x5A, 0x6A, 0x52, 0x4E, 0x6C, 0x69, 0x48, 0x53, 0x61, 0x6C, 0x49, 0x58,
    0x3B, 0x4D, 0x46, 0x68, 0x63, 0x39, 0x50, 0x5F, 0x5F, 0x3F, 0x6F, 0x67, 0x53, 0x41, 0x25, 0x41,
    0x3C, 0x51, 0x54, 0x3D, 0x5E, 0x54, 0x5D, 0x4E, 0x4C, 0x39, 0x50, 0x5F, 0x5F, 0x5F, 0x3F, 0x6F,
    0x47, 0x43, 0x69, 0x48, 0x33, 0x51, 0x54, 0x5D, 0x6E, 0x3C, 0x31, 0x64, 0x35, 0x5A, 0x00, 0x00,
);
###############################################################################   

=head2 $checkcode = ICQV5_GET_PACKET_CHECKCODE($packet)

Function that will return packet checkcode.
If you don't know what is checkcode this fucntion will not be
useful for you.
  
=cut  

sub ICQV5_GET_PACKET_CHECKCODE {
    my $packet = shift ;

    # Packet length must be > 0x18

    if(length($packet) <= 0x18) {return undef;}
    
    #  1. Found NUMBER1 formed by:
    #
    #  B8 = Byte at position 8 of the packet. (starting at position 0)
    #  B4 = Byte at position 4 of the packet.
    #  B2 = Byte at position 2 of the packet.
    #  B6 = Byte at position 6 of the packet.
    #
    #  NUMBER1 = 0x B8 B4 B2 B6       (B8 = UPPER BYTE, B6 = LOWER BYTE)

    my ($number1);

    $number1  = unpack("c",substr($packet,0x08));
    $number1 <<= 8;
    $number1 += unpack("c",substr($packet,0x04));
    $number1 <<= 8;
    $number1 += unpack("c",substr($packet,0x02));
    $number1 <<= 8;
    $number1 += unpack("c",substr($packet,0x06));
   
    #  2. Calculate the following:
    #
    #  PL = Packet length
    #  R1 = a random number beetween 0x18 and (0x18 + PL)
    #  R2 = another random number beetween 0 and 0xFF

    my ($r1,$r2);
    
    $r1 = rand(length($packet) - 0x18) + 0x18;
    $r2 = rand(0xFF);

    #  $r1 = 0x18; # For Test
    #  $r2 = 0x7F; # For Test

    #  3. Found NUMBER2:
    #
    #  X4 = R1
    #  X3 = NOT (BYTE at pos X4 in the packet)
    #  X2 = R2
    #  X1 = NOT (BYTE at pos X2 in the TABLE)  (see TABLE section)
    #
    #  NUMBER2 = 0x X4 X3 X2 X1     (X4 = UPPER BYTE, X1 = LOWER BYTE)

    my ($number2);

    $number2  = $r1;
    $number2 <<= 8;
    $number2 += unpack("c",substr($packet,$r1));
    $number2 <<= 8;
    $number2 += $r2;
    $number2 <<= 8;
    $number2 += $ICQV5_CRYPT_TABLE[$r2];
    $number2 ^= 0x00FF00FF;
   
    #  4. You can now calculate the checkcode:
    #
    #  CHECKCODE = NUMBER1 XOR NUMBER2
   
    return $number1 ^ $number2;
}
#############################################################################   

=head2 $scheckcode = ICQV5_SCRAMBLE_CHECKCODE($checkcode)

Function that will return packet scrabmled checkcode.
If you don't know what is checkcode this fucntion will not be
useful for you.
  
=cut  

sub ICQV5_SCRAMBLE_CHECKCODE {
    my $checkcode = shift;

    my $a1 = $checkcode & 0x0000001F;
    my $a2 = $checkcode & 0x03E003E0;
    my $a3 = $checkcode & 0xF8000400;
    my $a4 = $checkcode & 0x0000F800;
    my $a5 = $checkcode & 0x041F0000;

    $a1 <<= 0x0C;
    $a2 <<= 0x01;
    $a3 >>= 0x0A;
    $a4 <<= 0x10;
    $a5 >>= 0x0F;

    return $a1 + $a2 + $a3 + $a4 + $a5;
}   
#############################################################################   

=head2 $dscheckcode = ICQV5_DESCRAMBLE_CHECKCODE($checkcode)

Function that will return packet descrabmled checkcode.
If you don't know what is checkcode this fucntion will not be
useful for you.
  
=cut  


sub ICQV5_DESCRAMBLE_CHECKCODE {
    my $checkcode = shift;

    my $a1 = $checkcode & 0x0001F000;
    my $a2 = $checkcode & 0x07C007C0;
    my $a3 = $checkcode & 0x003E0001;
    my $a4 = $checkcode & 0xF8000000;
    my $a5 = $checkcode & 0x0000083E;

    $a1 >>= 0x0C;
    $a2 >>= 0x01;
    $a3 <<= 0x0A;
    $a4 >>= 0x10;
    $a5 <<= 0x0F;

    return $a1 + $a2 + $a3 + $a4 + $a5;
}   
#############################################################################   

=head2 $crypted_packet = ICQV5_CRYPT_PACKET($packet)

Function that crypt incoming packet by ICQ V5 algorithm.
This is most usable function.
Packet must coming as string.
  
=cut  


sub ICQV5_CRYPT_PACKET {
    my $packet = shift;
    my $decryptpacket = shift;

    # Packet length must be > 0x18
    my $pl = length($packet);
    
    if($pl<=0x18) {return $packet;}

    # If you want to encrypt or decrypt a packet, use the following algorithm:
    # (the algorithm is the same for the ecryption AND decryption)

    # 1. Calculate the following:
    #
    #    Calculate the CHECKCODE
    
    my $checkcode;

    if(!$decryptpacket)
	{
	$checkcode = ICQV5_GET_PACKET_CHECKCODE($packet);
	}
    else
	{
	$checkcode = unpack("V",substr($packet,0x14));
        $checkcode = ICQV5_DESCRAMBLE_CHECKCODE($checkcode);
	}	

    # CODE1 = (DWORD) (PL * 0x68656C6C)     (flush the overflow)
    # CODE2 = (DWORD) (CODE1 + CHECKCODE)   (flush the overflow)

    my ($code1,$code2);
      
    $code1 = $pl * 0x68656C6C;
    while ($code1 > 0xFFFFFFFF) { $code1 = $code1 - 0xFFFFFFFF - 1; }
    
    $code2 = $code1 + $checkcode;
    if($code2 > 0xFFFFFFFF) { $code2 = $code2 - 0xFFFFFFFF - 1; }

    # 2. Do the following loop:
    
    my ($data,$code3);
    $packet = $packet . "000";

    # POS = 0x0A
    
    for(my $pos=0x0A;$pos<$pl;$pos+=4)
	{
	# T = POS MOD 0x0100
	# CODE3 = CODE2 + TABLE[T]      (see TABLE section)
	
	$code3 = $code2 + $ICQV5_CRYPT_TABLE[$pos & 0xFF];
   
	# DATA = DWORD at position POS in the packet
	#        (don't forget to reverse the byte order)
	# DATA = DATA XOR CODE3

	$data = unpack("V",substr($packet,$pos));
	$data ^= $code3;
	$packet = substr($packet,0,$pos) . pack("V",$data) . substr($packet,$pos+0x04);
	}
   
    if(!$decryptpacket)
	{
        $checkcode = ICQV5_SCRAMBLE_CHECKCODE($checkcode);
	$packet = substr($packet,0,0x14) . pack("V",$checkcode) . substr($packet,0x18);
	}

    $packet = substr($packet,0,$pl);
    
    return $packet;
}
#############################################################################   

=head2 $decrypted_packet = ICQV5_DECRYPT_PACKET($packet)

Function that decrypt incoming packet by ICQ V5 algorithm.
This is most usable function.
Packet must coming as string.
  
=cut  

sub ICQV5_DECRYPT_PACKET {
    my $packet = shift;

    return ICQV5_CRYPT_PACKET($packet,1);
}
#############################################################################   
1;

=head1 DISCLAIMERS

I am in no way affiliated with Mirabilis!

This module was made without any help from Mirabilis or their
consent.  No reverse engineering or decompilation of any Mirabilis
code took place to make this program.

=head1 COPYRIGHT

Copyright (c) 2000-2001 Sergei A. Nemarov (admin@tapor.com). All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

http://www.tapor.com/NetICQ/

=cut

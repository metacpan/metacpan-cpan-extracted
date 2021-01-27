#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/
#-------------------------------------------------------------------------------
# Simd::Avx512 - Emulate SIMD instructions
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2021
#-------------------------------------------------------------------------------
# podDocumentation
package Simd::Avx512;
our $VERSION = 20210122;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Dump qw(dump);
use feature qw(say current_sub);

my $develop = -e q(/home/phil/);                                                # Development mode

sub repeat($$)                                                                  # Repeat a string
 {my ($string, $repeat) = @_;                                                   # String to repeat, number of repetitions
  $string x $repeat
 }

sub zByte  {repeat('0',  8)}                                                    # Zero byte
sub zWord  {repeat('0', 16)}                                                    # Zero word
sub zDWord {repeat('0', 32)}                                                    # Zero double word
sub zQWord {repeat('0', 64)}                                                    # Zero quad word

sub zBytes($)                                                                   # String of zero bytes of specified length
 {my ($length) = @_;                                                            # Length
  repeat(zByte, $length)
 }

sub zWords($)                                                                   # String of zero words of specified length
 {my ($length) = @_;                                                            # Length
  repeat(zWord, $length)
 }

sub zDWords($)                                                                  # String of zero double words of specified length
 {my ($length) = @_;                                                            # Length
  repeat(zDWord, $length)
 }

sub zQWords($)                                                                  # String of zero quad words of specified length
 {my ($length) = @_;                                                            # Length
  repeat(zQWord, $length)
 }

sub byte($)                                                                     # A byte with the specified value
 {my ($value) = @_;                                                             # Value of the byte
  confess "0 - 2**8 required ($value)" unless $value >= 0 and $value < 2**8;
  sprintf("%08b", $value)
 }

sub word($)                                                                     # A word with the specified value
 {my ($value) = @_;                                                             # Value of the word
  confess "0 - 2**16 required ($value)" unless $value >= 0 and $value < 2**16;
  sprintf("%016b", $value)
 }

sub dWord($)                                                                    # A double word with the specified value
 {my ($value) = @_;                                                             # Value of the double word
  confess "0 - 2**32 required ($value)" unless $value >= 0 and $value < 2**32;
  sprintf("%032b", $value)
 }

sub qWord($)                                                                    # A quad word with the specified value
 {my ($value) = @_;                                                             # Value of the quad word
  confess "0 - 2**64 required ($value)" unless $value >= 0 and $value < 2**64;
  sprintf("%064b", $value)
 }

sub maskRegister {zQWord}                                                       # Mask register set to zero

sub require8or16or32or64($)                                                     # Check that we have a size of 8|16|32|64 bits
 {my ($size) = @_;                                                              # Size to check
  confess "8|16|32|64 required for operand ($size)" unless $size == 8 or $size == 16 or $size == 32 or $size == 64;
 }

sub require64($)                                                                # Check that we have a string of 64 bits
 {my ($xmm) = @_;                                                               # Bytes
  defined($xmm) or confess;
  my $l = length $xmm;
  confess "64 bits required for operand ($l)"      unless $l   == 64;
  confess "Only zeros and ones allowed in operand" unless $xmm =~ m(\A[01]+\Z);
 }

sub require128($)                                                               # Check that we have a string of 128 bits
 {my ($xmm) = @_;                                                               # Bytes
  my $l = length $xmm;
  confess "128 bits required for operand ($l)"     unless $l   == 128;
  confess "Only zeros and ones allowed in operand" unless $xmm =~ m(\A[01]+\Z);
 }

sub require128or245or512($;$)                                                   # Check that we have a string of 128|256|512 bits in the first operand and optionally the same in the second operand
 {my ($xmm1, $xmm2) = @_;                                                       # Bytes, optional bytes
  my $l = length $xmm1;
  confess "128|256|512 bits required for first operand ($l)"    unless $l == 128 or $l == 256 or $l == 512;
  if (defined $xmm2)
   {my $m = length $xmm2;
    confess "128|256|512 bits required for second operand ($m)" unless $m == 128 or $m == 256 or $m == 512;
    confess "Operands must have same length($l,$m)" unless $l == $m;
   }
 }

sub require64or128or245or512($)                                                 # Check that we have a string of 64|128|256|512 bits
 {my ($xmm) = @_;                                                               # Bytes
  my $l = length $xmm;
  confess "64|128|256|512 bits required for operand"  unless $l == 64 or $l == 128 or $l == 256 or $l == 512;
  confess "Only zeros and ones allowed in operand"    unless $xmm =~ m(\A[01]+\Z);
 }

sub requireSameLength($$)                                                       # Check that the two operands have the same length
 {my ($xmm1, $xmm2) = @_;                                                       # Bytes, bytes
  my ($l, $L) = (length($xmm1), length($xmm2));
  confess "Operands have different lengths($l, $L)" unless $l == $L;
  $l
 }

sub flipBitsUnderMask($$)                                                       # Flip the bits in a string where the corresponding  mask bit is 1 else leave the bit as is
 {my ($string, $mask) = @_;                                                     # Bit string, mask
  my $l = requireSameLength $string, $mask;
  my $f = '';
  for my $i(0..$l-1)                                                            # Each character in the string and mask
   {my $s = substr($string, $i, 1);
    $f .= substr($mask, $i, 1) eq '0' ? $s : $s eq '0' ? '1' : '0'
   }
  $f
 }

#D1 Instructions                                                                # Emulation of Avx512 instructions

sub PSLLDQ($$)                                                                  # Packed Shift Left Logical DoubleQword
 {my ($xmm1, $imm8) = @_;                                                       # Bytes, length of shift
  require128 $xmm1;                                                             # Check that we have a string of 128 bits
  substr($xmm1, $imm8 * 8).zBytes($imm8)
 }

sub VPSLLDQ($$)                                                                 # Packed Shift Left Logical DoubleQword
 {my ($xmm1, $imm8) = @_;                                                       # Bytes, length of shift
  require128or245or512 $xmm1;                                                   # Check that we have a string of 128 bits
  confess "0 - 15 for shift amount required" unless $imm8 >= 0 and $imm8 < 16;

  return PSLLDQ($xmm1, $imm8) if length($xmm1)                   == 128;

  return PSLLDQ(substr($xmm1,   0, 128), $imm8).
         PSLLDQ(substr($xmm1, 128, 128), $imm8) if length($xmm1) == 256;

  return PSLLDQ(substr($xmm1,   0, 128), $imm8).
         PSLLDQ(substr($xmm1, 128, 128), $imm8).
         PSLLDQ(substr($xmm1, 256, 128), $imm8).
         PSLLDQ(substr($xmm1, 384, 128), $imm8)
 }

sub PSRLDQ($$)                                                                  # Packed Shift Right Logical DoubleQword
 {my ($xmm1, $imm8) = @_;                                                       # Bytes, length of shift
  require128 $xmm1;                                                             # Check that we have a string of 128 bits
  zBytes($imm8).substr($xmm1, 0, 128 - $imm8 * 8)
 }

sub VPSRLDQ($$)                                                                 # Packed Shift Right Logical DoubleQword
 {my ($xmm1, $imm8) = @_;                                                       # Bytes, length of shift
  require128or245or512 $xmm1;                                                   # Check that we have a string of 128 bits
  confess "0 - 15 for shift amount required" unless $imm8 >= 0 and $imm8 < 16;

  return PSRLDQ($xmm1, $imm8) if length($xmm1)                   == 128;

  return PSRLDQ(substr($xmm1,   0, 128), $imm8).
         PSRLDQ(substr($xmm1, 128, 128), $imm8) if length($xmm1) == 256;

  return PSRLDQ(substr($xmm1,   0, 128), $imm8).
         PSRLDQ(substr($xmm1, 128, 128), $imm8).
         PSRLDQ(substr($xmm1, 256, 128), $imm8).
         PSRLDQ(substr($xmm1, 384, 128), $imm8)
 }

sub PCMPEQB($$)                                                                 # Packed CoMPare EQual Byte
 {my ($xmm1, $xmm2) = @_;                                                       # Bytes, bytes
  require128 $xmm1;                                                             # Check that we have a string of 128 bits in the first operand
  require128 $xmm2;                                                             # Check that we have a string of 128 bits in the second operand
  requireSameLength $xmm1, $xmm2;                                               # Check operands have the same length
  my $N = 16;                                                                   # Bytes in operation
  my $xmm3 = zBytes $N;
  for(0..$N-1)
   {substr($xmm3, $_*8, 8) = substr($xmm1, $_*8, 8) eq substr($xmm2, $_*8, 8) ?
                             byte(255) : byte(0);
   }
  $xmm3
 }

sub vpcmpeq($$$;$)                                                              #P Packed CoMPare EQual Byte|word|double|quad with optional masking
 {my ($size, $k2, $xmm1, $xmm2) = @_;                                           # Size in bits: 8|16|32|64 of each element, optional input mask, bytes, bytes

  require8or16or32or64     $size  if $develop;                                  # We supply this parameter so we ought to get it right
  require64or128or245or512 $k2    if defined $k2;                               # Optional mask
  require128or245or512     $xmm1, $xmm2;                                        # Check that we have a string of 128 bits in the first operand

  my $N = length($xmm1) / $size;                                                # Bytes|Words|Doubles|Quads in operation
  if (defined $k2)                                                              # Masked operation
   {my $k1 = maskRegister;                                                      # Result register
       $k2 = substr($k2, 48) if $N == 16;                                       # Relevant portion of register
       $k2 = substr($k2, 32) if $N == 32;
    for(0..$N-1)
     {next unless substr($k2, $_, 1) eq '1';
      my $o = $_ * $size;
      substr($k1, $_, 1) = substr($xmm1, $o, $size) eq
                           substr($xmm2, $o, $size) ? '1' : '0';
     }
    return zBytes(6).substr($k1, 0, 16) if $N == 16;
    return zBytes(4).substr($k1, 0, 32) if $N == 32;
    return $k1
   }

  my $xmm3 = zBytes $N;                                                         # Non masked operation
  my $clear = '0' x $size;
  my $set   = '1' x $size;
  for(0..$N-1)
   {my $o = $_ * $size;
    substr($xmm3, $o, $size) = substr($xmm1, $o, $size) eq
                               substr($xmm2, $o, $size) ? $set : $clear
   }
  $xmm3
 }

sub VPCMPEQB($$;$)                                                              # Packed CoMPare EQual Byte with optional masking
 {my ($k2, $xmm1, $xmm2) = @_ == 3 ? @_ : (undef, @_);                          # Optional input mask, bytes, bytes
  vpcmpeq(8, $k2, $xmm1, $xmm2)
 }

sub VPCMPEQW($$;$)                                                              # Packed CoMPare EQual Byte with optional masking
 {my ($k2, $xmm1, $xmm2) = @_ == 3 ? @_ : (undef, @_);                          # Optional input mask, bytes, bytes
  vpcmpeq(16, $k2, $xmm1, $xmm2)
 }

sub vpcmpu($$$$$)                                                               # Packed CoMPare Unsigned Byte
 {my ($size, $k2, $xmm1, $xmm2, $op) = @_;                                      # Size of element in bits, input mask, bytes, bytes, test code

  require8or16or32or64 $size if $develop;                                       # We supply this parameter so we ought to get it right
  require64 $k2;                                                                # Mask
  require128or245or512 $xmm1, $xmm2;                                            # Check that we have a string of 128 bits in the first operand
  confess "Invalid op code $op" unless $op =~ m(\A(0|1|2|4|5|6)\Z);             # Test code

  my $T  =                                                                      # String tests
   [sub {return 1 if $_[0] eq $_[1]; 0},                                        # eq 0
    sub {return 1 if $_[0] lt $_[1]; 0},                                        # lt 1
    sub {return 1 if $_[0] le $_[1]; 0},                                        # le 2
    undef,
    sub {return 1 if $_[0] ne $_[1]; 0},                                        # ne 4
    sub {return 1 if $_[0] ge $_[1]; 0},                                        # ge 5
    sub {return 1 if $_[0] gt $_[1]; 0},                                        # gt 6
   ];

  my $N  = length($xmm1) / $size;                                               # Number of elements
  my $k1 = maskRegister;
     $k2 = substr($k2, -$N);                                                    # Relevant portion of mask
  for(0..$N-1)
   {next unless substr($k2, $_, 1) eq '1';                                      # Mask
    my $o = $_ * $size;
    substr($k1, $_, 1) = &{$$T[$op]}(substr($xmm1, $o, $size),                  # Compare according to code
                                     substr($xmm2, $o, $size)) ? '1' : '0';
   }

  substr(zBytes(8).substr($k1, 0, $N), -64)
 }

sub VPCMPUB($$$$)                                                               # Packed CoMPare Unsigned Byte
 {my ($k2, $xmm1, $xmm2, $op) = @_;                                             # Input mask, bytes, bytes, test code
  vpcmpu 8, $k2, $xmm1, $xmm2, $op
 }

sub VPCMPUW($$$$)                                                               # Packed CoMPare Unsigned Word
 {my ($k2, $xmm1, $xmm2, $op) = @_;                                             # Input mask, words, words, test code
  vpcmpu 16, $k2, $xmm1, $xmm2, $op
 }

sub VPCMPUD($$$$)                                                               # Packed CoMPare Unsigned Dword
 {my ($k2, $xmm1, $xmm2, $op) = @_;                                             # Input mask, dwords, dwords, test code
  vpcmpu 32, $k2, $xmm1, $xmm2, $op
 }

sub VPCMPUQ($$$$)                                                               # Packed CoMPare Unsigned Qword
 {my ($k2, $xmm1, $xmm2, $op) = @_;                                             # Input mask, qwords, qwords, test code
  vpcmpu 64, $k2, $xmm1, $xmm2, $op
 }

#D0
#-------------------------------------------------------------------------------
# Export
#-------------------------------------------------------------------------------

use Exporter qw(import);

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT_OK    = qw(
);
%EXPORT_TAGS  = (all=>[@EXPORT, @EXPORT_OK]);

# podDocumentation

=pod

=encoding utf-8

=head1 Name

Simd::Avx512 - Emulate SIMD instructions

=head1 Synopsis

Help needed please!

=head1 Description

Emulate SIMD instructions


Version 20210122.


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Instructions

Emulation of Avx512 instructions

=head2 PSLLDQ($xmm1, $imm8)

Packed Shift Left Logical DoubleQword

     Parameter  Description
  1  $xmm1      Bytes
  2  $imm8      Length of shift

B<Example:>


  
    is_deeply PSLLDQ(                                                             # 128  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  #Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
  #D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
  #W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
  #B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
  #b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
   '11100001000010000000000011000000000000000100000000001000000000000110000000000000000000111111000000000000000000000000000000001111'
  ,2),
   '00000000110000000000000001000000000010000000000001100000000000000000001111110000000000000000000000000000000011110000000000000000'
  

=head2 VPSLLDQ($xmm1, $imm8)

Packed Shift Left Logical DoubleQword

     Parameter  Description
  1  $xmm1      Bytes
  2  $imm8      Length of shift

B<Example:>


  
    is_deeply VPSLLDQ(                                                            # 128  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  #Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
  #D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
  #W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
  #B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
  #b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
   '11100001000010000000000011000000000000000100000000001000000000000110000000000000000000111111000000000000000000000000000000001111'
  ,2),
   '00000000110000000000000001000000000010000000000001100000000000000000001111110000000000000000000000000000000011110000000000000000'
  
  
    is_deeply VPSLLDQ(                                                            # 2*128  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  #Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
  #D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
  #W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
  #B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
  #b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
   '11100001000010000000000011000000000000000100000000001000000000000110000000000000000000111111000000000000000000000000000000001111'
  .'11100001000010000000000011000000000000000100000000001000000000000110000000000000000000111111000000000000000000000000000000001111'
  ,2),
   '00000000110000000000000001000000000010000000000001100000000000000000001111110000000000000000000000000000000011110000000000000000'
  .'00000000110000000000000001000000000010000000000001100000000000000000001111110000000000000000000000000000000011110000000000000000'
  
  
    is_deeply VPSLLDQ(                                                            # 4*128  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  #Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
  #D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
  #W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
  #B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
  #b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
   '11100001000010000000000011000000000000000100000000001000000000000110000000000000000000111111000000000000000000000000000000001111'
  .'11100001000010000000000011000000000000000100000000001000000000000110000000000000000000111111000000000000000000000000000000001111'
  .'11100001000010000000000011000000000000000100000000001000000000000110000000000000000000111111000000000000000000000000000000001111'
  .'11100001000010000000000011000000000000000100000000001000000000000110000000000000000000111111000000000000000000000000000000001111'
  ,2),
   '00000000110000000000000001000000000010000000000001100000000000000000001111110000000000000000000000000000000011110000000000000000'
  .'00000000110000000000000001000000000010000000000001100000000000000000001111110000000000000000000000000000000011110000000000000000'
  .'00000000110000000000000001000000000010000000000001100000000000000000001111110000000000000000000000000000000011110000000000000000'
  .'00000000110000000000000001000000000010000000000001100000000000000000001111110000000000000000000000000000000011110000000000000000'
  

=head2 PSRLDQ($xmm1, $imm8)

Packed Shift Right Logical DoubleQword

     Parameter  Description
  1  $xmm1      Bytes
  2  $imm8      Length of shift

B<Example:>


  
    is_deeply PSRLDQ(                                                             # 128  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  #Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
  #D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
  #W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
  #B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
  #b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
   '11100001000010000000000011000000000000000100000000001000000000000110000000000000000000111111000000000000000000000000000000001111'
  ,2),
   '00000000000000001110000100001000000000001100000000000000010000000000100000000000011000000000000000000011111100000000000000000000'
  

=head2 VPSRLDQ($xmm1, $imm8)

Packed Shift Right Logical DoubleQword

     Parameter  Description
  1  $xmm1      Bytes
  2  $imm8      Length of shift

B<Example:>


  
    is_deeply VPSRLDQ(                                                            # 128  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  #Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
  #D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
  #W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
  #B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
  #b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
   '11100001000010000000000011000000000000000100000000001000000000000110000000000000000000111111000000000000000000000000000000001111'
  ,2),
   '00000000000000001110000100001000000000001100000000000000010000000000100000000000011000000000000000000011111100000000000000000000'
  
  
    is_deeply VPSRLDQ(                                                            # 2*128  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  #Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
  #D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
  #W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
  #B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
  #b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
   '11100001000010000000000011000000000000000100000000001000000000000110000000000000000000111111000000000000000000000000000000001111'
  .'11100001000010000000000011000000000000000100000000001000000000000110000000000000000000111111000000000000000000000000000000001111'
  ,2),
   '00000000000000001110000100001000000000001100000000000000010000000000100000000000011000000000000000000011111100000000000000000000'
  .'00000000000000001110000100001000000000001100000000000000010000000000100000000000011000000000000000000011111100000000000000000000'
  
  
    is_deeply VPSRLDQ(                                                            # 4*128  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  #Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
  #D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
  #W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
  #B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
  #b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
   '11100001000010000000000011000000000000000100000000001000000000000110000000000000000000111111000000000000000000000000000000001111'
  .'11100001000010000000000011000000000000000100000000001000000000000110000000000000000000111111000000000000000000000000000000001111'
  .'11100001000010000000000011000000000000000100000000001000000000000110000000000000000000111111000000000000000000000000000000001111'
  .'11100001000010000000000011000000000000000100000000001000000000000110000000000000000000111111000000000000000000000000000000001111'
  ,2),
   '00000000000000001110000100001000000000001100000000000000010000000000100000000000011000000000000000000011111100000000000000000000'
  .'00000000000000001110000100001000000000001100000000000000010000000000100000000000011000000000000000000011111100000000000000000000'
  .'00000000000000001110000100001000000000001100000000000000010000000000100000000000011000000000000000000011111100000000000000000000'
  .'00000000000000001110000100001000000000001100000000000000010000000000100000000000011000000000000000000011111100000000000000000000'
  

=head2 PCMPEQB($xmm1, $xmm2)

Packed CoMPare EQual Byte

     Parameter  Description
  1  $xmm1      Bytes
  2  $xmm2      Bytes

B<Example:>


  
    is_deeply PCMPEQB(                                                            # 128  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  #Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
  #D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
  #W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
  #B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
  #b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
   '11100001000010000000000011000000000000011000000000010000000000001100000000000000000001111110000000000000000000000000000000011110'
  ,'11100001000001000000000011000000000000010000000000100000000000001100000000000000000001111110000000000000000000000000000000011010'
  ),
   '11111111000000001111111111111111111111110000000000000000111111111111111111111111111111111111111111111111111111111111111100000000'
  

=head2 VPCMPEQB($k2, $xmm1, $xmm2)

Packed CoMPare EQual Byte with optional masking

     Parameter  Description
  1  $k2        Optional input mask
  2  $xmm1      Bytes
  3  $xmm2      Bytes

B<Example:>


  
    is_deeply VPCMPEQB(                                                           # 128  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  #Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
  #D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
  #W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
  #B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
  #b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
   '11100001000010000000000011000000000000011000000000010000000000001100000000000000000001111110000000000000000000000000000000011110'
  ,'11100001000001000000000011000000000000010000000000100000000000001100000000000000000001111110000000000000000000000000000000011010'
  ),
   '11111111000000001111111111111111111111110000000000000000111111111111111111111111111111111111111111111111111111111111111100000000'
  
  
    is_deeply VPCMPEQB(                                                           # 512  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  #Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
  #D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
  #W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
  #B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
  #b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
   '11100001000010000000000011000000000000011000000000010000000000001100000000000000000001111110000000000000000000000000000000011110'
  .'11100001000010000000000011000000000000011000000000010000000000001100000000000000000001111110000000000000000000000000000000011110'
  ,'11100001000001000000000011000000000000010000000000100000000000001100000000000000000001111110000000000000000000000000000000011010'
  .'11100001000001000000000011000000000000010000000000100000000000001100000000000000000001111110000000000000000000000000000000011010'
  ),
   '11111111000000001111111111111111111111110000000000000000111111111111111111111111111111111111111111111111111111111111111100000000'
  .'11111111000000001111111111111111111111110000000000000000111111111111111111111111111111111111111111111111111111111111111100000000'
  
  
    is_deeply VPCMPEQB(                                                           # 128  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  #Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
  #D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
  #W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
  #B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
  #b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
   '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1',
                                                                                                                                                                                                                                                                                                                                                                                                   '00000001000010000000000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
                                                                                                                                                                                                                                                                                                                                                                                                   '10000001000010000000000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
  ),
   '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1';
  
  
    is_deeply VPCMPEQB(                                                           # 256  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  #Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
  #D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
  #W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
  #B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
  #b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
   '1'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '1'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1',
                                                                                                                                                                                                                                                                   '0000000100001000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
                                                                                                                                                                                                                                                                   '1000000100001000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
  ),
   '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1';
  
  
    is_deeply VPCMPEQB(                                                           # 512  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  #Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
  #D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
  #W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
  #B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
  #b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
   '1'.    '1'.    '1'.    '0'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1',
   '00000000110000001000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
   '00000000110000000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
  ),
   '1'.    '1'.    '0'.    '0'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1';
  

=head2 VPCMPEQW($k2, $xmm1, $xmm2)

Packed CoMPare EQual Byte with optional masking

     Parameter  Description
  1  $k2        Optional input mask
  2  $xmm1      Bytes
  3  $xmm2      Bytes

=head2 vpcmpu($size, $k2, $xmm1, $xmm2, $op)

Packed CoMPare Unsigned Byte

     Parameter  Description
  1  $size      Size of element in bits
  2  $k2        Input mask
  3  $xmm1      Bytes
  4  $xmm2      Bytes
  5  $op        Test code

=head2 VPCMPUB($k2, $xmm1, $xmm2, $op)

Packed CoMPare Unsigned Byte

     Parameter  Description
  1  $k2        Input mask
  2  $xmm1      Bytes
  3  $xmm2      Bytes
  4  $op        Test code

B<Example:>


    my ($mi, $mo, $o1, $o2) = (                                                   # 128
  #Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
  #D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
  #W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
  #B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
  #b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
   '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1',
   '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1',
                                                                                                                                                                                                                                                                                                                                                                                                   '00000001000010000000000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
                                                                                                                                                                                                                                                                                                                                                                                                   '10000001000010000000000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
  );
  
  
    is_deeply VPCMPUB($mi, $o1, $o2, 0), $mo;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply VPCMPUB($mi, $o1, $o2, 4), zBytes(6).flipBitsUnderMask substr($mo, 48), substr($mi, 48);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    my ($mi, $mo, $o1, $o2) = (                                                   # 256
  #Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
  #D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
  #W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
  #B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
  #b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
   '1'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '1'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1',
   '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1',
                                                                                                                                                                                                                                                                   '0000000100001000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
                                                                                                                                                                                                                                                                   '1000000100001000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
  );
  
    is_deeply VPCMPUB($mi, $o1, $o2, 0), $mo;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply VPCMPUB($mi, $o1, $o2, 4), zBytes(4).flipBitsUnderMask substr($mo, 32), substr($mi, 32);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    my ($mi, $meq, $mlt, $mgt, $o1, $o2) = (                                      # 512
  #Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
  #D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
  #W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
  #B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
  #b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
   '1'.    '1'.    '1'.    '0'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1',
   '1'.    '1'.    '0'.    '0'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1',
   '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0',
   '0'.    '0'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '0'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0',
   '00000000110000001000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110000000110000111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
   '00000000110000000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011000001100000011111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
  );
  
    is_deeply VPCMPUB($mi, $o1, $o2, 0),                     $meq;                # eq  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply VPCMPUB($mi, $o1, $o2, 1),                     $mlt;                # lt  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply VPCMPUB($mi, $o1, $o2, 2),   flipBitsUnderMask $mgt, $mi;           # le  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply VPCMPUB($mi, $o1, $o2, 4),   flipBitsUnderMask $meq, $mi;           # ne  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply VPCMPUB($mi, $o1, $o2, 5),   flipBitsUnderMask $mlt, $mi;           # ge  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply VPCMPUB($mi, $o1, $o2, 6),                     $mgt;                # gt  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  

=head2 VPCMPUW($k2, $xmm1, $xmm2, $op)

Packed CoMPare Unsigned Word

     Parameter  Description
  1  $k2        Input mask
  2  $xmm1      Words
  3  $xmm2      Words
  4  $op        Test code

B<Example:>


    my ($mi, $meq, $mlt, $mgt, $o1, $o2) = (                                      # 512
  #Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
  #D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
  #W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
  #B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
  #b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
   '1'.            '1'.            '1'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '1'.            '1'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '1',
   '1'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '1',
   '0'.            '0'.            '1'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '1'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0',
   '0'.            '1'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '1'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0',
   '00000000110000001000000001100000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110000000110000011111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
   '00000000110000000000000001100000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011000001100000111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
  );
    for my $i(\($mi, $meq, $mlt, $mgt))
     {$$i = zBytes(4).$$i;
     }
  
    is_deeply VPCMPUW($mi, $o1, $o2, 0),                     $meq;                # eq  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply VPCMPUW($mi, $o1, $o2, 1),                     $mlt;                # lt  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply VPCMPUW($mi, $o1, $o2, 2),   flipBitsUnderMask $mgt, $mi;           # le  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply VPCMPUW($mi, $o1, $o2, 4),   flipBitsUnderMask $meq, $mi;           # ne  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply VPCMPUW($mi, $o1, $o2, 5),   flipBitsUnderMask $mlt, $mi;           # ge  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply VPCMPUW($mi, $o1, $o2, 6),                     $mgt;                # gt  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  

=head2 VPCMPUD($k2, $xmm1, $xmm2, $op)

Packed CoMPare Unsigned Dword

     Parameter  Description
  1  $k2        Input mask
  2  $xmm1      Dwords
  3  $xmm2      Dwords
  4  $op        Test code

B<Example:>


    my ($mi, $meq, $mlt, $mgt, $o1, $o2) = (                                      # 512
  #Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
  #D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
  #W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
  #B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
  #b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
   '1'.                            '1'.                            '1'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '1'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '1',
   '0'.                            '0'.                            '1'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0',
   '0'.                            '1'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0',
   '1'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '1'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '1',
   '00000000110000001000000001100000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110000000110000011111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000',
   '00000000110000000000000001100000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011000001100000111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000',
  );
    for my $i(\($mi, $meq, $mlt, $mgt))
     {$$i = zBytes(6).$$i;
     }
  
    is_deeply VPCMPUD($mi, $o1, $o2, 0),                     $meq;                # eq  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply VPCMPUD($mi, $o1, $o2, 1),                     $mlt;                # lt  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply VPCMPUD($mi, $o1, $o2, 2),   flipBitsUnderMask $mgt, $mi;           # le  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply VPCMPUD($mi, $o1, $o2, 4),   flipBitsUnderMask $meq, $mi;           # ne  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply VPCMPUD($mi, $o1, $o2, 5),   flipBitsUnderMask $mlt, $mi;           # ge  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply VPCMPUD($mi, $o1, $o2, 6),                     $mgt;                # gt  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  

=head2 VPCMPUQ($k2, $xmm1, $xmm2, $op)

Packed CoMPare Unsigned Qword

     Parameter  Description
  1  $k2        Input mask
  2  $xmm1      Qwords
  3  $xmm2      Qwords
  4  $op        Test code

B<Example:>


    my ($mi, $meq, $mlt, $mgt, $o1, $o2) = (                                      # 512
  #Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
  #D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
  #W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
  #B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
  #b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
   '1'.                                                            '1'.                                                            '1'.                                                            '1'.                                                            '1'.                                                            '0'.                                                            '0'.                                                            '1',
   '0'.                                                            '1'.                                                            '0'.                                                            '0'.                                                            '0'.                                                            '0'.                                                            '0'.                                                            '0',
   '1'.                                                            '0'.                                                            '1'.                                                            '1'.                                                            '0'.                                                            '0'.                                                            '0'.                                                            '0',
   '0'.                                                            '0'.                                                            '0'.                                                            '0'.                                                            '1'.                                                            '0'.                                                            '0'.                                                            '1',
   '00000000110000001000000001100000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000000000000000000110000000110000011111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000',
   '00000000110000001000000001100000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000000000000000000011000001100000111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000',
  );
    for my $i(\($mi, $meq, $mlt, $mgt))
     {$$i = zBytes(7).$$i;
     }
  
    is_deeply VPCMPUQ($mi, $o1, $o2, 0),                     $meq;                # eq  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply VPCMPUQ($mi, $o1, $o2, 1),                     $mlt;                # lt  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply VPCMPUQ($mi, $o1, $o2, 2),   flipBitsUnderMask $mgt, $mi;           # le  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply VPCMPUQ($mi, $o1, $o2, 4),   flipBitsUnderMask $meq, $mi;           # ne  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply VPCMPUQ($mi, $o1, $o2, 5),   flipBitsUnderMask $mlt, $mi;           # ge  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    is_deeply VPCMPUQ($mi, $o1, $o2, 6),                     $mgt;                # gt  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  


=head1 Private Methods

=head2 vpcmpeq($size, $k2, $xmm1, $xmm2)

Packed CoMPare EQual Byte|word|double|quad with optional masking

     Parameter  Description
  1  $size      Size in bits: 8|16|32|64 of each element
  2  $k2        Optional input mask
  3  $xmm1      Bytes
  4  $xmm2      Bytes


=head1 Index


1 L<PCMPEQB|/PCMPEQB> - Packed CoMPare EQual Byte

2 L<PSLLDQ|/PSLLDQ> - Packed Shift Left Logical DoubleQword

3 L<PSRLDQ|/PSRLDQ> - Packed Shift Right Logical DoubleQword

4 L<vpcmpeq|/vpcmpeq> - Packed CoMPare EQual Byte|word|double|quad with optional masking

5 L<VPCMPEQB|/VPCMPEQB> - Packed CoMPare EQual Byte with optional masking

6 L<VPCMPEQW|/VPCMPEQW> - Packed CoMPare EQual Byte with optional masking

7 L<vpcmpu|/vpcmpu> - Packed CoMPare Unsigned Byte

8 L<VPCMPUB|/VPCMPUB> - Packed CoMPare Unsigned Byte

9 L<VPCMPUD|/VPCMPUD> - Packed CoMPare Unsigned Dword

10 L<VPCMPUQ|/VPCMPUQ> - Packed CoMPare Unsigned Qword

11 L<VPCMPUW|/VPCMPUW> - Packed CoMPare Unsigned Word

12 L<VPSLLDQ|/VPSLLDQ> - Packed Shift Left Logical DoubleQword

13 L<VPSRLDQ|/VPSRLDQ> - Packed Shift Right Logical DoubleQword

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Simd::Avx512

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2019 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut



# Tests and documentation

sub test
 {my $p = __PACKAGE__;
  binmode($_, ":utf8") for *STDOUT, *STDERR;
  return if eval "eof(${p}::DATA)";
  my $s = eval "join('', <${p}::DATA>)";
  $@ and die $@;
  eval $s;
  $@ and die $@;
  1
 }

test unless caller;

1;
# podDocumentation
__DATA__
use warnings FATAL=>qw(all);
use strict;
require v5.26;
use Time::HiRes qw(time);
use Test::More;

is_deeply flipBitsUnderMask('0101', '1100'), '1001';

if (1) {                                                                        #TPSLLDQ
  is_deeply PSLLDQ(                                                             # 128
#Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
#D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
#W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
#B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
#b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
 '11100001000010000000000011000000000000000100000000001000000000000110000000000000000000111111000000000000000000000000000000001111'
,2),
 '00000000110000000000000001000000000010000000000001100000000000000000001111110000000000000000000000000000000011110000000000000000'
 }

if (1) {                                                                        #TVPSLLDQ
  is_deeply VPSLLDQ(                                                            # 128
#Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
#D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
#W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
#B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
#b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
 '11100001000010000000000011000000000000000100000000001000000000000110000000000000000000111111000000000000000000000000000000001111'
,2),
 '00000000110000000000000001000000000010000000000001100000000000000000001111110000000000000000000000000000000011110000000000000000'
 }

if (1) {                                                                        #TVPSLLDQ
  is_deeply VPSLLDQ(                                                            # 2*128
#Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
#D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
#W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
#B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
#b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
 '11100001000010000000000011000000000000000100000000001000000000000110000000000000000000111111000000000000000000000000000000001111'
.'11100001000010000000000011000000000000000100000000001000000000000110000000000000000000111111000000000000000000000000000000001111'
,2),
 '00000000110000000000000001000000000010000000000001100000000000000000001111110000000000000000000000000000000011110000000000000000'
.'00000000110000000000000001000000000010000000000001100000000000000000001111110000000000000000000000000000000011110000000000000000'
 }

if (1) {                                                                        #TVPSLLDQ
  is_deeply VPSLLDQ(                                                            # 4*128
#Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
#D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
#W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
#B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
#b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
 '11100001000010000000000011000000000000000100000000001000000000000110000000000000000000111111000000000000000000000000000000001111'
.'11100001000010000000000011000000000000000100000000001000000000000110000000000000000000111111000000000000000000000000000000001111'
.'11100001000010000000000011000000000000000100000000001000000000000110000000000000000000111111000000000000000000000000000000001111'
.'11100001000010000000000011000000000000000100000000001000000000000110000000000000000000111111000000000000000000000000000000001111'
,2),
 '00000000110000000000000001000000000010000000000001100000000000000000001111110000000000000000000000000000000011110000000000000000'
.'00000000110000000000000001000000000010000000000001100000000000000000001111110000000000000000000000000000000011110000000000000000'
.'00000000110000000000000001000000000010000000000001100000000000000000001111110000000000000000000000000000000011110000000000000000'
.'00000000110000000000000001000000000010000000000001100000000000000000001111110000000000000000000000000000000011110000000000000000'
 }

if (1) {                                                                        #TPSRLDQ
  is_deeply PSRLDQ(                                                             # 128
#Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
#D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
#W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
#B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
#b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
 '11100001000010000000000011000000000000000100000000001000000000000110000000000000000000111111000000000000000000000000000000001111'
,2),
 '00000000000000001110000100001000000000001100000000000000010000000000100000000000011000000000000000000011111100000000000000000000'
 }

if (1) {                                                                        #TVPSRLDQ
  is_deeply VPSRLDQ(                                                            # 128
#Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
#D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
#W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
#B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
#b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
 '11100001000010000000000011000000000000000100000000001000000000000110000000000000000000111111000000000000000000000000000000001111'
,2),
 '00000000000000001110000100001000000000001100000000000000010000000000100000000000011000000000000000000011111100000000000000000000'
 }

if (1) {                                                                        #TVPSRLDQ
  is_deeply VPSRLDQ(                                                            # 2*128
#Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
#D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
#W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
#B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
#b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
 '11100001000010000000000011000000000000000100000000001000000000000110000000000000000000111111000000000000000000000000000000001111'
.'11100001000010000000000011000000000000000100000000001000000000000110000000000000000000111111000000000000000000000000000000001111'
,2),
 '00000000000000001110000100001000000000001100000000000000010000000000100000000000011000000000000000000011111100000000000000000000'
.'00000000000000001110000100001000000000001100000000000000010000000000100000000000011000000000000000000011111100000000000000000000'
 }

if (1) {                                                                        #TVPSRLDQ
  is_deeply VPSRLDQ(                                                            # 4*128
#Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
#D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
#W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
#B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
#b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
 '11100001000010000000000011000000000000000100000000001000000000000110000000000000000000111111000000000000000000000000000000001111'
.'11100001000010000000000011000000000000000100000000001000000000000110000000000000000000111111000000000000000000000000000000001111'
.'11100001000010000000000011000000000000000100000000001000000000000110000000000000000000111111000000000000000000000000000000001111'
.'11100001000010000000000011000000000000000100000000001000000000000110000000000000000000111111000000000000000000000000000000001111'
,2),
 '00000000000000001110000100001000000000001100000000000000010000000000100000000000011000000000000000000011111100000000000000000000'
.'00000000000000001110000100001000000000001100000000000000010000000000100000000000011000000000000000000011111100000000000000000000'
.'00000000000000001110000100001000000000001100000000000000010000000000100000000000011000000000000000000011111100000000000000000000'
.'00000000000000001110000100001000000000001100000000000000010000000000100000000000011000000000000000000011111100000000000000000000'
 }

if (1) {                                                                        #TPCMPEQB
  is_deeply PCMPEQB(                                                            # 128
#Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
#D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
#W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
#B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
#b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
 '11100001000010000000000011000000000000011000000000010000000000001100000000000000000001111110000000000000000000000000000000011110'
,'11100001000001000000000011000000000000010000000000100000000000001100000000000000000001111110000000000000000000000000000000011010'
),
 '11111111000000001111111111111111111111110000000000000000111111111111111111111111111111111111111111111111111111111111111100000000'
 }

if (1) {                                                                        #TVPCMPEQB
  is_deeply VPCMPEQB(                                                           # 128
#Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
#D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
#W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
#B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
#b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
 '11100001000010000000000011000000000000011000000000010000000000001100000000000000000001111110000000000000000000000000000000011110'
,'11100001000001000000000011000000000000010000000000100000000000001100000000000000000001111110000000000000000000000000000000011010'
),
 '11111111000000001111111111111111111111110000000000000000111111111111111111111111111111111111111111111111111111111111111100000000'
 }

if (1) {                                                                        #TVPCMPEQB
  is_deeply VPCMPEQB(                                                           # 512
#Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
#D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
#W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
#B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
#b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
 '11100001000010000000000011000000000000011000000000010000000000001100000000000000000001111110000000000000000000000000000000011110'
.'11100001000010000000000011000000000000011000000000010000000000001100000000000000000001111110000000000000000000000000000000011110'
,'11100001000001000000000011000000000000010000000000100000000000001100000000000000000001111110000000000000000000000000000000011010'
.'11100001000001000000000011000000000000010000000000100000000000001100000000000000000001111110000000000000000000000000000000011010'
),
 '11111111000000001111111111111111111111110000000000000000111111111111111111111111111111111111111111111111111111111111111100000000'
.'11111111000000001111111111111111111111110000000000000000111111111111111111111111111111111111111111111111111111111111111100000000'
 }

if (1) {                                                                        #TVPCMPEQB
  is_deeply VPCMPEQB(                                                           # 128
#Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
#D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
#W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
#B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
#b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
 '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1',
                                                                                                                                                                                                                                                                                                                                                                                                 '00000001000010000000000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
                                                                                                                                                                                                                                                                                                                                                                                                 '10000001000010000000000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
),
 '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1';
 }

if (1) {                                                                        #TVPCMPEQB
  is_deeply VPCMPEQB(                                                           # 256
#Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
#D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
#W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
#B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
#b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
 '1'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '1'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1',
                                                                                                                                                                                                                                                                 '0000000100001000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
                                                                                                                                                                                                                                                                 '1000000100001000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
),
 '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1';
 }

if (1) {                                                                        #TVPCMPEQB
  is_deeply VPCMPEQB(                                                           # 512
#Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
#D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
#W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
#B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
#b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
 '1'.    '1'.    '1'.    '0'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1',
 '00000000110000001000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
 '00000000110000000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
),
 '1'.    '1'.    '0'.    '0'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1';
 }


if (1) {                                                                        #TVPCMPUB
  my ($mi, $mo, $o1, $o2) = (                                                   # 128
#Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
#D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
#W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
#B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
#b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
 '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1',
 '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1',
                                                                                                                                                                                                                                                                                                                                                                                                 '00000001000010000000000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
                                                                                                                                                                                                                                                                                                                                                                                                 '10000001000010000000000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
);

  is_deeply VPCMPUB($mi, $o1, $o2, 0), $mo;
  is_deeply VPCMPUB($mi, $o1, $o2, 4), zBytes(6).flipBitsUnderMask substr($mo, 48), substr($mi, 48);
 }

if (1) {                                                                        #TVPCMPUB
  my ($mi, $mo, $o1, $o2) = (                                                   # 256
#Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
#D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
#W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
#B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
#b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
 '1'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '1'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1',
 '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1',
                                                                                                                                                                                                                                                                 '0000000100001000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
                                                                                                                                                                                                                                                                 '1000000100001000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
);
  is_deeply VPCMPUB($mi, $o1, $o2, 0), $mo;
  is_deeply VPCMPUB($mi, $o1, $o2, 4), zBytes(4).flipBitsUnderMask substr($mo, 32), substr($mi, 32);
 }

if (1) {                                                                        #TVPCMPUB
  my ($mi, $meq, $mlt, $mgt, $o1, $o2) = (                                      # 512
#Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
#D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
#W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
#B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
#b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
 '1'.    '1'.    '1'.    '0'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1',
 '1'.    '1'.    '0'.    '0'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1',
 '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0',
 '0'.    '0'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '0'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0',
 '00000000110000001000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110000000110000111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
 '00000000110000000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011000001100000011111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
);
  is_deeply VPCMPUB($mi, $o1, $o2, 0),                     $meq;                # eq
  is_deeply VPCMPUB($mi, $o1, $o2, 1),                     $mlt;                # lt
  is_deeply VPCMPUB($mi, $o1, $o2, 2),   flipBitsUnderMask $mgt, $mi;           # le
  is_deeply VPCMPUB($mi, $o1, $o2, 4),   flipBitsUnderMask $meq, $mi;           # ne
  is_deeply VPCMPUB($mi, $o1, $o2, 5),   flipBitsUnderMask $mlt, $mi;           # ge
  is_deeply VPCMPUB($mi, $o1, $o2, 6),                     $mgt;                # gt
 }

if (1) {                                                                        #TVPCMPUW
  my ($mi, $meq, $mlt, $mgt, $o1, $o2) = (                                      # 512
#Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
#D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
#W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
#B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
#b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
 '1'.            '1'.            '1'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '1'.            '1'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '1',
 '1'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '1',
 '0'.            '0'.            '1'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '1'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0',
 '0'.            '1'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '1'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0'.            '0',
 '00000000110000001000000001100000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110000000110000011111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
 '00000000110000000000000001100000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011000001100000111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
);
  for my $i(\($mi, $meq, $mlt, $mgt))
   {$$i = zBytes(4).$$i;
   }
  is_deeply VPCMPUW($mi, $o1, $o2, 0),                     $meq;                # eq
  is_deeply VPCMPUW($mi, $o1, $o2, 1),                     $mlt;                # lt
  is_deeply VPCMPUW($mi, $o1, $o2, 2),   flipBitsUnderMask $mgt, $mi;           # le
  is_deeply VPCMPUW($mi, $o1, $o2, 4),   flipBitsUnderMask $meq, $mi;           # ne
  is_deeply VPCMPUW($mi, $o1, $o2, 5),   flipBitsUnderMask $mlt, $mi;           # ge
  is_deeply VPCMPUW($mi, $o1, $o2, 6),                     $mgt;                # gt
 }

if (1) {                                                                        #TVPCMPUD
  my ($mi, $meq, $mlt, $mgt, $o1, $o2) = (                                      # 512
#Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
#D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
#W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
#B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
#b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
 '1'.                            '1'.                            '1'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '1'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '1',
 '0'.                            '0'.                            '1'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0',
 '0'.                            '1'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0',
 '1'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '1'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '0'.                            '1',
 '00000000110000001000000001100000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110000000110000011111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000',
 '00000000110000000000000001100000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011000001100000111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000',
);
  for my $i(\($mi, $meq, $mlt, $mgt))
   {$$i = zBytes(6).$$i;
   }
  is_deeply VPCMPUD($mi, $o1, $o2, 0),                     $meq;                # eq
  is_deeply VPCMPUD($mi, $o1, $o2, 1),                     $mlt;                # lt
  is_deeply VPCMPUD($mi, $o1, $o2, 2),   flipBitsUnderMask $mgt, $mi;           # le
  is_deeply VPCMPUD($mi, $o1, $o2, 4),   flipBitsUnderMask $meq, $mi;           # ne
  is_deeply VPCMPUD($mi, $o1, $o2, 5),   flipBitsUnderMask $mlt, $mi;           # ge
  is_deeply VPCMPUD($mi, $o1, $o2, 6),                     $mgt;                # gt
 }

if (1) {                                                                        #TVPCMPUQ
  my ($mi, $meq, $mlt, $mgt, $o1, $o2) = (                                      # 512
#Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
#D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
#W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
#B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
#b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
 '1'.                                                            '1'.                                                            '1'.                                                            '1'.                                                            '1'.                                                            '0'.                                                            '0'.                                                            '1',
 '0'.                                                            '1'.                                                            '0'.                                                            '0'.                                                            '0'.                                                            '0'.                                                            '0'.                                                            '0',
 '1'.                                                            '0'.                                                            '1'.                                                            '1'.                                                            '0'.                                                            '0'.                                                            '0'.                                                            '0',
 '0'.                                                            '0'.                                                            '0'.                                                            '0'.                                                            '1'.                                                            '0'.                                                            '0'.                                                            '1',
 '00000000110000001000000001100000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000000000000000000110000000110000011111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000',
 '00000000110000001000000001100000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000000000000000000011000001100000111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000',
);
  for my $i(\($mi, $meq, $mlt, $mgt))
   {$$i = zBytes(7).$$i;
   }
  is_deeply VPCMPUQ($mi, $o1, $o2, 0),                     $meq;                # eq
  is_deeply VPCMPUQ($mi, $o1, $o2, 1),                     $mlt;                # lt
  is_deeply VPCMPUQ($mi, $o1, $o2, 2),   flipBitsUnderMask $mgt, $mi;           # le
  is_deeply VPCMPUQ($mi, $o1, $o2, 4),   flipBitsUnderMask $meq, $mi;           # ne
  is_deeply VPCMPUQ($mi, $o1, $o2, 5),   flipBitsUnderMask $mlt, $mi;           # ge
  is_deeply VPCMPUQ($mi, $o1, $o2, 6),                     $mgt;                # gt
 }


done_testing;

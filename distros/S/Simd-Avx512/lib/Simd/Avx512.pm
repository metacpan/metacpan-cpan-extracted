#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/
#-------------------------------------------------------------------------------
# Simd::Avx512 - Emulate SIMD instructions
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2021
#-------------------------------------------------------------------------------
# podDocumentation
package Simd::Avx512;
our $VERSION = 20210121;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Dump qw(dump);
use feature qw(say current_sub);

sub repeat($$)                                                                  # Repeat a string
 {my ($string, $repeat) = @_;                                                   # String to repeat, number of repetitions
  $string x $repeat
 }

sub zByte {repeat('0', 8)}                                                      # Zero byte

sub zBytes($)                                                                   # String of zero bytes of specified length
 {my ($length) = @_;                                                            # Length
  repeat(zByte, $length)
 }

sub byte($)                                                                     # A byte with the specified value
 {my ($value) = @_;                                                             # Value of the byte
  confess "0 - 255 required" unless $value >= 0 and $value < 2**8;
  sprintf("%08b", $value)
 }

sub maskRegister {zBytes(8)}                                                    # Mask register set to zero

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

sub VPCMPEQB($$;$)                                                              # Packed CoMPare EQual Byte with optional masking
 {my ($k2, $xmm1, $xmm2) = @_ == 3 ? @_ : (undef, @_);                          # Optional input mask, bytes, bytes

  require64or128or245or512 $k2 if defined $k2;                                  # Optional mask
  require128or245or512 $xmm1, $xmm2;                                            # Check that we have a string of 128 bits in the first operand

  my $N = length($xmm1) / 8;                                                    # Bytes in operation
  if (defined $k2)                                                              # Masked operation
   {my $k1 = maskRegister;                                                      # Result register
       $k2 = substr($k2, 48) if $N == 16;                                       # Relevant portion of register
       $k2 = substr($k2, 32) if $N == 32;
    for(0..$N-1)
     {next unless substr($k2, $_, 1) eq '1';
      substr($k1, $_, 1) = substr($xmm1, $_*8, 8) eq substr($xmm2, $_*8, 8) ? '1' : '0';
     }
    return zBytes(6).substr($k1, 0, 16) if $N == 16;
    return zBytes(4).substr($k1, 0, 32) if $N == 32;
    return $k1
   }

  my $xmm3 = zBytes $N;                                                         # Non masked operation
  for(0..$N-1)
   {substr($xmm3, $_*8, 8) = substr($xmm1, $_*8, 8) eq substr($xmm2, $_*8, 8) ?
                             byte(255) : byte(0);
   }
  $xmm3
 }

sub VPCMPUB($$$$)                                                               # Packed CoMPare Unsigned Byte
 {my ($k2, $xmm1, $xmm2, $op) = @_;                                             # Input mask, bytes, bytes, test code

  require64 $k2;                                                                # Mask
  require128or245or512 $xmm1, $xmm2;                                            # Check that we have a string of 128 bits in the first operand
  confess "Invalid op code $op" unless $op =~ m(\A(0|1|2|4|5|6)\Z);             # Test code

  my $test =
   [sub {return 1 if $_[0] eq $_[1]; 0},
    sub {return 1 if $_[0] lt $_[1]; 0},
    sub {return 1 if $_[0] le $_[1]; 0},
    undef,
    sub {return 1 if $_[0] ne $_[1]; 0},
    sub {return 1 if $_[0] ge $_[1]; 0},
    sub {return 1 if $_[0] gt $_[1]; 0},
   ];

  my $N = length($xmm1) / 8;                                                    # Bytes in operation
  my $k1 = maskRegister;
     $k2 = substr($k2, 48) if $N == 16;                                         # Relevant portion of register
     $k2 = substr($k2, 32) if $N == 32;
  for(0..$N-1)
   {next unless substr($k2, $_, 1) eq '1';                                      # Mask
    substr($k1, $_, 1) = &{$$test[$op]}(substr($xmm1, $_*8, 8),                 # Compare according to code
                                        substr($xmm2, $_*8, 8)) ? '1' : '0';
   }

  return zBytes(6).substr($k1, 0, 16) if $N == 16;
  return zBytes(4).substr($k1, 0, 32) if $N == 32;
  return $k1
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


Version 20210121.


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


  
  is_deeply  PSLLDQ(repeat("$b55$b33",  8), 1), repeat(repeat("$b33$b55", 7)."$b33$b00", 1);   # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  

=head2 VPSLLDQ($xmm1, $imm8)

Packed Shift Left Logical DoubleQword

     Parameter  Description
  1  $xmm1      Bytes
  2  $imm8      Length of shift

B<Example:>


  
  is_deeply VPSLLDQ(repeat("$b55$b33", 16), 1), repeat(repeat("$b33$b55", 7)."$b33$b00", 2);   # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  

=head2 PSRLDQ($xmm1, $imm8)

Packed Shift Right Logical DoubleQword

     Parameter  Description
  1  $xmm1      Bytes
  2  $imm8      Length of shift

B<Example:>


  
  is_deeply  PSRLDQ(repeat("$b55$b33",  8), 1), repeat("$b00$b55".repeat("$b33$b55", 7), 1);   # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  

=head2 VPSRLDQ($xmm1, $imm8)

Packed Shift Right Logical DoubleQword

     Parameter  Description
  1  $xmm1      Bytes
  2  $imm8      Length of shift

B<Example:>


  
  is_deeply VPSRLDQ(repeat("$b55$b33", 16), 1), repeat("$b00$b55".repeat("$b33$b55", 7), 2);   # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  

=head2 PCMPEQB($xmm1, $xmm2)

Packed CoMPare EQual Byte

     Parameter  Description
  1  $xmm1      Bytes
  2  $xmm2      Bytes

B<Example:>


  
    is_deeply  PCMPEQB(repeat("$b00$b01$b02$b03",  4),  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

                       repeat("$b06$b05$b04$b03",  4)),
               repeat("$b00$b00$b00$bff",  4);
  

=head2 VPCMPEQB($k2, $xmm1, $xmm2)

Packed CoMPare EQual Byte with optional masking

     Parameter  Description
  1  $k2        Optional input mask
  2  $xmm1      Bytes
  3  $xmm2      Bytes

B<Example:>


  
    is_deeply VPCMPEQB(repeat("$b00$b01$b02$b03",  8),  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

                       repeat("$b06$b05$b04$b03",  8)),
              repeat("$b00$b00$b00$bff",  8);
  
  
    is_deeply VPCMPEQB(                                                           # 128  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  #Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
  #D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
  #W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
  #B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
  #b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
   '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0',
                                                                                                                                                                                                                                                                                                                                                                                                   '00000001000010000000000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
                                                                                                                                                                                                                                                                                                                                                                                                   '10000001000010000000000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
  ),
   '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0';
  

=head2 VPCMPUB($k2, $xmm1, $xmm2, $op)

Packed CoMPare Unsigned Byte

     Parameter  Description
  1  $k2        Input mask
  2  $xmm1      Bytes
  3  $xmm2      Bytes
  4  $op        Test code

B<Example:>


  
    is_deeply VPCMPUB(                                                            # 256  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  #Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
  #D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
  #W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
  #B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
  #b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
   '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0',
                                                                                                                                                                                                                                                                   '0000000100001000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
                                                                                                                                                                                                                                                                   '1000000100001000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
  0),
   '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0';
  
  
    is_deeply VPCMPUB(                                                            # 512  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  #Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
  #D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
  #W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
  #B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
  #b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
   '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0',
   '00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100001000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
   '00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000100001000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
  0),
   '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0';
  


=head1 Index


1 L<PCMPEQB|/PCMPEQB> - Packed CoMPare EQual Byte

2 L<PSLLDQ|/PSLLDQ> - Packed Shift Left Logical DoubleQword

3 L<PSRLDQ|/PSRLDQ> - Packed Shift Right Logical DoubleQword

4 L<VPCMPEQB|/VPCMPEQB> - Packed CoMPare EQual Byte with optional masking

5 L<VPCMPUB|/VPCMPUB> - Packed CoMPare Unsigned Byte

6 L<VPSLLDQ|/VPSLLDQ> - Packed Shift Left Logical DoubleQword

7 L<VPSRLDQ|/VPSRLDQ> - Packed Shift Right Logical DoubleQword

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

my $b00 = zByte;
my $b01 = '00000001';
my $b02 = '00000010';
my $b03 = '00000011';
my $b04 = '00000100';
my $b05 = '00000101';
my $b06 = '00000110';
my $b07 = '00000111';
my $b08 = '00001000';
my $b09 = '00001001';
my $b17 = '00010001';
my $b33 = '00110011';
my $b55 = '01010101';
my $b7f = '01111111';
my $bff = '11111111';

is_deeply $b00, byte( 0);
is_deeply $b01, byte( 1);
is_deeply $b02, byte( 2);
is_deeply $b03, byte( 3);
is_deeply $b04, byte( 4);
is_deeply $b05, byte( 5);
is_deeply $b06, byte( 6);
is_deeply $b07, byte( 7);
is_deeply $b08, byte( 8);
is_deeply $b09, byte( 9);
is_deeply $b17, byte(17);
is_deeply $b33, byte(51);
is_deeply $b55, byte(85);
is_deeply $b7f, byte(127);
is_deeply $bff, byte(255);

is_deeply  PSLLDQ(repeat("$b55$b33",  8), 1), repeat(repeat("$b33$b55", 7)."$b33$b00", 1); #TPSLLDQ
is_deeply VPSLLDQ(repeat("$b55$b33", 16), 1), repeat(repeat("$b33$b55", 7)."$b33$b00", 2); #TVPSLLDQ
is_deeply VPSLLDQ(repeat("$b55$b33", 32), 1), repeat(repeat("$b33$b55", 7)."$b33$b00", 4);

is_deeply  PSRLDQ(repeat("$b55$b33",  8), 1), repeat("$b00$b55".repeat("$b33$b55", 7), 1); #TPSRLDQ
is_deeply VPSRLDQ(repeat("$b55$b33", 16), 1), repeat("$b00$b55".repeat("$b33$b55", 7), 2); #TVPSRLDQ
is_deeply VPSRLDQ(repeat("$b55$b33", 32), 1), repeat("$b00$b55".repeat("$b33$b55", 7), 4);

if (1) {                                                                        #TPCMPEQB
  is_deeply  PCMPEQB(repeat("$b00$b01$b02$b03",  4),
                     repeat("$b06$b05$b04$b03",  4)),
             repeat("$b00$b00$b00$bff",  4);
 }

if (1) {                                                                        #TVPCMPEQB
  is_deeply VPCMPEQB(repeat("$b00$b01$b02$b03",  8),
                     repeat("$b06$b05$b04$b03",  8)),
            repeat("$b00$b00$b00$bff",  8);
 }

is_deeply VPCMPEQB(repeat("$b00$b01$b02$b03", 16),
                   repeat("$b06$b05$b04$b03", 16)),
          repeat("$b00$b00$b00$bff", 16);

is_deeply VPCMPEQB(repeat("$b17",              8),
                   repeat("$b00$b01$b02$b03",  4),
                   repeat("$b06$b05$b02$b03",  4)),
          repeat("$b00", 6).repeat("$b17",     2);

is_deeply VPCMPEQB(repeat("$b17",              8),
                   repeat("$b00$b01$b02$b03",  8),
                   repeat("$b06$b05$b02$b03",  8)),
          repeat("$b00", 4).repeat("$b17", 4);

is_deeply VPCMPEQB(repeat("$b17",               8),
                   repeat("$b00$b01$b02$b03",  16),
                   repeat("$b06$b05$b02$b03",  16)),
          repeat("$b17", 8);

if (1) {                                                                        #TVPCMPEQB
  is_deeply VPCMPEQB(                                                           # 128
#Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
#D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
#W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
#B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
#b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
 '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0',
                                                                                                                                                                                                                                                                                                                                                                                                 '00000001000010000000000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
                                                                                                                                                                                                                                                                                                                                                                                                 '10000001000010000000000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
),
 '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0';
 }

if (1) {                                                                        #TVPCMPUB
  is_deeply VPCMPUB(                                                            # 256
#Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
#D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
#W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
#B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
#b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
 '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0',
                                                                                                                                                                                                                                                                 '0000000100001000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
                                                                                                                                                                                                                                                                 '1000000100001000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
0),
 '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0';
 }

if (1) {                                                                        #TVPCMPUB
  is_deeply VPCMPUB(                                                            # 512
#Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
#D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
#W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
#B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
#b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
 '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0',
 '00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100001000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
 '00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000100001000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
0),
 '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0';
 }

done_testing;

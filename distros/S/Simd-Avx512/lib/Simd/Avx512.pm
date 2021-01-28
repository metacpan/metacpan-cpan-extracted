#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/
#-------------------------------------------------------------------------------
# Simd::Avx512 - Emulate SIMD instructions
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2021
#-------------------------------------------------------------------------------
# podDocumentation
package Simd::Avx512;
our $VERSION = 20210128;
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

sub require128or256or512($;$)                                                   # Check that we have a string of 128|256|512 bits in the first operand and optionally the same in the second operand
 {my ($xmm1, $xmm2) = @_;                                                       # Bytes, optional bytes
  my $l = length $xmm1;
  confess "128|256|512 bits required for first operand ($l)"    unless $l == 128 or $l == 256 or $l == 512;
  if (defined $xmm2)
   {my $m = length $xmm2;
    confess "128|256|512 bits required for second operand ($m)" unless $m == 128 or $m == 256 or $m == 512;
    confess "Operands must have same length($l,$m)" unless $l == $m;
   }
 }

sub require64or128or256or512($)                                                 # Check that we have a string of 64|128|256|512 bits
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

sub compareTwosComplement($$)                                                   # Compare two numbers in two's complement formats and return -1 if the first number is less than the second, 0 if they are equal, else +1
 {my ($a, $b) = @_;                                                             # First, second
  my $n = requireSameLength $a, $b;

  return -1 if substr($a, 0, 1) eq '1' and substr($b, 0, 1) eq '0';             # Leading sign bit
  return +1 if substr($a, 0, 1) eq '0' and substr($b, 0, 1) eq '1';

  for(1..$n)                                                                    # Non sign bits
   {return -1 if substr($a, $_, 1) eq '0' and substr($b, $_, 1) eq '1';
    return +1 if substr($a, $_, 1) eq '1' and substr($b, $_, 1) eq '0';
   }
  0                                                                             # Equal
 }

#D1 Instructions                                                                # Emulation of Avx512 instructions

sub PSLLDQ($$)                                                                  # Packed Shift Left Logical DoubleQword
 {my ($xmm1, $imm8) = @_;                                                       # Bytes, length of shift in bytes
  require128 $xmm1;                                                             # Check that we have a string of 128 bits
  substr($xmm1, $imm8 * 8).zBytes($imm8)
 }

sub VPSLLDQ($$)                                                                 # Packed Shift Left Logical DoubleQword
 {my ($xmm1, $imm8) = @_;                                                       # Bytes, length of shift in bytes
  require128or256or512 $xmm1;                                                   # Check that we have a string of 128 bits
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
  require128or256or512 $xmm1;                                                   # Check that we have a string of 128 bits
  confess "0 - 15 for shift amount required" unless $imm8 >= 0 and $imm8 < 16;

  return PSRLDQ($xmm1, $imm8) if length($xmm1)                   == 128;

  return PSRLDQ(substr($xmm1,   0, 128), $imm8).
         PSRLDQ(substr($xmm1, 128, 128), $imm8) if length($xmm1) == 256;

  return PSRLDQ(substr($xmm1,   0, 128), $imm8).
         PSRLDQ(substr($xmm1, 128, 128), $imm8).
         PSRLDQ(substr($xmm1, 256, 128), $imm8).
         PSRLDQ(substr($xmm1, 384, 128), $imm8)
 }

#D1 PCMP                                                                        # Packed CoMPare
#D2 PCMPEQ                                                                      # Packed CoMPare EQual

sub pcmpeq($$$)                                                                 #P Packed CoMPare EQual
 {my ($size, $xmm1, $xmm2) = @_;                                                # Size in bits, element, element

  require8or16or32or64 $size  if $develop;                                      # We supply this parameter so we ought to get it right
  require128 $xmm1;                                                             # Check that we have a string of 128 bits in the first operand
  require128 $xmm2;                                                             # Check that we have a string of 128 bits in the second operand
  requireSameLength $xmm1, $xmm2;                                               # Check operands have the same length

  my $N = 128 / $size;                                                          # Bytes in operation
  my $clear = '0' x $size;
  my $set   = '1' x $size;
  my $xmm3 = zBytes $N;
  for(0..$N-1)
   {my $o = $_ * $size;
    substr($xmm3, $o, $size) =
    substr($xmm1, $o, $size) eq
    substr($xmm2, $o, $size) ? $set : $clear;
   }
  $xmm3
 }

sub PCMPEQB($$)                                                                 # Packed CoMPare EQual Byte
 {my ($xmm1, $xmm2) = @_;                                                       # Bytes, bytes
  pcmpeq 8, $xmm1, $xmm2;
 }

sub PCMPEQW($$)                                                                 # Packed CoMPare EQual Word
 {my ($xmm1, $xmm2) = @_;                                                       # Words, words
  pcmpeq 16, $xmm1, $xmm2;
 }

sub PCMPEQD($$)                                                                 # Packed CoMPare EQual DWord
 {my ($xmm1, $xmm2) = @_;                                                       # DWords, DWords
  pcmpeq 32, $xmm1, $xmm2;
 }

sub PCMPEQQ($$)                                                                 # Packed CoMPare EQual QWord
 {my ($xmm1, $xmm2) = @_;                                                       # QWords, QWords
  pcmpeq 64, $xmm1, $xmm2;
 }

#D2 PCMPGT                                                                      # Packed CoMPare Greater Than

sub pcmpgt($$$)                                                                 #P Packed CoMPare Greater Than
 {my ($size, $xmm1, $xmm2) = @_;                                                # Size in bits, element, element

  require8or16or32or64 $size  if $develop;                                      # We supply this parameter so we ought to get it right
  require128 $xmm1;                                                             # Check that we have a string of 128 bits in the first operand
  require128 $xmm2;                                                             # Check that we have a string of 128 bits in the second operand
  requireSameLength $xmm1, $xmm2;                                               # Check operands have the same length

  my $N = 128 / $size;                                                          # Bytes in operation
  my $clear = '0' x $size;
  my $set   = '1' x $size;
  my $xmm3 = zBytes $N;
  for(0..$N-1)
   {my $o = $_ * $size;
    substr($xmm3, $o, $size) = +1 == compareTwosComplement(                     # Signed compare
    substr($xmm1, $o, $size),
    substr($xmm2, $o, $size)) ? $set : $clear;
   }
  $xmm3
 }

sub PCMPGTB($$)                                                                 # Packed CoMPare Greater Than Byte
 {my ($xmm1, $xmm2) = @_;                                                       # Bytes, bytes
  pcmpgt 8, $xmm1, $xmm2;
 }

sub PCMPGTW($$)                                                                 # Packed CoMPare Greater Than Word
 {my ($xmm1, $xmm2) = @_;                                                       # Words, words
  pcmpgt 16, $xmm1, $xmm2;
 }

sub PCMPGTD($$)                                                                 # Packed CoMPare Greater Than DWord
 {my ($xmm1, $xmm2) = @_;                                                       # DWords, DWords
  pcmpgt 32, $xmm1, $xmm2;
 }

sub PCMPGTQ($$)                                                                 # Packed CoMPare Greater Than QWord
 {my ($xmm1, $xmm2) = @_;                                                       # QWords, QWords
  pcmpgt 64, $xmm1, $xmm2;
 }

#D1 VPCMP                                                                       # Packed CoMPare
#D2 VPCMPEQ                                                                     # Packed CoMPare EQual

sub vpcmpeq($$$;$)                                                              #P Packed CoMPare EQual Byte|word|double|quad with optional masking
 {my ($size, $k2, $xmm1, $xmm2) = @_;                                           # Size in bits: 8|16|32|64 of each element, optional input mask, bytes, bytes

  require8or16or32or64     $size  if $develop;                                  # We supply this parameter so we ought to get it right
  require64or128or256or512 $k2    if defined $k2;                               # Optional mask
  require128or256or512     $xmm1, $xmm2;                                        # Check that we have a string of 128 bits in the first operand

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
 {my ($k2, $xmm1, $xmm2) = @_ == 3 ? @_ : (undef, @_);                          # Optional input mask, words, words
  vpcmpeq(16, $k2, $xmm1, $xmm2)
 }

sub VPCMPEQD($$;$)                                                              # Packed CoMPare EQual Byte with optional masking
 {my ($k2, $xmm1, $xmm2) = @_ == 3 ? @_ : (undef, @_);                          # Optional input mask, dwords, dwords
  vpcmpeq(32, $k2, $xmm1, $xmm2)
 }

sub VPCMPEQQ($$;$)                                                              # Packed CoMPare EQual Byte with optional masking
 {my ($k2, $xmm1, $xmm2) = @_ == 3 ? @_ : (undef, @_);                          # Optional input mask, qwords, qwords
  vpcmpeq(64, $k2, $xmm1, $xmm2)
 }

#D2 VPCMP                                                                       # Packed CoMPare

sub vpcmp($$$$$)                                                                #P Packed CoMPare
 {my ($size, $k2, $xmm1, $xmm2, $op) = @_;                                      # Size of element in bits, input mask, bytes, bytes, test code

  require8or16or32or64 $size if $develop;                                       # We supply this parameter so we ought to get it right
  require64 $k2;                                                                # Mask
  require128or256or512 $xmm1, $xmm2;                                            # Check that we have a string of 128 bits in the first operand
  confess "Invalid op code $op" unless $op =~ m(\A(0|1|2|4|5|6)\Z);             # Test code

  my $T  =                                                                      # String tests
   [sub {return 1 if compareTwosComplement($_[0], $_[1]) ==  0; 0},             # eq 0
    sub {return 1 if compareTwosComplement($_[0], $_[1]) == -1; 0},             # lt 1
    sub {return 1 if compareTwosComplement($_[0], $_[1]) != +1; 0},             # le 2
    undef,
    sub {return 1 if compareTwosComplement($_[0], $_[1]) !=  0; 0},             # ne 4
    sub {return 1 if compareTwosComplement($_[0], $_[1]) != -1; 0},             # ge 5
    sub {return 1 if compareTwosComplement($_[0], $_[1]) == +1; 0},             # gt 6
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

sub VPCMPB($$$$)                                                                # Packed CoMPare Byte
 {my ($k2, $xmm1, $xmm2, $op) = @_;                                             # Input mask, bytes, bytes, test code
  vpcmp 8, $k2, $xmm1, $xmm2, $op
 }

sub VPCMPW($$$$)                                                                # Packed CoMPare Word
 {my ($k2, $xmm1, $xmm2, $op) = @_;                                             # Input mask, words, words, test code
  vpcmp 16, $k2, $xmm1, $xmm2, $op
 }

sub VPCMPD($$$$)                                                                # Packed CoMPare Dword
 {my ($k2, $xmm1, $xmm2, $op) = @_;                                             # Input mask, dwords, dwords, test code
  vpcmp 32, $k2, $xmm1, $xmm2, $op
 }

sub VPCMPQ($$$$)                                                                # Packed CoMPare Qword
 {my ($k2, $xmm1, $xmm2, $op) = @_;                                             # Input mask, qwords, qwords, test code
  vpcmp 64, $k2, $xmm1, $xmm2, $op
 }

#D2 VPCMPU                                                                      # Packed CoMPare Unsigned

sub vpcmpu($$$$$)                                                               #P Packed CoMPare Unsigned
 {my ($size, $k2, $xmm1, $xmm2, $op) = @_;                                      # Size of element in bits, input mask, bytes, bytes, test code

  require8or16or32or64 $size if $develop;                                       # We supply this parameter so we ought to get it right
  require64 $k2;                                                                # Mask
  require128or256or512 $xmm1, $xmm2;                                            # Check that we have a string of 128 bits in the first operand
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

#D1 VPTEST                                                                      # Packed TEST
#D2 VPTESTM                                                                     # Packed TEST MASK

sub andAndTest($$)                                                              #P And two bit strings of the same length and return 0 if the result is 0 else 1
 {my ($a, $b) = @_;                                                             # Element, element
  my $N = requireSameLength $a, $b;                                             # Check that the two elements have the same length
  for(0..$N-1)                                                                  # Look for match
   {return 1 if substr($a, $_, 1) eq '1' and substr($b, $_, 1) eq '1';
   }
  0
 }

sub vptest($$$)                                                                 #P Packed TEST
 {my ($size, $xmm1, $xmm2) = @_;                                                # Size of element in bits, element, element

  require8or16or32or64 $size if $develop;                                       # We supply this parameter so we ought to get it right
  require128or256or512 $xmm1, $xmm2;                                            # Check that we have a string of 128 bits in the first operand

  my $N  = length($xmm1) / $size;                                               # Number of elements
  my $k1 = maskRegister;
  for(0..$N-1)
   {my $o = $_ * $size;
    substr($k1, $_, 1) = andAndTest(substr($xmm1, $o, $size),                   # Test two elements
                                    substr($xmm2, $o, $size)) ? '1' : '0';
   }

  substr(zBytes(8).substr($k1, 0, $N), -64)
 }

sub VPTESTMB($$)                                                                # Packed TEST Mask Byte
 {my ($xmm1, $xmm2) = @_;                                                       # Bytes, bytes
  vptest 8, $xmm1, $xmm2
 }

sub VPTESTMW($$)                                                                # Packed TEST Mask Word
 {my ($xmm1, $xmm2) = @_;                                                       # Words, words
  vptest 16, $xmm1, $xmm2
 }

sub VPTESTMD($$)                                                                # Packed TEST Mask Dword
 {my ($xmm1, $xmm2) = @_;                                                       # Dwords, dwords
  vptest 32, $xmm1, $xmm2
 }

sub VPTESTMQ($$)                                                                # Packed TEST Mask Quad
 {my ($xmm1, $xmm2) = @_;                                                       # Quads, quads
  vptest 64, $xmm1, $xmm2
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


Version 20210127.


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Instructions

Emulation of Avx512 instructions

=head2 PSLLDQ($xmm1, $imm8)

Packed Shift Left Logical DoubleQword

     Parameter  Description
  1  $xmm1      Bytes
  2  $imm8      Length of shift in bytes

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
  2  $imm8      Length of shift in bytes

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


=head1 PCMP

Packed CoMPare

=head2 PCMPEQ

Packed CoMPare EQual

=head3 PCMPEQB($xmm1, $xmm2)

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


=head3 PCMPEQW($xmm1, $xmm2)

Packed CoMPare EQual Word

     Parameter  Description
  1  $xmm1      Words
  2  $xmm2      Words

B<Example:>



    is_deeply PCMPEQW(                                                            # 128  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  #Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
  #D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
  #W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
  #B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
  #b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
   '11100001000010000000000011000000000000011000000000010000000000001100000000000000000001111110000000000000000000000000000000011110'
  ,'11100001000001000000000011000000000000010000000000100000000000001100000000000000000001111110000000000000000000000000000000011010'
  ),
   '00000000000000001111111111111111000000000000000000000000000000001111111111111111111111111111111111111111111111110000000000000000'


=head3 PCMPEQD($xmm1, $xmm2)

Packed CoMPare EQual DWord

     Parameter  Description
  1  $xmm1      DWords
  2  $xmm2      DWords

B<Example:>



    is_deeply PCMPEQD(                                                            # 128  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  #Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
  #D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
  #W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
  #B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
  #b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
   '11100001000010000000000011000000000000011000000000010000000000001100000000000000000001111110000000000000000000000000000000011110'
  ,'11100001000001000000000011000000000000010000000000100000000000001100000000000000000001111110000000000000000000000000000000011010'
  ),
   '00000000000000000000000000000000000000000000000000000000000000001111111111111111111111111111111100000000000000000000000000000000'


=head3 PCMPEQQ($xmm1, $xmm2)

Packed CoMPare EQual QWord

     Parameter  Description
  1  $xmm1      QWords
  2  $xmm2      QWords

B<Example:>



    is_deeply PCMPEQQ(                                                            # 128  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  #Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
  #D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
  #W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
  #B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
  #b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
   '11100001000011000000000011000000000000011000000000110000000000001100000000000000000001111110000000000000000000000000000000011110'
  ,'11100001000011000000000011000000000000011000000000110000000000001100000000000000000001111110000000000000000000000000000000011010'
  ),
   '11111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000'


=head2 PCMPGT

Packed CoMPare Greater Than

=head3 PCMPGTB($xmm1, $xmm2)

Packed CoMPare Greater Than Byte

     Parameter  Description
  1  $xmm1      Bytes
  2  $xmm2      Bytes

B<Example:>



    is_deeply PCMPGTB(                                                            # 128  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  #Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
  #D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
  #W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
  #B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
  #b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
   '11100001000010000000000011000000010000011000000000010000000000001100000000000000000001111110000000000000000000000000000000011110'
  ,'11100001000001000000000001000000100000010000000000100000000000001100000000000000000001111110000000000000000000000000000000011010'
  ),
   '00000000111111110000000000000000111111110000000000000000000000000000000000000000000000000000000000000000000000000000000011111111'


=head3 PCMPGTW($xmm1, $xmm2)

Packed CoMPare Greater Than Word

     Parameter  Description
  1  $xmm1      Words
  2  $xmm2      Words

B<Example:>



    is_deeply PCMPGTW(                                                            # 128  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  #Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
  #D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
  #W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
  #B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
  #b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
   '11100001000010000000000011000000000000011000000000010000000000001100000000000000000001111110000000000000000000000000000000011110'
  ,'11100001000001000000000011000000000000010000000000100000000000001100000000000000000000111110000000000000000000000000000000011010'
  ),
   '11111111111111110000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000001111111111111111'


=head3 PCMPGTD($xmm1, $xmm2)

Packed CoMPare Greater Than DWord

     Parameter  Description
  1  $xmm1      DWords
  2  $xmm2      DWords

B<Example:>



    is_deeply PCMPGTD(                                                            # 128  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  #Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
  #D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
  #W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
  #B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
  #b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
   '11100001000010000000000011000000000000011000000000010000000000001100000000000000000001111110000000000000000000000000000000011110'
  ,'11100001000001000000000011000000000000010000000000100000000000001100000000000000000001111110000000000000000000000000000000011010'
  ),
   '11111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000011111111111111111111111111111111'


=head3 PCMPGTQ($xmm1, $xmm2)

Packed CoMPare Greater Than QWord

     Parameter  Description
  1  $xmm1      QWords
  2  $xmm2      QWords

B<Example:>



    is_deeply PCMPGTQ(                                                            # 128  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  #Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
  #D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
  #W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
  #B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
  #b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
   '11100001000011000000000011000000000000011000000000110000000000001100000000000000000001111110000000000000000000000000000000011110'
  ,'11100001000011000000000011000000000000011000000000110000000000001100000000000000000001111110000000000000000000000000000000011010'
  ),
   '00000000000000000000000000000000000000000000000000000000000000001111111111111111111111111111111111111111111111111111111111111111'


=head1 VPCMP

Packed CoMPare

=head2 VPCMPEQ

Packed CoMPare EQual

=head3 VPCMPEQB($k2, $xmm1, $xmm2)

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


=head3 VPCMPEQW($k2, $xmm1, $xmm2)

Packed CoMPare EQual Byte with optional masking

     Parameter  Description
  1  $k2        Optional input mask
  2  $xmm1      Words
  3  $xmm2      Words

=head3 VPCMPEQD($k2, $xmm1, $xmm2)

Packed CoMPare EQual Byte with optional masking

     Parameter  Description
  1  $k2        Optional input mask
  2  $xmm1      Dwords
  3  $xmm2      Dwords

=head3 VPCMPEQQ($k2, $xmm1, $xmm2)

Packed CoMPare EQual Byte with optional masking

     Parameter  Description
  1  $k2        Optional input mask
  2  $xmm1      Qwords
  3  $xmm2      Qwords

=head2 VPCMP

Packed CoMPare

=head3 VPCMPB($k2, $xmm1, $xmm2, $op)

Packed CoMPare Byte

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


    is_deeply VPCMPB($mi, $o1, $o2, 0), $mo;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    is_deeply VPCMPB($mi, $o1, $o2, 4), zBytes(6).flipBitsUnderMask substr($mo, 48), substr($mi, 48);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


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

    is_deeply VPCMPB($mi, $o1, $o2, 0), $mo;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    is_deeply VPCMPB($mi, $o1, $o2, 4), zBytes(4).flipBitsUnderMask substr($mo, 32), substr($mi, 32);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    my ($mi, $meq, $mlt, $mgt, $o1, $o2) = (                                      # 512
  #Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
  #D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
  #W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
  #B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
  #b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
   '1'.    '1'.    '1'.    '0'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1',
   '1'.    '1'.    '0'.    '0'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1',
   '0'.    '0'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0',
   '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0',
   '00000000110000001000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110000000110000111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
   '00000000110000000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011000001100000011111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
  );

    is_deeply VPCMPB($mi, $o1, $o2, 0),                     $meq;                 # eq  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    is_deeply VPCMPB($mi, $o1, $o2, 1),                     $mlt;                 # lt  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    is_deeply VPCMPB($mi, $o1, $o2, 2),   flipBitsUnderMask $mgt, $mi;            # le  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    is_deeply VPCMPB($mi, $o1, $o2, 4),   flipBitsUnderMask $meq, $mi;            # ne  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    is_deeply VPCMPB($mi, $o1, $o2, 5),   flipBitsUnderMask $mlt, $mi;            # ge  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    is_deeply VPCMPB($mi, $o1, $o2, 6),                     $mgt;                 # gt  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲



=head3 VPCMPW($k2, $xmm1, $xmm2, $op)

Packed CoMPare Word

     Parameter  Description
  1  $k2        Input mask
  2  $xmm1      Words
  3  $xmm2      Words
  4  $op        Test code

=head3 VPCMPD($k2, $xmm1, $xmm2, $op)

Packed CoMPare Dword

     Parameter  Description
  1  $k2        Input mask
  2  $xmm1      Dwords
  3  $xmm2      Dwords
  4  $op        Test code

=head3 VPCMPQ($k2, $xmm1, $xmm2, $op)

Packed CoMPare Qword

     Parameter  Description
  1  $k2        Input mask
  2  $xmm1      Qwords
  3  $xmm2      Qwords
  4  $op        Test code

=head2 VPCMPU

Packed CoMPare Unsigned

=head3 VPCMPUB($k2, $xmm1, $xmm2, $op)

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



=head3 VPCMPUW($k2, $xmm1, $xmm2, $op)

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



=head3 VPCMPUD($k2, $xmm1, $xmm2, $op)

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



=head3 VPCMPUQ($k2, $xmm1, $xmm2, $op)

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



=head1 VPTEST

Packed TEST

=head2 VPTESTM

Packed TEST MASK

=head3 VPTESTMB($xmm1, $xmm2)

Packed TEST Mask Byte

     Parameter  Description
  1  $xmm1      Bytes
  2  $xmm2      Bytes

B<Example:>


    my ($o1, $o2, $k1) = (                                                        # 128
  #Q0                                                               1                                                               2
  #D0                               1                               2                               3                               4
  #W0               1               2               3               4               5               6               7               0
  #B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0
  #b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670
   '00000001000010000000000011000000000100000000001000010010000000000001100000000000000010100000101000011000000000111111111100010000',
   '10000001000010000000100011001000000001000001000000001100000001000000000000010010000101000001010000000110000111000000000000010000',
   '1'.    '1'.    '0'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1',
  );

    is_deeply VPTESTMB($o1, $o2), zBytes(6).$k1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲



=head3 VPTESTMW($xmm1, $xmm2)

Packed TEST Mask Word

     Parameter  Description
  1  $xmm1      Words
  2  $xmm2      Words

B<Example:>


    my ($o1, $o2, $k1) = (                                                        # 256
  #Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
  #D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
  #W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
  #B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
  #b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
   '0000110100001000000000001100000000010000000000000001001000000000000000000000000000000000110000000000000000000000000011000001000100000001000010000000000011000000000100000000000000010010000000000000010000000000000000000000000000000000000000000000000000010000',
   '0000000101001000000000001100000000010000110000000001001000000000000000000000000000000011000000000000000110000000000000010001000100000001100010000000000011000000000100000010000000010010001000000000000000010000000000000100000000000001100000000000000000010000',
   '1'.            '1'.            '1'.            '1'.            '0'.            '0'.            '0'.            '1'.            '1'.            '1'.            '1'.            '1'.            '0'.            '0'.            '0'.            '1',
  );


    is_deeply VPTESTMW($o1, $o2), zBytes(6).$k1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲



=head3 VPTESTMD($xmm1, $xmm2)

Packed TEST Mask Dword

     Parameter  Description
  1  $xmm1      Dwords
  2  $xmm2      Dwords

B<Example:>


    my ($o1, $o2, $k1) = (                                                        # 512
  #Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
  #D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
  #W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
  #B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
  #b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
   '00011001000010100100000011000000000100000101000000010010000000000000000000000000000000000000000000000001001000100000000000010000000000010000100000000000110000000001000000000000000100000000000000000100000000000000000000000000000000000111110000000000000100000000000100001000000000001110000000010000000000000001111000000000000000001110000000000000000000000001001010101010000000000001000000000001000010000000000011000000000100000100000000010010001000000000010000000000000000000000000000000000000000000000000000010000',
   '00010101000010101000000011000000000100000010100000010010000000000000000000000000000000000000000000000001010010000000000000010000000000010000100000000000110000000001000000000000000100100000010000000001000000000000000000000000000000111100001111100000000100000000000000000000000000000100010000000000000000000000000011000000000000001001000000000000000000000001001001010001010100000001000000000000000000000000000000000000000000100000000000000000000010000000000000000000000000000000000000000000000000000000000000010000',
   '1'.                            '1'.                            '0'.                            '1'.                            '1'.                            '1'.                            '0'.                            '1'.                            '1'.                            '0'.                            '1'.                            '1'.                            '0'.                            '0'.                            '0'.                            '1',
  );


    is_deeply VPTESTMD($o1, $o2), zBytes(6).$k1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲



=head3 VPTESTMQ($xmm1, $xmm2)

Packed TEST Mask Quad

     Parameter  Description
  1  $xmm1      Quads
  2  $xmm2      Quads

B<Example:>


    my ($o1, $o2, $k1) = (                                                        # 512
  #Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
  #D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
  #W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
  #B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
  #b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
   '00011001000010100100000011000000000100000101000000010010000000000000000000000000000000000000000000000001001000100000000000010000000000010000100000000000110000000001000000000000000100000000000000000100000000000000000000000000000000000111110000000000000100000000000100001000000000001110000000010000000000000001001000000000000000000110000000000000000000000000000010101010000000000001000000000001000010000000000011000000000100000100000000010010001000000000010000000001111111111111111111111111111111111111111100000000',
   '00010101000010101000000011000000000100000010100000010010000000000000000000000000000000000000000000000000000000000000000000100000000000001000010000000000000011000000000000000011000000100000010000000001000000000000000000000000000000111000001111100000000000000000000000000000000000000100010000000000000000000001001000000000000000001001000000000000000000000001001001010001010100000010000000000000001100000000000100100000001000100000000000100100000010000000010000000000000000000000000000000000000000000000000000010000',
   '1'.                                                            '0'.                                                            '0'.                                                            '0'.                                                            '1'.                                                            '0'.                                                            '0'.                                                            '1',
  );


    is_deeply VPTESTMQ($o1, $o2), zBytes(7).$k1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲




=head1 Private Methods

=head2 pcmpeq($size, $xmm1, $xmm2)

Packed CoMPare EQual

     Parameter  Description
  1  $size      Size in bits
  2  $xmm1      Element
  3  $xmm2      Element

=head2 pcmpgt($size, $xmm1, $xmm2)

Packed CoMPare Greater Than

     Parameter  Description
  1  $size      Size in bits
  2  $xmm1      Element
  3  $xmm2      Element

=head2 vpcmpeq($size, $k2, $xmm1, $xmm2)

Packed CoMPare EQual Byte|word|double|quad with optional masking

     Parameter  Description
  1  $size      Size in bits: 8|16|32|64 of each element
  2  $k2        Optional input mask
  3  $xmm1      Bytes
  4  $xmm2      Bytes

=head2 vpcmp($size, $k2, $xmm1, $xmm2, $op)

Packed CoMPare

     Parameter  Description
  1  $size      Size of element in bits
  2  $k2        Input mask
  3  $xmm1      Bytes
  4  $xmm2      Bytes
  5  $op        Test code

=head2 vpcmpu($size, $k2, $xmm1, $xmm2, $op)

Packed CoMPare Unsigned

     Parameter  Description
  1  $size      Size of element in bits
  2  $k2        Input mask
  3  $xmm1      Bytes
  4  $xmm2      Bytes
  5  $op        Test code

=head2 andAndTest($a, $b)

And two bit strings of the same length and return 0 if the result is 0 else 1

     Parameter  Description
  1  $a         Element
  2  $b         Element

=head2 vptest($size, $xmm1, $xmm2)

Packed TEST

     Parameter  Description
  1  $size      Size of element in bits
  2  $xmm1      Element
  3  $xmm2      Element


=head1 Index


1 L<andAndTest|/andAndTest> - And two bit strings of the same length and return 0 if the result is 0 else 1

2 L<pcmpeq|/pcmpeq> - Packed CoMPare EQual

3 L<PCMPEQB|/PCMPEQB> - Packed CoMPare EQual Byte

4 L<PCMPEQD|/PCMPEQD> - Packed CoMPare EQual DWord

5 L<PCMPEQQ|/PCMPEQQ> - Packed CoMPare EQual QWord

6 L<PCMPEQW|/PCMPEQW> - Packed CoMPare EQual Word

7 L<pcmpgt|/pcmpgt> - Packed CoMPare Greater Than

8 L<PCMPGTB|/PCMPGTB> - Packed CoMPare Greater Than Byte

9 L<PCMPGTD|/PCMPGTD> - Packed CoMPare Greater Than DWord

10 L<PCMPGTQ|/PCMPGTQ> - Packed CoMPare Greater Than QWord

11 L<PCMPGTW|/PCMPGTW> - Packed CoMPare Greater Than Word

12 L<PSLLDQ|/PSLLDQ> - Packed Shift Left Logical DoubleQword

13 L<PSRLDQ|/PSRLDQ> - Packed Shift Right Logical DoubleQword

14 L<vpcmp|/vpcmp> - Packed CoMPare

15 L<VPCMPB|/VPCMPB> - Packed CoMPare Byte

16 L<VPCMPD|/VPCMPD> - Packed CoMPare Dword

17 L<vpcmpeq|/vpcmpeq> - Packed CoMPare EQual Byte|word|double|quad with optional masking

18 L<VPCMPEQB|/VPCMPEQB> - Packed CoMPare EQual Byte with optional masking

19 L<VPCMPEQD|/VPCMPEQD> - Packed CoMPare EQual Byte with optional masking

20 L<VPCMPEQQ|/VPCMPEQQ> - Packed CoMPare EQual Byte with optional masking

21 L<VPCMPEQW|/VPCMPEQW> - Packed CoMPare EQual Byte with optional masking

22 L<VPCMPQ|/VPCMPQ> - Packed CoMPare Qword

23 L<vpcmpu|/vpcmpu> - Packed CoMPare Unsigned

24 L<VPCMPUB|/VPCMPUB> - Packed CoMPare Unsigned Byte

25 L<VPCMPUD|/VPCMPUD> - Packed CoMPare Unsigned Dword

26 L<VPCMPUQ|/VPCMPUQ> - Packed CoMPare Unsigned Qword

27 L<VPCMPUW|/VPCMPUW> - Packed CoMPare Unsigned Word

28 L<VPCMPW|/VPCMPW> - Packed CoMPare Word

29 L<VPSLLDQ|/VPSLLDQ> - Packed Shift Left Logical DoubleQword

30 L<VPSRLDQ|/VPSRLDQ> - Packed Shift Right Logical DoubleQword

31 L<vptest|/vptest> - Packed TEST

32 L<VPTESTMB|/VPTESTMB> - Packed TEST Mask Byte

33 L<VPTESTMD|/VPTESTMD> - Packed TEST Mask Dword

34 L<VPTESTMQ|/VPTESTMQ> - Packed TEST Mask Quad

35 L<VPTESTMW|/VPTESTMW> - Packed TEST Mask Word

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Simd::Avx512

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2021 Philip R Brenan.

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

#Test::More->builder->output("/dev/null") if -d q(/home/phil/);

is_deeply flipBitsUnderMask('0101', '1100'), '1001';
ok compareTwosComplement('0111', '0011') eq +1;
ok compareTwosComplement('0010', '0011') eq -1;
ok compareTwosComplement('0011', '0011') eq  0;

ok compareTwosComplement('1111', '1011') eq +1;
ok compareTwosComplement('1010', '1011') eq -1;
ok compareTwosComplement('1011', '1011') eq  0;

ok compareTwosComplement('0111', '1011') eq +1;
ok compareTwosComplement('0010', '1011') eq +1;
ok compareTwosComplement('1011', '0011') eq -1;

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

if (1) {                                                                        #TPCMPEQW
  is_deeply PCMPEQW(                                                            # 128
#Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
#D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
#W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
#B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
#b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
 '11100001000010000000000011000000000000011000000000010000000000001100000000000000000001111110000000000000000000000000000000011110'
,'11100001000001000000000011000000000000010000000000100000000000001100000000000000000001111110000000000000000000000000000000011010'
),
 '00000000000000001111111111111111000000000000000000000000000000001111111111111111111111111111111111111111111111110000000000000000'
 }

if (1) {                                                                        #TPCMPEQD
  is_deeply PCMPEQD(                                                            # 128
#Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
#D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
#W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
#B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
#b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
 '11100001000010000000000011000000000000011000000000010000000000001100000000000000000001111110000000000000000000000000000000011110'
,'11100001000001000000000011000000000000010000000000100000000000001100000000000000000001111110000000000000000000000000000000011010'
),
 '00000000000000000000000000000000000000000000000000000000000000001111111111111111111111111111111100000000000000000000000000000000'
 }

if (1) {                                                                        #TPCMPEQQ
  is_deeply PCMPEQQ(                                                            # 128
#Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
#D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
#W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
#B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
#b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
 '11100001000011000000000011000000000000011000000000110000000000001100000000000000000001111110000000000000000000000000000000011110'
,'11100001000011000000000011000000000000011000000000110000000000001100000000000000000001111110000000000000000000000000000000011010'
),
 '11111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000'
 }

if (1) {                                                                        #TPCMPGTB
  is_deeply PCMPGTB(                                                            # 128
#Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
#D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
#W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
#B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
#b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
 '11100001000010000000000011000000010000011000000000010000000000001100000000000000000001111110000000000000000000000000000000011110'
,'11100001000001000000000001000000100000010000000000100000000000001100000000000000000001111110000000000000000000000000000000011010'
),
 '00000000111111110000000000000000111111110000000000000000000000000000000000000000000000000000000000000000000000000000000011111111'
 }

if (1) {                                                                        #TPCMPGTW
  is_deeply PCMPGTW(                                                            # 128
#Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
#D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
#W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
#B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
#b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
 '11100001000010000000000011000000000000011000000000010000000000001100000000000000000001111110000000000000000000000000000000011110'
,'11100001000001000000000011000000000000010000000000100000000000001100000000000000000000111110000000000000000000000000000000011010'
),
 '11111111111111110000000000000000111111111111111100000000000000000000000000000000111111111111111100000000000000001111111111111111'
 }

if (1) {                                                                        #TPCMPGTD
  is_deeply PCMPGTD(                                                            # 128
#Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
#D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
#W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
#B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
#b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
 '11100001000010000000000011000000000000011000000000010000000000001100000000000000000001111110000000000000000000000000000000011110'
,'11100001000001000000000011000000000000010000000000100000000000001100000000000000000001111110000000000000000000000000000000011010'
),
 '11111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000011111111111111111111111111111111'
 }

if (1) {                                                                        #TPCMPGTQ
  is_deeply PCMPGTQ(                                                            # 128
#Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
#D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
#W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
#B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
#b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
 '11100001000011000000000011000000000000011000000000110000000000001100000000000000000001111110000000000000000000000000000000011110'
,'11100001000011000000000011000000000000011000000000110000000000001100000000000000000001111110000000000000000000000000000000011010'
),
 '00000000000000000000000000000000000000000000000000000000000000001111111111111111111111111111111111111111111111111111111111111111'
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


if (1) {                                                                        #TVPCMPB
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

  is_deeply VPCMPB($mi, $o1, $o2, 0), $mo;
  is_deeply VPCMPB($mi, $o1, $o2, 4), zBytes(6).flipBitsUnderMask substr($mo, 48), substr($mi, 48);
 }

if (1) {                                                                        #TVPCMPB
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
  is_deeply VPCMPB($mi, $o1, $o2, 0), $mo;
  is_deeply VPCMPB($mi, $o1, $o2, 4), zBytes(4).flipBitsUnderMask substr($mo, 32), substr($mi, 32);
 }

if (1) {                                                                        #TVPCMPB
  my ($mi, $meq, $mlt, $mgt, $o1, $o2) = (                                      # 512
#Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
#D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
#W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
#B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
#b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
 '1'.    '1'.    '1'.    '0'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1',
 '1'.    '1'.    '0'.    '0'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1',
 '0'.    '0'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0',
 '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0',
 '00000000110000001000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110000000110000111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
 '00000000110000000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011000001100000011111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
);
  is_deeply VPCMPB($mi, $o1, $o2, 0),                     $meq;                 # eq
  is_deeply VPCMPB($mi, $o1, $o2, 1),                     $mlt;                 # lt
  is_deeply VPCMPB($mi, $o1, $o2, 2),   flipBitsUnderMask $mgt, $mi;            # le
  is_deeply VPCMPB($mi, $o1, $o2, 4),   flipBitsUnderMask $meq, $mi;            # ne
  is_deeply VPCMPB($mi, $o1, $o2, 5),   flipBitsUnderMask $mlt, $mi;            # ge
  is_deeply VPCMPB($mi, $o1, $o2, 6),                     $mgt;                 # gt
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

if (1) {                                                                        #TVPTESTMB
  my ($o1, $o2, $k1) = (                                                        # 128
#Q0                                                               1                                                               2
#D0                               1                               2                               3                               4
#W0               1               2               3               4               5               6               7               0
#B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0
#b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670
 '00000001000010000000000011000000000100000000001000010010000000000001100000000000000010100000101000011000000000111111111100010000',
 '10000001000010000000100011001000000001000001000000001100000001000000000000010010000101000001010000000110000111000000000000010000',
 '1'.    '1'.    '0'.    '1'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '0'.    '1',
);
  is_deeply VPTESTMB($o1, $o2), zBytes(6).$k1;
 }

if (1) {                                                                        #TVPTESTMW
  my ($o1, $o2, $k1) = (                                                        # 256
#Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
#D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
#W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
#B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
#b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
 '0000110100001000000000001100000000010000000000000001001000000000000000000000000000000000110000000000000000000000000011000001000100000001000010000000000011000000000100000000000000010010000000000000010000000000000000000000000000000000000000000000000000010000',
 '0000000101001000000000001100000000010000110000000001001000000000000000000000000000000011000000000000000110000000000000010001000100000001100010000000000011000000000100000010000000010010001000000000000000010000000000000100000000000001100000000000000000010000',
 '1'.            '1'.            '1'.            '1'.            '0'.            '0'.            '0'.            '1'.            '1'.            '1'.            '1'.            '1'.            '0'.            '0'.            '0'.            '1',
);

  is_deeply VPTESTMW($o1, $o2), zBytes(6).$k1;
 }

if (1) {                                                                        #TVPTESTMD
  my ($o1, $o2, $k1) = (                                                        # 512
#Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
#D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
#W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
#B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
#b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
 '00011001000010100100000011000000000100000101000000010010000000000000000000000000000000000000000000000001001000100000000000010000000000010000100000000000110000000001000000000000000100000000000000000100000000000000000000000000000000000111110000000000000100000000000100001000000000001110000000010000000000000001111000000000000000001110000000000000000000000001001010101010000000000001000000000001000010000000000011000000000100000100000000010010001000000000010000000000000000000000000000000000000000000000000000010000',
 '00010101000010101000000011000000000100000010100000010010000000000000000000000000000000000000000000000001010010000000000000010000000000010000100000000000110000000001000000000000000100100000010000000001000000000000000000000000000000111100001111100000000100000000000000000000000000000100010000000000000000000000000011000000000000001001000000000000000000000001001001010001010100000001000000000000000000000000000000000000000000100000000000000000000010000000000000000000000000000000000000000000000000000000000000010000',
 '1'.                            '1'.                            '0'.                            '1'.                            '1'.                            '1'.                            '0'.                            '1'.                            '1'.                            '0'.                            '1'.                            '1'.                            '0'.                            '0'.                            '0'.                            '1',
);

  is_deeply VPTESTMD($o1, $o2), zBytes(6).$k1;
 }

if (1) {                                                                        #TVPTESTMQ
  my ($o1, $o2, $k1) = (                                                        # 512
#Q0                                                               1                                                               2                                                               3                                                               4                                                               5                                                               6                                                               7                                                               8
#D0                               1                               2                               3                               4                               5                               6                               7                               0                               1                               2                               3                               4                               5                               6                               7                               8
#W0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               0               1               2               3               4               5               6               7               8
#B0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       0       1       2       3       4       5       6       7       8
#b012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345678
 '00011001000010100100000011000000000100000101000000010010000000000000000000000000000000000000000000000001001000100000000000010000000000010000100000000000110000000001000000000000000100000000000000000100000000000000000000000000000000000111110000000000000100000000000100001000000000001110000000010000000000000001001000000000000000000110000000000000000000000000000010101010000000000001000000000001000010000000000011000000000100000100000000010010001000000000010000000001111111111111111111111111111111111111111100000000',
 '00010101000010101000000011000000000100000010100000010010000000000000000000000000000000000000000000000000000000000000000000100000000000001000010000000000000011000000000000000011000000100000010000000001000000000000000000000000000000111000001111100000000000000000000000000000000000000100010000000000000000000001001000000000000000001001000000000000000000000001001001010001010100000010000000000000001100000000000100100000001000100000000000100100000010000000010000000000000000000000000000000000000000000000000000010000',
 '1'.                                                            '0'.                                                            '0'.                                                            '0'.                                                            '1'.                                                            '0'.                                                            '0'.                                                            '1',
);

  is_deeply VPTESTMQ($o1, $o2), zBytes(7).$k1;
 }

if (1) {                                                                        #TpositionOfMostSignificantBitIn64
  my @m = (                                                                     # Test strings
#B0       1       2       3       4       5       6       7
#b0123456701234567012345670123456701234567012345670123456701234567
 '0000000000000000000000000000000000000000000000000000000000000000',
 '0000000000000000000000000000000000000000000000000000000000000001',
 '0000000000000000000000000000000000000000000000000000000000000010',
 '0000000000000000000000000000000000000000000000000000000000000111',
 '0000000000000000000000000000000000000000000000000000001010010000',
 '0000000000000000000000000000000000001000000001100100001010010000',
 '0000000000000000000001001000010000000000000001100100001010010000',
 '0000000000000000100000000000000100000000000001100100001010010000',
 '1000000000000000100000000000000100000000000001100100001010010000',
);
  my @n = (0, 1, 2, 3, 10, 28, 43, 48, 64);                                     # Expected positions of msb

  sub positionOfMostSignificantBitIn64($)                                       # Find the position of the most significant bit in a string of 64 bits starting from 1 for the least significant bit or return 0 if the input field is all zeros
   {my ($s64) = @_;                                                             # String of 64 bits

    my $N = 128;                                                                # 128 bit operations
    my $f = 0;                                                                  # Position of first bit set
    my $x = '0'x$N;                                                             # Double Quad Word set to 0
    my $s = substr $x.$s64, -$N;                                                # 128 bit area needed

    substr(VPTESTMD($s, $s), -2, 1) eq '1' ? ($s = PSRLDQ $s, 4) : ($f += 32);  # Test 2 dwords
    substr(VPTESTMW($s, $s), -2, 1) eq '1' ? ($s = PSRLDQ $s, 2) : ($f += 16);  # Test 2 words
    substr(VPTESTMB($s, $s), -2, 1) eq '1' ? ($s = PSRLDQ $s, 1) : ($f +=  8);  # Test 2 bytes

    $s = substr($s, -8);                                                        # Last byte remaining

    $s < $_ ? ++$f : last for                                                   # Search remaing byte
     (qw(10000000 01000000 00100000 00010000
         00001000 00000100 00000010 00000001));

    64 - $f                                                                     # Position of first bit set
   }

  ok $n[$_] eq positionOfMostSignificantBitIn64 $m[$_] for keys @m              # Test
 }

done_testing;

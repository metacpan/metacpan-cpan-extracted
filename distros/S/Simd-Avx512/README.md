![Test](https://github.com/philiprbrenan/SimdAvx512/workflows/Test/badge.svg)

Single Instruction Multiple Data Emulation in Pure Perl

For documentation see: [CPAN](https://metacpan.org/pod/Simd::Avx512)

```
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
```

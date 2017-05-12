my @exports = grep { !/^is_|NaNInf|^NonBigInt$/ } @MooX::Types::CLike::EXPORT_OK;

# Can't use "package NAMESPACE BLOCK" yet :(
package Dummy::CLike::Test;

use sanity '-namespace::sweep';  # (using dual subrefs here...)

use Moo;
use MooX::Types::MooseLike::Base;
use MooX::Types::CLike ':all';

no strict 'refs';
foreach my $name (@exports) {
   has 'Test_'.$name => (
      is  => 'rw',
      isa => &$name,
   );
}
   
package main;

use sanity;

use Test::More;
use Test::Exception;
use Data::Float;
use Math::BigInt;
use Math::BigFloat;

# configure some basic big number stuff
Math::BigInt  ->config({
   upgrade    => 'Math::BigFloat',
   round_mode => 'common',
   trap_nan   => 0,
   trap_inf   => 0,
});
Math::BigFloat->config({
   round_mode => 'common',
   trap_nan   => 0,
   trap_inf   => 0,
});

my $bigtwo = Math::BigInt->new(2);
my $bigten = Math::BigInt->new(10);

my $obj = Dummy::CLike::Test->new();
my $types = {
   unsigned => [
      (grep { /^U[A-Z]|Unsigned/ } @exports),
      qw(Nibble SemiOctet Byte Octet OctaWord DoubleQuadWord),
   ],
   signed   => [
      (grep { /^S[A-Z]|^Int|Signed|^(?!U)\w+Int$/ } @exports),
      qw(Short Long LongLong),
   ],
   money    => [ grep { /Money$|Currency$/ } @exports ],
   float    => [
      (grep { /^Float|Float$|^Binary|^Extended/ } @exports),
      qw(Half Single Real Double Decimal Quadruple Quad),
   ],
   decimal  => [ grep { /^Decimal\d+/ } @exports ],
   char     => [ grep { /^Char|^WChar/ } @exports ],
   
   int4   => [qw(SNibble SSemiOctet Int4 Signed4)],            uint4   => [qw(Nibble SemiOctet UInt4 Unsigned4)],
   int8   => [qw(SByte SOctet TinyInt Int8 Signed8)],          uint8   => [qw(Byte Octet UnsignedTinyInt UInt8 Unsigned8)],
   int16  => [qw(Short SmallInt Int16 Signed16)],              uint16  => [qw(UShort UnsignedSmallInt UInt16 Unsigned16)],
   int24  => [qw(MediumInt Int24 Signed24)],                   uint24  => [qw(UnsignedMediumInt UInt24 Unsigned24)],
   int32  => [qw(Int Int32 Signed32)],                         uint32  => [qw(UInt UnsignedInt UInt32 Unsigned32)],
   int64  => [qw(Long LongLong BigInt Int64 Signed64)],        uint64  => [qw(ULong ULongLong UnsignedBigInt UInt64 Unsigned64)],
   int128 => [qw(SOctaWord SDoubleQuadWord Int128 Signed128)], uint128 => [qw(OctaWord DoubleQuadWord UInt128 Unsigned128)],

   money32  => [qw(SmallMoney)],
   money64  => [qw(Money Currency)],
   money128 => [qw(BigMoney)],

   float16_4   => [qw(ShortFloat)],
   float16_5   => [qw(Half Float16 Binary16)],
   float32_8   => [qw(Single Real Float Float32 Binary32)],
   float40_8   => [qw(ExtendedSingle Float40)],
   float64_11  => [qw(Double Float64 Binary64)],
   float80_15  => [qw(ExtendedDouble Float80)],
   float104_8  => [qw(Decimal)],
   float128_15 => [qw(Quadruple Quad Float128 Binary128)],
};
$types->{unsafe} = [ map { @$_ } @$types{ (grep { /^[a-z]+(\d+)/ and $1 > 32 } sort keys %$types), 'decimal' } ];

# First, some self-tests on this $types object
foreach my $bits (4,8,16,24,32,64,128) {
   foreach my $type ('int', 'uint') {
      my $key = $type.$bits;
      foreach my $name (@{ $types->{$key} }) {
         my $msg = "Test Sanity Check: $name in $key, but not in";
         die "$msg unsigned" if     ($type eq 'uint' && not ($name ~~ @{ $types->{unsigned} }));
         die "$msg signed"   if     ($type eq 'int'  && not ($name ~~ @{ $types->{signed}   }));
         die "$msg EXPORTS"  unless ($name ~~ @exports);
      }
   }
}
foreach my $bits (32,64,128) {
   my $key = 'money'.$bits;
   foreach my $name (@{ $types->{$key} }) {
      my $msg = "Test Sanity Check: $name in $key, but not in";
      die "$msg money"   unless ($name ~~ @{ $types->{money} });
      die "$msg EXPORTS" unless ($name ~~ @exports);
   }
}
foreach my $args (qw(16_4 16_5 32_8 40_8 64_11 80_15 104_8 128_15)) {
   my $key = 'float'.$args;
   foreach my $name (@{ $types->{$key} }) {
      my $msg = "Test Sanity Check: $name in $key, but not in";
      die "$msg float"   unless ($name ~~ @{ $types->{float} });
      die "$msg EXPORTS" unless ($name ~~ @exports);
   }
}
my @basic = map { @$_ } @$types{qw(unsigned signed money float decimal char)};
foreach my $name (@exports) {
   die "Test Sanity Check: $name in EXPORTS, but not in unsigned,signed,money,float,decimal,char"
      unless ($name ~~ @basic);
}
foreach my $aname (qw(unsigned signed money float decimal char)) {
   foreach my $bname (qw(unsigned signed money float decimal char)) {
      next if $aname eq $bname;
      foreach my $name (@{ $types->{$bname} }) {
         my $msg = "Test Sanity Check: $name found in both $aname and $bname";
         die $msg if ($name ~~ @{ $types->{$aname} });
      }
   }
}

plan tests => scalar @exports;
foreach my $name (@exports) {
   my $sub = 'Test_'.$name;
   
   subtest $sub => sub {
      # classes are required for at least 64-bit and above
      my $is_safe = ($name ~~ $types->{unsafe}) ? 0 : 1;
      my $n1   = $is_safe ? 1 : Math::BigFloat->bone();   # everything else can be overloaded
      my $n0   = $is_safe ? 0 : Math::BigFloat->bzero();  # ...well, almost...
      my $n_1  = -$n1;           # -1
      my $n05  = $n1 / 2;        # +0.5
      my $n15  = $n1 + $n05;     # +1.5
      my $n_25 = -($n15 + $n1);  # -2.5

      my ($nan, $pinf, $ninf);
      if ($is_safe) {
         $nan  = Data::Float::nan;
         $pinf = Data::Float::pos_infinity;
         $ninf = Data::Float::neg_infinity;
      }
      else {
         $nan  = Math::BigFloat->bnan();
         $pinf = Math::BigFloat->binf('+');
         $ninf = Math::BigFloat->binf('-');
      }
      
      # Common tests
      is $obj->$sub($n0), $n0, "$name accepts/== 0";
      is $obj->$sub(),    $n0, "$name == 0";
      is $obj->$sub($n1), $n1, "$name accepts/== 1";
      is $obj->$sub(),    $n1, "$name == 1";
      dies_ok { $obj->$sub('ABC') } "$name rejects 'ABC'";
      
      if ($name ~~ $types->{unsigned}) {
          dies_ok { $obj->$sub($n_1)  } "$name: Unsigned rejects -1";
          dies_ok { $obj->$sub($n05)  } "$name: Unsigned rejects  0.5";
          dies_ok { $obj->$sub($n15)  } "$name: Unsigned rejects  1.5";
          dies_ok { $obj->$sub($n_25) } "$name: Unsigned rejects -2.5";
          dies_ok { $obj->$sub($nan)  } "$name: Unsigned rejects  NaN";
          dies_ok { $obj->$sub($pinf) } "$name: Unsigned rejects +inf";
          dies_ok { $obj->$sub($ninf) } "$name: Unsigned rejects -inf";
      }
      if ($name ~~ $types->{signed}) {
         lives_ok { $obj->$sub($n_1)  } "$name: Signed accepts -1";
          dies_ok { $obj->$sub($n05)  } "$name: Signed rejects  0.5";
          dies_ok { $obj->$sub($n15)  } "$name: Signed rejects  1.5";
          dies_ok { $obj->$sub($n_25) } "$name: Signed rejects -2.5";
          dies_ok { $obj->$sub($nan)  } "$name: Signed rejects  NaN";
          dies_ok { $obj->$sub($pinf) } "$name: Signed rejects +inf";
          dies_ok { $obj->$sub($ninf) } "$name: Signed rejects -inf";
      }
      if ($name ~~ $types->{money}) {
         lives_ok { $obj->$sub($n_1)  } "$name: Money accepts -1";
         lives_ok { $obj->$sub($n05)  } "$name: Money accepts  0.5";
         lives_ok { $obj->$sub($n15)  } "$name: Money accepts  1.5";
         lives_ok { $obj->$sub($n_25) } "$name: Money accepts -2.5";
          
          ### XXX: This behavior is undefined... ###
          # dies_ok { $obj->$sub($nan)  } "$name: Money rejects  NaN";
          # dies_ok { $obj->$sub($pinf) } "$name: Money rejects +inf";
          # dies_ok { $obj->$sub($ninf) } "$name: Money rejects -inf";
      }
      if ($name ~~ $types->{float}) {
         lives_ok { $obj->$sub($n_1)  } "$name: Float accepts -1";
         lives_ok { $obj->$sub($n05)  } "$name: Float accepts  0.5";
         lives_ok { $obj->$sub($n15)  } "$name: Float accepts  1.5";
         lives_ok { $obj->$sub($n_25) } "$name: Float accepts -2.5";
         lives_ok { $obj->$sub($nan)  } "$name: Float accepts  NaN";
         lives_ok { $obj->$sub($pinf) } "$name: Float accepts +inf";
         lives_ok { $obj->$sub($ninf) } "$name: Float accepts -inf";
      }
      if ($name ~~ $types->{decimal}) {
         lives_ok { $obj->$sub($n_1)  } "$name: Decimal accepts -1";
         lives_ok { $obj->$sub($n05)  } "$name: Decimal accepts  0.5";
         lives_ok { $obj->$sub($n15)  } "$name: Decimal accepts  1.5";
         lives_ok { $obj->$sub($n_25) } "$name: Decimal accepts -2.5";
         lives_ok { $obj->$sub($nan)  } "$name: Decimal accepts  NaN";
         lives_ok { $obj->$sub($pinf) } "$name: Decimal accepts +inf";
         lives_ok { $obj->$sub($ninf) } "$name: Decimal accepts -inf";
      }
      if ($name ~~ $types->{char}) {
          dies_ok { $obj->$sub($n_1)  } "$name: Char rejects -1";
          dies_ok { $obj->$sub($n05)  } "$name: Char rejects  0.5";
          dies_ok { $obj->$sub($n15)  } "$name: Char rejects  1.5";
          dies_ok { $obj->$sub($n_25) } "$name: Char rejects -2.5";
          dies_ok { $obj->$sub($nan)  } "$name: Char rejects  NaN";
          dies_ok { $obj->$sub($pinf) } "$name: Char rejects +inf";
          dies_ok { $obj->$sub($ninf) } "$name: Char rejects -inf";
         lives_ok { $obj->$sub('A')   } "$name: Char accepts 'A'";
      }

      # Specific limits

      # (trying to minimize the level of automation while still keep some sanity...)
      foreach my $bits (4,8,16,24,32,64,128) {
         next unless ($name ~~ $types->{'int'.$bits} || $name ~~ $types->{'uint'.$bits});
         my $spos = $bigtwo->copy ** ($bits-1) - 1;  # 8-bit =  127
         my $sneg = -1 - $spos;                      # 8-bit = -128
         my $upos = $bigtwo->copy ** $bits - 1;      # 8-bit =  255

         if ($name ~~ $types->{'int'.$bits}) {
            lives_ok { $obj->$sub($spos+0) } "$name: $bits-bit Int accepts $spos+0 (scalar)";
            lives_ok { $obj->$sub($sneg-0) } "$name: $bits-bit Int accepts $sneg-0 (scalar)";
             dies_ok { $obj->$sub($upos+0) } "$name: $bits-bit Int rejects $upos+0 (scalar)";
             dies_ok { $obj->$sub($spos+1) } "$name: $bits-bit Int rejects $spos+1 (scalar)";
             dies_ok { $obj->$sub($sneg-1) } "$name: $bits-bit Int rejects $sneg-1 (scalar)";
             dies_ok { $obj->$sub($upos+1) } "$name: $bits-bit Int rejects $upos+1 (scalar)";
         }
         if ($name ~~ $types->{'uint'.$bits}) {
            lives_ok { $obj->$sub($spos+0) } "$name: $bits-bit UInt accepts $spos+0 (scalar)";
             dies_ok { $obj->$sub($sneg-0) } "$name: $bits-bit UInt rejects $sneg-0 (scalar)";
            lives_ok { $obj->$sub($upos+0) } "$name: $bits-bit UInt accepts $upos+0 (scalar)";
            lives_ok { $obj->$sub($spos+1) } "$name: $bits-bit UInt accepts $spos+1 (scalar)";
             dies_ok { $obj->$sub($sneg-1) } "$name: $bits-bit UInt rejects $sneg-1 (scalar)";
             dies_ok { $obj->$sub($upos+1) } "$name: $bits-bit UInt rejects $upos+1 (scalar)";
         }

         # classes only for above 32-bit, just to be safe
         if ($bits <= 32) {
            $spos = 2 ** ($bits-1) - 1;  # 8-bit =  127
            $sneg = -1 - $spos;          # 8-bit = -128
            $upos = 2 ** $bits - 1;      # 8-bit =  255
         
            if ($name ~~ $types->{'int'.$bits}) {
               lives_ok { $obj->$sub($spos+0) } "$name: $bits-bit Int accepts $spos+0 (BigInt)";
               lives_ok { $obj->$sub($sneg-0) } "$name: $bits-bit Int accepts $sneg-0 (BigInt)";
                dies_ok { $obj->$sub($upos+0) } "$name: $bits-bit Int rejects $upos+0 (BigInt)";
                dies_ok { $obj->$sub($spos+1) } "$name: $bits-bit Int rejects $spos+1 (BigInt)";
                dies_ok { $obj->$sub($sneg-1) } "$name: $bits-bit Int rejects $sneg-1 (BigInt)";
                dies_ok { $obj->$sub($upos+1) } "$name: $bits-bit Int rejects $upos+1 (BigInt)";
            }
            if ($name ~~ $types->{'uint'.$bits}) {
               lives_ok { $obj->$sub($spos+0) } "$name: $bits-bit UInt accepts $spos+0 (BigInt)";
                dies_ok { $obj->$sub($sneg-0) } "$name: $bits-bit UInt rejects $sneg-0 (BigInt)";
               lives_ok { $obj->$sub($upos+0) } "$name: $bits-bit UInt accepts $upos+0 (BigInt)";
               lives_ok { $obj->$sub($spos+1) } "$name: $bits-bit UInt accepts $spos+1 (BigInt)";
                dies_ok { $obj->$sub($sneg-1) } "$name: $bits-bit UInt rejects $sneg-1 (BigInt)";
                dies_ok { $obj->$sub($upos+1) } "$name: $bits-bit UInt rejects $upos+1 (BigInt)";
            }
         }
      }
      foreach my $bits (32,64,128) {
         next unless ($name ~~ $types->{'money'.$bits});
         my $pos = $bigtwo->copy ** ($bits-1) - 1;
         my $neg = -1 - $pos;
         my $s   = 10 ** -($bits > 64 ? 6 : 4);
         
         $pos = Math::BigFloat->new($pos);
         $neg = Math::BigFloat->new($neg);
         
         $pos *= $s;
         $neg *= $s;

         lives_ok { $obj->$sub($pos+0 ) } "$name: $bits-bit Money accepts $pos+0 (BigFloat)";
         lives_ok { $obj->$sub($neg+0 ) } "$name: $bits-bit Money accepts $neg+0 (BigFloat)";
          dies_ok { $obj->$sub($pos+$s) } "$name: $bits-bit Money rejects $pos+$s (BigFloat)";
          dies_ok { $obj->$sub($neg-$s) } "$name: $bits-bit Money rejects $neg-$s (BigFloat)";
      }
      
      # I hate copying module code for this, but I don't have much of a choice here...
      foreach my $args (qw(16_4 16_5 32_8 40_8 64_11 80_15 104_8 128_15)) {
         my ($bits, $ebits) = split /_/, $args;
         next unless ($name ~~ $types->{'float'.$args});
         my $sbits = $bits - 1 - $ebits;  # remove sign bit and exponent bits = significand precision
         
         # MAX = (2 - 2**(-$sbits-1)) * 2**($ebits-1)
         my $emax = $bigtwo->copy->bpow($ebits-1)->bsub(1);             # Y = (2**($ebits-1)-1)
         my $smin = $bigtwo->copy->bpow(-$sbits-1)->bmul(-1)->badd(2);  # Z = (2 - X) = -X + 2  (where X = 2**(-$sbits-1) )
         my $max  = $bigtwo->copy->bpow($emax)->bmul($smin);            # MAX = 2**Y * Z

         # $max should have auto-upgraded (due to negative bpow), so create a new $bad version
         my $bad = $max;  # my bad?
         $bad =~ s/\..+$//g;  # can't give BigInt any decimals, either
         $bad = Math::BigInt->new($bad);
         $bad->upgrade('');
         
         my $s = 0.0000000000001;
         
         lives_ok { $obj->$sub( $max+0 ) } "$name: $args Float accepts  $max+0 (BigFloat)";
         lives_ok { $obj->$sub(-$max+0 ) } "$name: $args Float accepts -$max+0 (BigFloat)";
          dies_ok { $obj->$sub( $max+$s) } "$name: $args Float rejects  $max+$s (BigFloat)";
          dies_ok { $obj->$sub(-$max-$s) } "$name: $args Float rejects -$max-$s (BigFloat)";
          dies_ok { $obj->$sub($bad)     } "$name: $args Float rejects BigInt";

         # this is a global, even when called by the OO *grumble*
         # see RT #78097: https://rt.cpan.org/Ticket/Display.html?id=78097
         Math::BigInt->upgrade('Math::BigFloat');
      }

      foreach my $args (qw(32_7_96 64_16_384 128_34_6144)) {
         my ($bits, $digits, $emax) = split /_/, $args;
         next unless ($name eq 'Decimal'.$bits);
         
         my $max = $bigten->copy->bpow($emax)->bsub(1);

         my $bad = $max;  # my bad?
         $bad->upgrade('');
         $max = Math::BigFloat->new($max);
         my $s = 0.0000000000001;
         
         lives_ok { $obj->$sub( $max+0 ) } "$name: Decimal$bits accepts  $max+0 (BigFloat)";
         lives_ok { $obj->$sub(-$max+0 ) } "$name: Decimal$bits accepts -$max+0 (BigFloat)";
          dies_ok { $obj->$sub( $max+$s) } "$name: Decimal$bits rejects  $max+$s (BigFloat)";
          dies_ok { $obj->$sub(-$max-$s) } "$name: Decimal$bits rejects -$max-$s (BigFloat)";
          dies_ok { $obj->$sub($bad)     } "$name: Decimal$bits rejects BigInt";

         # this is a global, even when called by the OO *grumble*
         # see RT #78097: https://rt.cpan.org/Ticket/Display.html?id=78097
         Math::BigInt->upgrade('Math::BigFloat');
      }
      
      # Char48/Char64 is going to accept every single character, because UTF-8 is 6 bytes.
      # Ditto for Char32, since UTF-8 currently doesn't have anything beyond the U+1003FF codepage.
      foreach my $bits (8,16,24,32) {
         # We can't just blindly make up FFFFFF characters; UTF-8 has a specific standard
         state $chars = {
             6 => chr 0x24,
             7 => chr 0x80,     
             8 => chr 0xFF,     
            16 => chr 0xC2A2,
            24 => chr 0xE282AC,
            32 => chr 0xF0A4ADA2,
         };

         if ($name eq 'Char'.$bits) {
            foreach my $cb (sort { $a <=> $b } keys %$chars) {
               my $c = $chars->{$cb};
               ($bits >= $cb) ? lives_ok { $obj->$sub($c) } "$name: Char$bits accepts chr ".sprintf('%X', ord $c) :
                                 dies_ok { $obj->$sub($c) } "$name: Char$bits rejects chr ".sprintf('%X', ord $c);
            }
         }
      }
   };
}

done_testing;

1;

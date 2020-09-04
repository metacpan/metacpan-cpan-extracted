package Ordeal::Model::ChaCha20;

# vim: ts=3 sts=3 sw=3 et ai :

# Adapted from Math::Prime::Util::ChaCha 0.70
# https://metacpan.org/pod/Math::Prime::Util::ChaCha
# which is copyright 2017 by Dana Jacobsen E<lt>dana@acm.orgE<gt>

use 5.020;
use strict;
use warnings;
{ our $VERSION = '0.004'; }
use Ouch;
use Mo qw< build default >;
use experimental qw< signatures postderef >;
no warnings qw< experimental::signatures experimental::postderef >;

use constant BITS => (~0 == 4294967295) ? 32 : 64;
use constant CACHE_SIZE => 1000;
use constant ROUNDS     => 20;

use constant RELEASE => 0x01; # 0x00 marks extension

has _state    => ();
has _buffer   => ();
has seed     => ();

sub _bits_rand ($self, $n) {
   while (length($self->{_buffer}) < $n) {
      my $add_on = $self->_core((int($n / 8) + 64) >> 6);
      $self->{_buffer} .= unpack 'b*', $add_on;
   }
   return substr $self->{_buffer}, 0, $n, '';
} ## end sub _bits_rand

sub BUILD ($self) {
   my $seed = $self->seed // do {
      my $s = CORE::rand 1_000_000;
      $s < 4294967295
        ? pack 'V', $s
        : pack 'V2', $s, $s >> 32;
   };
   $self->seed($seed);
   $self->reset;
} ## end sub BUILD ($self)

sub clone ($self) { return ref($self)->new->restore($self->freeze) }

sub freeze ($self) {
   my $release = unpack 'H*', pack 'C*', RELEASE;
   my $state = unpack 'H*', join '', pack 'N*', $self->_state->@*;
   my $buffer = $self->_buffer;
   my $buflen = unpack 'H*', pack 'N', length $buffer;
   $buffer = unpack 'H*', join '', pack 'B*', $buffer;
   my $seed = unpack 'H*', substr $self->seed, 0, 40;
   return join '', $release, $state, $buflen, $buffer, $seed;
}

sub _int_rand_parameters ($self, $N) {
   state $cache = {};
   return $cache->{$N}->@* if exists $cache->{$N};

   # basic parameters, find the minimum number of bits to cover $N
   my $nbits = int(log($N) / log(2));
   my $M = 2 ** $nbits;
   while ($M < $N) {
      $nbits++;
      $M *= 2;
   }
   my $reject_threshold = $M - $M % $N; # same as $N here

   # if there is still space in the cache, this pair will be used many
   # times, so we want to reduce the rejection rate
   if (keys($cache->%*) <= CACHE_SIZE) {

      # The average number of rolls needed to get a non-rejected sample
      # is the inverse of the acceptance probability:
      #
      # $P = $rejected_threshold/$M
      #
      # This means that, on average, we will need $nbits * 1 / $P bits for
      # each successful roll. If this goes beyond $nbits + 1, we might just
      # as well draw one more bit in the first place and get a non-worse
      # rejection rate.
      while (($nbits * $M / $reject_threshold) > ($nbits + 1)) {
         $nbits++;
         $M *= 2;
         $reject_threshold = $M - $M % $N;
      }
   }
   return ($nbits, $reject_threshold);
}

sub int_rand ($self, $low, $high) {
   my $N = $high - $low + 1;
   my ($nbits, $reject_threshold) = $self->_int_rand_parameters($N);
   my $retval = $reject_threshold;
   while ($retval >= $reject_threshold) {
      my $bitsequence = $self->_bits_rand($nbits);
      $retval = 0;
      for my $v (reverse split //, pack 'b*', $bitsequence) {
         $retval <<= 8;
         $retval += ord $v;
      }
   } ## end while ($retval >= $reject_threshold)
   return $low + $retval % $N;
} ## end sub int_rand

sub reset ($self) {
   my $seed = $self->seed;
   $seed .= pack 'C', 0 while length($seed) % 4;
   my @seed = unpack 'V*', substr $seed, 0, 40;
   if (@seed < 10) {
      my $rng = __prng_new(map { $_ <= $#seed ? $seed[$_] : 0 } 0 .. 3);
      push @seed, __prng_next($rng) while @seed < 10;
   }
   ouch 500, 'seed count failure', @seed if @seed != 10;
   $self->_state(
      [
         0x61707865,    0x3320646e,    0x79622d32, 0x6b206574, # 1^ row
         @seed[0 .. 3],                                        # 2^ row
         @seed[4 .. 7],                                        # 3^ row
         0, 0, @seed[8 .. 9],                                  # 4^ row
      ]
   );
   $self->_buffer('');
}

sub _restore_01 ($self, $opaque) {
   for ($opaque) {
      my @state = unpack 'N*', join '', pack 'H*', substr $_, 0, 128, '';
      $self->_state(\@state);
      s{^-}{}mxs;
      my $buflen = unpack 'N', pack 'H*', substr $_, 0, 8, '';
      s{^-}{}mxs;
      my $buffer = '';
      if ($buflen) {
         my $sl = ($buflen + (8 - $buflen % 8) % 8) / 4; # 2 * ... / 8
         $buffer = unpack 'B*', join '', pack 'H*', substr $_, 0, $sl, '';
         $buffer = substr $buffer, 0, $buflen;
      }
      $self->_buffer($buffer);
      s{^-}{}mxs;
      $self->seed(join '', pack 'H*', $_);
   }
   return $self;
}

sub restore ($self, $opaque) {
   my $release = substr $opaque, 0, 2, '';
   my $method = $self->can("_restore_$release")
      or ouch 400, 'cannot restore release', $release;
   $self->$method($opaque);
   return $self;
}

# Simple PRNG used to fill small seeds
sub __prng_next ($s) {
   my $word;
   my $oldstate = $s->[0];
   if (BITS == 64) {
      $s->[0] = ($s->[0] * 747796405 + $s->[1]) & 0xFFFFFFFF;
      $word =
        ((($oldstate >> (($oldstate >> 28) + 4)) ^ $oldstate) * 277803737)
        & 0xFFFFFFFF;
   } ## end if (BITS == 64)
   else {
      {
         use integer;
         $s->[0] = unpack("L", pack("L", $s->[0] * 747796405 + $s->[1]));
      }
      $word =
        (($oldstate >> (($oldstate >> 28) + 4)) ^ $oldstate) & 0xFFFFFFFF;
      { use integer; $word = unpack("L", pack("L", $word * 277803737)); }
   } ## end else [ if (BITS == 64) ]
   ($word >> 22) ^ $word;
} ## end sub __prng_next ($s)

sub __prng_new ($A, $B, $C, $D) {
   my @s = (0, (($B << 1) | 1) & 0xFFFFFFFF);
   __prng_next(\@s);
   $s[0] = ($s[0] + $A) & 0xFFFFFFFF;
   __prng_next(\@s);
   $s[0] = ($s[0] ^ $C) & 0xFFFFFFFF;
   __prng_next(\@s);
   $s[0] = ($s[0] ^ $D) & 0xFFFFFFFF;
   __prng_next(\@s);
   return \@s;
} ## end sub __prng_new

###############################################################################
# Begin ChaCha core, reference RFC 7539
# with change to make blockcount/nonce be 64/64 from 32/96
# Dana Jacobsen, 9 Apr 2017
# Adapted Flavio Poletti, 3 Feb 2018

#  State is:
#       cccccccc  cccccccc  cccccccc  cccccccc
#       kkkkkkkk  kkkkkkkk  kkkkkkkk  kkkkkkkk
#       kkkkkkkk  kkkkkkkk  kkkkkkkk  kkkkkkkk
#       bbbbbbbb  nnnnnnnn  nnnnnnnn  nnnnnnnn
#
#     c=constant k=key b=blockcount n=nonce

# We have to take care with 32-bit Perl so it sticks with integers.
# Unfortunately the pragma "use integer" means signed integer so
# it ruins right shifts.  We also must ensure we save as unsigned.

sub _core ($self, $blocks) {
   my $j  = $self->_state;
   my $ks = '';

   while ($blocks-- > 0) {
      my (
         $x0, $x1, $x2,  $x3,  $x4,  $x5,  $x6,  $x7,
         $x8, $x9, $x10, $x11, $x12, $x13, $x14, $x15
      ) = @$j;
      for (1 .. ROUNDS / 2) {
         use integer;
         if (BITS == 64) {
            $x0 = ($x0 + $x4) & 0xFFFFFFFF;
            $x12 ^= $x0;
            $x12 = (($x12 << 16) | ($x12 >> 16)) & 0xFFFFFFFF;
            $x8 = ($x8 + $x12) & 0xFFFFFFFF;
            $x4 ^= $x8;
            $x4 = (($x4 << 12) | ($x4 >> 20)) & 0xFFFFFFFF;
            $x0 = ($x0 + $x4) & 0xFFFFFFFF;
            $x12 ^= $x0;
            $x12 = (($x12 << 8) | ($x12 >> 24)) & 0xFFFFFFFF;
            $x8 = ($x8 + $x12) & 0xFFFFFFFF;
            $x4 ^= $x8;
            $x4 = (($x4 << 7) | ($x4 >> 25)) & 0xFFFFFFFF;
            $x1 = ($x1 + $x5) & 0xFFFFFFFF;
            $x13 ^= $x1;
            $x13 = (($x13 << 16) | ($x13 >> 16)) & 0xFFFFFFFF;
            $x9 = ($x9 + $x13) & 0xFFFFFFFF;
            $x5 ^= $x9;
            $x5 = (($x5 << 12) | ($x5 >> 20)) & 0xFFFFFFFF;
            $x1 = ($x1 + $x5) & 0xFFFFFFFF;
            $x13 ^= $x1;
            $x13 = (($x13 << 8) | ($x13 >> 24)) & 0xFFFFFFFF;
            $x9 = ($x9 + $x13) & 0xFFFFFFFF;
            $x5 ^= $x9;
            $x5 = (($x5 << 7) | ($x5 >> 25)) & 0xFFFFFFFF;
            $x2 = ($x2 + $x6) & 0xFFFFFFFF;
            $x14 ^= $x2;
            $x14 = (($x14 << 16) | ($x14 >> 16)) & 0xFFFFFFFF;
            $x10 = ($x10 + $x14) & 0xFFFFFFFF;
            $x6 ^= $x10;
            $x6 = (($x6 << 12) | ($x6 >> 20)) & 0xFFFFFFFF;
            $x2 = ($x2 + $x6) & 0xFFFFFFFF;
            $x14 ^= $x2;
            $x14 = (($x14 << 8) | ($x14 >> 24)) & 0xFFFFFFFF;
            $x10 = ($x10 + $x14) & 0xFFFFFFFF;
            $x6 ^= $x10;
            $x6 = (($x6 << 7) | ($x6 >> 25)) & 0xFFFFFFFF;
            $x3 = ($x3 + $x7) & 0xFFFFFFFF;
            $x15 ^= $x3;
            $x15 = (($x15 << 16) | ($x15 >> 16)) & 0xFFFFFFFF;
            $x11 = ($x11 + $x15) & 0xFFFFFFFF;
            $x7 ^= $x11;
            $x7 = (($x7 << 12) | ($x7 >> 20)) & 0xFFFFFFFF;
            $x3 = ($x3 + $x7) & 0xFFFFFFFF;
            $x15 ^= $x3;
            $x15 = (($x15 << 8) | ($x15 >> 24)) & 0xFFFFFFFF;
            $x11 = ($x11 + $x15) & 0xFFFFFFFF;
            $x7 ^= $x11;
            $x7 = (($x7 << 7) | ($x7 >> 25)) & 0xFFFFFFFF;
            $x0 = ($x0 + $x5) & 0xFFFFFFFF;
            $x15 ^= $x0;
            $x15 = (($x15 << 16) | ($x15 >> 16)) & 0xFFFFFFFF;
            $x10 = ($x10 + $x15) & 0xFFFFFFFF;
            $x5 ^= $x10;
            $x5 = (($x5 << 12) | ($x5 >> 20)) & 0xFFFFFFFF;
            $x0 = ($x0 + $x5) & 0xFFFFFFFF;
            $x15 ^= $x0;
            $x15 = (($x15 << 8) | ($x15 >> 24)) & 0xFFFFFFFF;
            $x10 = ($x10 + $x15) & 0xFFFFFFFF;
            $x5 ^= $x10;
            $x5 = (($x5 << 7) | ($x5 >> 25)) & 0xFFFFFFFF;
            $x1 = ($x1 + $x6) & 0xFFFFFFFF;
            $x12 ^= $x1;
            $x12 = (($x12 << 16) | ($x12 >> 16)) & 0xFFFFFFFF;
            $x11 = ($x11 + $x12) & 0xFFFFFFFF;
            $x6 ^= $x11;
            $x6 = (($x6 << 12) | ($x6 >> 20)) & 0xFFFFFFFF;
            $x1 = ($x1 + $x6) & 0xFFFFFFFF;
            $x12 ^= $x1;
            $x12 = (($x12 << 8) | ($x12 >> 24)) & 0xFFFFFFFF;
            $x11 = ($x11 + $x12) & 0xFFFFFFFF;
            $x6 ^= $x11;
            $x6 = (($x6 << 7) | ($x6 >> 25)) & 0xFFFFFFFF;
            $x2 = ($x2 + $x7) & 0xFFFFFFFF;
            $x13 ^= $x2;
            $x13 = (($x13 << 16) | ($x13 >> 16)) & 0xFFFFFFFF;
            $x8 = ($x8 + $x13) & 0xFFFFFFFF;
            $x7 ^= $x8;
            $x7 = (($x7 << 12) | ($x7 >> 20)) & 0xFFFFFFFF;
            $x2 = ($x2 + $x7) & 0xFFFFFFFF;
            $x13 ^= $x2;
            $x13 = (($x13 << 8) | ($x13 >> 24)) & 0xFFFFFFFF;
            $x8 = ($x8 + $x13) & 0xFFFFFFFF;
            $x7 ^= $x8;
            $x7 = (($x7 << 7) | ($x7 >> 25)) & 0xFFFFFFFF;
            $x3 = ($x3 + $x4) & 0xFFFFFFFF;
            $x14 ^= $x3;
            $x14 = (($x14 << 16) | ($x14 >> 16)) & 0xFFFFFFFF;
            $x9 = ($x9 + $x14) & 0xFFFFFFFF;
            $x4 ^= $x9;
            $x4 = (($x4 << 12) | ($x4 >> 20)) & 0xFFFFFFFF;
            $x3 = ($x3 + $x4) & 0xFFFFFFFF;
            $x14 ^= $x3;
            $x14 = (($x14 << 8) | ($x14 >> 24)) & 0xFFFFFFFF;
            $x9 = ($x9 + $x14) & 0xFFFFFFFF;
            $x4 ^= $x9;
            $x4 = (($x4 << 7) | ($x4 >> 25)) & 0xFFFFFFFF;
         } ## end if (BITS == 64)
         else {    # 32-bit
            $x0 += $x4;
            $x12 ^= $x0;
            $x12 = ($x12 << 16) | (($x12 >> 16) & 0xFFFF);
            $x8 += $x12;
            $x4 ^= $x8;
            $x4 = ($x4 << 12) | (($x4 >> 20) & 0xFFF);
            $x0 += $x4;
            $x12 ^= $x0;
            $x12 = ($x12 << 8) | (($x12 >> 24) & 0xFF);
            $x8 += $x12;
            $x4 ^= $x8;
            $x4 = ($x4 << 7) | (($x4 >> 25) & 0x7F);
            $x1 += $x5;
            $x13 ^= $x1;
            $x13 = ($x13 << 16) | (($x13 >> 16) & 0xFFFF);
            $x9 += $x13;
            $x5 ^= $x9;
            $x5 = ($x5 << 12) | (($x5 >> 20) & 0xFFF);
            $x1 += $x5;
            $x13 ^= $x1;
            $x13 = ($x13 << 8) | (($x13 >> 24) & 0xFF);
            $x9 += $x13;
            $x5 ^= $x9;
            $x5 = ($x5 << 7) | (($x5 >> 25) & 0x7F);
            $x2 += $x6;
            $x14 ^= $x2;
            $x14 = ($x14 << 16) | (($x14 >> 16) & 0xFFFF);
            $x10 += $x14;
            $x6 ^= $x10;
            $x6 = ($x6 << 12) | (($x6 >> 20) & 0xFFF);
            $x2 += $x6;
            $x14 ^= $x2;
            $x14 = ($x14 << 8) | (($x14 >> 24) & 0xFF);
            $x10 += $x14;
            $x6 ^= $x10;
            $x6 = ($x6 << 7) | (($x6 >> 25) & 0x7F);
            $x3 += $x7;
            $x15 ^= $x3;
            $x15 = ($x15 << 16) | (($x15 >> 16) & 0xFFFF);
            $x11 += $x15;
            $x7 ^= $x11;
            $x7 = ($x7 << 12) | (($x7 >> 20) & 0xFFF);
            $x3 += $x7;
            $x15 ^= $x3;
            $x15 = ($x15 << 8) | (($x15 >> 24) & 0xFF);
            $x11 += $x15;
            $x7 ^= $x11;
            $x7 = ($x7 << 7) | (($x7 >> 25) & 0x7F);
            $x0 += $x5;
            $x15 ^= $x0;
            $x15 = ($x15 << 16) | (($x15 >> 16) & 0xFFFF);
            $x10 += $x15;
            $x5 ^= $x10;
            $x5 = ($x5 << 12) | (($x5 >> 20) & 0xFFF);
            $x0 += $x5;
            $x15 ^= $x0;
            $x15 = ($x15 << 8) | (($x15 >> 24) & 0xFF);
            $x10 += $x15;
            $x5 ^= $x10;
            $x5 = ($x5 << 7) | (($x5 >> 25) & 0x7F);
            $x1 += $x6;
            $x12 ^= $x1;
            $x12 = ($x12 << 16) | (($x12 >> 16) & 0xFFFF);
            $x11 += $x12;
            $x6 ^= $x11;
            $x6 = ($x6 << 12) | (($x6 >> 20) & 0xFFF);
            $x1 += $x6;
            $x12 ^= $x1;
            $x12 = ($x12 << 8) | (($x12 >> 24) & 0xFF);
            $x11 += $x12;
            $x6 ^= $x11;
            $x6 = ($x6 << 7) | (($x6 >> 25) & 0x7F);
            $x2 += $x7;
            $x13 ^= $x2;
            $x13 = ($x13 << 16) | (($x13 >> 16) & 0xFFFF);
            $x8 += $x13;
            $x7 ^= $x8;
            $x7 = ($x7 << 12) | (($x7 >> 20) & 0xFFF);
            $x2 += $x7;
            $x13 ^= $x2;
            $x13 = ($x13 << 8) | (($x13 >> 24) & 0xFF);
            $x8 += $x13;
            $x7 ^= $x8;
            $x7 = ($x7 << 7) | (($x7 >> 25) & 0x7F);
            $x3 += $x4;
            $x14 ^= $x3;
            $x14 = ($x14 << 16) | (($x14 >> 16) & 0xFFFF);
            $x9 += $x14;
            $x4 ^= $x9;
            $x4 = ($x4 << 12) | (($x4 >> 20) & 0xFFF);
            $x3 += $x4;
            $x14 ^= $x3;
            $x14 = ($x14 << 8) | (($x14 >> 24) & 0xFF);
            $x9 += $x14;
            $x4 ^= $x9;
            $x4 = ($x4 << 7) | (($x4 >> 25) & 0x7F);
         } ## end else [ if (BITS == 64) ]
      } ## end for (1 .. ROUNDS / 2)
      $ks .= pack("V16",
         $x0 + $j->[0],
         $x1 + $j->[1],
         $x2 + $j->[2],
         $x3 + $j->[3],
         $x4 + $j->[4],
         $x5 + $j->[5],
         $x6 + $j->[6],
         $x7 + $j->[7],
         $x8 + $j->[8],
         $x9 + $j->[9],
         $x10 + $j->[10],
         $x11 + $j->[11],
         $x12 + $j->[12],
         $x13 + $j->[13],
         $x14 + $j->[14],
         $x15 + $j->[15]);
      if (++$j->[12] > 4294967295) {
         $j->[12] = 0;
         $j->[13]++;
      }
   } ## end while ($blocks-- > 0)
   return $ks;
} ## end sub _core

# End ChaCha core
###############################################################################

1;
__END__

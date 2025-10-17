package QRCode::Encoder::QRSpec;
use v5.24;
use warnings;
use experimental qw< signatures >;

use Exporter qw< import >;
our @EXPORT_OK = qw<
   qrspec_ecc_spec
   qrspec_data_size
   qrspec_ecc_size
   qrspec_width
   qrspec_remainder
   qrspec_min_version
   qrspec_min_version_for
   qrspec_length_indicator
   qrspec_maximum_words
   qrspec_mode_indicator 
   qrspec_alignment_patterns
   qrspec_format_pattern 
   qrspec_version_pattern 
   qrspec_alignment_patterns 
>;
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

# Liberally taken from libqrencode/qrspec.c, which is distributed with
# LGPL license

sub qrspec_ecc_spec ($version, $level) {
   state $ecc_table = [
      map { _zip_hash([qw< L M Q H >], $_) } (
         #  L         M         Q         H
         [[ 1,  0], [ 1,  0], [ 1,  0], [ 1,  0]],
         [[ 1,  0], [ 1,  0], [ 1,  0], [ 1,  0]],
         [[ 1,  0], [ 1,  0], [ 2,  0], [ 2,  0]],
         [[ 1,  0], [ 2,  0], [ 2,  0], [ 4,  0]],
         [[ 1,  0], [ 2,  0], [ 2,  2], [ 2,  2]],
         [[ 2,  0], [ 4,  0], [ 4,  0], [ 4,  0]],
         [[ 2,  0], [ 4,  0], [ 2,  4], [ 4,  1]],
         [[ 2,  0], [ 2,  2], [ 4,  2], [ 4,  2]],
         [[ 2,  0], [ 3,  2], [ 4,  4], [ 4,  4]],
         [[ 2,  2], [ 4,  1], [ 6,  2], [ 6,  2]],
         [[ 4,  0], [ 1,  4], [ 4,  4], [ 3,  8]],
         [[ 2,  2], [ 6,  2], [ 4,  6], [ 7,  4]],
         [[ 4,  0], [ 8,  1], [ 8,  4], [12,  4]],
         [[ 3,  1], [ 4,  5], [11,  5], [11,  5]],
         [[ 5,  1], [ 5,  5], [ 5,  7], [11,  7]],
         [[ 5,  1], [ 7,  3], [15,  2], [ 3, 13]],
         [[ 1,  5], [10,  1], [ 1, 15], [ 2, 17]],
         [[ 5,  1], [ 9,  4], [17,  1], [ 2, 19]],
         [[ 3,  4], [ 3, 11], [17,  4], [ 9, 16]],
         [[ 3,  5], [ 3, 13], [15,  5], [15, 10]],
         [[ 4,  4], [17,  0], [17,  6], [19,  6]],
         [[ 2,  7], [17,  0], [ 7, 16], [34,  0]],
         [[ 4,  5], [ 4, 14], [11, 14], [16, 14]],
         [[ 6,  4], [ 6, 14], [11, 16], [30,  2]],
         [[ 8,  4], [ 8, 13], [ 7, 22], [22, 13]],
         [[10,  2], [19,  4], [28,  6], [33,  4]],
         [[ 8,  4], [22,  3], [ 8, 26], [12, 28]],
         [[ 3, 10], [ 3, 23], [ 4, 31], [11, 31]],
         [[ 7,  7], [21,  7], [ 1, 37], [19, 26]],
         [[ 5, 10], [19, 10], [15, 25], [23, 25]],
         [[13,  3], [ 2, 29], [42,  1], [23, 28]],
         [[17,  0], [10, 23], [10, 35], [19, 35]],
         [[17,  1], [14, 21], [29, 19], [11, 46]],
         [[13,  6], [14, 23], [44,  7], [59,  1]],
         [[12,  7], [12, 26], [39, 14], [22, 41]],
         [[ 6, 14], [ 6, 34], [46, 10], [ 2, 64]],
         [[17,  4], [29, 14], [49, 10], [24, 46]],
         [[ 4, 18], [13, 32], [48, 14], [42, 32]],
         [[20,  4], [40,  7], [43, 22], [10, 67]],
         [[19,  6], [18, 31], [34, 34], [20, 61]],
      )
   ];

   my ($b1, $b2) = $ecc_table->[$version - 1]{$level}->@*;
   my $data_size = qrspec_data_size($version, $level);
   my $ecc_size  = qrspec_ecc_size($version, $level);
   my @retval;

   push @retval, {
      count => $b1,
      data  => int($data_size / ($b1 + $b2)),
      ecc   => int($ecc_size  / ($b1 + $b2)),
   };

   push @retval, {
      count => $b2,
      data  => ($retval[0]{data} + 1),
      ecc   => $retval[0]{ecc},
   } if $b2;

   return @retval;
}

sub qrspec_width ($version) { 17 + $version * 4 }

{
   state $table = [
      map { $_->{ec} = _zip_hash([qw< L M Q H >], $_->{ec}); $_ } (
         { words =>  26, remainder => 0, ec => [   7,   10,   13,   17]},
         { words =>  44, remainder => 7, ec => [  10,   16,   22,   28]},
         { words =>  70, remainder => 7, ec => [  15,   26,   36,   44]},
         { words => 100, remainder => 7, ec => [  20,   36,   52,   64]},
         { words => 134, remainder => 7, ec => [  26,   48,   72,   88]}, 
         { words => 172, remainder => 7, ec => [  36,   64,   96,  112]},
         { words => 196, remainder => 0, ec => [  40,   72,  108,  130]},
         { words => 242, remainder => 0, ec => [  48,   88,  132,  156]},
         { words => 292, remainder => 0, ec => [  60,  110,  160,  192]},
         { words => 346, remainder => 0, ec => [  72,  130,  192,  224]}, 
         { words => 404, remainder => 0, ec => [  80,  150,  224,  264]},
         { words => 466, remainder => 0, ec => [  96,  176,  260,  308]},
         { words => 532, remainder => 0, ec => [ 104,  198,  288,  352]},
         { words => 581, remainder => 3, ec => [ 120,  216,  320,  384]},
         { words => 655, remainder => 3, ec => [ 132,  240,  360,  432]}, 
         { words => 733, remainder => 3, ec => [ 144,  280,  408,  480]},
         { words => 815, remainder => 3, ec => [ 168,  308,  448,  532]},
         { words => 901, remainder => 3, ec => [ 180,  338,  504,  588]},
         { words => 991, remainder => 3, ec => [ 196,  364,  546,  650]},
         { words =>1085, remainder => 3, ec => [ 224,  416,  600,  700]}, 
         { words =>1156, remainder => 4, ec => [ 224,  442,  644,  750]},
         { words =>1258, remainder => 4, ec => [ 252,  476,  690,  816]},
         { words =>1364, remainder => 4, ec => [ 270,  504,  750,  900]},
         { words =>1474, remainder => 4, ec => [ 300,  560,  810,  960]},
         { words =>1588, remainder => 4, ec => [ 312,  588,  870, 1050]}, 
         { words =>1706, remainder => 4, ec => [ 336,  644,  952, 1110]},
         { words =>1828, remainder => 4, ec => [ 360,  700, 1020, 1200]},
         { words =>1921, remainder => 3, ec => [ 390,  728, 1050, 1260]},
         { words =>2051, remainder => 3, ec => [ 420,  784, 1140, 1350]},
         { words =>2185, remainder => 3, ec => [ 450,  812, 1200, 1440]}, 
         { words =>2323, remainder => 3, ec => [ 480,  868, 1290, 1530]},
         { words =>2465, remainder => 3, ec => [ 510,  924, 1350, 1620]},
         { words =>2611, remainder => 3, ec => [ 540,  980, 1440, 1710]},
         { words =>2761, remainder => 3, ec => [ 570, 1036, 1530, 1800]},
         { words =>2876, remainder => 0, ec => [ 570, 1064, 1590, 1890]}, 
         { words =>3034, remainder => 0, ec => [ 600, 1120, 1680, 1980]},
         { words =>3196, remainder => 0, ec => [ 630, 1204, 1770, 2100]},
         { words =>3362, remainder => 0, ec => [ 660, 1260, 1860, 2220]},
         { words =>3532, remainder => 0, ec => [ 720, 1316, 1950, 2310]},
         { words =>3706, remainder => 0, ec => [ 750, 1372, 2040, 2430]},
      )
   ];

   sub qrspec_data_size ($version, $level) {
      my $item = $table->[$version - 1];
      return $item->{words} - $item->{ec}{$level};
   }

   sub qrspec_ecc_size  ($version, $level) {
      return $table->[$version - 1]{ec}{$level};
   }

   sub qrspec_remainder ($version) { $table->[$version - 1]{remainder} }

   sub qrspec_min_version ($size, $level) {
      state $arefs = {};

      # first run goes through all items in the table, so this function
      # is inefficient if called once per process but gets better when it
      # is used multiple times per process.
      my $aref = $arefs->{$level} //= do {
         [ map { $_->{words} - $_->{ec}{$level} } $table->@* ]
      };

      # do not bother looking for a version if none is possible
      return if $size > $aref->[-1];

      # binary search over $aref
      my ($lo, $hi) = (0, $aref->$#*);
      while ($lo < $hi) {
         my $mi = int(($lo + $hi) / 2);
         my $misz = $aref->[$mi];
         if    ($misz <  $size) { $lo = $mi + 1   }  # move ahead
         elsif ($misz == $size) { $lo = $hi = $mi }  # exact match
         else                   { $hi = $mi       }  # set upper limit
      }
      return $lo + 1;
   }
}

{
   state $table = {
      numeric => '0001',
      alphanumeric => '0010',
      byte => '0100',
      kanji => '1000',
      eci => '0111',
      structured_append => '0011',
      fnc1_1 => '0101',
      fnc1_2 => '1001',
      terminator => '0000',
   };
   sub qrspec_mode_indicator ($mode) { $table->{$mode} }
}

{
   state $table = {
      numeric      => [10, 12, 14],
      alphanumeric => [ 9, 11, 13],
      byte         => [ 8, 16, 16],
      kanji        => [ 8, 10, 12],
   };

   sub qrspec_min_version_for ($mode, $size, $level) {
      state $size_bits_for = {
         numeric => sub ($s) { 10 * int($s / 3) + [0, 4, 7]->[$s % 3] },
         alphanumeric => sub ($s) { 11 * int($s / 2) + 6 * ($s % 2)   },
         byte         => sub ($s) { return  8 * $s },
         kanji        => sub ($s) { return 13 * $s },
      };

      my $min_bits = 4 + $size_bits_for->{$mode}->($size);
      my $lengths = $table->{$mode};
      for my $i (0 .. $lengths->$#*) {
         my $n_bits = $min_bits + $lengths->[$i];
         my $rem = $n_bits % 8;
         my $n_words = (($n_bits - $rem) / 8) + ($rem ? 1 : 0);
         my $version = qrspec_min_version($n_words, $level);
         my $j = $version <= 9 ? 0 : $version <= 26 ? 1 : 2;
         return $version if $i == $j;
      }
      return;
   }

   sub qrspec_length_indicator ($mode, $version) {
      my $l = $version <= 9 ? 0 : $version <= 26 ? 1 : 2;
      return $table->{$mode}[$l];
   }

   sub qrspec_maximum_words ($mode, $version) {
      my $l = $version <= 9 ? 0 : $version <= 26 ? 1 : 2;
      my $bits = $table->{$mode}[$l];
      my $words = (1 << $bits) - 1;
      $words *= 2 if $mode eq 'kanji';
      return $words;
   }
}

sub qrspec_format_pattern ($level, $mask_id) {
   state $formats_for = {
      L => [0x77c4, 0x72f3, 0x7daa, 0x789d, 0x662f, 0x6318, 0x6c41, 0x6976],
      M => [0x5412, 0x5125, 0x5e7c, 0x5b4b, 0x45f9, 0x40ce, 0x4f97, 0x4aa0],
      Q => [0x355f, 0x3068, 0x3f31, 0x3a06, 0x24b4, 0x2183, 0x2eda, 0x2bed],
      H => [0x1689, 0x13be, 0x1ce7, 0x19d0, 0x0762, 0x0255, 0x0d0c, 0x083b],
   };
   return $formats_for->{$level}[$mask_id];
}

sub qrspec_version_pattern ($version) {
   state $version_pattern_for = [ 
               0x07c94, 0x085bc, 0x09a99, 0x0a4d3,  #  7-10
      0x0bbf6, 0x0c762, 0x0d847, 0x0e60d, 0x0f928,  # 11-15
      0x10b78, 0x1145d, 0x12a17, 0x13532, 0x149a6,  # 16-20
      0x15683, 0x168c9, 0x177ec, 0x18ec4, 0x191e1,  # 21-25
      0x1afab, 0x1b08e, 0x1cc1a, 0x1d33f, 0x1ed75,  # 26-30
      0x1f250, 0x209d5, 0x216f0, 0x228ba, 0x2379f,  # 31-35
      0x24b0b, 0x2542e, 0x26a64, 0x27541, 0x28c69,  # 36-40
   ];
   return $version <= 6 ? undef : $version_pattern_for->[$version - 7];
}

sub qrspec_alignment_patterns ($version) {
   state $base = [
                [18    ], [22    ], [26    ], [30    ], #  2- 5
      [34    ], [22, 38], [24, 42], [26, 46], [28, 50], #  6-10
      [30, 54], [32, 58], [34, 62], [26, 46], [26, 48], # 11-15
      [26, 50], [30, 54], [30, 56], [30, 58], [34, 62], # 16-20
      [28, 50], [26, 50], [30, 54], [28, 54], [32, 58], # 21-25
      [30, 58], [34, 62], [26, 50], [30, 54], [26, 52], # 26-30
      [30, 56], [34, 60], [30, 58], [34, 62], [30, 54], # 31-35
      [24, 50], [28, 54], [32, 58], [26, 54], [30, 58], # 35-40
   ];
   state $cache = { 1 => [] };
   my $aref = $cache->{$version} //= do {
      my @offset = (6, $base->[$version - 2]->@*);
      my $width = qrspec_width($version);
      while ('necessary') {
         my $next = 2 * $offset[-1] - $offset[-2];
         last if $next + 2 >= $width;
         push @offset, $next;
      }
      \@offset;
   };
   return $aref->@*;
}

sub _zip_hash ($aref1, $aref2) {
   my %hash;
   @hash{$aref1->@*} = $aref2->@*;
   return \%hash;
}

1;

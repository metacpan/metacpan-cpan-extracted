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

{
   state $table = [
      map { $_->{ec} = _zip_hash([qw< L M Q H >], $_->{ec}); $_ } (
         { width =>  21, words =>  26, remainder => 0, ec => [   7,   10,   13,   17]},
         { width =>  25, words =>  44, remainder => 7, ec => [  10,   16,   22,   28]},
         { width =>  29, words =>  70, remainder => 7, ec => [  15,   26,   36,   44]},
         { width =>  33, words => 100, remainder => 7, ec => [  20,   36,   52,   64]},
         { width =>  37, words => 134, remainder => 7, ec => [  26,   48,   72,   88]}, 
         { width =>  41, words => 172, remainder => 7, ec => [  36,   64,   96,  112]},
         { width =>  45, words => 196, remainder => 0, ec => [  40,   72,  108,  130]},
         { width =>  49, words => 242, remainder => 0, ec => [  48,   88,  132,  156]},
         { width =>  53, words => 292, remainder => 0, ec => [  60,  110,  160,  192]},
         { width =>  57, words => 346, remainder => 0, ec => [  72,  130,  192,  224]}, 
         { width =>  61, words => 404, remainder => 0, ec => [  80,  150,  224,  264]},
         { width =>  65, words => 466, remainder => 0, ec => [  96,  176,  260,  308]},
         { width =>  69, words => 532, remainder => 0, ec => [ 104,  198,  288,  352]},
         { width =>  73, words => 581, remainder => 3, ec => [ 120,  216,  320,  384]},
         { width =>  77, words => 655, remainder => 3, ec => [ 132,  240,  360,  432]}, 
         { width =>  81, words => 733, remainder => 3, ec => [ 144,  280,  408,  480]},
         { width =>  85, words => 815, remainder => 3, ec => [ 168,  308,  448,  532]},
         { width =>  89, words => 901, remainder => 3, ec => [ 180,  338,  504,  588]},
         { width =>  93, words => 991, remainder => 3, ec => [ 196,  364,  546,  650]},
         { width =>  97, words =>1085, remainder => 3, ec => [ 224,  416,  600,  700]}, 
         { width => 101, words =>1156, remainder => 4, ec => [ 224,  442,  644,  750]},
         { width => 105, words =>1258, remainder => 4, ec => [ 252,  476,  690,  816]},
         { width => 109, words =>1364, remainder => 4, ec => [ 270,  504,  750,  900]},
         { width => 113, words =>1474, remainder => 4, ec => [ 300,  560,  810,  960]},
         { width => 117, words =>1588, remainder => 4, ec => [ 312,  588,  870, 1050]}, 
         { width => 121, words =>1706, remainder => 4, ec => [ 336,  644,  952, 1110]},
         { width => 125, words =>1828, remainder => 4, ec => [ 360,  700, 1020, 1200]},
         { width => 129, words =>1921, remainder => 3, ec => [ 390,  728, 1050, 1260]},
         { width => 133, words =>2051, remainder => 3, ec => [ 420,  784, 1140, 1350]},
         { width => 137, words =>2185, remainder => 3, ec => [ 450,  812, 1200, 1440]}, 
         { width => 141, words =>2323, remainder => 3, ec => [ 480,  868, 1290, 1530]},
         { width => 145, words =>2465, remainder => 3, ec => [ 510,  924, 1350, 1620]},
         { width => 149, words =>2611, remainder => 3, ec => [ 540,  980, 1440, 1710]},
         { width => 153, words =>2761, remainder => 3, ec => [ 570, 1036, 1530, 1800]},
         { width => 157, words =>2876, remainder => 0, ec => [ 570, 1064, 1590, 1890]}, 
         { width => 161, words =>3034, remainder => 0, ec => [ 600, 1120, 1680, 1980]},
         { width => 165, words =>3196, remainder => 0, ec => [ 630, 1204, 1770, 2100]},
         { width => 169, words =>3362, remainder => 0, ec => [ 660, 1260, 1860, 2220]},
         { width => 173, words =>3532, remainder => 0, ec => [ 720, 1316, 1950, 2310]},
         { width => 177, words =>3706, remainder => 0, ec => [ 750, 1372, 2040, 2430]},
      )
   ];

   sub qrspec_data_size ($version, $level) {
      my $item = $table->[$version - 1];
      return $item->{words} - $item->{ec}{$level};
   }

   sub qrspec_ecc_size  ($version, $level) {
      return $table->[$version - 1]{ec}{$level};
   }

   sub qrspec_width     ($version) { $table->[$version - 1]{width}     }
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

sub _zip_hash ($aref1, $aref2) {
   my %hash;
   @hash{$aref1->@*} = $aref2->@*;
   return \%hash;
}

1;

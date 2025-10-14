package QRCode::Encoder::Matrix;
use v5.24;
use experimental qw< signatures >;
use List::Util qw< sum >;

use Exporter qw< import >;
our @EXPORT_OK = qw< add_matrix >;

# Parts liberally taken from libqrencode/qrspec.c, which is distributed
# with LGPL license

sub add_matrix ($data) {
   add_base_matrix($data);
   add_quiet($data);
   add_finders($data);
   add_format_reservations($data);   # MUST: before add_timing
   add_version($data);
   add_timing($data);
   add_alignments($data);
   add_codewords($data);
   add_mask($data);
   return $data;
}

sub stringify_matrix ($data) {
   my @chunks;
   my $matrix = $data->{matrix};
   for my $row ($matrix->@*) {
      push @chunks, join '', map { chr($_) } $row->@*;
   }
   return join "\n", @chunks;
}

sub stringify_matrix_2 ($data) {
   my @chunks;
   my $matrix = $data->{matrix};
   for my $row ($matrix->@*) {
      push @chunks, join '', map { ($_ & 0x1) ? '#' : ' ' } $row->@*;
   }
   return join "\n", @chunks;
}

sub add_base_matrix ($data) {
   my $side = $data->{side_size} = 17 + 4 * $data->{version};
   my $eside = $data->{eside_size} = $side + 8;
   $data->{matrix} = [ map { [ ( 0x38 ) x $eside ] } 1 .. $eside ];
   return $data;
}

sub add_finders ($data) {
   my $eside_size = $data->{eside_size};
   add_finder($data, 4 - 1, 4 - 1);
   add_finder($data, 4 - 1, $eside_size - 8 - 4);
   add_finder($data, $eside_size - 8 - 4, 4 - 1);
   return $data;
}

sub add_quiet ($data) {
   my $es = $data->{eside_size};
   my $matrix = $data->{matrix};
   for my $i (0 .. 3) {
      for my $j (0 .. $es - 1) {
         $matrix->[$i][$j] =
         $matrix->[$es - 1 - $i][$j] =
         $matrix->[$j][$i] =
         $matrix->[$j][$es - 1 - $i] = 0x30;
      }
   }
   return $data;
}

sub add_finder ($data, $x, $y) {
   state $shape = [
      [  0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30 ],
      [  0x30, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x30 ],
      [  0x30, 0x31, 0x30, 0x30, 0x30, 0x30, 0x30, 0x31, 0x30 ],
      [  0x30, 0x31, 0x30, 0x31, 0x31, 0x31, 0x30, 0x31, 0x30 ],
      [  0x30, 0x31, 0x30, 0x31, 0x31, 0x31, 0x30, 0x31, 0x30 ],
      [  0x30, 0x31, 0x30, 0x31, 0x31, 0x31, 0x30, 0x31, 0x30 ],
      [  0x30, 0x31, 0x30, 0x30, 0x30, 0x30, 0x30, 0x31, 0x30 ],
      [  0x30, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x30 ],
      [  0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30 ],
   ];
   my $matrix = $data->{matrix};
   for my $yoff (0 .. 8) {
      my $Y = $y + $yoff;
      for my $xoff (0 .. 8) {
         my $X = $x + $xoff;
         $matrix->[$Y][$X] = $shape->[$yoff][$xoff];
      }
   }
   return $data;
}

sub add_format_reservations ($data) {
   my $matrix = $data->{matrix};
   my $es = $data->{eside_size};
   for my $i (0 .. 7) {
      $matrix->[12][$i + 4] =
      $matrix->[12][$i + $es - 4 - 8] =
      $matrix->[$i + $es - 4 - 8][12] =
      $matrix->[$i + 4][12] = 0x32;
   }
   $matrix->[12][12] = 0x32;
   $matrix->[$es - 4 - 8][12] = 0x31;
   return $data;
}

sub add_version_reservations ($data) {
   return $data->{version} <= 6;

   my $matrix = $data->{matrix};
   my $ecstart = $data->{eside_size} - 4 - 7 - 4;
   for my $i (4 .. 9) {
      for my $j ($ecstart .. ($ecstart + 2)) {
         $matrix->[$i][$j] = $matrix->[$j][$i] = 0x32;
      }
   }

   return $data;
}

sub add_timing ($data) {
   my $matrix = $data->{matrix};
   my $es = $data->{eside_size};
   for my $i (12 .. ($es - 4 - 8 - 1)) {  
      $matrix->[$i][10] = $matrix->[10][$i] = 0x35 ^ ($i & 1);
   }
   return $data;
}

sub try_add_alignment_pattern ($data, $x, $y) {
   state $shape = [
      [  0x31, 0x31, 0x31, 0x31, 0x31 ],
      [  0x31, 0x30, 0x30, 0x30, 0x31 ],
      [  0x31, 0x30, 0x31, 0x30, 0x31 ],
      [  0x31, 0x30, 0x30, 0x30, 0x31 ],
      [  0x31, 0x31, 0x31, 0x31, 0x31 ],
   ];
   $x += 4; # offset by quiet zone
   $y += 4; # offset by quiet zone
   my $matrix = $data->{matrix};
   return if $matrix->[$y][$x] < 0x34
      || $matrix->[$y][$x + 4] < 0x34
      || $matrix->[$y + 4][$x] < 0x34;
   for my $i (0 .. 4) {
      for my $j (0 .. 4) {
         $matrix->[$y + $i][$x + $j] = $shape->[$i][$j];
      }
   }
}

sub add_alignments ($data) {
   state $alignment_pattern_for = [
                [18    ], [22    ], [26    ], [30    ], #  2- 5
      [34    ], [22, 38], [24, 42], [26, 46], [28, 50], #  6-10
      [30, 54], [32, 58], [34, 62], [26, 46], [26, 48], # 11-15
      [26, 50], [30, 54], [30, 56], [30, 58], [34, 62], # 16-20
      [28, 50], [26, 50], [30, 54], [28, 54], [32, 58], # 21-25
      [30, 58], [34, 62], [26, 50], [30, 54], [26, 52], # 26-30
      [30, 56], [34, 60], [30, 58], [34, 62], [30, 54], # 31-35
      [24, 50], [28, 54], [32, 58], [26, 54], [30, 58], # 35-40
   ];
   my $version = $data->{version};
   return if $version <= 1;

   my $side_size = $data->{side_size};
   my @offset = (6, $alignment_pattern_for->[$version - 2]->@*);
   while ('necessary') {
      my $next = 2 * $offset[-1] - $offset[-2];
      last if $next + 2 >= $side_size;
      push @offset, $next;
   }

   for my $y_center (@offset) {
      for my $x_center (@offset) {
         try_add_alignment_pattern($data, $x_center - 2, $y_center - 2);
      }
   }

   return $data;
}

sub bits_iterator ($data) {
   my $n_expanded = length($data->{expanded});
   my $rem = $data->{remainder};
   my $i = 0;
   my @queue;
   return sub {
      if (! @queue) {
         if ($i < $n_expanded) {
            push @queue, split m{}mxs, unpack 'B*', substr($data->{expanded}, $i++, 1);
         }
         else {
            push @queue, ('0') x $rem;
            $rem = 0;
         }
      }
      return shift(@queue);
   };
}

sub add_codewords ($data) {
   my $it = bits_iterator($data);
   my $matrix = $data->{matrix};
   my $side_size = $data->{side_size};

   # start from a fake position that would be the last bit of a
   # hypothetical "-1" codeword
   my $x = $side_size - 2;
   my $y = $side_size;
   my $left = 1;
   my $d = -1; # direction
   while (defined(my $bit = $it->())) {
      while ('necessary') {
         if ($x % 2 == $left) {
            ++$x;
            $y += $d;
         }
         else {
            --$x;
         }
         if ($d < 0 && $y < 0) { # reset condition
            $x -= 2;
            $y = 0;
            $d = 1;
         }
         elsif ($d > 0 && $y >= $side_size) { # other reset condition
            $x -= 2;
            $y = $side_size - 1;
            $d = -1;
         }
         if ($x == 6) { # left timing column, skip a column entirely
            $x = 5;
            $left = 0;
         }
         last if $matrix->[$y + 4][$x + 4] > 0x37;  # found suitable position
      }
      $matrix->[$y + 4][$x + 4] = $bit ? 0x37 : 0x36;
   }
   return $data;
}

sub evaluate_matrix ($matrix) {
   return 0
      + evaluate_matrix_adjacents_and_11311($matrix)
      + evaluate_matrix_blocks($matrix)
      + evaluate_matrix_proportion($matrix);
}

sub __row ($matrix, $i) {
   my $max_idx = $matrix->[0]->$#* - 4;
   join('', map { $matrix->[$i + 4][$_] & 0x01 ? 1 : 0 } 4 .. $max_idx);
}

sub __col ($matrix, $i) {
   my $max_idx = $matrix->[0]->$#* - 4;
   join('', map { $matrix->[$_][$i + 4] & 0x01 ? 1 : 0 } 4 .. $max_idx);
}

sub evaluate_matrix_adjacents_and_11311 ($matrix) {
   my $side_size = $matrix->[0]->@* - 8;
   my $penalty = 0;
   my $penalty2 = 0;
   for my $i (0 .. ($side_size - 1)) {
      for my $seq (__row($matrix, $i), __col($matrix, $i)) {

         # adjacences
         my @contributions =
            map  { $_ -  2 }
            grep { $_ >= 5 }
            map  { length  }
            split m{(0+)}mxs, $seq;
         $penalty += sum(@contributions) if @contributions;

         # 000011311 | 113110000
         my @matches = $seq =~ m{
            (
                 (?: (?<=0000) 1011101           )  # look behind...
               | (?:           1011101 (?=0000)  )  # or look ahead
            )
         }gmxs;
         $penalty2 += 40 * scalar(@matches);

      }
   }
   return $penalty + $penalty2;
}

sub evaluate_matrix_blocks ($matrix) {
   my $side_size = $matrix->[0]->@* - 8;
   my $penalty = 0;
   for my $i (0 .. ($side_size - 2)) {
      for my $j (0 .. ($side_size - 2)) {
         my $count = 0;
         for my $offset ([0, 0], [0, 1], [1, 0], [1, 1]) {
            my ($oi, $oj) = $offset->@*;
            $count++ if $matrix->[$i + $oi + 4][$j + $oj + 4] & 1;
         }
         $penalty += 3 if ($count == 0) || ($count == 4);
      }
   }
   return $penalty;
}

sub evaluate_matrix_proportion ($matrix) {
   my $count = sum( map { map { $_ & 0x1 ? 1 : 0 } $_->@* } $matrix->@* );
   my $side_size = $matrix->[0]->@* - 8;
   my $total = $side_size * $side_size;
   my $percentage = 100 * $count / $total;
   my $deviation = abs($percentage - 50);
   my $penalty = 10 * int($deviation / 5);
   return $penalty;
}

sub masked_matrix ($data, $mask_id) {
   state $mask_for = {
      0 => sub ($i, $j) { (($i + $j) % 2) == 0 },
      1 => sub ($i, $j) { ($i % 2) == 0 },
      2 => sub ($i, $j) { ($j % 3) == 0 },
      3 => sub ($i, $j) { (($i + $j) % 3) == 0 },
      4 => sub ($i, $j) { ((int($i / 2) + int($j / 3)) % 2) == 0 },
      5 => sub ($i, $j) { ((($i * $j) % 2) + (($i * $j) % 3)) == 0 },
      6 => sub ($i, $j) { (((($i * $j) % 2) + (($i * $j) % 3)) % 2) == 0 },
      7 => sub ($i, $j) { (((($i + $j) % 2) + (($i * $j) % 3)) % 2) == 0 },
   };
   my $matrix = $data->{matrix};
   my @masked;
   my $eside_size = $data->{eside_size};
   my $mask = $mask_for->{$mask_id};
   for my $i (0 .. ($eside_size - 1)) {
      for my $j (0 .. ($eside_size - 1)) {
         if (($matrix->[$i][$j] >= 0x36) && $mask->($i - 4, $j - 4)) {
            $masked[$i][$j] = $matrix->[$i][$j] ^ 0x01;
         }
         else {
            $masked[$i][$j] = $matrix->[$i][$j];
         }
      }
   }
   return \@masked;
}

sub add_mask ($data) {
   my ($best_mask_id, $best_matrix, $best_penalty);
   $data->{masked} = \my @masked;
   for my $mask_id (0 .. 7) {
      my $matrix = masked_matrix($data, $mask_id);
      add_format($matrix, $data->{level}, $mask_id);
      push @masked, $matrix;
      my $penalty = evaluate_matrix($matrix);
      ($best_mask_id, $best_matrix, $best_penalty) = ($mask_id, $matrix, $penalty)
         if (! $best_matrix) || $penalty < $best_penalty;
   }
   $data->{original_matrix} = delete($data->{matrix});
   $data->{matrix} = $best_matrix;
   $data->{mask_id} = $best_mask_id;
   return $data;
}

sub add_format ($matrix, $level, $mask_id) {

   # FIXME Move into QRSpec?
   state $formats_for = {
      L => [0x77c4, 0x72f3, 0x7daa, 0x789d, 0x662f, 0x6318, 0x6c41, 0x6976],
      M => [0x5412, 0x5125, 0x5e7c, 0x5b4b, 0x45f9, 0x40ce, 0x4f97, 0x4aa0],
      Q => [0x355f, 0x3068, 0x3f31, 0x3a06, 0x24b4, 0x2183, 0x2eda, 0x2bed],
      H => [0x1689, 0x13be, 0x1ce7, 0x19d0, 0x0762, 0x0255, 0x0d0c, 0x083b],
   };
   my $fmt = $formats_for->{$level}[$mask_id];
   my $es = $matrix->[0]->@*;

   # 1st copy
   my $format = $fmt;
   for my $i (0 .. 7) {
      $matrix->[12][$es - 1 - 4 - $i] = $format & 0x01 ? 0x31 : 0x30;
      $format >>= 1;
   }
   for my $i (8 .. 14) {
      $matrix->[$es - 1 - 4 - 14 + $i][12] = $format & 0x01 ? 0x31 : 0x30;
      $format >>= 1;
   }

   # 2nd copy
   $format = $fmt;
   for my $i (0 .. 5) {
      $matrix->[4 + $i][12] = $format & 0x01 ? 0x31 : 0x30;
      $format >>= 1;
   }
   for my $i (6, 7) {
      $matrix->[4 + 1 + $i][12] = $format & 0x01 ? 0x31 : 0x30;
      $format >>= 1;
   }
   # 8
   $matrix->[4 + 1 + 7][11] = $format & 0x01 ? 0x31 : 0x30;
   $format >>= 1;
   for my $i (9 .. 14) {
      $matrix->[4 + 1 + 7][9 + 9 - $i] = $format & 0x01 ? 0x31 : 0x30;
      $format >>= 1;
   }

   return $matrix;
}

sub add_version ($data) {

   # FIXME Move into QRSpec?
   state $version_pattern_for = [ 
               0x07c94, 0x085bc, 0x09a99, 0x0a4d3,  #  7-10
      0x0bbf6, 0x0c762, 0x0d847, 0x0e60d, 0x0f928,  # 11-15
      0x10b78, 0x1145d, 0x12a17, 0x13532, 0x149a6,  # 16-20
      0x15683, 0x168c9, 0x177ec, 0x18ec4, 0x191e1,  # 21-25
      0x1afab, 0x1b08e, 0x1cc1a, 0x1d33f, 0x1ed75,  # 26-30
      0x1f250, 0x209d5, 0x216f0, 0x228ba, 0x2379f,  # 31-35
      0x24b0b, 0x2542e, 0x26a64, 0x27541, 0x28c69,  # 36-40
   ];

   my $version = $data->{version};
   return if $version <= 6;

   my $vp = $version_pattern_for->[$version - 7];
   my $matrix = $data->{matrix};
   my $ecstart = $data->{eside_size} - 4 - 7 - 4;
   for my $i (4 .. 9) {
      for my $j ($ecstart .. ($ecstart + 2)) {
         $matrix->[$i][$j] = $matrix->[$j][$i] = 0x30 ^ ($vp & 1);
         $vp >>= 1;
      }
   }

   return $data;
}

1;

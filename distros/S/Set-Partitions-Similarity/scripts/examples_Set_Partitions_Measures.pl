#!/usr/bin/env perl

use strict;
use warnings;

{
  use Set::Partitions::Similarity qw(getAccuracyAndPrecision);
  use Data::Dump qw(dump);

  # set elements are Perl strings.
  dump getAccuracyAndPrecision ([[qw(a b)],[1,2]], [[qw(a b 1)],[2]]);
  # dumps:
  # ("0.5", "0.25")

  # partitions are equivalent to themselves, including the empty partition.
  dump getAccuracyAndPrecision ([[1,2], [3,4]], [[2,1], [4,3]]);
  dump getAccuracyAndPrecision ([], []);
  # dumps:
  # (1, 1)
  # (1, 1)

  # accuracy and precision are symmetric functions.
  my ($p, $q) = ([[1,2,3], [4]], [[1], [2,3,4]]);
  dump getAccuracyAndPrecision ($p, $q);
  dump getAccuracyAndPrecision ($q, $p);
  # dumps:
  # ("0.333333333333333", "0.2")
  # ("0.333333333333333", "0.2")

  # checks partitions and throws an exception.
  eval { getAccuracyAndPrecision ([[1]], [[1,2]], 1); };
  warn $@ if $@;
  # dumps:
  # partitions are invalid, they have different set elements.
}

{
  use Set::Partitions::Similarity qw(getAccuracy);
  use Data::Dump qw(dump);
  dump getAccuracy ([[qw(a b)], [qw(c d)]], [[qw(a b c d)]]);
  dump getAccuracy ([[qw(a b c d)]], [[qw(a b)], [qw(c d)]]);
  # dumps:
  # "0.333333333333333"
  # "0.333333333333333"
}

{
  use Set::Partitions::Similarity qw(getAccuracyAndPrecision);
  use Data::Dump qw(dump);
  dump getAccuracyAndPrecision ([[1,2], [3,4]], [[1], [2], [3], [4]]);
  dump getAccuracyAndPrecision ([[1], [2], [3], [4]], [[1,2], [3,4]]);
  # dumps:
  # ("0.666666666666667", 0)
  # ("0.666666666666667", 0)
}

{
  use Set::Partitions::Similarity qw(getDistance);
  use Data::Dump qw(dump);
  dump getDistance ([[1,2,3], [4]], [[1], [2,3,4]]);
  # dumps:
  # "0.666666666666667"
}

{
  use Set::Partitions::Similarity qw(getPrecision);
  use Data::Dump qw(dump);
  dump getPrecision ([[1,2,3], [4]], [[1], [2,3,4]]);
  # dumps:
  # "0.2"
}

{
  use Set::Partitions::Similarity qw(getDistance);
  my @p = ([0..511]);
  for (my $s = 1; $s <= 512; $s += $s)
  {
    my @q = map { [$s*$_..($s*$_+$s-1)] } (0..(512/$s-1));
    print join (', ', $s, getDistance (\@p, \@q, 1)) . "\n";
  }
  # dumps:
  # 1, 1
  # 2, 0.998043052837573
  # 4, 0.99412915851272
  # 8, 0.986301369863014
  # 16, 0.970645792563601
  # 32, 0.939334637964775
  # 64, 0.876712328767123
  # 128, 0.75146771037182
  # 256, 0.500978473581213
  # 512, 0
}

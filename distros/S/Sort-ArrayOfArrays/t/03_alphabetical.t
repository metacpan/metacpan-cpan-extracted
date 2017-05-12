#!/usr/bin/perl -w
use strict;
use Test;

BEGIN { plan tests => 2}

use Sort::ArrayOfArrays;

my $sort = Sort::ArrayOfArrays->new({
  results     => [
    ['a' .. 'c'],
    ['d' .. 'f'],
    ['g' .. 'i'],
  ],
  sort_column => '-1',
});
my $results = $sort->sort_it;
ok($results && ref $results eq 'ARRAY' && $results->[0] && ref $results->[0] eq 'ARRAY');
ok(
  $results->[0][0] eq 'g' && $results->[0][1] eq 'h' && $results->[0][2] eq 'i' &&
  $results->[1][0] eq 'd' && $results->[1][1] eq 'e' && $results->[1][2] eq 'f' &&
  $results->[2][0] eq 'a' && $results->[2][1] eq 'b' && $results->[2][2] eq 'c'
);
__END__
$results = [
      [
        "g",
        "h",
        "i"
      ],
      [
        "d",
        "e",
        "f"
      ],
      [
        "a",
        "b",
        "c"
      ]
    ];

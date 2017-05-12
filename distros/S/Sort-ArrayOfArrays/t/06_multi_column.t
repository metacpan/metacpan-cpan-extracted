#!/usr/bin/perl -w
use strict;
use Test;

BEGIN { plan tests => 2}

use Sort::ArrayOfArrays;

my $sort = Sort::ArrayOfArrays->new({
  results     => [
    ['aaa', 'bbb', 'zzz'],
    ['aaa', 'bbb', 'aaa'],
    ['aaa', 'ccc', 'zzz'],
  ],
  sort_column => '0,-2,1',
});
my $results = $sort->sort_it;
ok($results && ref $results eq 'ARRAY' && $results->[0] && ref $results->[0] eq 'ARRAY');
ok(
  $results->[0][0] eq 'aaa' && $results->[0][1] eq 'bbb' && $results->[0][2] eq 'aaa' &&
  $results->[1][0] eq 'aaa' && $results->[1][1] eq 'bbb' && $results->[1][2] eq 'zzz' &&
  $results->[2][0] eq 'aaa' && $results->[2][1] eq 'ccc' && $results->[2][2] eq 'zzz'
);
__END__
$results = [
      [
        "aaa",
        "bbb",
        "aaa"
      ],
      [
        "aaa",
        "bbb",
        "zzz"
      ],
      [
        "aaa",
        "ccc",
        "zzz"
      ]
    ];

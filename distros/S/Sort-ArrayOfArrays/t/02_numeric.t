#!/usr/bin/perl -w
use strict;
use Test;

BEGIN { plan tests => 2}

use Sort::ArrayOfArrays;

my $sort = Sort::ArrayOfArrays->new({
  results     => [
    [1 .. 3],
    [4 .. 6],
    [7 .. 9],
  ],
  sort_column => '-0',
});
my $results = $sort->sort_it;
ok($results && ref $results eq 'ARRAY' && $results->[0] && ref $results->[0] eq 'ARRAY');
ok(
  $results->[0][0] == 7 && $results->[0][1] == 8 && $results->[0][2] == 9 &&
  $results->[1][0] == 4 && $results->[1][1] == 5 && $results->[1][2] == 6 &&
  $results->[2][0] == 1 && $results->[2][1] == 2 && $results->[2][2] == 3
);
__END__
   $results = [
          [
            7,
            8,
            9
          ],
          [
            4,
            5,
            6
          ],
          [
            1,
            2,
            3
          ]
        ];

#!perl

use 5.010001;
use strict;
use warnings;

use Permute::Unnamed;
use Test::More 0.98;

is_deeply(scalar(permute_unnamed([0,1], [qw/foo bar baz/])),
          [
              [0, 'foo'],
              [0, 'bar'],
              [0, 'baz'],
              [1, 'foo'],
              [1, 'bar'],
              [1, 'baz'],
          ]);

is_deeply(scalar(permute_unnamed([0])),
          [
              [0],
          ]);

done_testing;

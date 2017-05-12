#!perl

use 5.010001;
use strict;
use warnings;

use PERLANCAR::Permute::Named;
use Test::More 0.98;

is_deeply(scalar(permute_named(bool=>[0,1], x=>[qw/foo bar baz/])),
          [
              { bool => 0, x => 'foo' },
              { bool => 0, x => 'bar' },
              { bool => 0, x => 'baz' },
              { bool => 1, x => 'foo' },
              { bool => 1, x => 'bar' },
              { bool => 1, x => 'baz' },
          ]);

is_deeply(scalar(permute_named(bool=>0, x=>"foo")),
          [
              { bool => 0, x => 'foo' },
          ]);

done_testing;

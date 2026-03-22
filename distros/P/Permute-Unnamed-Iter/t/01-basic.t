#!perl

use 5.010001;
use strict;
use warnings;

use Permute::Unnamed::Iter qw(permute_unnamed_iter);
use Test::More 0.98;

sub permute_unnamed {
    my @p;
    my $iter = permute_unnamed_iter(@_);
    while (my $h = $iter->()) { push @p, $h }
    \@p;
}

is_deeply(permute_unnamed([0,1], [qw/foo bar baz/]),
          [
              [0, 'foo'],
              [0, 'bar'],
              [0, 'baz'],
              [1, 'foo'],
              [1, 'bar'],
              [1, 'baz'],
          ]);

is_deeply(permute_unnamed([0], ["foo"]),
          [
              [0, 'foo'],
          ]);

is_deeply(permute_unnamed([0,1,2]),
          [
              [0],
              [1],
              [2],
          ]);

done_testing;

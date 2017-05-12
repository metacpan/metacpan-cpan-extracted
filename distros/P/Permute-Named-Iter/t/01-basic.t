#!perl

use 5.010001;
use strict;
use warnings;

use Permute::Named::Iter qw(permute_named_iter);
use Test::More 0.98;

sub permute_named {
    my @p;
    my $iter = permute_named_iter(@_);
    while (my $h = $iter->()) { push @p, $h }
    \@p;
}

is_deeply(permute_named(bool=>[0,1], x=>[qw/foo bar baz/]),
          [
              { bool => 0, x => 'foo' },
              { bool => 0, x => 'bar' },
              { bool => 0, x => 'baz' },
              { bool => 1, x => 'foo' },
              { bool => 1, x => 'bar' },
              { bool => 1, x => 'baz' },
          ]);

is_deeply(permute_named(bool=>0, x=>"foo"),
          [
              { bool => 0, x => 'foo' },
          ]);

is_deeply(permute_named(bool=>[0,1,2]),
          [
              { bool => 0 },
              { bool => 1 },
              { bool => 2 },
          ]);

done_testing;

#!perl -T

use strict;
use warnings;
use lib 't/lib';

use Test::More 'no_plan';

BEGIN { use_ok('Sub::Pipeline'); }

{
  my $test_pipeline = Sub::Pipeline->new({
    order => [ qw(A B C) ],
    pipe  => {
      A => sub { $_[-1] = $_[ 0] + 1 },
      B => sub { $_[-1] = $_[-1] * 2 },
      C => sub { Sub::Pipeline::Success->throw(value => $_[-1]); },
    },
  });

  my $x = 10;
  my $y = $test_pipeline->call($x);

  is($x, 10, 'pipe did not alter $x');
  is($y, 22, 'pipe returned proper value');
}

{
  my $test_pipeline = Sub::Pipeline->new({
    order => [ qw(A B C) ],
    pipe  => {
      A => sub { $_[0] += 1 },
      B => sub { $_[0] *= 2 },
      C => sub { Sub::Pipeline::Success->throw(value => $_[0]); },
    },
  });

  my $x = 10;
  my $y = $test_pipeline->call($x);

  is($x, 22, 'pipe altered $x in place');
  is($y, 22, 'pipe returned proper value');
}

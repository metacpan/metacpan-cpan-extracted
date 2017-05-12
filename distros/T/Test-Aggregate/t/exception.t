#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use lib 't/lib';
use AggTestTester;

my $dir = 'aggtests-extras';
my @agg_tests = qw( die );
my @agg_paths = map { catfile($dir, "$_.t") } @agg_tests;

my @exp_results = (
  # The test starts with an ok(1).
  [
    1, qr{$dir.die\.t \*\*\*\*\* 1},
    'Ran die.t',
  ],

  # This is the important one:
  [
    0, qr/Ensure exceptions are not hidden during aggregate tests/,
    "Exception shown as ok(0)",
  ],
);

aggregate('Test::Aggregate', \@agg_paths, \@exp_results);

only_with_nested {
  push @exp_results, (
    # Nested will add the parent 'ok' for the subtest.
    [
      1, qr{Tests for $dir.die\.t},
      'Subtest completed for die.t',
    ],
  );

  aggregate('Test::Aggregate::Nested', \@agg_paths, \@exp_results);
};

done_testing;

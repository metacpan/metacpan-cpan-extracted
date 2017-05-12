#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib';
use AggTestTester;
use Test::More;

only_with_nested {

  aggregate(
      'Test::Aggregate::Nested',
      [
        catfile('aggtests-extras', 'fake_read_failure.t'),
        catfile('aggtests-extras', 'skip_to_end_undefined.t'),
        catfile('aggtests', 'skip_to_end.t'),
      ],
      [
        [ 0, qr/No tests run/, 'read failure results in failed test' ],
        [ 1, qr/Tests for .+?\bskip_to_end_undefined\.t/, 'skipped to end' ],
        [ 1, qr/Tests for .+?\bskip_to_end\.t/, 'skipped to end' ],
      ],
      diag => [
        qr/ unknown if .+?\bfake_read_failure\.t.+? actually finished.+? error was set \(\$!\):/sm,
        qr/No tests run/,
      ],
  );
};

done_testing;

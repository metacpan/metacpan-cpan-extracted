#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use lib 't/lib';
use AggTestTester;

my $path = catfile(qw(aggtests-does-not-exist no-really-it-should-not-exist.t));
{
  my $run = eval {
    aggregate('Test::Aggregate', [$path], []);
    1;
  };
  my $e = $@;
  is $run, undef, 'run failed (expectedly)';
  like $@, qr/^Cannot read .\Q$path\E./,
    'Instant death for file that does not exist';
}

only_with_nested {
  my $gen_exp_results = sub {
    my $path = shift;
    return ([
      [
        0, qr/No tests run for subtest .+?\Q$path\E/,
        "Read failure results in failed test",
      ]
    ],
      diag => [
        qr/unknown if .+?\Q$path\E.+? actually finished/,
        qr/No tests run/,
      ],
    );
  };

  # A file that doesn't exist.
  aggregate('Test::Aggregate::Nested', [$path], $gen_exp_results->($path),
    # Re-running FindBin will die because the file doesn't exist, so don't.
    findbin => 0,
  );

  # Simulate a file that does exist but fails to read for some other reason.
  $path = catfile(qw(aggtests-extras fake_read_failure.t));
  aggregate('Test::Aggregate::Nested', [$path], $gen_exp_results->($path));
};

done_testing;

#!perl -T

use Test::More;

BEGIN {
  my $tests = 0;

  foreach (qw/PLN::PT/) {
    use_ok($_) || print "$_ failed to load!\n";
    $tests++;
  }

  done_testing($tests);
}


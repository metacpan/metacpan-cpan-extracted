package TDHTester;

use strict;
use warnings;

use Test::Tester;
use Test::More 0.88;
use Test::Deep;

use Exporter 'import';
our @EXPORT = qw(good_test bad_test);

Test::Deep::builder(Test::Tester::capture());

sub good_test {
  my ($have, $want, $desc) = @_;

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  check_test(
    sub {
      cmp_deeply($have, $want);
    },
    {
      actual_ok => 1,
      diag => "",
      depth => -1,
    },
    $desc,
  );
}

sub bad_test {
  my ($have, $want, $diag, $desc) = @_;

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my (undef, $res) = check_test(
    sub {
      cmp_deeply($have, $want);
    },
    {
      actual_ok => 0,
      depth => -1,
    },
    $desc,
  );

  if (ref $diag) {
    for my $r (@$diag) {
      like($res->{diag}, $r, 'our diag looks good');
    }
  } else {
    is($res->{diag}, $diag, 'our diag looks good');
  }
}


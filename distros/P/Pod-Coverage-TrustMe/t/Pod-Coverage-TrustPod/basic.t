use strict;
use warnings;
use Test::More;

use lib 't/Pod-Coverage-TrustPod/lib';

use Pod::Coverage::TrustMe;
my $PC = 'Pod::Coverage::TrustMe';

{
  my $obj = $PC->new(
    package  => 'NoCoverage',
  );

  if (! defined $obj->coverage) {
    diag "no coverage: " . $obj->why_unrated;
    die;
  }

  is($obj->coverage, 0, "no coverage in NoCoverage");
  is_deeply([ $obj->naked ], [ qw(not_covered) ], "1 symbol");
}

{
  my $obj = $PC->new(
    package  => 'PodPrivate',
  );

  is($obj->coverage, 1, 'total coverage in PodPrivate');
}

{
  my $obj = $PC->new(
    package  => 'TrustStar',
  );

  is($obj->coverage, 1, 'total coverage in TrustStar');
}

{
  my $obj = $PC->new(
    package  => 'PodFor',
  );

  is($obj->coverage, 1, 'total coverage in PodFor');
}

{
  my $obj = $PC->new(
    package  => 'TrustMe',
    trustme  => [ qr/zzz/ ],
  );

  if (! defined $obj->coverage) {
    diag "no coverage: " . $obj->why_unrated;
    die;
  }

  ok(
    $obj->coverage >= 0.66 && $obj->coverage <= 0.68,
    "about one third covered in TrustMe",
  ) or diag "actual coverage: " . $obj->coverage;
  is_deeply([ $obj->naked ], [ qw(foo_xyz_bar) ], "1 symbol");
}

done_testing;

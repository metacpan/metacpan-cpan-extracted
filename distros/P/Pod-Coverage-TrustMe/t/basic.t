use strict;
use warnings;
use Test::More;
use Pod::Coverage::TrustMe;

use lib 't/corpus';

for my $package (qw(
  CoveredByParent
  CoveredByRole
  CoveredFile
  RoleWithCoverage
  WithUTF8
)) {
  my $cover = Pod::Coverage::TrustMe->new(
    package => $package,
    require_link => 1,
  );

  is $cover->coverage, 1, "$package is covered"
    or diag $cover->report;
}

done_testing;

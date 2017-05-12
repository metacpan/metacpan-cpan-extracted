
use warnings;
use strict;

use Test::More;
my @packages = qw(
  Shebangml
  Shebangml::FromXML
);
plan(tests => scalar(@packages));

eval {require version};
foreach my $package (@packages) {
  use_ok($package) or BAIL_OUT("cannot load $package");
}
diag("Testing $packages[0] ", $packages[0]->VERSION );

# vim:syntax=perl:ts=2:sw=2:et:sta

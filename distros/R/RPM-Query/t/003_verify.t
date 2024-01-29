#! -- perl --
use strict;
use warnings;
use Test::More tests => 2 + 3;
BEGIN { use_ok('RPM::Query') };

my $rpm  = RPM::Query->new;
isa_ok($rpm, 'RPM::Query');

my $skip = 1;
foreach (1) {
  last unless $^O eq 'linux';
  last unless qx{rpm -q perl};
  last if $?;
  $skip = 0;
}

SKIP: {
  skip 'rpm command not found or perl not installed by rpm', 3 if $skip;
  ok($rpm->verify('perl'), 'verify direct');

  my $package = $rpm->query('perl');
  isa_ok($package, 'RPM::Query::Package');
  ok($package->verify, 'verify from package object');
}

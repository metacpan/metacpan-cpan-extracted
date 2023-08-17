#! -- perl --
use strict;
use warnings;
use Test::More tests => 2 + 3;
BEGIN { use_ok('RPM::Query') };

my $rpm  = RPM::Query->new;
isa_ok($rpm, 'RPM::Query');

my $skip = $^O eq 'linux' ? do {qx{rpm --version}; $?} : 1;

SKIP: {
  skip 'rpm command not found', 3 if $skip;
  ok($rpm->verify('perl'), 'verify direct');

  my $package = $rpm->query('perl');
  isa_ok($package, 'RPM::Query::Package');
  ok($package->verify, 'verify from package object');
}

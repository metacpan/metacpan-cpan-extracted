#! -- perl --
use strict;
use warnings;
use Test::More tests => 2 + 4;
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
  skip 'rpm command not found or perl not installed by rpm', 4 if $skip;
  my $whatprovides = $rpm->whatprovides('perl(strict)');
  isa_ok($whatprovides, 'ARRAY');
  is(@$whatprovides, 1, 'size of whatprovides');
  my $package = $whatprovides->[0];
  isa_ok($package, 'RPM::Query::Package');
  is($package->name, 'perl', 'name');
}

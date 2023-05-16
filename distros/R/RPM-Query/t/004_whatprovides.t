#! -- perl --
use strict;
use warnings;
use Test::More tests => 2 + 4;
BEGIN { use_ok('RPM::Query') };

my $rpm  = RPM::Query->new;
isa_ok($rpm, 'RPM::Query');

my $skip = not qx{rpm --version > /dev/null ; echo $?};

SKIP: {
  skip 'rpm command not found', 4 if $skip;
  my $whatprovides = $rpm->whatprovides('perl(strict)');
  isa_ok($whatprovides, 'ARRAY');
  is(@$whatprovides, 1, 'size of whatprovides');
  my $package = $whatprovides->[0];
  isa_ok($package, 'RPM::Query::Package');
  is($package->name, 'perl', 'name');
}

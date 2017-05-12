#! perl
#
# 05-max-depth.t
#
# Testsuite for the max_depth() method, which is read-only as of 0.03
#

use 5.006;
use strict;
use warnings;

use Test::More 0.88;

use Module::Loader;

my ($loader, @modules);

$loader = Module::Loader->new()
          || BAIL_OUT("Can't instantiate Module::Loader");
ok(!defined($loader->max_depth), "Max depth should be undefined");

$loader = Module::Loader->new(max_depth => 5)
          || BAIL_OUT("Can't instantiate Module::Loader");
ok($loader->max_depth == 5, "Max depth should be 5");

my $max_depth;
eval {
    $loader->max_depth(1);
};
ok($@, "max_depth is immutable, so trying to set it should croak");

done_testing;


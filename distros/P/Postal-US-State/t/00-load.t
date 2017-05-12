
use warnings;
use strict;

use Test::More tests => 1;

my $package = 'Postal::US::State';
use_ok('Postal::US::State') or BAIL_OUT('cannot load Postal::US::State');

eval {require version};
diag("Testing $package ", $package->VERSION );

# vim:syntax=perl:ts=2:sw=2:et:sta

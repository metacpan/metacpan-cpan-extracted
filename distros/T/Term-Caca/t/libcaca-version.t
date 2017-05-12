use strict;

use Test::More tests => 1;                      # last test to print

my $version =  scalar `caca-config --version`;

diag "libcaca version: $version" if $version;

ok $version, "libcaca present on system";


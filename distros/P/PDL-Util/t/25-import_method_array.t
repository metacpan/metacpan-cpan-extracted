use strict;
use warnings;

use PDL;
use Test::More tests => 3;

use_ok('PDL::Util', ['unroll', 'export2d']);

my $pdl = zeros(5,5);
ok($pdl->can('unroll'), "'unroll' method imported during 'use'");
ok($pdl->can('export2d'), "'export2d' method imported during 'use'");


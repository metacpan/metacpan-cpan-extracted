use strict;
use warnings;

use PDL;
use Test::More tests => 2;

use_ok('PDL::Util', {'mymethod_unroll' => 'unroll'});

my $pdl = zeros(5,5);
ok($pdl->can('mymethod_unroll'), "method imported during 'use'");


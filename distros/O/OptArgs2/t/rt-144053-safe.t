#!perl
use strict;
use warnings;
use Safe;
use Test2::V0;

BEGIN { Safe->new }

use OptArgs2;

like( dies { cmd 'Class' }, qr/attribute\(s\) required/, 'Expected error' );

done_testing();

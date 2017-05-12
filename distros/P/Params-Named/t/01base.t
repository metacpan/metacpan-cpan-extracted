use strict;
use warnings;

use Test::More 'no_plan'; #tests => 1;

use_ok( 'Params::Named' );

can_ok( __PACKAGE__, 'MAPARGS' );

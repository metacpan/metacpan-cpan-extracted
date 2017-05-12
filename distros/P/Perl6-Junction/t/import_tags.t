use strict;
use Test::More tests => 4;

use Perl6::Junction ':ALL';

ok( all( 3, 3.0 ) == 3, '==' );
ok( any( 2, 3.0 ) == 2, '==' );
ok( none( 2, 3.0 ) == 4, '==' );
ok( one( 2, 3 ) == 2, '==' );

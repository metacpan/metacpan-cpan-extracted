use strict;
use Test::More tests => 4;

use Perl6::Junction;

ok( Perl6::Junction::all( 3, 3.0 ) == 3, '==' );
ok( Perl6::Junction::any( 2, 3.0 ) == 2, '==' );
ok( Perl6::Junction::none( 2, 3.0 ) == 4, '==' );
ok( Perl6::Junction::one( 2, 3 ) == 2, '==' );

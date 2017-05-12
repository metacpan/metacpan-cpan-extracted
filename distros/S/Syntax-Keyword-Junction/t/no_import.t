use strict;
use Test::More tests => 4;

use Syntax::Keyword::Junction;

ok( Syntax::Keyword::Junction::all( 3, 3.0 ) == 3, '==' );
ok( Syntax::Keyword::Junction::any( 2, 3.0 ) == 2, '==' );
ok( Syntax::Keyword::Junction::none( 2, 3.0 ) == 4, '==' );
ok( Syntax::Keyword::Junction::one( 2, 3 ) == 2, '==' );

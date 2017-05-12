use strict;

use Test::More tests => 2;

use Salvation::System ();
use Salvation::Service ();

use Salvation::Stuff '&load_class';

ok( &load_class( 'Salvation::System' ) );
ok( &load_class( 'Salvation::Service' ) );


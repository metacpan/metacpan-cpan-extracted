use 5.012;
use strict;
use warnings;

use Test::More tests => 3;

{
   package NO_PBP;
   use Modern::PBP::Moose;
   has 'thing' => ( is => 'rw' );
}

ok(   NO_PBP->can('thing'),     "NO_PBP build thing" );
ok( ! NO_PBP->can('get_thing'), "NO_PBP no get_thing" );
ok( ! NO_PBP->can('set_thing'), "NO_PBP no set_thing" );

done_testing();

use 5.012;
use strict;
use warnings;

use Test::More tests => 6;

{
   package PBP_1;
   use Modern::PBP::Moose qw{pbp};
   has 'thing' => ( is => 'rw' );
}

{
   package PBP_2;
   use Modern::PBP::Moose qw{pbp};
   has '_thing' => ( is => 'rw' );
}

ok(    PBP_1->can('get_thing'),  "PBP_1 build get_thing" );
ok(    PBP_1->can('set_thing'),  "PBP_1 build set_thing" );
ok( !  PBP_1->can('thing'),      "PBP_1 loaded" );

ok(    PBP_2->can('_get_thing'), "PBP_2 build _get_thing" );
ok(    PBP_2->can('_set_thing'), "PBP_2 build _set_thing" );
ok( !  PBP_2->can('thing'),      "PBP:2 loaded" );

done_testing();

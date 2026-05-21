#!perl
use v5.22;
use warnings;

use Test2::V0;

use Object::PadX::Enum;

enum Colors {
   item RED;
   item GREEN;
   item BLUE;
}

is( Colors->RED->ordinal,   0, 'RED has ordinal 0' );
is( Colors->GREEN->ordinal, 1, 'GREEN has ordinal 1' );
is( Colors->BLUE->ordinal,  2, 'BLUE has ordinal 2' );

is( Colors->RED->name,   'RED',   'RED has name "RED"' );
is( Colors->GREEN->name, 'GREEN', 'GREEN has name "GREEN"' );
is( Colors->BLUE->name,  'BLUE',  'BLUE has name "BLUE"' );

isa_ok( Colors->RED, [ 'Colors' ], 'RED is a Colors' );

ok( Colors->RED == Colors->RED,   'RED is identity-stable' );
ok( Colors->RED != Colors->GREEN, 'RED and GREEN differ' );

done_testing;

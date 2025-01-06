# -*- perl -*-
use strict;
use warnings;
use Test::More tests => 7;

BEGIN { use_ok( 'String::ProperCase::Surname' ); }

is(ProperCase("macdonald"), "MacDonald", "normal");
is(ProperCase("macleod"), "MacLeod", "before");

delete($String::ProperCase::Surname::surname{lc($_)}) foreach qw{MacDonald MacLeod};

is(ProperCase("macdonald"), "Macdonald", "delete");
is(ProperCase("macleod"), "Macleod", "delete");

is(ProperCase("davis"), "Davis", "normal");

$String::ProperCase::Surname::surname{lc($_)}=$_ foreach qw{DaVis};

is(ProperCase("davis"), "DaVis", "add");

use strict;
use warnings;
use Test::More tests => 4;

BEGIN { use_ok 'Photography::EV' }

is shutter_speed(9,11, []), undef, 'empty list of shutter speeds always returns undef';
is shutter_speed(9,11), .25,       'EV 9  f/11  ... 1/4s';
is shutter_speed(14,1.4), 1/8000,  'EV 14 f/1.4 ... 1/8000s';

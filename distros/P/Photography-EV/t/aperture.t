use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Photography::EV' }

is aperture(9,1/60, []), undef, 'empty list of apertures always returns undef';

is aperture(9,1/60), 2.8, 'EV 9  1/60  ... f/2.8';

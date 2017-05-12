#! perl
use strict;
use Test::More tests => 3;
use Test::NoWarnings;

use Number::Phone::FR;

is(Number::Phone::FR->country, 'FR', ":Full loading success");
ok(defined(Number::Phone::FR->VERSION), ':Full has a VERSION');

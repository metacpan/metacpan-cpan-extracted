#!perl -T

use 5.006;
use strict;
use warnings;

use Test::More tests => 1 + 1;
use Test::NoWarnings;

BEGIN { use_ok('Object::Lazy') }

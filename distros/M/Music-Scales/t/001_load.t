# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test;

BEGIN { plan tests => 1 }
END { ok($loaded) }
use Music::Scales;
$loaded++;




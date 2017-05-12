use strict;
use warnings;
use Test::More tests => 1;

use Pigment;

my ($major, $minor, $micro) = Pigment->version;
is(Pigment->version_string, "Pigment ${major}.${minor}.${micro}");

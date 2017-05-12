use Test::More tests => 1;

use strict;
use warnings;

use PDLA;

my $pdl = sequence(3,3);
ok( overload::Method($pdl, '""'), 'piddle stringifies');

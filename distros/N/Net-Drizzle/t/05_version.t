use strict;
use Test::More tests => 1;

use Net::Drizzle;

like(Net::Drizzle->drizzle_version, qr/^\d\.\d$/);


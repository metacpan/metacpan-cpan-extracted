use strict;
use Test::More tests => 1;

BEGIN { use_ok 'Net::Drizzle' }

diag "version of libdrizzle: " . Net::Drizzle->drizzle_version();

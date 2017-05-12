use strict;
use warnings;
use Test::More tests => 1;
use Net::Drizzle ':constants';

is(DRIZZLE_DEFAULT_TCP_HOST, '127.0.0.1');

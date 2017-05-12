use strict;
use warnings;
use Test::More tests => 3;

use Net::DNS::GuessTZ;

is(Net::DNS::GuessTZ->tz_from_host(''),    undef, "no guess for '' host");
is(Net::DNS::GuessTZ->tz_from_host(undef), undef, "no guess for undef host");

ok('We compiled okay.  Real tests are in ./xt/author');

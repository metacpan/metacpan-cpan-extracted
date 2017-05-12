use bytes;
use strict;

use Test::More tests => 1 + 6;
use Test::NoWarnings;

use Net::IDN::UTS46 qw(:all);

is(uts46_to_ascii('mueller'),'mueller');
is(uts46_to_ascii('xn--mller-kva'),'xn--mller-kva');
is(uts46_to_ascii('müller'),'xn--mller-kva');

is(uts46_to_unicode('mueller'),'mueller');
is(uts46_to_unicode('xn--mller-kva'),'müller');
is(uts46_to_unicode('müller'),'müller');


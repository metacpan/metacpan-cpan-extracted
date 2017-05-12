use bytes;
use strict;

use Test::More tests => 1+6;
use Test::NoWarnings;

use Net::IDN::UTS46 qw(:all);

is(uts46_to_ascii('müller'),'xn--mller-kva');
is(Net::IDN::UTS46::to_ascii('müller'),'xn--mller-kva');
is(Net::IDN::UTS46::uts46_to_ascii('müller'),'xn--mller-kva');

is(uts46_to_unicode('xn--mller-kva'),'müller');
is(Net::IDN::UTS46::to_unicode('xn--mller-kva'),'müller');
is(Net::IDN::UTS46::uts46_to_unicode('xn--mller-kva'),'müller');

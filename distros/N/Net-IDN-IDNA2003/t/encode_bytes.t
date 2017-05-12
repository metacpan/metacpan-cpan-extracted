use bytes;
use strict;

use Test::More tests => 1+6;
use Test::NoWarnings;

use Net::IDN::IDNA2003 qw(:all);

is(idna2003_to_ascii('mueller'),'mueller');
is(idna2003_to_ascii('xn--mller-kva'),'xn--mller-kva');
is(idna2003_to_ascii('müller'),'xn--mller-kva');

is(idna2003_to_unicode('mueller'),'mueller');
is(idna2003_to_unicode('xn--mller-kva'),'müller');
is(idna2003_to_unicode('müller'),'müller');

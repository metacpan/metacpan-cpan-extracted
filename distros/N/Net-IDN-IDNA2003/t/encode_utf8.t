use utf8;
use strict;

use Test::More tests => 1+8;
use Test::NoWarnings;

use Net::IDN::IDNA2003 qw(:all);

is(idna2003_to_ascii('mueller'),'mueller');
is(idna2003_to_ascii('xn--mller-kva'),'xn--mller-kva');
is(idna2003_to_ascii('müller'),'xn--mller-kva');
is(idna2003_to_ascii('中央大学'),'xn--fiq80yua78t');

is(idna2003_to_unicode('mueller'),'mueller');
is(idna2003_to_unicode('xn--mller-kva'),'müller');
is(idna2003_to_unicode('müller'),'müller');
is(idna2003_to_unicode('xn--fiq80yua78t'),'中央大学');

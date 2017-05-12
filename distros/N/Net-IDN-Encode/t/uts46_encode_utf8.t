use utf8;
use strict;

BEGIN { binmode STDOUT, ':utf8'; binmode STDERR, ':utf8'; }

use Test::More tests => 1+8;
use Test::NoWarnings;

use Net::IDN::UTS46 qw(:all);

is(uts46_to_ascii('mueller'),'mueller');
is(uts46_to_ascii('xn--mller-kva'),'xn--mller-kva');
is(uts46_to_ascii('müller'),'xn--mller-kva');
is(uts46_to_ascii('中央大学'),'xn--fiq80yua78t');

is(uts46_to_unicode('mueller'),'mueller');
is(uts46_to_unicode('xn--mller-kva'),'müller');
is(uts46_to_unicode('müller'),'müller');
is(uts46_to_unicode('xn--fiq80yua78t'),'中央大学');

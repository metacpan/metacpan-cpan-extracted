# -*- perl -*-
use lib 't';

use strict;
use warnings;
use TestCapture;
use Test::More tests => 1;

our($catbin, $input);

ok(TestCapture([$catbin, $input],
	       stdout => { nlines => 71, length => 4051 },
	       stderr => { nlines => 0, length => 0 }));



# -*- perl -*-

use lib 't';

use strict;
use warnings;
use TestCapture;
use Test::More tests => 1;

our($catbin, $input, $content);

ok(TestCapture([$catbin, $input],
	       stdout => {
		   nlines => 71,
		   length => 4051,
		   content => $content
               }));



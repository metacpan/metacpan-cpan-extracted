# -*- perl -*-
use lib 't';

use strict;
use warnings;
use TestCapture;
use Test::More tests => 1;

our($catbin, $input, $content);

ok(TestCapture([$catbin, '-l', 337, '-o', $input, '-s', 628, '-l', 734, '-e', $input],
	       stdout => {
		   nlines => 8,
		   length => 337,
		   content => substr($content, 0, 337)
               },
	       stderr => {
		   nlines => 11,
		   length => 734,
		   content => substr($content, 628, 734)
	       }
   ));



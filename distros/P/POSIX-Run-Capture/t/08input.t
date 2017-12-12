# -*- perl -*-

use lib 't';

use strict;
use warnings;
use TestCapture;
use Test::More tests => 2;

our($catbin, $input, $content);

ok(TestCapture({ argv => [$catbin, '-'],
                 input => $content },
	       stdout => {
		   nlines => 71,
		   length => 4051,
		   content => $content
               }));

open(my $fd, '<', $input) or die;
ok(TestCapture({ argv => [$catbin, '-'],
                 input => $fd },
	       stdout => {
		   nlines => 71,
		   length => 4051,
		   content => $content
               }));

package MooX::A;

use strict;
use warnings;

sub import {
	$main::COUNT += 1 if $main::COUNT == 0;
}

1;
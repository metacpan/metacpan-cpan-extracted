package MooX::B;

use strict;
use warnings;

sub import {
	$main::COUNT += 2 if $main::COUNT == 1;
}

1;
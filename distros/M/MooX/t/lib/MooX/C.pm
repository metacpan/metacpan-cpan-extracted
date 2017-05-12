package MooX::C;

use strict;
use warnings;

sub import {
	$main::COUNT += 4 if $main::COUNT == 3;
}

1;
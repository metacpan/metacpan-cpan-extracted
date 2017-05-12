package NonMooX::A;

use strict;
use warnings;

sub import {
	$main::COUNT += 100 if $main::COUNT == 1;
}

1;
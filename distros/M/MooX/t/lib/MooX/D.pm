package MooX::D;

use strict;
use warnings;

sub import {
	my ( $class, @args ) = @_;
	$main::COUNT += shift @args while (@args);
}

1;
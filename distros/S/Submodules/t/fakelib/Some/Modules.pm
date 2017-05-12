package Some::Modules;
use strict;
use warnings;
our $VERSION = '1.0';
our $IMPORTED;
our $COUNT++;

sub package {
	return __PACKAGE__;
}

sub import {
	$IMPORTED = 1;
}

1;

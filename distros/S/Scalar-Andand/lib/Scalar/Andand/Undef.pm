package Scalar::Andand::Undef;

use strict;
use warnings;
our $VERSION = 0.05;

use Class::Null;
my $noop = Class::Null->new;

sub andand {
	return $noop;
}

1;

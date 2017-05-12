package Miril::URL;

use strict;
use warnings;
use autodie;

use Object::Tiny qw(
	abs
	rel
	tag
);

sub new {
	my $class = shift;
	return bless { @_ }, $class;
}

1;

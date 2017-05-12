package Miril::Type;

use strict;
use warnings;
use autodie;

use Object::Tiny qw(
	id
	name
	location
	template
);

sub new {
	my $class = shift;
	return bless { @_ }, $class;
}

1;

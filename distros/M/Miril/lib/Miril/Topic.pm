package Miril::Topic;

use strict;
use warnings;
use autodie;

use Object::Tiny qw(
	id
	name
);

sub new {
	my $class = shift;
	return bless { @_ }, $class;
}

1;

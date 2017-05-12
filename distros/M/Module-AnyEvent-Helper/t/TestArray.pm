package TestArray;

use strict;
use warnings;

sub new
{
	return bless {};
}

sub func1
{
	return (1, 2);
}

sub func2
{
	return (2, 3, 4);
}

sub func3
{
	my ($self, $arg) = @_;
	return func1() if $arg == 1;
	return func2() if $arg == 2;
	return ();
}

1;

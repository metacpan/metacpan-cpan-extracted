package Test4Args::Test;

sub new
{
	return bless {};
}

sub func4
{
	return 0;
}

package Test4Args;

use strict;
use warnings;

sub new
{
	return bless {
		test => Test4Args::Test->new,
	};
}

sub func1
{
	return 1;
}

sub func2
{
	return 2;
}

sub func3
{
	my ($self, $arg) = @_;
	return func1() if $arg == 1;
	return func2() if $arg == 2;
	return $self->{test}->func4();
}

1;

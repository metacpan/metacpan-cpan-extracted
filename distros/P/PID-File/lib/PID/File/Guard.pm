package PID::File::Guard;

use 5.006;

use strict;
use warnings;

sub new
{
	my ( $class, $sub ) = @_;
	die "Can't create guard in void context" if ! defined wantarray;
	return bless $sub, $class;
}

sub DESTROY
{
	my $self = shift;
	$self->();
}

1;

package CustomBuilder;

use v5.10;
use strict;
use warnings;

use parent 'Mooish::AttributeBuilder';

sub attribute_types
{
	my ($self) = @_;

	my $std = $self->SUPER::attribute_types;
	return {
		%{$std},
		cache => {
			is => 'ro',
			init_arg => undef,
			lazy => sub { {} },
			clearer => 1,
		}
	};
}

sub hidden_prefix
{
	return '_hid';
}

sub hidden_methods
{
	my ($self) = @_;

	my $std = $self->SUPER::hidden_methods;
	$std->{clearer} = 1;

	return $std;
}

sub method_prefixes
{
	my ($self) = @_;

	my $std = $self->SUPER::method_prefixes;
	$std->{clearer} = 'cleanse';

	return $std;
}

1;


package Quantum::Superpositions::Lazy::Util;

our $VERSION = '1.07';

use v5.24;
use warnings;
use Exporter qw(import);
use Scalar::Util qw(blessed);
use Random::Any qw(rand);

our @EXPORT_OK = qw(
	is_collapsible
	is_state
	get_rand
);

sub is_collapsible
{
	my ($item) = @_;

	return blessed $item && $item->DOES("Quantum::Superpositions::Lazy::Role::Collapsible");
}

sub is_state
{
	my ($item) = @_;

	return blessed $item && $item->isa("Quantum::Superpositions::Lazy::State");
}

# MUST return a value in range of [0, 1)
sub get_rand { rand() }

1;

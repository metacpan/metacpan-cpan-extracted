package Quantum::Superpositions::Lazy::Util;

our $VERSION = '1.04';

use v5.28;
use warnings;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use Exporter qw(import);
use Scalar::Util qw(blessed);
use Data::Entropy::Algorithms qw(rand_flt);

our @EXPORT_OK = qw(
	is_collapsible
	is_state
	get_rand
);

sub is_collapsible ($item)
{
	return blessed $item && $item->DOES("Quantum::Superpositions::Lazy::Role::Collapsible");
}

sub is_state ($item)
{
	return blessed $item && $item->isa("Quantum::Superpositions::Lazy::State");
}

sub get_rand { rand_flt 0, 1 }

1;

package Quantum::Superpositions::Lazy::Util;

our $VERSION = '1.10';

use v5.24;
use warnings;
use Exporter qw(import);
use Scalar::Util qw(blessed);
use List::Util qw(max);
use Random::Any qw(rand);

our @EXPORT_OK = qw(
	is_collapsible
	is_state
	get_rand
	get_iterator
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

sub get_iterator
{
	my (@states) = @_;

	my @indexes = map { 0 } @states;
	my @max_indexes = map { $#$_ } @states;

	# we can't iterate if one of the elements do not exist
	my $finished = scalar grep { $_ < 0 } @max_indexes;
	return sub {
		my ($with_indexes) = @_;
		return if $finished;

		my $i = 0;
		my @ret =
			map { is_state($_) ? $_->value : $_ }
			map { $states[$i++][$_] }
			@indexes;

		if ($with_indexes) {
			@ret = map { $indexes[$_], $ret[$_] } 0 .. max($#indexes, $#ret);
		}

		$i = 0;
		while ($i < @indexes && ++$indexes[$i] > $max_indexes[$i]) {
			$indexes[$i] = 0;
			$i += 1;
		}

		$finished = $i == @indexes;
		return @ret;
	};
}

1;

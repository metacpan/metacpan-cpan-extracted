package Quantum::Superpositions::Lazy::Statistics;

our $VERSION = '1.00';

use v5.24; use warnings;
use Moo;

use feature qw(signatures);
no warnings qw(experimental::signatures);

use Quantum::Superpositions::Lazy::Role::Collapsible;
use Quantum::Superpositions::Lazy::State;
use Types::Standard qw(ArrayRef ConsumerOf InstanceOf);
use Sort::Key qw(keysort nkeysort);
use List::Util qw(sum);

# This approximation should be well within the range of 32 bit
# floating point values - 6 digits (IEEE 754)
use constant HALF_APPROX => "0.500000";

sub transform_states($items, $transformer)
{
	my @transformed = map {
		$_->clone_with(value => $transformer)
	} @$items;

	return \@transformed;
}

sub weight_to_probability($item, $weight_sum)
{
	return $item->clone_with(
		weight => sub ($weight) { $weight / $weight_sum }
	) if defined $item;

	return $item;
}

sub weighted_mean($list_ref, $weight_sum = undef)
{
	$weight_sum = sum map { $_->weight } $list_ref->@*
		unless defined $weight_sum;

	my @values = map { $_->value * $_->weight / $weight_sum } $list_ref->@*;
	return sum @values;
}

# The sorting order is irrelevant here
sub weighted_median($sorted_list_ref, $average = 0)
{
	my $approx_half = sub ($value) {
		return HALF_APPROX eq substr(($value . (0 x length HALF_APPROX)), 0, length HALF_APPROX);
	};

	my $running_sum = 0;
	my $last_el;
	my @found;

	for my $el ($sorted_list_ref->@*) {
		$running_sum += $el->weight;

		if ($running_sum > 0.5) {
			push @found, $last_el if $approx_half->($running_sum - $el->weight);
			push @found, $el;
			last;
		}

		$last_el = $el;
	}

	# if we're allowed to average the result, do that
	return weighted_mean(\@found)
		if $average;

	# get the lowest weight value if we can't average the two
	# be biased towards the first value
	return $found[1]->weight < $found[0]->weight ? $found[1]->value : $found[0]->value
		if @found == 2;

	return @found > 0 ? $found[0]->value : undef;
}

# CAUTION: float == comparison inside. Will only work for elements
# that were obtained in a similar fasion
sub find_border_elements($sorted) {
	my @found;
	for my $state (@$sorted) {
		push @found, $state
			if @found == 0 || $found[-1]->weight == $state->weight;
	}

	return \@found;
}

my %options = (
	is => "ro",
	lazy => 1,
	init_arg => undef,
);

use namespace::clean;

has "parent" => (
	is => "ro",
	isa => ConsumerOf["Quantum::Superpositions::Lazy::Role::Collapsible"],
	weak_ref => 1,
);

# Sorted in ascending order
has "sorted_by_probability" => (
	%options,
	isa => ArrayRef[InstanceOf["Quantum::Superpositions::Lazy::State"]],
	default => sub ($self) {
		[
			map {
				weight_to_probability($_, $self->parent->weight_sum)
			} nkeysort {
				$_->weight
			} $self->parent->states->@*
		]
	},
);

# Sorted in ascending order
# (we use sorted_by_probability to avoid copying states twice in weight_to_probability)
has "sorted_by_value_str" => (
	%options,
	isa => ArrayRef[InstanceOf["Quantum::Superpositions::Lazy::State"]],
	default => sub ($self) {
		[
			keysort { $_->value }
				$self->sorted_by_probability->@*
		]
	},
);

has "sorted_by_value_num" => (
	%options,
	isa => ArrayRef[InstanceOf["Quantum::Superpositions::Lazy::State"]],
	default => sub ($self) {
		[
			nkeysort { $_->value }
				$self->sorted_by_probability->@*
		]
	},
);

# Other consumer indicator
has "most_probable" => (
	%options,
	isa => InstanceOf["Quantum::Superpositions::Lazy::Superposition"],
	default => sub ($self) {
		my @sorted = reverse $self->sorted_by_probability->@*;
		return Quantum::Superpositions::Lazy::Superposition->new(
			states => find_border_elements(\@sorted)
		);
	},
);

has "least_probable" => (
	%options,
	isa => InstanceOf["Quantum::Superpositions::Lazy::Superposition"],
	default => sub ($self) {
		my $sorted = $self->sorted_by_probability;
		return Quantum::Superpositions::Lazy::Superposition->new(
			states => find_border_elements($sorted)
		);
	},
);

has "median_str" => (
	%options,
	default => sub ($self) {
		weighted_median($self->sorted_by_value_str);
	},
);

has "median_num" => (
	%options,
	default => sub ($self) {
		weighted_median($self->sorted_by_value_num, 1);
	},
);

has "mean" => (
	%options,
	default => sub ($self) {
		# since the mean won't return a state, we're free not
		# to make copies of the states.
		weighted_mean($self->parent->states, $self->parent->weight_sum);
	},
);

has "variance" => (
	%options,
	default => sub ($self) {
		# transform_states is required here so that we don't modify existing states
		weighted_mean(transform_states($self->parent->states, sub { $_[0] ** 2 }), $self->parent->weight_sum)
			-
		$self->mean ** 2
	},
);

sub sorted_by_value($self)
{
	return $self->sorted_by_value_str;
}

sub median($self)
{
	return $self->median_str;
}

sub expected_value($self)
{
	return $self->mean;
}

sub standard_deviation($self)
{
	return sqrt $self->variance;
}

1;

__END__

=head1 NAME

Quantum::Superpositions::Lazy::Statistics - statistical measures on superpositions

=head1 DESCRIPTION

This package contains implementations of basic statistical measures available directly from the superposition object via the I<stats> method. Upon calling any method on the statistics object, the full set of states will be created on the superposition.

=head1 METHODS

All the methods results are cached on the first call. Most methods use other
methods internally to avoid multiple invocations of possibly costly
calculations. Modifying the returned reference contents will change the value
stored in the cache and will thus lead to wrong values being returned.

=head2 parent

Returns the superposition which is used for getting the states data, a consumer of L<Quantum::Superpositions::Lazy::Role::Collapsible>.

=head2 sorted_by_probability

Returns all the states sorted by probability in ascending order.

=head2 sorted_by_value

=head2 sorted_by_value_str

=head2 sorted_by_value_num

Returns all the states sorted by their value in ascending order. Values can be treated either as numbers or strings in the comparison.

The I<sorted_by_value> method is an alias for I<sorted_by_value_str>.

=head2 most_probable

=head2 least_probable

Returns the border elements based on weight - the most or the least probable elements. The return value is a new superposition which contains the border elements. Multiple border elements will be grouped in this superposition.

=head2 median
=head2 median_str
=head2 median_num

Returns the weighted median of the superposition states (a floating point value). The string variant and the numerical variant differ in two ways:

=over

=item * the method of sorting used when calculating the median

=item * the numerical variant will average the result if the data set has two elements that meet the criteria

=back

The I<median> method is an alias for I<median_str>.

=head2 mean

=head2 expected_value

Returns the weighted mean of the data set (a floating point value). The expected value of the discrete set is equal to its weighted mean, hence the I<expected_value> is just an alias for convenience.

=head2 variance

Returns the variance of the data set (a floating point value).

=head2 standard_deviation

Returns the standard deviation of the data set - a square root of variance (a floating point value).


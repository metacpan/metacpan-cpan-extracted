use strict;
use warnings;

package PDL::Graphics::Prima::Scaling;

our $VERSION = 0.17;   # update with update-version.pl

package
sc;
use constant Linear => 'PDL::Graphics::Prima::Scaling::Linear';
use constant Log => 'PDL::Graphics::Prima::Scaling::Log';


# Defines the scaling classes.
# working here - add a broken axis scaling class

package PDL::Graphics::Prima::Scaling::Linear;

use PDL;
use Carp;

# order of magnitude returns the power of 10 that is below the given value.
# Examples:
# 12    -> 10
# 0.04  -> 0.01
# 3.2e3 -> 1e3
sub order_of_magnitude {
	my $number = shift;
	confess("Internal error: non-positive numbers are not allowed in order_of_magnitude (I received $number)")
		if $number <= 0;
	my $exponent = log($number) / log(10);
	# Correct for truncation of negative numbers:
	$exponent-- if $exponent < 0;
	return 10**(int $exponent);
}

# A function that returns a usable min/max when the two are identical. For
# linear scaling, this amounts to returning the current value +- half itself,
# unless that value is zero (in which case I return +-1).
sub min_max_for_degenerate {
	my ($class, $value) = @_;
	if ($value == 0) {
		return (-1, 1);
	}
	elsif ($value > 0) {
		return (0.5*$value, 1.5 * $value);
	}
	else {
		return (1.5*$value, 0.5 * $value);
	}
}

sub _adjusted_position {
	my ($value, $interval, $offset, $direction) = @_;
	
	{
		no warnings 'numeric';
		# check for nan and croak since I can't continue with nans:
		confess("_adjusted_position got \$value of nan!") if ($value != $value);
		confess("_adjusted_position got \$interval of nan!")
			if ($interval != $interval);
	}
	
	# Find the first copy of $interval that's less than $value:
	my $to_return = int($value / $interval) * $interval;
	# include the offset:
	$to_return += $offset;
	while(1) {
		return $to_return if $value == $to_return;
		return $to_return if (($to_return <=> $value) == $direction);
		$to_return += $direction * $interval;
	}
	# Return the final, adjusted position:
	return $to_return;
}


sub compute_ticks {
	my (undef, $min, $max) = @_;
	# This revised algorithm is much simpler and faster, and designed to
	# reduce tick "jitter" when panning or scrolling.
	#	min  	max		ticks at
	#   3       4      3, 3.25, 3.5, 3.75, 4
	#   3.1     4.1    3.25, 3.5, 3.75, 4
	#   2       3.7    2, 2.25, 2.5, 2.75, 3, 3.25, 3.5
	#   2       3.8    2, 2.5, 3, 3.5
	#   2       4      2, 2.5, 3, 3.5, 4
	#   2.2     4.2    2.5, 3, 3.5, 4
	#   2       5      2, 2.5, 3, 3.5, 4, 4.5, 5
	#   2       5.5    2, 3, 4, 5
	#   2       8      2, 3, 4, 5, 6, 7, 8
	#   2       9      2, 4, 6, 8
	#   0       20     0, 5, 10, 15, 20
	#   30.5    37.5   32, 34, 36
	#   0       112    0, 25, 50, 75, 100
	
	# Determine the order of magnitude of the min/max range:
	my $full_range = $max - $min;
	my $order_of_magnitude = order_of_magnitude($full_range);
	my $relative_range = $full_range / $order_of_magnitude;
	
	# This is a table for determining the tick size as a *function* of the
	# size of the range wrt the order of magnitude
						# relative range less than...	# use tick size of...
	my $rel_interval	= $relative_range < 1.75		? 0.25
						: $relative_range < 3			? 0.5
						: $relative_range < 7			? 1
						:								  2
						;
	
	# Compute the major tick interval and the layout
	my $Tick_interval = $order_of_magnitude * $rel_interval;
	# The ticks will start at either a multiple of the interval,
	# or a multiple of the interval plus the offset. So,
	# recompute the range in light of the tick size:
	my $min_Tick = _adjusted_position($min, $Tick_interval, 0, 1);
	my $max_Tick = _adjusted_position($max, $Tick_interval, 0, -1);
	# Count the number of ticks between min_Tick and max_Tick
	my $N_Ticks = ($max_Tick - $min_Tick) / $Tick_interval + 1;
	# Add 0.1 to escape rounding trouble.
	my $Ticks = zeroes($N_Ticks + 0.1)->xlinvals($min_Tick, $max_Tick);
	
	# Construct the minor tick marks:
	my $tick_interval = $Tick_interval / 5;
	$tick_interval = $Tick_interval / 4 if $rel_interval >= 1;
	my $min_tick = _adjusted_position($min, $tick_interval, 0, 1);
	my $max_tick = _adjusted_position($max, $tick_interval, 0, -1);
	my $N_ticks = ($max_tick - $min_tick) / $tick_interval + 1;
	# Add 0.1 to escape rounding trouble.
	my $ticks = zeroes($N_ticks + 0.1)->xlinvals($min_tick, $max_tick);

	# finally, set up zero values that make sense:
	# working here - convoluted so the debugger wouldn't get angry at me:
#	$best_Ticks->where(abs($best_Ticks) * 1e10 < ($max - $min)) .= 0;
#	$ticks->where(abs($ticks) * 1e10 < ($max - $min)) .= 0;
	my $foo = $Ticks->where(abs($Ticks) * 1e10 < ($max - $min));
	$foo .= 0;
	$foo = $ticks->where(abs($ticks) * 1e10 < ($max - $min));
	$foo .= 0;
	return ($Ticks, $ticks);
}

# Rescales the data so that the min has a value of zero and the max has a value
# of 1.
use Carp 'croak';
sub transform {
	my ($class, $min, $max, $data) = @_;
	my $range = $max - $min;
	croak("Scaling::Linear::transform needs min != max but got min = max = $min")
		if $range == 0;
	croak('Scaling::Linear::transform needs well-defined data') 
		if not defined $data;
	return (($data - $min) / $range);
}

# Rescales data so that a value of zero gets the minimum and a value of 1 gets
# the maximum:
sub inv_transform {
	my ($class, $min, $max, $data) = @_;
	my $range = $max - $min;
	croak("Scaling::Linear::inv_transform needs min != max but got min = max = $min")
		if $range == 0;
	croak('Scaling::Linear::inv_transform needs well-defined data') 
		if not defined $data;
	return $range * $data + $min;
}

# Generates a collection of points that extrapolate evenly from the min to the
# max
sub sample_evenly {
	my ($class, $min, $max, $N_values) = @_;
	croak("Scaling::Linear::sample_evenly needs min != max but got min = max = $min")
		if $min == $max;
	croak("Scaling::Linear::sample_evenly expects N_values > 1")
		if not defined $N_values or $N_values < 2;
	return zeroes($N_values)->xlinvals($min, $max);
}

# This should ONLY be called on real numbers, numbers that you actually intend
# to use in plotting. In other words, inf will return 0!
# Usage:
# On success, it returns 1. On failure, it returns zero and modifies $@ with
# an explanation (which is used in capturing error messages).
sub is_valid_extremum {
	no warnings 'numeric';
	
	# Allow anything except infinity or nan:
	if ($_[1] != $_[1]) {	# nan
		$@ = 'nan is not allowed; value must be real';
		return 0;
	}
	elsif ($_[1] * 0.0 != 0.0) {	# inf
		$@ = 'value must be finite';
		return 0;
	}
	return 1;
}

package PDL::Graphics::Prima::Scaling::Log;
#our @ISA = qw(PDL::Graphics::Prima::Scaling::Linear);

use PDL;
use Carp;

sub min_max_for_degenerate {
	my ($class, $value) = @_;
	croak("All values must be strictly positive with logarithmic scaling")
		unless $value > 0;
	return ($value / 2, $value * 2);
}

# For data between 0.5 and 15, I would want tick marks at
# 0.5, 1, 1.5, 2.5, 5, 10, 15
# for data between 10 and 300, I would want tick marks at
# 10, 20, 50, 100, 200, 

sub compute_ticks {
	# These are the actual data's min and max:
	my (undef, $min, $max) = @_;
	
	# I have three different possible behaviors depending on the dynamic range:
	my $dynamic_range = log($max / $min) / log(10);
	
	# First thing's first: if the data show a minimal dynamic range, just use
	# the linear tick algorithm:
	return PDL::Graphics::Prima::Scaling::Linear::compute_ticks(undef, $min, $max)
		if ($dynamic_range < 1.5);
	
	# If the data show low dynamic range, return the scaling for that:
	return low_dynamic_ticks($min, $max, $dynamic_range) if ($dynamic_range < 7);
	
	# If the data show an medium dynamic range, return the scaling for that:
	return medium_dynamic_ticks($min, $max, $dynamic_range) if ($dynamic_range < 13);
	
	# If the data show a high dynamic range (from, say 10**-6 to 10**15), use
	# the high-dynamic range algorithm, which simply wraps the linear tick
	# algorithm:
	# working here - this doesn't always work!
	my ($Ticks, $ticks) = PDL::Graphics::Prima::Scaling::Linear::compute_ticks(undef, log($min)/log(1000), log($max) / log(1000));
	return (1000**$Ticks, 1000**$ticks);
}

# This algorithm determines the logarithmic tick marks for low dynamic ranges,
# which are dynamic ranges between 1.5 and 3.
sub low_dynamic_ticks {
	my ($min, $max, $dynamic_range) = @_;
	
	# Determine the number of ticks per order (dynamic range cutoff of 2 was
	# determined empirically):
	#			For dynamic ranges less than...		use ... ticks per order
	my $N_Ticks_per_order	= $dynamic_range < 2	? 3
							: $dynamic_range < 3	? 2
							: 						  1;
	
	# Accumulate the Tick marks:
	my @Ticks = (_smallest_next_low_number($min, $N_Ticks_per_order));
	my $max_Tick = _largest_previous_low_number($max, $N_Ticks_per_order);
	for(my $current_value = _smallest_next_low_number($min*1.01, $N_Ticks_per_order)
		; $current_value < $max_Tick
		; $current_value = _smallest_next_low_number($current_value*1.01, $N_Ticks_per_order)) {
		push @Ticks, $current_value;
	}
	push @Ticks, $max_Tick;
	
	# Determine the minimum and maximum tick marks (notice the lower case):
	my $min_order = PDL::Graphics::Prima::Scaling::Linear::order_of_magnitude($min);
	my $max_order = PDL::Graphics::Prima::Scaling::Linear::order_of_magnitude($max);
	
	# Add a tick for all 10 values in each decade:
	my $ticks = (sequence(10) * $min_order);
	$ticks = $ticks->where($min < $ticks);
	for (my $current_order = $min_order * 10; $current_order <= $max_order
		; $current_order *= 10) {
		my $to_add = (sequence(10) * $current_order);
		$ticks = $ticks->append($to_add->where($to_add < $max));
	}
	
	# All done. PDLify the ticks and return them:
	return (pdl(@Ticks), $ticks);
}

# Determines the first number greater than the given value that satisfies the
# given number of ticks per order, as used for low dynamic ranges. For example:
#	Value	N_ticks_per_order	return
#	34		1					100
#	34		2,3					50
#	19		2					50
#	19		3					20
#	99		1,2,3				100
#	100		1,2,3				100
sub _smallest_next_low_number {
	my ($value, $N_ticks_per_order) = @_;
	
	# First get the order of magnitude of this value:
	my $order = PDL::Graphics::Prima::Scaling::Linear::order_of_magnitude($value);
	
	# The order of magnitude is guaranteed to be less than the actual value.
	# Now determine which value to return.
	return $order if $value == $order;
	return $order*2 if $value < $order*2 and $N_ticks_per_order > 2;
	return $order*5 if $value < $order*5 and $N_ticks_per_order > 1;
	return $order*10;
}

# Determines the first number smaller than the given value that satisfies the
# given number of ticks per order, as used for low dynamic ranges. For example:
#	Value	N_ticks_per_order	return
#	34		1,2					10
#	34		3					20
#	19		1,2,3				10
#	21		1,2					10
#	57		1,2,3				50
#	100		1,2,3				100
sub _largest_previous_low_number {
	my ($value, $N_ticks_per_order) = @_;

	# First get the order of magnitude of this value:
	my $order = PDL::Graphics::Prima::Scaling::Linear::order_of_magnitude($value);

	# The order of magnitude is guaranteed to be less than the actual value.
	# Now determine which value to return.
	return $order if $value == $order;
	return $order*5 if $order*5 < $value and $N_ticks_per_order > 1;
	return $order*2 if $order*2 < $value and $N_ticks_per_order > 2;
	return $order;
}

# This algorithm determines the logarithmic tick marks for medium dynamic ranges,
# which are dynamic ranges between 3 and 12. The number of decades per tick mark
# for these ranges should be either one or two.
sub medium_dynamic_ticks {
	my ($min, $max, $dynamic_range) = @_;
	
	# Set the decades per tick:
	my $N_decades_per_tick = 2;
	
	# Accumulate the Tick marks:
	my @Ticks = (_smallest_next_number($min, $N_decades_per_tick));
	my $max_Tick = _largest_previous_number($max, $N_decades_per_tick);
	for(my $current_value = _smallest_next_number($min*1.01, $N_decades_per_tick)
		; $current_value < $max_Tick
		; $current_value = _smallest_next_number($current_value*1.01, $N_decades_per_tick)) {
		push @Ticks, $current_value;
	}
	push @Ticks, $max_Tick;
	
	# Determine the minimum and maximum tick marks:
	my $min_order = PDL::Graphics::Prima::Scaling::Linear::order_of_magnitude($min);
	my $max_order = PDL::Graphics::Prima::Scaling::Linear::order_of_magnitude($max);
	
	my @ticks;
	for (my $current_order = $min_order; $current_order < $max; $current_order *= 10) {
		push @ticks, $current_order
			if ($min < $current_order and $current_order < $max);
		push @ticks, $current_order * sqrt(10)
			if ($min < $current_order * sqrt(10) and $current_order * sqrt(10) < $max);
	}
	
	# All done. PDLify the ticks and return them:
	return (pdl(@Ticks), pdl(@ticks));
}

# Determines the next number larger than the given value for the given number
# of decades per tick (at least one) and decade offset. This probably only makes
# sense with some examples.
# Consider the smallest next number for a given number of decades. Suppose I
# wanted to work with triples of decades, i.e. 1, 1e3, 1e6, 1e9, etc. For any
# value less than 1000, the smallest next number is 1000. For any number greater
# than 1000 and less than a million, the smallest next number is a million.
sub _smallest_next_number {
	my ($value, $N_decades_per_tick) = @_;
	# Compute the exponent (see order_of_magnitude)
	my $exponent = log($value) / log(10);
	# Correct for truncation of negative numbers:
	$exponent-- if $exponent < 0;
	my $trunc_exponent = int $exponent;
	
	# Return the desired next number:
	return 10**($trunc_exponent + $N_decades_per_tick
		- ($trunc_exponent % $N_decades_per_tick));
}

# Determines the previous number smaller than the given value for the given
# number of decades per tick. See the previous function for details.
sub _largest_previous_number {
	my ($value, $N_decades_per_tick) = @_;
	# Compute the exponent (see order_of_magnitude)
	my $exponent = log($value) / log(10);
	# Correct for truncation of negative numbers:
	$exponent-- if $exponent < 0;
	my $trunc_exponent = int $exponent;
	
	# Return the desired previous number:
	return 10**($trunc_exponent - ($trunc_exponent % $N_decades_per_tick));
}

# Rescales the data so that the min has a value of zero and the max has a value
# of 1.
sub transform {
	my ($class, $min, $max, $data) = @_;
	croak("Scaling::Log::transform needs min > 0 and max > 0 but got min = $min and max = $max")
		unless $min > 0 and $max > 0;
	my ($log_min, $log_max, $log_data) = (log($min), log($max), log($data));
	my $range = $log_max - $log_min;
	croak('Scaling::Log::transform needs min != max') if $range == 0;
	croak('Scaling::Log::transform needs well-defined data') 
		if not defined $data;
	return (($log_data - $log_min) / $range);
}

# Rescales data so that a value of zero gets the minimum and a value of 1 gets
# the maximum:
sub inv_transform {
	# working here - make sure this works
	my ($class, $min, $max, $data) = @_;
	croak("Scaling::Log::inv_transform needs min > 0 and max > 0 but got min = $min and max = $max")
		unless $min > 0 and $max > 0;
	my ($log_min, $log_max) = (log($min), log($max));
	my $range = $log_max - $log_min;
	croak('Scaling::Log::transform needs min != max') if $range == 0;
	croak('Scaling::Log::transform needs well-defined data') 
		if not defined $data;
	return exp($range * $data + $log_min);
}

# Generates a collection of points that extrapolate evenly from the min to the
# max
sub sample_evenly {
	my ($class, $min, $max, $N_values) = @_;
	croak("Scaling::Log::sample_evenly needs min != max but got min = max = $min")
		if $min == $max;
	croak("Scaling::Log::sample_evenly expects N_values > 1")
		if not defined $N_values or $N_values < 2;
	return zeroes($N_values)->xlogvals($min, $max);
}

sub is_valid_extremum {
	my ($class, $extremum) = @_;
	no warnings 'numeric';
	if ($extremum <= 0) {
		# no negative values:
		$@ = 'must be positive for logarithmic scaling';
		return 0;
	}
	elsif ($extremum != $extremum) {
		# nans not allowed:
		$@ = 'nan is not allowed';
		return 0;
	}
	elsif ($extremum * 0.0 != 0.0) {
		# inf is bad:
		$@ = 'must be finite';
		return 0;
	}
	# otherwise we're good:
	return 1;
}

1;

=head1 AUTHOR

David Mertens (dcmertens.perl@gmail.com)

=head1 ADDITIONAL MODULES

Here is the full list of modules in this distribution:

=over

=item L<PDL::Graphics::Prima|PDL::Graphics::Prima/>

Defines the Plot widget for use in Prima applications

=item L<PDL::Graphics::Prima::Axis|PDL::Graphics::Prima::Axis/>

Specifies the behavior of axes (but not the scaling)

=item L<PDL::Graphics::Prima::DataSet|PDL::Graphics::Prima::DataSet/>

Specifies the behavior of DataSets

=item L<PDL::Graphics::Prima::Limits|PDL::Graphics::Prima::Limits/>

Defines the lm:: namespace

=item L<PDL::Graphics::Prima::Palette|PDL::Graphics::Prima::Palette/>

Specifies a collection of different color palettes

=item L<PDL::Graphics::Prima::PlotType|PDL::Graphics::Prima::PlotType/>

Defines the different ways to visualize your data

=item L<PDL::Graphics::Prima::ReadLine|PDL::Graphics::Prima::ReadLine/>

Encapsulates all interaction with the L<Term::ReadLine> family of
modules.

=item L<PDL::Graphics::Prima::Scaling|PDL::Graphics::Prima::Scaling/>

Specifies different kinds of scaling, including linear and logarithmic

=item L<PDL::Graphics::Prima::Simple|PDL::Graphics::Prima::Simple/>

Defines a number of useful functions for generating simple and not-so-simple
plots

=back

=head1 LICENSE AND COPYRIGHT

Unless otherwise stated, all contributions in code and documentation are
copyright (c) their respective authors, all rights reserved.

Portions of this module's code are copyright (c) 2011 The Board of
Trustees at the University of Illinois.

Portions of this module's code are copyright (c) 2011-2013 Northwestern
University.

Portions of this module's code are copyright (c) 2013-2014 Dickinson
College.

This module's documentation is copyright (c) 2011-2014 David Mertens.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

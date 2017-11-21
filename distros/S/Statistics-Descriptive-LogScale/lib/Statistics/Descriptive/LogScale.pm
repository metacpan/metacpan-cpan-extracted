use 5.006;
use strict;
use warnings;

package Statistics::Descriptive::LogScale;

=head1 NAME

Statistics::Descriptive::LogScale - Memory-efficient approximate univariate
descriptive statistics class.

=head1 VERSION

Version 0.10

=cut

our $VERSION = 0.11;

=head1 SYNOPSIS

=head2 Basic usage

The basic usage is roughly the same as that of L<Statistics::Descriptive::Full>.

    use Statistics::Descriptive::LogScale;
    my $stat = Statistics::Descriptive::LogScale->new ();

    while(<>) {
        chomp;
        $stat->add_data($_);
    };

    # This can also be done in O(1) memory, precisely
    printf "Mean: %f +- %f\n", $stat->mean, $stat->standard_deviation;
    # This requires storing actual data, or approximating
    printf "25%%  : %f\n", $stat->percentile(25);
    printf "Median: %f\n", $stat->median;
    printf "75%%  : %f\n", $stat->percentile(75);

=head2 Save/load

This is not present in L<Statistics::Descriptive::Full>.
The save/load interface is designed compatible with JSON::XS.
However, any other serializer can be used.
The C<TO_JSON> method is I<guaranteed> to return unblessed hashref
with enough information to restore the original object.

    use Statistics::Descriptive::LogScale;
    my $stat = Statistics::Descriptive::LogScale->new ();

    # ..... much later
    # Save
    print $fd encoder_of_choice( $stat->TO_JSON )
        or die "Failed to save: $!";

    # ..... and even later
    # Load
    my $plain_hash = decoder_of_choice( $raw_data );
    my $copy_of_stat = Statistics::Descriptive::LogScale->new( %$plain_hash );

    # Import into existing LogScale instance
    my $plain_hash = decoder_of_choice( $more_raw_data );
    $copy_of_stat->add_data_hash( $plain_hash->{data} );

=head2 Histograms

Both L<Statistics::Descriptive::Full> and L<Statistics::Descriptive::LogScale>
offer C<frequency_distribution_ref> method for querying data point counts.
However, there's also C<histogram> method for making pretty pictures.
Here's a simple text-based histogram.
A proper GD example was too long to fit into this margin.

    use strict;
    use warnings;

    use Statistics::Descriptive::LogScale;
    my $stat = Statistics::Descriptive::LogScale->new ();

    # collect/load data ...
    my $re_float = qr([-+]?(?:\d+\.?\d*|\.\d+)(?:[Ee][-+]?\d+)?);
    while (<>) {
        $stat->add_data($_) for m/($re_float)/g;
    };
    die "Empty set"
        unless $stat->count;

    # get data in [ count, lower_bound, upper_bound ] format as arrayref
    my $hist = $stat->histogram( count => 20 );

    # find maximum value to use as a scale factor
    my $scale = $hist->[0][0];
    $scale < $_->[0] and $scale = $_->[0] for @$hist;

    foreach (@$hist) {
        printf "%10f %s\n", $_->[1], '#' x ($_->[0] * 68 / $scale);
    };
    printf "%10f\n", $hist->[-1][2];

=head1 DESCRIPTION

This module aims at providing some advanced statistical functions without
storing all data in memory, at the cost of certain (predictable) precision loss.

Data is represented by a set of bins that only store counts of fitting
data points.
Most bins are logarithmic, i.e. lower end / upper end ratio is constant.
However, around zero linear approximation may be user instead
(see "linear_width" and "linear_thresh" parameters in new()).

All operations are then performed on the bins, introducing relative error
which does not, however, exceed the bins' relative width ("base").

=head1 METHODS

=cut

########################################################################
#  == HOW IT WORKS ==
#  Buckets are stored in a hash: { $value => $count, ... }
#  {base} is bin width, {logbase} == log {base} (cache)
#  {linear_thresh} is where we switch to equal bin approximation
#  {linear_width} is width of bin around zero (==linear_thresh if not given)
#  {floor} is lower bound of bin whose center is 1. {logfloor} = log {floor}
#  Nearly all meaningful subs have to scan all the bins, which is bad,
#     but anyway better than scanning full sample.

use Carp;
use POSIX qw(floor ceil);

# Fields are NOT used internally for now, so this is just a declaration
use fields qw(
	data count
	linear_width base logbase floor linear_thresh only_linear logfloor
	cache
);

# Some internal constants
# This is for infinite portability^W^W portable infinity
my $INF = 9**9**9;
my $re_num = qr/(?:[-+]?(?:\d+\.?\d*|\.\d+)(?:[Ee][-+]?\d+)?)/;

=head2 new( %options )

%options may include:

=over

=item * base - ratio of adjacent bins. Default is 10^(1/232), which gives
1% precision and exact decimal powers.
This value represents acceptable relative error in analysis results.

B<NOTE> Actual value may be slightly less than requested one.
This is done so to avoid troubles with future rounding in (de)serialization.

=item * linear_width - width of linear bins around zero.
This value represents precision of incoming data.
Default is zero, i.e. we assume that the measurement is precise.

B<NOTE> Actual value may be less (by no more than a factor of C<base>)
so that borders of linear and logarithmic bins fit nicely.

=item * linear_thresh - where to switch to linear approximation.
If only one of C<linear_thresh> and C<linear_width> is given,
the other will be calculated.
However, user may want to specify both in some cases.

B<NOTE> Actual value may be less (by no more than a factor of C<base>)
so that borders of linear and logarithmic bins fit nicely.

=item * only_linear = 1 (B<EXPERIMENTAL>) -
throw away log approximation and become a discrete statistics
class with fixed precision.
C<linear_width> must be given in this case.

B<NOTE> This obviously kills memory efficiency, unless one knows beforehand
that all values come from a finite pool.

=item * data - hashref with C<{ value => weight }> for initializing data.
Used for cloning.
See C<add_data_hash()>.

=item * zero_thresh - absolute value threshold below which everything is
considered zero.
DEPRECATED, C<linear_width> and C<linear_thresh> override this if given.

=back

=cut

my @new_keys = qw( base linear_width linear_thresh data zero_thresh only_linear );
	# TODO Throw if extra options given?
	# TODO Check args better
sub new {
	my $class = shift;
	my %opt = @_;

	# First, check for only_linear option
	if ($opt{only_linear}) {
		$opt{linear_width}
			or croak "only_linear option given, but no linear width";
		$opt{only_linear} = $opt{linear_width};
		delete $opt{$_} for qw(linear_width base linear_thresh zero_thresh);
	};

	# base for logarithmic bins, sane default: +-1%, exact decimal powers
	# UGLY HACK number->string->number to avoid
	#     future serialization inconsistencies
	$opt{base} ||= 10**(1/232);
	$opt{base} = 0 + "$opt{base}";
	$opt{base} > 1 or croak __PACKAGE__.": new(): base must be >1";

	# calculate where to switch to linear approximation
	# the condition is: linear bin( thresh ) ~~ log bin( thresh )
	# i.e. thresh * base - thresh ~~ absolute error * 2
	# i.e. thresh ~~ absolute_error * 2 / (base - 1)
	# also support legacy API (zero_thresh)
	if (defined $opt{linear_thresh} ) {
		$opt{linear_width} ||= $opt{linear_thresh} * ($opt{base}-1);
	} else {
		$opt{linear_thresh}  = $opt{zero_thresh};
	};
	$opt{linear_thresh} = abs($opt{linear_width}) / ($opt{base} - 1)
		if $opt{linear_width} and !$opt{linear_thresh};
	$opt{linear_thresh} ||= 0;
	$opt{linear_thresh} >= 0
		or croak __PACKAGE__.": new(): linear_thresh must be >= 0";

	# Can't use fields::new anymore
	#    due to JSON::XS incompatibility with restricted hashes
	my $self = bless {}, $class;

	$self->{base} = $opt{base};
	# cache values to ease calculations
	# floor = (lower end of bin) / (center of bin)
	$self->{floor} = 2/(1+$opt{base});
	$self->{logbase} = log $opt{base};
	$self->{logfloor} = log $self->{floor};

	# bootstrap linear_thresh - make it fit bin edge
	$self->{linear_width} = $self->{linear_thresh} = 0;
	$self->{linear_thresh} = $self->_lower( $opt{linear_thresh} );

	# divide anything below linear_thresh into odd number of bins
	#      not exceeding requested linear_width
	if ($self->{linear_thresh}) {
		my $linear_width = $opt{linear_width} || 2 * $self->{linear_thresh};
		my $n_linear = ceil(2 * $self->{linear_thresh} / abs($linear_width));
		$n_linear++ unless $n_linear % 2;
		$self->{linear_width} = (2 * $self->{linear_thresh} / $n_linear);
	};

	if ($opt{only_linear}) {
		$self->{linear_width} = $opt{only_linear};
		$self->{linear_thresh} = $INF;
		$self->{only_linear} = 1;
	};

	$self->clear;
	if ($opt{data}) {
		$self->add_data_hash($opt{data});
	};
	return $self;
};

=head1 General statistical methods

These methods are used to query the distribution properties. They generally
follow the interface of L<Statistics::Descriptive> and co,
with minor additions.

All methods return C<undef> on empty data set, except for
C<count>, C<sum>, C<sumsq>, C<stdandard_deviation> and C<variance>
which all return 0.

B<NOTE> This module caches whatever it calculates very agressively.
Don't hesitate to use statistical functions (except for sum_of/mean_of)
more than once. The cache is deleted upon data entry.

=head2 clear

Destroy all stored data.

=cut

sub clear {
	my $self = shift;
	$self->{data} = {};
	$self->{count} = 0;
	delete $self->{cache};
	return $self;
};

=head2 add_data( @data )

Add numbers to the data pool.

Returns self, so that methods can be chained.

If incorrect data is given (i.e. non-numeric, undef),
an exception is thrown and only partial data gets inserted.
The state of object is guaranteed to remain consistent in such case.

B<NOTE> Cache is reset, even if no data was actually inserted.

B<NOTE> It is possible to add infinite values to data pool.
The module will try and calculate whatever can still be calculated.
However, no portable way of serializing such values is done yet.

=cut

sub add_data {
	my $self = shift;

	delete $self->{cache};
	foreach (@_) {
		$self->{data}{ $self->_round($_) }++;
		$self->{count}++;
	};
	$self;
};

=head2 count

Returns number of data points.

=cut

sub count {
	my $self = shift;
	return $self->{count};
};

=head2 min

=head2 max

Values of minimal and maximal bins.

NOTE: Due to rounding, some of the actual inserted values may fall outside
of the min..max range. This may change in the future.

=cut

sub min {
	my $self = shift;
	return $self->_sort->[0];
};

sub max {
	my $self = shift;
	return $self->_sort->[-1];
};

=head2 sample_range

Return sample range of the dataset, i.e. max() - min().

=cut

sub sample_range {
	my $self = shift;
	return $self->count ? $self->max - $self->min : undef;
};

=head2 sum

Return sum of all data points.

=cut

sub sum {
	my $self = shift;
	return $self->sum_of(sub { $_[0] });
};

=head2 sumsq

Return sum of squares of all datapoints.

=cut

sub sumsq {
	my $self = shift;
	return $self->sum_of(sub { $_[0] * $_[0] });
};

=head2 mean

Return mean, or average value, i.e. sum()/count().

=cut

sub mean {
	my $self = shift;
	return $self->{count} ? $self->sum / $self->{count} : undef;
};

=head2 variance

=head2 variance( $correction )

Return data variance, i.e. E((x - E(x)) ** 2).

Bessel's correction (division by n-1 instead of n) is used by default.
This may be changed by specifying $correction explicitly.

B<NOTE> The binning strategy used here should also introduce variance bias.
This is not yet accounted for.

=cut

sub variance {
	my $self = shift;
	my $correction = shift;

	# in fact we'll receive correction='' because of how cache works
	$correction = 1 unless defined $correction and length $correction;

	return 0 if ($self->{count} < 1 + $correction);

	my $var = $self->sumsq - $self->sum**2 / $self->{count};
	return $var <= 0 ? 0 : $var / ( $self->{count} - $correction );
};

=head2 standard_deviation

=head2 standard_deviation( $correction )

=head2 std_dev

=head2 stdev

Return standard deviation, i.e. square root of variance.

Bessel's correction (division by n-1 instead of n) is used by default.
This may be changed by specifying $correction explicitly.

B<NOTE> The binning strategy used here should also introduce variance bias.
This is not yet accounted for.

=cut

sub standard_deviation {
	my $self = shift;

	return sqrt($self->variance(@_));
};

=head2 cdf ($x)

Cumulative distribution function. Returns estimated probability of
random data point from the sample being less than C<$x>.

As a special case, C<cdf(0)> accounts for I<half> of zeroth bin count (if any).

Not present in Statistics::Descriptive::Full, but appears in
L<Statistics::Descriptive::Weighted>.

=head2 cdf ($x, $y)

Returns probability of a value being between C<$x> and C<$y> ($x <= $y).
This is essentially C<cdf($y)-cdf($x)>.

=cut

sub cdf {
	my $self = shift;
	return unless $self->{count};
	return $self->_count(@_) / $self->{count};
};

=head2 percentile( $n )

Find $n-th percentile, i.e. a value below which lies $n % of the data.

0-th percentile is by definition -inf and is returned as undef
(see Statistics::Descriptive).

$n is a real number, not necessarily integer.

=cut

sub percentile {
	my $self = shift;
	my $x = shift;

	# assert 0<=$x<=100
	croak __PACKAGE__.": percentile() argument must be between 0 and 100"
		unless 0<= $x and $x <= 100;

	my $need = $x * $self->{count} / 100;
	return if $need < 1;

	# dichotomize
	# $i is lowest value >= needed
	# $need doesnt exceed last bin!
	my $i = _bin_search_ge( $self->_probability, $need );
	return $self->_sort->[ $i ];
};

=head2 quantile( 0..4 )

From Statistics::Descriptive manual:

  0 => zero quartile (Q0) : minimal value
  1 => first quartile (Q1) : lower quartile = lowest cut off (25%) of data = 25th percentile
  2 => second quartile (Q2) : median = it cuts data set in half = 50th percentile
  3 => third quartile (Q3) : upper quartile = highest cut off (25%) of data, or lowest 75% = 75th percentile
  4 => fourth quartile (Q4) : maximal value

=cut

sub quantile {
	my $self = shift;
	my $t = shift;

	croak (__PACKAGE__.": quantile() argument must be one of 0..4")
		unless $t =~ /^[0-4]$/;

	$t or return $self->min;
	return $self->percentile($t * 100 / 4);
};

=head2 median

Return median of data, a value that divides the sample in half.
Same as percentile(50).

=cut

sub median {
	my $self = shift;
	return $self->percentile(50);
};

=head2 trimmed_mean( $ltrim, [ $utrim ] )

Return mean of sample with $ltrim and $utrim fraction of data points
remover from lower and upper ends respectively.

ltrim defaults to 0, and rtrim to ltrim.

=cut

sub trimmed_mean {
	my $self = shift;
	my ($lower, $upper) = @_;
	$lower ||= 0;
	$upper = $lower unless defined $upper;

	my $min = $self->percentile($lower * 100);
	my $max = $self->percentile(100 - $upper * 100);

	return unless $min < $max;

	return $self->mean_of(sub{$_[0]}, $min, $max);
};

=head2 harmonic_mean

Return harmonic mean of the data, i.e. 1/E(1/x).

Return undef if division by zero occurs (see Statistics::Descriptive).

=cut

sub harmonic_mean {
	my $self = shift;

	my $ret;
	eval {
		$ret = $self->count / $self->sum_of(sub { 1/$_[0] });
	};
	if ($@ and $@ !~ /division.*zero/) {
		die $@; # rethrow ALL BUT 1/0 which yields undef
	};
	return $ret;
};

=head2 geometric_mean

Return geometric mean of the data, that is, exp(E(log x)).

Dies unless all data points are of the same sign.

=cut

sub geometric_mean {
	my $self = shift;

	return unless $self->count;
	croak __PACKAGE__.": geometric_mean() called on mixed sign sample"
		if $self->min * $self->max < 0;

	return 0 if $self->{data}{0};
	# this must be dog slow, but we already log() too much at this point.
	my $ret = exp( $self->sum_of( sub { log abs $_[0] } ) / $self->{count} );
	return $self->min < 0 ? -$ret : $ret;
};

=head2 skewness

Return skewness of the distribution, calculated as
n/(n-1)(n-2) * E((x-E(x))**3)/std_dev**3 (this is consistent with Excel).

=cut

sub skewness {
	my $self = shift;

	my $n = $self->{count};
	return unless $n > 2;

	# code stolen from Statistics::Descriptive
	my $skew = $n * $self->std_moment(3);
	my $correction = $n / ( ($n-1) * ($n-2) );
	return $correction * $skew;
};

=head2 kurtosis

Return kurtosis of the distribution, that is 4-th standardized moment - 3.
The exact formula used here is consistent with that of Excel and
Statistics::Descriptive.

=cut

sub kurtosis {
	my $self = shift;

	my $n = $self->{count};
	return unless $n > 3;

	# code stolen from Statistics::Descriptive
	my $kurt = $n * $self->std_moment(4);
	my $correction1 = ( $n * ($n+1) ) / ( ($n-1) * ($n-2) * ($n-3) );
	my $correction2 = ( 3  * ($n-1) ** 2) / ( ($n-2) * ($n-3) );

	return $correction1 * $kurt - $correction2;
};

=head2 central_moment( $n )

Return $n-th central moment, that is, E((x - E(x))^$n).

Not present in Statistics::Descriptive::Full.

=cut

sub central_moment {
	my $self = shift;
	my $n = shift;

	my $mean = $self->mean;
	return $self->sum_of(sub{ ($_[0] - $mean) ** $n }) / $self->{count};
};

=head2 std_moment( $n )

Return $n-th standardized moment, that is,
E((x - E(x))**$n) / std_dev(x)**$n.

Not present in Statistics::Descriptive::Full.

=cut

sub std_moment {
	my $self = shift;
	my $n = shift;

	my $mean = $self->mean;
	my $dev = $self->std_dev;
	return $self->sum_of(sub{ ($_[0] - $mean) ** $n })
		/ ( $dev**$n * $self->{count} );
};

=head2 abs_moment( $power, [$offset] )

Return $n-th moment of absolute value, that is, C<E(|x - offset|^$n)>.

Default value for offset if E(x).
Power may be fractional.

B<NOTE> Experimental. Not present in Statistics::Descriptive::Full.

=cut

sub abs_moment {
	my ($self, $power, $offset) = @_;

	$offset = $self->mean unless defined $offset;
	return $self->sum_of(sub{ return abs($_[0] - $offset) ** $power })
		 / $self->{count};
};

=head2 std_abs_moment( $power, [$offset] )

Returns standardized absolute moment - like above, but scaled
down by a factor of to standard deviation to n-th power.

That is, C<E(|x - offset|^$n) / E(|x - offset|^2)^($n/2)>

Default value for offset if E(x).
Power may be fractional.

B<NOTE> Experimental. Not present in Statistics::Descriptive::Full.

=cut

sub std_abs_moment {
    my ($self, $power, $offset) = @_;

    return  $self->abs_moment($power, $offset)
                /
            ($self->abs_moment(2, $offset) ** ($power/2));
};

=head2 mode

Mode of a distribution is the most common value for a discrete distribution,
or maximum of probability density for continuous one.

For now we assume that the distribution IS discrete, and return the bin with
the biggest hit count.

NOTE A better algorithm is still wanted. Experimental.
Behavior may change in the future.

=cut

# Naive implementation
# Find bin w/greatest count and return it
sub mode {
	my $self = shift;

	return if !$self->count;

	my $index = $self->_sort;
	return $index->[0] if @$index == 1;

	my @count = map { $self->{data}{$_} } @$index;

	my $max_index;
	my $max_growth = 0;
	for (my $i = 0; $i<@count; $i++) {
		$count[$i] > $max_growth or next;
		$max_index = $i;
		$max_growth = $count[$i];
	};

	return $index->[$max_index];
};

=head2 frequency_distribution_ref( \@index )

=head2 frequency_distribution_ref( $n )

=head2 frequency_distribution_ref

Return numbers of data point counts below each number in @index as hashref.

If a number is given instead of arrayref, @index is created
by dividing [min, max] into $n intervals.

If no parameters are given, return previous result, if any.

=cut

sub frequency_distribution_ref {
	my $self = shift;
	my $index = shift;

	return unless $self->count;
	# ah, compatibility - return last value
	return $self->{cache}{frequency_distribution_ref}
		unless defined $index;
	# make index if number given
	if (!ref $index) {
		croak __PACKAGE__.": frequency_distribution_ref(): ".
			"argument must be array, of number > 2, not $index"
			unless $index > 2;
		my $min = $self->_lower($self->min);
		my $max = $self->_upper($self->max);
		my $step = ($max - $min) / $index;
		$index = [ map { $min + $_ * $step } 1..$index ];
	};

	@$index = (-$INF, sort { $a <=> $b } @$index);

	my @count;
	for (my $i = 0; $i<@$index-1; $i++) {
		push @count, $self->_count( $index->[$i], $index->[$i+1] );
	};
	shift @$index; # remove -inf

	my %hash;
	@hash{@$index} = @count;
	$self->{cache}{frequency_distribution_ref} = \%hash;
	return \%hash;
};

=head1 Specific methods

The folowing methods only apply to this module, or are experimental.

=cut

=head2 bucket_width

Get bin width (relative to center of bin). Percentiles are off
by no more than half of this. DEPRECATED.

=cut

sub bucket_width {
	my $self = shift;
	return $self->{base} - 1;
};

=head2 log_base

Get upper/lower bound ratio for logarithmic bins.
This represents relative precision of sample.

=head2 linear_width

Get width of linear buckets.
This represents absolute precision of sample.

=head2 linear_threshold

Get absolute value threshold below which interpolation is switched to linear.

=cut

sub log_base {
	my $self = shift;
	return $self->{base};
};

sub linear_width {
	my $self = shift;
	return $self->{linear_width};
};

sub linear_threshold {
	my $self = shift;
	return $self->{linear_thresh};
};

=head2 add_data_hash ( { value => weight, ... } )

Add values with counts/weights.
This can be used to import data from other
Statistics::Descriptive::LogScale object.

Returns self, so that methods can be chained.

Negative counts are allowed and treated as "forgetting" data.
If a bin count goes below zero, such bin is simply discarded.
Minus infinity weight is allowed and has the same effect.
Data is guaranteed to remain consistent.

If incorrect data is given (i.e. non-numeric, undef, or +infinity),
an exception is thrown and nothing changes.

B<NOTE> Cache may be reset, even if no data was actually inserted.

B<NOTE> It is possible to add infinite values to data pool.
The module will try and calculate whatever can still be calculated.
However, no portable way of serializing such values is done yet.

=cut

sub add_data_hash {
	my $self = shift;
	my $hash = shift;

	# check incoming data for being numeric, and no +inf values
	eval {
		use warnings FATAL => qw(numeric);
		while (my ($k, $v) = each %$hash) {
			$k == 0+$k and $v == 0+$v and $v < $INF
				or die "Infinite count for $k\n";
		}
	};
	croak __PACKAGE__.": add_data_hash failed: $@"
		if $@;

	delete $self->{cache};

	# update our counters
	foreach (keys %$hash) {
		next unless $hash->{$_};
		my $key = $self->_round($_);

		# Insert data. Make sure -Inf doesn't corrupt our counter.
		my $newcount = ($self->{data}{$key} || 0) + $hash->{$_};
		if ($newcount > 0) {
			# normal insert
			$self->{data}{$key} = $newcount;
			$self->{count} += $hash->{$_};
		} else {
			# We're "forgetting" data, AND the bin got empty
			$self->{count} -= delete $self->{data}{$key} || 0;
		};
	};
	$self;
};

=head2 get_data_hash( %options )

Return distribution hashref {value => number of occurances}.

This is inverse of add_data_hash.

Options may include:

=over

=item * min - ignore values below this. (See find_boundaries)

=item * max - ignore values above this. (See find_boundaries)

=item * ltrim - ignore this % of values on lower end. (See find_boundaries)

=item * rtrim - ignore this % of values on upper end. (See find_boundaries)

=item * noise_thresh - strip bins with count below this.

=back

=cut

sub get_data_hash {
	my ($self, %opt) = @_;

	# shallow copy of data if no options given
	return {%{ $self->{data} }} unless %opt;

	my ($min, $max) = $self->find_boundaries( %opt );
	my $noize = $opt{noize_thresh} || 0;

	my $data = $self->{data};
	my %hash;
	foreach (keys %$data ) {
		$_ < $min and next;
		$_ > $max and next;
		$data->{$_} < $noize and next;
		$hash{$_} = $data->{$_};
	};

	return \%hash;
};

=head2 TO_JSON()

Return enough data to recreate the whole object as an unblessed hashref.

This routine conforms with C<JSON::XS>, hence the name.
Can be called as

    my $str = JSON::XS->new->allow_blessed->convert_blessed->encode( $this );

B<NOTE> This module DOES NOT require JSON::XS or serialize to JSON.
It just deals with data.
Use C<JSON::XS>, C<YAML::XS>, C<Data::Dumper> or any serializer of choice.

    my $raw_data = $stat->TO_JSON;
    Statistics::Descriptive::LogScale->new( %$raw_data );

Would generate an exact copy of C<$stat> object
(provided it's S::D::L and not a subclass).

=head2 clone( [ %options ] )

Copy constructor - returns copy of an existing object.
Cache is not preserved.

Constructor options may be given to override existing data. See new().

Trim options may be given to get partial data. See get_data_hash().

=cut

sub clone {
	my ($self, %opt) = @_;

	my $raw = $self->TO_JSON;
	if (%opt) {
		$raw->{data} = $self->get_data_hash( %opt )
			unless exists $opt{data};
		exists $opt{$_} and $raw->{$_} = $opt{$_}
			for @new_keys;
	};

	return (ref $self)->new( %$raw );
};

sub TO_JSON {
	my $self = shift;
	# UGLY HACK Increase linear_thresh by a factor of base ** 1/10
	# so that it's rounded down to present value
	return {
		CLASS => ref $self,
		VERSION => $VERSION,
		base => $self->{base},
		linear_width => $self->{linear_width},
		linear_thresh => $self->{linear_thresh} * ($self->{base}+9)/10,
		only_linear => $self->{only_linear},
		data => $self->get_data_hash,
	};
};

=head2 scale_sample( $scale )

Multiply all bins' counts by given value. This can be used to adjust
significance of previous data before adding new data (e.g. gradually
"forgetting" past data in a long-running application).

=cut

sub scale_sample {
	my $self = shift;
	my $factor = shift;
	$factor > 0 or croak (__PACKAGE__.": scale_sample: factor must be positive");

	delete $self->{cache};
	foreach (@{ $self->_sort }) {
		$self->{data}{$_} *= $factor;
	};
	$self->{count} *= $factor;
	return $self;
};

=head2 mean_of( $code, [$min, $max] )

Return expectation of $code over sample within given range.

$code is expected to be a pure function (i.e. depending only on its input
value, and having no side effects).

The underlying integration mechanism only calculates $code once per bin,
so $code should be stable as in not vary wildly over small intervals.

=cut

sub mean_of {
	my $self = shift;
	my ($code, $min, $max) = @_;

	my $weight = $self->sum_of( sub {1}, $min, $max );
	return unless $weight;
	return $self->sum_of($code, $min, $max) / $weight;
};

=head1 Experimental methods

These methods may be subject to change in the future, or stay, if they
are good.

=head2 sum_of ( $code, [ $min, $max ] )

Integrate arbitrary function over the sample within the [ $min, $max ] interval.
Default values for both limits are infinities of appropriate sign.

Values in the edge bins are cut using interpolation if needed.

NOTE: sum_of(sub{1}, $a, $b) would return rough nubmer of data points
 between $a and $b.

EXPERIMENTAL. The method name may change in the future.

=cut

sub sum_of {
	my $self = shift;
	my ($code, $realmin, $realmax) = @_;

	# Just app up stuff
	if (!defined $realmin and !defined $realmax) {
		my $sum = 0;
		while (my ($val, $count) = each %{ $self->{data} }) {
			$sum += $count * $code->( $val );
		};
		return $sum;
	};

	$realmin = -$INF unless defined $realmin;
	$realmax =  $INF unless defined $realmax;
	return 0 if( $realmin >= $realmax );

	# correct limits. $min, $max are indices; $left, $right are limits
	my $min   = $self->_round($realmin);
	my $max   = $self->_round($realmax);
	my $left  = $self->_lower($realmin);
	my $right = $self->_upper($realmax);

	# find first bin that's above $left
	my $keys = $self->_sort;
	my $i = _bin_search_ge($keys, $left);

	# warn "sum_of [$min, $max]";
	# add up bins
	my $sum = 0;
	for (; $i < @$keys; $i++) {
		my $val = $keys->[$i];
		last if $val > $right;
		$sum += $self->{data}{$val} * $code->( $val );
	};

	# cut edges: the hard part
	# min and max are now used as indices
	# if min or max hits 0, we cut it in half (i.e. into equal 0+ and 0-)
	# warn "Add up, sum_of = $sum";
	if ($self->{data}{$max}) {
		my $width = $self->_upper($max) - $self->_lower($max);
		my $part = $width
			? ($self->_upper($max) - $realmax) / $width
			: 0.5;
		$sum -= $self->{data}{$max} * $code->($max) * $part;
	};
	# warn "Cut R,  sum_of = $sum";
	if ($self->{data}{$min}) {
		my $width = $self->_upper($min) - $self->_lower($min);
		my $part = $width
			? ($realmin - $self->_lower($min)) / $width
			: 0.5;
		$sum -= $self->{data}{$min} * $code->($min) * $part;
	};
	# warn "Cut L,  sum_of = $sum";

	return $sum;
}; # end sum_of

=head2 histogram ( %options )

Returns array of form [ [ count0_1, x0, x1 ], [count1_2, x1, x2 ], ... ]
where countX_Y is number of data points between X and Y.

Options may include:

=over

=item * count (+) - number of intervals to divide sample into.

=item * index (+) - interval borders as array. Will be sorted before processing.

=item * min - ignore values below this. Default = $self->min - epsilon.

=item * max - ignore values above this. Default = $self->max + epsilon.

=item * ltrim - ignore this % of values on lower end.

=item * rtrim - ignore this % of values on upper end.

=item * normalize_to <nnn> - adjust counts so that max number becomes nnn.
This may be useful if one intends to draw pictures.

=back

Either count or index must be present.

NOTE: this is equivalent to frequency_distribution_ref but better suited
for omitting sample tails and outputting pretty pictures.

=cut

sub histogram {
	my ($self, %opt) = @_;

	return unless $self->count;
	my ($min, $max) = $self->find_boundaries( %opt );
	# build/check index
	my @index = @{ $opt{index} || [] };
	if (!@index) {
		my $n = $opt{count};
		$n > 0 or croak (__PACKAGE__.": histogram: insufficient options (count < 1 )");
		my $step = ($max - $min) / $n;
		for (my $x = $min; $x <= $max; $x += $step) {
			push @index, $x;
		};
	} else {
		# sort & uniq raw index
		my %known;
		@index = grep { !$known{$_}++ } @index;
		@index = sort { $a <=> $b } @index;
		@index > 1 or croak (__PACKAGE__.": histogram: insufficient options (index < 2)");
	};

	# finally: estimated counts between indices!
	my @ret;
	for ( my $i = 0; $i<@index-1; $i++) {
		my $count = $self->_count( $index[$i], $index[$i+1] );
		push @ret, [ $count, $index[$i], $index[$i+1] ];
	};

	# if normalize - find maximum & divide by it
	if (my $norm = $opt{normalize_to}) {
		my $max = 0;
		$max < $_->[0] and $max = $_->[0]
			for @ret;
		$norm /= $max;
		$_->[0] *= $norm for @ret;
	};

	return \@ret;
};

=head2 find_boundaries( %opt )

Return ($min, $max) of part of sample denoted by options.

Options may include:

=over

=item * min - ignore values below this. default = min() - epsilon.

=item * max - ignore values above this. default = max() + epsilon.

=item * ltrim - ignore this % of values on lower end.

=item * rtrim - ignore this % of values on upper end.

=back

If no options are given, the whole sample is guaranteed to reside between
returned values.

=cut

sub find_boundaries {
	my $self = shift;
	my %opt = @_;

	return unless $self->count;

	# preprocess boundaries
	my $min = defined $opt{min} ? $opt{min} : $self->_lower( $self->min );
	my $max = defined $opt{max} ? $opt{max} : $self->_upper( $self->max );

	if ($opt{ltrim}) {
		my $newmin = $self->percentile( $opt{ltrim} );
		defined $newmin and $newmin > $min and $min = $newmin;
	};
	if ($opt{utrim}) {
		my $newmax = $self->percentile( 100-$opt{utrim} );
		defined $newmax and $newmax < $max and $max = $newmax;
	};

	return ($min, $max);
};

=head2 format( "printf-like expression", ... )

Returns a summary as requested by format string.
Just as with printf and sprintf, a placeholder starts with a C<%>,
followed by formatting options and a

The following placeholders are supported:

=over

=item * % - a literal %

=item * s, f, g - a normal printf acting on an extra argument.
The number of extra arguments MUST match the number of such placeholders,
or this function dies.

=item * n - count;

=item * m - min;

=item * M - max,

=item * a - mean,

=item * d - standard deviation,

=item * S - skewness,

=item * K - kurtosis,

=item * q(x) - x-th quantile (requires argument),

=item * p(x) - x-th percentile (requires argument),

=item * P(x) - cdf - the inferred cumulative distribution function (x)
(requires argument),

=item * e(n) - central_moment - central moment of n-th power
(requires argument),

=item * E(n) - std_moment - standard moment of n-th power (requires argument),

=item * A(n) - abs_moment - absolute moment of n-th power (requires argument).

=back

For example,

    $stat->format( "99%% results lie between %p(0.5) and %p(99.5)" );

Or

    for( my $i = 0; $i < @stats; $i++ ) {
        print $stats[$i]->format( "%s-th average value is %a +- %d", $i );
    };

=cut

my %format = (
    # percent literal
    '%' => '%',
    # placeholders without parameters
    n => 'count',
    m => 'min',
    M => 'max',
    a => 'mean',
    d => 'std_dev',
    S => 'skewness',
    K => 'kurtosis',
    # placeholders with 1 parameter
    q => 'quantile?',
    p => 'percentile?',
    P => 'cdf?',
    e => 'central_moment?',
    E => 'std_moment?',
    A => 'abs_moment?',
);

my %printf = (
    s => 1,
    f => 1,
    g => 1,
);

my $re_format = join "|", keys %format, keys %printf;
$re_format = qr((?:$re_format));

sub format {
	my ($self, $format, @extra) = @_;

	# FIXME this accepts %m(5), then dies - UGLY
    # TODO rewrite this as a giant sprintf... one day...
	$format =~ s <%([0-9.\-+ #]*)($re_format)(?:\(($re_num)?\)){0,1}>
		< _format_dispatch($self, $2, $1, $3, \@extra) >ge;

    croak __PACKAGE__.": Extra arguments in format()"
        if @extra;
	return $format;
};

sub _format_dispatch {
	my ($obj, $method, $float, $arg, $extra) = @_;

    # Handle % escapes
	if ($method !~ /^[a-zA-Z]/) {
		return $method;
	};
    # Handle printf built-in formats
    if (!$format{$method}) {
        croak __PACKAGE__.": Not enough arguments in format()"
            unless @$extra;
        return sprintf "%${float}${method}", shift @$extra;
    };

    # Now we know it's LogScale's own method
    $method = $format{$method};
	if ($method =~ s/\?$//) {
		die "Missing argument in method $method" if !defined $arg;
	} else {
		die "Extra argument in method $method" if defined $arg;
	};
	my $result = $obj->$method($arg);

	# work around S::D::Full's convention that "-inf == undef"
	$result = -9**9**9
		if ($method eq 'percentile' and !defined $result);
	return sprintf "%${float}f", $result;
};

################################################################
#  No more public methods please

# MEMOIZE
# We'll keep methods' returned values under {cache}.
# All setters destroy said cache altogether.
# PLEASE replace this with a ready-made module if there's one.

# Sorry for this black magic, but it's too hard to write //= in EVERY method
# Long story short
# The next sub replaces $self->foo() with
# sub { $self->{cache}{foo} //= $self->originnal_foo }
# All setter methods are EXPECTED to destroy {cache} altogether.

# NOTE if you plan subclassing the method, re-memoize methods you change.
sub _memoize_method {
	my ($class, $name, $arg) = @_;

	my $orig_code = $class->can($name);
	die "Error in memoizer section ($name)"
		unless ref $orig_code eq 'CODE';

	# begin long conditional
	my $cached_code = !$arg
	? sub {
		if (!exists $_[0]->{cache}{$name}) {
			$_[0]->{cache}{$name} = $orig_code->($_[0]);
		};
		return $_[0]->{cache}{$name};
	}
	: sub {
		my $self = shift;
		my $arg = do {
			no warnings 'uninitialized'; ## no critic
			join ':', @_;
		};

		if (!exists $self->{cache}{"$name:$arg"}) {
			$self->{cache}{"$name:$arg"} = $orig_code->($self, @_);
		};
		return $self->{cache}{"$name:$arg"};
	};
	# conditional ends here

	no strict 'refs'; ## no critic
	no warnings 'redefine'; ## no critic
	*{$class."::".$name} = $cached_code;
}; # end of _memoize_method

# Memoize all the methods w/o arguments
foreach ( qw(sum sumsq mean min max mode) ) {
	__PACKAGE__->_memoize_method($_);
};

# Memoize methods with 1 argument
foreach (qw(quantile central_moment std_moment abs_moment standard_deviation
	variance)) {
	__PACKAGE__->_memoize_method($_, 1);
};

# add shorter alias of standard_deviation (this must happen AFTER memoization)
{
	no warnings 'once'; ## no critic
	*std_dev = \&standard_deviation;
	*stdev = \&standard_deviation;
};

# Get number of values below $x
# Like sum_of(sub{1}, undef, $x), but faster.
# Used by cdf()
sub _count {
	my $self = shift;
	@_>1 and return $self->_count($_[1]) - $self->_count($_[0]);
	my $x = shift;

	my $upper = $self->_upper($x);
	my $i = _bin_search_gt( $self->_sort, $upper );
	!$i-- and return 0;
	my $count = $self->_probability->[$i];

	# interpolate
	my $bin = $self->_round( $x );
	if (my $val = $self->{data}{$bin}) {
		my $width = ($upper - $bin) * 2;
		my $part = $width ? ( ($upper - $x) / $width) : 1/2;
		$count -= $part * $val;
	};
	return $count;
};

# BINARY SEARCH
# Not a method, just a function
# Takes sorted \@array and a $num
# Return lowest $i such that $array[$i] >= $num
# Return (scalar @array) if no such $i exists
sub _bin_search_ge {
	my ($array, $x) = @_;

	return 0 unless @$array and $array->[0] < $x;
	my $l = 0;
	my $r = @$array;
	while ($l+1 < $r) {
		my $m = int( ($l + $r) /2);
		$array->[$m] < $x ? $l = $m : $r = $m;
	};
	return $l+1;
};
sub _bin_search_gt {
	my ($array, $x) = @_;
	my $i = _bin_search_ge(@_);
	$i++ if defined $array->[$i] and $array->[$i] == $x;
	return $i;
};

# THE CORE
# Here come the number=>bin functions
# round() generates bin center
# upper() and lower() are respective boundaries.
# Here's the algorithm:
# 1) determine whether bin is linear or logarithmic
# 2) for linear bins, return bin# * bucket_width (==2*absolute error)
#         add/subtract 0.5 to get edges.
# 3) for logarithmic bins, return base ** bin# with appropriate sign
#         multiply by precalculated constant to get edges
#         note that +0.5 doesn't work here, since sqrt(a*b) != (a+b)/2
# This part is fragile and can be written better

# center of bin containing x
sub _round {
	my $self = shift;
	my $x = shift;

	use warnings FATAL => qw(numeric uninitialized);

	if (abs($x) <= $self->{linear_thresh}) {
		return $self->{linear_width}
			&& $self->{linear_width} * floor( $x / $self->{linear_width} + 0.5 );
	};
	my $i = floor (((log abs $x) - $self->{logfloor})/ $self->{logbase});
	my $value = $self->{base} ** $i;
	return $x < 0 ? -$value : $value;
};

# lower, upper limits of bin containing x
sub _lower {
	my $self = shift;
	my $x = shift;

	use warnings FATAL => qw(numeric uninitialized);

	if (abs($x) <= $self->{linear_thresh}) {
		return $self->{linear_width}
			&& $self->{linear_width} * (floor( $x / $self->{linear_width} + 0.5) - 0.5);
	};
	my $i = floor (((log abs $x) - $self->{logfloor} )/ $self->{logbase});
	if ($x > 0) {
		return  $self->{floor} * $self->{base}**($i);
	} else {
		return -$self->{floor} * $self->{base}**($i+1);
	};
};

sub _upper {
	return -$_[0]->_lower(-$_[1]);
};

# build bin index
sub _sort {
	my $self = shift;
	return $self->{cache}{sorted}
		||= [ sort { $a <=> $b } keys %{ $self->{data} } ];
};

# build cumulative bin counts index
sub _probability {
	my $self = shift;
	return $self->{cache}{probability} ||= do {
		my @array;
		my $sum = 0;
		foreach (@{ $self->_sort }) {
			$sum += $self->{data}{$_};
			push @array, $sum;
		};
		\@array;
	};
};

=head1 AUTHOR

Konstantin S. Uvarin, C<< <khedin at gmail.com> >>

=head1 BUGS

The module is currently under development. There may be bugs.

C<mode()> only works for discrete distributions, and simply returns
the first bin with largest bin count.
A better algorithm is wanted.

C<sum_of()> should have been made a private method.
Its signature and/or name may change in the future.

See the TODO file in the distribution package.

Please feel free to post bugs and/or feature requests to github:
L<https://github.com/dallaylaen/perl-Statistics-Descriptive-LogScale/issues/new>

Alternatively, you can use CPAN RT
via e-mail C<bug-statistics-descriptive-logscale at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Statistics-Descriptive-LogScale>.

Your contribution is appreciated.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::Descriptive::LogScale

You can also look for information at:

=over 4

=item * GitHub:

L<https://github.com/dallaylaen/perl-Statistics-Descriptive-LogScale>

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-Descriptive-LogScale>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Statistics-Descriptive-LogScale>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Statistics-Descriptive-LogScale>

=item * Search CPAN

L<http://search.cpan.org/dist/Statistics-Descriptive-LogScale/>

=back

=head1 ACKNOWLEDGEMENTS

This module was inspired by a talk that Andrew Aksyonoff, author of
L<Sphinx search software|http://sphinxsearch.com/>,
has given at HighLoad++ conference in Moscow, 2012.

L<Statistics::Descriptive> was and is used as reference when in doubt.
Several code snippets were shamelessly stolen from there.

C<linear_width> and C<linear_threshold> parameter names were suggested by
CountZero from http://perlmonks.org

=head1 LICENSE AND COPYRIGHT

Copyright 2013-2015 Konstantin S. Uvarin.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Statistics::Descriptive::LogScale

package Statistics::Descriptive::Discrete;

### This module draws heavily from Statistics::Descriptive

use strict;
use warnings;
use Carp;
use AutoLoader;
use vars qw($VERSION $AUTOLOAD $DEBUG $Tolerance %autosubs);

$VERSION = '0.11';
$DEBUG = 0;

#see Statistics::Descriptive documentation for use of $Tolerance
$Tolerance = 0.0;

#what subs can be autoloaded?
%autosubs = (
  count					=> undef,
  mean					=> undef,
  geometric_mean=> undef,
  harmonic_mean=>undef,
  sum					=> undef,
  mode					=> undef,
  median				=> undef,
  min					=> undef,
  max					=> undef,
  mindex			=> undef,
  maxdex			=> undef,
  standard_deviation	=> undef,
  sample_range			=> undef,
  variance				=> undef,
  text					=> undef,
);

	
sub new
{
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	$self->{_permitted} = \%autosubs;
	$self->{data} = ();
	$self->{_dataindex} = (); #index of where each value first seen when adding data
	$self->{dirty} = 1; #is the data dirty?
	$self->{_index} = 0; #current index of number of data items added

	bless ($self,$class);
	print __PACKAGE__,"->new(",join(',',@_),")\n" if $DEBUG;
	return $self;
}

# Clear the stat object & erase all data
# Object will be ready to use as if new was called
# Not sure this is more efficient than just creating a new object but
# maintained for compatability with Statistics::Descriptive
sub clear
{
	my $self = shift;
    my %keys = %{ $self };

	#remove _permitted from the deletion list
    delete $keys{"_permitted"};

    foreach my $key (keys %keys) 
	{ # Check each key in the object
		print __PACKAGE__,"->clear, deleting $key\n" if $DEBUG;
        delete $self->{$key};  # Delete any out of date cached key
    }
	$self->{data} = ();
	$self->{_dataindex} = ();
	$self->{dirty} = 1;
	$self->{_index} = 0;
}

sub add_data
{
	#add data but don't compute ANY statistics yet
	my $self = shift;
	print __PACKAGE__,"->add_data(",join(',',@_),")\n" if $DEBUG;

	#get each element and add 0 to force it be a number
	#that way, 0.000 and 0 are treated the same
	my $val = shift;
	while (defined $val)
	{
		$val += 0; 
		$self->{data}{$val}++;
		if (not exists $self->{_dataindex}{$val}) {
			$self->{_dataindex}{$val} = $self->{_index};
		}
		$self->{_index}++;
		#set dirty flag so we know cached stats are invalid
		$self->{dirty}++;
		$val = shift; #get next element
	}
}

sub add_data_tuple
{
	#add data but don't compute ANY statistics yet
	#the data are pairs of values and occurrences
	#e.g. 4,2 means 2 occurrences of the value 4
	#thanks to Bill Dueber for suggesting this

	my $self = shift;
	print __PACKAGE__,"->add_data_tuple(",join(',',@_),")\n" if $DEBUG;

	#we want an even number of arguments (tuples in the form (value, count))
	carp "argument list must have even number of elements" if @_ % 2;

	#get each element and add 0 to force it be a number
	#that way, 0.000 and 0 are treated the same
	#if $count is 0, then this will set the dirty flag but have no effect on
	#the statistics
	my $val = shift;
	my $count = shift;
	while (defined $count)
	{
		$val += 0; 
		$self->{data}{$val} += $count;
		if (not exists $self->{_dataindex}{$val}) {
			$self->{_dataindex}{$val} = $self->{_index};
		}
		$self->{_index} += $count;
		#set dirty flag so we know cached stats are invalid
		$self->{dirty}++;
		$val = shift; #get next element
		$count = shift; 
	}
}

sub _test_for_too_small_val
{
    my $self = shift;
    my $val = shift;

    return (abs($val) <= $Statistics::Descriptive::Discrete::Tolerance);
}

sub _calc_harmonic_mean
{
    my $self = shift;
		my $count = shift;
		my $datakeys = shift; #array ref

    my $hs = 0;

    foreach my $val ( @{$datakeys} )
    {
        ##Guarantee that there are no divide by zeros
        if ($self->_test_for_too_small_val($val))
        {
            return;
        }
			
				foreach (1..$self->{data}{$val})
				{
        	$hs += 1/$val;
				}
    }

    if ($self->_test_for_too_small_val($hs))
    {
        return;
    }

    return $count/$hs;
}

sub _all_stats
{
	#compute all the stats in one sub to save overhead of sub calls
	#a little wasteful to do this if all we want is count or sum for example but
	#I want to keep add_data as lean as possible since it gets called a lot
	my $self = shift;
	print __PACKAGE__,"->_all_stats(",join(',',@_),")\n" if $DEBUG;

	#if data is empty, set all stats to undef and return
	if (!$self->{data})
	{
		foreach my $key (keys %{$self->{_permitted}})
		{
			$self->{$key} = undef;
		}
		$self->{count} = 0;
		return;
	}

	#count = total number of data values we have
	my $count = 0;
	$count += $_ foreach (values %{$self->{data}});

	my @datakeys = keys %{$self->{data}};

	#initialize min, max, mode to an arbitrary value that's in the hash
	my $default = $datakeys[0];
	my $max  = $default; 
	my $min  = $default;
	my $mode = $default;
	my $moden = 0;
	my $sum = 0;

	#find min, max, sum, and mode
	foreach (@datakeys)
	{
		my $n = $self->{data}{$_};
		$sum += $_ * $n;
		$min = $_ if $_ < $min;
		$max = $_ if $_ > $max;
	
		#only finds one mode but there could be more than one
		#also, there might not be any mode (all the same frequency)
		#todo: need to make this more robust
		if ($n > $moden)
		{
			$mode = $_;
			$moden = $n;
		}
	}
	my $mindex = $self->{_dataindex}{$min};
	my $maxdex = $self->{_dataindex}{$max};

	my $mean = $sum/$count;
	
	my $stddev = 0;
	my $variance = 0;

	if ($count > 1)
	{
		# Thanks to Peter Dienes for finding and fixing a round-off error
		# in the following variance calculation

		foreach my $val (@datakeys)
		{
			$stddev += $self->{data}{$val} * (($val - $mean) ** 2);
		}
		$variance = $stddev / ($count - 1);
		$stddev = sqrt($variance);
	}
	else {$stddev = undef}
	
	#find median, and do it without creating a list of the all the data points 
	#if n=count is odd and n=2k+1 then median = data(k+1)
	#if n=count is even and n=2k, then median = (data(k) + data(k+1))/2
	my $odd = $count % 2; #odd or even number of points?
	my $even = !$odd;
	my $k = $odd ? ($count-1)/2 : $count/2;
	my $median = undef;
	my $temp = 0;
	MEDIAN: foreach my $val (sort {$a <=> $b} (@datakeys))
	{
		foreach (1..$self->{data}{$val})
		{
			$temp++;
			if (($temp == $k) && $even)
			{
				$median += $val;
			}
			elsif ($temp == $k+1)
			{
				$median += $val;
				$median /= 2 if $even;
				last MEDIAN;
			}
		}
	}
	
	#compute geometric mean
	my $gm = 1;
	my $exponent = 1/$count;
	foreach my $val (@datakeys)
		{
				if ($val < 0)
				{
						$gm = undef;
						last;
				}
				foreach (1..$self->{data}{$val})
				{
					$gm *= $val**$exponent;
				}
		}

	#compute harmonic mean
	my $harmonic_mean = scalar $self->_calc_harmonic_mean($count, \@datakeys);

	print __PACKAGE__,"count: $count, _index ",$self->{_index},"\n" if $DEBUG;

	$self->{count}  = $count;
	$self->{sum}    = $sum;
	$self->{standard_deviation} = $stddev;
	$self->{variance} = $variance;
	$self->{min}    = $min;
	$self->{max}    = $max;
	$self->{mindex} = $mindex;
	$self->{maxdex} = $maxdex;
	$self->{sample_range} = $max - $min; #todo: does this require any bounds checking
	$self->{mean}    = $mean;
	$self->{geometric_mean} = $gm;
	$self->{harmonic_mean} = $harmonic_mean;
	$self->{median} = $median;
	$self->{mode}   = $mode;

	#clear dirty flag so we don't needlessly recompute the statistics 
	$self->{dirty} = 0;  
}

sub set_text
{
	my $self = shift;
	$self->{text} = shift;
}

sub get_data
{
	#returns a list of the data in sorted order
	#the list could be very big an this defeat the purpose of using this module
	#use this only if you really need it
	my $self = shift;
	print __PACKAGE__,"->get_data(",join(',',@_),")\n" if $DEBUG;

	my @data;
	foreach my $val (sort {$a <=> $b} (keys %{$self->{data}}))
	{
		push @data, $val foreach (1..$self->{data}{$val});
	}
	return @data;
}

# this is the previous frequency_distribution code
# redid this completely based on current implementation in
# Statistics::Descriptive
# sub frequency_distribution
# {
# 	#Compute frequency distribution (histogram), borrowed heavily from Statistics::Descriptive
# 	#Behavior is slightly different than Statistics::Descriptive
# 	#e.g. if partition is not specified, we use  to set the number of partitions
# 	#     if partition = 0, then we return the data hash WITHOUT binning it into equal bins
# 	#	  I often want to just see how many of each value I saw 
# 	#Also, you can manually pass in the bin info (min bin, bin size, and number of partitions)
# 	#I don't cache the frequency data like Statistics::Descriptive does since it's not as expensive to compute
# 	#but I might add that later
# 	#todo: the minbin/binsize stuff is funky and not intuitive -- fix it
# 	my $self = shift;
# 	print __PACKAGE__,"->frequency_distribution(",join(',',@_),")\n" if $DEBUG;

# 	my $partitions = shift; #how many partitions (bins)?
# 	my $minbin = shift; #upper bound of first bin
# 	my $binsize = shift; #how wide is each bin?
	
# 	#if partition == 0, then return the data hash
# 	if (not defined $partitions || ($partitions == 0))
# 	{
# 		$self->{frequency_partitions} = 0;
# 		%{$self->{frequency}} = %{$self->{data}};
# 		return %{$self->{frequency}};
# 	}

# 	#otherwise, partition better be >= 1
# 	return undef unless $partitions >= 1;

# 	$self->_all_stats() if $self->{dirty}; #recompute stats if dirty, (so we have count)
# 	return undef if $self->{count} < 2; #must have at least 2 values 

# 	#set up the bins
# 	my ($interval, $iter, $max);
# 	if (defined $minbin && defined $binsize)
# 	{
# 		$iter = $minbin;
# 		$max = $minbin+$partitions*$binsize - $binsize;
# 		$interval = $binsize;
# 		$iter -= $interval; #so that loop that sets up bins works correctly
# 	}
# 	else
# 	{
# 		$iter = $self->{min};
# 		$max = $self->{max};
# 		$interval = $self->{sample_range}/$partitions;
# 	}
# 	my @k;
# 	my %bins;
# 	while (($iter += $interval) < $max)
# 	{
# 		$bins{$iter} = 0;
# 		push @k, $iter;
# 	}
# 	$bins{$max} = 0;
# 	push @k, $max;

# 	VALUE: foreach my $val (keys %{$self->{data}})
# 	{
# 		foreach my $k (@k)
# 		{
# 			if ($val <= $k)
# 			{
# 				$bins{$k} += $self->{data}{$val};  #how many of this value do we have?
# 				next VALUE;
# 			}
# 		}
# # 	}

# 	%{$self->{frequency}} = %bins;   #save it for later in case I add caching
# 	$self->{frequency_partitions} = $partitions; #in case I add caching in the future
# 	return %{$self->{frequency}};
# }

sub frequency_distribution_ref
{
    my $self = shift;
    my @k = ();

		# If called with no parameters, return the cached hashref 
		# if we have one and data is not dirty
		# This is implemented this way because that's how Statistics::Descriptive
		# implements this.  I don't like it.
  	if ((!@_) && (! $self->{dirty}) && (defined $self->{_frequency}))
    {
        return $self->{_frequency};
    }

		$self->_all_stats() if $self->{dirty}; #recompute stats if dirty, (so we have count)

    # Must have at least two elements
    if ($self->count() < 2)
    {
        return undef;
    }
  
    my %bins;
    my $partitions = shift;

    if (ref($partitions) eq 'ARRAY')
    {
        @k = @{ $partitions };
        return undef unless @k;  ##Empty array
        if (@k > 1) {
            ##Check for monotonicity
            my $element = $k[0];
            for my $next_elem (@k[1..$#k]) {
                if ($element > $next_elem) {
                    carp "Non monotonic array cannot be used as frequency bins!\n";
                    return undef;
                }
                $element = $next_elem;
            }
        }
        %bins = map { $_ => 0 } @k;
    }
    else
    {
        return undef unless (defined $partitions) && ($partitions >= 1);
        my $interval = $self->sample_range() / $partitions;
        foreach my $idx (1 .. ($partitions-1))
        {
            push @k, ($self->min() + $idx * $interval);
        }

        $bins{$self->max()} = 0;

        push @k, $self->max();
    }

    ELEMENT:
    foreach my $element (keys %{$self->{data}})
    {
        foreach my $limit (@k)
        {
            if ($element <= $limit)
            {
                $bins{$limit} += $self->{data}{$element};
                next ELEMENT;
            }
        }
    }

		$self->{_frequency} = \%bins;
    return $self->{_frequency};
}

sub frequency_distribution {
    my $self = shift;

    my $ret = $self->frequency_distribution_ref(@_);

    if (!defined($ret))
    {
        return undef;
    }
    else
    {
        return %$ret;
    }
}

# return count of unique values in data if called in scalar context
# returns sorted array of unique data values if called in array context
# returns undef if no data
sub uniq
{
	my $self = shift;
	
	if (!$self->{data})
	{
		return undef;
	}

	my @datakeys = sort {$a <=> $b} keys %{$self->{data}};

	if (wantarray)
	{
		return @datakeys;
	}
	else
	{
		my $uniq = @datakeys;
		return $uniq;
	}
}

sub AUTOLOAD {
	my $self = shift;
	my $type = ref($self)
		or croak "$self is not an object";
	my $name = $AUTOLOAD;
	$name =~ s/.*://;     ##Strip fully qualified-package portion
	return if $name eq "DESTROY";
	unless (exists $self->{_permitted}{$name} ) {
		croak "Can't access `$name' field in class $type";
	}

	print __PACKAGE__,"->AUTOLOAD $name\n" if $DEBUG;

	#compute stats if necessary
	$self->_all_stats() if $self->{dirty};
	return $self->{$name};
}

1;

__END__

=head1 NAME

Statistics::Descriptive::Discrete - Compute descriptive statistics for discrete data sets.

To install, use the CPAN module (https://metacpan.org/pod/Statistics::Descriptive::Discrete).

=head1 SYNOPSIS

  use Statistics::Descriptive::Discrete;

  my $stats = new Statistics::Descriptive::Discrete;
  $stats->add_data(1,10,2,1,1,4,5,1,10,8,7);
  print "count = ",$stats->count(),"\n";
  print "uniq  = ",$stats->uniq(),"\n";
  print "sum = ",$stats->sum(),"\n";
  print "min = ",$stats->min(),"\n";
  print "min index = ",$stats->mindex(),"\n";
  print "max = ",$stats->max(),"\n";
  print "max index = ",$stats->maxdex(),"\n";
  print "mean = ",$stats->mean(),"\n";
  print "geometric mean = ",$stats->geometric_mean(),"\n";
  print "harmonic mean = ", $stats->harmonic_mean(),"\n";
  print "standard_deviation = ",$stats->standard_deviation(),"\n";
  print "variance = ",$stats->variance(),"\n";
  print "sample_range = ",$stats->sample_range(),"\n";
  print "mode = ",$stats->mode(),"\n";
  print "median = ",$stats->median(),"\n";
  my $f = $stats->frequency_distribution_ref(3);
  for (sort {$a <=> $b} keys %$f) {
    print "key = $_, count = $f->{$_}\n";
  }

=head1 DESCRIPTION

This module provides basic functions used in descriptive statistics.
It borrows very heavily from Statistics::Descriptive::Full
(which is included with Statistics::Descriptive) with one major
difference.  This module is optimized for discretized data 
e.g. data from an A/D conversion that  has a discrete set of possible values.  
E.g. if your data is produced by an 8 bit A/D then you'd have only 256 possible 
values in your data  set.  Even though you might have a million data points, 
you'd only have 256 different values in those million points.  Instead of storing the 
entire data set as Statistics::Descriptive does, this module only stores
the values seen and the number of times each value occurs.

For very large data sets, this storage method results in significant speed
and memory improvements.  For example, for an 8-bit data set (256 possible values),
with 1,000,000 data points,  this module is about 10x faster than Statistics::Descriptive::Full 
or Statistics::Descriptive::Sparse.  

Statistics::Descriptive run time is a factor of the size of the data set. In particular,
repeated calls to C<add_data> are slow.  Statistics::Descriptive::Discrete's C<add_data> is 
optimized for speed.  For a give number of data points, this module's run time will increase 
as the number of unique data values in the data set increases. For example, while this module
runs about 10x the speed of Statistics::Descriptive::Full for an 8-bit data set, the 
run speed drops to about 3x for an equivalent sized 20-bit data set.  

See sdd_prof.pl in the examples directory to play with profiling this module against 
Statistics::Descriptive::Full.

=head1 METHODS

=over

=item $stat = Statistics::Descriptive::Discrete->new();

Create a new statistics object.

=item $stat->add_data(1,2,3,4,5);

Adds data to the statistics object.  Sets a flag so that
the statistics will be recomputed the next time they're
needed.

=item $stat->add_data_tuple(1,2,42,3);

Adds data to the statistics object where every two elements
are a value and a count (how many times did the value occur?)
The above is equivalent to C<< $stat->add_data(1,1,42,42,42); >>
Use this when your data is in a form isomorphic to 
($value, $occurrence).

=item $stat->max();

Returns the maximum value of the data set.

=item $stat->min();

Returns the minimum value of the data set.

=item $stat->mindex();

Returns the index of the minimum value of the data set.  
The index returned is the first occurence of the minimum value.

Note: the index is determined by the order data was added using add_data() or add_data_tuple().
It is meaningless in context of get_data() as get_data() does not return values in the same
order in which they were added.  This behavior is different than Statistics::Descriptive which
does preserve order.  

=item $stat->maxdex();

Returns the index of the maximum value of the data set.  
The index returned is the first occurence of the maximum value.

Note: the index is determined by the order data was added using 
C<add_data()> or C<add_data_tuple()>. It is meaningless in context of 
C<get_data()> as C<get_data()> does not return values in the same
order in which they were added.  This behavior is different than 
Statistics::Descriptive which does preserve order.  

=item $stat->count();

Returns the total number of elements in the data set.

=item $stat->uniq();

If called in scalar context, returns the total number of unique elements in the data set.
For example, if your data set is (1,2,2,3,3,3), uniq will return 3.  

If called in array context, returns an array of each data value in the data set in sorted order.
In the above example, C<< @uniq = $stats->uniq(); >> would return (1,2,3)

This function is specific to Statistics::Descriptive::Discrete
and is not implemented in Statistics::Descriptive.

It is useful for getting a frequency distribution for each discrete value in the data the set:

   my $stats = Statistics::Descriptive::Discrete->new();
	 $stats->add_data_tuple(1,1,2,2,3,3,4,4,5,5,6,6,7,7);
	 my @bins = $stats->uniq();
	 my $f = $stats->frequency_distribution_ref(\@bins);
	 for (sort {$a <=> $b} keys %$f) {
		 print "value = $_, count = $f->{$_}\n";
	 }

=item $stat->sum();

Returns the sum of all the values in the data set.

=item $stat->mean();

Returns the mean of the data.

=item $stat->harmonic_mean();

Returns the harmonic mean of the data.  Since the mean is undefined
if any of the data are zero or if the sum of the reciprocals is zero,
it will return undef for both of those cases.

=item $stat->geometric_mean();

Returns the geometric mean of the data.  Returns C<undef> if any of the data
are less than 0. Returns 0 if any of the data are 0.

=item $stat->median();

Returns the median value of the data.

=item $stat->mode();

Returns the mode of the data.

=item $stat->variance();

Returns the variance of the data.

=item $stat->standard_deviation();

Returns the standard_deviation of the data.

=item $stat->sample_range();

Returns the sample range (max - min) of the data set.

=item $stat->frequency_distribution_ref($num_partitions);

=item $stat->frequency_distribution_ref(\@bins);

=item $stat->frequency_distribution_ref();

C<frequency_distribution_ref($num_partitions)> slices the data into
C<$num_partitions> sets (where $num_partitions is greater than 1) and counts
the number of items that fall into each partition. It returns a reference to a
hash where the keys are the numerical values of the partitions used. The
minimum value of the data set is not a key and the maximum value of the data
set is always a key. The number of entries for a particular partition key are
the number of items which are greater than the previous partition key and less
then or equal to the current partition key. As an example,

   $stat->add_data(1,1.5,2,2.5,3,3.5,4);
   $f = $stat->frequency_distribution_ref(2);
   for (sort {$a <=> $b} keys %$f) {
      print "key = $_, count = $f->{$_}\n";
   }

prints

   key = 2.5, count = 4
   key = 4, count = 3

since there are four items less than or equal to 2.5, and 3 items
greater than 2.5 and less than 4.

C<frequency_distribution_ref(\@bins)> provides the bins that are to be used
for the distribution.  This allows for non-uniform distributions as
well as trimmed or sample distributions to be found.  C<@bins> must
be monotonic and must contain at least one element.  Note that unless the
set of bins contains the full range of the data, the total counts returned will
be less than the sample size.

Calling C<frequency_distribution_ref()> with no arguments returns the last
distribution calculated, if such exists.

=item my %hash = $stat->frequency_distribution($partitions);

=item my %hash = $stat->frequency_distribution(\@bins);

=item my %hash = $stat->frequency_distribution();

Same as C<frequency_distribution_ref()> except that it returns the hash
clobbered into the return list. Kept for compatibility reasons with previous
versions of Statistics::Descriptive::Discrete and using it is discouraged.

Note: in earlier versions of Statistics:Descriptive::Discrete, C<frequency_distribution()>
behaved differently than the Statistics::Descriptive implementation.  Any code that uses
this function should be carefully checked to ensure compatability with the current 
implementation.


=item $stat->get_data();

Returns a copy of the data array.  Note: This array could be
very large and would thus defeat the purpose of using this
module.  Make sure you really need it before using get_data().

The returned array contains the values sorted by value.  It does
not preserve the order in which the values were added.  Preserving
order would defeat the purpose of this module which trades speed
and memory usage over preserving order.  If order is important,
use Statistics::Descriptive.

=item $stat->clear();

Clears all data and resets the instance as if it were newly created

Effectively the same as

  my $class = ref($stat);
  undef $stat;
  $stat = new $class;

=back

=head1 NOTE

The interface for this module strives to be identical to Statistics::Descriptive.  
Any differences are noted in the description for each method.

=head1 BUGS

=over

=item *

Code for calculating mode is not as robust as it should be.

=item *

Other bugs are lurking I'm sure.

=back

=head1 TODO

=over 

=item *

Add rest of methods (at least ones that don't depend on original order of data) 
from Statistics::Descriptive

=back

=head1 AUTHOR

Rhet Turnbull, rturnbull+cpan@gmail.com

=head1 CREDIT

Thanks to the following individuals for finding bugs, providing feedback, 
and submitting changes:

=over

=item *

Peter Dienes for finding and fixing a bug in the variance calculation.

=item *

Bill Dueber for suggesting the add_data_tuple method.

=back

=head1 COPYRIGHT

  Copyright (c) 2002, 2019 Rhet Turnbull. All rights reserved.  This
  program is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.

  Portions of this code is from Statistics::Descriptive which is under
  the following copyrights:

  Copyright (c) 1997,1998 Colin Kuskie. All rights reserved.  This
  program is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.

  Copyright (c) 1998 Andrea Spinelli. All rights reserved.  This program
  is free software; you can redistribute it and/or modify it under the
  same terms as Perl itself.

  Copyright (c) 1994,1995 Jason Kastner. All rights
  reserved.  This program is free software; you can redistribute it
  and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

Statistics::Descriptive

Statistics::Discrete





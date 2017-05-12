package Statistics::Descriptive::Discrete;

### This module draws heavily from Statistics::Descriptive

use strict;
use warnings;
use Carp;
use AutoLoader;
use vars qw($VERSION $REVISION $AUTOLOAD $DEBUG %autosubs);

$VERSION = '0.07';
$REVISION = '$Revision: 1.14 $';
$DEBUG = 0;

#what subs can be autoloaded?
%autosubs = (
  count					=> undef,
  mean					=> undef,
  sum					=> undef,
  uniq					=> undef,
  mode					=> undef,
  median				=> undef,
  min					=> undef,
  max					=> undef,
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
	$self->{permitted} = \%autosubs;
	$self->{data} = ();
	$self->{dirty} = 1; #is the data dirty?
	
	bless ($self,$class);
	print __PACKAGE__,"->new(",join(',',@_),")\n" if $DEBUG;
	return $self;
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
		#set dirty flag so we know cached stats are invalid
		$self->{dirty}++;
		$val = shift; #get next element
		$count = shift; 
	}
}

sub _all_stats
{
	#compute all the stats in one sub to save overhead of sub calls
	#a little wasteful to do this if all we want is count or sum for example but
	#I want to keep add_data as lean as possible since it gets called a lot
	my $self = shift;
	print __PACKAGE__,"->_all_stats(",join(',',@_),")\n" if $DEBUG;

	#count = total number of data values we have
	my $count = 0;
	$count += $_ foreach (values %{$self->{data}});

	#todo: I use keys %{$self->{data}} several times:
	#should I store it in an array and use the array instead?

	#uniq = number of unique data values
	my $uniq = keys %{$self->{data}};

	#initialize min, max, mode to an arbitrary value that's in the hash
	my $default = (keys %{$self->{data}})[0];
	my $max  = $default; 
	my $min  = $default;
	my $mode = $default;
	my $moden = 0;
	my $sum = 0;

	#find min, max, sum, and mode
	foreach (keys %{$self->{data}})
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
	my $mean = $sum/$count;
	
	my $stddev = 0;
	my $variance = 0;

	if ($count > 1)
	{
		# Thanks to Peter Dienes for finding and fixing a round-off error
		# in the following variance calculation

		foreach my $val (keys %{$self->{data}})
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
	MEDIAN: foreach my $val (sort {$a <=> $b} (keys %{$self->{data}}))
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
	
	$self->{count}  = $count;
	$self->{uniq}   = $uniq;
	$self->{sum}    = $sum;
	$self->{standard_deviation} = $stddev;
	$self->{variance} = $variance;
	$self->{min}    = $min;
	$self->{max}    = $max;
	$self->{sample_range} = $max - $min;
	$self->{mean}    = $mean;
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

sub frequency_distribution
{
	#Compute frequency distribution (histogram), borrowed heavily from Statistics::Descriptive
	#Behavior is slightly different than Statistics::Descriptive
	#e.g. if partition is not specified, we use uniq to set the number of partitions
	#     if partition = 0, then we return the data hash WITHOUT binning it into equal bins
	#Why? because I like it this way -- I often want to just see how many of each value I saw 
	#Also, you can manually pass in the bin info (min bin, bin size, and number of partitions)
	#I don't cache the frequency data like Statistics::Descriptive does since it's not as expensive to compute
	#but I might add that later
	#todo: the minbin/binsize stuff is funky and not intuitive -- fix it
	my $self = shift;
	print __PACKAGE__,"->frequency_distribution(",join(',',@_),")\n" if $DEBUG;

	my $partitions = shift; #how many partitions (bins)?
	my $minbin = shift; #upper bound of first bin
	my $binsize = shift; #how wide is each bin?
	
	#if partition == 0, then just give 'em the data hash
	if (defined $partitions && ($partitions == 0))
	{
		$self->{frequency_partitions} = 0;
		%{$self->{frequency}} = %{$self->{data}};
		return %{$self->{frequency}};
	}

	#otherwise, partition better be >= 1
	return undef unless $partitions >= 1;

	$self->_all_stats() if $self->{dirty}; #recompute stats if dirty, (so we have count)
	return undef if $self->{count} < 2; #must have at least 2 values 

	#set up the bins
	my ($interval, $iter, $max);
	if (defined $minbin && defined $binsize)
	{
		$iter = $minbin;
		$max = $minbin+$partitions*$binsize - $binsize;
		$interval = $binsize;
		$iter -= $interval; #so that loop that sets up bins works correctly
	}
	else
	{
		$iter = $self->{min};
		$max = $self->{max};
		$interval = $self->{sample_range}/$partitions;
	}
	my @k;
	my %bins;
	while (($iter += $interval) < $max)
	{
		$bins{$iter} = 0;
		push @k, $iter;
	}
	$bins{$max} = 0;
	push @k, $max;

	VALUE: foreach my $val (keys %{$self->{data}})
	{
		foreach my $k (@k)
		{
			if ($val <= $k)
			{
				$bins{$k} += $self->{data}{$val};  #how many of this value do we have?
				next VALUE;
			}
		}
	}

	%{$self->{frequency}} = %bins;   #save it for later in case I add caching
	$self->{frequency_partitions} = $partitions; #in case I add caching in the future
	return %{$self->{frequency}};
}

sub AUTOLOAD {
	my $self = shift;
	my $type = ref($self)
		or croak "$self is not an object";
	my $name = $AUTOLOAD;
	$name =~ s/.*://;     ##Strip fully qualified-package portion
	return if $name eq "DESTROY";
	unless (exists $self->{permitted}{$name} ) {
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

=head1 SYNOPSIS

  use Statistics::Descriptive::Discrete;

  my $stats = new Statistics::Descriptive::Discrete;
  $stats->add_data(1,10,2,0,1,4,5,1,10,8,7);
  print "count = ",$stats->count(),"\n";
  print "uniq  = ",$stats->uniq(),"\n";
  print "sum = ",$stats->sum(),"\n";
  print "min = ",$stats->min(),"\n";
  print "max = ",$stats->max(),"\n";
  print "mean = ",$stats->mean(),"\n";
  print "standard_deviation = ",$stats->standard_deviation(),"\n";
  print "variance = ",$stats->variance(),"\n";
  print "sample_range = ",$stats->sample_range(),"\n";
  print "mode = ",$stats->mode(),"\n";
  print "median = ",$stats->median(),"\n";

=head1 DESCRIPTION

This module provides basic functions used in descriptive statistics.
It borrows very heavily from Statistics::Descriptive::Full
(which is included with Statistics::Descriptive) with one major
difference.  This module is optimized for discretized data 
e.g. data from an A/D conversion that 
has a discrete set of possible values.  E.g. if your data is produced
by an 8 bit A/D then you'd have only 256 possible values in your data 
set.  Even though you might have a million data points, you'd only have
256 different values in those million points.  Instead of storing the 
entire data set as Statistics::Descriptive does, this module only stores
the values it's seen and the number of times it's seen each value.

For very large data sets, this storage method results in significant speed
and memory improvements.  In a test case with 2.6 million data points from
a real world application, Statistics::Descriptive::Discrete took 40 seconds 
to calculate a set of statistics instead of the 561 seconds required by
Statistics::Descriptive::Full.  It also required only 4MB of RAM instead of 
the 400MB used by Statistics::Descriptive::Full for the same data set.

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
The above is equivalent to $stat->add_data(1,1,42,42,42);
Use this when your data is in a form isomorphic to 
($value, $occurrence).

=item $stat->max();

Returns the maximum value of the data set.

=item $stat->min();

Returns the minimum value of the data set.

=item $stat->count();

Returns the total number of elements in the data set.

=item $stat->uniq();

Returns the total number of unique elements in the data set.
For example, if your data set is (1,2,2,3,3,3), uniq will 
return 3.

=item $stat->sum();

Returns the sum of all the values in the data set.

=item $stat->mean();

Returns the mean of the data.

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

=item $stat->get_data();

Returns a copy of the data array.  Note: This array could be
very large and would thus defeat the purpose of using this
module.  Make sure you really need it before using get_data().

=back

=head1 NOTE

The interface for this module is almost identical to Statistics::Descriptive.  
This module is incomplete and not fully tested.  

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

Make test suite more robust

=item *

Add rest of methods (at least ones that don't depend on original order of data) 
from Statistics::Descriptive

=back

=head1 AUTHOR

Rhet Turnbull, RhetTbull on perlmonks.org, rhettbull at hotmail.com

If you find this code useful, I would appreciate an email letting me know.

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

  Copyright (c) 2002 Rhet Turnbull. All rights reserved.  This
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




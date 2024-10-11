package Statistics::Running::Tiny;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.04';

use overload
	'+' => \&concatenate,
	'==' => \&equals,
	'""' => \&stringify,
;

use constant SMALL_NUMBER_FOR_EQUALITY => 1E-10;

# creates an obj. There are no input params
sub     new {
	my $class = $_[0];

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my $self = {
		# these are internal variables to store mean etc. or used to calculate Kurtosis
		'M1' => 0.0,
		'M2' => 0.0,
		'M3' => 0.0,
		'M4' => 0.0,
		'SUM' => 0.0,
		'ABS-SUM' => 0.0,
		'MIN' => 0.0,
		'MAX' => 0.0,
		'N' => 0, # number of data items inserted
	};
	bless($self, $class);
	$self->clear();
	return $self
}
# push Data: a sample and process/update mean and all other stat measures
sub     add {
	my $self = $_[0];
	my $x = $_[1];

	# ADDED 22/02/2019
	if( ! defined $x ){ print STDERR "add() : attempted to push undefined value."; return }

	my $aref = ref($x);

	if( $aref eq '' ){
		# a scalar input
		my ($delta, $delta_n, $delta_n2, $term1);
		my $n1 = $self->{'N'};
		if( $n1 == 0 ){ $self->{'MIN'} = $self->{'MAX'} = $x }
		else {
			if( $x < $self->{'MIN'} ){ $self->{'MIN'} = $x }
			if( $x > $self->{'MAX'} ){ $self->{'MAX'} = $x }
		}
		$self->{'SUM'} += $x; # add x to the total SUM
		$self->{'ABS-SUM'} += abs($x); # add abs-value x to the total ABS-SUM
		$self->{'N'} += 1; # increment sample size push in
		my $n0 = $self->{'N'};

		$delta = $x - $self->{'M1'};
		$delta_n = $delta / $n0;
		$delta_n2 = $delta_n * $delta_n;
		$term1 = $delta * $delta_n * $n1;
		$self->{'M1'} += $delta_n;
		$self->{'M4'} += $term1 * $delta_n2 * ($n0*$n0 - 3*$n0 + 3)
			+ 6 * $delta_n2 * $self->{'M2'}
			- 4 * $delta_n * $self->{'M3'}
		;
		$self->{'M3'} += $term1 * $delta_n * ($n0 - 2)
			- 3 * $delta_n * $self->{'M2'}
		;
		$self->{'M2'} += $term1;
	} elsif( $aref eq 'ARRAY' ){
		# an array input
		foreach (@$x){ $self->add($_) }
	} else {
		die "add(): only ARRAY and SCALAR can be handled (input was type '$aref')."
	}
}
# copies input(=src) Running obj into current/self overwriting our data, this is not a clone()!
sub     copy_from {
	my $self = $_[0];
	my $src = $_[1];
	$self->{'M1'} = $src->M1();
	$self->{'M2'} = $src->M2();
	$self->{'M3'} = $src->M3();
	$self->{'M4'} = $src->M4();
	$self->set_N($src->get_N());
}
# clones current obj into a new Running obj with same values
sub     clone {
	my $self = $_[0];
	my $newO = Statistics::Running::Tiny->new();
	$newO->{'M1'} = $self->M1();
	$newO->{'M2'} = $self->M2();
	$newO->{'M3'} = $self->M3();
	$newO->{'M4'} = $self->M4();
	$newO->set_N($self->get_N());
	return $newO
}
# clears all data entered/calculated including histogram
sub     clear {
	my $self = $_[0];
	$self->{'M1'} = 0.0;
	$self->{'M2'} = 0.0;
	$self->{'M3'} = 0.0;
	$self->{'M4'} = 0.0;
	$self->{'MIN'} = 0.0;
	$self->{'MAX'} = 0.0;
	$self->{'SUM'} = 0.0;
	$self->{'ABS-SUM'} = 0.0;
	$self->{'N'} = 0;
}
# return the mean of the data entered so far
sub     mean { return $_[0]->{'M1'} }
sub     sum { return $_[0]->{'SUM'} }
sub     abs_sum { return $_[0]->{'ABS-SUM'} }
sub     min { return $_[0]->{'MIN'} }
sub     max { return $_[0]->{'MAX'} }
# get number of total elements entered so far
sub     get_N { return $_[0]->{'N'} }
sub     variance {
	my $self = $_[0];
	my $m = $self->{'N'};
	if( $m == 1 ){ return 0 }
	return $self->{'M2'}/($m-1.0)
}
sub     standard_deviation { return sqrt($_[0]->variance()) }
sub     skewness {
	my $self = $_[0];
	my $m = $self->{'M2'};
	if( $m == 0 ){ return 0 }
	return sqrt($self->{'N'})
		* $self->{'M3'} / ($m ** 1.5)
	;
}
sub     kurtosis {
	my $self = $_[0];
	my $m = $self->{'M2'};
	if( $m == 0 ){ return 0 }
	return $self->{'N'}
		* $self->{'M4'}
		/ ($m * $m)
	- 3.0
	;
}
# concatenates another Running obj with current
# returns a new Running obj with concatenated stats
# input objs are not modified.
sub     concatenate {
	my $self = $_[0]; # us
	my $other = $_[1]; # another Running obj

	my $combined = Statistics::Running::Tiny->new();

	my $selfN = $self->get_N();
	my $otherN = $other->get_N();
	my $selfM2 = $self->M2();
	my $otherM2 = $other->M2();
	my $selfM3 = $self->M3();
	my $otherM3 = $other->M3();

	my $combN = $selfN + $otherN;
	$combined->set_N($combN);
	 
	my $delta = $other->M1() - $self->M1();
	my $delta2 = $delta*$delta;
	my $delta3 = $delta*$delta2;
	my $delta4 = $delta2*$delta2;

	$combined->{'M1'} = ($selfN*$self->M1() + $otherN*$other->M1()) / $combN;

	$combined->{'M2'} = $selfM2 + $otherM2 +
			$delta2 * $selfN * $otherN / $combN;
	 
	$combined->{'M3'} = $selfM3 + $otherM3 + 
			$delta3 * $selfN * $otherN * ($selfN - $otherN)/($combN*$combN) +
			3.0*$delta * ($selfN*$otherM2 - $otherN*$selfM2) / $combN
	;
	 
	$combined->{'M4'} = $self->{'M4'} + $other->{'M4'}
			+ $delta4*$selfN*$otherN * ($selfN*$selfN - $selfN*$otherN + $otherN*$otherN) / 
				($combN*$combN*$combN)
			+ 6.0*$delta2 * ($selfN*$selfN*$otherM2 + $otherN*$otherN*$selfM2)/($combN*$combN) +
				  4.0*$delta*($selfN*$otherM3 - $otherN*$selfM3) / $combN
	;

	$combined->{'SUM'} = $self->{'SUM'} + $other->{'SUM'};
	$combined->{'ABS-SUM'} = $self->{'ABS-SUM'} + $other->{'ABS-SUM'};
	$combined->{'MIN'} = $self->{'MIN'} < $other->{'MIN'} ? $self->{'MIN'} : $other->{'MIN'};
	$combined->{'MAX'} = $self->{'MAX'} > $other->{'MAX'} ? $self->{'MAX'} : $other->{'MAX'};
	 
	return $combined;
}
# appends another Running obj INTO current
# current obj (self) IS MODIFIED
sub     append {
	my $self = $_[0]; # us
	my $other = $_[1]; # another Running obj
	$self->copy_from($self+$other);
}
# equality only wrt to stats BUT NOT histogram
sub     equals {
	my $self = $_[0]; # us
	my $other = $_[1]; # another Running obj
	return
		$self->get_N() == $other->get_N() &&
		$self->equals_statistics($other)
}
sub     equals_statistics {
	my $self = $_[0]; # us
	my $other = $_[1]; # another Running obj
	return
		abs($self->M1()-$other->M1()) < Statistics::Running::Tiny::SMALL_NUMBER_FOR_EQUALITY &&
		abs($self->M2()-$other->M2()) < Statistics::Running::Tiny::SMALL_NUMBER_FOR_EQUALITY &&
		abs($self->M3()-$other->M3()) < Statistics::Running::Tiny::SMALL_NUMBER_FOR_EQUALITY &&
		abs($self->M4()-$other->M4()) < Statistics::Running::Tiny::SMALL_NUMBER_FOR_EQUALITY
}
# print object as a string, string concat/printing is overloaded on this method
sub     stringify {
	my $self = $_[0];
	return "N: ".$self->get_N()
		.", mean: ".$self->mean()
		.", range: ".$self->min()." to ".$self->max()
		.", sum: ".$self->sum()
		.", standard deviation: ".$self->standard_deviation()
		.", kurtosis: ".$self->kurtosis()
		.", skewness: ".$self->skewness()
}
# internal methods, no need for anyone to know or use externally
sub     set_N { $_[0]->{'N'} = $_[1] }
sub     M1 { return $_[0]->{'M1'} }
sub     M2 { return $_[0]->{'M2'} }
sub     M3 { return $_[0]->{'M3'} }
sub     M4 { return $_[0]->{'M4'} }

1;
__END__
# end program, below is the POD
=pod

=encoding UTF-8


=head1 NAME

Statistics::Running::Tiny - Basic descriptive statistics (mean/stdev/min/max/skew/kurtosis) over data without the need to store data points ever. OOP style. The Tiny version.


=head1 VERSION

Version 0.04


=head1 SYNOPSIS

        use Statistics::Running::Tiny;
        my $ru = Statistics::Running::Tiny->new();
        for(1..100){
                $ru->add(rand());
        }
        print "mean: ".$ru->mean()."\n";
        $ru->add(12345);
        print "mean: ".$ru->mean()."\n";

        my $ru2 = Statistics::Running::Tiny->new();
        for(1..100){
                $ru2->add(rand());
        }
        my $ru3 = $ru + $ru2;
        print "mean of concatenated data: ".$ru3->mean()."\n";

        $ru += $ru2;
        print "mean after appending data: ".$ru->mean()."\n";

        print "stats: ".$ru->stringify()."\n";


=head1 DESCRIPTION

Calculate basic descriptive statistics (mean, variance, standard deviation, skewness, kurtosis)
without the need to store any data point/sample. Statistics are
updated each time a new data point/sample comes in.

There are three amazing things about B.P.Welford's algorithm implemented here:

=over 4

=item 1. It calculates and keeps updating mean/standard-deviation etc. on 
data without the need to store that data. As new data comes in, the
statistics are updated based on the state of a few variables (mean, number
of data points, etc.) but not the past data points. This includes the
calculation of standard deviation which most of us knew (wrongly) that
it requires a second pass on the data points, after the mean is calculated.
Well, B.P.Welford found a way to avoid this.

=item 2. The standard formula for standard deviation requires to sum
the square of the difference of each sample from the mean.
If samples are large numbers then you are summing differences of large
numbers. If further there is little difference between samples, and the
discrepancy from the mean is small, then you are prone to
precision errors which accumulate to destructive effect if the number of
samples is large. In contrast,  B.P.Welford's algorithm does
not suffer from this, it is stable and accurate.

=item 3. B.P.Welford's online statistics algorithm
is quite a revolutionary idea and why is not an obligatory subject
in first-year programming courses is beyond comprehension.
Here is a way to decrease those CO2 emissions.

=back

The basis for the code in this module is from 
L<John D. Cook's article and C++ implementation|https://www.johndcook.com/blog/skewness_kurtosis>


=head1 EXPORT

Nothing, this is an Object Oriented module. Once you instantiate
an object all its methods are yours.


=head1 SUBROUTINES/METHODS


=head2 new

Constructor, initialises internal variables.


=head2 add

Update our statistics after one more data point/sample (or an
array of them) is presented to us.

        my $ru1 = Statistics::Running::Tiny->new();
        for(1..100){
                $ru1->add(rand());
                print $ru1."\n";
        }

Input can be a single data point (a scalar) or a reference
to an array of data points.


=head2 copy_from

Copy state of input object into current effectively making us like
them. Our previous state is forgotten. After that adding a new data point into
us will be with the new state copied.

        my $ru1 = Statistics::Running::Tiny->new();
        for(1..100){
                $ru1->add(rand());
        }
        my $ru2 = Statistics::Running::Tiny->new();
        for(1..100){
                $ru2->add(rand(1000000));
        }
        # copy the state of ru1 into ru2. state of ru1 is forgotten.
        $ru2->copy_from($ru1);


=head2 clone

Clone state of our object into a newly created object which is returned.
Our object and returned object are identical at the time of cloning.

        my $ru1 = Statistics::Running::Tiny->new();
        for(1..100){
                $ru1->add(rand(1000000));
        }
        my $ru2 = $ru1->clone();


=head2 clear

Clear our internal state as if no data points have ever added into us.
As if we were just created. All state is forgotten and reset to zero.

=head2 mean

Returns the mean of all the data pushed in us


=head2 sum

Returns the sum of all the data pushed in us (algebraic sum, not absolute sum)


=head2 abs_sum

Returns the sum of the absolute value of all the data pushed in us (this is not algebraic sum)


=head2 min

Returns the minimum data sample added in us


=head2 max

Returns the maximum data sample added in us


=head2 get_N

Returns the number of data points/samples inserted, and had
their descriptive statistics calculated, so far.


=head2 variance

Returns the variance of the data points/samples added onto us so far.


=head2 standard_deviation

Returns the standard deviation of the data points/samples added onto us so far. This is the square root of the variance.


=head2 skewness

Returns the skewness of the data points/samples added onto us so far.


=head2 kurtosis

Returns the kurtosis of the data points/samples added onto us so far.


=head2 concatenate

Concatenates our state with the input object's state and returns
a newly created object with the combined state. Our object and
input object are not modified. The overloaded symbol '+' points
to this sub.


=head2 append

Appends input object's state into ours.
Our state is modified. (input object's state is not modified)
The overloaded symbol '+=' points
to this sub.


=head2 equals

Check if our state (number of samples and all internal state) is
the same with input object's state. Equality here implies that
ALL statistics are equal (within a small number Statistics::Running::Tiny::SMALL_NUMBER_FOR_EQUALITY)


=head2 equals_statistics

Check if our statistics only (and not sample size)
are the same with input object. E.g. it checks mean, variance etc.
but not sample size (as with the real equals()).
It returns 0 on non-equality. 1 if equal.


=head2 stringify

Returns a string description of descriptive statistics we know about
(mean, standard deviation, kurtosis, skewness) as well as the
number of data points/samples added onto us so far. Note that
this method is not necessary because stringification is overloaded
and the follow B<< print $stats_obj."\n" >> is equivalent to
B<< print $stats_obj->stringify()."\n" >>


=head1 Overloaded functionality

=over 3

=item 1. Addition of two statistics objects: B<< my $ru3 = $ru1 + $ru2 >>

=item 2. Test for equality: B<< if( $ru2 == $ru3 ){ ... } >>

=item 3. Stringification: B<< print $ru1."\n" >>

=back


=head1 Testing for Equality

In testing if two objects are the same, their means, standard deviations
etc. are compared. This is done using
B<< if( ($self->mean() - $other->mean()) < Statistics::Running::SMALL_NUMBER_FOR_EQUALITY ){ ... } >>


=head1 BENCHMARKS

Run B<< make bench >> for benchmarks which report the maximum number of data points inserted
per second (in your system).


=head1 SEE ALSO

=over 4

=item 1. L<Wikipedia|http://en.wikipedia.org/wiki/Algorithms_for_calculating_variance#Online_algorithm>

=item 2. L<John D. Cook's article and C++ implementation|https://www.johndcook.com/blog/skewness_kurtosis>
was used both as inspiration and as the basis for the formulas for B<< kurtosis() >> and B<< skewness() >>

=item 3. L<Statistics::Welford> This module does not provide B<< kurtosis() >> and B<< skewness() >>
which current module does.

=item 4. L<Statistics::Running> This is the exact same module with the addition of
a histogram logging each inserted data point. The histogram is in effect
a discrete approximation of the Probability Distribution of the input data
points. The current module is the same as that bar the histogram. That
makes it a bit faster. Check B<< make bench >> for benchmarks

=back


=head1 AUTHOR

Andreas Hadjiprocopis, C<< <bliako at cpan.org> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-statistics-running at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Statistics-Running>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::Running::Tiny


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-Running>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Statistics-Running>

=item * Review this module at PerlMonks

L<https://www.perlmonks.org/?node_id=21144>

=item * Search CPAN

L<http://search.cpan.org/dist/Statistics-Running/>

=back


=head1 DEDICATIONS

Almaz


=head1 ACKNOWLEDGEMENTS

B.P.Welford, John Cook.


=head1 LICENSE AND COPYRIGHT

Copyright 2018-2019 Andreas Hadjiprocopis.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
=cut

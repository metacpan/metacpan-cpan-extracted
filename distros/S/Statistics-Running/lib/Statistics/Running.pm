package Statistics::Running;

use 5.006;
use strict;
use warnings;

use Data::Dumper;

our $VERSION = '0.13';

# overload these operators to have special meaning when
# operand(s) are Statistics::Running:
use overload
	# add two stats object and adjust summed mean,stdev etc.
	'+' => \&concatenate,
	# check if two stats objects are same wrt mean,stdev,N BUT NOT histogram
	'==' => \&equals,
	# convert a stats object into a string, e.g. print $obj."\n";
	'""' => \&stringify,
;

use Try::Tiny;
use Statistics::Histogram;

# this is for all numerical equality comparisons
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
		'ABS-SUM' => 0.0,
		'SUM' => 0.0,
		'MIN' => 0.0,
		'MAX' => 0.0,
		'N' => 0, # number of data items inserted
		# this histogram is updated each time a new data point is pushed in the object
		# it just holds the number of items in each bin, so it is not too expensive.
		# with this we get an idea of the Probability Distribution of the pushed data.
		# Which may or may not be useful to users.
		# Should you want to avoid this then use Statistics::Running::Tiny
		'histo' => {
			'num-bins' => -1,
			'bins' => {
				# b: [histo-left-boundary, bin1_right_boundary, bin2_right_boundary, ... binN-1_right_boundary, histo-right-boundary]
				'b' => [], # length is 'num-bins'+1
				# c: contains the counts, its size is equal to the number of bins
				# the first cell contains counts in the interval [histo-left-boundary, bin1_right_boundary]
				# the last cell contains counts of [binN-1_right_boundary, histo-right-boundary]
				'c' => [], # length 'num-bins'
			},
			# cached stringified histogram, it is re-calculated only if data points added
			# and asked to print histogram
			'stringified' => undef,
			# when asked to stringify a hist we actually use a cached string
			# which needs to be recalculated whenever data is added or hist re-created
			'needs-recalculate' => 1,
		},
	};
	bless($self, $class);
	$self->clear();
	return $self
}
# returns the histogram bins (can be empty) in our internal format
sub     histogram { return $_[0]->{'histo'} }
# if no params, it returns our bins as a hash
# otherwise it imports input bins in the form of a hash
# and before that it erases previous histogram and forms it according to input, e.g.
# sets bin-widths and numbins etc.
sub     histogram_bins_hash {
	my $self = $_[0];
	my $bins = $_[1];
	if( ! defined($bins) ){
		# export to a hash
		return $self->_bins2hash()
	}
	# import from a hash
	$self->_hash2bins($bins);
}
# if no params, it returns our bins as a hash of the form returned by Statistics::Descriptive::frequency_distribution()
# otherwise it imports input bins in the form of a hash in the form returned by Statistics::Descriptive::frequency_distribution()
sub     histogram_bins_stathash {
	my $self = $_[0];
	my $bi = $_[1];
	if( ! defined($bi) ){
		# export to a hash
		return $self->_bins2stathash()
	}
	# import from a hash
	$self->_stathash2bins($bi);
}
# return a string showing this histogram by calling Statistics::Histogram::print_histogram()
# we first convert our hist to stathash format
sub     histogram_stringify {
	my ($self, @opts) = @_;
	if( $self->{'histo'}->{'needs-recalculate'} == 1 ){ $self->_histogram_recalculate(@opts) }
	return $self->{'histo'}->{'stringified'}
}
# we need to recalculate each time a new data is added.
# but we do recalculate whenever it is needed, i.e. when we asked to print histogram
sub	_histogram_recalculate {
	my ($self, @stringify_opts) = @_;
	my $histstr = "<no-bins>";
	if( $self->{'histo'}->{'num-bins'} > 0 ){
		Try::Tiny::try {
			$histstr = Statistics::Histogram::print_histogram(
				'hist' => $self->_bins2stathash(),
				'x_min' => $self->{'histo'}->{'bins'}->{'b'}->[0],
				use_linear_axes => 1,
				@stringify_opts
			)
		} Try::Tiny::catch {
			print STDERR "_histogram_recalculate() : error caught trying to stringify: $_\n";
			$histstr = "<no-bins>";
		};
	}
	$self->{'histo'}->{'stringified'} = $histstr;
	$self->{'histo'}->{'needs-recalculate'} = 0;
}
# disable histogram logging, all existing histogram data is erased
sub	histogram_disable {
	my $self = $_[0];

	$self->{'histo'}->{'num-bins'} = -1;
	$self->{'histo'}->{'bins'}->{'b'} = [];
	$self->{'histo'}->{'bins'}->{'c'} = [];
	$self->{'histo'}->{'needs-recalculate'} = 1;
}
# returns the count in bin specified as 1st input param
sub	histogram_count { return $_[0]->{'histo'}->{'c'}->[$_[1]] }

# enables histogram logging
# it expects some parameters for creating the histogram in various forms,
# e.g. by specifying the number of bins, bin-width and left boundary or
# by specifying a HASH or ARRAY of bin specifications for non-uniform bin
# sizes. HASH must be of the form 'FROM:TO'->counts 
# ARRAY of bin boundaries of the form
# [histo-left-boundary, bin1_right_boundary, bin2_right_boundary, ... binN-1_right_boundary, histo-right-boundary]
# the number of bins is 1 less than the length of this array
sub	histogram_enable {
	my $self = $_[0];
	my $params = $_[1]; # $_[1] // {} does not work for perl<5.10, ? : requests $_[1] twice, so Cish if( ! defined below...

	if( ! defined($params) ){ $params = {} }

	my ($m1, $m2, $m3);
	if( defined($m1=$params->{'bins'}) ){
		my $aref = ref($m1);
		if( $aref eq 'ARRAY' ){
			# an array of bin boundaries of the form
			# [histo-left-boundary, bin1_right_boundary, bin2_right_boundary, ... binN-1_right_boundary, histo-right-boundary]
			# the number of bins is 1 less than the length of this array
			my @mm = @$m1;
			$self->{'histo'}->{'num-bins'} = scalar(@mm)-1;
			$self->{'histo'}->{'bins'}->{'b'} = [@mm];
			$self->{'histo'}->{'bins'}->{'c'} = (0) x $self->{'histo'}->{'num-bins'};
		} elsif( $aref eq 'HASH' ){
			# a hashref keyed on bin-intervals in the form FROM:TO->counts
			$self->_hash2bins($m1);
		} else { die "parameter 'bins' expects either a HASHREF keyed on bin-intervals in the form FROM:TO->counts (and counts can be non-zero if that is a previous histogram), or an ARRAYREF with bin boundaries of the form [histo-left-boundary, bin1_right_boundary, bin2_right_boundary, ... binN-1_right_boundary, histo-right-boundary]. In this case the number of bins is 1 less than the length of the array." }
	} elsif( defined($m1=$params->{'bin-width'})
	     &&  defined($m2=$params->{'num-bins'})
	     &&  defined($m3=$params->{'left-boundary'})
	){
		# we re-create our own bins based on num-bins etc.
		$self->_histogram_create_bins_from_spec($m1, $m2, $m3)
	} else {
		# no params! we need params
		print STDERR "enable_histogram() : failed to enable histogram because no histogram specification was supplied. Try enable_histogram({bin-width=>1, nun-bins=>10, left-boundary=>-5});\n";
	}
	$self->{'histo'}->{'needs-recalculate'} = 1;
}
# set existing histogram to zero counts
sub     histogram_reset {
	my $self = $_[0];

	# no params, set all counts OF ALREADY EXISTING histogram to zero
	my $m1 = $self->{'histo'}->{'bins'}->{'c'};
	for(my $i=$self->{'histo'}->{'num-bins'};$i-->0;){ $m1->[$i] = 0 }
	$self->{'histo'}->{'needs-recalculate'} = 1;
}
# push Data: a sample and process/update mean and all other stat measures
# also insert it in histogram
sub     add {
	my $self = $_[0];
	my $x = $_[1];

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
		$self->{'ABS-SUM'} += abs($x); # add abs(x) to the total SUM
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
		# add data point to the internal histogram
		$self->_histogram_add($x);
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
	$self->_histogram_copy_from($src);
}
# clones current obj into a new Running obj with same values
sub     clone {
	my $self = $_[0];
	my $newO = Statistics::Running->new();
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
	$self->{'ABS-SUM'} = 0.0;
	$self->{'SUM'} = 0.0;
	$self->{'N'} = 0;
	$self->histogram_reset();
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
# AND returns a new Running obj with concatenated stats
# Current object is not modified.
sub     concatenate {
	my $self = $_[0]; # us
	my $other = $_[1]; # another Running obj

	my $combined = Statistics::Running->new();

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

	# add the histograms only if structure matches:
	if( $self->_equals_histograms_structure($other) ){
		$combined->_histogram_copy_from($self);
		$combined->_add_histograms($other);
	}

	return $combined;
}
# appends another Running obj INTO current
# histogram data is appended only if histogram specs are the same
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
		abs($self->M1()-$other->M1()) < Statistics::Running::SMALL_NUMBER_FOR_EQUALITY &&
		abs($self->M2()-$other->M2()) < Statistics::Running::SMALL_NUMBER_FOR_EQUALITY &&
		abs($self->M3()-$other->M3()) < Statistics::Running::SMALL_NUMBER_FOR_EQUALITY &&
		abs($self->M4()-$other->M4()) < Statistics::Running::SMALL_NUMBER_FOR_EQUALITY
}
# checks if structure is same and then if bin contents (counts) are same
# returns 1 if equals
# returns 0 if either structure or counts are not the same
sub     equals_histograms {
	my $self = $_[0]; # us
	my $other = $_[1]; # another Running obj

	# structure is not the same
	if( $self->_equals_histograms_structure($other) == 0 ){ return 0 }

	my $selfC = $self->{'histo'}->{'bins'}->{'c'};
	my $otherC = $other->{'histo'}->{'bins'}->{'c'};
	my $i;
	for($i=$self->{'histo'}->{'num-bins'};$i-->0;){
		if( $selfC->[$i] != $otherC->[$i] ){ return 0 }
	}
	return 1 # equal in structure and counts
}
# adds counts of histograms to us from other
# returns 0 if structures do not match
# returns 1 if counts added OK
sub     _add_histograms {
	my $self = $_[0]; # us
	my $other = $_[1]; # another Running obj

	# structure is not the same
	if( $self->_equals_histograms_structure($other) == 0 ){ return 0 }

	my $selfC = $self->{'histo'}->{'bins'}->{'c'};
	my $otherC = $other->{'histo'}->{'bins'}->{'c'};
	my $i;
	for($i=$self->{'histo'}->{'num-bins'};$i-->0;){
		$selfC->[$i] += $otherC->[$i];
	}
	$self->{'histo'}->{'needs-recalculate'} = 1;
	return 1 # counts added
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
		.", histogram:\n".$self->histogram_stringify()
}
# internal methods, no need for anyone to know or use externally
sub     set_N { $_[0]->{'N'} = $_[1] }
sub     M1 { return $_[0]->{'M1'} }
sub     M2 { return $_[0]->{'M2'} }
sub     M3 { return $_[0]->{'M3'} }
sub     M4 { return $_[0]->{'M4'} }
# copy src's histogram to us, erasing previous data and histo-format
sub	_histogram_copy_from {
	my $self = $_[0];
	my $src = $_[1]; # a src stats object whose histogram we are copying onto us
	$self->histogram_bins_hash($src->histogram_bins_hash());
}
# given bin-width, num-bins and left-boundary create the bin arrays
sub     _histogram_create_bins_from_spec {
	my ($self, $bw, $nb, $lb) = @_;

	$self->{'histo'}->{'num-bins'} = $nb;
	my @B = (0)x($nb+1);
	my ($i);
	my $v = $lb;
	for($i=0;$i<=$nb;$i++){
		$B[$i] = $v;
		$v += $bw;
	}
	$self->{'histo'}->{'bins'}->{'b'} = \@B;
	$self->{'histo'}->{'bins'}->{'c'} = [(0)x$nb];
	$self->{'histo'}->{'needs-recalculate'} = 1;
}
# add a datapoint to the histogram, this is usually called only via the public add()
sub     _histogram_add {
	my $self = $_[0];
	my $x = $_[1]; # value to add
	my ($n, $i);
	if( ($n=$self->{'histo'}->{'num-bins'}) <= 0 ){ return }
	my $B = $self->{'histo'}->{'bins'}->{'b'};
	for($i=0;$i<$n;$i++){
		if( ($x > $B->[$i]) && ($x <= $B->[$i+1]) ){
			$self->{'histo'}->{'bins'}->{'c'}->[$i]++;
			$self->{'histo'}->{'needs-recalculate'} = 1; # need to recalc stringify
			return
		}
	}
}
# given the bins and bin counts arrays, return a hash in the natural form:
# from-bin:to-bin -> count
# see also _bins2stathash for returning a hash of the format specified in Statistics::Descriptive
sub     _bins2hash {
	my $self = $_[0];
	my %ret = ();
	my $B = $self->{'histo'}->{'bins'}->{'b'};
	my $C = $self->{'histo'}->{'bins'}->{'c'};
	my $i;
	for($i=$self->{'histo'}->{'num-bins'};$i-->0;){
		$ret{$B->[$i].":".$B->[$i+1]} = $C->[$i]
	}
	return \%ret
}
# given the bins and bin counts arrays, return a hash with keys
# to-bin -> count
# whereas count is the count of the bin specified by to-bin and its previous key of the hash
sub     _bins2stathash {
	my $self = $_[0];
	my %ret = ();
	my $B = $self->{'histo'}->{'bins'}->{'b'};
	my $C = $self->{'histo'}->{'bins'}->{'c'};
	my $i;
	for($i=$self->{'histo'}->{'num-bins'}-1;$i-->0;){
		$ret{$B->[$i+1]} = $C->[$i]
	}
	return \%ret
}
# given a hash with keys
# from-bin:to-bin -> count
# erase and re-create the bin and counts arrays of histo.
# for a way to import Statistics::Descriptive frequency_distribution hash check _stathash2bins()
sub     _hash2bins {
	my $self = $_[0];
	my $H = $_[1];
	my @B = ();
	my @C = ();
	my @K = keys %$H;
	$self->{'histo'}->{'num-bins'} = scalar(@K);
	my ($acount, $akey);

	my @X = map {
		push(@B, $_->[1]); # left-bin (from)
		push(@C, $H->{$_->[0]}); # counts
		$_->[2]; # spit out the right-bin (to)
	}
	sort { $a->[1] <=> $b->[1] }
	  map { [ $_, split(/\:/, $_) ] }
	  @K
	;
	push(@B, $X[-1]);
	$self->{'histo'}->{'bins'}->{'b'} = \@B;
	$self->{'histo'}->{'bins'}->{'c'} = \@C;
	$self->{'histo'}->{'needs-recalculate'} = 1;
}
# given a hash with keys
# to-bin -> count
# erase and re-create the bin and counts arrays of histo.
# the hash is exactly what Statistics::Descriptive::frequency_distribution() returns
# there is only one problem: what is the left-boundary? we will set it to -infinity.
sub     _stathash2bins {
	my $self = $_[0];
	my $H = $_[1]; # hashref: exactly what Statistics::Descriptive::frequency_distribution() returns
	my @B = ();
	my @C = ();
	my @K = keys %$H;
	$self->{'histo'}->{'num-bins'} = scalar(@K);
	my ($acount, $akey);

	push(@B, -(~0 >> 1)); # -MAX_INT fuck you.
	foreach my $k (sort { $a <=> $b } keys %$H){
		push(@B, $k);
		push(@C, $H->{$k});
	}
	$self->{'histo'}->{'bins'}->{'b'} = \@B;
	$self->{'histo'}->{'bins'}->{'c'} = \@C;
	$self->{'histo'}->{'needs-recalculate'} = 1;
}
# compares the structure of the histograms of us and another obj
# if histograms have same number of bins and same bin-specs (boundaries)
# then histograms are equal and returns 1
# if both histograms contain zero bins (not initialised) then also returns 1
# else, histogram structure differs and returns 0
sub	_equals_histograms_structure {
	my ($self, $other) = @_;

	my $NB1 = $self->{'histo'}->{'num-bins'};
	if( $NB1 != $other->{'histo'}->{'num-bins'} ){ return 0 }

	# no bins, so equal!
	if( $NB1 == -1 ){ return 1 }

	my $b1 = $self->{'histo'}->{'bins'}->{'b'};
	my $b2 = $other->{'histo'}->{'bins'}->{'b'};
	for(my $i=$NB1+1;$i-->0;){
		if( $b1->[$i] != $b2->[$i] ){ return 0 }
	}
	return 1 # equal histogram STRUCTURES (not bincounts)
}
1;
__END__
# end program, below is the POD
=pod

=encoding UTF-8


=head1 NAME

Statistics::Running - Basic descriptive statistics (mean/stdev/min/max/skew/kurtosis) and discrete Probability Distribution (via histogram) over data without the need to store data points ever. OOP style.


=head1 VERSION

Version 0.11


=head1 SYNOPSIS

	use Statistics::Running;
	my $ru = Statistics::Running->new();
	for(1..100){
		$ru->add(rand());
	}
	print "mean: ".$ru->mean()."\n";
	$ru->add(12345);
	print "mean: ".$ru->mean()."\n";

	my $ru2 = Statistics::Running->new();
	$ru2->histogram_enable({
		'num-bins' => 10,
		'bin-width' => 0.01,
		'left-boundary' => 0
	});
	for(1..100){
		$ru2->add(rand());
	}
	print "Probability Distribution of data:\n".$ru2->histogram_stringify()."\n";

	# add two stat objects together (histograms are not!)
	my $ru3 = $ru + $ru2;
	print "mean of concatenated data: ".$ru3->mean()."\n";

	$ru += $ru2;
	print "mean after appending data: ".$ru->mean()."\n";

	print "stats: ".$ru->stringify()."\n";

	# example output:
	print $ru2."\n";
N: 100, mean: 0.488978434779093, range: 0.0056063539679414 to 0.99129297226348, standard deviation: 0.298129905728534, kurtosis: -1.22046199974301, skewness: -0.0268827866000826, histogram:
   0.000 -    0.010:     2 #####################################################
   0.010 -    0.020:     2 #####################################################
   0.020 -    0.030:     2 #####################################################
   0.030 -    0.041:     2 #####################################################
   0.041 -    0.051:     1 ###########################
   0.051 -    0.062:     0 |
   0.062 -    0.073:     2 #####################################################
   0.073 -    0.083:     0 |
   0.083 -    0.094:     1 ###########################

=head1 DESCRIPTION

Statistics are updated every time a new data point
is added in. The common practice to calculate descriptive
statistics for 5 data points as well as 1 billion points
is to store them in an array,
loop over the array to calculate the mean, then loop over the array
again to calculate standard deviation, as Sum (x_i-mean)**2.
Standard deviation is the reason data is stored in the array.
This module uses B.P.Welford's method to calculate descriptive
statistics by continually adjusting the stats and not storing
a single data point. Except from the computational and environmental
benefits of such an approach, B.P.Welford's method is also
immune to accumulated precision errors. It is stable and accurate.

For more details on the method and its stability look at this:
L<John D. Cook's article and C++ implementation|https://www.johndcook.com/blog/skewness_kurtosis>

A version without the histogram exists under L<Statistics::Running::Tiny>
and is faster, obviously. About 25% faster.

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

The basis for the code in this module comes from
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

	my $ru1 = Statistics::Running->new();
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

	my $ru1 = Statistics::Running->new();
	for(1..100){
		$ru1->add(rand());
	}
	my $ru2 = Statistics::Running->new();
	for(1..100){
		$ru2->add(rand());
	}
	# copy the state of ru1 into ru2. state of ru1 is forgotten.
	$ru2->copy_from($ru1);


=head2 clone

Clone state of our object into a newly created object which is returned.
Our object and returned object are identical at the time of cloning.

	my $ru1 = Statistics::Running->new();
	for(1..100){
		$ru1->add(rand());
	}
	my $ru2 = $ru1->clone();


=head2 clear

Clear our internal state as if no data points have ever been added into us.
As if we were just created. All state is forgotten and reset to zero, including histogram.


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


=head2 histogram_enable

Enables histogram logging by creating a histogram with specified
parameters. These parameters can be of different formats:

	my $ru1 = Statistics::Running->new();
	$ru1->histogram_enable({
		'num-bins' => 10,
		'bin-width' => 0.01,
		'left-boundary' => 0
	});
	# or, 2 bins: 0-1 and 1-2
	$ru1->histogram_enable({
		'0:1' => 0,
		'1:2' => 1,
	});
	# or, 2 bins: 0-1 and 1-2
	$ru1->histogram_enable([0,1,2]);


=over 3

=item 1. by specifying the number of bins, bin-width and left boundary as a
parameters hash, e.g. C< $ru->enable_histogram({'num-bins'=>5, 'bin-width'=>1, 'left-boundary'=>-2}); >

=item 2. by specifying a HASH where keys are 'FROM:TO' and values are the bin counts,
which can be zero, or even a positive integer if you want to start with some counts already.

=item 3. ARRAY of bin boundaries of the form
  C< [histo-left-boundary, bin1_right_boundary, bin2_right_boundary, ... binN-1_right_boundary, histo-right-boundary] >
It follows that the number of bins will be 1 less than the length of this array.

=back

=head2 histogram_disable

Disable histogram logging, all existing histogram data is erased. Number of bins
is forgotten, along with bin boundaries, etc.


=head2 histogram_reset

Set existing histogram to zero counts.


=head2 histogram_count 

Returns the count in bin specified by bin index (which is 0 to number-of-bins - 1)


=head2 equals

Check if our state (number of samples and all internal state) is
the same with input object's state. Equality here implies that
ALL statistics are equal (within a small number Statistics::Running::SMALL_NUMBER_FOR_EQUALITY)


=head2 equals_statistics

Check if our statistics only (and not sample size)
are the same with input object. E.g. it checks mean, variance etc.
but not sample size (as with the real equals()).
It returns 0 on non-equality. 1 if equal.


=head2 equals_histograms

Check if our histogram only (and not statitstics)
are the same with input object.
It returns 0 on non-equality. 1 if equal.


=head2 stringify

Returns a string description of descriptive statistics we know about
(mean, standard deviation, kurtosis, skewness) as well as the
number of data points/samples added onto us so far. Note that
this method is not necessary because stringification is overloaded
and the follow C< print $stats_obj."\n" > is equivalent to
C< print $stats_obj->stringify()."\n" >


=head1 Overloaded functionality

=over 3

=item 1. Addition of two statistics objects: C< my $ru3 = $ru1 + $ru2 >

=item 2. Test for equality: C< if( $ru2 == $ru3 ){ ... } >

=item 3. Stringification: C< print $ru1."\n" >

=back


=head1 Testing for Equality

In testing if two objects are the same, their means, standard deviations
etc. are compared. This is done using
C< if( ($self->mean() - $other->mean()) < Statistics::Running::SMALL_NUMBER_FOR_EQUALITY ){ ... } >


=head1 BENCHMARKS

Run C< make bench > for benchmarks which report the maximum number of data points inserted
per second (in your system).


=head1 SEE ALSO

=over 4

=item 1. L<Wikipedia|http://en.wikipedia.org/wiki/Algorithms_for_calculating_variance#Online_algorithm>

=item 2. L<John D. Cook's article and C++ implementation|https://www.johndcook.com/blog/skewness_kurtosis>
was used both as inspiration and as the basis for the formulas for C< kurtosis() >
and C< skewness() >

=item 3. L<Statistics::Welford> This module is equivalent but it
does not provide C< kurtosis() > and C< skewness() > which
current module does. Additionally,
current module builds a Histogram for inserted data as a discrete
approximation of the Probability Distribution data comes from.

=item 4. L<Statistics::Running::Tiny> This is the exact same module but
without histogram capabilities. That makes it
a bit faster than current module only when data is inserted.
Space-wise, the histogram does not take much
space. It is just an array of bins and the number
of items (not the original data items themselves!) it contains.
Run C< make bench > to get a report on the maximum number
of data point insertions per unit time in your system.
L<Statistics::Running::Tiny> is approximately 25% faster than this module.

=back


=head1 AUTHOR

Andreas Hadjiprocopis, C<< <bliako at cpan.org> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-statistics-running at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Statistics-Running>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::Running


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-Running>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Statistics-Running>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Statistics-Running>

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

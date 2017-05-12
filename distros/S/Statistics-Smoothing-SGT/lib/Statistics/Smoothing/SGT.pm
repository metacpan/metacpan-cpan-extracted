=head1 NAME

Statistics::Smoothing::SGT - 	A Simple Good-Turing (SGT) smoothing implementation

=head1 SYNOPSIS

=head2 Basic Usage

  use Statistics::Smoothing::SGT
  my $sgt = new Statistics::Smoothing::SGT($frequencyClasses, $total);
  $sgt->calculateValues();
  $probabilities = $sgt->getProbabilities();
  $newFrequencies = $sgt->getNewFrequencies();
  $nBar = $sgt->getNBar();

=head1 AUTHORS

Florian Doemges, florian@doemges.net

Bjoern Wilmsmann, bjoern@wilmsmann.de

=head1 COPYRIGHT

Copyright (C) 2006, Florian Doemges and Bjoern Wilmsmann,
Department of Linguistics, Ruhr-University, Bochum

Partially based on the SGT module (Copyright (C) 2004) by Andre Halama
(halama@linguistics.rub.de) and Tibor Kiss (tibor@linguistics.rub.de),
Department of Linguistics, Ruhr-University, Bochum.

This module in turn was based on the work (including an implementation
of the algorithm in C) by
Geoffrey Sampson, Department of Informatics, University of Sussex.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to

    The Free Software Foundation, Inc.,
    59 Temple Place - Suite 330,
    Boston, MA  02111-1307, USA.

Note: a copy of the GNU General Public License is available on the web
at L<http://www.gnu.org/licenses/gpl.txt> and is included in this
distribution under the name GPL.

=head1 BUGS

=head1 SEE ALSO

=head1 DESCRIPTION

This Perl module implements the Simple Good Turing (SGT) algorithm 
for smoothing of probabilistic values developed by William Gale and 
Geoffrey Sampson.

The algorithm is described in detail in Sampson's Empirical Linguistics
(Continuum International, London and New York, 2001), chapter 7.
An online version of this paper is available at Geoffrey Sampson's
homepage under L<http://www.grsampson.net/AGtf.html>.

=head2 Error Codes

=head2 Methods

=over

=cut


package Statistics::Smoothing::SGT;

# use strict, as we do not our variables to go haywire
use strict;

# use these for debugging purposes
use warnings;
use Data::Dumper;

our ($VERSION);

$VERSION = '2.1.2';

# constructor
sub new {
	my ($class, $frequencyClasses, $ngramTotal) = @_;
	my $rowsFound = scalar(keys(%{$frequencyClasses}));
	unless ($rowsFound >=5) {
	    die("At least 5 m/V(m) pairs must be provided for SGT.\nThe hash contains only $rowsFound rows.\n");
	}
	my $self = {
		frequencyClasses => $frequencyClasses,
		ngramTotal => $ngramTotal
	};
	bless($self, $class);
	return $self;
}

# method for calculating all Z(m)
sub calculateZ() {
	my ($self) = @_;
	my @zValues;
	my @equivalenceClasses;
	my @cardinalities;
	
	# iterate over frequencies for conversion into ascendingly ordered list
	foreach my $frequency (sort {$a <=> $b} keys(%{$self->{frequencyClasses}})) {
		# push frequency to array of equivalence classes
		push(@equivalenceClasses, $frequency);

		# push cardinality of this frequency class to array of cardinalities at corresponding
		# position
		push(@cardinalities, $self->{frequencyClasses}->{$frequency});
	}
	
	# save arrays for processing in other functions
	$self->{equivalenceClasses} = \@equivalenceClasses;
	$self->{cardinalities} = \@cardinalities;
	
	# calculate z value for m = 1
	push(@zValues, 2 * $self->{cardinalities}->[0] / ($self->{equivalenceClasses}->[1]));
	
	# iterate over equivalence classes and their respective cardinalities
	# for calculating z values for all m > 1 and m < max
	for (my $i = 1; $i < @{$self->{equivalenceClasses}} - 1; $i++) {
		push(@zValues, 2 * $self->{cardinalities}->[$i] / ($self->{equivalenceClasses}->[$i + 1] - $self->{equivalenceClasses}->[$i - 1]));
	}

	# calculate z value for m = max
	push(@zValues, 2 * $self->{cardinalities}->[@{$self->{cardinalities}} - 1] / ($self->{equivalenceClasses}->[@{$self->{equivalenceClasses}} - 1] - $self->{equivalenceClasses}->[@{$self->{equivalenceClasses}} - 2]));

	# return
	return \@zValues;
}

# method for getting first gap between frequencies
sub getGap {
	my ($self) = @_;
	my $gapAt;
	my $buffer = 0;

	# iterate over equivalence classes
	for (my $i = 0; $i <= @{$self->{equivalenceClasses}}; $i++) {
		# check if gap between current value and previous
		# one is bigger than 1
		if (!defined $self->{equivalenceClasses}->[$i] || $buffer + 1 < $self->{equivalenceClasses}->[$i]) {
			# if so, we have found our gap and can skip the
			# remaining iterations
			$gapAt = $buffer;
			last;
		}

		# write current value to buffer for checking next value
		$buffer = $self->{equivalenceClasses}->[$i];
	}
	
	# return gap
	return $gapAt;
}

# method for deducing slope and intersection of a logarithmised
# exponential function with its best fitting linear function
# (i.e. linear regression)
sub logBestFit { 
	my ($self, $Xaxis, $Yaxis) = @_;
	my $XYs = 0;
	my $Xsquares = 0;
	my $meanX = 0;
	my $meanY = 0;
	my $rows = scalar @{$Xaxis};

	# calculate log mean values for x and y
	for (my $i = 0; $i < $rows; $i++) {
		$meanX += log($Xaxis->[$i]);
		$meanY += log($Yaxis->[$i]);
	}
	$meanX /= $rows;
	$meanY /= $rows;

	# calculate slope and intersection
	for (my $i = 0; $i < $rows; $i++) {
		$XYs += ((log($Xaxis->[$i]) - $meanX) * (log($Yaxis->[$i]) - $meanY));
		$Xsquares += (log($Xaxis->[$i]) - $meanX) ** 2;
	}
	my $slope = $XYs / $Xsquares;
	my $intersection = $meanY - $slope * $meanX;
	
	# return slope and intersection
	return ($slope, $intersection);
}

# public method for calculating SGT-smoothed values
sub calculateValues() {
	my ($self) = @_;
	my $gapAt;
	my $slope;
	my $intersection;
	my %xValues;
	my %yValues;
	my $zValues;
	my %mFound;
	my %mStar;
	my $newFrequencies;
	my $m;
	my $xFlag;
	my $diff;
	my $i;

	# get z values
	$zValues = $self->calculateZ();

	# get first frequency gap
	$gapAt = $self->getGap();

	# perform linear regression
	($slope, $intersection) = $self->logBestFit($self->{equivalenceClasses}, $zValues);
	
	# calculcate y function values
    for ($i = 0; $i <= $self->{equivalenceClasses}->[@{$self->{equivalenceClasses}} - 1]; $i++) {
		$yValues{$i} = ($i + 1) * exp($slope * (log($i + 2) - log($i + 1)));
    }

	# calculate x value only, if last element has not yet
	# been reached, x values for large classes do not matter
	# anyway
	for($i = 0; $i < @{$self->{equivalenceClasses}} - 2; $i++) {
		$xValues{$self->{equivalenceClasses}->[$i]} = $self->{equivalenceClasses}->[$i + 1] * $self->{cardinalities}->[$i + 1] / $self->{cardinalities}->[$i];
	}

	# build hash for all existing m (=equivalence class) and V(m) (= cardinality)
	for ($i = 0; $i < @{$self->{equivalenceClasses}}; $i++){
		$mFound{$self->{equivalenceClasses}->[$i]} = $self->{cardinalities}->[$i]; 
	}

	# iterate over equivalence classes in order to determine
	# which function to use
	for ($i = 1; $i <= $self->{equivalenceClasses}->[@{$self->{equivalenceClasses}} - 1]; $i++) {
		# check, if m (=equivalence class) and V(m) (= cardinality) exist for this index
		unless ($mFound{$i}) {
			next;
		}
		
		# if y function has not been used yet and first gap between frequencies
		# has not yet been reached
		if (!$xFlag && $i < $gapAt) {
			# calculate distance value between x and y function for which y
			# function is to be used
			$diff = (sqrt (($self->{equivalenceClasses}->[$i + 1] ** 2) *
					($self->{cardinalities}->[$i + 1] / $self->{cardinalities}->[$i] ** 2) *
					(1 + $self->{cardinalities}->[$i + 1] / $self->{cardinalities}->[$i]))) * 1.65;

			# if difference between x and y value is smaller than the difference
			# value calculated above
			if (abs($xValues{$i} - $yValues{$i}) < $diff) {
				# use y function from now on
				$mStar{$i} = $yValues{$i};
				$xFlag = 1;
			} else {
				# use x function
				$mStar{$i} = $xValues{$i};
			}
		} else {
			# use y function from now on
			$mStar{$i} = $yValues{$i};
			$xFlag = 1;
		}
		
		# calculate new total (i.e. nBar);
		$self->{nBar} += $mStar{$i} * $mFound{$i};
	}

	# save new frequencies
	$self->{newFrequencies} = \%mStar;

	# calculate the probability for unseen events (i.e. pZero)
	$self->{probabilities}->{0} = $self->{cardinalities}->[0] / $self->{ngramTotal};

	# calculate all other probabilities
	foreach $m (keys(%mStar)) {
		$self->{probabilities}->{$m} = (1 - $self->{probabilities}->{0}) * ($mStar{$m} / $self->{nBar});
	}
}

# public method for getting new frequencies
sub getNewFrequencies() {
	my ($self) = @_;

	# return equivalence classes
	return $self->{newFrequencies};
}

# public method for getting equivalence classes
sub getEquivalenceClasses() {
	my ($self) = @_;

	# return equivalence classes
	return $self->{equivalenceClasses};
}

# public method for getting probabilities
sub getProbabilities() {
	my ($self) = @_;

	# return probabilities
	return $self->{probabilities};
}

# public method for getting nBar
sub getNBar() {
	my ($self) = @_;

	# return nBar
	return $self->{nBar};
}

1;

__END__


package Statistics::SPC;

use strict;
use Carp;
use vars qw($VERSION);
$VERSION = "0.01";

=head1 NAME

Statistics::SPC - Calculations for Stastical Process Control

=head1 DESCRIPTION

Creates thresholds based on the variability of all data, # of samples not
meeting spec, and variablity within sample sets, all from training data.

Note: this is only accurate for data which is normally distributed when
the process is under control

Recommended usage: at least 15 sample sets, w/ sample size >=2 (5 is good)
This module is fudged to work for sample size 1, but it's a better idea
to use >= 2

Important: the closer the process your are monitoring to how you would
like it to be running (steady state), the better the calculated control
limits will be.

Example: we take 5 recordings of the CPU utilization at random intervals
over the course of a minute.  We do this for 15 minutes, keeping all
fifteen samples.  Using this will be able to tell whether or not 
CPU use is in steady state.

=head1 SYNOPSIS

 my $spc = new Statistics::SPC;
 $spc->n(5) # set the number of samples per set
 $spc->Uspec(.50); # CPU should not be above 50% utilization
 $spc->Lspec(.05); # CPU should not be below 5%
 	# (0 is boring in an example)
 
 # Now feed training data into our object
 $return = $spc->history($history); # "train the system";
 	# $history is ref to 2d array;
 	# $return > 1 means process not likely to
 	# meet the constraints of your specified
 	# upper and lower bounds
 
 # now check to see if the the latest sample of CPU util indicates
 	# CPU utilization was under control during the time of the sample
 
 $return = $spc->test($data); # check one sample of size n
 	# $return < 0 there is something wrong with your data
 	# $return == 0 the sample is "in control"
 	# $return > 0 there are $return problems with the sample set
 

=head2 Possible problems with a sample set

=head3 The range (max - min) is not what we predicted:

The range of the data ($self->R) greater than our calculated upper limit on
the intra-sample range ($self->UCLR);

The range of the data ($self->R) less than our calculated lower limit on the
intra-sample range ($self->LCLR);

=head3 The average of the sample is not what we predicited:

The average of the sample set ($self->Xbar) is greater than our calculated
upper limit ($self->UCLXbar)

The average of the sample set ($self->Xbar) is less than our calculated
upper limit ($self->LCLXbar)

=head3 The number of errors is not what we predicited:

The number of data that fall outside our specification (i.e. errors)
($self->p) is greater than our calculated upate limit ($self->UCLp)

The number of data that fall outside our specification (i.e. errors)
($self->p) is less than our calculated upate limit ($self->LCLp)

=cut
############################################################################
# Let the code begin                                                       
############################################################################

my @d2 = (undef, 1, 1.128, 1.693, 2.059, 2.326, 2.534, 2.704, 2.847,
2.97, 3.078, 3.173, 3.258, 3.336, 3.407, 3.472, 3.532, 3.588, 3.64,
3.689, 3.735, 3.778, 3.819, 3.858, 3.895, 3.931);

my @D3 = (undef, 0, 0, 0, 0, 0, 0, 0.076, 0.136, 0.184, 0.223, 0.256,
0.283, 0.307, 0.328, 0.347, 0.363, 0.378, 0.391, 0.404, 0.415, 0.425,
0.435, 0.443, 0.452, 0.459);

my @D4 = (undef, 4, 3.267, 2.575, 2.282, 2.114, 2.004, 1.924, 1.864,
1.816, 1.777, 1.744, 1.717, 1.693, 1.672, 1.653, 1.637, 1.622, 1.609,
1.596, 1.585, 1.575, 1.565, 1.557, 1.548, 1.541);

my $INFINITY = 999999999999999;

sub new {
	my $that = shift;
	my $self = {};
	
	$self->{n} = undef;
	$self->{Xbar} = undef;
	$self->{Xbarbar} = undef;
	$self->{Rbar} = undef;
	$self->{UCLXbar} = undef;
	$self->{LCLXbar} = undef;
	$self->{UCLR} = undef;
	$self->{LCLR} = undef;
	$self->{defects} = undef;
	$self->{p} = undef;
	$self->{pbar} = undef;
	$self->{Uspec} = undef;
	$self->{Lspec} = undef;

	bless($self);
	return($self);
}

sub history {
# calculate all of the necessary variables based on the
# historical "training" data
	my $self = shift;

	# get the history
	# could be from DB or whatever, and do not need to store, just
	# need to calculate over the "training" data, usu. 15+ samples

	# we'll force this to be a 2-d array, row: sample, col: sample set data
	my $history = shift;
	unless ( defined $history ) {
		warn "history not provided as input";
		return -1;
	}
	
	my $average;
	my $defects = 0;
	my $history_samples = $#{$history} + 1;
	my ($row, $column);
	my $sample;
	my $sum_defects;
	my $sum_average;
	my $row_range;

	for($row=0; $row < $history_samples; $row++) {
		my $min = $INFINITY;
		my $max = -1 * $INFINITY;
		for($column=0;$column<$self->n();$column++) {
			$sample = $history->[$row][$column];
			if ( ! defined $sample ) {
				warn "found an undefined sample value in provided history";
				return -1;
			}
			if ( $sample > $max ) {
				$max = $sample;
			}
			if ( $sample < $min ) {
				$min = $sample;
			}
			if ( $sample > $self->Uspec ) {
				$defects += 1;
			}
			if ( $sample < $self->Lspec ) {
				$defects += 1;
			}
			$average += $sample;
		}
		$sum_defects += $defects/$column;
		$defects = 0;
		$sum_average += $average/$column;
		$average = 0;
		$row_range += $max - $min;
	}
	$self->Xbarbar($sum_average/$history_samples);
	$self->Rbar($row_range/$history_samples);
	$self->pbar($sum_defects/$history_samples);
	$self->UCLXbar(
		$self->Xbarbar()+$self->Rbar()*3/($d2[$self->n()]*sqrt($self->n()))
	);
	$self->LCLXbar(
		$self->Xbarbar()-$self->Rbar()*3/($d2[$self->n()]*sqrt($self->n()))
	);
	$self->UCLR($D4[$self->n()] * $self->Rbar());
	$self->LCLR($D3[$self->n()] * $self->Rbar());
	$self->UCLp(
		$self->pbar()+3*sqrt($self->pbar()*(1-$self->pbar())/$self->n())
	);
	$self->LCLp(
		$self->pbar()-3*sqrt($self->pbar()*(1-$self->pbar())/$self->n())
	);

	if ( $self->UCLXbar() > $self->Uspec() ) {
		return 1;
	}
	if ( $self->LCLXbar() < $self->Lspec() ) {
		return 1;
	}
	
	return 0;
}

sub Rbar {
	my $self = shift;
	my $n = shift;
	return $self->{Rbar} unless defined($n);
	$self->{Rbar} = $n;
	return $n;
}

sub Xbarbar {
	my $self = shift;
	my $n = shift;
	return $self->{Xbarbar} unless defined($n);
	$self->{Xbarbar} = $n;
	return $n;
}

sub defects {
	my $self = shift;
	my $n = shift;
	return $self->{defects} unless defined($n);
	$self->{defects} = $n;
	return $n;
}

sub pbar {
	my $self = shift;
	my $n = shift;
	return $self->{pbar} unless defined($n);
	$self->{pbar} = $n;
	return $n;
}

sub p {
	my $self = shift;
	my $n = shift;
	return $self->{p} unless defined($n);
	$self->{p} = $n;
	return $n;
}

sub UCLpbar {
	my $self = shift;
	my $n = shift;
	return $self->{UCLpbar} unless defined($n);
	$self->{UCLpbar} = $n;
	return $n;
}

sub LCLpbar {
	my $self = shift;
	my $n = shift;
	return $self->{LCLpbar} unless defined($n);
	$self->{LCLpbar} = $n;
	return $n;
}

sub UCLp {
	my $self = shift;
	my $n = shift;
	return $self->{UCLp} unless defined($n);
	$self->{UCLp} = $n;
	return $n;
}

sub LCLp {
	my $self = shift;
	my $n = shift;
	return $self->{LCLp} unless defined($n);
	$self->{LCLp} = $n;
	return $n;
}

sub LCLXbar {
	my $self = shift;
	my $n = shift;
	return $self->{LCLXbar} unless defined($n);
	$self->{LCLXbar} = $n;
	return $n;
}

sub UCLXbar {
	my $self = shift;
	my $n = shift;
	return $self->{UCLXbar} unless defined($n);
	$self->{UCLXbar} = $n;
	return $n;
}

sub Xbar {
	my $self = shift;
	my $n = shift;
	return $self->{Xbar} unless defined($n);
	$self->{Xbar} = $n;
	return $n;
}

sub LCLR {
	my $self = shift;
	my $n = shift;
	return $self->{LCLR} unless (defined $n);
	$self->{LCLR} = $n;
	return $n;
}

sub UCLR {
	my $self = shift;
	my $n = shift;
	return $self->{UCLR} unless defined($n);
	$self->{UCLR} = $n;
	return $n;
}

sub R {
	my $self = shift;
	my $n = shift;
	return $self->{R} unless defined($n);
	$self->{R} = $n;
	return $n;
}

sub n {
	my $self = shift;
	my $n = shift;
	return $self->{n} unless defined($n);
	$self->{n} = $n;
	return $n;
}

sub Uspec {
	my $self = shift;
	my $n = shift;
	return $self->{Uspec} unless defined($n);
	$self->{Uspec} = $n;
	return $n;
}

sub Lspec {
	my $self = shift;
	my $n = shift;
	return $self->{Lspec} unless defined($n);
	$self->{Lspec} = $n;
	return $n;
}

sub test {
	my $self = shift;
	my $data = shift;
	my @data;
	push @data, @{$data};

	if ( ($#data+1) != $self->n ) {
		# not the right number of sample size
		warn "number of samples does not match 'n'";
		return -1;
	}

	my $min = $INFINITY;
	my $max = -1 * $INFINITY;
	my $defects = 0;
	my $sum = 0;
 
	for (my $i=0; $i < $self->n; $i++ ) {
		if ( $data[$i] > $max ) {
			$max = $data[$i];
		}
		if ( $data[$i] < $min ) {
			$min = $data[$i];
		}
		if ( $data[$i] < $self->Lspec ) {
			$defects += 1;
		}	
		if ( $data[$i] > $self->Uspec ) {
			$defects += 1;
		}	
		$sum += $data[$i];
	}
	$self->R($max - $min);
	$self->Xbar($sum/$self->n);
	$self->defects($defects);
	$self->p($defects/$self->n);

	my $return = 0;
	if ( $self->R > $self->UCLR ) {
		$return += 1;
	}
	if ( $self->R < $self->LCLR ) {
		$return += 1;
	}
	
	if ( $self->Xbar > $self->UCLXbar ) {
		$return += 1;
	}
	if ( $self->Xbar < $self->LCLXbar ) {
		$return += 1;
	}

	if ( $self->p() > $self->UCLp() ) {
		$return += 1;
	}
	if ( $self->p() < $self->LCLp() ) {
		$return += 1;
	}

	return $return;
}

1;

=head1 AUTHOR

Erich S. Morisse <emorisse@cpan.org>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2007 Erich Morisse

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
USA.

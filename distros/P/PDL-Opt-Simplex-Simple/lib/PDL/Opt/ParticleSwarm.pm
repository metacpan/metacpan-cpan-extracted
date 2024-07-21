#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU Library General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
#  This is a port of AI::ParticleSwarmOptimization by Peter Jaquiery to use
#  PDL.  
#
#  For PDL-port and related changes: 
#    Copyright (C) 2023- eWheeler, Inc. L<https://www.linuxglobal.com/>
#
#  All rights reserved.
#
#  All tradmarks, product names, logos, and brands are property of their
#  respective owners and no grant or license is provided thereof.

package PDL::Opt::ParticleSwarm;

use strict;
use warnings;

use PDL;

require Exporter;

our @ISA    = qw(Exporter);
our @EXPORT = qw(kLogBetter kLogStall kLogIter);

use constant kLogBetter => 1;
use constant kLogStall  => 2;
use constant kLogIter   => 4;

sub new
{
	my ($class, %params) = @_;
	my $self = bless {}, $class;

	$self->setParams(%params);
	return $self;
}

sub setParams
{
	my ($self, %params) = @_;

	my %valid_params = map { $_ => 1 } qw/
		fitFunc
		logFunc

		dimensions
		initialGuess

		numParticles
		numNeighbors
		iterations

		posMax
		posMin

		searchSize

		stallSpeed
		stallSearchScale

		meWeight
		themWeight
		inertia

		exitFit
		exitPlateau
		exitPlateauBurnin
		exitPlateauDP
		exitPlateauWindow

		randStartVelocity

		verbose
		/;

	foreach my $p (map { s/^-//; $_ } keys(%params))
	{
		die "invalid parameter: $p" if !$valid_params{$p};
	}

	if (defined $params{-fitFunc})
	{
		# Process required parameters - -fitFunc and -dimensions
		if ('ARRAY' eq ref $params{-fitFunc})
		{
			($self->{fitFunc}, @{ $self->{fitParams} }) = @{ $params{-fitFunc} };
		}
		else
		{
			$self->{fitFunc} = $params{-fitFunc};
		}

		$self->{fitParams} ||= [];
	}

	if (defined $params{-logFunc})
	{
		$self->{logFunc} = $params{-logFunc};
	}

	die 'logFunc is not a coderef'
		if defined($self->{logFunc}) && ref($self->{logFunc}) ne 'CODE';

	$self->{prtcls} = undef    # Need to reinit if num dimensions changed
		if defined $params{-dimensions}
			and defined $self->{dimensions}
			and $params{-dimensions} != $self->{dimensions};

	$self->{$_} = $params{"-$_"} for (grep { exists $params{"-$_"} } keys(%valid_params));
	if (defined($self->{initialGuess}) && ref($self->{initialGuess}) !~ /^PDL(:|$)/)
	{
		die "-initialGuess must be a PDL reference";
	}

	if (!defined($self->{dimensions}) && !defined($self->{initialGuess}))
	{
		die "you must define either -dimensions or -initialGuess";
	}
	elsif (    defined($self->{dimensions})
		&& defined($self->{initialGuess})
		&& $self->{initialGuess}->getdim(-1) != $self->{dimensions})
	{
		warn "-dimensions does not match -initialGuess; using "
			. $self->{initialGuess}->getdim(-1);
	}

	if (defined($self->{initialGuess}))
	{
		$self->{dimensions} = $self->{initialGuess}->getdim(-1);
	}

	die "-dimensions must be greater than 0\n"
		if exists $self->{dimensions} && $self->{dimensions} <= 0;

	if (defined $self->{verbose} and 'ARRAY' eq ref $self->{verbose})
	{
		my @log = map { lc } @{ $self->{verbose} };
		my %logTypes = (
			better => kLogBetter,
			stall  => kLogStall,
			iter   => kLogIter,
			);

		$self->{verbose} = 0;
		exists $logTypes{$_} and $self->{verbose} |= $logTypes{$_} for @log;
	}

	$self->{numParticles} ||= $self->{dimensions} * 10       if defined $self->{dimensions};
	$self->{numNeighbors} ||= int sqrt $self->{numParticles} if defined $self->{numParticles};
	$self->{numNeighbors} = $self->{numParticles} - 1 if ($self->{numNeighbors} >= $self->{numParticles});

	$self->{iterations}   ||= 1000;
	$self->{exitPlateauDP}     ||= 10;
	$self->{exitPlateauWindow} ||= $self->{iterations} * 0.1;
	$self->{exitPlateauBurnin} ||= $self->{iterations} * 0.5;
	$self->{posMax} = 100 unless defined $self->{posMax};
	$self->{posMin} = -$self->{posMax} unless defined $self->{posMin};
	$self->{meWeight}   ||= 0.5;
	$self->{themWeight} ||= 0.5;
	$self->{inertia}    ||= 0.9;
	$self->{verbose}    ||= 0;
	$self->{stallSpeed} ||= 1e-9;
	$self->{stallSearchScale} ||= 1;

	$self->{posMin} = pdl([$self->{posMin}]) if (ref($self->{posMin}) !~ /^PDL(:|$)/);
	$self->{posMax} = pdl([$self->{posMax}]) if (ref($self->{posMax}) !~ /^PDL(:|$)/);

	return 1;
}

sub init
{
	my ($self) = @_;

	die "-fitFunc must be set before init or optimize is called"
		unless $self->{fitFunc} and 'CODE' eq ref $self->{fitFunc};

	die "-dimensions must be set to 1 or greater before init or optimize is called"
		unless $self->{dimensions} and $self->{dimensions} >= 1;

	$self->{prtcls} = undef;

	$self->{bestBest}       = undef;
	$self->{bestBestByIter} = undef;
	$self->{bestsMean}      = 0;

	$self->{deltaMax} = ($self->{posMax} - $self->{posMin}) / 100.0;

	$self->{iterCount} = 0;

	# Normalise weights.
	my $totalWeight =
		$self->{inertia} + $self->{themWeight} + $self->{meWeight};

	$self->{inertia}    /= $totalWeight;
	$self->{meWeight}   /= $totalWeight;
	$self->{themWeight} /= $totalWeight;

	die "-posMax must be greater than -posMin"
		unless all($self->{posMax} > $self->{posMin});
	$self->{$_} > 0 or die "-$_ must be greater then 0" for qw/numParticles/;

	$self->{_seq_numNeighbors} = sequence($self->{numNeighbors});
	$self->{_seq_numParticles} = sequence($self->{numParticles});

	$self->_initParticles();
	return 1;
}

sub optimize
{
	my ($self, $iterations) = @_;

	$iterations ||= $self->{iterations};
	$self->init() unless $self->{prtcls};
	return $self->_swarm($iterations);
}

sub getIterationCount
{
	my ($self) = @_;

	return $self->{iterCount};
}

sub _initParticles
{
	my ($self, $mask) = @_;

	$self->{prtcls} //= {
		bestPos => zeroes($self->{dimensions}, $self->{numParticles}),
		currPos => zeroes($self->{dimensions}, $self->{numParticles}),
		nextPos => zeroes($self->{dimensions}, $self->{numParticles}),

		bestFit => zeroes(1, $self->{numParticles}) + inf,
		currFit => zeroes(1, $self->{numParticles}) + inf,
		nextFit => zeroes(1, $self->{numParticles}) + inf,

		# Count the number of stalls a particle has experienced.
		# Start at -1 because it gets incremented below.
		stalls => zeroes(1, $self->{numParticles}) -1,

		velocity => zeroes($self->{dimensions}, $self->{numParticles}),

		};

	$mask //= ones($self->{numParticles});
	$mask = $mask->clump(-1);

	# Create piddle slices for each key from the {prtcls} hash (ie, bestPos,
	# velocity, ...) that match $mask.  In the default case, all particles will
	# be calculated.  However if $mask is passed, then only those matching the
	# mask will be calculated.
	my $prtcls = {
		map { $_ => $self->{prtcls}->{$_}->transpose->whereND($mask)->transpose }
			keys(%{ $self->{prtcls} })
			};

	my $numParticles = $prtcls->{bestPos}->getdim(-1);

	# sanity check:
	if ($mask->sum != $numParticles)
	{
		printf "mask size != particles size: mask=$mask, numParticles=$numParticles";
		#_printPrtcls($prtcls);
		die;
	}

	if (defined($self->{initialGuess}))
	{
		$prtcls->{bestPos} .= $self->{initialGuess};
	}
	else
	{
		$prtcls->{bestPos} .=
			$self->_randInRangePDL($self->{posMin}, $self->{posMax},
				$self->{dimensions}, $numParticles);
	}

	# This function is called on init or on stall, so always increment stalls:
	$prtcls->{stalls} += 1;
	if (defined($self->{searchSize}))
	{
		my $guess;
		if (defined($self->{initialGuess}) && $self->{iterCount} == 0)
		{
			# Use the initial guess only initially (iterCount==0)
			$guess = $self->{initialGuess};
		}
		else
		{
			$guess = $prtcls->{bestPos};
		}

		my $searchSize = $self->{searchSize} * ($self->{stallSearchScale}**$prtcls->{stalls});

		# Search $guess +/- (searchSize% of the search range from posMin to posMax:
		$prtcls->{currPos} .= $guess +
			$searchSize *
				($self->{posMax} - $self->{posMin}) *
					(1 - 2*random($self->{dimensions}, $numParticles));
	}
	else
	{
		$prtcls->{currPos} .=
			$self->_randInRangePDL($self->{posMin}, $self->{posMax},
				$self->{dimensions}, $numParticles);
	}

	if ($self->{randStartVelocity})
	{
		$prtcls->{velocity} .= $self->_randInRangePDL(
			-$self->{deltaMax},  $self->{deltaMax},
			$self->{dimensions}, $numParticles
			);
	}
	else
	{
		$prtcls->{velocity} .= zeroes($self->{dimensions}, $numParticles);
	}

	$prtcls->{currFit} .= $self->_calcPosFit($prtcls->{currPos});
	$self->_calcNextPos($prtcls);
	$prtcls->{bestFit} .= $self->_calcPosFit($prtcls->{bestPos});


	# Now that bestFit has been calculated, store these as bestBest if no
	# previous best has yet been calculated.  This is intended to happen
	# only on the first call to _initParticles() when {initialGuess} is
	# defined.
	if (defined($self->{initialGuess}))
	{
		$self->{bestBest}    //= $prtcls->{bestFit}->slice(':', 0)->clump(-1)->sclr;
		$self->{bestBestPos} //= $prtcls->{bestPos}->slice(':', 0)->copy;
	}

	return $prtcls;
}

sub _calcPosFit
{
	my ($self, $pos) = @_;

	# We have to transpose here because functions return a vector
	# for each particle, but internally we need a (1,N) piddle for
	# fitness values:
	my $fit = $self->{fitFunc}->(@{ $self->{fitParams} }, $pos)->transpose;

	# Convert any NaN's to infinity so the optimizer knows they are a poor
	# solution.  It will then continue to try and find a lower fitness
	# value.
	return $fit->setnantobad()->setbadtoval(inf);
}

sub _swarm
{
	my ($self, $iterations) = @_;

	for my $iter (1 .. $iterations)
	{
		++$self->{iterCount};
		last if defined $self->_moveParticles($iter);

		$self->_updateVelocities($iter);

		if (defined($self->{logFunc}))
		{
			$self->{logFunc}->($self->getBestPos(), $self->getBestFit());
		}

		next if !$self->{exitPlateau} || !defined $self->{bestBest};

		if ($iter >= $self->{exitPlateauBurnin} - $self->{exitPlateauWindow})
		{
			my $i = $iter % $self->{exitPlateauWindow};

			if (defined $self->{bestBestByIter}[$i])
			{
				$self->{bestsMean} -= $self->{bestBestByIter}[$i];
			}

			$self->{bestBestByIter}[$i] =
				$self->{bestBest} / $self->{exitPlateauWindow};

			$self->{bestsMean} += $self->{bestBestByIter}[$i];
		}

		next if $iter <= $self->{exitPlateauBurnin};

		#Round to the specified number of d.p.
		my $format  = "%.$self->{exitPlateauDP}f";
		my $mean    = sprintf $format, $self->{bestsMean};
		my $current = sprintf $format, $self->{bestBest};

		#Check if there is a sufficient plateau - stopping iterations if so
		last if $mean == $current;
	}

	return $self->getBestFit();
}

sub _moveParticles
{
	my ($self, $iter) = @_;

	print "Iter $iter\n" if $self->{verbose} & kLogIter;

	my $prtcls = $self->{prtcls};

	$prtcls->{currPos} .= $prtcls->{nextPos};
	$prtcls->{currFit} .= $prtcls->{nextFit};

	# might be able to refactor this without the loop using a mask:
	for (my $i = 0 ; $i < $self->{numParticles} ; $i++)
	{
		my $fit = $prtcls->{currFit}->slice(0,   $i);
		my $sfit = $fit->sclr;

		my $bestfit = $prtcls->{bestFit}->slice(0,   $i);
		my $sbestfit = $bestfit->sclr;

		if ($sfit < $sbestfit)
		{
			my $bestpos = $prtcls->{bestPos}->slice(':', $i);
			my $pos = $prtcls->{currPos}->slice(':', $i);

			$bestpos .= $pos;
			$bestfit .= $fit;

			if ($self->{verbose} & kLogBetter)
			{
				my $v = $prtcls->{velocity}->slice(':', $i);
				my $vmag = sqrt(sum($v**2));
				printf "#%05d: Particle $i best: %.4f (v: %.5f)\n",
					$iter, $fit->sclr, $vmag->sclr;
			}

			if (!defined($self->{bestBest}) || $sfit < $self->{bestBest})
			{
				# bestBest doesn't need to be scalar, but it performs
				# better since it is a 1,1-piddle that needs evaluated.
				$self->{bestBest}    = $fit->sclr;

				# However, this does need to be a piddle.  Copy for safety:
				$self->{bestBestPos} = $pos->copy;
			}

		}

		return $fit if defined $self->{exitFit} and $sfit < $self->{exitFit};

		if ($self->{verbose} & kLogIter)
		{
			my $v = $prtcls->{velocity}->slice(':', $i);
			my $vmag = sqrt(sum($v**2))->sclr;
			my $pos = $prtcls->{currPos}->slice(':', $i);
			printf "Part %3d fit %15.2f (vmag=%8.6f pos=%s)\n", $i, $fit->sclr,
				$vmag, $pos->clump(-1);
		}
	}

	return undef;
}

sub _updateVelocities
{
	my ($self, $iter) = @_;

	my $prtcls = $self->{prtcls};

	# Build a D,P piddle where each row represents the Nth particle's
	# neighbor's positions that have the best fit according to _getBestNeighbour:
	my $bestNeighbors = zeroes($self->{dimensions}, $self->{numParticles});

	for (my $i = 0 ; $i < $self->{numParticles} ; $i++)
	{
		my $bestNeighIdx = $self->_getBestNeighbour($i);
		$bestNeighbors->slice(':', $i) .= $prtcls->{bestPos}->slice(':', $bestNeighIdx);
	}

	# meFactor/themFactor need to be (N,1) piddles because they are scaled
	# against each particle:
	my $meFactor = $self->_randInRangePDL(-$self->{meWeight}, $self->{meWeight}, $self->{dimensions}, 1);

	my $themFactor = $self->_randInRangePDL(-$self->{themWeight}, $self->{themWeight}, $self->{dimensions}, 1);

	my $meDelta   = $prtcls->{bestPos} - $prtcls->{currPos};
	my $themDelta = $bestNeighbors - $prtcls->{currPos};

	$prtcls->{velocity} .=
		$prtcls->{velocity} * $self->{inertia} +
		$meFactor * $meDelta +
		$themFactor * $themDelta;

	my $vel     = sqrt(sumover($prtcls->{velocity}**2));
	my $stalled = ($vel < $self->{stallSpeed});

	if (any $stalled)
	{
		$stalled = $stalled->clump(-1);

		if ($self->{verbose} & kLogStall)
		{
			my $stall_count = $prtcls->{stalls}->clump(-1);
			my $searchSize = $self->{searchSize} * ($self->{stallSearchScale}**$prtcls->{stalls});
			$searchSize = $searchSize->clump(-1);

			printf "#%05d: Particles stalled: %s count=%s searchSize=%s v=%s\n",
				$iter,
				$stalled * $self->{_seq_numParticles},
				$stalled * $stall_count,
				$stalled * $searchSize,
				$vel * $stalled;
		}

		$self->_initParticles($stalled);
	}

	$self->_calcNextPos($prtcls);
}

# Optionally calculate next positions for a subset of particles ($prtcls)
sub _calcNextPos
{
	my ($self, $prtcls) = @_;

	$prtcls //= $self->{prtcls};

	$prtcls->{nextPos} .= $prtcls->{currPos} + $prtcls->{velocity};

	# Set velocity to 0 if nextPos is out of bounds:
	my $velocity_mask =
		!($prtcls->{nextPos} < $self->{posMin}) | ($prtcls->{nextPos} > $self->{posMax});
	$prtcls->{velocity} *= $velocity_mask;

	# Clip nextPos to its bounds:
	$prtcls->{nextPos} .= $prtcls->{nextPos}->clip($self->{posMin}, $self->{posMax});

	$prtcls->{nextFit} .= $self->_calcPosFit($prtcls->{nextPos});
}

sub _randInRangePDL
{
	my ($self, $min, $max, @dims) = @_;

	return $min + ($max - $min) * random(@dims);
}

sub _getBestNeighbour
{
	my ($self, $me) = @_;

	# take the best fits and select a numNeighbors chunks
	# that is offset by $me.
	my $bestfits = $self->{prtcls}{bestFit}->clump(-1);
	$bestfits = $bestfits->index(
		($self->{_seq_numNeighbors} + ($me+1)) % $self->{numParticles});

	# Find it's minimum index and re-work the original index to return the
	# index into $self->{prtcls}{bestFit}:
	my $small_idx = minimum_ind($bestfits)->sclr;
	my $orig_idx  = ($small_idx + $me + 1) % $self->{numParticles};

	return $orig_idx;
}

sub getBestPos
{
	my $self = shift;

	if (!defined($self->{bestBestPos}))
	{
		my $min = minimum_ind($self->{prtcls}->{bestFit}->clump(-1));
		return $self->{prtcls}->{bestPos}->slice(':', $min);
	}

	return $self->{bestBestPos};
}

sub getBestFit
{
	my $self = shift;

	if (!defined($self->{bestBest}))
	{
		my $min = minimum_ind($self->{prtcls}->{bestFit}->clump(-1));
		return $self->{prtcls}->{bestFit}->slice(':', $min)->clump(-1);
	}

	# Internally this is scalar for faster comparison,
	# but externally the caller expects a piddle:
	return pdl $self->{bestBest};
}

sub getStallCount
{
	my $self = shift;
	return $self->{prtcls}->{stalls};
}

# For debugging, but requires Data::Dumper which we are not marking as a
# dependency.  Still it shouldn't be necessary as a dep because (I think) it is
# in the standard perl distribution.
sub _printPrtcls
{
	require Data::Dumper;

	my $p = shift;
	print ref($p) . "\n";
	if (ref($p) eq 'ARRAY')
	{
		return [ map { _printPrtcls($_) } @$p ];
	}
	elsif (ref($p) eq 'CODE')
	{
		return "CODE";
	}
	elsif (ref($p) eq 'HASH' || ref($p) eq __PACKAGE__)
	{
		print "==== " . Data::Dumper::Dumper(
			{
				map {
					$_ => ref($p->{$_}) eq 'PDL'
						? "$p->{$_}"
						: (ref($p->{$_}) ? _printPrtcls($p->{$_}) : $p->{$_})
				} keys(%{$p})
			}
			);
	}
	else
	{
		print "unknown ref: " . ref($p) . "\n";
	}

}

1;

__END__

=head1 NAME

PDL::Opt::ParticleSwarm - Particle Swarm Optimization (object oriented)

=head1 SYNOPSIS

    use PDL::Opt::ParticleSwarm;

    my $pso = PDL::Opt::ParticleSwarm->new (
        -fitFunc    => \&calcFit,
        -dimensions => 1,
        );

    my $bestFit        = $pso->optimize();
    my $bestPos        = $pso->getBestPos();

    print "Fit $bestFit at $bestPos\n";

    sub calcFit {
        my $vec = shift;
        my $x = $vec->slice('(0)');

        # The parabola (x+3)^2 - 5 has a minima at x=-3:
        return (($x+3)**2 - 5);
    }

=head1 Description

The Particle Swarm Optimization technique uses communication of the current best
position found between a number of particles moving over a hyper surface as a
technique for locating the best location on the surface (where 'best' is the
minimum of some fitness function). For a Wikipedia discussion of PSO see
L<http://en.wikipedia.org/wiki/Particle_swarm_optimization>.

This pure Perl module is an implementation of the Particle Swarm Optimization
technique for finding minima of hyper surfaces using the L<PDL> module for
accelerated vector calculations. It presents an object oriented interface that
facilitates easy configuration of the optimization parameters and (in
principle) allows the creation of derived classes to reimplement all aspects of
the optimization engine (a future version will describe the replaceable engine
components).

This implementation allows communication of a local best point between a
selected number of neighbours.

This module and its documentation is based on L<AI::ParticleSwarmOptimization>
by Peter Jaquiery to support PDL objects and additional features such as search
space scaling and initial guess options.

=head1 Methods

PDL::Opt::ParticleSwarm provides the following public methods. The parameter lists shown
for the methods denote optional parameters by showing them in [].

=over 4

=item new(%parameters)

Create an optimization object. The following parameters may be used:

=over 4

=item I<-initialGuess>: a vector of initial "best" values to start with.

This must be a PDL object.  As long as it is correctly broadcasts, this
can take any PDL representation.

=item I<-searchSize>: a scalar multiple to control the search distance from C<-initialGuess>

For example, if your C<initialGuess> is "5", C<posMin>/C<posMax> range is 0-10,
and C<searchSize> is 0.5 then it will initialize the particles to search in the
region between 2.5 and 7.5.

If undefined, then search the entire space between C<posMin> and C<posMax>

Default value: undef

=item I<-dimensions>: positive number, semi-required

The number of dimensions of the hypersurface being searched. This can be
omitted if C<-intitialGuess> is provided.

=item I<-exitFit>: number, optional

If provided, I<-exitFit> allows early termination of optimize if the
fitness value becomes equal or less than I<-exitFit>.

=item I<-fitFunc>: required

I<-fitFunc> is a reference to the fitness function used by the search. If extra
parameters need to be passed to the fitness function an array ref may be used
with the code ref as the first array element and parameters to be passed into
the fitness function as following elements. User provided parameters are passed
as the first parameters to the fitness function when it is called:

    my $pso = PDL::Opt::ParticleSwarm->new (
		fitFunc    => [\&calcFit, $context],
		dimensions => 3,
        );

    ...

    sub calcFit {
        my ($context, $pdl_vec_to_optimize) = @_;
		... do something with $pdl_vec_to_optimize
		return $fitness;
        }

In addition to any user provided parameters the list of values representing the
current particle position in the hyperspace is passed in. There is one value per
hyperspace dimension.

=item I<-logFunc>: log function callback, optional

This function is called after each iteration with the current C<bestPos> and
C<bestFit> values as follows:

	$self->{logFunc}->($self->getBestPos(), $self->getBestFit());

=item I<-inertia>: positive or zero number, optional

Determines what proportion of the previous velocity is carried forward to the
next iteration.  This can be a PDL object, so it should work in any dimension
so long as it works in the broadcast sense.

Defaults to 0.9

See also I<-meWeight> and I<-themWeight>.

=item I<-iterations>: number, optional

Number of optimization iterations to perform. Defaults to 1000.

=item I<-meWeight>: number, optional

Coefficient determining the influence of the current local best position on the
next iterations velocity.  This can be a PDL object, so it should work in any dimension
so long as it works in the broadcast sense.

Defaults to 0.5.

See also I<-inertia> and I<-themWeight>.

=item I<-numNeighbors>: positive number, optional

Number of local particles considered to be part of the neighbourhood of the
current particle.

Defaults to the square root of the total number of particles.

Background: "The basic version of the algorithm uses the global topology as
the swarm communication structure [when (numNeighbors=numParticles-1)]. This
topology allows all particles to communicate with all the other particles, thus
the whole swarm share the same best position from a single particle. However,
this approach might lead the swarm to be trapped into a local minimum."
[ L<https://en.wikipedia.org/wiki/Particle_swarm_optimization> ]

Thus, as C<numNeighbors> approaches C<numParticles-1>, there is a greater risk
of getting stuck in a local minima.

The neighbor selection algorithm in
L<PDL::Opt::ParticleSwarm> uses C<numNeighbors> particles following the Nth
particle index in the particle piddle being evaluated for its neighbors. The
term "neighbor" is perhaps a misnomer in the sense that it is not a vector
distance, but an index distance.

Future work could include adding other neighbor selection algorithms (ie,
random, vector distance, ring, others).

=item I<-numParticles>: positive number, optional

Number of particles in the swarm. Defaults to 10 times the number of dimensions.

=item I<-posMax>: number, optional

Maximum coordinate value for any dimension in the hyper space. This can be a
PDL object, so it should work in any dimension so long as it works in the
broadcast sense.  For example, different dimensions could have different posMax
values by passing a vector of length C<dimension>.

Defaults to 100.

=item I<-posMin>: number, optional

Minimum coordinate value for any dimension in the hyper space. This can be a
PDL object, so it should work in any dimension so long as it works in the
broadcast sense. For example, different dimensions could have different posMax
values by passing a vector of length C<dimension>.

Defaults to -I<-posMax> (if I<-posMax> is negative I<-posMin> should be set
more negative).

=item I<-randStartVelocity>: boolean, optional

Set true to initialize particles with a random velocity. Otherwise particle
velocity is set to 0 on initalization.

A range based on 1/100th of -I<-posMax> - I<-posMin> is used for the initial
speed in each dimension of the velocity vector if a random start velocity is
used.

=item I<-stallSpeed>: positive number, optional

Speed below which a particle is considered to be stalled and is repositioned to
a new random location with a new initial speed.  This can be a PDL object, so
it should work in any dimension so long as it works in the broadcast sense.

By default I<-stallSpeed> is undefined but particles with a speed of 1e-9 will be
repositioned.

=item I<-stallSearchScale>: positive number, optional

If a particle stalls, then jump to a random location that exists +/-
C<searchSize%> of the current location, but increase C<searchSize%>
for that particle by C<stallSearchScale> after each stall:

	$searchSize = $searchSize * ($stallSearchScale ** $numStalls)

Default: 1 (does not change C<searchSize>).

A recommended value is that which will slightly increase C<searchSize>
over time.  For example, if C<stallSearchScale = 1.1> and C<searchSize =
0.5> then C<searchSize> will change for that particle as follows:

	Stalls                  searchSize
	------                  ----------
	  0                        0.5        # initial configured value
	  1                        0.55
	  2                        0.605
	  3                        0.6655
	  5                        0.8053
	  7                        0.9744

In this example, C<searchSize> will be capped at a value of 1.0
after the particle stalls 8 times.

See also: I<-searchSize>

=item I<-themWeight>: number, optional

Coefficient determining the influence of the neighbourhod best position on the
next iterations velocity. This can be a PDL object, so it should work in any dimension
so long as it works in the broadcast sense.

Defaults to 0.5.

See also I<-inertia> and I<-meWeight>.

=item I<-exitPlateau>: boolean, optional

Set true to have the optimization check for plateaus (regions where the fit
hasn't improved much for a while) during the search. The optimization ends when
a suitable plateau is detected following the burn in period.

Defaults to undefined (option disabled).

=item I<-exitPlateauDP>: number, optional

Specify the number of decimal places to compare between the current fitness
function value and the mean of the previous I<-exitPlateauWindow> values.

Defaults to 10.

=item I<-exitPlateauWindow>: number, optional

Specify the size of the window used to calculate the mean for comparison to
the current output of the fitness function.  Correlates to the minimum size of a
plateau needed to end the optimization.

Defaults to 10% of the number of iterations (I<-iterations>).

=item I<-exitPlateauBurnin>: number, optional

Determines how many iterations to run before checking for plateaus.

Defaults to 50% of the number of iterations (I<-iterations>).

=item I<-verbose>: flags, optional

If set to a non-zero value I<-verbose> determines the level of diagnostic print
reporting that is generated during optimization.

The following constants may be bitwise ored together to set logging options:

=over 4

=item * kLogBetter

prints particle details when its fit becomes bebtter than its previous best.

=item * kLogStall

prints particle details when its velocity reaches 0 or falls below the stall
threshold.

=item * kLogIter

Shows the current iteration number.

=back

=back

=item B<setParams(%parameters)>

Set or change optimization parameters. See I<-new> above for a description of
the parameters that may be supplied.

=item B<init()>

Reinitialize the optimization. B<init()> will be called during the first call
to B<optimize()> if it hasn't already been called.

=item B<optimize()>

Runs the minimization optimization. Returns the fit value of the best fit
found. The best possible fit is negative infinity.

B<optimize()> may be called repeatedly to continue the fitting process. The fit
processing on each subsequent call will continue from where the last call left
off.

Use C<getBestPos()> and C<getBestFit()> after optimization to get the optimized
result.

=item B<getBestPos()>

Return the best position vector that has been found so far, as determined by C<fitFunc>. 
Use this after calling C<optimize()>.

=item B<getBestFit()>

Return the fit value that has been found so far, as returned by C<fitFunc>
Use this after calling C<optimize()>.

=item B<getIterationCount()>

Return the number of iterations performed. This may be useful when the
I<-exitFit> criteria has been met or where multiple calls to I<optimize> have
been made.

=item B<getStallCount()>

Returns a PDL of stall counts per particle.

Hint: to get a total stall count, call `$pso->getStallCount()->sum()` .

=back

=head1 SEE ALSO

=over

=item L<PDL::Opt::ParticleSwarm::Simple> - Use names for Particle Swarm-optimized values

=item L<PDL::Opt::Simplex> - A PDL implementation of the Simplex optimization algorithm

=item L<PDL::Opt::Simplex::Simple> - Use names for Simplex-optimized values

=item L<http://en.wikipedia.org/wiki/Particle_swarm_optimization>

=item L<AI::ParticleSwarmOptimization>

=item L<AI::PSO>

=back

=head1 ACKNOWLEDGEMENTS

This PDL implementation is based on L<AI::ParticleSwarmOptimization> by Peter
Jaquiery (GRANDPA), which in turn was based on the L<AI::PSO> originally
created by Kyle Schlansker (KYLESCH).


=head1 AUTHORS

=over

=item Copyright (C) 2023 by Eric Wheeler (EWHEELER)

=item Copyright (C) 2011 by Peter Jaquiery (GRANDPA) as L<AI::ParticleSwarmOptimization>

=item Copyright (C) 2006 by W. Kyle Schlansker (KYLESCH) as L<AI::PSO>

=back

All rights reserved.

=head1 LICENSE

This module is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation, either version 3 of the License, or (at your
option) any later version.

This module is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License along
with this module. If not, see <http://www.gnu.org/licenses/>.

=cut

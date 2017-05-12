#
# LSNoHistory.pm - least-squares regression without data history
#
# $Id: LSNoHistory.pm,v 1.6 2003/02/23 05:11:29 pliam Exp $
#

package Statistics::LSNoHistory;
use strict;

use vars qw($VERSION);
$VERSION = sprintf("%d.%02d", (q$Name: LSNoHist_Release_0_01 $ =~ /\d+/g));

#############################################################################
# top-level pod 
#############################################################################

=pod

=head1 NAME

Statistics::LSNoHistory - Least-Squares linear regression package without 
data history

=head1 SYNOPSIS

  # construct from points
  $reg = Statistics::LSNoHistory->new(points => [
    1.0 => 1.0,
    2.1 => 1.9,
    2.8 => 3.2,
    4.0 => 4.1,
    5.2 => 4.9
  ]);

  # other equivalent constructions
  $reg = Statistics::LSNoHistory->new(
    xvalues => [1.0, 2.1, 2.8, 4.0, 5.2],
    yvalues => [1.0, 1.9, 3.2, 4.1, 4.9]
  );
  # or
  $reg = Statistics::LSNoHistory->new;
  $reg->append_arrays(
    [1.0, 2.1, 2.8, 4.0, 5.2],
    [1.0, 1.9, 3.2, 4.1, 4.9]
  );
  # or
  $reg = Statistics::LSNoHistory->new;
  $reg->append_points(
    1.0 => 1.0, 2.1 => 1.9, 2.8 => 3.2, 4.0 => 4.1, 5.2 => 4.9
  );

  # You may also construct from the preliminary statistics of a 
  # previous regression:
  $reg = Statistics::LSNoHistory->new(
    num => 5,
    sumx => 15.1,
    sumy => 15.1,
    sumxx => 56.29,
    sumyy => 55.67,
    sumxy => 55.83,
    minx => 1.0,
    maxx => 5.2,
    miny => 1.0,
    maxy => 4.9
  );
  # thus a branch may be instantiated as follows
  $branch = Statistics::LSNoHistory->new(%{$reg->dump_stats});
  $reg->append_point(6.1, 5.9);
  $branch->append_point(5.8, 6.0);

  # calculate regression values, print some
  printf("Slope: %.2f\n", $reg->slope);
  printf("Intercept %.2f\n", $reg->intercept);
  printf("Correlation Coefficient: %.2f\n", $reg->pearson_r);
  ...


=head1 DESCRIPTION

This package provides standard least squares linear regression 
functionality without the need for storing the complete data history.  
Like any other, it finds best m,k (in least squares sense) so that 
y = m*x + k fits data points (x_1,y_1),...,(x_n,y_n).

In many applications involving linear regression, it is desirable
to compute a regression based on the intermediate statistics of a 
previous regression along with any I<new> data points.  Thus there
is no need to store a complete data history, but rather only a minimal 
set of intermediate statistics, the number of which, thanks to Gauss, 
is 6.  

The user interface provides a way to instantiate a regression object 
with either raw data or previous intermediate statistics.

=cut

#############################################################################
# construction
#############################################################################

=pod

=head1 CONSTRUCTOR ARGUMENTS

The constructor (or class method I<new>) takes several possible 
arguments.  The initialization scenario depends on the kinds of 
arguments passed and falls into one of the following categories:

=over 2

=item *

I<default:> S<new>() by itself is equivalent to initializing with no
data.  All internal statistics are set to zero.

=item *

I<data points array:> new(I<points> => [x_1 => y_1, x_2 => y_2,..., 
x_n => y_n]) processes the n specified data points.  Note that
points expects an array reference even though we've written it
in "hash notation" for clarity.

=item *

I<data value arrays:> new(I<xvalues> => [x_1, x_2,..., x_n], 
I<yvalues> => [y_1, y_2,..., y_n]) is equivalent to the above.

=item *

I<previous state:> new(I<state arguments>) requires I<all> of the
following intermediate statistics:

=over 6

=item I<num>

S<=E<gt>> Number of points.

=item I<sumx>

S<=E<gt>> Sum of x values.

=item I<sumy> 

S<=E<gt>> Sum of y values.

=item I<sumxx>

S<=E<gt>> Sum of x values squared.

=item I<sumyy>

S<=E<gt>> Sum of y values squared.

=item I<sumxy> 

S<=E<gt>> Sum of x*y products.

=item I<minx> 

S<=E<gt>> Minimum x value.

=item I<maxx> 

S<=E<gt>> Maximum x value.

=item I<miny> 

S<=E<gt>> Minimum y value.

=item I<maxy> 

S<=E<gt>> Maximum y value.

=back 6

=back 2

=cut

## new constructor
sub new {
	my $class = shift;
	my %args = @_;
	my $self;
	my @stats = qw(num sumx sumy sumxx sumyy sumxy);
	push(@stats, qw(minx maxx miny maxy)); # min/max

	# if complete set of statistics, construct from previous state
	# if (@stats == scalar(grep {defined($args{$_})} @stats)) {
	if (@stats == grep {defined($args{$_})} @stats) {
		# reject unsupported arguments and combinations 
		if (grep {defined($args{$_})} qw(points xvalues yvalues)) {
			die "Cannot give new data along with previous state.";
		}
		unless (@stats == keys %args) {
			die "Unknown constructor arguments.";
		}
		# check the number of points for consistency
		unless (abs(int($args{num})) == $args{num}) {
			die "Bad number of points: must be positive integer.";
		}
		$self = \%args;
    	bless $self, $class;
		return $self;
	}
	# in any other case we're starting from scratch
	$self = {};
	bless $self, $class;
	$self->_init;
	# x & y value array refs
	if (defined($args{xvalues}) && defined($args{yvalues})) {
		if (defined $args{points}) {
			die "Must give points or array values, but not both";
		}
		unless (scalar(keys %args) == 2) {
			die "Unknown constructor arguments.";
		}
		$self->append_arrays($args{xvalues}, $args{yvalues});
	}
	# (x,y) point array ref
	elsif (defined($args{points})) {
		if (grep {defined($args{$_})} qw(xvalues yvalues)) {
			die "Must give points or array values, but not both";
		}
		unless (scalar(keys %args) == 1) {
			die "Unknown constructor arguments.";
		}
		$self->append_points(@{$args{points}});
	}
	# default constructor (already initialized above)
	else { 
		if (scalar(keys %args)) {
			die "Unknown constructor arguments.";
		}
	}
    return $self;
}

## _init in this context really means start with state of 0's
sub _init {
	my $self = shift;
	my @stats = qw(num sumx sumy sumxx sumyy sumxy);
	push(@stats, qw(minx maxx miny maxy)); # min/max

	@$self{@stats} = (0) x scalar(@stats);
}


#############################################################################
# other methods
#############################################################################
=pod

=head1 METHODS

=over 2

=cut

#
# adding data
#

## append_point
=pod 

=item *

I<append_point>(x,y) process an additional data point.

=cut 
sub append_point {
	my $self = shift;
	my($x,$y) = @_;

	## will have to recompute regression
	$self->{cached} = 0;

	# min/max
	if ($self->{num}) {
		$self->{minx} = ($x < $self->{minx}) ? $x : $self->{minx};
		$self->{maxx} = ($x > $self->{maxx}) ? $x : $self->{maxx};
		$self->{miny} = ($y < $self->{miny}) ? $y : $self->{miny};
		$self->{maxy} = ($y > $self->{maxy}) ? $y : $self->{maxy};
	}
	else {
		$self->{minx} = $x;
		$self->{maxx} = $x;
		$self->{miny} = $y;
		$self->{maxy} = $y;
	}

	# classic stats
	$self->{num}++;
	$self->{sumx} += $x;
	$self->{sumy} += $y;
	$self->{sumxx} += $x**2;
	$self->{sumyy} += $y**2;
	$self->{sumxy} += $x*$y;
}

## append_points
=pod 

=item *

I<append_points>(x_1 => y_1,..., x_n => y_n) process additional data points, 
which is equivalent to calling append_point() n times.

=cut 
sub append_points {
	my $self = shift;
	my @points = @_;
	my $num = scalar(@points);

	if ($num % 2) { die "Incomplete list of points."; }

	$num /= 2;
	for (1..$num) { $self->append_point(splice(@points, 0, 2)); }
}


## append_arrays
=pod 

=item *

I<append_arrays>([x_1, x_2,..., x_n], [y_1, y_2,..., y_n])
process additional data points given a pair x and y data array
references.  Also equivalent to calling append_point() n times.

=cut 
sub append_arrays {
	my $self = shift;
	my ($xr, $yr) = @_;
	my ($xn, $yn);

	# check arg type
	unless ((ref($xr) eq 'ARRAY') && (ref($yr) eq 'ARRAY'))  { 
		die "Must pass pair of array references."; 
	}

	# check that sizes match
	$xn = scalar(@$xr);
	$yn = scalar(@$yr);
	unless ($xn == $yn) { die "Incomplete list of points."; }

	for (1..$xn) { $self->append_point(shift(@$xr), shift(@$yr)); }
}

#
# computing the regression
#

## _regress method -- done behind the scenes & considered private
sub _regress {
	my $self = shift;
	my($n) = $self->{num};
	my($dx) = $n*$self->{sumxx} - $self->{sumx}**2;
	my($dy) = $n*$self->{sumyy} - $self->{sumy}**2;

	# check that we have 2 points 
	unless ($n >= 2) { die "Must have at least 2 points for regression."; }
	# check data for consistency
	unless (($dx!=0) && ($dy!=0)) { 
		die "Inconsistent data: would divide by zero."; 
	}

	# means and variances
	$self->{avgx} = $self->{sumx}/$n;
	$self->{avgy} = $self->{sumy}/$n;
	$self->{varx} = $dx/$n/($n-1);
	$self->{vary} = $dy/$n/($n-1);

	# slopes and intercepts
	$self->{mx} = ($n*$self->{sumxy} - $self->{sumx}*$self->{sumy})/$dx;
	$self->{kx} = $self->{avgy} - $self->{mx}*$self->{avgx};
	$self->{my} = ($n*$self->{sumxy} - $self->{sumx}*$self->{sumy})/$dy;
	$self->{ky} = $self->{avgx} - $self->{my}*$self->{avgy};
	
	# correlation coefficient (Pearson's r) and chi squared
	$self->{r} = ($n*$self->{sumxy} - $self->{sumx}*$self->{sumy}) 
		/ sqrt($dx*$dy);
	$self->{chi2} = (1-$self->{r}**2)*$dy/$n;

	# flag that regression calculations are up to date
	$self->{cached} = 1;
}

#
# presentation of stats, prediction
#

## average_x 
=pod 

=item *

I<average_x> returns the mean of the x values.

=cut
sub average_x { 
	my $self = shift;
	$self->_regress unless $self->{cached};
	return $self->{avgx}
}

## average_y 
=pod 

=item *

I<average_y> returns the mean of the y values.

=cut
sub average_y { 
	my $self = shift;
	$self->_regress unless $self->{cached};
	return $self->{avgy}
}

## variance_x
=pod 

=item *

I<variance_x> returns the (n-1)-style variance of the x values. 

=cut
sub variance_x { 
	my $self = shift;
	$self->_regress unless $self->{cached};
	return $self->{varx}
}

## variance_y
=pod 

=item *

I<variance_y> returns the (n-1)-style variance of the y values. 

=cut
sub variance_y { 
	my $self = shift;
	$self->_regress unless $self->{cached};
	return $self->{vary}
}

## slope
=pod 

=item *

I<slope> returns the slope m so that y = m*x + k is a least squares fit.
Note that this is the least (y-y_avg)**2, and thus the standard slope.

=cut
sub slope { 
	my $self = shift;
	$self->_regress unless $self->{cached};
	return $self->{mx}
}

## intercept
=pod 

=item *

I<intercept> returns the intercept k so that y = m*x + k is a least squares 
fit.  Note again that this is the least (y-y_avg)**2, and thus the 
standard intercept.

=cut
sub intercept { 
	my $self = shift;
	$self->_regress unless $self->{cached};
	return $self->{kx}
}

## predict - predicte a y value given an x value
=pod 

=item *

I<predict>(x) predicts a y value, given an x value.  Computes m*x + k, where 
m, k are the standard regression slope and intercept (->slope and ->intercept, 
respectively) for the most recent data.

=cut 
sub predict {
	my $self = shift;
	my($x) = @_;

	$self->_regress unless $self->{cached};
	return $self->{mx}*$x + $self->{kx};
}

## slope_y
=pod 

=item *

I<slope_y> returns the slope m' so that y = m'*x + k' is a least squares fit.
Note that this is the least (x-x_avg)**2, and thus I<not> the standard slope.

=cut
sub slope_y { 
	my $self = shift;
	$self->_regress unless $self->{cached};
	return $self->{my}
}

## intercept_y
=pod 

=item *

I<intercept_y> returns the intercept k' so that y = m'*x + k' is a least 
squares fit.  Note that this is the least (x-x_avg)**2, and thus I<not> 
the standard intercept.

=cut
sub intercept_y { 
	my $self = shift;
	$self->_regress unless $self->{cached};
	return $self->{ky}
}

## predict_x - predicte an x value given a y value
=pod 

=item *

I<predict_x>(y) predicts an x value given a y value.  Computes m'*y + k', 
where m', k' are the regression (y-reletive) slope and intercept 
(->slope_y and ->intercept_y, respectively) for the most recent data.

=cut 
sub predict_x {
	my $self = shift;
	my($y) = @_;

	$self->_regress unless $self->{cached};
	return $self->{my}*$y + $self->{ky};
}

## pearson_r
=pod 

=item *

I<pearson_r> returns Pearson's r correlation coefficient.

=cut
sub pearson_r { 
	my $self = shift;
	$self->_regress unless $self->{cached};
	return $self->{r}
}

## chi_squared
=pod 

=item *

I<chi_squared> returns the chi squared statistic.

=cut
sub chi_squared { 
	my $self = shift;
	$self->_regress unless $self->{cached};
	return $self->{chi2}
}

## minimum_x
=pod 

=item *

I<minimum_x> returns the minimum x value

=cut
sub minimum_x { return shift->{minx}; }

## maximum_x
=pod 

=item *

I<maximum_x> returns the maximum x value

=cut
sub maximum_x { return shift->{maxx}; }

## minimum_y
=pod 

=item *

I<minimum_y> returns the minimum y value

=cut
sub minimum_y { return shift->{miny}; }

## maximum_y
=pod 

=item *

I<maximum_y> returns the maximum y value

=cut
sub maximum_y { return shift->{maxy}; }

## dump_stats
=pod 

=item *

I<dump_stats> returns a hash reference of the form

        { num => <val>,
          sumx => <val>,
          sumy => <val>,
          sumxx => <val>,
          sumyy => <val>,
          sumxy => <val>,
          minx => <val>,
          maxx => <val>,
          miny => <val>,
          maxy => <val> }

in other words, containing all the stats required by the final constructor 
above.  This effectively dumps the regression history.

=cut
sub dump_stats { 
	my $self = shift;
	my @stats = qw(num sumx sumy sumxx sumyy sumxy);
	push(@stats, qw(minx maxx miny maxy)); # min/max
	my %dump;

	@dump{@stats} = @$self{@stats};
	return \%dump;
}

1;

__END__
=pod 

=head1 BUGS

This technique is more susceptible to roundoff errors than others which
store the data.  Extra care must be taken to scale the data before 
processing.

=head1 AUTHOR

John Pliam <pliam@cpan.org>

=head1 SEE ALSO

CPAN modules: Statistics::OLS, Statistics::Descriptive, 
Statistics::GaussHelmert, Statistics::Regression.

Any book on statistics, any handbook of mathematics, any comprehensive 
book on numerical algorithms.

Press et al, Numerical Recipes in L [L in {C,Fortran, ...}], Nth edition
[N > 0], Cambridge Univ Press.

=head1 COPYING

See distribution file C<COPYING> for complete information.

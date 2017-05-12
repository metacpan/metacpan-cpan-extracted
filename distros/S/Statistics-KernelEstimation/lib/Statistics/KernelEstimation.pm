package Statistics::KernelEstimation;

use 5.008008;
use strict;
use warnings;

use Carp;

our $VERSION = '0.05';

# =================================================================
# TO DOs
#
# - More unit tests
#   - bandidth from data
#   - math function
#   - optimization
#
# - opt broken for epanechnikov
# - max number of integration steps in stiffness integral

# =================================================================
# Ctors

sub new {
  return new_gauss( @_ );
}

sub new_gauss {
  my $self = _new( @_ );

  $self->{pdf} = \&_gauss_pdf;
  $self->{cdf} = \&_gauss_cdf;

  $self->{curvature} = \&_gauss_curvature;
  $self->{extension} = 3;

  return $self;
}

sub new_box {
  my $self = _new( @_ );

  $self->{pdf} = \&_box_pdf;
  $self->{cdf} = \&_box_cdf;

  $self->{curvature} = \&_box_curvature;
  $self->{extension} = 0;

  $self->{optimizable} = 0;

  return $self;

}

sub new_epanechnikov {
  my $self = _new( @_ );

  $self->{pdf} = \&_epanechnikov_pdf;
  $self->{cdf} = \&_epanechnikov_cdf;

  $self->{curvature} = \&_epanechnikov_curvature;
  $self->{extension} = 0;

  $self->{optimizable} = 0;

  return $self;
}

sub _new {
  my ( $class ) = @_;
  bless { data => [],
	  sum_x   => 0,
	  sum_x2  => 0,
	  sum_cnt => 0,
	  min => undef,
	  max => undef,
	  optimizable => 1 }, $class;
}

# =================================================================
# Accessors

sub count {
  my ( $self ) = @_;
  return $self->{sum_cnt};
}

sub range {
  my ( $self ) = @_;

  if( wantarray ) {
    return ( $self->{min}, $self->{max} );
  }

  return $self->{max};
}

sub extended_range {
  my ( $self ) = @_;

  my ( $min, $max ) = $self->range();
  my $w = $self->{extension}*$self->default_bandwidth();

  if( wantarray ) {
    return ( $min - $w, $max + $w );
  }

  return $max + $w;
}

sub default_bandwidth {
  my ( $self ) = @_;

  if( $self->{sum_cnt} == 0 ) { return undef; }

  my $x  = $self->{sum_x}/$self->{sum_cnt};
  my $x2 = $self->{sum_x2}/$self->{sum_cnt};
  my $sigma = sqrt( $x2 - $x**2 );

  # This is the optimal bandwidth if the point distribution is Gaussian.
  # (Applied Smoothing Techniques for Data Analysis
  # by Adrian W, Bowman & Adelchi Azzalini (1997)) */
  return $sigma * ( (3.0*$self->{sum_cnt}/4.0)**(-1.0/5.0) );
}

# =================================================================
# Adding Data

sub add_data {
  my ( $self, $x, $y, $w ) = @_;

  unless( _isNumber( $x ) ) { croak "Input ,$x, is not numeric."; }

  if( !defined( $y ) ) {
    $y = 1;
  } elsif( !_notNegative( $y ) ) {
    croak "Weight ,$y, must be non-negative number.";
  }

  if( defined( $w ) && !_isPositive( $w ) ) {
    croak "Bandwidth ,$w, must be strictly positive number in add_data.";
  }

  # If no bandwidth has been specified, $w will be undef!
  push @{ $self->{data} }, { pos => $x, cnt => $y, wid => $w };

  # Update summary statistics as we go along:
  $self->{sum_x}   += $y*$x;
  $self->{sum_x2}  += $y*$x*$x;
  $self->{sum_cnt} += $y;

  if( scalar @{ $self->{data} } == 1 ) {
    $self->{min} = $x;
    $self->{max} = $x;
  } else {
    $self->{min} = $x < $self->{min} ? $x : $self->{min};
    $self->{max} = $x > $self->{max} ? $x : $self->{max};
  }

  return;
}

# =================================================================
# Kernel Estimate

sub pdf {
  my $self = shift;
  return $self->_impl( 'pdf', 'default', @_ );
}

sub pdf_width_from_data {
  my $self = shift;
  return $self->_impl( 'pdf', 'fromdata', @_ );
}

# sub pdf_optimal {
#   my $self = shift;
#   return $self->_impl( 'pdf', 'optimal', @_ );
# }


sub cdf {
  my $self = shift;
  return $self->_impl( 'cdf', 'default', @_ );
}

sub cdf_width_from_data {
  my $self = shift;
  return $self->_impl( 'cdf', 'fromdata', @_ );
}

# sub cdf_optimal {
#   my $self = shift;
#   return $self->_impl( 'cdf', 'optimal', @_ );
# }

sub _curvature {
  my $self = shift;
  return $self->_impl( 'curvature', 'default', @_ );
}

sub _impl {
  my ( $self, $mode, $bandwidth_mode, $x, $w ) = @_;

  unless( $mode eq 'pdf' || $mode eq 'cdf'
	  || $mode eq 'curvature' ) { die "Illegal mode: ,$mode,"; }
  unless( _isNumber( $x ) ) { croak "Position ,$x, must be numeric."; }

  # If no data (or only data w/ weight zero), return immediately
  my $count = $self->count();
  if( $count == 0 ) { return 0; }

  # If bandwidth is from data, calculate result and return immediately
  if( $bandwidth_mode eq 'fromdata' ) {
    my $y = 0;
    for my $p ( @{ $self->{data} } ) {
      unless( defined $p->{wid} ) {
	carp "Undefined bandwidth in data at position " . $p->{pos}
	  . ". Using default bandwidth.";
	$w = $self->default_bandwidth();
      } else {
	$w = $p->{wid};
      }

      $y += $p->{cnt} * $self->{$mode}( $x, $p->{pos}, $w );
    }
    return $y/$count;
  }

  # ... otherwise, determine bandwidth
  if( $bandwidth_mode eq 'default' ) {
    if( !defined( $w ) ) {
      $w = $self->default_bandwidth();
    } elsif( !_notNegative( $w ) ) {
      croak "Bandwidth ,$w, must be strictly positive number.";
    }

# } elsif( $bandwidth_mode eq 'optimal' ) {
#   $w = $self->optimal_bandwidth();
  }

  # ... now use bandwidth from above to find result
  my $y = 0;
  for my $q ( @{ $self->{data} } ) {
    $y += $q->{cnt} * $self->{$mode}( $x, $q->{pos}, $w );
  }

  return $y/$count;
}

# =================================================================
# Classical Histograms

sub histogram {
  my ( $self, $bins ) = @_;

  unless( _isPositive( $bins ) && $bins==int($bins) ) {
    croak "Number of bins must be strictly positive integer.";
  }

  if( $self->count() == 0 ) { return []; }

  my ( $min, $max ) = $self->range();

  if( $bins == 1 ) {
    return [ { pos => 0.5*($max-$min), cnt => $self->count() } ];
  }

  my $w = ($max - $min)/($bins - 1);

  my @histo = ();
  for my $k ( 0..$bins-1 ) {
    push @histo, { pos => $min + $k*$w, cnt => 0 };
  }

  for my $p ( @{ $self->{data} } ) {
    my $i = int( ($p->{pos} - ( $min - 0.5*$w ) )/$w );
    my ( $lo, $hi ) = ( $min + ($i-0.5)*$w, $min + ($i+0.5)*$w );

    my $x = $p->{pos};

    if(     $x < $lo )             { $i -= 1; }
    elsif( $lo <= $x && $x < $hi ) { $i = $i; }
    elsif( $hi <= $x )             { $i += 1; }

    $histo[ $i ]->{cnt} += $p->{cnt};
  }

  return \@histo;
}

sub distribution_function {
  my ( $self ) = @_;

  my @sorted = sort { $a->{pos} <=> $b->{pos} } @{ $self->{data} };

  my @dist = ();
  my $cumul = 0;
  for my $p ( @sorted ) {
    $cumul += $p->{cnt};
    push @dist, { pos => $p->{pos}, cnt => $cumul };
  }

  return \@dist;
}

# =================================================================
# Input validation

# In general: undef evaluates to invalid input!

sub _isNumber {
  my ( $in ) = @_;
  if( defined( $in ) &&
      $in =~ /^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/ ) { return 1; }
  return 0;
}

sub _isPositive {
  my ( $in ) = @_;
  if( _isNumber( $in ) && $in > 0 ) { return 1; }
  return 0;
}

sub _notNegative {
  my ( $in ) = @_;
  if( _isNumber( $in ) && $in >= 0 ) { return 1; }
  return 0;
}

# =================================================================
# Optimal Bandwidth

# Development history:
#
# Equation solver:
# 1) Straight iteration
# 2) Newton's method
# 3) Sekant method
# 4) Bisection
#
# Integration:
# 1) Numerical differentiation
# 2) Numerical differentiation, with equal step width as integration
# 3) Symbolic differentiation
# 4) Adaptive step size integration
# 5) Romberg integration (not implemented)

# This routine solves the equation encoded in _optimal_bandwidth_equation
# using the secant method.

sub optimal_bandwidth {
  my $self = shift;
  my $n    = @_ ? shift : 25;
  my $eps  = @_ ? shift : 1e-3;

  unless( $self->{optimizable} ) {
    croak "Bandwidth Optimization not available for this type of kernel.";
  }

  if( $self->{sum_cnt} == 0 ) { return undef; }

  my $x0 = $self->default_bandwidth();
  my $y0 = $self->_optimal_bandwidth_equation( $x0 );

  my $x = 0.8*$x0;
# my $x = $x0 * ( 1 - 1e-6 );
  my $y = $self->_optimal_bandwidth_equation( $x );

  my $dx = 0;

  my $i = 0;
  while( $i++ < $n ) {
    $x -= $y*($x0-$x)/($y0-$y);
    $y = $self->_optimal_bandwidth_equation( $x );

    if( abs($y) < $eps*$y0 ) { last }
  }

  if( wantarray ) { return ( $x, $i ); }
  return $x;
}

# This routine uses the secant method.

sub optimal_bandwidth_safe {
  my $self = shift;
  my $x0 = @_ ? shift : $self->default_bandwidth() / $self->count();
  my $x1 = @_ ? shift : 2*$self->default_bandwidth();
  my $eps  = @_ ? shift : 1e-3;

  unless( $self->{optimizable} ) {
    croak "Bandwidth Optimization not available for this type of kernel.";
  }

  if( $self->{sum_cnt} == 0 ) { return undef; }

  my $y0 = $self->_optimal_bandwidth_equation( $x0 );
  my $y1 = $self->_optimal_bandwidth_equation( $x1 );

  unless( $y0 * $y1 < 0 ) {
    croak "Interval [ f(x0=$x0)=$y0 : f(x1=$x1)=$y1 ] does not bracket root.";
  }

  my ( $x, $y, $i ) = ( 0, 0, 0 );
  while( abs( $x0 - $x1 ) > $eps*$x1 ) {
    $i += 1;

    $x = ( $x0 + $x1 )/2;
    $y = $self->_optimal_bandwidth_equation( $x );

    if( abs( $y ) < $eps*$y0 ) { last }

    if( $y * $y0 < 0 ) {
      ( $x1, $y1 ) = ( $x, $y );
    } else {
      ( $x0, $y0 ) = ( $x, $y );
    }
  }

  if( wantarray ) { return ( $x, $i ); }
  return $x;
}

# This routine encodes the self-consistent equation that is fulfilled
# by the optimal bandwidth. Notation according to Bowman & Azzalini.

sub _optimal_bandwidth_equation {
  my ( $self, $w ) = @_;

  my $alpha = 1.0/(2.0*sqrt( 3.14159265358979323846 ) );
  my $sigma = 1.0;
  my $n = $self->count();
  my $q = $self->_stiffness_integral( $w );

  return $w - ( ($n*$q*$sigma**4)/$alpha )**(-1.0/5.0);
}

# This routine calculates the integral over the square of the curvature
# (it: Int (f'')**2 ) using the trapezoidal rule. The routine decreases
# the step size by half until the relative error in the last step is less
# than epsilon.

sub _stiffness_integral {
  my ( $self, $w ) = @_;

  my $eps = 1e-4;

  my ( $mn, $mx ) = $self->extended_range();
  my $n = 1;
  my $dx = ($mx-$mn)/$n;

  my $yy = 0.5*($self->_curvature($mn,$w)**2+$self->_curvature($mx,$w)**2)*$dx;

  # The trapezoidal rule guarantees a relative error of better than eps
  # for some number of steps less than maxn.
  my $maxn = ($mx-$mn)/sqrt($eps);

  # This is not ideal, but I want to cap the total computation spent here:
  $maxn = ( $maxn > 2048 ? 2048 : $maxn );

  for( my $n=2; $n<=$maxn; $n*=2 ) {
    $dx /= 2.0;

    my $y = 0;
    for( my $i=1; $i<=$n-1; $i+=2 ) {
      $y += $self->_curvature( $mn + $i*$dx, $w )**2;
    }
    $yy = 0.5*$yy + $y*$dx;

    # Make at least 8 steps, then evaluate the relative change between steps
    if( $n > 8 && abs($y*$dx-0.5*$yy) < $eps*$yy ) { last }
  }

  return $yy;
}

# =================================================================
# Kernels

sub _gauss_pdf {
  my ( $x, $m, $s ) = @_;
  my $z = ($x - $m)/$s;
  return exp(-0.5*$z*$z)/( $s*sqrt( 2.0*3.14159265358979323846 ) );
}

# Abramowitz & Stegun, 26.2.17
sub _gauss_cdf {
  my ( $x, $m, $s ) = @_;

  my $z = abs( $x - $m)/$s;
  my $t = 1.0/(1.0 + 0.2316419*$z);
  my $y = $t*( 0.319381530
	       + $t*( -0.356563782
		    + $t*( 1.781477937
			  + $t*( -1.821255978 + $t*1.330274429 ) ) ) );

  if( $x >= $m ) {
    return 1.0 - _gauss_pdf( $x, $m, $s )*$y*$s;
  } else {
    return _gauss_pdf( $x, $m, $s )*$y*$s;
  }
}

sub _gauss_curvature {
  my ( $x, $m, $s ) = @_;
  my $z = ($x - $m)/$s;
  return ($z**2 - 1.0)*_gauss_pdf( $x, $m, $s )/$s**2;
}

sub _box_pdf {
  my ( $x, $m, $s ) = @_;
  if( $x < $m-0.5*$s || $x > $m+0.5*$s ) { return 0.0; }
  return 1.0/$s;
}

sub _box_cdf {
  my ( $x, $m, $s ) = @_;
  if( $x < $m-0.5*$s ) { return 0.0; }
  if( $x > $m+0.5*$s ) { return 1.0; }
  return ( $x-$m )/$s + 0.5;
}

sub _box_curvature {
  return 0;
}

sub _epanechnikov_pdf {
  my ( $x, $m, $s ) = @_;
  my $z = ($x-$m)/$s;
  if( abs($z) > 1 ) { return 0.0; }
  return 0.75*(1-$z**2)/$s;
}

sub _epanechnikov_cdf {
  my ( $x, $m, $s ) = @_;
  my $z = ($x-$m)/$s;
  if( $z < -1 ) { return 0.0; }
  if( $z >  1 ) { return 1.0; }
  return 0.25*(2.0 + 3.0*$z - $z**3 );
}

sub _epanechnikov_curvature {
  my ( $x, $m, $s ) = @_;
  my $z = ($x-$m)/$s;
  if( abs($z) > 1 ) { return 0; }
  return -1.5/$s**3;
}

1;

__END__


=head1 NAME

Statistics::KernelEstimation - Kernel Density Estimates and Histograms

=head1 SYNOPSIS

  use Statistics::KernelEstimation;

  $s = Statistics::KernelEstimation->new();

  for $x ( @data ) {
    $s->add_data( $x );
  }

  $w = $s->default_bandwidth();
  ( $min, $max ) = $s->extended_range();
  for( $x=$min; $x<=$max; $x+=($max-$min)/100 ) {
    print $x, "\t", $s->pdf( $x, $w ), "\t", $s->cdf( $x, $w ), "\n";
  }

  # Alternatively:
  @histo = $s->histogram( 10 );            # 10 bins
  for( @histo ) {
    print $_->{pos}, "\t", $_->{cnt}, "\n";
  }

  @cumul = $s->distribution_function();
  for( @cumul ) {
    print $_->{pos}, "\t", $_->{cnt}, "\n";
  }


=head1 DESCRIPTION

This modules calculates Kernel Density Estimates and related quantities
for a collection of random points.

A Kernel Density Estimate (KDE) is similar to a histogram, but improves
on two known problems of histograms: it is smooth (whereas a histogram
is ragged) and does not suffer from ambiguity in regards to the placement
of bins.

In a KDE, a smooth, strongly peaked function is placed at the location
of each point in the collection, and the contributions from all points
is summed. The resulting function is a smooth approximation to the
probability density from which the set of points was drawn. The smoothness
of the resulting curve can be controlled through a bandwidth parameter.
(More information can be found in the books listed below.)

This module calculates KDEs as well as Cumulative Density Functions (CDF).
Three different kernels are available (Gaussian, Box, Epanechnikov). The
module also offers limited support for bandwidth optimization.

Finally, the module can generate "classical" histograms and distribution
functions.

=head2 Limitations

This module is intended for small to medium-sized data sets (up to a few
hundreds or thousands of points). It is not intended for very large data
sets, or for multi-dimensional data sets. (Although nothing prevents
applications to huge data sets, performance is likely to be poor.)


=head1 METHODS

=head2 Instantiation

A calculator object must be instantiated before it can be used.
The choice of kernel is fixed at instantiation time and can not 
be changed.

=over 5

=item $s = Statistics::KernelEstimation->new()

=item $s = Statistics::KernelEstimation->new_gauss()

Both create a calculator object using the Gaussian kernel:

  exp(-0.5 ((x-m)/s))**2 )/sqrt(2 pi s**2).

=item $s = Statistics::KernelEstimation->new_box()

Creates a calculator object using the box kernel:

  1/s if abs( (x-m)/s ) < 1
  0 otherwise

=item $s = Statistics::KernelEstimation->new_epanechnikov()

Creates a calculator object using the Epanechnikov kernel:

  0.75*(1-((x-m)/s)**2)/s if abs( (x-m)/s ) < 1
  0 otherwise

=back


=head2 Adding Data

=over 5

=item $s->add_data( $x )

Add a single data point at position $x. $x must be a number.

=item $s->add_data( $x, $y )

Add a data point at position $x with weight $y. $y must be a non-negative
number. The following two statements are ((almost)) identical:

  for( 1..5 ) { $s->add_data( $x ); }
  $s->add_data( $x, 5 );

=item $s->add_data( $x, $y, $w )

Add a data point at position $x with weight $y and a bandwidth $w,
which is specific to this data point. $w must be a positive number.
The data specific bandwidth is only meaningful if used with the
functions pdf_width_from_data() and cdf_width_from_data() (cf. below).

=back


=head2 Accessing Information

=over 5

=item $n = $s->count()

Returns the sum of the weights for all data points. If using the
default weights (ie, if only using $s->add_data( $x ) ), this is
equal to the number of data points.

=item $max = $s->range()

=item ( $min, $max ) = $s->range()

=item $emax = $s->extended_range()

=item ( $emin, $emax ) = $s->extended_range()

The $s->range() function returns the minimum and maximum of all data
points. For the box and the Epanechnikov kernel, the $s->extended_range()
function is identical to range(), but for the Gaussian kernel, the
extended range is padded on both sides by 5 * default_bandwidth.
The extended range is chosen such that the kernel density estimate
will have fallen to near zero at the ends of the extended range.

Both functions return an array containing ( min, max ) in array
context, and only the max in scalar context.

=item $bw = $s->default_bandwidth()

The "default bandwidth" is the bandwidth that would be optimal if
the data set was taken from a Normal distribution. It is equal to
sigma * ( 4/(3*n) )**(1/5), where n is the weighted number of data
points (as returned by $s->count()) and sigma is the standard deviation
for the set of points.

For most data sets, the default bandwidth is too wide, leading to
an oversmoothed kernel estimate.

=back


=head2 Kernel Estimates

Probability density functions (PDF) are normalized, such that the 
integral over all of space for a pdf equals 1. Cumulative density
functions (CDF) are normalized such that as x -> infty, cdf -> 1.
A CDF is the integral of a PDF from -infty to x.

=over 5

=item $s->pdf( $x, $w )

Calculates the kernel density estimate (probability density function)
at position $x and for kernel bandwidth $w. If $w is omitted, the
default bandwidth is used.

=item $s->cdf( $x, $w )

Calculates the cumulative distribution function based on the kernel
estimate at position $x with kernel bandwidth $w. If $w is omitted,
the default bandwidth is used.

=item $s->pdf_width_from_data( $x )

Calculates the kernel density estimate (probability density function)
at position $x, using the bandwidth that was specified in the call to
$s->add_data( $x, $w ). If no bandwidth was specified for a data point,
a warning is issued and the default bandwidth is used instead. Any
additional arguments (besides $x) to $s->pdf_width_from_data( $x ) are
ignored.

=item $s->cdf_width_from_data( $x )

Calculates the cumulative distribution function based on the kernel
estimate at position $x, using the bandwidth that was specified in the
call to $s->add_data( $x, $w ). If no bandwidth was specified for a data
point, a warning is issued and the default bandwidth is used instead. Any
additional arguments (besides $x) to $s->cdf_width_from_data( $x ) are
ignored.

=back


=head2 Bandwidth Optimization

This module contains limited support for optimal bandwidth selection.
The $s->optimal_bandwidth() function returns a value for the kernel
bandwidth which is optimal in the AMISE (Asymptotic Mean Square Error)
sense. Check the literature listed below for details.
I<Bandwidth optimization is only available for the Gaussian kernel.>

B<Bandwidth optimization is an expensive process!> Even for moderately
sized data sets (a few hundred points), the process can take a while
(5-30 seconds), more for larger data sets.

The optimal bandwidth is the solution to a self-consistent equation.
This module provides two different algorithms to solve this equation:
one fast, the other one guaranteed safe.

The fast algorithm uses the secant method and should be tried first,
in particular for larger data sets (hundreds of points). As with all
iterative non-linear equation solvers, it is not guaranteed to converge.

The safe algorithm uses the bisection method. With properly chosen
end-points, the bisection method is guaranteed to converge. It is
slower (by about a factor of 3), compared to the secant method. For
smaller data sets (less than hundred points), the difference in speed
is imperceptible.

The bandwidth optimization routines in this module use iterative
algorithms to solve a non-linear equation. Several parameters are
provided which can be used to fine-tune the behavior of these routines
in case the defaults are not sufficient to achieve the desired
convergence. You can consult any standard reference on numerical
analysis for the meaning of these parameters and how to use them.
(The chapter on non-linear equations in "Numerical Recipes" by
Press, Teukolsky, Vetterling, Flannery is sufficient.)

=over 5

=item $s->optimal_bandwidth()

Finds the optimal bandwidth in an AMISE sense using the secant method.
Returns the value for the optimal bandwidth in scalar context.
In array context, returns a two element array ( $bw, $n ), where
the first element is the optimal bandwidth, and the second element
is the number of steps required to achieve convergence in the secant
method.

=item $s->optimal_bandwidth( $n, $eps )

The same as $s->optimal_bandwidth(), but setting explicitly the
maximum number of iteration steps in the secant method $n (default:
$n=25), and the relative final residual $eps (default: $eps=1e-3).

=item $s->optimal_bandwidth_safe()

Finds the optimal bandwidth in an AMISE sense using the bisection method.
Returns the value for the optimal bandwidth in scalar context.
In array context, returns a two element array ( $bw, $n ), where
the first element is the optimal bandwidth, and the second element
is the number of steps required to achieve convergence in the bisection
method.

=item $s->optimal_bandwidth_safe( $x1, $x2, $eps )

The same as $s->optimal_bandwidth_safe(), but setting explicitly the
desired relative accuracy of the result (default: $eps=1e-3), and the
two end-points of the bisection interval (defaults:
$x1=default_bandwidth/count, $x2=2*default_bandwidth). The endpoints
must bracket a root.

=back


=head2 Classical Histograms and Distribution Functions

This module contains basic support for "classical" histograms and
distribution functions.

Histograms are normalized in such a way that the sum over all bins
equals the return value of $s->count(). Distribution functions are
normalized in such a way that the right-most value equals $s-count().

=over 5

=item $r = $s->histogram( $bins )

Given a number $bins of bins, this function returns a histogram of
the data set as a I<ref to an array of hashes>. Each element in the
array is a two element hash: { pos => $x, cnt => $y }. Here, the value
of the pos element is the position of the I<center> of the bin,
whereas the value of the cnt element is the weighted number of points
in the bin. (If only the default weight has been used for all points,
(ie. $s->add_data( $x ) without explicit weight), then the value of
the cnt element is the number of data points in this bin.

The returned array is sorted in ascending order of bin positions.

The first bin is I<centered> at the smallest data point, the last
bin is I<centered> at the greatest data point. All bins have the
same width, namely ($max-$min)/($bins-1). If $bins==1, a single bin
is returned, centered at the half-way point between $min and $max.

There is no support for histograms with variable bin widths, nor for
any choice in the placement of bins (flush left/right vs. centered).

=item $r = $s->distribution_function()

Returns the cumulative distribution function as a
I<ref to an array of hashes>. Each element in the array is a two element
hash: { pos => $x, cnt => $y }. Here, the value of the pos element gives
the x-coordinate and the value of the cnt element gives the corresponding
y-value of the cumulative distribution function.

The returned array is sorted in ascending order of x-coordinates.

The cumulative distribution function is obtained by first sorting all
data points according to their location, and then summing their weights
from left to right. As a consequence, the number of elements in the array
returned from this function equals the number of calls to $s->add_data( $x ).
If multiple calls have been made to $s->add_data( $x ) with the same value
of $x, the distribution function will have multiple entries with the same
x-coordinate, but increasing y-value.

=back



=head1 SEE ALSO

For descriptive summary statistics, check out the
Statistics::Descriptive module on CPAN.

Good information on Kernel Density Estimation can be found in
the following books (in descending order of detail):

=over 4

=item Kernel Smoothing

by M.P. Wand and M.C. Jones, Chapman and Hall, 1995

=item Applied Smoothing Techniques for Data Analysis

by A. W. Bowman and A. Azzalini, Oxford University Press, 1997

=item All of Statistics

by Larry Wasserman, Springer, 2004

=back


=head1 AUTHOR

Philipp K. Janert, E<lt>janert at ieee dot orgE<gt>, http://www.beyondcode.org


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Philipp K. Janert

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

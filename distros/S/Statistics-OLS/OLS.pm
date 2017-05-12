#================---------=================================================#
# Statistics::OLS -- Perform Ordinary Least Squares (with statistics) 2-D  #
#                     by Sanford Morton <smorton@pobox.com>               #
#==========================================================================#

# Revision history for Perl module Statistics::OLS.	  
# 							    
# 0.01 - 22 March 1998					  
# 	   - original version				  
# 							    
# 0.02 - 29 March 1998					  
# 	   - corrected array bounds check bug in setData	  
# 	   - included check for divide by zero in standard error of
# 	     coefficients and t-stats             	  
# 							    
# 0.03 - 31 May 1998					  
# 	   - placed module into standard format using h2xs  
# 							    
# 0.04 - 13 July 1998 					  
# 	   - changed the name from Statistics::Ols to Statistics::OLS
# 							    
# 0.05 - 15 Sep 1999					  
# 	   - corrected error checking bug			  
# 	   - corrected pod documentation bug		  
# 							    
# 0.06 - 4 July 2000					  
# 	   - allowed data in scientific (exponential) notation
# 
# 0.07 - 12 October 2000
#          - _sse fix for potential precision problems

package Statistics::OLS;

$Statistics::OLS::VERSION = '0.07';

use strict;

#==================#
#  public methods  #
#==================#

sub new {
    my $class = shift;
    my $self = {};
    
    bless $self, $class;
    $self->_init (@_);

    return $self;
}


sub setData {
  # check for equal or non-numeric data
  # can receive data either as \@xdata, \@ydata or as @xydata.
  # set refs:  either to $self->{'_xdata'} and $self->{'_ydata'}
  #            or to $self->{'_xydata'}
  # then set $self->{'_flatDataArray'}
  my $self = shift;
  my ($arrayref1, $arrayref2) = @_;
  my ($arrayref, $i);

  if (ref $arrayref2) { # passing data as two data arrays (x0 ...) (y0 ...)

    unless ($#$arrayref1 == $#$arrayref2) { # error checking
      $self->{'_errorMessage'} = "The dataset does not contain an equal number of x and y values. ";
      return 0;
    }

    unless ($#$arrayref1 > 1) { # error checking
      $self->{'_errorMessage'} = "The data set must contain at least three points. ";
      return 0;
    }

    # check whether data are equal and numeric
    for ($i=0; $i<=$#$arrayref1; $i++) {

      unless ($$arrayref1[$i] =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/) {
	$self->{'_errorMessage'} = "The data element $$arrayref1[$i] is non-numeric. ";
	return 0;
      }
      unless ($$arrayref2[$i] =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/) {
	$self->{'_errorMessage'} = "The data element $$arrayref2[$i] is non-numeric. ";
	return 0;
      }
    }
    
    $self->{'_xdata'} = $arrayref1;
    $self->{'_ydata'} = $arrayref2;
    $self->{'_flatDataArray'} = 0; # passed as two data arrays

  } else { # passing data as a single flat data array (x0 y0 ...)
  
    # check whether array is unbalanced
    if ($#$arrayref1 % 2 == 0) {
      $self->{'_errorMessage'} = "The dataset does not contain an equal number of x and y values.";
      return 0;
    }

    unless ($#$arrayref1 > 4) { # error checking
      $self->{'_errorMessage'} = "The data set must contain at least three points. ";
      return 0;
    }

    # check whether data are numeric
    for ($i=0; $i<=$#$arrayref1; $i++) {
      unless ($$arrayref1[$i] =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/) {
	$self->{'_errorMessage'} = "The data element $$arrayref1[$i] is non-numeric.";
	return 0;
      }
    }

    $self->{'_xydata'} = $arrayref1;
    $self->{'_flatDataArray'} = 1; # passed as one data array
  }

  $self->{'_dataIsSet'} = 1;
  $self->{'_gotMinMax'} = 0; # recalculate min-max if already calculated
  return 1;
}



sub error {
  # returns the last error message as a string
  my $self = shift;
  return $self->{'_errorMessage'};
}


sub regress {
  my $self = shift;

  unless ($self->{'_dataIsSet'}) {
      $self->{'_errorMessage'} = "No datset has been registered. ";
      return 0;
  }

  my ($sumX, $sumY, $sumXX, $sumYY, $sumXY) = qw (0 0 0 0 0); 
  my ($n, $i, $arrayref);

  if ($self->{'_flatDataArray'}) {
    $arrayref = $self->{'_xydata'};
    $n = 1 + $#{ $arrayref };
    for ($i=0; $i<$n; $i+=2) {
      $sumX += $self->{'_xydata'}[$i];
      $sumY += $self->{'_xydata'}[$i+1];
      $sumXX += $self->{'_xydata'}[$i]**2; 
      $sumYY += $self->{'_xydata'}[$i+1]**2; 
      $sumXY += $self->{'_xydata'}[$i] * $self->{'_xydata'}[$i+1]; 
    }
    $n /= 2; # number of observations
  } else {
    $arrayref = $self->{'_xdata'};
    $n = $#{ $arrayref };  
    $n++; # number of observations
    for ( $i=0; $i<$n; $i++ ) {
      $sumX += $self->{'_xdata'}[$i];
      $sumY += $self->{'_ydata'}[$i];
      $sumXX += $self->{'_xdata'}[$i]**2; 
      $sumYY += $self->{'_ydata'}[$i]**2; 
      $sumXY += $self->{'_xdata'}[$i] * $self->{'_ydata'}[$i]; 
    }
  }

  # sum of squared deviations of X and Y
  $self->{'_ssdX'} = $sumXX - $sumX**2/$n; 
  $self->{'_ssdY'} = $sumYY - $sumY**2/$n;
  $self->{'_ssdXY'} = $sumXY - $sumX*$sumY/$n;

  # num observations and sample averages
  $self->{'_n'} = $n;
  ($self->{'_avX'}, $self->{'_avY'}) = ($sumX/$n, $sumY/$n);

  # sample var's and cov's (using n-1)
  $self->{'_varX'} = $self->{'_ssdX'} / ($n-1);
  $self->{'_varY'} = $self->{'_ssdY'} / ($n-1);
  $self->{'_covXY'} = $self->{'_ssdXY'} / ($n-1);

  # coefficient estimates
  $self->{'_b2'} = $self->{'_ssdX'} == 0
    ? undef 
      : $self->{'_ssdXY'} / $self->{'_ssdX'}; # slope
  $self->{'_b1'} = ($sumY - $self->{'_b2'} * $sumX) / $n; # intercept

  # R-squared
  $self->{'_rsq'} = ($self->{'_ssdX'} == 0 or $self->{'_ssdY'} == 0) 
    ? 1.0
      : ($self->{'_ssdXY'} / $self->{'_ssdX'}) 
	* ($self->{'_ssdXY'} / $self->{'_ssdY'}) ;
#  $self->{'_rsq'} = $self->{'_b2'}**2 * $self->{'_ssdX'} /  $self->{'_ssdY'};

  # error (residual) sum of squares
  $self->{'_sse'} = $self->{'_ssdY'} - $self->{'_ssdX'} * $self->{'_b2'}**2;
  $self->{'_sse'} = 0 if $self->{'_sse'} < 0; # potential precision problems

  # homoscedastic standard deviation of error term
  $self->{'_sigma'} = sqrt ($self->{'_sse'}/($n-2)); 

  # standard error of coefficients and t-stats
  $self->{'_seB1'} = $self->{'_seB2'} = undef;
  $self->{'_t1'} = $self->{'_t2'} = undef;

  unless ($self->{'_ssdX'} == 0) {
    $self->{'_seB1'} = $self->{'_sigma'} * sqrt ($sumXX / ($n*$self->{'_ssdX'})); 
    $self->{'_seB2'} = $self->{'_sigma'} / sqrt $self->{'_ssdX'}; 
    $self->{'_t2'} = $self->{'_b2'} / $self->{'_seB2'} unless $self->{'_seB2'} == 0;
    $self->{'_t1'} = $self->{'_b1'} / $self->{'_seB1'} unless $self->{'_seB1'} == 0;
  }

  # durbin-watson
  my $sum = 0;
  my ($prevErr, $currentErr);

  if ($self->{'_sse'} == 0) {
    $self->{'_dw'} = undef;
  } else {
    if ($self->{'_flatDataArray'}) { 
      $arrayref = $self->{'_xydata'};
      $n = 1+$#{ $arrayref };
      $prevErr = $self->{'_xydata'}[1]
	- $self->{'_b1'} - $self->{'_b2'} * $self->{'_xydata'}[0];
      for ($i=2; $i<$n; $i+=2) {
	$currentErr = $self->{'_xydata'}[$i+1] 
	  - $self->{'_b1'} - $self->{'_b2'} * $self->{'_xydata'}[$i];
	$sum += ($currentErr - $prevErr)**2;
	$prevErr = $currentErr;
      }
    } else { 
      $arrayref = $self->{'_xdata'};
      $n = 1+$#{ $arrayref };
      $prevErr = $self->{'_ydata'}[0] 
	- $self->{'_b1'} - $self->{'_b2'} * $self->{'_xdata'}[0];
      for ( $i=1; $i<$n; $i++ ) {
	$currentErr = $self->{'_ydata'}[$i] 
	  - $self->{'_b1'} - $self->{'_b2'} * $self->{'_xdata'}[$i];
	$sum += ($currentErr - $prevErr)**2;
	$prevErr = $currentErr;
      }
    }
    $self->{'_dw'} = $sum / $self->{'_sse'};
  }

  $self->{'_gotMinMax'} = 0; # should recalculate min-max's if already calculated
  return 1;
}

sub minMax {
  my $self = shift;
  $self->_getMinMax() unless $self->{'_gotMinMax'};
  return ($self->{'_xmin'}, $self->{'_xmax'}, 
	  $self->{'_ymin'}, $self->{'_ymax'});
}

sub coefficients {  my $self = shift;  return ($self->{'_b1'}, $self->{'_b2'}); }

sub rsq {  my $self = shift;  return $self->{'_rsq'}; }

sub tstats {  my $self = shift;  return ($self->{'_t1'}, $self->{'_t2'}); } 

sub av {  my $self = shift;  return ($self->{'_avX'}, $self->{'_avY'}); }

sub var {  my $self = shift;  return ($self->{'_varX'}, $self->{'_varY'},
				      $self->{'_covXY'}); }

sub sigma {  my $self = shift;  return $self->{'_sigma'}; }

sub size {   my $self = shift;  return $self->{'_n'}; }

sub dw {   my $self = shift;  return $self->{'_dw'}; }

sub residuals {
  my $self = shift;
  my ($n, $i, $arrayref);
  my @result = ();

  if ($self->{'_flatDataArray'}) { # construct xy data array
    $arrayref = $self->{'_xydata'};
    $n = 1+$#{ $arrayref };
    for ($i=0; $i<$n; $i+=2) {
      $result[$i] = $self->{'_xydata'}[$i];
      $result[$i+1] = $self->{'_xydata'}[$i+1] 
                      - $self->{'_b1'} - $self->{'_b2'} * $self->{'_xydata'}[$i];
    }
  } else { # construct y data array
    $arrayref = $self->{'_xdata'};
    $n = 1+$#{ $arrayref };
    for ( $i=0; $i<$n; $i++ ) {
      $result[$i] = $self->{'_ydata'}[$i] 
                    - $self->{'_b1'} - $self->{'_b2'} * $self->{'_xdata'}[$i];
    }
  }
  return @result;
}

sub predicted {
  my $self = shift;
  my ($n, $i, $arrayref);
  my @result = ();

  if ($self->{'_flatDataArray'}) {
    $arrayref = $self->{'_xydata'};
    $n = 1+$#{ $arrayref };
    for ($i=0; $i<$n; $i+=2) {
      $result[$i] = $self->{'_xydata'}[$i];
      $result[$i+1] = $self->{'_b1'} + $self->{'_b2'} * $self->{'_xydata'}[$i];
    }
  } else {
    $arrayref = $self->{'_xdata'};
    $n = 1+$#{ $arrayref };
    for ( $i=0; $i<$n; $i++ ) {
      $result[$i] = $self->{'_b1'} + $self->{'_b2'} * $self->{'_xdata'}[$i];
    }
  }
  return @result;
}


#===================#
#  private methods  #
#===================#

# initialization; 
# this contains a record of all private data
# this is the place to start if you want to read the code.
sub _init {
  my $self = shift;

# $self->{'_flatDataArray'} = ''; # data passed as one flat or two data arrays?
  $self->{'_dataIsSet'} = 0; # return error if asking to regress
  $self->{'_errorMessage'} = '';
    
  # will hold references to caller's data array(s)
# $self->{'_xydata'} = $self->{'_xdata'} = $self->{'_ydata'} = '';

# $self->{'_ssdX'} = $self->{'_ssdY'} = $self->{'_ssdXY'} = '';
  $self->{'_n'} = 0; # num observations
# $self->{'_avX'} = $self->{'_avY'} = '';
# $self->{'_varX'} =  $self->{'_vary'} =  $self->{'_covXY'} = '';

  $self->{'_gotMinMax'} = 0; # do not calculate again
# $self->{'_xmin'} = $self->{'_xmax'} = 0; 
# $self->{'_ymin'} = $self->{'_ymax'} = 0;

# $self->{'_b1'} = $self->{'_b2'} = '';
# $self->{'_rsq'} = $self->{'_sse'} = $self->{'_sigma'} = '';

# $self->{'_seB1'} = $self->{'_seB2'} = undef;
# $self->{'_t1'} = $self->{'_t2'} = undef;
# $self->{'_dw'} = undef;
}


# sets min and max values of all data (_xmin, _ymin, _xmax, _ymax);
# also sets _xslope, _yslope, _ax and _ay used in _data2pxl;
# usage: $self->_getMinMax
sub _getMinMax {
  my $self = shift;
  my ($i, $n, $arrayref);

  if ($self->{'_flatDataArray'}) {
    $self->{'_xmin'} = $self->{'_xmax'} = $self->{'_xydata'}[0];
    $self->{'_ymin'} = $self->{'_ymax'} = $self->{'_xydata'}[1];
    $arrayref = $self->{'_xydata'};
    $n = 1+$#{ $arrayref };
    for ($i=2; $i<$n; $i+=2) {
      $self->{'_xmin'} = $self->{'_xydata'}[$i] 
	if $self->{'_xydata'}[$i] < $self->{'_xmin'};
      $self->{'_xmax'} = $self->{'_xydata'}[$i] 
	if $self->{'_xydata'}[$i] > $self->{'_xmax'};
      $self->{'_ymin'} = $self->{'_xydata'}[$i+1] 
	if $self->{'_xydata'}[$i+1] < $self->{'_ymin'};
      $self->{'_ymax'} = $self->{'_xydata'}[$i+1] 
	if $self->{'_xydata'}[$i+1] > $self->{'_ymax'};
    }
    $n /= 2; # number of observations
  } else {
    $self->{'_xmin'} = $self->{'_xmax'} = $self->{'_xdata'}[0];
    $self->{'_ymin'} = $self->{'_ymax'} = $self->{'_ydata'}[0];
    $arrayref = $self->{'_xdata'};
    $n = 1+$#{ $arrayref };
    for ( $i=1; $i<$n; $i++ ) {
      $self->{'_xmin'} = $self->{'_xdata'}[$i] 
	if $self->{'_xdata'}[$i] < $self->{'_xmin'};
      $self->{'_xmax'} = $self->{'_xdata'}[$i] 
	if $self->{'_xdata'}[$i] > $self->{'_xmax'};
      $self->{'_ymin'} = $self->{'_ydata'}[$i] 
	if $self->{'_ydata'}[$i] < $self->{'_ymin'};
      $self->{'_ymax'} = $self->{'_ydata'}[$i] 
	if $self->{'_ydata'}[$i] > $self->{'_ymax'};
    }
  }
  $self->{'_gotMinMax'} = 1;
}

1;

__END__


=head1 NAME

Statistics::OLS - perform ordinary least squares and associated statistics, v 0.07.

=head1 SYNOPSIS

    use Statistics::OLS; 
    
    my $ls = Statistics::OLS->new(); 
    
    $ls->setData (\@xydataset) or die( $ls->error() );
    $ls->setData (\@xdataset, \@ydataset);
    
    $ls->regress();
    
    my ($intercept, $slope) = $ls->coefficients();
    my $R_squared = $ls->rsq();
    my ($tstat_intercept, $tstat_slope) = $ls->tstats();
    my $sigma = $ls->sigma();
    my $durbin_watson = $ls->dw();  
    
    my $sample_size = $ls->size();    
    my ($avX, $avY) = $ls->av();
    my ($varX, $varY, $covXY) = $ls->var();
    my ($xmin, $xmax, $ymin, $ymax) = $ls->minMax();
    
    # returned arrays are x-y or y-only data 
    # depending on initial call to setData()
    my @predictedYs = $ls->predicted();
    my @residuals = $ls->residuals();


=head1 DESCRIPTION

I wrote B<Statistics::OLS> to perform Ordinary Least Squares (linear
curve fitting) on two dimensional data: y = a + bx. The other simple
statistical module I found on CPAN (Statistics::Descriptive) is
designed for univariate analysis. It accomodates OLS, but somewhat
inflexibly and without rich bivariate statistics. Nevertheless, it
might make sense to fold OLS into that module or a supermodule
someday.

B<Statistics::OLS> computes the estimated slope and intercept of the
regression line, their T-statistics, R squared, standard error of the
regression and the Durbin-Watson statistic. It can also return the
residuals.

It is pretty simple to do two dimensional least squares, but much
harder to do multiple regression, so OLS is unlikely ever to work
with multiple independent variables.

This is a beta code and has not been extensively tested. It has worked
on a few published datasets. Feedback is welcome, particularly if you
notice an error or try it with known results that are not reproduced
correctly.

=head1 USAGE

=head2 Create a regression object: new()

    use Statistics::OLS;
    my $ls = Statistics::OLS->new; 

=head2 Register a dataset: setData()

    $ls->setData (\@xydata);
    $ls->setData (\@xdata, \@ydata);

The setData() method registers a two-dimensional dataset with the
regression object.  You can pass the dataset either as a reference to
one flat array containing the paired x,y data or as references to two
arrays, one each for the x and y data. [In either case, the data
arrays in your script are not cached (copied into the object). If you
alter your data, you may optionally call setData() again (if you want
error checking--see below) but you should at least call the regress()
method (see below) to recompute statistics for the new data. Or more
simply, do not alter your data.]

As a single array, in your script, construct a flat array of the form
(x0, y0, ..., xn, yn) containing n+1 x,y data points.  Then pass a
reference to the data array to the setData() method. (If you do not
know what a reference is, just put a backslash (\) in front of the
name of your data array when you pass it as an argument to setData().)
Like this:

    my @xydata = qw( -3 9   -2 4   -1 1   0 0   1 1  2 4  3 9);
    $ls->setData (\@xydata);

Or, you may find it more convenient to construct two equal length
arrays, one for the horizontal and one for the corresponding vertical
data. Then pass references to both arrays (horizontal first) to
setData():

    my @xdata = qw( -3  -2  -1  0  1  2  3 );
    my @ydata = qw(  9   4   1  0  1  4  9 );
    $ls->setData (\@xdata, \@ydata);

B<Error checking:> The setData() method returns a postive integer on
success and 0 on failure. If setData() fails, you can recover an error
message about the failure with the error() method. The
error string returned will either be one of

    The data set does not contain an equal number of x and y values. 
    The data element ... is non-numeric.
    The data set must contain at least three points.

In your script, you could test for errors like:

    $ls->setData (\@data) or die( $ls->error() );

In the current version, only numerals, decimal points (apologies to
Europeans), scientific notation (1.7E10) and minus signs are
permitted.  Currencies ($), time (11:23am) or dates (23/05/98) are not
yet supported and will generate errors. I may figure these out
someday.


=head2 Perform the regression: regress()

    $ls->regress() or die ( $ls->error() );

This performs most of the calculations. Call this method after setting
the data, but before asking for any regressions results. If you change
your data, previous calculations will generallly be inaccurate, so you
should call this method again. The regress() method returns 1 on
success, The only error message is

    No datset has been registered. 

although a number of undef results (due to divide by zero errors) may
be returned in specific statistics below.


=head2 Obtain regression results: coefficients(), rsq(), tstats(), etc.

    my ($intercept, $slope) = $ls->coefficients();
    my $R_squared = $ls->rsq();
    my ($tstat_intercept, $tstat_slope) = $ls->tstats();
    my $sigma = $ls->sigma();
    my $durbin_watson = $ls->dw();

    my $sample_size = $ls->size();    
    my ($avX, $avY) = $ls->av();
    my ($varX, $varY, $covXY) = $ls->var();
    my ($xmin, $xmax, $ymin, $ymax) = $ls->minMax();

Call these methods only after you have called regress().  Most of
these should be familiar from any econometrics text. If the slope is
infinite (variance of X is zero) it is set to undef. R-squared is 1.0
if the sample variances of either X or Y are zero (or the data are
colinear). If the variance of X is zero, both T statistics are set to
undef. sigma is an estimate of the homoscedastic standard deviation of
the error term, also known as the standard error of the estimate. The
variances use n-1.  Durbin-Watson returns undef if the data are
colinear.

=head2 Obtain predicted or residual data: predicted() and residuals()

    my @predictedYs = $ls->predicted();
    my @residuals = $ls->residuals();

Call these methods only after you have called regress().  Both methods
return data arrays, in the same format you used in setData(). If the
data was passed to setData() as a reference to an @xydata array of the
form (x0, y0, ..., xn, yn), then the results of these methods will be
of this same form, except that the y values will either be the
predicted y based on the coefficient estimates, or the residual error
of that predicted y from the observed value of y.

If the data was passed as references to two arrays, @xdata = (x0
... xn) and @ydata = (y0 ... yn), then the results of these two
methods will be a single array of y type data, either the predicted y or
residual error. The original x data array will still correspond to
these result arrays.

=head1 BUGS AND TO DO

This module is beta code, so it is not guaranteed to work right.
I have not exhaustively tested it.

Possible future work includes support for other data formats, such as
date, time and currency.

Generalization to multiple regression is probably not in the cards,
since it is more than an order of magnitude more difficult. Better to
use something Fortran based or maybe the Perl Data Language.

It would make sense to fold this into Statistics::Descriptive as a
more comprehensive library, perhaps called C<libstats>. But that might
not happen soon, since it sounds like a big project.

Comments and bug reports are welcome.

=head1 AUTHOR

Copyright (c) 1998 by Sanford Morton, smorton@pobox.com.  All rights
reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself. 

This work is dedicated to the memory of Dr. Andrew Morton, who requested it. 
I<Requiescat in pace>, my friend.

=head1 SEE ALSO

The Statistics::Descriptive(1) module performs useful univariate
statistics and is well tested. The Perl Data Language (see CPAN) may
also prove useful for statistics. 

Simple linear regression is discussed in all econometrics and most
probablility and statistics texts. I used E<Basic Econometrics> 2nd
ed., by Gujaratii, New York: McGraw-Hill,1988, for most of the
formulas and the test example (appendix 3A.6, page 87).

=cut 

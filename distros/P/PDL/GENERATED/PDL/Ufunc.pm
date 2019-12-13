
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::Ufunc;

@EXPORT_OK  = qw( PDL::PP prodover PDL::PP dprodover PDL::PP cumuprodover PDL::PP dcumuprodover PDL::PP sumover PDL::PP dsumover PDL::PP cumusumover PDL::PP dcumusumover PDL::PP andover PDL::PP bandover PDL::PP borover PDL::PP orover PDL::PP zcover PDL::PP intover PDL::PP average PDL::PP avgover PDL::PP daverage PDL::PP davgover PDL::PP medover PDL::PP oddmedover PDL::PP modeover PDL::PP pctover PDL::PP oddpctover  pct  oddpct  avg  sum  prod  davg  dsum  dprod  zcheck  and  band  or  bor  min  max  median  mode  oddmedian  any all  minmax PDL::PP qsort PDL::PP qsorti PDL::PP qsortvec PDL::PP qsortveci PDL::PP minimum PDL::PP minimum_ind PDL::PP minimum_n_ind PDL::PP maximum PDL::PP maximum_ind PDL::PP maximum_n_ind PDL::PP maxover PDL::PP maxover_ind PDL::PP maxover_n_ind PDL::PP minover PDL::PP minover_ind PDL::PP minover_n_ind PDL::PP minmaximum PDL::PP minmaxover );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Ufunc ;





=head1 NAME

PDL::Ufunc - primitive ufunc operations for pdl

=head1 DESCRIPTION

This module provides some primitive and useful functions defined
using PDL::PP based on functionality of what are sometimes called
I<ufuncs> (for example NumPY and Mathematica talk about these).
It collects all the functions generally used to C<reduce> or
C<accumulate> along a dimension. These all do their job across the
first dimension but by using the slicing functions you can do it
on any dimension.

The L<PDL::Reduce|PDL::Reduce> module provides an alternative interface
to many of the functions in this module.

=head1 SYNOPSIS

 use PDL::Ufunc;

=cut

use PDL::Slices;
use Carp;






=head1 FUNCTIONS



=cut






=head2 prodover

=for sig

  Signature: (a(n); int+ [o]b())


=for ref

Project via product to N-1 dimensions

This function reduces the dimensionality of a piddle
by one by taking the product along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

=for usage

 $y = prodover($x);

=for example

 $spectrum = prodover $image->xchg(0,1)





=for bad

prodover processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*prodover = \&PDL::prodover;





=head2 dprodover

=for sig

  Signature: (a(n); double [o]b())


=for ref

Project via product to N-1 dimensions

This function reduces the dimensionality of a piddle
by one by taking the product along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

=for usage

 $y = dprodover($x);

=for example

 $spectrum = dprodover $image->xchg(0,1)

Unlike L<prodover|/prodover>, the calculations are performed in double
precision.



=for bad

dprodover processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*dprodover = \&PDL::dprodover;





=head2 cumuprodover

=for sig

  Signature: (a(n); int+ [o]b(n))


=for ref

Cumulative product

This function calculates the cumulative product
along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

The sum is started so that the first element in the cumulative product
is the first element of the parameter.

=for usage

 $y = cumuprodover($x);

=for example

 $spectrum = cumuprodover $image->xchg(0,1)





=for bad

cumuprodover processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cumuprodover = \&PDL::cumuprodover;





=head2 dcumuprodover

=for sig

  Signature: (a(n); double [o]b(n))


=for ref

Cumulative product

This function calculates the cumulative product
along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

The sum is started so that the first element in the cumulative product
is the first element of the parameter.

=for usage

 $y = cumuprodover($x);

=for example

 $spectrum = cumuprodover $image->xchg(0,1)

Unlike L<cumuprodover|/cumuprodover>, the calculations are performed in double
precision.



=for bad

dcumuprodover processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*dcumuprodover = \&PDL::dcumuprodover;





=head2 sumover

=for sig

  Signature: (a(n); int+ [o]b())


=for ref

Project via sum to N-1 dimensions

This function reduces the dimensionality of a piddle
by one by taking the sum along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

=for usage

 $y = sumover($x);

=for example

 $spectrum = sumover $image->xchg(0,1)





=for bad

sumover processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*sumover = \&PDL::sumover;





=head2 dsumover

=for sig

  Signature: (a(n); double [o]b())


=for ref

Project via sum to N-1 dimensions

This function reduces the dimensionality of a piddle
by one by taking the sum along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

=for usage

 $y = dsumover($x);

=for example

 $spectrum = dsumover $image->xchg(0,1)

Unlike L<sumover|/sumover>, the calculations are performed in double
precision.



=for bad

dsumover processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*dsumover = \&PDL::dsumover;





=head2 cumusumover

=for sig

  Signature: (a(n); int+ [o]b(n))


=for ref

Cumulative sum

This function calculates the cumulative sum
along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

The sum is started so that the first element in the cumulative sum
is the first element of the parameter.

=for usage

 $y = cumusumover($x);

=for example

 $spectrum = cumusumover $image->xchg(0,1)





=for bad

cumusumover processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cumusumover = \&PDL::cumusumover;





=head2 dcumusumover

=for sig

  Signature: (a(n); double [o]b(n))


=for ref

Cumulative sum

This function calculates the cumulative sum
along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

The sum is started so that the first element in the cumulative sum
is the first element of the parameter.

=for usage

 $y = cumusumover($x);

=for example

 $spectrum = cumusumover $image->xchg(0,1)

Unlike L<cumusumover|/cumusumover>, the calculations are performed in double
precision.



=for bad

dcumusumover processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*dcumusumover = \&PDL::dcumusumover;





=head2 andover

=for sig

  Signature: (a(n); int+ [o]b())


=for ref

Project via and to N-1 dimensions

This function reduces the dimensionality of a piddle
by one by taking the and along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

=for usage

 $y = andover($x);

=for example

 $spectrum = andover $image->xchg(0,1)





=for bad

If C<a()> contains only bad data (and its bad flag is set), 
C<b()> is set bad. Otherwise C<b()> will have its bad flag cleared,
as it will not contain any bad values.

=cut






*andover = \&PDL::andover;





=head2 bandover

=for sig

  Signature: (a(n);  [o]b())


=for ref

Project via bitwise and to N-1 dimensions

This function reduces the dimensionality of a piddle
by one by taking the bitwise and along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

=for usage

 $y = bandover($x);

=for example

 $spectrum = bandover $image->xchg(0,1)





=for bad

If C<a()> contains only bad data (and its bad flag is set), 
C<b()> is set bad. Otherwise C<b()> will have its bad flag cleared,
as it will not contain any bad values.

=cut






*bandover = \&PDL::bandover;





=head2 borover

=for sig

  Signature: (a(n);  [o]b())


=for ref

Project via bitwise or to N-1 dimensions

This function reduces the dimensionality of a piddle
by one by taking the bitwise or along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

=for usage

 $y = borover($x);

=for example

 $spectrum = borover $image->xchg(0,1)





=for bad

If C<a()> contains only bad data (and its bad flag is set), 
C<b()> is set bad. Otherwise C<b()> will have its bad flag cleared,
as it will not contain any bad values.

=cut






*borover = \&PDL::borover;





=head2 orover

=for sig

  Signature: (a(n); int+ [o]b())


=for ref

Project via or to N-1 dimensions

This function reduces the dimensionality of a piddle
by one by taking the or along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

=for usage

 $y = orover($x);

=for example

 $spectrum = orover $image->xchg(0,1)





=for bad

If C<a()> contains only bad data (and its bad flag is set), 
C<b()> is set bad. Otherwise C<b()> will have its bad flag cleared,
as it will not contain any bad values.

=cut






*orover = \&PDL::orover;





=head2 zcover

=for sig

  Signature: (a(n); int+ [o]b())


=for ref

Project via == 0 to N-1 dimensions

This function reduces the dimensionality of a piddle
by one by taking the == 0 along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

=for usage

 $y = zcover($x);

=for example

 $spectrum = zcover $image->xchg(0,1)





=for bad

If C<a()> contains only bad data (and its bad flag is set), 
C<b()> is set bad. Otherwise C<b()> will have its bad flag cleared,
as it will not contain any bad values.

=cut






*zcover = \&PDL::zcover;





=head2 intover

=for sig

  Signature: (a(n); float+ [o]b())


=for ref

Project via integral to N-1 dimensions

This function reduces the dimensionality of a piddle
by one by taking the integral along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

=for usage

 $y = intover($x);

=for example

 $spectrum = intover $image->xchg(0,1)

Notes:

C<intover> uses a point spacing of one (i.e., delta-h==1).  You will
need to scale the result to correct for the true point delta).

For C<n E<gt> 3>, these are all C<O(h^4)> (like Simpson's rule), but are
integrals between the end points assuming the pdl gives values just at
these centres: for such `functions', sumover is correct to C<O(h)>, but
is the natural (and correct) choice for binned data, of course.




=for bad

intover ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*intover = \&PDL::intover;





=head2 average

=for sig

  Signature: (a(n); int+ [o]b())


=for ref

Project via average to N-1 dimensions

This function reduces the dimensionality of a piddle
by one by taking the average along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

=for usage

 $y = average($x);

=for example

 $spectrum = average $image->xchg(0,1)





=for bad

average processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*average = \&PDL::average;



*PDL::avgover = \&PDL::average;


*avgover = \&PDL::average;


=head2 avgover

=for ref

  Synonym for average.

=cut





=head2 daverage

=for sig

  Signature: (a(n); double [o]b())


=for ref

Project via average to N-1 dimensions

This function reduces the dimensionality of a piddle
by one by taking the average along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

=for usage

 $y = daverage($x);

=for example

 $spectrum = daverage $image->xchg(0,1)

Unlike L<average|/average>, the calculation is performed in double
precision.



=for bad

daverage processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*daverage = \&PDL::daverage;



*PDL::davgover = \&PDL::daverage;


*davgover = \&PDL::daverage;


=head2 davgover

=for ref

  Synonym for daverage.

=cut





=head2 medover

=for sig

  Signature: (a(n); [o]b(); [t]tmp(n))


=for ref

Project via median to N-1 dimensions

This function reduces the dimensionality of a piddle
by one by taking the median along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

=for usage

 $y = medover($x);

=for example

 $spectrum = medover $image->xchg(0,1)





=for bad

medover processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*medover = \&PDL::medover;





=head2 oddmedover

=for sig

  Signature: (a(n); [o]b(); [t]tmp(n))


=for ref

Project via oddmedian to N-1 dimensions

This function reduces the dimensionality of a piddle
by one by taking the oddmedian along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

=for usage

 $y = oddmedover($x);

=for example

 $spectrum = oddmedover $image->xchg(0,1)



The median is sometimes not a good choice as if the array has
an even number of elements it lies half-way between the two
middle values - thus it does not always correspond to a data
value. The lower-odd median is just the lower of these two values
and so it ALWAYS sits on an actual data value which is useful in
some circumstances.
	



=for bad

oddmedover processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*oddmedover = \&PDL::oddmedover;





=head2 modeover

=for sig

  Signature: (data(n); [o]out(); [t]sorted(n))


=for ref

Project via mode to N-1 dimensions

This function reduces the dimensionality of a piddle
by one by taking the mode along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

=for usage

 $y = modeover($x);

=for example

 $spectrum = modeover $image->xchg(0,1)



The mode is the single element most frequently found in a 
discrete data set.

It I<only> makes sense for integer data types, since
floating-point types are demoted to integer before the
mode is calculated.

C<modeover> treats BAD the same as any other value:  if
BAD is the most common element, the returned value is also BAD.




=for bad

modeover does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*modeover = \&PDL::modeover;





=head2 pctover

=for sig

  Signature: (a(n); p(); [o]b(); [t]tmp(n))



=for ref

Project via percentile to N-1 dimensions

This function reduces the dimensionality of a piddle by one by finding
the specified percentile (p) along the 1st dimension.  The specified
percentile must be between 0.0 and 1.0.  When the specified percentile
falls between data points, the result is interpolated.  Values outside
the allowed range are clipped to 0.0 or 1.0 respectively.  The algorithm
implemented here is based on the interpolation variant described at
L<http://en.wikipedia.org/wiki/Percentile> as used by Microsoft Excel
and recommended by NIST.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

=for usage

 $y = pctover($x, $p);

=for example

 $spectrum = pctover $image->xchg(0,1), $p



=for bad

pctover processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*pctover = \&PDL::pctover;





=head2 oddpctover

=for sig

  Signature: (a(n); p(); [o]b(); [t]tmp(n))



Project via percentile to N-1 dimensions

This function reduces the dimensionality of a piddle by one by finding
the specified percentile along the 1st dimension.  The specified
percentile must be between 0.0 and 1.0.  When the specified percentile
falls between two values, the nearest data value is the result.
The algorithm implemented is from the textbook version described
first at L<http://en.wikipedia.org/wiki/Percentile>.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

=for usage

 $y = oddpctover($x, $p);

=for example

 $spectrum = oddpctover $image->xchg(0,1), $p



=for bad

oddpctover processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*oddpctover = \&PDL::oddpctover;




=head2 pct

=for ref

Return the specified percentile of all elements in a piddle. The
specified percentile (p) must be between 0.0 and 1.0.  When the
specified percentile falls between data points, the result is
interpolated.

=for usage

 $x = pct($data, $pct);

=cut

*pct = \&PDL::pct;
sub PDL::pct {
	my($x, $p) = @_; 
    my $tmp;
	$x->clump(-1)->pctover($p, $tmp=PDL->nullcreate($x));
	return $tmp->at();
}




=head2 oddpct

=for ref

Return the specified percentile of all elements in a piddle. The
specified percentile must be between 0.0 and 1.0.  When the specified
percentile falls between two values, the nearest data value is the
result.

=for usage

 $x = oddpct($data, $pct);

=cut

*oddpct = \&PDL::oddpct;
sub PDL::oddpct {
	my($x, $p) = @_; 
    my $tmp;
	$x->clump(-1)->oddpctover($p, $tmp=PDL->nullcreate($x));
	return $tmp->at();
}




=head2 avg

=for ref

Return the average of all elements in a piddle.

See the documentation for L<average|/average> for more information.

=for usage

 $x = avg($data);

=cut



=for bad

This routine handles bad values.

=cut




*avg = \&PDL::avg;
sub PDL::avg {
	my($x) = @_; my $tmp;
	$x->clump(-1)->average( $tmp=PDL->nullcreate($x) );
	return $tmp->at();
}



=head2 sum

=for ref

Return the sum of all elements in a piddle.

See the documentation for L<sumover|/sumover> for more information.

=for usage

 $x = sum($data);

=cut



=for bad

This routine handles bad values.

=cut




*sum = \&PDL::sum;
sub PDL::sum {
	my($x) = @_; my $tmp;
	$x->clump(-1)->sumover( $tmp=PDL->nullcreate($x) );
	return $tmp->at();
}



=head2 prod

=for ref

Return the product of all elements in a piddle.

See the documentation for L<prodover|/prodover> for more information.

=for usage

 $x = prod($data);

=cut



=for bad

This routine handles bad values.

=cut




*prod = \&PDL::prod;
sub PDL::prod {
	my($x) = @_; my $tmp;
	$x->clump(-1)->prodover( $tmp=PDL->nullcreate($x) );
	return $tmp->at();
}



=head2 davg

=for ref

Return the average (in double precision) of all elements in a piddle.

See the documentation for L<daverage|/daverage> for more information.

=for usage

 $x = davg($data);

=cut



=for bad

This routine handles bad values.

=cut




*davg = \&PDL::davg;
sub PDL::davg {
	my($x) = @_; my $tmp;
	$x->clump(-1)->daverage( $tmp=PDL->nullcreate($x) );
	return $tmp->at();
}



=head2 dsum

=for ref

Return the sum (in double precision) of all elements in a piddle.

See the documentation for L<dsumover|/dsumover> for more information.

=for usage

 $x = dsum($data);

=cut



=for bad

This routine handles bad values.

=cut




*dsum = \&PDL::dsum;
sub PDL::dsum {
	my($x) = @_; my $tmp;
	$x->clump(-1)->dsumover( $tmp=PDL->nullcreate($x) );
	return $tmp->at();
}



=head2 dprod

=for ref

Return the product (in double precision) of all elements in a piddle.

See the documentation for L<dprodover|/dprodover> for more information.

=for usage

 $x = dprod($data);

=cut



=for bad

This routine handles bad values.

=cut




*dprod = \&PDL::dprod;
sub PDL::dprod {
	my($x) = @_; my $tmp;
	$x->clump(-1)->dprodover( $tmp=PDL->nullcreate($x) );
	return $tmp->at();
}



=head2 zcheck

=for ref

Return the check for zero of all elements in a piddle.

See the documentation for L<zcover|/zcover> for more information.

=for usage

 $x = zcheck($data);

=cut



=for bad

This routine handles bad values.

=cut




*zcheck = \&PDL::zcheck;
sub PDL::zcheck {
	my($x) = @_; my $tmp;
	$x->clump(-1)->zcover( $tmp=PDL->nullcreate($x) );
	return $tmp->at();
}



=head2 and

=for ref

Return the logical and of all elements in a piddle.

See the documentation for L<andover|/andover> for more information.

=for usage

 $x = and($data);

=cut



=for bad

This routine handles bad values.

=cut




*and = \&PDL::and;
sub PDL::and {
	my($x) = @_; my $tmp;
	$x->clump(-1)->andover( $tmp=PDL->nullcreate($x) );
	return $tmp->at();
}



=head2 band

=for ref

Return the bitwise and of all elements in a piddle.

See the documentation for L<bandover|/bandover> for more information.

=for usage

 $x = band($data);

=cut



=for bad

This routine handles bad values.

=cut




*band = \&PDL::band;
sub PDL::band {
	my($x) = @_; my $tmp;
	$x->clump(-1)->bandover( $tmp=PDL->nullcreate($x) );
	return $tmp->at();
}



=head2 or

=for ref

Return the logical or of all elements in a piddle.

See the documentation for L<orover|/orover> for more information.

=for usage

 $x = or($data);

=cut



=for bad

This routine handles bad values.

=cut




*or = \&PDL::or;
sub PDL::or {
	my($x) = @_; my $tmp;
	$x->clump(-1)->orover( $tmp=PDL->nullcreate($x) );
	return $tmp->at();
}



=head2 bor

=for ref

Return the bitwise or of all elements in a piddle.

See the documentation for L<borover|/borover> for more information.

=for usage

 $x = bor($data);

=cut



=for bad

This routine handles bad values.

=cut




*bor = \&PDL::bor;
sub PDL::bor {
	my($x) = @_; my $tmp;
	$x->clump(-1)->borover( $tmp=PDL->nullcreate($x) );
	return $tmp->at();
}



=head2 min

=for ref

Return the minimum of all elements in a piddle.

See the documentation for L<minimum|/minimum> for more information.

=for usage

 $x = min($data);

=cut



=for bad

This routine handles bad values.

=cut




*min = \&PDL::min;
sub PDL::min {
	my($x) = @_; my $tmp;
	$x->clump(-1)->minimum( $tmp=PDL->nullcreate($x) );
	return $tmp->at();
}



=head2 max

=for ref

Return the maximum of all elements in a piddle.

See the documentation for L<maximum|/maximum> for more information.

=for usage

 $x = max($data);

=cut



=for bad

This routine handles bad values.

=cut




*max = \&PDL::max;
sub PDL::max {
	my($x) = @_; my $tmp;
	$x->clump(-1)->maximum( $tmp=PDL->nullcreate($x) );
	return $tmp->at();
}



=head2 median

=for ref

Return the median of all elements in a piddle.

See the documentation for L<medover|/medover> for more information.

=for usage

 $x = median($data);

=cut



=for bad

This routine handles bad values.

=cut




*median = \&PDL::median;
sub PDL::median {
	my($x) = @_; my $tmp;
	$x->clump(-1)->medover( $tmp=PDL->nullcreate($x) );
	return $tmp->at();
}



=head2 mode

=for ref

Return the mode of all elements in a piddle.

See the documentation for L<modeover|/modeover> for more information.

=for usage

 $x = mode($data);

=cut



=for bad

This routine handles bad values.

=cut




*mode = \&PDL::mode;
sub PDL::mode {
	my($x) = @_; my $tmp;
	$x->clump(-1)->modeover( $tmp=PDL->nullcreate($x) );
	return $tmp->at();
}



=head2 oddmedian

=for ref

Return the oddmedian of all elements in a piddle.

See the documentation for L<oddmedover|/oddmedover> for more information.

=for usage

 $x = oddmedian($data);

=cut



=for bad

This routine handles bad values.

=cut




*oddmedian = \&PDL::oddmedian;
sub PDL::oddmedian {
	my($x) = @_; my $tmp;
	$x->clump(-1)->oddmedover( $tmp=PDL->nullcreate($x) );
	return $tmp->at();
}



=head2 any

=for ref

Return true if any element in piddle set

Useful in conditional expressions:

=for example

 if (any $x>15) { print "some values are greater than 15\n" }

=cut



=for bad

See L<or|/or> for comments on what happens when all elements
in the check are bad.

=cut



*any = \&or;
*PDL::any = \&PDL::or;

=head2 all

=for ref

Return true if all elements in piddle set

Useful in conditional expressions:

=for example

 if (all $x>15) { print "all values are greater than 15\n" }

=cut



=for bad

See L<and|/and> for comments on what happens when all elements
in the check are bad.

=cut




*all = \&and;
*PDL::all = \&PDL::and;




=head2 minmax

=for ref

Returns an array with minimum and maximum values of a piddle.

=for usage

 ($mn, $mx) = minmax($pdl);

This routine does I<not> thread over the dimensions of C<$pdl>; 
it returns the minimum and maximum values of the whole array.
See L<minmaximum|/minmaximum> if this is not what is required.
The two values are returned as Perl scalars similar to min/max.

=for example

 pdl> $x = pdl [1,-2,3,5,0]
 pdl> ($min, $max) = minmax($x);
 pdl> p "$min $max\n";
 -2 5

=cut

*minmax = \&PDL::minmax;
sub PDL::minmax {
  my ($x)=@_; my $tmp;
  my @arr = $x->clump(-1)->minmaximum;
  return map {$_->sclr} @arr[0,1]; # return as scalars !
}





=head2 qsort

=for sig

  Signature: (a(n); [o]b(n))


=for ref

Quicksort a vector into ascending order.

=for example

 print qsort random(10);



=for bad

Bad values are moved to the end of the array:

 pdl> p $y
 [42 47 98 BAD 22 96 74 41 79 76 96 BAD 32 76 25 59 BAD 96 32 BAD]
 pdl> p qsort($y)
 [22 25 32 32 41 42 47 59 74 76 76 79 96 96 96 98 BAD BAD BAD BAD]


=cut






*qsort = \&PDL::qsort;





=head2 qsorti

=for sig

  Signature: (a(n); indx [o]indx(n))


=for ref

Quicksort a vector and return index of elements in ascending order.

=for example

 $ix = qsorti $x;
 print $x->index($ix); # Sorted list



=for bad

Bad elements are moved to the end of the array:

 pdl> p $y
 [42 47 98 BAD 22 96 74 41 79 76 96 BAD 32 76 25 59 BAD 96 32 BAD]
 pdl> p $y->index( qsorti($y) )
 [22 25 32 32 41 42 47 59 74 76 76 79 96 96 96 98 BAD BAD BAD BAD]


=cut






*qsorti = \&PDL::qsorti;





=head2 qsortvec

=for sig

  Signature: (a(n,m); [o]b(n,m))


=for ref

Sort a list of vectors lexicographically.

The 0th dimension of the source piddle is dimension in the vector;
the 1st dimension is list order.  Higher dimensions are threaded over.

=for example

 print qsortvec pdl([[1,2],[0,500],[2,3],[4,2],[3,4],[3,5]]);
 [
  [  0 500]
  [  1   2]
  [  2   3]
  [  3   4]
  [  3   5]
  [  4   2]
 ]
 



=for bad

Vectors with bad components should be moved to the end of the array:


=cut






*qsortvec = \&PDL::qsortvec;





=head2 qsortveci

=for sig

  Signature: (a(n,m); indx [o]indx(m))


=for ref

Sort a list of vectors lexicographically, returning the indices of the
sorted vectors rather than the sorted list itself.

As with C<qsortvec>, the input PDL should be an NxM array containing M
separate N-dimensional vectors.  The return value is an integer M-PDL 
containing the M-indices of original array rows, in sorted order.

As with C<qsortvec>, the zeroth element of the vectors runs slowest in the
sorted list.  

Additional dimensions are threaded over: each plane is sorted separately,
so qsortveci may be thought of as a collapse operator of sorts (groan).



=for bad

Vectors with bad components should be moved to the end of the array:


=cut






*qsortveci = \&PDL::qsortveci;





=head2 minimum

=for sig

  Signature: (a(n); [o]c())


=for ref

Project via minimum to N-1 dimensions

This function reduces the dimensionality of a piddle
by one by taking the minimum along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

=for usage

 $y = minimum($x);

=for example

 $spectrum = minimum $image->xchg(0,1)





=for bad

Output is set bad if all elements of the input are bad,
otherwise the bad flag is cleared for the output piddle.

Note that C<NaNs> are considered to be valid values;
see L<isfinite|PDL::Math/isfinite> and L<badmask|PDL::Math/badmask>
for ways of masking NaNs.


=cut






*minimum = \&PDL::minimum;





=head2 minimum_ind

=for sig

  Signature: (a(n); indx [o] c())

=for ref

Like minimum but returns the index rather than the value

=for bad

Output is set bad if all elements of the input are bad,
otherwise the bad flag is cleared for the output piddle.

=cut






*minimum_ind = \&PDL::minimum_ind;





=head2 minimum_n_ind

=for sig

  Signature: (a(n); indx [o]c(m))

=for ref

Returns the index of C<m> minimum elements

=for bad

Not yet been converted to ignore bad values

=cut






*minimum_n_ind = \&PDL::minimum_n_ind;





=head2 maximum

=for sig

  Signature: (a(n); [o]c())


=for ref

Project via maximum to N-1 dimensions

This function reduces the dimensionality of a piddle
by one by taking the maximum along the 1st dimension.

By using L<xchg|PDL::Slices/xchg> etc. it is possible to use
I<any> dimension.

=for usage

 $y = maximum($x);

=for example

 $spectrum = maximum $image->xchg(0,1)





=for bad

Output is set bad if all elements of the input are bad,
otherwise the bad flag is cleared for the output piddle.

Note that C<NaNs> are considered to be valid values;
see L<isfinite|PDL::Math/isfinite> and L<badmask|PDL::Math/badmask>
for ways of masking NaNs.


=cut






*maximum = \&PDL::maximum;





=head2 maximum_ind

=for sig

  Signature: (a(n); indx [o] c())

=for ref

Like maximum but returns the index rather than the value

=for bad

Output is set bad if all elements of the input are bad,
otherwise the bad flag is cleared for the output piddle.

=cut






*maximum_ind = \&PDL::maximum_ind;





=head2 maximum_n_ind

=for sig

  Signature: (a(n); indx [o]c(m))

=for ref

Returns the index of C<m> maximum elements

=for bad

Not yet been converted to ignore bad values

=cut






*maximum_n_ind = \&PDL::maximum_n_ind;



*PDL::maxover = \&PDL::maximum;


*maxover = \&PDL::maximum;


=head2 maxover

=for ref

  Synonym for maximum.

=cut



*PDL::maxover_ind = \&PDL::maximum_ind;


*maxover_ind = \&PDL::maximum_ind;


=head2 maxover_ind

=for ref

  Synonym for maximum_ind.

=cut



*PDL::maxover_n_ind = \&PDL::maximum_n_ind;


*maxover_n_ind = \&PDL::maximum_n_ind;


=head2 maxover_n_ind

=for ref

  Synonym for maximum_n_ind.

=cut



*PDL::minover = \&PDL::minimum;


*minover = \&PDL::minimum;


=head2 minover

=for ref

  Synonym for minimum.

=cut



*PDL::minover_ind = \&PDL::minimum_ind;


*minover_ind = \&PDL::minimum_ind;


=head2 minover_ind

=for ref

  Synonym for minimum_ind.

=cut



*PDL::minover_n_ind = \&PDL::minimum_n_ind;


*minover_n_ind = \&PDL::minimum_n_ind;


=head2 minover_n_ind

=for ref

  Synonym for minimum_n_ind

=cut





=head2 minmaximum

=for sig

  Signature: (a(n); [o]cmin(); [o] cmax(); indx [o]cmin_ind(); indx [o]cmax_ind())


=for ref

Find minimum and maximum and their indices for a given piddle;

=for usage

 pdl> $x=pdl [[-2,3,4],[1,0,3]]
 pdl> ($min, $max, $min_ind, $max_ind)=minmaximum($x)
 pdl> p $min, $max, $min_ind, $max_ind
 [-2 0] [4 3] [0 1] [2 2]

See also L<minmax|/minmax>, which clumps the piddle together.



=for bad

If C<a()> contains only bad data, then the output piddles will
be set bad, along with their bad flag.
Otherwise they will have their bad flags cleared,
since they will not contain any bad values.

=cut






*minmaximum = \&PDL::minmaximum;



*PDL::minmaxover = \&PDL::minmaximum;


*minmaxover = \&PDL::minmaximum;


=head2 minmaxover

=for ref

  Synonym for minmaximum.

=cut



;


=head1 AUTHOR

Copyright (C) Tuomas J. Lukka 1997 (lukka@husc.harvard.edu).
Contributions by Christian Soeller (c.soeller@auckland.ac.nz)
and Karl Glazebrook (kgb@aaoepp.aao.gov.au).  All rights
reserved. There is no warranty. You are allowed to redistribute this
software / documentation under certain conditions. For details, see
the file COPYING in the PDL distribution. If this file is separated
from the PDL distribution, the copyright notice should be included in
the file.

=cut





# Exit with OK status

1;

		   
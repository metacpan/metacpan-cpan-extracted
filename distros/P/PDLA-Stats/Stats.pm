package PDLA::Stats;

=head1 NAME

PDLA::Stats - a collection of statistics modules in Perl Data Language, with a quick-start guide for non-PDLA people.

=cut

$VERSION = '0.72';

$PDLA::onlinedoc->scan(__FILE__) if $PDLA::onlinedoc;

=head1 DESCRIPTION

Loads modules named below, making the functions available in the current namespace.

Properly formated documentations online at http://pdl-stats.sf.net
 
=head1 SYNOPSIS

    use PDLA::LiteF;        # loads less modules
    use PDLA::NiceSlice;    # preprocessor for easier pdl indexing syntax 

    use PDLA::Stats;
 
    # Is equivalent to the following:

    use PDLA::Stats::Basic;
    use PDLA::Stats::GLM;
    use PDLA::Stats::Kmeans;
    use PDLA::Stats::TS;
 
    # and the following if installed;

    use PDLA::Stats::Distr;
    use PDLA::GSL::CDF;

=head1 QUICK-START FOR NON-PDLA PEOPLE

Enjoy PDLA::Stats without having to dive into PDLA, just wet your feet a little. Three key words two concepts and an icing on the cake, you should be well on your way there.

=head2 pdl

The magic word that puts PDLA::Stats at your disposal. pdl creates a PDLA numeric data object (a pdl, pronounced "piddle" :/ ) from perl array or array ref. All PDLA::Stats methods, unless meant for regular perl array, can then be called from the data object.

    my @y = 0..5;

    my $y = pdl @y;

    # a simple function

    my $stdv = $y->stdv;

    # you can skip the intermediate $y

    my $stdv = stdv( pdl @y );

    # a more complex method, skipping intermediate $y

    my @x1 = qw( y y y n n n );
    my @x2 = qw( 1 0 1 0 1 0 )

    # do a two-way analysis of variance with y as DV and x1 x2 as IVs

    my %result = pdl(@y)->anova( \@x1, \@x2 );
    print "$_\t$result{$_}\n" for (sort keys %result);

If you have a list of list, ie array of array refs, pdl will create a multi-dimensional data object.

    my @a = ( [1,2,3,4], [0,1,2,3], [4,5,6,7] );

    my $a = pdl @a;

    print $a . $a->info;

    # here's what you will get

    [
     [1 2 3 4]
     [0 1 2 3]
     [4 5 6 7]
    ]
    PDLA: Double D [4,3]

PDLA::Stats puts observations in the first dimension and variables in the second dimension, ie pdl [obs, var]. In PDLA::Stats the above example represents 4 observations on 3 variables.

    # you can do all kinds of fancy stuff on such a 2D pdl.

    my %result = $a->kmeans( {NCLUS=>2} );
    print "$_\t$result{$_}\n" for (sort keys %result);

Make sure the array of array refs is rectangular. If the array refs are of unequal sizes, pdl will pad it out with 0s to match the longest list.

=head2 info

Tells you the data type (yes pdls are typed, but you shouldn't have to worry about it here*) and dimensionality of the pdl, as seen in the above example. I find it a big help for my sanity to keep track of the dimensionality of a pdl. As mentioned above, PDLA::Stats uses 2D pdl with observation x variable dimensionality.

*pdl uses double precision by default. If you are working with things like epoch time, then you should probably use pdl(long, @epoch) to maintain the precision.

=head2 list

Come back to the perl reality from the PDLA wonder land. list turns a pdl data object into a regular perl list. Caveat: list produces a flat list. The dimensionality of the data object is lost.

=head2 Signature

This is not a function, but a concept. You will see something like this frequently in the pod:

    stdv
    
      Signature: (a(n); float+ [o]b())

The signature tells you what the function expects as input and what kind of output it produces. a(n) means it expects a 1D pdl with n elements; [o] is for output, b() means its a scalar. So stdv will take your 1D list and give back a scalar. float+ you can ignore; but if you insist, it means the output is at float or double precision. The name a or b or c is not important. What's important is the thing in the parenthesis.

    corr
    
      Signature: (a(n); b(n); float+ [o]c())

Here the function corr takes two inputs, two 1D pdl with the same numbers of elements, and gives back a scalar.

    t_test
    
      Signature: (a(n); b(m); float+ [o]t(); [o]d())

Here the function t_test can take two 1D pdls of unequal size (n==m is certainly fine), and give back two scalars, t-value and degrees of freedom. Yes we accommodate t-tests with unequal sample sizes.

    assign
    
      Signature: (data(o,v); centroid(c,v); byte [o]cluster(o,c))

Here is one of the most complicated signatures in the package. This is a function from Kmeans. assign takes data of observasion x variable dimensions, and a centroid of cluster x variable dimensions, and returns an observation x cluster membership pdl (indicated by 1s and 0s).

Got the idea? Then we can see how PDLA does its magic :)

=head2 Threading

Another concept. The first thing to know is that, threading is optional.

PDLA threading means automatically repeating the operation on extra elements or dimensions fed to a function. For a function with a signature like this

    gsl_cdf_tdist_P

      Signature: (double x(); double nu();  [o]out())

the signatures says that it takes two scalars as input, and returns a scalar as output. If you need to look up the p-values for a list of t's, with the same degrees of freedom 19,

    my @t = ( 1.65, 1.96, 2.56 );

    my $p = gsl_cdf_tdist_P( pdl(@t), 19 );

    print $p . "\n" . $p->info;

    # here's what you will get

    [0.94231136 0.96758551 0.99042586]
    PDLA: Double D [3]

The same function is repeated on each element in the list you provided. If you had different degrees of freedoms for the t's,

    my @df = (199, 39, 19);

    my $p = gsl_cdf_tdist_P( pdl(@t), pdl(@df) );

    print $p . "\n" . $p->info;

    # here's what you will get
     
    [0.94973979 0.97141553 0.99042586]
    PDLA: Double D [3]

The df's are automatically matched with the t's to give you the results.

An example of threading thru extra dimension(s):

    stdv
    
      Signature: (a(n); float+ [o]b())

if the input is of 2D, say you want to compute the stdv for each of the 3 variables,

    my @a = ( [1,1,3,4], [0,1,2,3], [4,5,6,7] );

    # pdl @a is pdl dim [4,3]

    my $sd = stdv( pdl @a );

    print $sd . "\n" . $sd->info;

    # this is what you will get

    [ 1.2990381   1.118034   1.118034]
    PDLA: Double D [3]

Here the function was given an input with an extra dimension of size 3, so it repeates the stdv operation on the extra dimenion 3 times, and gives back a 1D pdl of size 3.

Threading works for arbitrary number of dimensions, but it's best to refrain from higher dim pdls unless you have already decided to become a PDLA wiz / witch.

Not all PDLA::Stats methods thread. As a rule of thumb, if a function has a signature attached to it, it threads.

=head2 perldl

Essentially a perl shell with "use PDLA;" at start up. Comes with the PDLA installation. Very handy to try out pdl operations, or just plain perl. print is shortened to p to avoid injury from exessive typing. my goes out of scope at the end of (multi)line input, so mostly you will have to drop the good practice of my here.

=head2 For more info

PDLA::Impatient

=cut

use strict;
use warnings;


sub PDLA::Stats::import {

  my $pkg = (caller())[0];
  my $use;
  
  if (grep {-e $_ . '/PDLA/GSL/CDF.pm'} @INC) {
    $use = <<EOD;
  
package $pkg;

use PDLA::Stats::Basic;
use PDLA::Stats::Distr;
use PDLA::Stats::GLM;
use PDLA::Stats::Kmeans;
use PDLA::Stats::TS;
use PDLA::GSL::CDF;

EOD
  }
  else {
    $use = <<EOD;

package $pkg;

use PDLA::Stats::Basic;
use PDLA::Stats::GLM;
use PDLA::Stats::Kmeans;
use PDLA::Stats::TS;

EOD
  }
  
  eval $use;
  die $@ if $@;
}

=head1 AUTHOR

~~~~~~~~~~~~ ~~~~~ ~~~~~~~~ ~~~~~ ~~~ `` ><(((">

Copyright (C) 2009-2013 Maggie J. Xiong <maggiexyz users.sourceforge.net>

All rights reserved. There is no warranty. You are allowed to redistribute this software / documentation as described in the file COPYING in the PDLA distribution.

=cut

1;

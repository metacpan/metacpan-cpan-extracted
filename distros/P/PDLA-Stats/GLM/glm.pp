#!/usr/bin/perl

pp_add_exported('', 'ols_t', 'anova', 'anova_rptd', 'dummy_code', 'effect_code', 'effect_code_w', 'interaction_code', 'ols', 'ols_rptd', 'r2_change', 'logistic', 'pca', 'pca_sorti', 'plot_means', 'plot_residuals', 'plot_screes');

pp_addpm({At=>'Top'}, <<'EOD');

use strict;
use warnings;

use Carp;
use PDLA::LiteF;
use PDLA::MatrixOps;
use PDLA::NiceSlice;
use PDLA::Stats::Basic;
use PDLA::Stats::Kmeans;

$PDLA::onlinedoc->scan(__FILE__) if $PDLA::onlinedoc;

eval { require PDLA::GSL::CDF; };
my $CDF = 1 if !$@;

eval { require PDLA::Slatec; };
my $SLATEC = 1 if !$@;

eval {
  require PDLA::Graphics::PGPLOT::Window;
  PDLA::Graphics::PGPLOT::Window->import( 'pgwin' );
};
my $PGPLOT = 1 if !$@;

my $DEV = ($^O =~ /win/i)? '/png' : '/xs';

=head1 NAME

PDLA::Stats::GLM -- general and generalized linear modeling methods such as ANOVA, linear regression, PCA, and logistic regression.

=head1 DESCRIPTION

The terms FUNCTIONS and METHODS are arbitrarily used to refer to methods that are threadable and methods that are NOT threadable, respectively. FUNCTIONS except B<ols_t> support bad value. B<PDLA::Slatec> strongly recommended for most METHODS, and it is required for B<logistic>.

P-values, where appropriate, are provided if PDLA::GSL::CDF is installed.

=head1 SYNOPSIS

    use PDLA::LiteF;
    use PDLA::NiceSlice;
    use PDLA::Stats::GLM;

    # do a multiple linear regression and plot the residuals

    my $y = pdl( 8, 7, 7, 0, 2, 5, 0 );

    my $x = pdl( [ 0, 1, 2, 3, 4, 5, 6 ],        # linear component
                 [ 0, 1, 4, 9, 16, 25, 36 ] );   # quadratic component

    my %m  = $y->ols( $x, {plot=>1} );

    print "$_\t$m{$_}\n" for (sort keys %m);

=cut

EOD

pp_addhdr('
#include <math.h>
#include <stdlib.h>
#include <time.h>

'
);

pp_def('fill_m',
  Pars      => 'a(n); float+ [o]b(n)',
  Inplace   => 1,
  GenericTypes => [F, D],
  HandleBad => 1,
  Code      => '
    loop (n) %{
      $b() = $a();
    %}
  ',
  BadCode   => '
    $GENERIC(b) sa, m;
    sa = 0;
    long N = 0;
    loop (n) %{
      if ( $ISGOOD($a()) ) {
        sa += $a();
        N  ++;
      }
    %}
    m = N?   sa / N : 0;
    loop (n) %{
      if ( $ISGOOD($a()) ) {
        $b() = $a();
      }
      else {
        $b() = m;
      }
    %}
  ',
  CopyBadStatusCode => '
    /* propagate badflag if inplace AND it has changed */
    if ( a == b && $ISPDLASTATEBAD(a) )
      PDLA->propagate_badflag( b, 0 );

    /* always make sure the output is "good" */
    $SETPDLASTATEGOOD(b);

  ',
  Doc      => '

=for ref

Replaces bad values with sample mean. Mean is set to 0 if all obs are bad. Can be done inplace.

=for usage

     perldl> p $data
     [
      [  5 BAD   2 BAD]
      [  7   3   7 BAD]
     ]

     perldl> p $data->fill_m
     [
      [      5     3.5       2     3.5]
      [      7       3       7 5.66667]
     ] 

=cut

  ',
  BadDoc  => '
The output pdl badflag is cleared.
  ',

);

pp_def('fill_rand',
  Pars      => 'a(n); [o]b(n)',
  Inplace   => 1,
  HandleBad => 1,
  Code      => '
    loop (n) %{
      $b() = $a();
    %}
  ',
  BadCode   => '
    $GENERIC(a) *g[ $SIZE(n) ];
    long i, j;
    i = 0;
    srand( time( NULL ) );
    loop (n) %{
      if ( $ISGOOD($a()) ) {
        g[i++] = &$a();
      }
    %}
    loop (n) %{
      if ( $ISGOOD($a()) ) {
        $b() = $a();
      }
      else {
        j = (long) ((i-1) * (double)(rand()) / (double)(RAND_MAX) + .5);
        $b() = *g[j];
      }
    %}
  ',
  CopyBadStatusCode => '
    /* propagate badflag if inplace AND it has changed */
    if ( a == b && $ISPDLASTATEBAD(a) )
      PDLA->propagate_badflag( b, 0 );

    /* always make sure the output is "good" */
    $SETPDLASTATEGOOD(b);

  ',
  Doc      => '

=for ref

Replaces bad values with random sample (with replacement) of good observations from the same variable. Can be done inplace.

=for usage

    perldl> p $data
    [
     [  5 BAD   2 BAD]
     [  7   3   7 BAD]
    ]
    
    perldl> p $data->fill_rand
    
    [
     [5 2 2 5]
     [7 3 7 7]
    ]

=cut

  ',
  BadDoc  => '
The output pdl badflag is cleared. 
  ',

);

pp_def('dev_m',
  Pars      => 'a(n); float+ [o]b(n)',
  Inplace   => 1,
  GenericTypes => [F, D],
  HandleBad => 1,
  Code      => '
    $GENERIC(b) sa, m;
    sa = 0; m = 0;
    long N = $SIZE(n);
    loop (n) %{
      sa += $a();
    %}
    m  = sa / N;
    loop (n) %{
      $b() = $a() - m;
    %}
  ',
  BadCode   => '
    $GENERIC(b) sa, m;
    sa = 0; m = 0;
    long N = 0;
    loop (n) %{
      if ( $ISGOOD($a()) ) {
        sa += $a();
        N  ++;
      }
    %}
    m = sa / N;
    loop (n) %{
      if ( $ISGOOD($a()) ) {
        $b() = $a() - m;
      }
      else {
        $SETBAD($b());
      }
    %}
  ',
  Doc      => '

=for ref

Replaces values with deviations from the mean. Can be done inplace.

=cut

  ',

);

pp_def('stddz',
  Pars      => 'a(n); float+ [o]b(n)',
  Inplace   => 1,
  GenericTypes => [F, D],
  HandleBad => 1,
  Code      => '
    $GENERIC(b) sa, a2, m, sd;
    sa = 0; a2 = 0;
    long N = $SIZE(n);
    loop (n) %{
      sa += $a();
      a2 += pow($a(),2);
    %}
    m  = sa / N;
    sd = pow( a2/N - pow(m,2), .5 );
    loop (n) %{
      $b() = (sd>0)?  (($a() - m) / sd) : 0;
    %}
  ',
  BadCode   => '
    $GENERIC(b) sa, a2, m, sd;
    sa = 0; a2 = 0; m = 0; sd = 0;
    long N = 0;
    loop (n) %{
      if ( $ISGOOD($a()) ) {
        sa += $a();
        a2 += pow($a(),2);
        N  ++;
      }
    %}
    if (N) {
      m  = sa / N;
      sd = pow( a2/N - pow(m,2), .5 );
      loop (n) %{
        if ( $ISGOOD(a()) ) {
/* sd? does not work, presumably due to floating point */
          $b() = (sd>0)? (($a() - m) / sd) : 0;
        }
        else {
          $SETBAD(b());
        }
      %}
    }
    else {
      loop (n) %{
        $SETBAD(b());
      %}
    }
  ',
  Doc       => '
=for ref

Standardize ie replace values with z_scores based on sample standard deviation from the mean (replace with 0s if stdv==0). Can be done inplace.

=cut

  ',

);

pp_def('sse',
  Pars      => 'a(n); b(n); float+ [o]c()',
  GenericTypes => [F, D],
  HandleBad => 1,
  Code      => '
    $GENERIC(c) ss = 0;
    loop (n) %{
      ss += pow($a() - $b(), 2);
    %}
    $c() = ss;
  ',
  BadCode  => '
    $GENERIC(c) ss = 0;
    loop (n) %{
      if ( $ISBAD($a()) || $ISBAD($b()) ) { }
      else {
        ss += pow($a() - $b(), 2);
      }
    %}
    $c() = ss;
  ',
  Doc      => '

=for ref

Sum of squared errors between actual and predicted values.

=cut

  ',

);

pp_def('mse',
  Pars      => 'a(n); b(n); float+ [o]c()',
  GenericTypes => [F, D],
  HandleBad => 1,
  Code      => '
    $GENERIC(c) ss = 0;
    loop (n) %{
      ss += pow($a() - $b(), 2);
    %}
    $c() = ss / $SIZE(n);
  ',
  BadCode  => '
    $GENERIC(c) ss = 0;
    long N = 0;
    loop (n) %{
      if ( $ISBAD($a()) || $ISBAD($b()) ) { }
      else {
        ss += pow($a() - $b(), 2);
        N ++;
      }
    %}
    if (N) { $c() = ss/N;  }
    else   { $SETBAD(c()); }
  ',
  Doc      => '

=for ref

Mean of squared errors between actual and predicted values, ie variance around predicted value.

=cut

  ',

);


pp_def('rmse',
  Pars      => 'a(n); b(n); float+ [o]c()',
  GenericTypes => [F, D],
  HandleBad => 1,
  Code      => '
    $GENERIC(c) d2;
    d2 = 0;
    long N = $SIZE(n);
    loop (n) %{
      d2 += pow($a() - $b(), 2);
    %}
    $c() = sqrt( d2 / N );
  ',
  BadCode  => '
    $GENERIC(c) d2;
    d2 = 0;
    long N = 0;
    loop (n) %{
      if ( $ISBAD($a()) || $ISBAD($b()) ) { }
      else {
        d2 += pow($a() - $b(), 2);
        N  ++;
      }
    %}
    if (N)  { $c() = sqrt( d2 / N ); }
    else    { $SETBAD(c()); }
  ',
  Doc      => '

=for ref

Root mean squared error, ie stdv around predicted value.

=cut

  ',

);

pp_def('pred_logistic',
  Pars      => 'a(n,m); b(m); float+ [o]c(n)',
  GenericTypes => [F, D],
  HandleBad => 1,
  Code      => '
    loop (n) %{
      $GENERIC(c) l = 0;
      loop (m) %{
        l += $a() * $b();
      %}
      $c() = 1 / ( 1 + exp(-l) );
    %}
  ',
  BadCode  => '
    loop (n) %{
      $GENERIC(c) l = 0;
      long bad = 0;
      loop (m) %{
        if ( $ISBAD($a()) || $ISBAD($b()) ) {
          bad = 1;
        }
        else {
          l += $a() * $b();
        }
      %}
      if (bad) { $SETBAD( $c() ); }
      else     { $c() = 1 / ( 1 + exp(-l) ); }
    %}
  ',
  Doc      => '

=for ref

Calculates predicted prob value for logistic regression.

=for usage

    # glue constant then apply coeff returned by the logistic method

    $pred = $x->glue(1,ones($x->dim(0)))->pred_logistic( $m{b} );

=cut

  ',

);

pp_def('d0',
  Pars      => 'a(n); float+ [o]c()',
  GenericTypes => [F, D],
  HandleBad => 1,
  Code      => '
    $GENERIC(c) p, ll;
    p = 0; ll = 0;
    long N = $SIZE(n);
    loop (n) %{
      p += $a();
    %}
    p /= N;
    loop (n) %{
      ll += $a()? log( p ) : log( 1 - p );
    %}
    $c() = -2 * ll;
  ',
  BadCode  => '
    $GENERIC(c) p, ll;
    p = 0; ll = 0;
    long N = 0;
    loop (n) %{
      if ($ISGOOD( $a() )) {
        p += $a();
        N ++;
      }
    %}
    if (N) {
      p /= N;
      loop (n) %{
        if ($ISGOOD( $a() ))
          ll += $a()? log( p ) : log( 1 - p );
      %}
      $c() = -2 * ll;
    }
    else {
      $SETBAD(c());
    }
  ',
  Doc      => '
=for usage

    my $d0 = $y->d0();

=for ref

Null deviance for logistic regression.

=cut

  ',

);

pp_def('dm',
  Pars      => 'a(n); b(n); float+ [o]c()',
  GenericTypes => [F, D],
  HandleBad => 1,
  Code      => '
    $GENERIC(c) ll;
    ll = 0;
    loop (n) %{
      ll += $a()? log( $b() ) : log( 1 - $b() );
    %}
    $c() = -2 * ll;
  ',
  BadCode  => '
    $GENERIC(c) ll;
    ll = 0;
    loop (n) %{
      if ( $ISBAD($a()) || $ISBAD($b()) ) { }
      else {
        ll += $a()? log( $b() ) : log( 1 - $b() );
      }
    %}
    $c() = -2 * ll;
  ',
  Doc      => '
=for usage

    my $dm = $y->dm( $y_pred );

      # null deviance
    my $d0 = $y->dm( ones($y->nelem) * $y->avg );

=for ref

Model deviance for logistic regression.

=cut

  ',

);


pp_def('dvrs',
  Pars      => 'a(); b(); float+ [o]c()',
  GenericTypes => [F, D],
  HandleBad => 1,
  Code      => '
    $c() = $a()?       sqrt( -2 * log($b()) )
         :        -1 * sqrt( -2 * log(1-$b()) )
         ;
  ',
  BadCode  => '
  if ( $ISBAD($a()) || $ISBAD($b()) ) {
    $SETBAD( $c() );
  }
  else {
    $c() = $a()?       sqrt( -2 * log($b()) )
         :        -1 * sqrt( -2 * log(1-$b()) )
         ;
  }

  ',
  Doc      => '

=for ref

Deviance residual for logistic regression.

=cut

  ',

);

pp_addpm(<<'EOD');

# my tmp var for PDLA 2.007 slice upate
my $_tmp;

=head2 ols_t

=for ref

Threaded version of ordinary least squares regression (B<ols>). The price of threading was losing significance tests for coefficients (but see B<r2_change>). The fitting function was shamelessly copied then modified from PDLA::Fit::Linfit. Uses PDLA::Slatec when possible but otherwise uses PDLA::MatrixOps. Intercept is LAST of coeff if CONST => 1.

ols_t does not handle bad values. consider B<fill_m> or B<fill_rand> if there are bad values.

=for options

Default options (case insensitive):

    CONST   => 1,

=for usage

Usage:

    # DV, 2 person's ratings for top-10 box office movies
    # ascending sorted by box office numbers

    perldl> p $y = qsort ceil( random(10, 2)*5 )    
    [
     [1 1 2 4 4 4 4 5 5 5]
     [1 2 2 2 3 3 3 3 5 5]
    ]

    # model with 2 IVs, a linear and a quadratic trend component

    perldl> $x = cat sequence(10), sequence(10)**2

    # suppose our novice modeler thinks this creates 3 different models
    # for predicting movie ratings

    perldl> p $x = cat $x, $x * 2, $x * 3
    [
     [
      [ 0  1  2  3  4  5  6  7  8  9]
      [ 0  1  4  9 16 25 36 49 64 81]
     ]
     [
      [  0   2   4   6   8  10  12  14  16  18]
      [  0   2   8  18  32  50  72  98 128 162]
     ]
     [
      [  0   3   6   9  12  15  18  21  24  27]
      [  0   3  12  27  48  75 108 147 192 243]
     ]
    ]

    perldl> p $x->info
    PDLA: Double D [10,2,3]

    # insert a dummy dim between IV and the dim (model) to be threaded

    perldl> %m = $y->ols_t( $x->dummy(2) )

    perldl> p "$_\t$m{$_}\n" for (sort keys %m)

    # 2 persons' ratings, eached fitted with 3 "different" models

    F
    [
     [ 38.314159  25.087209]
     [ 38.314159  25.087209]
     [ 38.314159  25.087209]
    ]

    # df is the same across dv and iv models
 
    F_df    [2 7]
    F_p
    [
     [0.00016967051 0.00064215074]
     [0.00016967051 0.00064215074]
     [0.00016967051 0.00064215074]
    ]
    
    R2
    [
     [ 0.9162963 0.87756762]
     [ 0.9162963 0.87756762]
     [ 0.9162963 0.87756762]
    ]

    b
    [  # linear      quadratic     constant
     [
      [  0.99015152 -0.056818182   0.66363636]    # person 1
      [  0.18939394  0.022727273          1.4]    # person 2
     ]
     [
      [  0.49507576 -0.028409091   0.66363636]
      [  0.09469697  0.011363636          1.4]
     ]
     [
      [  0.33005051 -0.018939394   0.66363636]
      [ 0.063131313 0.0075757576          1.4]
     ]
    ]

    # our novice modeler realizes at this point that
    # the 3 models only differ in the scaling of the IV coefficients 
    
    ss_model
    [
     [ 20.616667  13.075758]
     [ 20.616667  13.075758]
     [ 20.616667  13.075758]
    ]
    
    ss_residual
    [
     [ 1.8833333  1.8242424]
     [ 1.8833333  1.8242424]
     [ 1.8833333  1.8242424]
    ]
    
    ss_total        [22.5 14.9]
    y_pred
    [
     [
      [0.66363636  1.5969697  2.4166667  3.1227273  ...  4.9727273]
    ...

=cut

*ols_t = \&PDLA::ols_t;
sub PDLA::ols_t {
    # y [n], ivs [n x attr] pdl
  my ($y, $ivs, $opt) = @_;
  my %opt = ( CONST => 1 );
  $opt and $opt{uc $_} = $opt->{$_} for (keys %$opt);

#  $y = $y->squeeze;
  $ivs = $ivs->dummy(1) if $ivs->getndims == 1;
    # set up ivs and const as ivs
  $opt{CONST} and
    $ivs = $ivs->glue( 1, ones($ivs->dim(0)) );

  # Internally normalise data
  # (double) it or ushort y and sequence iv won't work right
  my $ymean = $y->abs->sumover->double / $y->dim(0);
  ($_tmp = $ymean->where( $ymean==0 )) .= 1;
  my $y2 = $y / $ymean->dummy(0);
 
  # Do the fit
     
  my $Y = $ivs x $y2->dummy(0);

  my $C;

  if ( $SLATEC ) {
    $C = PDLA::Slatec::matinv( $ivs x $ivs->xchg(0,1) );
  }
  else {
    $C = inv( $ivs x $ivs->xchg(0,1) );
  }

    # Fitted coefficients vector
  my $coeff = PDLA::squeeze( $C x $Y );

  $coeff = $coeff->dummy(0)
    if $coeff->getndims == 1 and $y->getndims > 1;
  $coeff *= $ymean->dummy(0);        # Un-normalise

  return $coeff
    unless wantarray; 

  my %ret;

    # ***$coeff x $ivs looks nice but produces nan on successive tries***
  $ret{y_pred} = sumover( $coeff->dummy(1) * $ivs->xchg(0,1) );
  $ret{ss_total} = $opt{CONST}? $y->ss : sumover( $y ** 2 );
  $ret{ss_residual} = $y->sse( $ret{y_pred} );
  $ret{ss_model} = $ret{ss_total} - $ret{ss_residual};
  $ret{R2} = $ret{ss_model} / $ret{ss_total};

  my $n_var = $opt{CONST}? $ivs->dim(1) - 1 : $ivs->dim(1);
  $ret{F_df} = pdl( $n_var, $y->dim(0) - $ivs->dim(1) );
  $ret{F}
    = $ret{ss_model} / $ret{F_df}->(0) / ($ret{ss_residual} / $ret{F_df}->(1));
  $ret{F_p} = 1 - $ret{F}->gsl_cdf_fdist_P( $ret{F_df}->dog )
    if $CDF;

  for (keys %ret) { ref $ret{$_} eq 'PDLA' and $ret{$_} = $ret{$_}->squeeze };

  $ret{b} = $coeff;

  return %ret;
}

=head2 r2_change

=for ref

Significance test for the incremental change in R2 when new variable(s) are added to an ols regression model. Returns the change stats as well as stats for both models. Based on B<ols_t>. (One way to make up for the lack of significance tests for coeffs in ols_t).

=for options

Default options (case insensitive): 

    CONST   => 1,

=for usage

Usage:

    # suppose these are two persons' ratings for top 10 box office movies
    # ascending sorted by box office

    perldl> p $y = qsort ceil(random(10, 2) * 5)
    [
     [1 1 2 2 2 3 4 4 4 4]
     [1 2 2 3 3 3 4 4 5 5]
    ]

    # first IV is a simple linear trend

    perldl> p $x1 = sequence 10
    [0 1 2 3 4 5 6 7 8 9]

    # the modeler wonders if adding a quadratic trend improves the fit

    perldl> p $x2 = sequence(10) ** 2
    [0 1 4 9 16 25 36 49 64 81]

    # two difference models are given in two pdls
    # each as would be pass on to ols_t
    # the 1st model includes only linear trend
    # the 2nd model includes linear and quadratic trends
    # when necessary use dummy dim so both models have the same ndims

    perldl> %c = $y->r2_change( $x1->dummy(1), cat($x1, $x2) )

    perldl> p "$_\t$c{$_}\n" for (sort keys %c)
      #              person 1   person 2
    F_change        [0.72164948 0.071283096]
      # df same for both persons
    F_df    [1 7]
    F_p     [0.42370145 0.79717232]
    R2_change       [0.0085966043 0.00048562549]
    model0  HASH(0x8c10828)
    model1  HASH(0x8c135c8)
   
    # the answer here is no.

=cut

*r2_change = \&PDLA::r2_change;
sub PDLA::r2_change {
  my ($self, $ivs0, $ivs1, $opt) = @_;
  $ivs0->getndims == 1 and $ivs0 = $ivs0->dummy(1);

  my %ret;

  $ret{model0} = { $self->ols_t( $ivs0, $opt ) };
  $ret{model1} = { $self->ols_t( $ivs1, $opt ) };

  $ret{R2_change} = $ret{model1}->{R2} - $ret{model0}->{R2};
  $ret{F_df}
    = pdl($ivs1->dim(1) - $ivs0->dim(1),
          $ret{model1}->{F_df}->((1)) );
  $ret{F_change}
    = $ret{R2_change} * $ret{F_df}->((1))
    / ( (1-$ret{model1}->{R2}) * $ret{F_df}->((0)) );
  $ret{F_p} = 1 - $ret{F_change}->gsl_cdf_fdist_P( $ret{F_df}->dog )
    if $CDF;

  for (keys %ret) { ref $ret{$_} eq 'PDLA' and $ret{$_} = $ret{$_}->squeeze };

  return %ret;
}

=head1 METHODS

=head2 anova

=for ref

Analysis of variance. Uses type III sum of squares for unbalanced data.

Dependent variable should be a 1D pdl. Independent variables can be passed as 1D perl array ref or 1D pdl.

Supports bad value (by ignoring missing or BAD values in dependent and independent variables list-wise).

=for options

Default options (case insensitive):

    V      => 1,          # carps if bad value in variables
    IVNM   => [],         # auto filled as ['IV_0', 'IV_1', ... ]
    PLOT   => 1,          # plots highest order effect
                          # can set plot_means options here

=for usage

Usage:

    # suppose this is ratings for 12 apples

    perldl> p $y = qsort ceil( random(12)*5 )
    [1 1 2 2 2 3 3 4 4 4 5 5]
    
    # IV for types of apple

    perldl> p $a = sequence(12) % 3 + 1
    [1 2 3 1 2 3 1 2 3 1 2 3]

    # IV for whether we baked the apple
    
    perldl> @b = qw( y y y y y y n n n n n n )

    perldl> %m = $y->anova( $a, \@b, { IVNM=>['apple', 'bake'] } )
    
    perldl> p "$_\t$m{$_}\n" for (sort keys %m)
    # apple # m
    [
     [2.5   3 3.5]
    ]
    
    # apple # se
    [
     [0.64549722 0.91287093 0.64549722]
    ]
    
    # apple ~ bake # m
    [
     [1.5 1.5 2.5]
     [3.5 4.5 4.5]
    ]
    
    # apple ~ bake # se
    [
     [0.5 0.5 0.5]
     [0.5 0.5 0.5]
    ]
    
    # bake # m
    [
     [ 1.8333333  4.1666667]
    ]
    
    # bake # se
    [
     [0.30731815 0.30731815]
    ]
    
    F       7.6
    F_df    [5 6]
    F_p     0.0141586545851857
    ms_model        3.8
    ms_residual     0.5
    ss_model        19
    ss_residual     3
    ss_total        22
    | apple | F     2
    | apple | F_df  [2 6]
    | apple | F_p   0.216
    | apple | ms    1
    | apple | ss    2
    | apple ~ bake | F      0.666666666666667
    | apple ~ bake | F_df   [2 6]
    | apple ~ bake | F_p    0.54770848985725
    | apple ~ bake | ms     0.333333333333334
    | apple ~ bake | ss     0.666666666666667
    | bake | F      32.6666666666667
    | bake | F_df   [1 6]
    | bake | F_p    0.00124263849516693
    | bake | ms     16.3333333333333
    | bake | ss     16.3333333333333

=cut

*anova = \&PDLA::anova;
sub PDLA::anova {
  my $opt = pop @_
    if ref $_[-1] eq 'HASH';
  my ($y, @ivs_raw) = @_;
  croak "Mismatched number of elements in DV and IV. Are you passing IVs the old-and-abandoned way?"
    if (ref $ivs_raw[0] eq 'ARRAY') and (@{ $ivs_raw[0] } != $y->nelem);

  for (@ivs_raw) {
    croak "too many dims in IV!"
      if ref $_ eq 'PDLA' and $_->squeeze->ndims > 1;
  }

  my %opt = (
    IVNM   => [],      # auto filled as ['IV_0', 'IV_1', ... ]
    PLOT   => 1,       # plots highest order effect
    V      => 1,       # carps if bad value
  );
  $opt and $opt{uc $_} = $opt->{$_} for (keys %$opt);
  $opt{IVNM} = [ map { "IV_$_" } (0 .. $#ivs_raw) ]
    if !$opt{IVNM} or !@{$opt{IVNM}};
  my @idv = @{ $opt{IVNM} };

  my %ret;

  $y = $y->squeeze;
    # create new vars here so we don't mess up original caller @
  my @pdl_ivs_raw = map {
    my $var = (ref $_ eq 'PDLA')? [list $_] : $_;
    scalar PDLA::Stats::Basic::_array_to_pdl $var;
  } @ivs_raw;

  my $pdl_ivs_raw = pdl \@pdl_ivs_raw;
    # explicit set badflag if any iv had bad value because pdl() removes badflag
  $pdl_ivs_raw->badflag( scalar grep { $_->badflag } @pdl_ivs_raw );

  ($y, $pdl_ivs_raw) = _rm_bad_value( $y, $pdl_ivs_raw );

  if ($opt{V} and $y->nelem < $pdl_ivs_raw[0]->nelem) {
    printf STDERR "%d subjects with missing data removed\n", $pdl_ivs_raw[0]->nelem - $y->nelem;
  }

    # dog preserves data flow
  @pdl_ivs_raw = map {$_->copy} $pdl_ivs_raw->dog;

  my ($ivs_ref, $i_cmo_ref)
    = _effect_code_ivs( \@pdl_ivs_raw );

  ($ivs_ref, $i_cmo_ref, my( $idv, $ivs_cm_ref ))
    = _add_interactions( $ivs_ref, $i_cmo_ref, \@idv, \@pdl_ivs_raw );

    # add const here
  my $ivs = PDLA->null->glue( 1, @$ivs_ref );
  $ivs = $ivs->glue(1, ones $ivs->dim(0));

  my $b_full = $y->ols_t( $ivs, {CONST=>0} );

  $ret{ss_total} = $y->ss;
  $ret{ss_residual} = $y->sse( sumover( $b_full * $ivs->xchg(0,1) ) );
  $ret{ss_model} = $ret{ss_total} - $ret{ss_residual};
  $ret{F_df} = pdl($ivs->dim(1) - 1, $y->nelem - ($ivs->dim(1) - 1) -1);
  $ret{ms_model} = $ret{ss_model} / $ret{F_df}->(0);
  $ret{ms_residual} = $ret{ss_residual} / $ret{F_df}->(1);
  $ret{F} = $ret{ms_model} / $ret{ms_residual};
  $ret{F_p} = 1 - $ret{F}->gsl_cdf_fdist_P( $ret{F_df}->dog )
    if $CDF;

  # get IV ss from $ivs_ref instead of $ivs pdl

  for my $k (0 .. $#$ivs_ref) {
    my (@G, $G, $b_G);
    @G = grep { $_ != $k } (0 .. $#$ivs_ref);
 
    if (@G) {
      $G = PDLA->null->glue( 1, @$ivs_ref[@G] );
      $G = $G->glue(1, ones $G->dim(0));
    }
    else {
      $G = ones( $y->dim(0) );
    }
    $b_G = $y->ols_t( $G, {CONST=>0} );

    $ret{ "| $idv->[$k] | ss" }
      = $y->sse( sumover($b_G * $G->transpose) ) - $ret{ss_residual};
    $ret{ "| $idv->[$k] | F_df" }
      = pdl( $ivs_ref->[$k]->dim(1), $ret{F_df}->(1)->copy )->squeeze;
    $ret{ "| $idv->[$k] | ms" }
      = $ret{ "| $idv->[$k] | ss" } / $ret{ "| $idv->[$k] | F_df" }->(0);
    $ret{ "| $idv->[$k] | F" }
      = $ret{ "| $idv->[$k] | ms" } / $ret{ms_residual};
    $ret{ "| $idv->[$k] | F_p" }
      = 1 - $ret{ "| $idv->[$k] | F" }->gsl_cdf_fdist_P( $ret{ "| $idv->[$k] | F_df" }->dog )
      if $CDF;
  }

  for (keys %ret) { $ret{$_} = $ret{$_}->squeeze };

  my $cm_ref = _cell_means( $y, $ivs_cm_ref, $i_cmo_ref, $idv, \@pdl_ivs_raw );
    # sort bc we can't count on perl % internal key order implementation
  @ret{ sort keys %$cm_ref } = @$cm_ref{ sort keys %$cm_ref };

  my $highest = join(' ~ ', @{ $opt{IVNM} });
  $cm_ref->{"# $highest # m"}->plot_means( $cm_ref->{"# $highest # se"}, {%opt, IVNM=>$idv} )
    if $opt{PLOT};

  return %ret;
}

sub _old_interface_check {
  my ($n, $ivs_ref) = @_;
  return 1
    if (ref $ivs_ref->[0][0] eq 'ARRAY') and (@{ $ivs_ref->[0][0] } != $n);
}

sub _effect_code_ivs {
  my $ivs = shift;

  my (@i_iv, @i_cmo);
  for (@$ivs) {
    my ($e, $map) = effect_code($_->squeeze);
    my $var = ($e->getndims == 1)? $e->dummy(1) : $e;
    push @i_iv, $var;
    my @indices = sort { $a<=>$b } values %$map;
    push @i_cmo, pdl @indices;
  }
  return \@i_iv, \@i_cmo;
}

sub _add_interactions {
  my ($var_ref, $i_cmo_ref, $idv, $raw_ref) = @_;

    # append info re inter to main effects
  my (@inter, @idv_inter, @inter_cm, @inter_cmo);
  for my $nway ( 2 .. @$var_ref ) {
    my $iter_idv = _combinations( $nway, [0..$#$var_ref] );

    while ( my @v = &$iter_idv() ) {
      my $i = ones( $var_ref->[0]->dim(0), 1 );
      for (@v) {
        $i = $i * $var_ref->[$_]->dummy(1);
        $i = $i->clump(1,2);
      }
      push @inter, $i;

      my $e = join( ' ~ ', @$idv[@v] );
      push @idv_inter, $e;

        # now prepare for cell mean
      my @i_cm = ();
      for my $o ( 0 .. $raw_ref->[0]->dim(0) - 1 ) {
        my @cell = map { $_($o)->squeeze } @$raw_ref[@v];
        push @i_cm, join('', @cell); 
      }
      my ($inter, $map) = effect_code( \@i_cm );
      push @inter_cm, $inter;

        # get the order to put means in correct multi dim pdl pos
        # this is order in var_e dim(1)
      my @levels = sort { $map->{$a} <=> $map->{$b} } keys %$map;
        # this is order needed for cell mean
      my @i_cmo  = sort { reverse($levels[$a]) cmp reverse($levels[$b]) }
                        0 .. $#levels;
      push @inter_cmo, pdl @i_cmo;
    }
  }
    # append info re inter to main effects
  return ([@$var_ref, @inter], [@$i_cmo_ref, @inter_cmo],
          [@$idv, @idv_inter], [@$var_ref, @inter_cm]     );
}

sub _cell_means {
  my ($data, $ivs_ref, $i_cmo_ref, $ids, $raw_ref) = @_;

  my %ind_id;
  @ind_id{ @$ids } = 0..$#$ids;

  my %cm;
  my $i = 0;
  for (@$ivs_ref) {
    my $last = zeroes $_->dim(0);
    my $i_neg = which $_( ,0) == -1;
    ($_tmp = $last($i_neg)) .= 1;
    ($_tmp = $_->where($_ == -1)) .= 0;
    $_ = $_->glue(1, $last);

    my @v = split ' ~ ', $ids->[$i];
    my @shape = map { $raw_ref->[$_]->uniq->nelem } @ind_id{@v};

    my ($m, $ss) = $data->centroid( $_ );
    $m  = $m($i_cmo_ref->[$i])->sever;
    $ss = $ss($i_cmo_ref->[$i])->sever;
    $m = $m->reshape(@shape);
    $m->getndims == 1 and $m = $m->dummy(1);
    my $se = sqrt( ($ss/($_->sumover - 1)) / $_->sumover )->reshape(@shape);
    $se->getndims == 1 and $se = $se->dummy(1);
    $cm{ "# $ids->[$i] # m" }  = $m;
    $cm{ "# $ids->[$i] # se" } = $se;
    $i++;
  }
  return \%cm;
}

  # http://www.perlmonks.org/?node_id=371228
sub _combinations {
  my ($num, $arr) = @_;

  return sub { return }
    if $num == 0 or $num > @$arr;

  my @pick;

  return sub {
    return @$arr[ @pick = ( 0 .. $num - 1 ) ]
      unless @pick;
    
    my $i = $#pick;
    $i-- until $i < 0 or $pick[$i]++ < @$arr - $num + $i;
    return if $i < 0;

    @pick[$i .. $#pick] = $pick[$i] .. $#$arr;
    
    return @$arr[@pick];
  };
}

=head2 anova_rptd

Repeated measures and mixed model anova. Uses type III sum of squares. The standard error (se) for the means are based on the relevant mean squared error from the anova, ie it is pooled across levels of the effect.

anova_rptd supports bad value in the dependent and independent variables. It automatically removes bad data listwise, ie remove a subject's data if there is any cell missing for the subject.

Default options (case insensitive):

    V      => 1,    # carps if bad value in dv
    IVNM   => [],   # auto filled as ['IV_0', 'IV_1', ... ]
    BTWN   => [],   # indices of between-subject IVs (matches IVNM indices)
    PLOT   => 1,    # plots highest order effect
                    # see plot_means() for more options

Usage:

    Some fictional data: recall_w_beer_and_wings.txt
  
    Subject Beer    Wings   Recall
    Alex    1       1       8
    Alex    1       2       9
    Alex    1       3       12
    Alex    2       1       7
    Alex    2       2       9
    Alex    2       3       12
    Brian   1       1       12
    Brian   1       2       13
    Brian   1       3       14
    Brian   2       1       9
    Brian   2       2       8
    Brian   2       3       14
    ...
  
      # rtable allows text only in 1st row and col
    my ($data, $idv, $subj) = rtable 'recall_w_beer_and_wings.txt';
  
    my ($b, $w, $dv) = $data->dog;
      # subj and IVs can be 1d pdl or @ ref
      # subj must be the first argument
    my %m = $dv->anova_rptd( $subj, $b, $w, {ivnm=>['Beer', 'Wings']} );
  
    print "$_\t$m{$_}\n" for (sort keys %m);

    # Beer # m	
    [
     [ 10.916667  8.9166667]
    ]
    
    # Beer # se	
    [
     [ 0.4614791  0.4614791]
    ]
    
    # Beer ~ Wings # m	
    [
     [   10     7]
     [ 10.5  9.25]
     [12.25  10.5]
    ]
    
    # Beer ~ Wings # se	
    [
     [0.89170561 0.89170561]
     [0.89170561 0.89170561]
     [0.89170561 0.89170561]
    ]
    
    # Wings # m	
    [
     [   8.5  9.875 11.375]
    ]
    
    # Wings # se	
    [
     [0.67571978 0.67571978 0.67571978]
    ]
    
    ss_residual	19.0833333333333
    ss_subject	24.8333333333333
    ss_total	133.833333333333
    | Beer | F	9.39130434782609
    | Beer | F_p	0.0547977008378944
    | Beer | df	1
    | Beer | ms	24
    | Beer | ss	24
    | Beer || err df	3
    | Beer || err ms	2.55555555555556
    | Beer || err ss	7.66666666666667
    | Beer ~ Wings | F	0.510917030567687
    | Beer ~ Wings | F_p	0.623881438624431
    | Beer ~ Wings | df	2
    | Beer ~ Wings | ms	1.625
    | Beer ~ Wings | ss	3.25000000000001
    | Beer ~ Wings || err df	6
    | Beer ~ Wings || err ms	3.18055555555555
    | Beer ~ Wings || err ss	19.0833333333333
    | Wings | F	4.52851711026616
    | Wings | F_p	0.0632754786153548
    | Wings | df	2
    | Wings | ms	16.5416666666667
    | Wings | ss	33.0833333333333
    | Wings || err df	6
    | Wings || err ms	3.65277777777778
    | Wings || err ss	21.9166666666667

For mixed model anova, ie when there are between-subject IVs involved, feed the IVs as above, but specify in BTWN which IVs are between-subject. For example, if we had added age as a between-subject IV in the above example, we would do 

    my %m = $dv->anova_rptd( $subj, $age, $b, $w,
                           { ivnm=>['Age', 'Beer', 'Wings'], btwn=>[0] });
 
=cut

*anova_rptd = \&PDLA::anova_rptd;
sub PDLA::anova_rptd {
  my $opt = pop @_
    if ref $_[-1] eq 'HASH';
  my ($y, $subj, @ivs_raw) = @_;

  for (@ivs_raw) {
    croak "too many dims in IV!"
      if ref $_ eq 'PDLA' and $_->squeeze->ndims > 1
  }

  my %opt = (
    V      => 1,    # carps if bad value in dv
    IVNM   => [],   # auto filled as ['IV_0', 'IV_1', ... ]
    BTWN   => [],   # indices of between-subject IVs (matches IVNM indices)
    PLOT   => 1,    # plots highest order effect
  );
  $opt and $opt{uc $_} = $opt->{$_} for (keys %$opt);
  $opt{IVNM} = [ map { "IV_$_" } 0 .. $#ivs_raw ]
    if !$opt{IVNM} or !@{ $opt{IVNM} };
  my @idv = @{ $opt{IVNM} };

  my %ret;

    # create new vars here so we don't mess up original caller @
  my ($sj, @pdl_ivs_raw)
    = map { my $var = (ref $_ eq 'PDLA')? [list $_] : $_;
            scalar PDLA::Stats::Basic::_array_to_pdl $var;
          } ( $subj, @ivs_raw );

    # delete bad data listwise ie remove subj if any cell missing
  $y = $y->squeeze;
  my $pdl_ivs_raw = pdl \@pdl_ivs_raw;
    # explicit set badflag because pdl() removes badflag
  $pdl_ivs_raw->badflag( scalar grep { $_->badflag } @pdl_ivs_raw );

  my $ibad = which( $y->isbad | nbadover($pdl_ivs_raw->transpose) );

  my $sj_bad = $sj($ibad)->uniq;
  if ($sj_bad->nelem) {
    print STDERR $sj_bad->nelem . " subjects with missing data removed\n"
      if $opt{V};
    $sj = $sj->setvaltobad($_)
      for (list $sj_bad);
    my $igood = which $sj->isgood;
    for ($y, $sj, @pdl_ivs_raw) {
      $_ = $_( $igood )->sever;
      $_->badflag(0);
    }
  }
    # code for ivs and cell mean in diff @s: effect_code vs iv_cluster
  my ($ivs_ref, $i_cmo_ref)
    = _effect_code_ivs( \@pdl_ivs_raw );

  ($ivs_ref, $i_cmo_ref, my( $idv, $ivs_cm_ref))
    = _add_interactions( $ivs_ref, $i_cmo_ref, \@idv, \@pdl_ivs_raw );

    # matches $ivs_ref, with an extra last pdl for subj effect
  my $err_ref
    = _add_errors( $sj, $ivs_ref, $idv, \@pdl_ivs_raw, \%opt );

    # stitch together
  my $ivs = PDLA->null->glue( 1, @$ivs_ref );
  $ivs = $ivs->glue(1, grep { defined($_) and ref($_) } @$err_ref);
  $ivs = $ivs->glue(1, ones $ivs->dim(0));
  my $b_full = $y->ols_t( $ivs, {CONST=>0} );

  $ret{ss_total} = $y->ss;
  $ret{ss_residual} = $y->sse( sumover( $b_full * $ivs->xchg(0,1) ) );

  my @full = (@$ivs_ref, @$err_ref);
  EFFECT: for my $k (0 .. $#full) {
    my $e = ($k > $#$ivs_ref)?  '| err' : '';
    my $i = ($k > $#$ivs_ref)?  $k - @$ivs_ref : $k;

    if (!defined $full[$k]) {     # ss_residual as error
      $ret{ "| $idv->[$i] |$e ss" } = $ret{ss_residual};
        # highest ord inter for purely within design, (p-1)*(q-1)*(n-1)
      $ret{ "| $idv->[$i] |$e df" }
        = pdl(map { $_->dim(1) } @full[0 .. $#ivs_raw])->prodover;
      $ret{ "| $idv->[$i] |$e df" }
        *= ref($full[-1])?   $full[-1]->dim(1)
        :                    $err_ref->[$err_ref->[-1]]->dim(1)
        ;
      $ret{ "| $idv->[$i] |$e ms" }
        = $ret{ "| $idv->[$i] |$e ss" } / $ret{ "| $idv->[$i] |$e df" };
    }
    elsif (ref $full[$k]) {       # unique error term
      my (@G, $G, $b_G);
      @G = grep { $_ != $k and defined $full[$_] } (0 .. $#full);
   
      next EFFECT
        unless @G;
  
      $G = PDLA->null->glue( 1, grep { ref $_ } @full[@G] );
      $G = $G->glue(1, ones $G->dim(0));
      $b_G = $y->ols_t( $G, {CONST=>0} );
  
      if ($k == $#full) {
        $ret{ss_subject}
          = $y->sse(sumover($b_G * $G->transpose)) - $ret{ss_residual};
      }
      else {
        $ret{ "| $idv->[$i] |$e ss" }
          = $y->sse(sumover($b_G * $G->transpose)) - $ret{ss_residual};
        $ret{ "| $idv->[$i] |$e df" }
          = $full[$k]->dim(1);
        $ret{ "| $idv->[$i] |$e ms" }
          = $ret{ "| $idv->[$i] |$e ss" } / $ret{ "| $idv->[$i] |$e df" };
      }
    }
    else {                        # repeating error term
      if ($k == $#full) {
        $ret{ss_subject} = $ret{"| $idv->[$full[$k]] |$e ss"};
      }
      else {
        $ret{ "| $idv->[$i] |$e ss" } = $ret{"| $idv->[$full[$k]] |$e ss"};
        $ret{ "| $idv->[$i] |$e df" } = $ret{"| $idv->[$full[$k]] |$e df"};
        $ret{ "| $idv->[$i] |$e ms" }
          = $ret{ "| $idv->[$i] |$e ss" } / $ret{ "| $idv->[$i] |$e df" };
      }
    }
  }
    # have all iv, inter, and error effects. get F and F_p
  for (0 .. $#$ivs_ref) {
    $ret{ "| $idv->[$_] | F" }
      = $ret{ "| $idv->[$_] | ms" } / $ret{ "| $idv->[$_] || err ms" };
    $ret{ "| $idv->[$_] | F_p" }
      = 1 - $ret{ "| $idv->[$_] | F" }->gsl_cdf_fdist_P(
        $ret{ "| $idv->[$_] | df" }, $ret{ "| $idv->[$_] || err df" } )
      if $CDF;
  }

  for (keys %ret) {ref $ret{$_} eq 'PDLA' and $ret{$_} = $ret{$_}->squeeze};

  my $cm_ref
    = _cell_means( $y, $ivs_cm_ref, $i_cmo_ref, $idv, \@pdl_ivs_raw );
  my @ls = map { $_->uniq->nelem } @pdl_ivs_raw;
  $cm_ref
    = _fix_rptd_se( $cm_ref, \%ret, $opt{'IVNM'}, \@ls, $sj->uniq->nelem );

    # integrate mean and se into %ret
    # sort bc we can't count on perl % internal key order implementation
  @ret{ sort keys %$cm_ref } = @$cm_ref{ sort keys %$cm_ref };

  my $highest = join(' ~ ', @{ $opt{IVNM} });
  $cm_ref->{"# $highest # m"}->plot_means( $cm_ref->{"# $highest # se"}, 
                                           { %opt, IVNM=>$idv } )
    if $opt{PLOT};

  return %ret;
}

sub _add_errors {
  my ($subj, $ivs_ref, $idv, $raw_ivs, $opt) = @_;

  # code (btwn group) subjects. Rutherford (2001) pp 101-102 

  my (@grp, %grp_s);
  for my $n (0 .. $subj->nelem - 1) {
      # construct string to code group membership
      # something not treated as BAD by _array_to_pdl to start off marking group membership
      # if no $opt->{BTWN}, everyone ends up in the same grp
    my $s = '_';
    $s .= $_->($n)
      for (@$raw_ivs[@{ $opt->{BTWN} }]);
    push @grp, $s;                 # group membership
    $s .= $subj($n);               # keep track of total uniq subj
    $grp_s{$s} = 1;
  }
  my $grp = PDLA::Stats::Kmeans::iv_cluster \@grp;

  my $spdl = zeroes $subj->dim(0), keys(%grp_s) - $grp->dim(1);
  my ($d0, $d1) = (0, 0);
  for my $g (0 .. $grp->dim(1)-1) {
    my $gsub = $subj( which $grp( ,$g) )->effect_code;
    my ($nobs, $nsub) = $gsub->dims;
    ($_tmp = $spdl($d0:$d0+$nobs-1, $d1:$d1+$nsub-1)) .= $gsub;
    $d0 += $nobs;
    $d1 += $nsub;
  }

  # if btwn factor involved, or highest order inter for within factors
  # elem is undef, so that
  # @errors ind matches @$ivs_ref, with an extra elem at the end for subj

    # mark btwn factors for error terms
    # same error term for B(wn) and A(btwn) x B(wn) (Rutherford, p98)
  my @qr = map { "(?:$idv->[$_])" } @{ $opt->{BTWN} };
  my $qr = join('|', @qr);

  my $ie_subj;
  my @errors = map
    { my @fs = split ' ~ ', $idv->[$_];
        # separate bw and wn factors
        # if only bw, error is bw x subj
        # if only wn or wn and bw, error is wn x subj
      my (@wn, @bw);
      if ($qr) {
        for (@fs) {
          /$qr/? push @bw, $_ : push @wn, $_;
        }
      }
      else {
        @wn = @fs;
      }
      $ie_subj = defined($ie_subj)? $ie_subj : $_
        if !@wn;

      my $err = @wn? join(' ~ ', @wn) : join(' ~ ', @bw);
      my $ie;               # mark repeating error term
      for my $i (0 .. $#$ivs_ref) {
        if ($idv->[$i] eq $err) {
          $ie = $i;
          last;
        }
      }

        # highest order inter of within factors, use ss_residual as error
      if ( @wn == @$raw_ivs - @{$opt->{BTWN}} )                   { undef }
        # repeating btwn factors use ss_subject as error
      elsif (!@wn and $_ > $ie_subj)                           { $ie_subj }
        # repeating error term
      elsif ($_ > $ie)                                              { $ie }
      else            { PDLA::clump($ivs_ref->[$_] * $spdl->dummy(1), 1,2) }
    } 0 .. $#$ivs_ref;

  @{$opt->{BTWN}}? push @errors, $ie_subj : push @errors, $spdl;

  return \@errors;
}

sub _fix_rptd_se {
    # if ivnm lvls_ref for within ss only this can work for mixed design
  my ($cm_ref, $ret, $ivnm, $lvls_ref, $n) = @_;

  my @se = grep /se$/, keys %$cm_ref;
  @se = map { /^# (.+?) # se$/; $1; } @se;

  my @n_obs
    = map {
        my @ivs = split / ~ /, $_;
        my $i_ivs = which_id $ivnm, \@ivs;
        my $icollapsed = setops pdl(0 .. $#$ivnm), 'XOR', $i_ivs;
        
        my $collapsed = $icollapsed->nelem?
                          pdl( @$lvls_ref[(list $icollapsed)] )->prodover
                      :   1
                      ;
        $n * $collapsed;
      } @se;

  for my $i (0 .. $#se) {
    ($_tmp = $cm_ref->{"# $se[$i] # se"})
      .= sqrt( $ret->{"| $se[$i] || err ms"} / $n_obs[$i] );
  }

  return $cm_ref;
}

=head2 dummy_code

=for ref

Dummy coding of nominal variable (perl @ ref or 1d pdl) for use in regression.

Supports BAD value (missing or 'BAD' values result in the corresponding pdl elements being marked as BAD).

=for usage

    perldl> @a = qw(a a a b b b c c c)
    perldl> p $a = dummy_code(\@a)
    [
     [1 1 1 0 0 0 0 0 0]
     [0 0 0 1 1 1 0 0 0]
    ]

=cut

*dummy_code = \&PDLA::dummy_code;
sub PDLA::dummy_code {
  my ($var_ref) = @_;

  my $var_e = effect_code( $var_ref );

  ($_tmp = $var_e->where( $var_e == -1 )) .= 0;

  return $var_e;
}

=head2 effect_code

=for ref

Unweighted effect coding of nominal variable (perl @ ref or 1d pdl) for use in regression. returns in @ context coded pdl and % ref to level - pdl->dim(1) index.

Supports BAD value (missing or 'BAD' values result in the corresponding pdl elements being marked as BAD).

=for usage

    my @var = qw( a a a b b b c c c );
    my ($var_e, $map) = effect_code( \@var );

    print $var_e . $var_e->info . "\n";
    
    [
     [ 1  1  1  0  0  0 -1 -1 -1]
     [ 0  0  0  1  1  1 -1 -1 -1]
    ]    
    PDLA: Double D [9,2]

    print "$_\t$map->{$_}\n" for (sort keys %$map)
    a       0
    b       1
    c       2

=cut

*effect_code = \&PDLA::effect_code;
sub PDLA::effect_code {
  my ($var_ref) = @_;

    # pdl->uniq sorts elems. so instead list it to maintain old order
  if (ref $var_ref eq 'PDLA') {
    $var_ref = $var_ref->squeeze;
    $var_ref->getndims > 1 and
      croak "multidim pdl passed for single var!";
    $var_ref = [ list $var_ref ];
  }

  my ($var, $map_ref) = PDLA::Stats::Basic::_array_to_pdl( $var_ref );
  my $var_e = zeroes float, $var->nelem, $var->max;

  for my $l (0 .. $var->max - 1) {
    my $v = $var_e( ,$l);
    ($_tmp = $v->index( which $var == $l )) .= 1;
    ($_tmp = $v->index( which $var == $var->max )) .= -1;
  }

  if ($var->badflag) {
    my $ibad = which $var->isbad;
    ($_tmp = $var_e($ibad, )) .= -99;
    $var_e = $var_e->setvaltobad(-99);
  }

  return wantarray? ($var_e, $map_ref) : $var_e;
}

=head2 effect_code_w

=for ref

Weighted effect code for nominal variable. returns in @ context coded pdl and % ref to level - pdl->dim(1) index.

Supports BAD value (missing or 'BAD' values result in the corresponding pdl elements being marked as BAD).

=for usage

    perldl> @a = qw( a a b b b c c )
    perldl> p $a = effect_code_w(\@a)
    [
     [   1    1    0    0    0   -1   -1]
     [   0    0    1    1    1 -1.5 -1.5]
    ]

=cut

*effect_code_w = \&PDLA::effect_code_w;
sub PDLA::effect_code_w {
  my ($var_ref) = @_;

  my ($var_e, $map_ref) = effect_code( $var_ref );

  if ($var_e->sum == 0) {
    return wantarray? ($var_e, $map_ref) : $var_e;
  }

  for (0..$var_e->dim(1)-1) {
    my $factor = $var_e( ,$_);
    my $pos = which $factor == 1;
    my $neg = which $factor == -1;
    my $w = $pos->nelem / $neg->nelem;
    ($_tmp = $factor($neg)) *= $w;
  }

  return wantarray? ($var_e, $map_ref) : $var_e;
}

=head2 interaction_code

Returns the coded interaction term for effect-coded variables.

Supports BAD value (missing or 'BAD' values result in the corresponding pdl elements being marked as BAD).

=for usage

    perldl> $a = sequence(6) > 2      
    perldl> p $a = $a->effect_code
    [
     [ 1  1  1 -1 -1 -1]
    ]
    
    perldl> $b = pdl( qw( 0 1 2 0 1 2 ) )            
    perldl> p $b = $b->effect_code
    [
     [ 1  0 -1  1  0 -1]
     [ 0  1 -1  0  1 -1]
    ]
    
    perldl> p $ab = interaction_code( $a, $b )
    [
     [ 1  0 -1 -1 -0  1]
     [ 0  1 -1 -0 -1  1]
    ]

=cut

*interaction_code = \&PDLA::interaction_code;
sub PDLA::interaction_code {
  my @vars = @_;

  my $i = ones( $vars[0]->dim(0), 1 );
  for (@vars) {
    $i = $i * $_->dummy(1);
    $i = $i->clump(1,2);
  }

  return $i;
}

=head2 ols

=for ref

Ordinary least squares regression, aka linear regression. Unlike B<ols_t>, ols is not threadable, but it can handle bad value (by ignoring observations with bad value in dependent or independent variables list-wise) and returns the full model in list context with various stats. 

IVs ($x) should be pdl dims $y->nelem or $y->nelem x n_iv. Do not supply the constant vector in $x. Intercept is automatically added and returned as LAST of the coeffs if CONST=>1. Returns full model in list context and coeff in scalar context.

=for options

Default options (case insensitive): 

    CONST  => 1,
    PLOT   => 1,   # see plot_residuals() for plot options

=for usage

Usage:

    # suppose this is a person's ratings for top 10 box office movies
    # ascending sorted by box office

    perldl> p $y = qsort ceil( random(10) * 5 )
    [1 1 2 2 2 2 4 4 5 5]

    # construct IV with linear and quadratic component

    perldl> p $x = cat sequence(10), sequence(10)**2
    [
     [ 0  1  2  3  4  5  6  7  8  9]
     [ 0  1  4  9 16 25 36 49 64 81]
    ]

    perldl> %m = $y->ols( $x )

    perldl> p "$_\t$m{$_}\n" for (sort keys %m)

    F       40.4225352112676
    F_df    [2 7]
    F_p     0.000142834216344756
    R2      0.920314253647587
 
    # coeff  linear     quadratic  constant
 
    b       [0.21212121 0.03030303 0.98181818]
    b_p     [0.32800118 0.20303404 0.039910509]
    b_se    [0.20174693 0.021579989 0.38987581]
    b_t     [ 1.0514223   1.404219  2.5182844]
    ss_model        19.8787878787879
    ss_residual     1.72121212121212
    ss_total        21.6
    y_pred  [0.98181818  1.2242424  1.5272727  ...  4.6181818  5.3454545]
 
=cut

*ols = \&PDLA::ols;
sub PDLA::ols {
    # y [n], ivs [n x attr] pdl
  my ($y, $ivs, $opt) = @_;
  my %opt = (
    CONST => 1,
    PLOT  => 1,
  );
  $opt and $opt{uc $_} = $opt->{$_} for (keys %$opt);

  $y = $y->squeeze;
  $y->getndims > 1 and
    croak "use ols_t for threaded version";

  $ivs = $ivs->dummy(1) if $ivs->getndims == 1;

  ($y, $ivs) = _rm_bad_value( $y, $ivs );

    # set up ivs and const as ivs
  $opt{CONST} and
    $ivs = $ivs->glue( 1, ones($ivs->dim(0)) );

  # Internally normalise data
  
  my $ymean = (abs($y)->sum)/($y->nelem);
  $ymean = 1 if $ymean == 0;
  my $y2 = $y / $ymean;
 
  # Do the fit
     
  my $Y = $ivs x $y2->dummy(0);

  my $C;
  if ( $SLATEC ) {
    $C = PDLA::Slatec::matinv( $ivs x $ivs->xchg(0,1) );
  }
  else {
    $C = inv( $ivs x $ivs->xchg(0,1) );
  }

    # Fitted coefficients vector
  my $coeff = PDLA::squeeze( $C x $Y );
     $coeff *= $ymean;        # Un-normalise

  my %ret;

    # ***$coeff x $ivs looks nice but produces nan on successive tries***
  $ret{y_pred} = sumover( $coeff * $ivs->transpose );

  $opt{PLOT} and $y->plot_residuals( $ret{y_pred}, \%opt );

  return $coeff
    unless wantarray;

  $ret{b} = $coeff;
  $ret{ss_total} = $opt{CONST}? $y->ss : sum( $y ** 2 );
  $ret{ss_residual} = $y->sse( $ret{y_pred} );
  $ret{ss_model} = $ret{ss_total} - $ret{ss_residual};
  $ret{R2} = $ret{ss_model} / $ret{ss_total};

  my $n_var = $opt{CONST}? $ivs->dim(1) - 1 : $ivs->dim(1);
  $ret{F_df} = pdl( $n_var, $y->nelem - $ivs->dim(1) );
  $ret{F} = $ret{ss_model} / $ret{F_df}->(0)
          / ( $ret{ss_residual} / $ret{F_df}->(1) );
  $ret{F_p} = 1 - $ret{F}->gsl_cdf_fdist_P( $ret{F_df}->dog )
    if $CDF;

  my $se_b = ones( $coeff->dims? $coeff->dims : 1 );

  $opt{CONST} and 
    ($_tmp = $se_b(-1)) .= sqrt( $ret{ss_residual} / $ret{F_df}->(1) * $C(-1,-1) );

    # get the se for bs by successivly regressing each iv by the rest ivs
  if ($ivs->dim(1) > 1) {
    for my $k (0 .. $n_var-1) {
      my @G = grep { $_ != $k } (0 .. $n_var-1);
      my $G = $ivs->dice_axis(1, \@G);
      $opt{CONST} and
        $G = $G->glue( 1, ones($ivs->dim(0)) );
      my $b_G = $ivs( ,$k)->ols( $G, {CONST=>0,PLOT=>0} );

      my $ss_res_k = $ivs( ,$k)->squeeze->sse( sumover($b_G * $G->transpose) );

      ($_tmp = $se_b($k)) .= sqrt( $ret{ss_residual} / $ret{F_df}->(1) / $ss_res_k );
    }
  }
  else {
    ($_tmp = $se_b(0))
      .= sqrt( $ret{ss_residual} / $ret{F_df}->(1) / sum( $ivs( ,0)**2 ) );
  }

  $ret{b_se} = $se_b;
  $ret{b_t} = $ret{b} / $ret{b_se};
  $ret{b_p} = 2 * ( 1 - $ret{b_t}->abs->gsl_cdf_tdist_P( $ret{F_df}->(1) ) )
    if $CDF;

  for (keys %ret) { ref $ret{$_} eq 'PDLA' and $ret{$_} = $ret{$_}->squeeze };

  return %ret;
}

sub _rm_bad_value {
  my ($y, $ivs) = @_;

  my $idx;
  if ($y->check_badflag or $ivs->check_badflag) {
     $idx = which(($y->isbad==0) & (nbadover ($ivs->transpose)==0));
     $y = $y($idx)->sever;
     $ivs = $ivs($idx,)->sever;
     $ivs->badflag(0);
     $y->badflag(0);
  }

  return $y, $ivs, $idx;
}

=head2 ols_rptd

=for ref

Repeated measures linear regression (Lorch & Myers, 1990; Van den Noortgate & Onghena, 2006). Handles purely within-subject design for now. See t/stats_ols_rptd.t for an example using the Lorch and Myers data.

=for usage

Usage:

    # This is the example from Lorch and Myers (1990),
    # a study on how characteristics of sentences affected reading time
    # Three within-subject IVs:
    # SP -- serial position of sentence
    # WORDS -- number of words in sentence
    # NEW -- number of new arguments in sentence

    # $subj can be 1D pdl or @ ref and must be the first argument
    # IV can be 1D @ ref or pdl
    # 1D @ ref is effect coded internally into pdl
    # pdl is left as is

    my %r = $rt->ols_rptd( $subj, $sp, $words, $new );

    print "$_\t$r{$_}\n" for (sort keys %r);

    (ss_residual)   58.3754646504336
    (ss_subject)    51.8590337714286
    (ss_total)  405.188241771429
    #      SP        WORDS      NEW
    F   [  7.208473  61.354153  1.0243311]
    F_p [0.025006181 2.619081e-05 0.33792837]
    coeff   [0.33337285 0.45858933 0.15162986]
    df  [1 1 1]
    df_err  [9 9 9]
    ms  [ 18.450705  73.813294 0.57026483]
    ms_err  [ 2.5595857  1.2030692 0.55671923]
    ss  [ 18.450705  73.813294 0.57026483]
    ss_err  [ 23.036272  10.827623  5.0104731]


=cut

*ols_rptd = \&PDLA::ols_rptd;
sub PDLA::ols_rptd {
  my ($y, $subj, @ivs_raw) = @_;

  $y = $y->squeeze;
  $y->getndims > 1 and
    croak "ols_rptd does not support threading";

  my @ivs = map {  (ref $_ eq 'PDLA' and $_->ndims > 1)?  $_
                  : ref $_ eq 'PDLA' ?                    $_->dummy(1)
                  :                   scalar effect_code($_)
                  ;
                } @ivs_raw;

  my %r;

  $r{'(ss_total)'} = $y->ss;

  # STEP 1: subj

  my $s = effect_code $subj;     # gives same results as dummy_code
  my $b_s = $y->ols_t($s);
  my $pred = sumover($b_s(0:-2) * $s->transpose) + $b_s(-1);
  $r{'(ss_subject)'} = $r{'(ss_total)'} - $y->sse( $pred );

  # STEP 2: add predictor variables

  my $iv_p = $s->glue(1, @ivs);
  my $b_p = $y->ols_t($iv_p);

    # only care about coeff for predictor vars. no subj or const coeff
  $r{coeff} = $b_p(-(@ivs+1) : -2)->sever;

    # get total sse for this step
  $pred = sumover($b_p(0:-2) * $iv_p->transpose) + $b_p(-1);
  my $ss_pe  = $y->sse( $pred );

    # get predictor ss by successively reducing the model
  $r{ss} = zeroes scalar(@ivs);
  for my $i (0 .. $#ivs) {
    my @i_rest = grep { $_ != $i } 0 .. $#ivs;
    my $iv = $s->glue(1, @ivs[ @i_rest ]);
    my $b  = $y->ols_t($iv);
    $pred = sumover($b(0:-2) * $iv->transpose) + $b(-1);
    ($_tmp = $r{ss}->($i)) .= $y->sse($pred) - $ss_pe;
  }

  # STEP 3: get precitor x subj interaction as error term

  my $iv_e = PDLA::glue 1, map { interaction_code( $s, $_ ) } @ivs;

    # get total sse for this step. full model now.
  my $b_f = $y->ols_t( $iv_p->glue(1,$iv_e) );
  $pred = sumover($b_f(0:-2) * $iv_p->glue(1,$iv_e)->transpose) + $b_f(-1);
  $r{'(ss_residual)'}  = $y->sse( $pred );

    # get predictor x subj ss by successively reducing the error term
  $r{ss_err} = zeroes scalar(@ivs);
  for my $i (0 .. $#ivs) {
    my @i_rest = grep { $_ != $i } 0 .. $#ivs;
    my $e_rest = PDLA::glue 1, map { interaction_code( $s, $_ ) } @ivs[@i_rest];
    my $iv = $iv_p->glue(1, $e_rest);
    my $b  = $y->ols_t($iv);
    my $pred = sumover($b(0:-2) * $iv->transpose) + $b(-1);
    ($_tmp = $r{ss_err}->($i)) .= $y->sse($pred) - $r{'(ss_residual)'};
  }

  # Finally, get MS, F, etc

  $r{df} = pdl( map { $_->squeeze->ndims } @ivs );
  $r{ms} = $r{ss} / $r{df};

  $r{df_err} = $s->dim(1) * $r{df};
  $r{ms_err} = $r{ss_err} / $r{df_err};

  $r{F} = $r{ms} / $r{ms_err};

  $r{F_p} = 1 - $r{F}->gsl_cdf_fdist_P( $r{df}, $r{df_err} )
    if $CDF;

  return %r;
}


=head2 logistic

=for ref

Logistic regression with maximum likelihood estimation using PDLA::Fit::LM (requires PDLA::Slatec. Hence loaded with "require" in the sub instead of "use" at the beginning).

IVs ($x) should be pdl dims $y->nelem or $y->nelem x n_iv. Do not supply the constant vector in $x. It is included in the model and returned as LAST of coeff. Returns full model in list context and coeff in scalar context.

The significance tests are likelihood ratio tests (-2LL deviance) tests. IV significance is tested by comparing deviances between the reduced model (ie with the IV in question removed) and the full model.

***NOTE: the results here are qualitatively similar to but not identical with results from R, because different algorithms are used for the nonlinear parameter fit. Use with discretion***

=for options

Default options (case insensitive):

    INITP => zeroes( $x->dim(1) + 1 ),    # n_iv + 1
    MAXIT => 1000,
    EPS   => 1e-7,

=for usage

Usage:

    # suppose this is whether a person had rented 10 movies

    perldl> p $y = ushort( random(10)*2 )
    [0 0 0 1 1 0 0 1 1 1]

    # IV 1 is box office ranking

    perldl> p $x1 = sequence(10)
    [0 1 2 3 4 5 6 7 8 9]

    # IV 2 is whether the movie is action- or chick-flick

    perldl> p $x2 = sequence(10) % 2
    [0 1 0 1 0 1 0 1 0 1]

    # concatenate the IVs together

    perldl> p $x = cat $x1, $x2
    [
     [0 1 2 3 4 5 6 7 8 9]
     [0 1 0 1 0 1 0 1 0 1]
    ]

    perldl> %m = $y->logistic( $x )

    perldl> p "$_\t$m{$_}\n" for (sort keys %m)

    D0	13.8629436111989
    Dm	9.8627829791575
    Dm_chisq	4.00016063204141
    Dm_df	2
    Dm_p	0.135324414081692
      #  ranking    genre      constant
    b	[0.41127706 0.53876358 -2.1201285]
    b_chisq	[ 3.5974504 0.16835559  2.8577151]
    b_p	[0.057868258  0.6815774 0.090936587]
    iter	12
    y_pred	[0.10715577 0.23683909 ... 0.76316091 0.89284423]


=cut

*logistic = \&PDLA::logistic;
sub PDLA::logistic {
  require PDLA::Fit::LM;              # uses PDLA::Slatec

  my ( $self, $ivs, $opt ) = @_;
  
  $self = $self->squeeze;
    # make compatible w multiple var cases
  $ivs->getndims == 1 and $ivs = $ivs->dummy(1);
  $self->dim(0) != $ivs->dim(0) and
    carp "mismatched n btwn DV and IV!";

  my %opt = (
    INITP => zeroes( $ivs->dim(1) + 1 ),    # n_ivs + 1
    MAXIT => 1000,
    EPS   => 1e-7,
  );
  $opt and $opt{uc $_} = $opt->{$_} for (%$opt);
    # not using it atm
  $opt{WT} = 1;

    # Use lmfit. Fourth input argument is reference to user-defined
    # copy INITP so we have the original value when needed 
  my ($yfit,$coeff,$cov,$iter)
    = PDLA::Fit::LM::lmfit($ivs, $self, $opt{WT}, \&_logistic, $opt{INITP}->copy,
      { Maxiter=>$opt{MAXIT}, Eps=>$opt{EPS} } );
    # apparently at least coeff is child of some pdl
    # which is changed in later lmfit calls
  $yfit  = $yfit->copy;
  $coeff = $coeff->copy;

  return $coeff unless wantarray;

  my %ret;

  my $n0 = $self->where($self == 0)->nelem;
  my $n1 = $self->nelem - $n0;

  $ret{D0} = -2*($n0 * log($n0 / $self->nelem) + $n1 * log($n1 / $self->nelem));
  $ret{Dm} = sum( $self->dvrs( $yfit ) ** 2 );
  $ret{Dm_chisq} = $ret{D0} - $ret{Dm};
  $ret{Dm_df} = $ivs->dim(1);
  $ret{Dm_p}
    = 1 - PDLA::GSL::CDF::gsl_cdf_chisq_P( $ret{Dm_chisq}, $ret{Dm_df} )
    if $CDF;

  my $coeff_chisq = zeroes $opt{INITP}->nelem;

  if ( $ivs->dim(1) > 1 ) {
    for my $k (0 .. $ivs->dim(1)-1) {
      my @G = grep { $_ != $k } (0 .. $ivs->dim(1)-1);
      my $G = $ivs->dice_axis(1, \@G);
  
      my $init = $opt{INITP}->dice([ @G, $opt{INITP}->dim(0)-1 ])->copy;
      my $y_G
        = PDLA::Fit::LM::lmfit( $G, $self, $opt{WT}, \&_logistic, $init,
        { Maxiter=>$opt{MAXIT}, Eps=>$opt{EPS} } );
  
      ($_tmp = $coeff_chisq($k)) .= $self->dm( $y_G ) - $ret{Dm};
    }
  }
  else {
      # d0 is, by definition, the deviance with only intercept
    ($_tmp = $coeff_chisq(0)) .= $ret{D0} - $ret{Dm};
  }

  my $y_c
      = PDLA::Fit::LM::lmfit( $ivs, $self, $opt{WT}, \&_logistic_no_intercept, $opt{INITP}->(0:-2)->copy,
      { Maxiter=>$opt{MAXIT}, Eps=>$opt{EPS} } );

  ($_tmp = $coeff_chisq(-1)) .= $self->dm( $y_c ) - $ret{Dm};

  $ret{b} = $coeff;
  $ret{b_chisq} = $coeff_chisq;
  $ret{b_p} = 1 - $ret{b_chisq}->gsl_cdf_chisq_P( 1 )
    if $CDF;
  $ret{y_pred} = $yfit;
  $ret{iter} = $iter;

  for (keys %ret) { ref $ret{$_} eq 'PDLA' and $ret{$_} = $ret{$_}->squeeze };

  return %ret;
}

sub _logistic {
  my ($x,$par,$ym,$dyda) = @_;

    # $b and $c are fit parameters slope and intercept
  my $b = $par(0 : $x->dim(1) - 1)->sever;
  my $c = $par(-1)->sever;
    
    # Write function with dependent variable $ym,
    # independent variable $x, and fit parameters as specified above.
    # Use the .= (dot equals) assignment operator to express the equality 
    # (not just a plain equals)
  ($_tmp = $ym) .= 1 / ( 1 + exp( -1 * (sumover($b * $x->transpose) + $c) ) );

  my (@dy) = map {$dyda -> slice(",($_)") } (0 .. $par->dim(0)-1);

    # Partial derivative of the function with respect to each slope 
    # fit parameter ($b in this case). Again, note .= assignment 
    # operator (not just "equals")
  ($_tmp = $dy[$_]) .= $x( ,$_) * $ym * (1 - $ym)
    for (0 .. $b->dim(0)-1);

    # Partial derivative of the function re intercept par
  ($_tmp = $dy[-1]) .= $ym * (1 - $ym);
}

sub _logistic_no_intercept {
  my ($x,$par,$ym,$dyda) = @_;
    
  my $b = $par(0 : $x->dim(1) - 1)->sever;

    # Write function with dependent variable $ym,
    # independent variable $x, and fit parameters as specified above.
    # Use the .= (dot equals) assignment operator to express the equality 
    # (not just a plain equals)
  ($_tmp = $ym) .= 1 / ( 1 + exp( -1 * sumover($b * $x->transpose) ) );

  my (@dy) = map {$dyda -> slice(",($_)") } (0 .. $par->dim(0)-1);

    # Partial derivative of the function with respect to each slope 
    # fit parameter ($b in this case). Again, note .= assignment 
    # operator (not just "equals")
  ($_tmp = $dy[$_]) .= $x( ,$_) * $ym * (1 - $ym)
    for (0 .. $b->dim(0)-1);
}

=head2 pca

=for ref

Principal component analysis. Based on corr instead of cov (bad values are ignored pair-wise. OK when bad values are few but otherwise probably should fill_m etc before pca). Use PDLA::Slatec::eigsys() if installed, otherwise use PDLA::MatrixOps::eigens_sym().

=for options

Default options (case insensitive):

    CORR  => 1,     # boolean. use correlation or covariance
    PLOT  => 1,     # calls plot_screes by default
                    # can set plot_screes options here

=for usage

Usage:

    my $d = qsort random 10, 5;      # 10 obs on 5 variables
    my %r = $d->pca( \%opt );
    print "$_\t$r{$_}\n" for (keys %r);

    eigenvalue    # variance accounted for by each component
    [4.70192 0.199604 0.0471421 0.0372981 0.0140346]

    eigenvector   # dim var x comp. weights for mapping variables to component
    [
     [ -0.451251  -0.440696  -0.457628  -0.451491  -0.434618]
     [ -0.274551   0.582455   0.131494   0.255261  -0.709168]
     [   0.43282   0.500662  -0.139209  -0.735144 -0.0467834]
     [  0.693634  -0.428171   0.125114   0.128145  -0.550879]
     [  0.229202   0.180393  -0.859217     0.4173  0.0503155]
    ]
    
    loadings      # dim var x comp. correlation between variable and component
    [
     [ -0.978489  -0.955601  -0.992316   -0.97901  -0.942421]
     [ -0.122661   0.260224  0.0587476   0.114043  -0.316836]
     [ 0.0939749   0.108705 -0.0302253  -0.159616 -0.0101577]
     [   0.13396 -0.0826915  0.0241629  0.0247483   -0.10639]
     [  0.027153  0.0213708  -0.101789  0.0494365 0.00596076]
    ]
    
    pct_var       # percent variance accounted for by each component
    [0.940384 0.0399209 0.00942842 0.00745963 0.00280691]

Plot scores along the first two components,

    $d->plot_scores( $r{eigenvector} );

=cut

*pca = \&PDLA::pca;
sub PDLA::pca { 
  my ($self, $opt) = @_;

  my %opt = (
    CORR  => 1,
    PLOT  => 1,
  );
  $opt and $opt{uc $_} = $opt->{$_} for (keys %$opt);

  my $var_var = $opt{CORR}? $self->corr_table : $self->cov_table;

    # value is axis pdl and score is var x axis
  my ($eigval, $eigvec);
  if ( $SLATEC ) {
    ($eigval, $eigvec) = $var_var->PDLA::Slatec::eigsys;
  }
  else {
    ($eigvec, $eigval) = $var_var->eigens_sym;
      # compatibility with PDLA::Slatec::eigsys
    $eigvec = $eigvec->inplace->transpose->sever;
  }

    # ind is sticky point for threading
  my $ind_sorted = $eigval->qsorti->(-1:0);
  $eigvec = $eigvec( ,$ind_sorted)->sever;
  $eigval = $eigval($ind_sorted)->sever;

    # var x axis
  my $var     = $eigval / $eigval->sum;
  my $loadings;
  if ($opt{CORR}) {
    $loadings = $eigvec * sqrt( $eigval->transpose );
  }
  else {
    my $scores = $eigvec x $self->dev_m;
    $loadings = $self->corr( $scores->dummy(1) );
  }

  $var->plot_screes(\%opt)
    if $opt{PLOT};

  return ( eigenvalue=>$eigval, eigenvector=>$eigvec,
           pct_var=>$var, loadings=>$loadings ); 
}

=head2 pca_sorti

Determine by which vars a component is best represented. Descending sort vars by size of association with that component. Returns sorted var and relevant component indices.

=for options

Default options (case insensitive):

    NCOMP => 10,     # maximum number of components to consider

=for usage

Usage:

      # let's see if we replicated the Osgood et al. (1957) study
    perldl> ($data, $idv, $ido) = rtable 'osgood_exp.csv', {v=>0}

      # select a subset of var to do pca
    perldl> $ind = which_id $idv, [qw( ACTIVE BASS BRIGHT CALM FAST GOOD HAPPY HARD LARGE HEAVY )]
    perldl> $data = $data( ,$ind)->sever
    perldl> @$idv = @$idv[list $ind]

    perldl> %m = $data->pca
 
    perldl> ($iv, $ic) = $m{loadings}->pca_sorti()

    perldl> p "$idv->[$_]\t" . $m{loadings}->($_,$ic)->flat . "\n" for (list $iv)

             #   COMP0     COMP1    COMP2    COMP3
    HAPPY	[0.860191 0.364911 0.174372 -0.10484]
    GOOD	[0.848694 0.303652 0.198378 -0.115177]
    CALM	[0.821177 -0.130542 0.396215 -0.125368]
    BRIGHT	[0.78303 0.232808 -0.0534081 -0.0528796]
    HEAVY	[-0.623036 0.454826 0.50447 0.073007]
    HARD	[-0.679179 0.0505568 0.384467 0.165608]
    ACTIVE	[-0.161098 0.760778 -0.44893 -0.0888592]
    FAST	[-0.196042 0.71479 -0.471355 0.00460276]
    LARGE	[-0.241994 0.594644 0.634703 -0.00618055]
    BASS	[-0.621213 -0.124918 0.0605367 -0.765184]
    
=cut

*pca_sorti = \&PDLA::pca_sorti;
sub PDLA::pca_sorti {
    # $self is pdl (var x component)
  my ($self, $opt) = @_;

  my %opt = (
    NCOMP => 10,     # maximum number of components to consider
  );
  $opt and $opt{uc $_} = $opt->{$_} for (keys %$opt);

  my $ncomp = pdl($opt{NCOMP}, $self->dim(1))->min;
  $self = $self->dice_axis( 1, pdl(0..$ncomp-1) );
  
  my $icomp = $self->transpose->abs->maximum_ind;
 
    # sort between comp
  my $ivar_sort = $icomp->qsorti;
  $self = $self($ivar_sort, )->sever;

    # sort within comp
  my $ic = $icomp($ivar_sort)->iv_cluster;
  for my $comp (0 .. $ic->dim(1)-1) {
    my $i = $self(which($ic( ,$comp)), ($comp))->qsorti->(-1:0);
    ($_tmp = $ivar_sort(which $ic( ,$comp)))
      .= $ivar_sort(which $ic( ,$comp))->($i)->sever;
  }
  return wantarray? ($ivar_sort, pdl(0 .. $ic->dim(1)-1)) : $ivar_sort;
}

=head2 plot_means

Plots means anova style. Can handle up to 4-way interactions (ie 4D pdl).

=for options

Default options (case insensitive):

    IVNM  => ['IV_0', 'IV_1', 'IV_2', 'IV_3'],
    DVNM  => 'DV',
    AUTO  => 1,       # auto set dims to be on x-axis, line, panel
                      # if set 0, dim 0 goes on x-axis, dim 1 as lines
                      # dim 2+ as panels
      # see PDLA::Graphics::PGPLOT::Window for next options
    WIN   => undef,   # pgwin object. not closed here if passed
                      # allows comparing multiple lines in same plot
                      # set env before passing WIN
    DEV   => '/xs',         # open and close dev for plotting if no WIN
                            # defaults to '/png' in Windows
    SIZE  => 640,           # individual square panel size in pixels
    SYMBL => [0, 4, 7, 11], 

=for usage

Usage:

      # see anova for mean / se pdl structure
    $mean->plot_means( $se, {IVNM=>['apple', 'bake']} );
  
Or like this:

    $m{'# apple ~ bake # m'}->plot_means;

=cut

*plot_means = \&PDLA::plot_means;
sub PDLA::plot_means {
  my $opt = pop @_
    if ref $_[-1] eq 'HASH';
  my ($self, $se) = @_;
  if (!$PGPLOT) {
    carp "No PDLA::Graphics::PGPLOT, no plot :(";
    return;
  }
  $self = $self->squeeze;
  if ($self->ndims > 4) {
    carp "Data is > 4D. No plot here.";
    return;
  }

  my %opt = (
    IVNM => ['IV_0', 'IV_1', 'IV_2', 'IV_3'],
    DVNM => 'DV',
    AUTO  => 1,             # auto set vars to be on X axis, line, panel
    WIN   => undef,         # PDLA::Graphics::PGPLOT::Window object
    DEV   => $DEV,
    SIZE  => 640,           # individual square panel size in pixels
    SYMBL => [0, 4, 7, 11], # ref PDLA::Graphics::PGPLOT::Window 
  );
  $opt and $opt{uc $_} = $opt->{$_} for (keys %$opt);

    # decide which vars to plot as x axis, lines, panels
    # put var w most levels on x axis
    # put var w least levels on diff panels
  my @iD = 0..3;
  my @dims = (1, 1, 1, 1);
    # splice ARRAY,OFFSET,LENGTH,LIST
  splice @dims, 0, $self->ndims, $self->dims;
  $self = $self->reshape(@dims)->sever;
  $se = $se->reshape(@dims)->sever
    if defined $se;
  @iD = reverse sort { $a<=>$b } @dims
    if $opt{AUTO};

    # $iD[0] on x axis
    # $iD[1] as separate lines
  my $nx = $self->dim($iD[2]);    # n xpanels
  my $ny = $self->dim($iD[3]);    # n ypanels
  
  my $w = $opt{WIN};
  if (!defined $w) {
    $w = pgwin(DEV=>$opt{DEV}, NX=>$nx, NY=>$ny,
                 SIZE=>[$opt{SIZE}*$nx, $opt{SIZE}*$ny], UNIT=>3);
  }

  my ($min, $max) = defined $se? pdl($self + $se, $self - $se)->minmax
                  :              $self->minmax
                  ;
  my $range = $max - $min;
  my $p = 0;   # panel

  for my $y (0..$self->dim($iD[3])-1) {
    for my $x (0..$self->dim($iD[2])-1) {
      $p ++;
      my $tl = '';
      $tl = $opt{IVNM}->[$iD[2]] . " $x"        if $self->dim($iD[2]) > 1;
      $tl .= ' ' . $opt{IVNM}->[$iD[3]] . " $y"  if $self->dim($iD[3]) > 1;
      $w->env( 0, $self->dim($iD[0])-1, $min - 2*$range/5, $max + $range/5,
             { XTitle=>$opt{IVNM}->[$iD[0]], YTitle=>$opt{DVNM}, Title=>$tl,                 PANEL=>$p, AXIS=>['BCNT', 'BCNST'], Border=>1, 
              } )
        unless $opt{WIN};
  
      my (@legend, @color);
      for (0 .. $self->dim($iD[1]) - 1) {
        push @legend, $opt{IVNM}->[$iD[1]] . " $_"
          if ($self->dim($iD[1]) > 1);
        push @color, $_ + 2;    # start from red
        $w->points( sequence($self->dim($iD[0])),
        $self->dice_axis($iD[3],$y)->dice_axis($iD[2],$x)->dice_axis($iD[1],$_),
                      $opt{SYMBL}->[$_],
                    { PANEL=>$p, CHARSIZE=>2, COLOR=>$_+2, PLOTLINE=>1, } );
        $w->errb( sequence($self->dim($iD[0])),
        $self->dice_axis($iD[3],$y)->dice_axis($iD[2],$x)->dice_axis($iD[1],$_),
        $se->dice_axis($iD[3],$y)->dice_axis($iD[2],$x)->dice_axis($iD[1],$_),
                    { PANEL=>$p, CHARSIZE=>2, COLOR=>$_+2 }  )
          if defined $se;
      }
      if ($self->dim($iD[1]) > 1) {
        $w->legend( \@legend, ($self->dim($iD[0])-1)/1.6, $min - $range/10,
                   { COLOR=>\@color } );
        $w->legend( \@legend, ($self->dim($iD[0])-1)/1.6, $min - $range/10,
                   { COLOR=>\@color, SYMBOL=>[ @{$opt{SYMBL}}[0..$#color] ] } );
      }
    }
  }
  $w->close
    unless $opt{WIN};

  return;
}

=head2 plot_residuals

Plots residuals against predicted values.

=for usage

Usage:

    $y->plot_residuals( $y_pred, { dev=>'/png' } );

=for options

Default options (case insensitive):

     # see PDLA::Graphics::PGPLOT::Window for more info
    WIN   => undef,  # pgwin object. not closed here if passed
                     # allows comparing multiple lines in same plot
                     # set env before passing WIN
    DEV   => '/xs',  # open and close dev for plotting if no WIN
                     # defaults to '/png' in Windows
    SIZE  => 640,    # plot size in pixels
    COLOR => 1,

=cut

*plot_residuals = \&PDLA::plot_residuals;
sub PDLA::plot_residuals {
  if (!$PGPLOT) {
    carp "No PDLA::Graphics::PGPLOT, no plot :(";
    return;
  }
  my $opt = pop @_
    if ref $_[-1] eq 'HASH';
  my ($y, $y_pred) = @_;
  my %opt = (
     # see PDLA::Graphics::PGPLOT::Window for next options
    WIN   => undef,  # pgwin object. not closed here if passed
                     # allows comparing multiple lines in same plot
                     # set env before passing WIN
    DEV   => $DEV ,  # open and close dev for plotting if no WIN
    SIZE  => 640,    # plot size in pixels
    COLOR => 1,
  );
  $opt and $opt{uc $_} = $opt->{$_} for (keys %$opt);

  my $residuals = $y - $y_pred;

  my $win = $opt{WIN};

  if (!$win) {
   $win = pgwin(DEV=>$opt{DEV}, SIZE=>[$opt{SIZE}, $opt{SIZE}], UNIT=>3);
   $win->env( $y_pred->minmax, $residuals->minmax,
     {XTITLE=>'predicted value', YTITLE=>'residuals',
      AXIS=>['BCNT', 'BCNST'], Border=>1,} );
  }

  $win->points($y_pred, $residuals, { COLOR=>$opt{COLOR} });
  # add 0-line
  $win->line(pdl($y_pred->minmax), pdl(0,0), { COLOR=>$opt{COLOR} } );

  $win->close
    unless $opt{WIN};

  return;
}

 
=head2 plot_scores

Plots standardized original and PCA transformed scores against two components. (Thank you, Bob MacCallum, for the documentation suggestion that led to this function.)

=for options

Default options (case insensitive):

  CORR  => 1,      # boolean. PCA was based on correlation or covariance
  COMP  => [0,1],  # indices to components to plot
    # see PDLA::Graphics::PGPLOT::Window for next options
  WIN   => undef,  # pgwin object. not closed here if passed
                   # allows comparing multiple lines in same plot
                   # set env before passing WIN
  DEV   => '/xs',  # open and close dev for plotting if no WIN
                   # defaults to '/png' in Windows
  SIZE  => 640,    # plot size in pixels
  COLOR => [1,2],  # color for original and rotated scores

=for usage

Usage:

  my %p = $data->pca();
  $data->plot_scores( $p{eigenvector}, \%opt );

=cut

*plot_scores = \&PDLA::plot_scores;
sub PDLA::plot_scores {
  if (!$PGPLOT) {
    carp "No PDLA::Graphics::PGPLOT, no plot :(";
    return;
  }
  my $opt = pop @_
    if ref $_[-1] eq 'HASH';
  my ($self, $eigvec) = @_;
  my %opt = (
    CORR  => 1,      # boolean. PCA was based on correlation or covariance
    COMP  => [0,1],  # indices to components to plot
     # see PDLA::Graphics::PGPLOT::Window for next options
    WIN   => undef,  # pgwin object. not closed here if passed
                     # allows comparing multiple lines in same plot
                     # set env before passing WIN
    DEV   => $DEV ,  # open and close dev for plotting if no WIN
    SIZE  => 640,    # plot size in pixels
    COLOR => [1,2],  # color for original and transformed scoress
  );
  $opt and $opt{uc $_} = $opt->{$_} for (keys %$opt);

  my $i = pdl $opt{COMP};
  my $z = $opt{CORR}? $self->stddz : $self->dev_m;

    # transformed normed values
  my $scores = sumover($eigvec( ,$i) * $z->transpose->dummy(1))->transpose;
  $z = $z( ,$i)->sever;

  my $win = $opt{WIN};
  my $max = pdl($z, $scores)->abs->ceil->max;
  if (!$win) {
   $win = pgwin(DEV=>$opt{DEV}, SIZE=>[$opt{SIZE}, $opt{SIZE}], UNIT=>3);
   $win->env(-$max, $max, -$max, $max,
     {XTitle=>"Compoment $opt{COMP}->[0]", YTitle=>"Component $opt{COMP}->[1]",
     AXIS=>['ABCNST', 'ABCNST'], Border=>1, });
  }

  $win->points( $z( ,0;-), $z( ,1;-), { COLOR=>$opt{COLOR}->[0] } );
  $win->points( $scores( ,0;-), $scores( ,1;-), { COLOR=>$opt{COLOR}->[1] } );
  $win->legend( ['original', 'transformed'], .2*$max, .8*$max, {color=>[1,2],symbol=>[1,1]} );
  $win->close
    unless $opt{WIN};
  return;
}

 
=head2 plot_screes

Scree plot. Plots proportion of variance accounted for by PCA components.

=for options

Default options (case insensitive):

  NCOMP => 20,     # max number of components to plot
  CUT   => 0,      # set to plot cutoff line after this many components
                   # undef to plot suggested cutoff line for NCOMP comps
   # see PDLA::Graphics::PGPLOT::Window for next options
  WIN   => undef,  # pgwin object. not closed here if passed
                   # allows comparing multiple lines in same plot
                   # set env before passing WIN
  DEV   => '/xs',  # open and close dev for plotting if no WIN
                   # defaults to '/png' in Windows
  SIZE  => 640,    # plot size in pixels
  COLOR => 1,

=for usage

Usage:

  # variance should be in descending order
 
  $pca{var}->plot_screes( {ncomp=>16} );

Or, because NCOMP is used so often, it is allowed a shortcut,

  $pca{var}->plot_screes( 16 );

=cut

*plot_scree = \&PDLA::plot_screes;      # here for now for compatibility
*plot_screes = \&PDLA::plot_screes;
sub PDLA::plot_screes {
  if (!$PGPLOT) {
    carp "No PDLA::Graphics::PGPLOT, no plot :(";
    return;
  }
  my $opt = pop @_
    if ref $_[-1] eq 'HASH';
  my ($self, $ncomp) = @_;
  my %opt = (
    NCOMP => 20,     # max number of components to plot
    CUT   => 0,      # set to plot cutoff line after this many components
                     # undef to plot suggested cutoff line for NCOMP comps
     # see PDLA::Graphics::PGPLOT::Window for next options
    WIN   => undef,  # pgwin object. not closed here if passed
                     # allows comparing multiple lines in same plot
                     # set env before passing WIN
    DEV   => $DEV ,  # open and close dev for plotting if no WIN
    SIZE  => 640,    # plot size in pixels
    COLOR => 1,
  );
  $opt and $opt{uc $_} = $opt->{$_} for (keys %$opt);
  $opt{NCOMP} = $ncomp
    if $ncomp;
    # re-use $ncomp below
  $ncomp = ($self->dim(0) < $opt{NCOMP})? $self->dim(0) : $opt{NCOMP};
  $opt{CUT}   = PDLA::Stats::Kmeans::_scree_ind $self(0:$ncomp-1)
    if !defined $opt{CUT};

  my $win = $opt{WIN};

  if (!$win) {
   $win = pgwin(DEV=>$opt{DEV}, SIZE=>[$opt{SIZE}, $opt{SIZE}], UNIT=>3);
   $win->env(0, $ncomp-1, 0, 1,
     {XTitle=>'Compoment', YTitle=>'Proportion of Variance Accounted for',
     AXIS=>['BCNT', 'BCNST'], Border=>1, });
  }

  $win->points(sequence($ncomp), $self(0:$ncomp-1, ),
        {CHARSIZE=>2, COLOR=>$opt{COLOR}, PLOTLINE=>1} );
  $win->line( pdl($opt{CUT}-.5, $opt{CUT}-.5), pdl(-.05, $self->max+.05),
        {COLOR=>15} )
    if $opt{CUT};
  $win->close
    unless $opt{WIN};
  return;
}

=head1 SEE ALSO

PDLA::Fit::Linfit

PDLA::Fit::LM

=head1 REFERENCES

Cohen, J., Cohen, P., West, S.G., & Aiken, L.S. (2003). Applied Multiple Regression/correlation Analysis for the Behavioral Sciences (3rd ed.). Mahwah, NJ: Lawrence Erlbaum Associates Publishers.

Hosmer, D.W., & Lemeshow, S. (2000). Applied Logistic Regression (2nd ed.). New York, NY: Wiley-Interscience. 

Lorch, R.F., & Myers, J.L. (1990). Regression analyses of repeated measures data in cognitive research. Journal of Experimental Psychology: Learning, Memory, & Cognition, 16, 149-157.

Osgood C.E., Suci, G.J., & Tannenbaum, P.H. (1957). The Measurement of Meaning. Champaign, IL: University of Illinois Press.

Rutherford, A. (2001). Introducing Anova and Ancova: A GLM Approach (1st ed.). Thousand Oaks, CA: Sage Publications.

Shlens, J. (2009). A Tutorial on Principal Component Analysis. Retrieved April 10, 2011 from http://citeseerx.ist.psu.edu/

The GLM procedure: unbalanced ANOVA for two-way design with interaction. (2008). SAS/STAT(R) 9.2 User's Guide. Retrieved June 18, 2009 from http://support.sas.com/

Van den Noortgatea, W., & Onghenaa, P. (2006). Analysing repeated measures data in cognitive research: A comment on regression coefficient analyses. European Journal of Cognitive Psychology, 18, 937-952.

=head1 AUTHOR

Copyright (C) 2009 Maggie J. Xiong <maggiexyz users.sourceforge.net>

All rights reserved. There is no warranty. You are allowed to redistribute this software / documentation as described in the file COPYING in the PDLA distribution.

=cut

EOD

pp_done();

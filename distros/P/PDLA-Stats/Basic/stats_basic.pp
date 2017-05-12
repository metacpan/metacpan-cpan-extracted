#!/usr/bin/perl

pp_add_exported('', 'binomial_test', 'rtable', 'which_id', 
);

pp_addpm({At=>'Top'}, <<'EOD');

use PDLA::LiteF;
use PDLA::NiceSlice;
use Carp;

$PDLA::onlinedoc->scan(__FILE__) if $PDLA::onlinedoc;

eval { require PDLA::GSL::CDF; };
my $CDF = 1 if !$@;

=head1 NAME

PDLA::Stats::Basic -- basic statistics and related utilities such as standard deviation, Pearson correlation, and t-tests.

=head1 DESCRIPTION

The terms FUNCTIONS and METHODS are arbitrarily used to refer to methods that are threadable and methods that are NOT threadable, respectively.

Does not have mean or median function here. see SEE ALSO.

=head1 SYNOPSIS

    use PDLA::LiteF;
    use PDLA::NiceSlice;
    use PDLA::Stats::Basic;

    my $stdv = $data->stdv;

or

    my $stdv = stdv( $data );  

=cut

EOD

pp_addhdr('
#include <math.h>

'
);

pp_def('stdv',
  Pars      => 'a(n); float+ [o]b()',
  GenericTypes => [F, D],
  HandleBad => 1,
  Code      => '
    $GENERIC(b) sa, a2;
    sa = 0; a2 = 0;
    long N = $SIZE(n);
    loop (n) %{
      sa += $a();
      a2 += pow($a(), 2);
    %}
    $b() = sqrt( a2 / N - pow(sa/N,2) );
  ',
  BadCode  => '
    $GENERIC(b) sa, a2;
    sa = 0; a2 = 0;
    long N = 0;
    loop (n) %{
      if ( $ISGOOD($a()) ) {
	sa += $a();
	a2 += pow($a(), 2);
	N  ++;
      }
    %}
    if (N) {
      $b() = sqrt( a2 / N - pow(sa/N,2) );
    }
    else {
      $SETBAD(b());
    }
  ',
  Doc      => '

=for ref

Sample standard deviation.

=cut
  ',

);

pp_def('stdv_unbiased',
  Pars      => 'a(n); float+ [o]b()',
  GenericTypes => [F, D],
  HandleBad => 1,
  Code      => '
    $GENERIC(b) sa, a2;
    sa = 0; a2 = 0;
    long N = $SIZE(n);
    loop (n) %{
      sa += $a();
      a2 += pow($a(), 2);
    %}
    $b() = pow( a2/(N-1) - pow(sa/N,2) * N/(N-1), .5 );
  ',
  BadCode  => '
    $GENERIC(b) sa, a2;
    sa = 0; a2 = 0;
    long N = 0;
    loop (n) %{
      if ( $ISGOOD($a()) ) {
	sa += $a();
	a2 += pow($a(), 2);
	N  ++;
      }
    %}
    if (N-1) {
      $b() = pow( a2/(N-1) - pow(sa/N,2) * N/(N-1), .5 );
    }
    else {
      $SETBAD(b());
    }
  ',
  Doc      => '

=for ref

Unbiased estimate of population standard deviation.

=cut
  ',

);

pp_def('var',
  Pars      => 'a(n); float+ [o]b()',
  GenericTypes => [F, D],
  HandleBad => 1,
  Code      => '
    $GENERIC(b) a2, sa;
    a2 = 0; sa = 0;
    long N = $SIZE(n);
    loop (n) %{
      a2 += pow($a(), 2);
      sa += $a();
    %}
    $b() = a2 / N - pow(sa/N, 2);
  ',
  BadCode  => '
    $GENERIC(b) a2, sa;
    a2 = 0; sa = 0;
    long N = 0;
    loop (n) %{
      if ( $ISGOOD($a()) ) {
        a2 += pow($a(), 2);
        sa += $a();
	N  ++;
      }
    %}
    if (N) {
      $b() = a2 / N - pow(sa/N, 2);
    }
    else {
      $SETBAD(b());
    }
  ',
  Doc      => '

=for ref

Sample variance.

=cut
  ',

);

pp_def('var_unbiased',
  Pars      => 'a(n); float+ [o]b()',
  GenericTypes => [F, D],
  HandleBad => 1,
  Code      => '
    $GENERIC(b) a2, sa;
    a2 = 0; sa = 0;
    long N = $SIZE(n);
    loop (n) %{
      a2 += pow($a(), 2);
      sa += $a();
    %}
    $b() = (a2 - pow(sa/N, 2) * N) / (N-1);
  ',
  BadCode  => '
    $GENERIC(b) a2, sa;
    a2 = 0; sa = 0;
    long N = 0;
    loop (n) %{
      if ( $ISGOOD($a()) ) {
        a2 += pow($a(), 2);
        sa += $a();
	N  ++;
      }
    %}
    if (N-1) {
      $b() = (a2 - pow(sa/N, 2) * N) / (N-1);
    }
    else {
      $SETBAD(b());
    }
  ',
  Doc      => '

=for ref

Unbiased estimate of population variance.

=cut
  ',

);

pp_def('se',
  Pars      => 'a(n); float+ [o]b()',
  GenericTypes => [F, D],
  HandleBad => 1,
  Code      => '
    $GENERIC(b) sa, a2;
    sa = 0; a2 = 0;
    long N = $SIZE(n);
    loop (n) %{
      sa += $a();
      a2 += pow($a(), 2);
    %}
    $b() = sqrt( (a2/(N-1) - pow(sa/N,2) * N/(N-1)) / N );
  ',
  BadCode  => '
    $GENERIC(b) sa, a2;
    sa = 0; a2 = 0;
    long N = 0;
    loop (n) %{
      if ( $ISGOOD($a()) ) {
	sa += $a();
	a2 += pow($a(), 2);
	N  ++;
      }
    %}
    if (N-1) {
      $b() = sqrt( (a2/(N-1) - pow(sa/N,2) * N/(N-1)) / N );
    }
    else {
      $SETBAD(b());
    }
  ',
  Doc      => '

=for ref

Standard error of the mean. Useful for calculating confidence intervals.

=for usage

    # 95% confidence interval for samples with large N

    $ci_95_upper = $data->average + 1.96 * $data->se;
    $ci_95_lower = $data->average - 1.96 * $data->se;

=cut

  ',

);

pp_def('ss',
  Pars      => 'a(n); float+ [o]b()',
  GenericTypes => [F, D],
  HandleBad => 1,
  Code      => '
    $GENERIC(b) sa, a2;
    sa = 0; a2 = 0;
    long N = $SIZE(n);
    loop (n) %{
      sa += $a();
      a2 += pow($a(), 2);
    %}
    $b() = a2 - N * pow(sa/N,2);
  ',
  BadCode  => '
    $GENERIC(b) sa, a2;
    sa = 0; a2 = 0;
    long N = 0;
    loop (n) %{
      if ( $ISGOOD($a()) ) {
	sa += $a();
	a2 += pow($a(), 2);
	N  ++;
      }
    %}
    if (N) {
      $b() = a2 - N * pow(sa/N,2);
    }
    else {
      $SETBAD(b());
    }
  ',
  Doc      => '

=for ref

Sum of squared deviations from the mean.

=cut
  ',

);

pp_def('skew',
  Pars      => 'a(n); float+ [o]b()',
  GenericTypes => [F, D],
  HandleBad => 1,
  Code      => '
    $GENERIC(b) sa, m, d, d2, d3;
    sa = 0; d2 = 0; d3 = 0;
    long N = $SIZE(n);
    loop (n) %{
      sa += $a();
    %}
    m = sa / N;
    loop (n) %{
      d   = $a() - m;
      d2 += pow(d, 2);
      d3 += pow(d, 3);
    %}
    $b() = d3/N / pow(d2/N, 1.5);
  ',
  BadCode  => '
    $GENERIC(b) sa, m, d, d2, d3;
    sa = 0; m = 0; d=0; d2 = 0; d3 = 0;
    long N = 0;
    loop (n) %{
      if ( $ISGOOD($a()) ) {
        sa += $a();
        N ++;
      }
    %}
    if (N) {
      m = sa / N;
      loop (n) %{
        if ( $ISGOOD($a()) ) {
      	  d   = $a() - m;
      	  d2 += pow(d, 2);
      	  d3 += pow(d, 3);
        }
      %}
      $b() = d3/N / pow(d2/N, 1.5);
    }
    else {
      $SETBAD(b());
    }
  ',
  Doc      => '

=for ref

Sample skewness, measure of asymmetry in data. skewness == 0 for normal distribution.

=cut
  ',

);

pp_def('skew_unbiased',
  Pars      => 'a(n); float+ [o]b()',
  GenericTypes => [F, D],
  HandleBad => 1,
  Code      => '
    $GENERIC(b) sa, m, d, d2, d3;
    sa = 0; d2 = 0; d3 = 0;
    long N = $SIZE(n);
    loop (n) %{
      sa += $a();
    %}
    m = sa / N;
    loop (n) %{
      d   = $a() - m;
      d2 += pow(d, 2);
      d3 += pow(d, 3);
    %}
    $b() = sqrt(N*(N-1)) / (N-2) * d3/N / pow(d2/N, 1.5);
  ',
  BadCode  => '
    $GENERIC(b) sa, m, d, d2, d3;
    sa = 0; m = 0; d=0; d2 = 0; d3 = 0;
    long N = 0;
    loop (n) %{
      if ( $ISGOOD($a()) ) {
        sa += $a();
        N ++;
      }
    %}
    if (N-2) {
      m = sa / N;
      loop (n) %{
        if ( $ISGOOD($a()) ) {
          d   = $a() - m;
          d2 += pow(d, 2);
          d3 += pow(d, 3);
        }
      %}
      $b() = sqrt(N*(N-1)) / (N-2) * d3/N / pow(d2/N, 1.5);
    }
    else {
      $SETBAD(b());
    }
  ',
  Doc      => '

=for ref

Unbiased estimate of population skewness. This is the number in GNumeric Descriptive Statistics.

=cut
  ',

);

pp_def('kurt',
  Pars      => 'a(n); float+ [o]b()',
  GenericTypes => [F, D],
  HandleBad => 1,
  Code      => '
    $GENERIC(b) sa, m, d, d2, d4;
    sa = 0; d2 = 0; d4 = 0;
    long N = $SIZE(n);
    loop (n) %{
      sa += $a();
    %}
    m = sa / N;
    loop (n) %{
      d   = $a() - m;
      d2 += pow(d, 2);
      d4 += pow(d, 4);
    %}
    $b() = N * d4 / pow(d2,2) - 3;
  ',
  BadCode  => '
    $GENERIC(b) sa, m, d, d2, d4;
    sa = 0; m = 0; d=0; d2 = 0; d4 = 0;
    long N = 0;
    loop (n) %{
      if ( $ISGOOD($a()) ) {
        sa += $a();
        N ++;
      }
    %}
    if (N) {
      m = sa / N;
      loop (n) %{
        if ( $ISGOOD($a()) ) {
          d   = $a() - m;
          d2 += pow(d, 2);
          d4 += pow(d, 4);
        }
      %}
      $b() = N * d4 / pow(d2,2) - 3;
    }
    else {
      $SETBAD(b());
    }
  ',
  Doc      => '

=for ref

Sample kurtosis, measure of "peakedness" of data. kurtosis == 0 for normal distribution. 

=cut
  ',

);

pp_def('kurt_unbiased',
  Pars      => 'a(n); float+ [o]b()',
  GenericTypes => [F, D],
  HandleBad => 1,
  Code      => '
    $GENERIC(b) sa, m, d, d2, d4;
    sa = 0; d2 = 0; d4 = 0;
    long N = $SIZE(n);
    loop (n) %{
      sa += $a();
    %}
    m = sa / N;
    loop (n) %{
      d   = $a() - m;
      d2 += pow(d, 2);
      d4 += pow(d, 4);
    %}
    $b() = ((N-1)*N*(N+1) * d4 / pow(d2,2) - 3 * pow(N-1,2)) / ((N-2)*(N-3));
  ',
  BadCode  => '
    $GENERIC(b) sa, m, d, d2, d4;
    sa = 0; m = 0; d=0; d2 = 0; d4 = 0;
    long N = 0;
    loop (n) %{
      if ( $ISGOOD($a()) ) {
        sa += $a();
        N ++;
      }
    %}
    if (N-3) {
      m = sa / N;
      loop (n) %{
        if ( $ISGOOD($a()) ) {
          d   = $a() - m;
          d2 += pow(d, 2);
          d4 += pow(d, 4);
        }
      %}
      $b() = ((N-1)*N*(N+1) * d4 / pow(d2,2) - 3 * pow(N-1,2)) / ((N-2)*(N-3));
    }
    else {
      $SETBAD(b());
    }
  ',
  Doc      => '

=for ref

Unbiased estimate of population kurtosis. This is the number in GNumeric Descriptive Statistics.

=cut
  ',

);


pp_def('cov',
  Pars      => 'a(n); b(n); float+ [o]c()',
  GenericTypes => [F, D],
  HandleBad => 1,
  Code      => '
    $GENERIC(c) ab, sa, sb;
    ab = 0; sa = 0; sb = 0;
    long N = $SIZE(n);
    loop (n) %{
      ab += $a() * $b();
      sa += $a();
      sb += $b();
    %}
    $c() = ab / N - (sa/N) * (sb/N);
  ',
  BadCode  => '
    $GENERIC(c) ab, sa, sb;
    ab = 0; sa = 0; sb = 0;
    long N = 0;
    loop (n) %{
      if ( $ISBAD($a()) || $ISBAD($b()) ) { }
      else {
	ab += $a() * $b();
	sa += $a();
	sb += $b();
	N  ++;
      }
    %}
    if (N) {
      $c() = ab / N - (sa/N) * (sb/N);
    }
    else {
      $SETBAD(c());
    }
  ',
  Doc      => '

=for ref

Sample covariance. see B<corr> for ways to call

=cut
  ',

);

pp_def('cov_table',
  Pars      => 'a(n,m); float+ [o]c(m,m)',
  HandleBad => 1,
  Code      => '

long N, M;
N = $SIZE(n); M = $SIZE(m);
$GENERIC(a) a_, b_;
$GENERIC(c) ab, sa, sb, cov;

if (N > 1 ) {
  long i, j;
  for (i=0; i<M; i++) {
    for (j=i; j<M; j++) {
      ab = 0; sa = 0; sb = 0;
      loop (n) %{
        a_ = $a(n=>n,m=>i);
        b_ = $a(n=>n,m=>j);
    	ab += a_ * b_;
    	sa += a_;
    	sb += b_;
      %}
      cov = ab - (sa * sb) / N;
      $c(m0=>i, m1=>j) =
      $c(m0=>j, m1=>i) = cov / N;
    }
  }
}
else {
  barf( "too few N" );
}

  ',
  BadCode  => '

if ($SIZE(n) >= 2 ) {
  $GENERIC(a) a_, b_;
  $GENERIC(c) ab, sa, sb, cov;
  long N, M, i, j;
  M = $SIZE(m);
  for (i=0; i<M; i++) {
    for (j=i; j<M; j++) {
      ab=0; sa=0; sb=0; N=0;
      loop (n) %{
        if ($ISBAD($a(n=>n, m=>i)) || $ISBAD($a(n=>n, m=>j))) { }
        else { 
          a_ = $a(n=>n,m=>i);
          b_ = $a(n=>n,m=>j);
          ab += a_ * b_;
          sa += a_;
          sb += b_;
          N ++;
        }
      %}
      if (N > 1) {
        cov = ab - (sa * sb) / N;
        $c(m0=>i, m1=>j) =
        $c(m0=>j, m1=>i) = cov / N;
      }
      else {
        $SETBAD($c(m0=>i, m1=>j));
        $SETBAD($c(m0=>j, m1=>i));
      }
    }
  }
}
else {
  barf( "too few N" );
}

  ',
  Doc      => '

=for ref

Square covariance table. Gives the same result as threading using B<cov> but it calculates only half the square, hence much faster. And it is easier to use with higher dimension pdls.

=for usage

Usage:

    # 5 obs x 3 var, 2 such data tables

    perldl> $a = random 5, 3, 2

    perldl> p $cov = $a->cov_table
    [
     [
      [ 8.9636438 -1.8624472 -1.2416588]
      [-1.8624472  14.341514 -1.4245366]
      [-1.2416588 -1.4245366  9.8690655]
     ]
     [
      [   10.32644 -0.31311789 -0.95643674]
      [-0.31311789   15.051779  -7.2759577]
      [-0.95643674  -7.2759577   5.4465141]
     ]
    ]
    # diagonal elements of the cov table are the variances
    perldl> p $a->var
    [
     [ 8.9636438  14.341514  9.8690655]
     [  10.32644  15.051779  5.4465141]
    ]

for the same cov matrix table using B<cov>,

    perldl> p $a->dummy(2)->cov($a->dummy(1)) 

=cut

  ',

);

pp_def('corr',
  Pars      => 'a(n); b(n); float+ [o]c()',
  GenericTypes => [F, D],
  HandleBad => 1,
  Code      => '
    $GENERIC(c) ab, sa, sb, a2, b2, cov, va, vb;
    ab=0; sa=0; sb=0; a2=0; b2=0; cov=0; va=0; vb=0;
    long N = $SIZE(n);
    if (N > 1 ) {
      loop (n) %{
	ab += $a() * $b();
	sa += $a();
	sb += $b();
	a2 += pow($a(), 2);
	b2 += pow($b(), 2);
      %}
/*  in fact cov * N, va * N, and vb * N  */
      cov = ab - (sa * sb) / N;
      va  = a2 - pow(sa,2) / N;
      vb  = b2 - pow(sb,2) / N;
      $c() = cov / sqrt( va * vb );
    }
    else {
      barf( "too few N" );
    }
  ',
  BadCode  => '
    $GENERIC(c) ab, sa, sb, a2, b2, cov, va, vb;
    ab=0; sa=0; sb=0; a2=0; b2=0;
    long N = 0;
    loop (n) %{
      if ( $ISBAD($a()) || $ISBAD($b()) ) { }
      else {
	ab += $a() * $b();
	sa += $a();
	sb += $b();
	a2 += pow($a(), 2);
	b2 += pow($b(), 2);
	N  ++;
      }
    %}
    if ( N > 1 ) {
      cov = ab - (sa * sb) / N;
      va  = a2 - pow(sa,2) / N;
      vb  = b2 - pow(sb,2) / N;
      $c() = cov / sqrt( va * vb );
    }
    else {
      $SETBAD(c());
    }
  ',
  Doc      => '

=for ref

Pearson correlation coefficient. r = cov(X,Y) / (stdv(X) * stdv(Y)).

=for usage 

Usage:

    perldl> $a = random 5, 3
    perldl> $b = sequence 5,3
    perldl> p $a->corr($b)

    [0.20934208 0.30949881 0.26713007]

for square corr table

    perldl> p $a->corr($a->dummy(1))

    [
     [           1  -0.41995259 -0.029301192]
     [ -0.41995259            1  -0.61927619]
     [-0.029301192  -0.61927619            1]
    ]

but it is easier and faster to use B<corr_table>.

=cut
  ',

);

pp_def('corr_table',
  Pars      => 'a(n,m); float+ [o]c(m,m)',
  HandleBad => 1,
  Code      => '

long N, M;
N = $SIZE(n); M = $SIZE(m);
$GENERIC(a) a_, b_;
$GENERIC(c) ab, sa, sb, a2, b2, cov, va, vb, r;

if (N > 1 ) {
  long i, j;
  for (i=0; i<M; i++) {
    for (j=i+1; j<M; j++) {
      ab = 0; sa = 0; sb = 0; a2 = 0; b2 = 0;
      loop (n) %{
        a_ = $a(n=>n,m=>i);
        b_ = $a(n=>n,m=>j);
    	ab += a_ * b_;
    	sa += a_;
    	sb += b_;
    	a2 += pow(a_, 2);
    	b2 += pow(b_, 2);
      %}
      cov = ab - (sa * sb) / N;
      va  = a2 - pow(sa,2) / N;
      vb  = b2 - pow(sb,2) / N;
      r   = cov / sqrt( va * vb );
      $c(m0=>i, m1=>j) =
      $c(m0=>j, m1=>i) = r;
    }
    $c(m0=>i, m1=>i) = 1.0;
  }
}
else {
  barf( "too few N" );
}

  ',
  BadCode  => '

if ($SIZE(n) >= 2 ) {
  $GENERIC(a) a_, b_;
  $GENERIC(c) ab, sa, sb, a2, b2, cov, va, vb, r;
  long N, M, i, j;
  M = $SIZE(m);
  for (i=0; i<M; i++) {
    for (j=i+1; j<M; j++) {
      ab=0; sa=0; sb=0; a2=0; b2=0; N=0;
      loop (n) %{
        if ($ISBAD($a(n=>n, m=>i)) || $ISBAD($a(n=>n, m=>j))) { }
        else { 
          a_ = $a(n=>n,m=>i);
          b_ = $a(n=>n,m=>j);
          ab += a_ * b_;
          sa += a_;
          sb += b_;
          a2 += pow(a_, 2);
          b2 += pow(b_, 2);
          N ++;
        }
      %}
      if (N > 1) {
        cov = ab - (sa * sb) / N;
        va  = a2 - pow(sa,2) / N;
        vb  = b2 - pow(sb,2) / N;
        r   = cov / sqrt( va * vb );
        $c(m0=>i, m1=>j) =
        $c(m0=>j, m1=>i) = r;
      }
      else {
        $SETBAD($c(m0=>i, m1=>j));
        $SETBAD($c(m0=>j, m1=>i));
      }
    }
    N=0;
    loop (n) %{
      if ($ISGOOD($a(n=>n,m=>i)))
        N ++;
      if (N > 1)
        break;
    %}
    if (N > 1) {  $c(m0=>i, m1=>i) = 1.0;  }
    else       {  $SETBAD($c(m0=>i, m1=>i)); }
  }
}
else {
  barf( "too few N" );
}

  ',
  Doc      => '

=for ref

Square Pearson correlation table. Gives the same result as threading using B<corr> but it calculates only half the square, hence much faster. And it is easier to use with higher dimension pdls.

=for usage

Usage:

    # 5 obs x 3 var, 2 such data tables
 
    perldl> $a = random 5, 3, 2
    
    perldl> p $a->corr_table
    [
     [
     [          1 -0.69835951 -0.18549048]
     [-0.69835951           1  0.72481605]
     [-0.18549048  0.72481605           1]
    ]
    [
     [          1  0.82722569 -0.71779883]
     [ 0.82722569           1 -0.63938828]
     [-0.71779883 -0.63938828           1]
     ]
    ]

for the same result using B<corr>,

    perldl> p $a->dummy(2)->corr($a->dummy(1)) 

This is also how to use B<t_corr> and B<n_pair> with such a table.

=cut

  ',

);

pp_def('t_corr',
  Pars      => 'r(); n(); [o]t()',
  GenericTypes => [F, D],
  HandleBad => 1,
  Code      => '
    $t() = $r() / pow( (1 - pow($r(), 2)) / ($n() - 2) , .5);
  ',
  BadCode   => '
    if ($ISBAD(r()) || $ISBAD(n()) ) {
      $SETBAD( $t() );
    }
    else {
      if ($n() > 2) {
        $t() = $r() / pow( (1 - pow($r(), 2)) / ($n() - 2) , .5);
      }
      else {
        $SETBAD(t());
      }
    }
  ',
  Doc       => '

=for usage

    $corr   = $data->corr( $data->dummy(1) );
    $n      = $data->n_pair( $data->dummy(1) );
    $t_corr = $corr->t_corr( $n );

    use PDLA::GSL::CDF;

    $p_2tail = 2 * (1 - gsl_cdf_tdist_P( $t_corr->abs, $n-2 ));

=for ref

t significance test for Pearson correlations.

=cut
  ',

);

pp_def('n_pair',
  Pars      => 'a(n); b(n); int [o]c()',
  GenericTypes => [L],
  HandleBad => 1,
  Code      => '
    $c() = $SIZE(n);
  ',
  BadCode   => '
    long N = 0;
    loop(n) %{
      if ( $ISBAD($a()) || $ISBAD($b()) ) { }
      else {
        N ++;
      }
    %}
    $c() = N;
  ',
  Doc       => '

=for ref

Returns the number of good pairs between 2 lists. Useful with B<corr> (esp. when bad values are involved)

=cut
  ',

);

pp_def('corr_dev',
  Pars      => 'a(n); b(n); float+ [o]c()',
  GenericTypes => [F, D],
  HandleBad => 1,
  Code      => '
    $GENERIC(c) ab, a2, b2, cov, va, vb;
    ab = 0; a2 = 0; b2 = 0;
    long N = $SIZE(n);
    if (N > 1) {
      loop (n) %{
	ab += $a() * $b();
	a2 += pow($a(), 2);
	b2 += pow($b(), 2);
      %}
      cov = ab / N;
      va  = a2 / N;
      vb  = b2 / N;
      $c() = cov / sqrt( va * vb );
    }
    else {
      barf( "too few N" );
    }
  ',
  BadCode   => '
    $GENERIC(c) ab, a2, b2, cov, va, vb;
    ab = 0; a2 = 0; b2 = 0;
    long N = 0;
    loop (n) %{
      if ( $ISBAD($a()) || $ISBAD($b()) ) { }
      else {
	ab += $a() * $b();
	a2 += pow($a(), 2);
	b2 += pow($b(), 2);
        N  ++;
      }
    %}
    if (N > 1) {
      cov = ab / N;
      va  = a2 / N;
      vb  = b2 / N;
      $c() = cov / sqrt( va * vb );
    }
    else {
      $SETBAD(c());
    }
  ',
  Doc       => '

=for usage

    $corr = $a->dev_m->corr_dev($b->dev_m);

=for ref

Calculates correlations from B<dev_m> vals. Seems faster than doing B<corr> from original vals when data pdl is big

=cut
  ',
);

pp_def('t_test',
  Pars      => 'a(n); b(m); float+ [o]t(); [o]d()',
  GenericTypes => [F, D],
  HandleBad => 1,
  Code      => '
    $GENERIC(t) N, M, sa, sb, a2, b2, va, vb, sdiff;
    sa = 0; sb = 0; a2 = 0; b2 = 0;
    N = $SIZE(n);
    M = $SIZE(m);
    if (N < 2 || M < 2) {
      barf( "too few N" );
    }
    else {
      loop (n) %{
        sa += $a();
	a2 += pow($a(), 2);
      %}
      loop (m) %{
        sb += $b();
	b2 += pow($b(), 2);
      %}

      $d() = N + M - 2;

      va = (a2 - pow(sa/N, 2) * N) / (N-1);
      vb = (b2 - pow(sb/M, 2) * M) / (M-1);
      sdiff = sqrt( (1/N + 1/M) * ((N-1)*va + (M-1)*vb) / $d() );
      $t() = (sa/N - sb/M) / sdiff;
    }
  ',
  BadCode   => '
    $GENERIC(t) N, M, sa, sb, a2, b2, va, vb, sdiff;
    sa = 0; sb = 0; a2 = 0; b2 = 0;
    N = 0;
    M = 0;
    loop (n) %{
      if ( $ISGOOD($a()) ) {
        sa += $a();
	a2 += pow($a(), 2);
        N ++;
      }
    %}
    loop (m) %{
      if ( $ISGOOD($b()) ) {
        sb += $b();
	b2 += pow($b(), 2);
        M ++;
      }
    %}
    if (N < 2 || M < 2) {
      $SETBAD($t());
      $SETBAD($d());
    }
    else {
      $d() = N + M - 2;

      va = (a2 - pow(sa/N, 2) * N) / (N-1);
      vb = (b2 - pow(sb/M, 2) * M) / (M-1);
      sdiff = sqrt( (1/N + 1/M) * ((N-1)*va + (M-1)*vb) / $d() );
      $t() = (sa/N - sb/M) / sdiff;
    }
  ',
  Doc       => '

=for usage

    my ($t, $df) = t_test( $pdl1, $pdl2 );

    use PDLA::GSL::CDF;

    my $p_2tail = 2 * (1 - gsl_cdf_tdist_P( $t->abs, $df ));

=for ref

Independent sample t-test, assuming equal var.

=cut
  ',
);

pp_def('t_test_nev',
  Pars      => 'a(n); b(m); float+ [o]t(); [o]d()',
  GenericTypes => [F, D],
  HandleBad => 1,
  Code      => '
    $GENERIC(t) N, M, sa, sb, a2, b2, se_a_2, se_b_2, sdiff;
    sa = 0; sb = 0; a2 = 0; b2 = 0;
    N = $SIZE(n);
    M = $SIZE(m);
    if (N < 2 || M < 2) {
      barf( "too few N" );
    }
    else {
      loop (n) %{
        sa += $a();
	a2 += pow($a(), 2);
      %}
      loop (m) %{
        sb += $b();
	b2 += pow($b(), 2);
      %}

      se_a_2 = (a2 - pow(sa/N,2)*N) / (N*(N-1));
      se_b_2 = (b2 - pow(sb/M,2)*M) / (M*(M-1));
      sdiff = sqrt( se_a_2 + se_b_2 );

      $t() = (sa/N - sb/M) / sdiff;
      $d() = pow(se_a_2 + se_b_2, 2)
           / ( pow(se_a_2,2) / (N-1) + pow(se_b_2,2) / (M-1) )
           ;
    }
  ',
  BadCode   => '
    $GENERIC(t) N, M, sa, sb, a2, b2, se_a_2, se_b_2, sdiff;
    sa = 0; sb = 0; a2 = 0; b2 = 0;
    N = 0;
    M = 0;
    loop (n) %{
      if ( $ISGOOD($a()) ) {
        sa += $a();
	a2 += pow($a(), 2);
        N ++;
      }
    %}
    loop (m) %{
      if ( $ISGOOD($b()) ) {
        sb += $b();
	b2 += pow($b(), 2);
        M ++;
      }
    %}
    if (N < 2 || M < 2) {
      $SETBAD($t());
      $SETBAD($d());
    }
    else {
      se_a_2 = (a2 - pow(sa/N,2)*N) / (N*(N-1));
      se_b_2 = (b2 - pow(sb/M,2)*M) / (M*(M-1));
      sdiff = sqrt( se_a_2 + se_b_2 );

      $t() = (sa/N - sb/M) / sdiff;
      $d() = pow(se_a_2 + se_b_2, 2)
           / ( pow(se_a_2,2) / (N-1) + pow(se_b_2,2) / (M-1) )
           ;
    }
  ',
  Doc       => '

=for ref

Independent sample t-test, NOT assuming equal var. ie Welch two sample t test. Df follows Welch-Satterthwaite equation instead of Satterthwaite (1946, as cited by Hays, 1994, 5th ed.). It matches GNumeric, which matches R.

=for usage

    my ($t, $df) = $pdl1->t_test( $pdl2 );

=cut
  ',
);

pp_def('t_test_paired',
  Pars      => 'a(n); b(n); float+ [o]t(); [o]d()',
  GenericTypes => [F, D],
  HandleBad => 1,
  Code      => '
    $GENERIC(t) N, diff, s_dif, diff2;
    s_dif = 0; diff2 = 0;
    N = $SIZE(n);
    if (N > 1) {
      loop (n) %{
        diff = $a() - $b();
        s_dif += diff;
	diff2 += pow(diff, 2);
      %}

      $d() = N - 1;
      $t() = s_dif / sqrt( N * ( diff2 - pow(s_dif/N,2)*N ) / (N-1) );
    }
    else {
      barf( "too few N" );
    }
  ',
  BadCode   => '
    $GENERIC(t) N, diff, s_dif, diff2;
    s_dif = 0; diff2 = 0;
    N = 0;
    loop (n) %{
      if ( $ISBAD($a()) || $ISBAD($b()) ) { }
      else {
        diff = $a() - $b();
        s_dif += diff;
	diff2 += pow(diff, 2);
        N ++;
      }
    %}
    if (N > 1) {
      $d() = N - 1;
      $t() = s_dif / sqrt( N * ( diff2 - pow(s_dif/N,2)*N ) / (N-1) );
    }
    else {
      $SETBAD($t());
      $SETBAD($d());
    }
  ',
  Doc       => '

=for ref

Paired sample t-test.

=cut
  ',
);

pp_addpm(<<'EOD');

=head2 binomial_test

=for Sig

  Signature: (x(); n(); p_expected(); [o]p())

=for ref

Binomial test. One-tailed significance test for two-outcome distribution. Given the number of successes, the number of trials, and the expected probability of success, returns the probability of getting this many or more successes.

This function does NOT currently support bad value in the number of successes.

=for usage

Usage:

  # assume a fair coin, ie. 0.5 probablity of getting heads
  # test whether getting 8 heads out of 10 coin flips is unusual

  my $p = binomial_test( 8, 10, 0.5 );  # 0.0107421875. Yes it is unusual.

=cut

*binomial_test = \&PDLA::binomial_test;
sub PDLA::binomial_test {
  my ($x, $n, $P) = @_;

  carp 'Please install PDLA::GSL::CDF.' unless $CDF;
  carp 'This function does NOT currently support bad value in the number of successes.' if $x->badflag();

  my $pdlx = pdl($x);
  $pdlx->badflag(1);
  $pdlx = $pdlx->setvaltobad(0);

  my $p = 1 - PDLA::GSL::CDF::gsl_cdf_binomial_P( $pdlx - 1, $P, $n );
  $p = $p->setbadtoval(1);
  $p->badflag(0);

  return $p;
}


=head1 METHODS

=head2 rtable

=for ref

Reads either file or file handle*. Returns observation x variable pdl and var and obs ids if specified. Ids in perl @ ref to allow for non-numeric ids. Other non-numeric entries are treated as missing, which are filled with $opt{MISSN} then set to BAD*. Can specify num of data rows to read from top but not arbitrary range.

*If passed handle, it will not be closed here.

*PDLA::Bad::setvaltobad only works consistently with the default TYPE double before PDLA-2.4.4_04.

=for options

Default options (case insensitive):

    V       => 1,        # verbose. prints simple status
    TYPE    => double,
    C_ID    => 1,        # boolean. file has col id.
    R_ID    => 1,        # boolean. file has row id.
    R_VAR   => 0,        # boolean. set to 1 if var in rows
    SEP     => "\t",     # can take regex qr//
    MISSN   => -999,     # this value treated as missing and set to BAD
    NROW    => '',       # set to read specified num of data rows

=for usage

Usage:

Sample file diet.txt:

    uid	height	weight	diet
    akw	72	320	1
    bcm	68	268	1
    clq	67	180	2
    dwm	70	200	2
  
    ($data, $idv, $ido) = rtable 'diet.txt';

    # By default prints out data info and @$idv index and element

    reading diet.txt for data and id... OK.
    data table as PDLA dim o x v: PDLA: Double D [4,3]
    0	height
    1	weight
    2	diet

Another way of using it,

    $data = rtable( \*STDIN, {TYPE=>long} );

=cut

sub rtable {
    # returns obs x var data matrix and var and obs ids
  my ($src, $opt) = @_;

  my $fh_in;
  if ($src =~ /STDIN/ or ref $src eq 'GLOB') { $fh_in = $src }
  else                                       { open $fh_in, $src or croak "$!" }

  my %opt = ( V       => 1,
              TYPE    => double,
              C_ID    => 1,
              R_ID    => 1,
              R_VAR   => 0,
              SEP     => "\t",
              MISSN   => -999,
              NROW    => '',
            );
  $opt and $opt{uc $_} = $opt->{$_} for (keys %$opt);
  $opt{V} and print STDERR "reading $src for data and id... ";
  
  local $PDLA::undefval = $opt{MISSN};

  my $id_c = [];     # match declaration of $id_r for return purpose
  if ($opt{C_ID}) {
    chomp( $id_c = <$fh_in> );
    my @entries = split $opt{SEP}, $id_c;
    $opt{R_ID} and shift @entries;
    $id_c = \@entries;
  }

  my ($c_row, $id_r, $data, @data) = (0, [], PDLA->null, );
  while (<$fh_in>) {
    chomp;
    my @entries = split /$opt{SEP}/, $_, -1;

    $opt{R_ID} and push @$id_r, shift @entries;
  
      # rudimentary check for numeric entry 
    for (@entries) { $_ = $opt{MISSN} unless defined $_ and /\d\b/ }

    push @data, pdl( $opt{TYPE}, \@entries );
    $c_row ++;
    last
      if $opt{NROW} and $c_row == $opt{NROW};
  }
  # not explicitly closing $fh_in here in case it's passed from outside
  # $fh_in will close by going out of scope if opened here. 

  $data = pdl $opt{TYPE}, @data;
  @data = ();
    # rid of last col unless there is data there
  $data = $data(0:$data->getdim(0)-2, )->sever
    unless ( nelem $data(-1, )->where($data(-1, ) != $opt{MISSN}) ); 

  my ($idv, $ido) = ($id_r, $id_c);
    # var in columns instead of rows
  $opt{R_VAR} == 0
    and ($data, $idv, $ido) = ($data->inplace->transpose, $id_c, $id_r);

  if ($opt{V}) {
    print STDERR "OK.\ndata table as PDLA dim o x v: " . $data->info . "\n";
    $idv and print STDERR "$_\t$$idv[$_]\n" for (0..$#$idv);
  }
 
  $data = $data->setvaltobad( $opt{MISSN} );
  $data->check_badflag;
  return wantarray? (@$idv? ($data, $idv, $ido) : ($data, $ido)) : $data;
}

=head2 group_by

Returns pdl reshaped according to the specified factor variable. Most useful when used in conjunction with other threading calculations such as average, stdv, etc. When the factor variable contains unequal number of cases in each level, the returned pdl is padded with bad values to fit the level with the most number of cases. This allows the subsequent calculation (average, stdv, etc) to return the correct results for each level.

Usage:

    # simple case with 1d pdl and equal number of n in each level of the factor

	pdl> p $a = sequence 10
	[0 1 2 3 4 5 6 7 8 9]

	pdl> p $factor = $a > 4
	[0 0 0 0 0 1 1 1 1 1]

	pdl> p $a->group_by( $factor )->average
	[2 7]

    # more complex case with threading and unequal number of n across levels in the factor

	pdl> p $a = sequence 10,2
	[
	 [ 0  1  2  3  4  5  6  7  8  9]
	 [10 11 12 13 14 15 16 17 18 19]
	]

	pdl> p $factor = qsort $a( ,0) % 3
	[
	 [0 0 0 0 1 1 1 2 2 2]
	]

	pdl> p $a->group_by( $factor )
	[
	 [
	  [ 0  1  2  3]
	  [10 11 12 13]
	 ]
	 [
	  [  4   5   6 BAD]
	  [ 14  15  16 BAD]
	 ]
	 [
	  [  7   8   9 BAD]
	  [ 17  18  19 BAD]
	 ]
	]
     ARRAY(0xa2a4e40)

    # group_by supports perl factors, multiple factors
    # returns factor labels in addition to pdl in array context

    pdl> p $a = sequence 12
    [0 1 2 3 4 5 6 7 8 9 10 11]

    pdl> $odd_even = [qw( e o e o e o e o e o e o )]

    pdl> $magnitude = [qw( l l l l l l h h h h h h )]

    pdl> ($a_grouped, $label) = $a->group_by( $odd_even, $magnitude )

    pdl> p $a_grouped
    [
     [
      [0 2 4]
      [1 3 5]
     ]
     [
      [ 6  8 10]
      [ 7  9 11]
     ]
    ]

    pdl> p Dumper $label
    $VAR1 = [
              [
                'e_l',
                'o_l'
              ],
              [
                'e_h',
                'o_h'
              ]
            ];


=cut

*group_by = \&PDLA::group_by;
sub PDLA::group_by {
    my $p = shift;
    my @factors = @_;

    if ( @factors == 1 ) {
        my $factor = $factors[0];
        my $label;
        if (ref $factor eq 'ARRAY') {
            $label  = _ordered_uniq($factor);
            $factor = _array_to_pdl($factor);
        } else {
            my $perl_factor = [$factor->list];
            $label  = _ordered_uniq($perl_factor);
        }

        my $p_reshaped = _group_by_single_factor( $p, $factor );

        return wantarray? ($p_reshaped, $label) : $p_reshaped;
    }

    # make sure all are arrays instead of pdls
    @factors = map { ref($_) eq 'PDLA'? [$_->list] : $_ } @factors;

    my (@cells);
    for my $ele (0 .. $#{$factors[0]}) {
        my $c = join '_', map { $_->[$ele] } @factors;
        push @cells, $c;
    }
    # get uniq cell labels (ref List::MoreUtils::uniq)
    my %seen;
    my @uniq_cells = grep {! $seen{$_}++ } @cells;

    my $flat_factor = _array_to_pdl( \@cells );

    my $p_reshaped = _group_by_single_factor( $p, $flat_factor );

    # get levels of each factor and reshape accordingly
    my @levels;
    for (@factors) {
        my %uniq;
        @uniq{ @$_ } = ();
        push @levels, scalar keys %uniq;
    }

    $p_reshaped = $p_reshaped->reshape( $p_reshaped->dim(0), @levels )->sever;

    # make labels for the returned data structure matching pdl structure
    my @labels;
    if (wantarray) {
        for my $ifactor (0 .. $#levels) {
            my @factor_label;
            for my $ilevel (0 .. $levels[$ifactor]-1) {
                my $i = $ifactor * $levels[$ifactor] + $ilevel;
                push @factor_label, $uniq_cells[$i];
            }
            push @labels, \@factor_label;
        }
    }

    return wantarray? ($p_reshaped, \@labels) : $p_reshaped;
}

# get uniq cell labels (ref List::MoreUtils::uniq)
sub _ordered_uniq {
    my $arr = shift;

    my %seen;
    my @uniq = grep { ! $seen{$_}++ } @$arr;

    return \@uniq;
}

sub _group_by_single_factor {
    my $p = shift;
    my $factor = shift;

    $factor = $factor->squeeze;
    die "Currently support only 1d factor pdl."
        if $factor->ndims > 1;

    die "Data pdl and factor pdl do not match!"
        unless $factor->dim(0) == $p->dim(0);

    # get active dim that will be split according to factor and dims to thread over
	my @p_threaddims = $p->dims;
	my $p_dim0 = shift @p_threaddims;

    my $uniq = $factor->uniq;

    my @uniq_ns;
    for ($uniq->list) {
        push @uniq_ns, which( $factor == $_ )->nelem;
    }

    # get number of n's in each group, find the biggest, fit output pdl to this
    my $uniq_ns = pdl \@uniq_ns;
	my $max = pdl(\@uniq_ns)->max;

    my $badvalue = int($p->max + 1);
    my $p_tmp = ones($max, @p_threaddims, $uniq->nelem) * $badvalue;
    for (0 .. $#uniq_ns) {
        my $i = which $factor == $uniq($_);
        $p_tmp->dice_axis(-1,$_)->squeeze->(0:$uniq_ns[$_]-1, ) .= $p($i, );
    }

    $p_tmp->badflag(1);
    return $p_tmp->setvaltobad($badvalue);
}

=head2 which_id

=for ref

Lookup specified var (obs) ids in $idv ($ido) (see B<rtable>) and return indices in $idv ($ido) as pdl if found. The indices are ordered by the specified subset. Useful for selecting data by var (obs) id.

=for usage

    my $ind = which_id $ido, ['smith', 'summers', 'tesla'];

    my $data_subset = $data( $ind, );

    # take advantage of perl pattern matching
    # e.g. use data from people whose last name starts with s

    my $i = which_id $ido, [ grep { /^s/ } @$ido ];

    my $data_s = $data($i, );

=cut

sub which_id {
  my ($id, $id_s) = @_;

  my %ind;
  @ind{ @$id } = ( 0 .. $#$id );

  my @ind_select;
  for (@$id_s) {
    defined( $ind{$_} ) and push @ind_select, $ind{$_};
  }
  return pdl @ind_select;
}

sub _array_to_pdl {
  my ($var_ref) = @_;

  my (%level, $l);
  $l = 0;
  for (@$var_ref) {
    if (defined($_) and $_ ne '' and $_ ne 'BAD') {
      $level{$_} = $l ++
        if !exists $level{$_};
    }
  }

  my $pdl = pdl( map { (defined($_) and $_ ne '' and $_ ne 'BAD')?  $level{$_} : -1 } @$var_ref );
  $pdl = $pdl->setvaltobad(-1);
  $pdl->check_badflag;

  return wantarray? ($pdl, \%level) : $pdl;
}


=head1 SEE ALSO

PDLA::Basic (hist for frequency counts)

PDLA::Ufunc (sum, avg, median, min, max, etc.)

PDLA::GSL::CDF (various cumulative distribution functions)

=head1 	REFERENCES

Hays, W.L. (1994). Statistics (5th ed.). Fort Worth, TX: Harcourt Brace College Publishers.

=head1 AUTHOR

Copyright (C) 2009 Maggie J. Xiong <maggiexyz users.sourceforge.net>

All rights reserved. There is no warranty. You are allowed to redistribute this software / documentation as described in the file COPYING in the PDLA distribution.

=cut

EOD

pp_done();

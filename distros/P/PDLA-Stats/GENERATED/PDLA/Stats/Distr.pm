
#
# GENERATED WITH PDLA::PP! Don't modify!
#
package PDLA::Stats::Distr;

@EXPORT_OK  = qw(  PDLA::PP mme_beta PDLA::PP pdf_beta PDLA::PP mme_binomial PDLA::PP pmf_binomial PDLA::PP mle_exp PDLA::PP pdf_exp PDLA::PP mme_gamma PDLA::PP pdf_gamma PDLA::PP mle_gaussian PDLA::PP pdf_gaussian PDLA::PP mle_geo PDLA::PP pmf_geo PDLA::PP mle_geosh PDLA::PP pmf_geosh PDLA::PP mle_lognormal PDLA::PP mme_lognormal PDLA::PP pdf_lognormal PDLA::PP mme_nbd PDLA::PP pmf_nbd PDLA::PP mme_pareto PDLA::PP pdf_pareto PDLA::PP mle_poisson PDLA::PP pmf_poisson PDLA::PP pmf_poisson_stirling PDLA::PP _pmf_poisson_factorial );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDLA::Core;
use PDLA::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDLA::Exporter','DynaLoader' );
   push @PDLA::Core::PP, __PACKAGE__;
   bootstrap PDLA::Stats::Distr ;





use strict;
use warnings;

use Carp;
use PDLA::LiteF;

$PDLA::onlinedoc->scan(__FILE__) if $PDLA::onlinedoc;

eval {
  require PDLA::Graphics::PGPLOT::Window;
  PDLA::Graphics::PGPLOT::Window->import( 'pgwin' );
};
my $PGPLOT = 1 if !$@;

my $DEV = ($^O =~ /win/i)? '/png' : '/xs';

=head1 NAME

PDLA::Stats::Distr -- parameter estimations and probability density functions for distributions.

=head1 DESCRIPTION

Parameter estimate is maximum likelihood estimate when there is closed form estimate, otherwise it is method of moments estimate.

=head1 SYNOPSIS

    use PDLA::LiteF;
    use PDLA::Stats::Distr;

      # do a frequency (probability) plot with fitted normal curve

    my ($xvals, $hist) = $data->hist;

      # turn frequency into probability
    $hist /= $data->nelem;

      # get maximum likelihood estimates of normal curve parameters
    my ($m, $v) = $data->mle_gaussian();

      # fitted normal curve probabilities
    my $p = $xvals->pdf_gaussian($m, $v);

    use PDLA::Graphics::PGPLOT::Window;
    my $win = pgwin( Dev=>"/xs" );

    $win->bin( $hist );
    $win->hold;
    $win->line( $p, {COLOR=>2} );
    $win->close;

Or, play with different distributions with B<plot_distr> :)

    $data->plot_distr( 'gaussian', 'lognormal' );

=cut







=head1 FUNCTIONS



=cut






=head2 mme_beta

=for sig

  Signature: (a(n); float+ [o]alpha(); float+ [o]beta())



=for usage

    my ($a, $b) = $data->mme_beta();

=for ref

beta distribution. pdf: f(x; a,b) = 1/B(a,b) x^(a-1) (1-x)^(b-1)


  

=for bad

mme_beta processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*mme_beta = \&PDLA::mme_beta;





=head2 pdf_beta

=for sig

  Signature: (x(); a(); b(); float+ [o]p())



=for ref

probability density function for beta distribution. x defined on [0,1].


  

=for bad

pdf_beta processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*pdf_beta = \&PDLA::pdf_beta;





=head2 mme_binomial

=for sig

  Signature: (a(n); int [o]n_(); float+ [o]p())



=for usage

    my ($n, $p) = $data->mme_binomial;

=for ref

binomial distribution. pmf: f(k; n,p) = (n k) p^k (1-p)^(n-k) for k = 0,1,2..n 


  

=for bad

mme_binomial processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*mme_binomial = \&PDLA::mme_binomial;





=head2 pmf_binomial

=for sig

  Signature: (ushort x(); ushort n(); p(); float+ [o]out())



=for ref

probability mass function for binomial distribution.


  

=for bad

pmf_binomial processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*pmf_binomial = \&PDLA::pmf_binomial;





=head2 mle_exp

=for sig

  Signature: (a(n); float+ [o]l())



=for usage

    my $lamda = $data->mle_exp;

=for ref

exponential distribution. mle same as method of moments estimate.


  

=for bad

mle_exp processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*mle_exp = \&PDLA::mle_exp;





=head2 pdf_exp

=for sig

  Signature: (x(); l(); float+ [o]p())



=for ref

probability density function for exponential distribution.


  

=for bad

pdf_exp processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*pdf_exp = \&PDLA::pdf_exp;





=head2 mme_gamma

=for sig

  Signature: (a(n); float+ [o]shape(); float+ [o]scale())



=for usage

    my ($shape, $scale) = $data->mme_gamma();

=for ref

two-parameter gamma distribution


  

=for bad

mme_gamma processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*mme_gamma = \&PDLA::mme_gamma;





=head2 pdf_gamma

=for sig

  Signature: (x(); a(); t(); float+ [o]p())



=for ref

probability density function for two-parameter gamma distribution.


  

=for bad

pdf_gamma processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*pdf_gamma = \&PDLA::pdf_gamma;





=head2 mle_gaussian

=for sig

  Signature: (a(n); float+ [o]m(); float+ [o]v())



=for usage

    my ($m, $v) = $data->mle_gaussian();

=for ref

gaussian aka normal distribution. same results as $data->average and $data->var. mle same as method of moments estimate.


  

=for bad

mle_gaussian processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*mle_gaussian = \&PDLA::mle_gaussian;





=head2 pdf_gaussian

=for sig

  Signature: (x(); m(); v(); float+ [o]p())



=for ref

probability density function for gaussian distribution.


  

=for bad

pdf_gaussian processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*pdf_gaussian = \&PDLA::pdf_gaussian;





=head2 mle_geo

=for sig

  Signature: (a(n); float+ [o]p())



=for ref

geometric distribution. mle same as method of moments estimate.


  

=for bad

mle_geo processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*mle_geo = \&PDLA::mle_geo;





=head2 pmf_geo

=for sig

  Signature: (ushort x(); p(); float+ [o]out())



=for ref

probability mass function for geometric distribution. x >= 0.


  

=for bad

pmf_geo processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*pmf_geo = \&PDLA::pmf_geo;





=head2 mle_geosh

=for sig

  Signature: (a(n); float+ [o]p())



=for ref

shifted geometric distribution. mle same as method of moments estimate.


  

=for bad

mle_geosh processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*mle_geosh = \&PDLA::mle_geosh;





=head2 pmf_geosh

=for sig

  Signature: (ushort x(); p(); float+ [o]out())



=for ref

probability mass function for shifted geometric distribution. x >= 1.


  

=for bad

pmf_geosh processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*pmf_geosh = \&PDLA::pmf_geosh;





=head2 mle_lognormal

=for sig

  Signature: (a(n); float+ [o]m(); float+ [o]v())



=for usage

    my ($m, $v) = $data->mle_lognormal();

=for ref

lognormal distribution. maximum likelihood estimation.


  

=for bad

mle_lognormal processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*mle_lognormal = \&PDLA::mle_lognormal;





=head2 mme_lognormal

=for sig

  Signature: (a(n); float+ [o]m(); float+ [o]v())



=for usage

    my ($m, $v) = $data->mme_lognormal();

=for ref

lognormal distribution. method of moments estimation.


  

=for bad

mme_lognormal processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*mme_lognormal = \&PDLA::mme_lognormal;





=head2 pdf_lognormal

=for sig

  Signature: (x(); m(); v(); float+ [o]p())



=for ref

probability density function for lognormal distribution. x > 0. v > 0.


  

=for bad

pdf_lognormal processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*pdf_lognormal = \&PDLA::pdf_lognormal;





=head2 mme_nbd

=for sig

  Signature: (a(n); float+ [o]r(); float+ [o]p())



=for usage

    my ($r, $p) = $data->mme_nbd();

=for ref

negative binomial distribution. pmf: f(x; r,p) = (x+r-1  r-1) p^r (1-p)^x for x=0,1,2...


  

=for bad

mme_nbd processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*mme_nbd = \&PDLA::mme_nbd;





=head2 pmf_nbd

=for sig

  Signature: (ushort x(); r(); p(); float+ [o]out())



=for ref

probability mass function for negative binomial distribution.


  

=for bad

pmf_nbd processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*pmf_nbd = \&PDLA::pmf_nbd;





=head2 mme_pareto

=for sig

  Signature: (a(n); float+ [o]k(); float+ [o]xm())



=for usage

    my ($k, $xm) = $data->mme_pareto();

=for ref

pareto distribution. pdf: f(x; k,xm) = k xm^k / x^(k+1) for x >= xm > 0.


  

=for bad

mme_pareto processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*mme_pareto = \&PDLA::mme_pareto;





=head2 pdf_pareto

=for sig

  Signature: (x(); k(); xm(); float+ [o]p())



=for ref

probability density function for pareto distribution. x >= xm > 0.


  

=for bad

pdf_pareto processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*pdf_pareto = \&PDLA::pdf_pareto;





=head2 mle_poisson

=for sig

  Signature: (a(n); float+ [o]l())



=for usage

    my $lamda = $data->mle_poisson();

=for ref

poisson distribution. pmf: f(x;l) = e^(-l) * l^x / x!


  

=for bad

mle_poisson processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*mle_poisson = \&PDLA::mle_poisson;





=head2 pmf_poisson

=for sig

  Signature: (x(); l(); float+ [o]p())



=for ref

Probability mass function for poisson distribution. Uses Stirling's formula for x > 85.


  

=for bad

pmf_poisson processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*pmf_poisson = \&PDLA::pmf_poisson;





=head2 pmf_poisson_stirling

=for sig

  Signature: (x(); l(); [o]p())



=for ref

Probability mass function for poisson distribution. Uses Stirling's formula for all values of the input. See http://en.wikipedia.org/wiki/Stirling's_approximation for more info.


  

=for bad

pmf_poisson_stirling processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*pmf_poisson_stirling = \&PDLA::pmf_poisson_stirling;




=head2 pmf_poisson_factorial

=for sig

  Signature: ushort x(); l(); float+ [o]p()

=for ref

Probability mass function for poisson distribution. Input is limited to x < 170 to avoid gsl_sf_fact() overflow.

=cut

*pmf_poisson_factorial = \&PDLA::pmf_poisson_factorial;
sub PDLA::pmf_poisson_factorial {
	my ($x, $l) = @_;

	my $pdlx = pdl($x);
	if (any( $pdlx >= 170 )) {
		croak "Does not support input greater than 170. Please use pmf_poisson or pmf_poisson_stirling instead.";
	} else {
		return _pmf_poisson_factorial(@_);
	}
}





*_pmf_poisson_factorial = \&PDLA::_pmf_poisson_factorial;



;


=head2 plot_distr

=for ref

Plots data distribution. When given specific distribution(s) to fit, returns % ref to sum log likelihood and parameter values under fitted distribution(s). See FUNCTIONS above for available distributions. 

=for options

Default options (case insensitive):

    MAXBN => 20, 
      # see PDLA::Graphics::PGPLOT::Window for next options
    WIN   => undef,   # pgwin object. not closed here if passed
                      # allows comparing multiple distr in same plot
                      # set env before passing WIN
    DEV   => '/xs' ,  # open and close dev for plotting if no WIN
                      # defaults to '/png' in Windows
    COLOR => 1,       # color for data distr

=for usage

Usage:

      # yes it threads :)
    my $data = grandom( 500, 3 )->abs;
      # ll on plot is sum across 3 data curves
    my ($ll, $pars)
      = $data->plot_distr( 'gaussian', 'lognormal', {DEV=>'/png'} );

      # pars are from normalized data (ie data / bin_size)
    print "$_\t@{$pars->{$_}}\n" for (sort keys %$pars);
    print "$_\t$ll->{$_}\n" for (sort keys %$ll);

=cut

*plot_distr = \&PDLA::plot_distr;
sub PDLA::plot_distr {
  if (!$PGPLOT) {
    carp "No PDLA::Graphics::PGPLOT, no plot :(";
    return;
  }
  my ($self, @distr) = @_;

  my %opt = (
    MAXBN => 20, 
    WIN   => undef,     # pgwin object. not closed here if passed
    DEV   => $DEV,      # open and close default win if no WIN
    COLOR => 1,         # color for data distr
  );
  my $opt = pop @distr
    if ref $distr[-1] eq 'HASH';
  $opt and $opt{uc $_} = $opt->{$_} for (keys %$opt);

  $self = $self->squeeze;

    # use int range, step etc for int xvals--pmf compatible
  my $INT = 1
    if grep { /(?:binomial)|(?:geo)|(?:nbd)|(?:poisson)/ } @distr;

  my ($range, $step, $step_int);
  $range = $self->max - $self->min;
  $step  = $range / $opt{MAXBN};
  $step_int = ($range <= $opt{MAXBN})? 1 
            :                          PDLA::ceil( $range / $opt{MAXBN} )
            ;
    # use min to make it pure scalar for sequence()
  $opt{MAXBN} = PDLA::ceil( $range / $step )->min;

  my $hist = $self->double->histogram($step, $self->min, $opt{MAXBN});
    # turn fre into prob
  $hist /= $self->dim(0);

  my $xvals = $self->min + sequence( $opt{MAXBN} ) * $step;
  my $xvals_int
    = PDLA::ceil($self->min) + sequence( $opt{MAXBN} ) * $step_int;
  $xvals_int = $xvals_int->where( $xvals_int <= $xvals->max )->sever;

  my $win = $opt{WIN};
  if (!$win) {
    $win = pgwin( Dev=>$opt{DEV} );
    $win->env($xvals->minmax,0,1, {XTitle=>'xvals', YTitle=>'probability'});
  }

  $win->line( $xvals, $hist, { COLOR=>$opt{COLOR} } );

  if (!@distr) {
    $win->close
      unless defined $opt{WIN};
    return;
  }

  my (%ll, %pars, @text, $c);
  $c = $opt{COLOR};        # fitted lines start from ++$c
  for my $distr ( @distr ) {
      # find mle_ or mme_$distr;
    my @funcs = grep { /_$distr$/ } (keys %PDLA::Stats::Distr::);
    if (!@funcs) {
      carp "Do not recognize $distr distribution!";
      next;
    }
      # might have mle and mme for a distr. sort so mle comes first 
    @funcs = sort @funcs;
    my ($f_para, $f_prob) = @funcs[0, -1];

    my $nrmd = $self / $step;
    eval {
      my @paras = $nrmd->$f_para();
      $pars{$distr} = \@paras;
  
      @paras = map { $_->dummy(0) } @paras;
      $ll{$distr} = $nrmd->$f_prob( @paras )->log->sumover;
      push @text, sprintf "$distr  LL = %.2f", $ll{$distr}->sum;

      if ($f_prob =~ /^pdf/) { 
        $win->line( $xvals, ($xvals/$step)->$f_prob(@paras), {COLOR=>++$c} );
      }
      else {
        $win->points( $xvals_int, ($xvals_int/$step_int)->$f_prob(@paras), {COLOR=>++$c} );
      }
    };
    carp $@ if $@;
  }
  $win->legend(\@text, ($xvals->min + $xvals->max)/2, .95,
               {COLOR=>[$opt{COLOR}+1 .. $c], TextFraction=>.75} );
  $win->close
    unless defined $opt{WIN};
  return (\%ll, \%pars);
}

=head1 DEPENDENCIES

GSL - GNU Scientific Library

=head1 SEE ALSO

PDLA::Graphics::PGPLOT

PDLA::GSL::CDF

=head1 AUTHOR

Copyright (C) 2009 Maggie J. Xiong <maggiexyz users.sourceforge.net>, David Mertens

All rights reserved. There is no warranty. You are allowed to redistribute this software / documentation as described in the file COPYING in the PDLA distribution.

=cut





# Exit with OK status

1;

		   
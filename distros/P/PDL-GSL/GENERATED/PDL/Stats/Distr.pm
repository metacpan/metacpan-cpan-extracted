#
# GENERATED WITH PDL::PP from lib/PDL/Stats/Distr.pd! Don't modify!
#
package PDL::Stats::Distr;

our @EXPORT_OK = qw(mme_beta pdf_beta mme_binomial pmf_binomial mle_exp pdf_exp mme_gamma pdf_gamma mle_gaussian pdf_gaussian mle_geo pmf_geo mle_geosh pmf_geosh mle_lognormal mme_lognormal pdf_lognormal mme_nbd pmf_nbd mme_pareto pdf_pareto mle_poisson pmf_poisson pmf_poisson_stirling pmf_poisson_factorial );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Stats::Distr ;








#line 7 "lib/PDL/Stats/Distr.pd"

use strict;
use warnings;

use Carp;
use PDL::LiteF;

=head1 NAME

PDL::Stats::Distr -- parameter estimations and probability density functions for distributions.

=head1 DESCRIPTION

Parameter estimate is maximum likelihood estimate when there is closed form estimate, otherwise it is method of moments estimate.

=head1 SYNOPSIS

    use PDL::LiteF;
    use PDL::Stats::Distr;

    # do a frequency (probability) plot with fitted normal curve
    my $data = grandom(100)->abs;

    my ($xvals, $hist) = $data->hist;

      # turn frequency into probability
    $hist /= $data->nelem;

      # get maximum likelihood estimates of normal curve parameters
    my ($m, $v) = $data->mle_gaussian();

      # fitted normal curve probabilities
    my $p = $xvals->pdf_gaussian($m, $v);
    use PDL::Graphics::Simple;
    my $win = pgswin();
    $win->plot( with=>'bins', $hist, with=>'lines', style => 2, $p );
    undef $win; # to close

Or, play with different distributions with B<plot_distr> :)

    $data->plot_distr( 'gaussian', 'lognormal' );

=cut
#line 71 "lib/PDL/Stats/Distr.pm"


=head1 FUNCTIONS

=cut






=head2 mme_beta

=for sig

 Signature: (a(n); float+ [o]alpha(); float+ [o]beta())
 Types: (float double ldouble)

=for usage

    my ($a, $b) = $data->mme_beta();

=for ref

beta distribution. pdf: f(x; a,b) = 1/B(a,b) x^(a-1) (1-x)^(b-1)

=pod

Broadcasts over its inputs.

=for bad

C<mme_beta> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*mme_beta = \&PDL::mme_beta;






=head2 pdf_beta

=for sig

 Signature: (x(); a(); b(); float+ [o]p())
 Types: (float double ldouble)

=for usage

 $p = pdf_beta($x, $a, $b);
 pdf_beta($x, $a, $b, $p);  # all arguments given
 $p = $x->pdf_beta($a, $b); # method call
 $x->pdf_beta($a, $b, $p);

=for ref

probability density function for beta distribution. x defined on [0,1].

=pod

Broadcasts over its inputs.

=for bad

C<pdf_beta> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*pdf_beta = \&PDL::pdf_beta;






=head2 mme_binomial

=for sig

 Signature: (a(n); int [o]n_(); float+ [o]p())
 Types: (float double ldouble)

=for usage

    my ($n, $p) = $data->mme_binomial;

=for ref

binomial distribution. pmf: f(k; n,p) = (n k) p^k (1-p)^(n-k) for k = 0,1,2..n

=pod

Broadcasts over its inputs.

=for bad

C<mme_binomial> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*mme_binomial = \&PDL::mme_binomial;






=head2 pmf_binomial

=for sig

 Signature: (ushort x(); ushort n(); p(); float+ [o]out())
 Types: (float double ldouble)

=for usage

 $out = pmf_binomial($x, $n, $p);
 pmf_binomial($x, $n, $p, $out);  # all arguments given
 $out = $x->pmf_binomial($n, $p); # method call
 $x->pmf_binomial($n, $p, $out);

=for ref

probability mass function for binomial distribution.

=pod

Broadcasts over its inputs.

=for bad

C<pmf_binomial> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*pmf_binomial = \&PDL::pmf_binomial;






=head2 mle_exp

=for sig

 Signature: (a(n); float+ [o]l())
 Types: (float double ldouble)

=for usage

    my $lamda = $data->mle_exp;

=for ref

exponential distribution. mle same as method of moments estimate.

=pod

Broadcasts over its inputs.

=for bad

C<mle_exp> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*mle_exp = \&PDL::mle_exp;






=head2 pdf_exp

=for sig

 Signature: (x(); l(); float+ [o]p())
 Types: (float double ldouble)

=for usage

 $p = pdf_exp($x, $l);
 pdf_exp($x, $l, $p);  # all arguments given
 $p = $x->pdf_exp($l); # method call
 $x->pdf_exp($l, $p);

=for ref

probability density function for exponential distribution.

=pod

Broadcasts over its inputs.

=for bad

C<pdf_exp> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*pdf_exp = \&PDL::pdf_exp;






=head2 mme_gamma

=for sig

 Signature: (a(n); float+ [o]shape(); float+ [o]scale())
 Types: (float double ldouble)

=for usage

    my ($shape, $scale) = $data->mme_gamma();

=for ref

two-parameter gamma distribution

=pod

Broadcasts over its inputs.

=for bad

C<mme_gamma> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*mme_gamma = \&PDL::mme_gamma;






=head2 pdf_gamma

=for sig

 Signature: (x(); a(); t(); float+ [o]p())
 Types: (float double ldouble)

=for usage

 $p = pdf_gamma($x, $a, $t);
 pdf_gamma($x, $a, $t, $p);  # all arguments given
 $p = $x->pdf_gamma($a, $t); # method call
 $x->pdf_gamma($a, $t, $p);

=for ref

probability density function for two-parameter gamma distribution.

=pod

Broadcasts over its inputs.

=for bad

C<pdf_gamma> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*pdf_gamma = \&PDL::pdf_gamma;






=head2 mle_gaussian

=for sig

 Signature: (a(n); float+ [o]m(); float+ [o]v())
 Types: (float double ldouble)

=for usage

    my ($m, $v) = $data->mle_gaussian();

=for ref

gaussian aka normal distribution. same results as $data->average and $data->var. mle same as method of moments estimate.

=pod

Broadcasts over its inputs.

=for bad

C<mle_gaussian> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*mle_gaussian = \&PDL::mle_gaussian;






=head2 pdf_gaussian

=for sig

 Signature: (x(); m(); v(); float+ [o]p())
 Types: (float double ldouble)

=for usage

 $p = pdf_gaussian($x, $m, $v);
 pdf_gaussian($x, $m, $v, $p);  # all arguments given
 $p = $x->pdf_gaussian($m, $v); # method call
 $x->pdf_gaussian($m, $v, $p);

=for ref

probability density function for gaussian distribution.

=pod

Broadcasts over its inputs.

=for bad

C<pdf_gaussian> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*pdf_gaussian = \&PDL::pdf_gaussian;






=head2 mle_geo

=for sig

 Signature: (a(n); float+ [o]p())
 Types: (float double ldouble)

=for usage

 $p = mle_geo($a);
 mle_geo($a, $p);  # all arguments given
 $p = $a->mle_geo; # method call
 $a->mle_geo($p);

=for ref

geometric distribution. mle same as method of moments estimate.

=pod

Broadcasts over its inputs.

=for bad

C<mle_geo> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*mle_geo = \&PDL::mle_geo;






=head2 pmf_geo

=for sig

 Signature: (ushort x(); p(); float+ [o]out())
 Types: (float double ldouble)

=for usage

 $out = pmf_geo($x, $p);
 pmf_geo($x, $p, $out);  # all arguments given
 $out = $x->pmf_geo($p); # method call
 $x->pmf_geo($p, $out);

=for ref

probability mass function for geometric distribution. x >= 0.

=pod

Broadcasts over its inputs.

=for bad

C<pmf_geo> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*pmf_geo = \&PDL::pmf_geo;






=head2 mle_geosh

=for sig

 Signature: (a(n); float+ [o]p())
 Types: (float double ldouble)

=for usage

 $p = mle_geosh($a);
 mle_geosh($a, $p);  # all arguments given
 $p = $a->mle_geosh; # method call
 $a->mle_geosh($p);

=for ref

shifted geometric distribution. mle same as method of moments estimate.

=pod

Broadcasts over its inputs.

=for bad

C<mle_geosh> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*mle_geosh = \&PDL::mle_geosh;






=head2 pmf_geosh

=for sig

 Signature: (ushort x(); p(); float+ [o]out())
 Types: (float double ldouble)

=for usage

 $out = pmf_geosh($x, $p);
 pmf_geosh($x, $p, $out);  # all arguments given
 $out = $x->pmf_geosh($p); # method call
 $x->pmf_geosh($p, $out);

=for ref

probability mass function for shifted geometric distribution. x >= 1.

=pod

Broadcasts over its inputs.

=for bad

C<pmf_geosh> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*pmf_geosh = \&PDL::pmf_geosh;






=head2 mle_lognormal

=for sig

 Signature: (a(n); float+ [o]m(); float+ [o]v())
 Types: (float double ldouble)

=for usage

    my ($m, $v) = $data->mle_lognormal();

=for ref

lognormal distribution. maximum likelihood estimation.

=pod

Broadcasts over its inputs.

=for bad

C<mle_lognormal> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*mle_lognormal = \&PDL::mle_lognormal;






=head2 mme_lognormal

=for sig

 Signature: (a(n); float+ [o]m(); float+ [o]v())
 Types: (float double ldouble)

=for usage

    my ($m, $v) = $data->mme_lognormal();

=for ref

lognormal distribution. method of moments estimation.

=pod

Broadcasts over its inputs.

=for bad

C<mme_lognormal> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*mme_lognormal = \&PDL::mme_lognormal;






=head2 pdf_lognormal

=for sig

 Signature: (x(); m(); v(); float+ [o]p())
 Types: (float double ldouble)

=for usage

 $p = pdf_lognormal($x, $m, $v);
 pdf_lognormal($x, $m, $v, $p);  # all arguments given
 $p = $x->pdf_lognormal($m, $v); # method call
 $x->pdf_lognormal($m, $v, $p);

=for ref

probability density function for lognormal distribution. x > 0. v > 0.

=pod

Broadcasts over its inputs.

=for bad

C<pdf_lognormal> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*pdf_lognormal = \&PDL::pdf_lognormal;






=head2 mme_nbd

=for sig

 Signature: (a(n); float+ [o]r(); float+ [o]p())
 Types: (float double ldouble)

=for usage

    my ($r, $p) = $data->mme_nbd();

=for ref

negative binomial distribution. pmf: f(x; r,p) = (x+r-1  r-1) p^r (1-p)^x for x=0,1,2...

=pod

Broadcasts over its inputs.

=for bad

C<mme_nbd> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*mme_nbd = \&PDL::mme_nbd;






=head2 pmf_nbd

=for sig

 Signature: (ushort x(); r(); p(); float+ [o]out())
 Types: (float double ldouble)

=for usage

 $out = pmf_nbd($x, $r, $p);
 pmf_nbd($x, $r, $p, $out);  # all arguments given
 $out = $x->pmf_nbd($r, $p); # method call
 $x->pmf_nbd($r, $p, $out);

=for ref

probability mass function for negative binomial distribution.

=pod

Broadcasts over its inputs.

=for bad

C<pmf_nbd> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*pmf_nbd = \&PDL::pmf_nbd;






=head2 mme_pareto

=for sig

 Signature: (a(n); float+ [o]k(); float+ [o]xm())
 Types: (float double ldouble)

=for usage

    my ($k, $xm) = $data->mme_pareto();

=for ref

pareto distribution. pdf: f(x; k,xm) = k xm^k / x^(k+1) for x >= xm > 0.

=pod

Broadcasts over its inputs.

=for bad

C<mme_pareto> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*mme_pareto = \&PDL::mme_pareto;






=head2 pdf_pareto

=for sig

 Signature: (x(); k(); xm(); float+ [o]p())
 Types: (float double ldouble)

=for usage

 $p = pdf_pareto($x, $k, $xm);
 pdf_pareto($x, $k, $xm, $p);  # all arguments given
 $p = $x->pdf_pareto($k, $xm); # method call
 $x->pdf_pareto($k, $xm, $p);

=for ref

probability density function for pareto distribution. x >= xm > 0.

=pod

Broadcasts over its inputs.

=for bad

C<pdf_pareto> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*pdf_pareto = \&PDL::pdf_pareto;






=head2 mle_poisson

=for sig

 Signature: (a(n); float+ [o]l())
 Types: (float double ldouble)

=for usage

    my $lamda = $data->mle_poisson();

=for ref

poisson distribution. pmf: f(x;l) = e^(-l) * l^x / x!

=pod

Broadcasts over its inputs.

=for bad

C<mle_poisson> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*mle_poisson = \&PDL::mle_poisson;






=head2 pmf_poisson

=for sig

 Signature: (x(); l(); float+ [o]p())
 Types: (float double ldouble)

=for usage

 $p = pmf_poisson($x, $l);
 pmf_poisson($x, $l, $p);  # all arguments given
 $p = $x->pmf_poisson($l); # method call
 $x->pmf_poisson($l, $p);

=for ref

Probability mass function for poisson distribution. Uses Stirling's formula for x > 85.

=pod

Broadcasts over its inputs.

=for bad

C<pmf_poisson> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*pmf_poisson = \&PDL::pmf_poisson;






=head2 pmf_poisson_stirling

=for sig

 Signature: (x(); l(); [o]p())
 Types: (float double ldouble)

=for usage

 $p = pmf_poisson_stirling($x, $l);
 pmf_poisson_stirling($x, $l, $p);  # all arguments given
 $p = $x->pmf_poisson_stirling($l); # method call
 $x->pmf_poisson_stirling($l, $p);

=for ref

Probability mass function for poisson distribution. Uses Stirling's formula for all values of the input. See http://en.wikipedia.org/wiki/Stirling's_approximation for more info.

=pod

Broadcasts over its inputs.

=for bad

C<pmf_poisson_stirling> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*pmf_poisson_stirling = \&PDL::pmf_poisson_stirling;






=head2 pmf_poisson_factorial

=for sig

 Signature: (ushort x(); l(); float+ [o]p())
 Types: (float double ldouble)

=for usage

 $p = pmf_poisson_factorial($x, $l);
 pmf_poisson_factorial($x, $l, $p);  # all arguments given
 $p = $x->pmf_poisson_factorial($l); # method call
 $x->pmf_poisson_factorial($l, $p);

=for ref

Probability mass function for poisson distribution. Input is limited to x < 170 to avoid gsl_sf_fact() overflow.

=pod

Broadcasts over its inputs.

=for bad

C<pmf_poisson_factorial> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





#line 646 "lib/PDL/Stats/Distr.pd"
sub PDL::pmf_poisson_factorial {
  my ($x, $l) = @_;
  my $pdlx = PDL->topdl($x);
  croak "Does not support input greater than 170. Please use pmf_poisson or pmf_poisson_stirling instead."
    if any($pdlx >= 170);
  PDL::_pmf_poisson_factorial_int($pdlx, $l, my $p = PDL->null);
  $p;
}
#line 1031 "lib/PDL/Stats/Distr.pm"

*pmf_poisson_factorial = \&PDL::pmf_poisson_factorial;







#line 662 "lib/PDL/Stats/Distr.pd"

#line 663 "lib/PDL/Stats/Distr.pd"

=head2 plot_distr

=for ref

Plots data distribution. When given specific distribution(s) to fit, returns % ref to sum log likelihood and parameter values under fitted distribution(s). See FUNCTIONS above for available distributions.

=for options

Default options (case insensitive):

    MAXBN => 20,
      # see PDL::Graphics::Simple for next options
    WIN   => undef,   # pgswin object. not closed here if passed
                      # allows comparing multiple distr in same plot
                      # set env before passing WIN
    COLOR => 1,       # "style" for data distr

=for usage

Usage:

      # yes it threads :)
    my $data = grandom( 500, 3 )->abs;
      # ll on plot is sum across 3 data curves
    my ($ll, $pars)
      = $data->plot_distr( 'gaussian', 'lognormal' );

      # pars are from normalized data (ie data / bin_size)
    print "$_\t@{$pars->{$_}}\n" for (sort keys %$pars);
    print "$_\t$ll->{$_}\n" for (sort keys %$ll);

=cut

*plot_distr = \&PDL::plot_distr;
sub PDL::plot_distr {
  require PDL::Graphics::Simple;
  my ($self, @distr) = @_;

  my %opt = (
    MAXBN => 20,
    WIN   => undef,     # pgswin object. not closed here if passed
    COLOR => 1,         # "style" for data distr
  );
  my $opt = ref($distr[-1]) eq 'HASH' ? pop @distr : undef;
  $opt and $opt{uc $_} = $opt->{$_} for (keys %$opt);

  $self = $self->squeeze;

    # use int range, step etc for int xvals--pmf compatible
  my $INT = !!grep { /(?:binomial)|(?:geo)|(?:nbd)|(?:poisson)/ } @distr;

  my ($range, $step, $step_int);
  $range = $self->max->sclr - $self->min->sclr;
  $step  = $range / $opt{MAXBN};
  $step_int = ($range <= $opt{MAXBN})? 1
            :                          PDL::ceil( $range / $opt{MAXBN} )
            ;
  $opt{MAXBN} = PDL::ceil( $range / $step )->min->sclr;

  my $hist = $self->double->histogram($step, $self->min->sclr, $opt{MAXBN});
    # turn fre into prob
  $hist /= $self->dim(0);

  my $xvals = $self->min->sclr + sequence( $opt{MAXBN} ) * $step;
  my $xvals_int
    = PDL::ceil($self->min->sclr) + sequence( $opt{MAXBN} ) * $step_int;
  $xvals_int = $xvals_int->where( $xvals_int <= $xvals->max )->sever;
  my $win = $opt{WIN} || PDL::Graphics::Simple::pgswin();
  my $inc = 0; # key only once
  $win->plot((map +(with=>'lines', style=>$opt{COLOR}, ($inc++?():(key=>"Base")), $xvals, $_), $hist->dog), {
    xlabel=>'xvals', ylabel=>'probability',
    legend=>'tc', # top centre
  });
  return if !@distr;

  my (%ll, %pars);
  my $c = $opt{COLOR};        # fitted lines start from ++$c
  for my $distr ( @distr ) {
      # find mle_ or mme_$distr;
    my @funcs = grep { /_$distr$/ } (keys %PDL::Stats::Distr::);
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
      my %curve_opts = (style=>++$c, key=>sprintf("$distr  LL = %.2f", $ll{$distr}->sum));
      my $inc = 0; # curve_opts only once
      if ($f_prob =~ /^pdf/) {
        $win->oplot( map +(with=>'lines', ($inc++?():%curve_opts), $xvals, $_), ($xvals/$step)->$f_prob(@paras)->dog );
      } else {
        $win->oplot( with=>'points', %curve_opts, $xvals_int, ($xvals_int/$step_int)->$f_prob(@paras) );
      }
    };
    carp $@ if $@;
  }
  return (\%ll, \%pars);
}

=head1 DEPENDENCIES

GSL - GNU Scientific Library

=head1 SEE ALSO

L<PDL::Graphics::Simple>

L<PDL::GSL::CDF>

=head1 AUTHOR

Copyright (C) 2009 Maggie J. Xiong <maggiexyz users.sourceforge.net>, David Mertens

All rights reserved. There is no warranty. You are allowed to redistribute this software / documentation as described in the file COPYING in the PDL distribution.

=cut
#line 1169 "lib/PDL/Stats/Distr.pm"

# Exit with OK status

1;

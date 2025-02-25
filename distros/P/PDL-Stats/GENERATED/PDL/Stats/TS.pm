#
# GENERATED WITH PDL::PP from lib/PDL/Stats/TS.pd! Don't modify!
#
package PDL::Stats::TS;

our @EXPORT_OK = qw(acf acvf dseason fill_ma filter_exp filter_ma mae mape wmape portmanteau pred_ar );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Stats::TS ;








#line 6 "lib/PDL/Stats/TS.pd"

=encoding utf8

=head1 NAME

PDL::Stats::TS -- basic time series functions

=head1 DESCRIPTION

The terms FUNCTIONS and METHODS are arbitrarily used to refer to
methods that are threadable and methods that are NOT threadable,
respectively. Plots require L<PDL::Graphics::Simple>.

***EXPERIMENTAL!*** In particular, bad value support is spotty and may be shaky. USE WITH DISCRETION!

=head1 SYNOPSIS

    use PDL::LiteF;
    use PDL::Stats::TS;

    my $r = $data->acf(5);

=cut

use strict;
use warnings;
use Carp;
use PDL::LiteF;
use PDL::Stats::Basic;
use PDL::Stats::Kmeans;
#line 58 "lib/PDL/Stats/TS.pm"


=head1 FUNCTIONS

=cut






=head2 acf

=for sig

 Signature: (x(t); [o]r(h); IV lag=>h)
 Types: (float double)

=for usage

 $r = acf($x, $lag);
 acf($x, $r, $lag);  # all arguments given
 $r = $x->acf($lag); # method call
 $x->acf($r, $lag);

=for ref

Autocorrelation function for up to lag h. If h is not specified it's set to t-1 by default.

acf does not process bad values.

=for example

usage:

    pdl> $a = sequence 10

    # lags 0 .. 5

    pdl> p $a->acf(5)
    [1 0.7 0.41212121 0.14848485 -0.078787879 -0.25757576]

=pod

Broadcasts over its inputs.

=for bad

C<acf> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





#line 79 "lib/PDL/Stats/TS.pd"
sub PDL::acf {
  my ($self, $h) = @_;
  $h ||= $self->dim(0) - 1;
  PDL::_acf_int($self, my $r = PDL->null, $h+1);
  $r;
}
#line 123 "lib/PDL/Stats/TS.pm"

*acf = \&PDL::acf;






=head2 acvf

=for sig

 Signature: (x(t); [o]v(h); IV lag=>h)
 Types: (float double)

=for usage

 $v = acvf($x, $lag);
 acvf($x, $v, $lag);  # all arguments given
 $v = $x->acvf($lag); # method call
 $x->acvf($v, $lag);

=for ref

Autocovariance function for up to lag h. If h is not specified it's set to t-1 by default.

acvf does not process bad values.

=for example

usage:

    pdl> $a = sequence 10

    # lags 0 .. 5

    pdl> p $a->acvf(5)
    [82.5 57.75 34 12.25 -6.5 -21.25]

    # autocorrelation

    pdl> p $a->acvf(5) / $a->acvf(0)
    [1 0.7 0.41212121 0.14848485 -0.078787879 -0.25757576]

=pod

Broadcasts over its inputs.

=for bad

C<acvf> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





#line 134 "lib/PDL/Stats/TS.pd"
sub PDL::acvf {
  my ($self, $h) = @_;
  $h ||= $self->dim(0) - 1;
  PDL::_acvf_int($self, my $v = PDL->null, $h+1);
  $v;
}
#line 190 "lib/PDL/Stats/TS.pm"

*acvf = \&PDL::acvf;






=head2 dseason

=for sig

 Signature: (x(t); indx d(); [o]xd(t))
 Types: (float double)

=for usage

 $xd = dseason($x, $d);
 dseason($x, $d, $xd);  # all arguments given
 $xd = $x->dseason($d); # method call
 $x->dseason($d, $xd);

=for ref

Deseasonalize data using moving average filter the size of period d.

=pod

Broadcasts over its inputs.

=for bad

C<dseason> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*dseason = \&PDL::dseason;






=head2 fill_ma

=for sig

 Signature: (x(t); indx q(); [o]xf(t))
 Types: (float double)

=for usage

 $xf = fill_ma($x, $q);
 fill_ma($x, $q, $xf);  # all arguments given
 $xf = $x->fill_ma($q); # method call
 $x->fill_ma($q, $xf);

=for ref

Fill missing value with moving average. xf(t) = sum(x(t-q .. t-1, t+1 .. t+q)) / 2q.

=for bad

fill_ma does handle bad values. Output pdl bad flag is cleared unless the specified window size q is too small and there are still bad values.

=pod

Broadcasts over its inputs.

=for bad

C<fill_ma> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





#line 251 "lib/PDL/Stats/TS.pd"
sub PDL::fill_ma {
  my ($x, $q) = @_;
  PDL::_fill_ma_int($x, $q, my $x_filled = PDL->null);
  $x_filled->check_badflag;
#  carp "ma window too small, still has bad value"
#    if $x_filled->badflag;
  return $x_filled;
}
#line 284 "lib/PDL/Stats/TS.pm"

*fill_ma = \&PDL::fill_ma;






=head2 filter_exp

=for sig

 Signature: (x(t); a(); [o]xf(t))
 Types: (float double)

=for usage

 $xf = filter_exp($x, $a);
 filter_exp($x, $a, $xf);  # all arguments given
 $xf = $x->filter_exp($a); # method call
 $x->filter_exp($a, $xf);

=for ref

Filter, exponential smoothing. xf(t) = a * x(t) + (1-a) * xf(t-1)

=pod

Broadcasts over its inputs.

=for bad

C<filter_exp> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*filter_exp = \&PDL::filter_exp;






=head2 filter_ma

=for sig

 Signature: (x(t); indx q(); [o]xf(t))
 Types: (float double)

=for usage

 $xf = filter_ma($x, $q);
 filter_ma($x, $q, $xf);  # all arguments given
 $xf = $x->filter_ma($q); # method call
 $x->filter_ma($q, $xf);

=for ref

Filter, moving average. xf(t) = sum(x(t-q .. t+q)) / (2q + 1)

=pod

Broadcasts over its inputs.

=for bad

C<filter_ma> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*filter_ma = \&PDL::filter_ma;






=head2 mae

=for sig

 Signature: (a(n); b(n); [o]c())
 Types: (float double)

=for usage

 $c = mae($a, $b);
 mae($a, $b, $c);  # all arguments given
 $c = $a->mae($b); # method call
 $a->mae($b, $c);

=for ref

Mean absolute error. MAE = 1/n * sum( abs(y - y_pred) )

=pod

Broadcasts over its inputs.

=for bad

C<mae> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*mae = \&PDL::mae;






=head2 mape

=for sig

 Signature: (a(n); b(n); [o]c())
 Types: (float double)

=for usage

 $c = mape($a, $b);
 mape($a, $b, $c);  # all arguments given
 $c = $a->mape($b); # method call
 $a->mape($b, $c);

=for ref

Mean absolute percent error. MAPE = 1/n * sum(abs((y - y_pred) / y))

=pod

Broadcasts over its inputs.

=for bad

C<mape> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*mape = \&PDL::mape;






=head2 wmape

=for sig

 Signature: (a(n); b(n); [o]c())
 Types: (float double)

=for usage

 $c = wmape($a, $b);
 wmape($a, $b, $c);  # all arguments given
 $c = $a->wmape($b); # method call
 $a->wmape($b, $c);

=for ref

Weighted mean absolute percent error. avg(abs(error)) / avg(abs(data)). Much more robust compared to mape with division by zero error (cf. Schütz, W., & Kolassa, 2006).

=pod

Broadcasts over its inputs.

=for bad

C<wmape> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*wmape = \&PDL::wmape;






=head2 portmanteau

=for sig

 Signature: (r(h); longlong t(); [o]Q())
 Types: (float double)

=for usage

 $Q = portmanteau($r, $t);
 portmanteau($r, $t, $Q);  # all arguments given
 $Q = $r->portmanteau($t); # method call
 $r->portmanteau($t, $Q);

=for ref

Portmanteau significance test (Ljung-Box) for autocorrelations.

=for example

Usage:

    pdl> $a = sequence 10

    # acf for lags 0-5
    # lag 0 excluded from portmanteau

    pdl> p $chisq = $a->acf(5)->portmanteau( $a->nelem )
    11.1753902662994

    # get p-value from chisq distr

    pdl> use PDL::GSL::CDF
    pdl> p 1 - gsl_cdf_chisq_P( $chisq, 5 )
    0.0480112934306748
  

=pod

Broadcasts over its inputs.

=for bad

C<portmanteau> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*portmanteau = \&PDL::portmanteau;






=head2 pred_ar

=for sig

 Signature: (x(p); b(p); [o]pred(t); IV end=>t)
 Types: (float double)

=for usage

 $pred = pred_ar($x, $b, $end);
 pred_ar($x, $b, $pred, $end);  # all arguments given
 $pred = $x->pred_ar($b, $end); # method call
 $x->pred_ar($b, $pred, $end);

=for ref

Calculates predicted values up to period t (extend current series up to period t) for autoregressive series, with or without constant. If there is constant, it is the last element in b, as would be returned by ols or ols_t.

pred_ar does not process bad values.

=for options

  CONST  => 1,

=for example

Usage:

    pdl> $x = sequence 2

      # last element is constant
    pdl> $b = pdl(.8, -.2, .3)

    pdl> p $x->pred_ar($b, 7)
    [0       1     1.1    0.74   0.492  0.3656 0.31408]

      # no constant
    pdl> p $x->pred_ar($b(0:1), 7, {const=>0})
    [0       1     0.8    0.44   0.192  0.0656 0.01408]

=pod

Broadcasts over its inputs.

=for bad

C<pred_ar> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





#line 425 "lib/PDL/Stats/TS.pd"
sub PDL::pred_ar {
  my ($x, $b, $t, $opt) = @_;
  my %opt = ( CONST => 1 );
  if ($opt) { $opt{uc $_} = $opt->{$_} for keys %$opt; }
  $b = PDL->topdl($b); # allows passing simple number
  my $ext;
  if ($opt{CONST}) {
    my $t_ = $t - ( $x->dim(0) - $b->dim(0) + 1 );
    PDL::_pred_ar_int($x->slice([-$b->dim(0)+1,-1]), $b->slice('0:-2'), $ext = PDL->null, $t_);
    $ext->slice([$b->dim(0)-1,-1]) += $b->slice(-1);
    return $x->append( $ext->slice([$b->dim(0)-1,-1]) );
  } else {
    my $t_ = $t - ( $x->dim(0) - $b->dim(0) );
    PDL::_pred_ar_int($x->slice([-$b->dim(0),-1]), $b, $ext = PDL->null, $t_);
    return $x->append($ext->slice([$b->dim(0),-1]));
  }
}
#line 619 "lib/PDL/Stats/TS.pm"

*pred_ar = \&PDL::pred_ar;





#line 472 "lib/PDL/Stats/TS.pd"

#line 473 "lib/PDL/Stats/TS.pd"

=head2 season_m

Given length of season, returns seasonal mean and variance for each period
(returns seasonal mean only in scalar context).

=for options

Default options (case insensitive):

    START_POSITION => 0,     # series starts at this position in season
    MISSING        => -999,  # internal mark for missing points in season
    PLOT  => 0,              # boolean
     # see PDL::Graphics::Simple for next options
    WIN   => undef,          # pass pgswin object for more plotting control
    COLOR => 1,

=for usage

    my ($m, $ms) = $data->season_m( 24, { START_POSITION=>2 } );

=cut

*season_m = \&PDL::season_m;
sub PDL::season_m {
  my ($self, $d, $opt) = @_;
  my %opt = (
    START_POSITION => 0,     # series starts at this position in season
    MISSING        => -999,  # internal mark for missing points in season
    PLOT  => 0,
    WIN   => undef,          # pass pgswin object for more plotting control
    COLOR => 1,
  );
  if ($opt) { $opt{uc $_} = $opt->{$_} for keys %$opt; }

  my $n_season = ($self->dim(0) + $opt{START_POSITION}) / $d;
  $n_season = pdl($n_season)->ceil->sum->sclr;

  my @dims = $self->dims;
  $dims[0] = $n_season * $d;
  my $data = zeroes( @dims ) + $opt{MISSING};

  $data->slice([$opt{START_POSITION},$opt{START_POSITION} + $self->dim(0)-1]) .= $self;
  $data->badflag(1);
  $data->inplace->setvaltobad( $opt{MISSING} );

  my $s = sequence $d;
  $s = $s->dummy(1, $n_season)->flat;
  $s = $s->iv_cluster();

  my ($m, $ms) = $data->centroid( $s );

  if ($opt{PLOT}) {
    require PDL::Graphics::Simple;
    my $w = $opt{WIN} || PDL::Graphics::Simple::pgswin();
    my $seq = sequence($d);
    my $errb_length = sqrt( $ms / $s->sumover )->squeeze;
    my $col = $opt{COLOR};
    my @plots = map +(with=>'lines', ke=>"Data $col", style=>$col++, $seq, $_), $m->dog;
    push @plots, with=>'errorbars', ke=>'Error', style=>$opt{COLOR}, $seq, $m->squeeze, $errb_length
      if $m->squeeze->ndims < 2 && ($errb_length > 0)->any;
    $w->plot(@plots, { xlabel=>'period', ylabel=>'mean' });
  }

  return wantarray? ($m, $ms) : $m;
}

=head2 plot_dseason

=for ref

Plots deseasonalized data and original data points. Opens and closes
default window for plotting unless a C<WIN> object is passed in
options. Returns deseasonalized data.

=for options

Default options (case insensitive):

    WIN   => undef,
    COLOR => 1,        # data point color

=cut

*plot_dseason = \&PDL::plot_dseason;
sub PDL::plot_dseason {
  require PDL::Graphics::Simple;
  my ($self, $d, $opt) = @_;
  !defined($d) and croak "please set season period length";
  $self = $self->squeeze;
  my %opt = (
      WIN   => undef,
      COLOR => 1,       # data point color
  );
  if ($opt) { $opt{uc $_} = $opt->{$_} for keys %$opt; }
  my $dsea = $self->dseason($d);
  my $w = $opt{WIN} || PDL::Graphics::Simple::pgswin();
  my $seq = sequence($self->dim(0));
  my $col = $opt{COLOR};
  my @plots = map +(with=>'lines', ke=>"Data $col", style=>$col++, $seq, $_), $dsea->dog;
  $col = $opt{COLOR};
  push @plots, map +(with=>'points', ke=>"De-seasonalised $col", style=>$col++, $seq, $_), $self->dog;
  $w->plot(@plots, { xlabel=>'T', ylabel=>'DV' });
  return $dsea;
}

=head1 METHODS

=head2 plot_acf

=for ref

Plots and returns autocorrelations for a time series.

=for options

Default options (case insensitive):

    SIG  => 0.05,      # can specify .10, .05, .01, or .001
    WIN  => undef,

=for usage

Usage:

    pdl> $a = sequence 10

    pdl> p $r = $a->plot_acf(5)
    [1 0.7 0.41212121 0.14848485 -0.078787879 -0.25757576]

=cut

*plot_acf = \&PDL::plot_acf;
sub PDL::plot_acf {
  require PDL::Graphics::Simple;
  my $opt = ref($_[-1]) eq 'HASH' ? pop @_ : undef;
  my ($self, $h) = @_;
  my $r = $self->acf($h);
  my %opt = (
    SIG => 0.05,
    WIN  => undef,
  );
  if ($opt) { $opt{uc $_} = $opt->{$_} for keys %$opt; }
  my $y_sig = ($opt{SIG} == 0.10)?   1.64485362695147
            : ($opt{SIG} == 0.05)?   1.95996398454005
            : ($opt{SIG} == 0.01)?   2.5758293035489
            : ($opt{SIG} == 0.001)?  3.29052673149193
            :                        0
            ;
  unless ($y_sig) {
    carp "SIG outside of recognized value. default to 0.05";
    $y_sig = 1.95996398454005;
  }
  my $w = $opt{WIN} || PDL::Graphics::Simple::pgswin();
  my $seq = pdl(-1,$h+1);
  my $y_seq = ones(2) * $y_sig / sqrt($self->dim(0)) * -1;
  $w->plot(
    with=>'lines', $seq, zeroes(2), # x axis
    with=>'lines', style=>2, $seq,  $y_seq,
    with=>'lines', style=>2, $seq, -$y_seq,
    (map +(with=>'lines', ones(2)*$_, pdl(0, $r->slice("($_)"))), 0..$h), { xlabel=>'lag', ylabel=>'acf', }
  );
  $r;
}

=head1 	REFERENCES

Brockwell, P.J., & Davis, R.A. (2002). Introduction to Time Series and Forecasting (2nd ed.). New York, NY: Springer.

Schütz, W., & Kolassa, S. (2006). Foresight: advantages of the MAD/Mean ratio over the MAPE. Retrieved Jan 28, 2010, from http://www.saf-ag.com/226+M5965d28cd19.html

=head1 AUTHOR

Copyright (C) 2009 Maggie J. Xiong <maggiexyz users.sourceforge.net>

All rights reserved. There is no warranty. You are allowed to redistribute this software / documentation as described in the file COPYING in the PDL distribution.

=cut
#line 808 "lib/PDL/Stats/TS.pm"

# Exit with OK status

1;

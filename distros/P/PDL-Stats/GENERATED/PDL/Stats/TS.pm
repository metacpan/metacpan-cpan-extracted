#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::Stats::TS;

our @EXPORT_OK = qw(_acf _acvf diff inte dseason _fill_ma filter_exp filter_ma mae mape wmape portmanteau _pred_ar );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Stats::TS ;







#line 1 "ts.pd"

=encoding utf8

=head1 NAME

PDL::Stats::TS -- basic time series functions

=head1 DESCRIPTION

The terms FUNCTIONS and METHODS are arbitrarily used to refer to methods that are threadable and methods that are NOT threadable, respectively. Plots require PDL::Graphics::PGPLOT.

***EXPERIMENTAL!*** In particular, bad value support is spotty and may be shaky. USE WITH DISCRETION! 

=head1 SYNOPSIS

    use PDL::LiteF;
    use PDL::NiceSlice;
    use PDL::Stats::TS;

    my $r = $data->acf(5);

=cut

use Carp;
use PDL::LiteF;
use PDL::NiceSlice;
use PDL::Stats::Basic;
use PDL::Stats::Kmeans;

my $DEV = ($^O =~ /win/i)? '/png' : '/xs';
#line 57 "TS.pm"


=head1 FUNCTIONS

=cut




*_acf = \&PDL::_acf;




*_acvf = \&PDL::_acvf;





#line 112 "ts.pd"

#line 113 "ts.pd"

=head2 acf

=for sig

  Signature: (x(t); int h(); [o]r(h+1))

=for ref

Autocorrelation function for up to lag h. If h is not specified it's set to t-1 by default.

acf does not process bad values.

=for usage

usage:

    perldl> $a = sequence 10

    # lags 0 .. 5

    perldl> p $a->acf(5)
    [1 0.7 0.41212121 0.14848485 -0.078787879 -0.25757576]

=cut

*acf = \&PDL::acf;
sub PDL::acf {
  my ($self, $h) = @_;
  $h ||= $self->dim(0) - 1;
  return $self->_acf($h+1);
}

=head2 acvf

=for sig

  Signature: (x(t); int h(); [o]v(h+1))

=for ref

Autocovariance function for up to lag h. If h is not specified it's set to t-1 by default.

acvf does not process bad values.

=for usage

usage:

    perldl> $a = sequence 10

    # lags 0 .. 5

    perldl> p $a->acvf(5)
    [82.5 57.75 34 12.25 -6.5 -21.25]

    # autocorrelation
    
    perldl> p $a->acvf(5) / $a->acvf(0)
    [1 0.7 0.41212121 0.14848485 -0.078787879 -0.25757576]

=cut

*acvf = \&PDL::acvf;
sub PDL::acvf {
  my ($self, $h) = @_;
  $h ||= $self->dim(0) - 1;
  return $self->_acvf($h+1);
}
#line 150 "TS.pm"


=head2 diff

=for sig

  Signature: (x(t); [o]dx(t))

=for ref

Differencing. DX(t) = X(t) - X(t-1), DX(0) = X(0). Can be done inplace.

=for bad

diff does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*diff = \&PDL::diff;






=head2 inte

=for sig

  Signature: (x(n); [o]ix(n))

=for ref

Integration. Opposite of differencing. IX(t) = X(t) + X(t-1), IX(0) = X(0). Can be done inplace.

=for bad

inte does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*inte = \&PDL::inte;






=head2 dseason

=for sig

  Signature: (x(t); indx d(); [o]xd(t))

=for ref

Deseasonalize data using moving average filter the size of period d.

  

=for bad

dseason processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*dseason = \&PDL::dseason;





#line 362 "ts.pd"

#line 363 "ts.pd"

=head2 fill_ma

=for sig

  Signature: (x(t); int q(); [o]xf(t))

=for ref

Fill missing value with moving average. xf(t) = sum(x(t-q .. t-1, t+1 .. t+q)) / 2q.

fill_ma does handle bad values. Output pdl bad flag is cleared unless the specified window size q is too small and there are still bad values.
 
=for usage

  my $x_filled = $x->fill_ma( $q );

=cut

*fill_ma = \&PDL::fill_ma;
sub PDL::fill_ma {
  my ($x, $q) = @_;

  my $x_filled = $x->_fill_ma($q);
  $x_filled->check_badflag;

#  carp "ma window too small, still has bad value"
#    if $x_filled->badflag;

  return $x_filled;
}
#line 269 "TS.pm"

*_fill_ma = \&PDL::_fill_ma;






=head2 filter_exp

=for sig

  Signature: (x(t); a(); [o]xf(t))

=for ref

Filter, exponential smoothing. xf(t) = a * x(t) + (1-a) * xf(t-1)

=for usage

  

=for bad

filter_exp does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*filter_exp = \&PDL::filter_exp;






=head2 filter_ma

=for sig

  Signature: (x(t); indx q(); [o]xf(t))

=for ref

Filter, moving average. xf(t) = sum(x(t-q .. t+q)) / (2q + 1)

  

=for bad

filter_ma does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*filter_ma = \&PDL::filter_ma;






=head2 mae

=for sig

  Signature: (a(n); b(n); float+ [o]c())

=for ref

Mean absolute error. MAE = 1/n * sum( abs(y - y_pred) )

=for usage

Usage:

    $mae = $y->mae( $y_pred );

=for bad

mae processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*mae = \&PDL::mae;






=head2 mape

=for sig

  Signature: (a(n); b(n); float+ [o]c())

=for ref

Mean absolute percent error. MAPE = 1/n * sum(abs((y - y_pred) / y))

=for usage

Usage:

    $mape = $y->mape( $y_pred );

=for bad

mape processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*mape = \&PDL::mape;






=head2 wmape

=for sig

  Signature: (a(n); b(n); float+ [o]c())

=for ref

Weighted mean absolute percent error. avg(abs(error)) / avg(abs(data)). Much more robust compared to mape with division by zero error (cf. Schütz, W., & Kolassa, 2006).

=for usage

Usage:

    $wmape = $y->wmape( $y_pred );

=for bad

wmape processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*wmape = \&PDL::wmape;






=head2 portmanteau

=for sig

  Signature: (r(h); longlong t(); [o]Q())

=for ref

Portmanteau significance test (Ljung-Box) for autocorrelations.

=for usage

Usage:

    perldl> $a = sequence 10

    # acf for lags 0-5
    # lag 0 excluded from portmanteau
    
    perldl> p $chisq = $a->acf(5)->portmanteau( $a->nelem )
    11.1753902662994
   
    # get p-value from chisq distr

    perldl> use PDL::GSL::CDF
    perldl> p 1 - gsl_cdf_chisq_P( $chisq, 5 )
    0.0480112934306748

  

=for bad

portmanteau does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*portmanteau = \&PDL::portmanteau;





#line 700 "ts.pd"

#line 701 "ts.pd"

=head2 pred_ar

=for sig

  Signature: (x(d); b(p|p+1); int t(); [o]pred(t))

=for ref

Calculates predicted values up to period t (extend current series up to period t) for autoregressive series, with or without constant. If there is constant, it is the last element in b, as would be returned by ols or ols_t.

pred_ar does not process bad values.

=for options

  CONST  => 1,

=for usage

Usage:

    perldl> $x = sequence 2

      # last element is constant
    perldl> $b = pdl(.8, -.2, .3)

    perldl> p $x->pred_ar($b, 7)
    [0       1     1.1    0.74   0.492  0.3656 0.31408]
 
      # no constant
    perldl> p $x->pred_ar($b(0:1), 7, {const=>0})
    [0       1     0.8    0.44   0.192  0.0656 0.01408]

=cut

sub PDL::pred_ar {
  my ($x, $b, $t, $opt) = @_;
  my %opt = ( CONST => 1 );
  $opt and $opt{uc $_} = $opt->{$_} for (keys %$opt);

  $b = pdl $b
    unless ref $b eq 'PDL';        # allows passing simple number

  my $ext;
  if ($opt{CONST}) {
    my $t_ = $t - ( $x->dim(0) - $b->dim(0) + 1 );
    $ext = $x(-$b->dim(0)+1:-1, )->_pred_ar($b(0:-2), $t_);
    $ext($b->dim(0)-1:-1) += $b(-1);
    return $x->append( $ext( $b->dim(0)-1 : -1 ) );
  }
  else {
    my $t_ = $t - ( $x->dim(0) - $b->dim(0) );
    $ext = $x(-$b->dim(0):-1, )->_pred_ar($b, $t_);
    return $x->append($ext($b->dim(0) : -1));
  }
}
#line 542 "TS.pm"

*_pred_ar = \&PDL::_pred_ar;





#line 790 "ts.pd"

#line 791 "ts.pd"

=head2 season_m

Given length of season, returns seasonal mean and var for each period (returns seasonal mean only in scalar context).

=for options

Default options (case insensitive):

    START_POSITION => 0,     # series starts at this position in season
    MISSING        => -999,  # internal mark for missing points in season
    PLOT  => 0,              # boolean
      # see PDL::Graphics::PGPLOT::Window for next options
    WIN   => undef,          # pass pgwin object for more plotting control
    DEV   => '/xs',          # open and close dev for plotting if no WIN
                             # defaults to '/png' in Windows
    COLOR => 1,

See PDL::Graphics::PGPLOT for detailed graphing options.

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
    WIN   => undef,          # pass pgwin object for more plotting control
    DEV   => $DEV,           # see PDL::Graphics::PGPLOT for more info
    COLOR => 1,
  );
  $opt and $opt{uc $_} = $opt->{$_} for (keys %$opt);
  if ($opt{PLOT}) {
    require PDL::Graphics::PGPLOT::Window;
  }

  my $n_season = ($self->dim(0) + $opt{START_POSITION}) / $d;
  $n_season = pdl($n_season)->ceil->sum->sclr;

  my @dims = $self->dims;
  $dims[0] = $n_season * $d;
  my $data = zeroes( @dims ) + $opt{MISSING};

  $data($opt{START_POSITION} : $opt{START_POSITION} + $self->dim(0)-1, ) .= $self;
  $data->badflag(1);
  $data->inplace->setvaltobad( $opt{MISSING} );

  my $s = sequence $d;
  $s = $s->dummy(1, $n_season)->flat;
  $s = $s->iv_cluster();

  my ($m, $ms) = $data->centroid( $s );

  if ($opt{PLOT}) {
    my $w = $opt{WIN};
    if (!$w) {
      $w = PDL::Graphics::PGPLOT::Window::pgwin( Dev=>$opt{DEV} );
      $w->env( 0, $d-1, $m->minmax,
              {XTitle=>'period', YTitle=>'mean'} );
    }
    $w->points( sequence($d), $m, {COLOR=>$opt{COLOR}, PLOTLINE=>1} );

    if ($m->squeeze->ndims < 2) {
      $w->errb( sequence($d), $m, sqrt( $ms / $s->sumover ),
               {COLOR=>$opt{COLOR}} );
    }
    $w->close
      unless $opt{WIN};
  }

  return wantarray? ($m, $ms) : $m;
}

=head2 plot_dseason

=for ref

Plots deseasonalized data and original data points. Opens and closes default window for plotting unless a pgwin object is passed in options. Returns deseasonalized data. 

=for options

Default options (case insensitive):

    WIN   => undef,
    DEV   => '/xs',    # open and close dev for plotting if no WIN
                       # defaults to '/png' in Windows
    COLOR => 1,        # data point color

See PDL::Graphics::PGPLOT for detailed graphing options.

=cut

*plot_dseason = \&PDL::plot_dseason;
sub PDL::plot_dseason {
  require PDL::Graphics::PGPLOT::Window;
  my ($self, $d, $opt) = @_;
  !defined($d) and croak "please set season period length";
  $self = $self->squeeze;

  my $dsea;
  my %opt = (
      WIN   => undef,
      DEV   => $DEV,
      COLOR => 1,       # data point color
  );
  $opt and $opt{uc $_} = $opt->{$_} for (keys %$opt);

  $dsea = $self->dseason($d);

  my $w = $opt{WIN};
  if (!$opt{WIN}) {
    $w = PDL::Graphics::PGPLOT::Window::pgwin( $opt{DEV} );
    $w->env( 0, $self->dim(0)-1, $self->minmax,
          {XTitle=>'T', YTitle=>'DV'} );
  }

  my $missn = ushort $self->max->sclr + 1;   # ushort in case precision issue
  $w->line( sequence($self->dim(0)), $dsea->setbadtoval( $missn ),
           {COLOR=>$opt{COLOR}+1, MISSING=>$missn} );
  $w->points( sequence($self->dim(0)), $self, {COLOR=>$opt{COLOR}} );
  $w->close
    unless $opt{WIN};

  return $dsea; 
}

*filt_exp = \&PDL::filt_exp;
sub PDL::filt_exp {
  print STDERR "filt_exp() deprecated since version 0.5.0. Please use filter_exp() instead\n";
  return filter_exp( @_ );
}

*filt_ma = \&PDL::filt_ma;
sub PDL::filt_ma {
  print STDERR "filt_ma() deprecated since version 0.5.0. Please use filter_ma() instead\n";
  return filter_ma( @_ );
}

=head1 METHODS

=head2 plot_acf

=for ref

Plots and returns autocorrelations for a time series.

=for options

Default options (case insensitive):

    SIG  => 0.05,      # can specify .10, .05, .01, or .001
    DEV  => '/xs',     # open and close dev for plotting
                       # defaults to '/png' in Windows

=for usage

Usage:

    perldl> $a = sequence 10
    
    perldl> p $r = $a->plot_acf(5)
    [1 0.7 0.41212121 0.14848485 -0.078787879 -0.25757576]

=cut

*plot_acf = \&PDL::plot_acf;
sub PDL::plot_acf {
  require PDL::Graphics::PGPLOT::Window;
  my $opt = pop @_
    if ref $_[-1] eq 'HASH';
  my ($self, $h) = @_;
  my $r = $self->acf($h);
    
  my %opt = (
      SIG => 0.05,
      DEV => $DEV,
  );
  $opt and $opt{uc $_} = $opt->{$_} for (keys %$opt);

  my $w = PDL::Graphics::PGPLOT::Window::pgwin( Dev=>$opt{DEV} );
  $w->env(-1, $h+1, -1.05, 1.05, {XTitle=>'lag', YTitle=>'acf'});
  $w->line(pdl(-1,$h+1), zeroes(2));   # x axis

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

  $w->line( pdl(-1,$h+1), ones(2) * $y_sig / sqrt($self->dim(0)),
            { LINESTYLE=>"Dashed" } );
  $w->line( pdl(-1,$h+1), ones(2) * $y_sig / sqrt($self->dim(0)) * -1,
            { LINESTYLE=>"Dashed" } );
  for my $lag (0..$h) {
    $w->line( ones(2)*$lag, pdl(0, $r($lag)) );
  }
  $w->close;

  return $r;
}

=head1 	REFERENCES

Brockwell, P.J., & Davis, R.A. (2002). Introcution to Time Series and Forecasting (2nd ed.). New York, NY: Springer.

Schütz, W., & Kolassa, S. (2006). Foresight: advantages of the MAD/Mean ratio over the MAPE. Retrieved Jan 28, 2010, from http://www.saf-ag.com/226+M5965d28cd19.html

=head1 AUTHOR

Copyright (C) 2009 Maggie J. Xiong <maggiexyz users.sourceforge.net>

All rights reserved. There is no warranty. You are allowed to redistribute this software / documentation as described in the file COPYING in the PDL distribution.

=cut
#line 778 "TS.pm"

# Exit with OK status

1;

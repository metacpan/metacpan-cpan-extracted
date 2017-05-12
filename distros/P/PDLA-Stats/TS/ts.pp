#!/usr/bin/perl

pp_addpm({At=>'Top'}, <<'EOD');

=encoding utf8

=head1 NAME

PDLA::Stats::TS -- basic time series functions

=head1 DESCRIPTION

The terms FUNCTIONS and METHODS are arbitrarily used to refer to methods that are threadable and methods that are NOT threadable, respectively. Plots require PDLA::Graphics::PGPLOT.

***EXPERIMENTAL!*** In particular, bad value support is spotty and may be shaky. USE WITH DISCRETION! 

=head1 SYNOPSIS

    use PDLA::LiteF;
    use PDLA::NiceSlice;
    use PDLA::Stats::TS;

    my $r = $data->acf(5);

=cut

use Carp;
use PDLA::LiteF;
use PDLA::NiceSlice;
use PDLA::Stats::Basic;
use PDLA::Stats::Kmeans;

$PDLA::onlinedoc->scan(__FILE__) if $PDLA::onlinedoc;

eval {
  require PDLA::Graphics::PGPLOT::Window;
  PDLA::Graphics::PGPLOT::Window->import( 'pgwin' );
};
my $PGPLOT = 1 if !$@;

my $DEV = ($^O =~ /win/i)? '/png' : '/xs';

EOD

pp_addhdr('
#include <math.h>
#define Z10  1.64485362695147
#define Z05  1.95996398454005
#define Z01  2.5758293035489
#define Z001 3.29052673149193

'
);

pp_def('_acf',
  Pars  => 'x(t); [o]r(h)',
  OtherPars => 'int lag=>h',
  GenericTypes => [F,D],
  Code  => '

$GENERIC(x) s, s2, m, cov0, covh;
s=0; s2=0; m=0; cov0=0; covh=0;
long T, i;
T = $SIZE(t);

loop(t) %{
  s += $x();
  s2 += pow($x(), 2);
%}
m = s/T;
cov0 = s2 - T * pow(m, 2);

loop (h) %{
  if (h) {
    covh = 0;
    for (i=0; i<T-h; i++) {
      covh += ($x(t=>i) - m) * ($x(t=>i+h) - m);
    }
    $r() = covh / cov0;
  }
  else {
    $r() = 1;
  }
%}
  ',
  Doc   => undef,
);

pp_def('_acvf',
  Pars  => 'x(t); [o]v(h)',
  OtherPars => 'int lag=>h;',
  GenericTypes => [F,D],
  Code  => '

$GENERIC(x) s, s2, m, covh;
s=0; s2=0; m=0; covh=0;
long T, i;
T = $SIZE(t);

loop(t) %{
  s += $x();
  s2 += pow($x(), 2);
%}
m = s/T;

loop (h) %{
  if (h) {
    covh = 0;
    for (i=0; i<T-h; i++) {
      covh += ($x(t=>i) - m) * ($x(t=>i+h) - m);
    }
    $v() = covh;
  }
  else {
    $v() = s2 - T * pow(m, 2);
  }
%}
  ',
  Doc   => undef,
);

pp_addpm(<<'EOD');

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

*acf = \&PDLA::acf;
sub PDLA::acf {
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

*acvf = \&PDLA::acvf;
sub PDLA::acvf {
  my ($self, $h) = @_;
  $h ||= $self->dim(0) - 1;
  return $self->_acvf($h+1);
}

EOD

pp_def('diff',
  Pars  => 'x(t); [o]dx(t)',
  Inplace   => 1,
  GenericTypes => [U,L,F,D],
  Code  => '

long tr;

/* do it in reverse so inplace works */

for (tr = $SIZE(t) - 1; tr >= 0; tr --) {
  if (tr) {
    $dx(t=>tr) = $x(t=>tr) - $x(t=>tr-1);
  }
  else {
    $dx(t=>tr) = $x(t=>tr);
  }
}

  ',
  Doc   => '
=for ref

Differencing. DX(t) = X(t) - X(t-1), DX(0) = X(0). Can be done inplace.

=cut

',
);

pp_def('inte',
  Pars  => 'x(n); [o]ix(n)',
  Inplace   => 1,
  GenericTypes => [F,D],
  Code  => '

$GENERIC(x) tmp;
tmp = 0;

loop(n) %{
  tmp += $x();
  $ix() = tmp;
%}

  ',
  Doc   => '
=for ref

Integration. Opposite of differencing. IX(t) = X(t) + X(t-1), IX(0) = X(0). Can be done inplace.

=cut

',
);


pp_def('dseason',
  Pars  => 'x(t); int d(); [o]xd(t)',
  GenericTypes => [F,D],
  HandleBad    => 1,
  Code  => '
$GENERIC(x) xc, sum;
int i, q, max;
q = ($d() % 2)? ($d() - 1) / 2 : $d() / 2;
max = $SIZE(t) - 1;

if ($d() % 2) {
  loop(t) %{
    sum = 0;
    for (i=-q; i<=q; i++) {
      sum += (t+i < 0)?    $x(t=>0)
           : (t+i > max)?  $x(t=>max)
           :               $x(t=>t+i)
           ;
    }
    $xd() = sum / $d();
  %}
}
else {
  loop(t) %{
    sum = 0;
    for (i=-q; i<=q; i++) {
      xc = (t+i < 0)?    $x(t=>0)
         : (t+i > max)?  $x(t=>max)
         :               $x(t=>t+i)
         ;
      sum += (i==-q || i==q)?   .5 * xc : xc;
    } 
    $xd() = sum / $d();
  %}
}

  ',
  BadCode  => '
$GENERIC(x) sum;
int i, q, min, max, ti, dd;
min = -1; max = -1;
q = ($d() % 2)? ($d() - 1) / 2 : $d() / 2;

/*find good min and max ind*/
loop (t) %{
  if ( $ISGOOD(x()) ) {
    if (min < 0) {
      min = t;
    }
    max = t;
  }
%}

if ($d() % 2) {
  loop(t) %{
    if (t < min || t > max) {
      $SETBAD(xd());
    }
    else {
      sum = 0; dd = 0;
      for (i=-q; i<=q; i++) {
        ti = (t+i < min)?  min
           : (t+i > max)?  max
           :               t+i
           ;
        if ( $ISGOOD($x(t=>ti)) ) {
          sum += $x(t=>ti);
          dd ++;
        }
      }
      if (dd) {
        $xd() = sum / dd;
      }
      else {
        $SETBAD(xd());
      }
    }
  %}
}
else {
  loop(t) %{
    if (t < min || t > max) {
      $SETBAD(xd());
    }
    else {
      sum = 0; dd = 0;
      for (i=-q; i<=q; i++) {
        ti = (t+i < min)?  min
           : (t+i > max)?  max
           :               t+i
           ;
        if ( $ISGOOD($x(t=>ti)) ) {
          sum += (i == q || i == -q)? .5 * $x(t=>ti) : $x(t=>ti);
          dd ++;
        }
      }
      if (dd) {
        dd --;
        if (  ($ISBAD(x(t=>t-q)) && $ISGOOD(x(t=>t+q)) )
           || ($ISBAD(x(t=>t+q)) && $ISGOOD(x(t=>t-q)) ) )
          dd += .5;
        $xd() = sum / dd;
      }
      else {
        $SETBAD(xd());
      }
    }
  %}
}

  ',
  Doc   => '
=for ref

Deseasonalize data using moving average filter the size of period d.

=cut

  ',
);

pp_addpm(<<'EOD');

=head2 fill_ma

=for sig

  Signature: (x(t); int q(); [o]xf(t))

=for ref

Fill missing value with moving average. xf(t) = sum(x(t-q .. t-1, t+1 .. t+q)) / 2q.

fill_ma does handle bad values. Output pdl bad flag is cleared unless the specified window size q is too small and there are still bad values.
 
=for usage

  my $x_filled = $x->fill_ma( $q );

=cut

*fill_ma = \&PDLA::fill_ma;
sub PDLA::fill_ma {
  my ($x, $q) = @_;

  my $x_filled = $x->_fill_ma($q);
  $x_filled->check_badflag;

#  carp "ma window too small, still has bad value"
#    if $x_filled->badflag;

  return $x_filled;
}

EOD

pp_def('_fill_ma',
  Pars  => 'x(t); int q(); [o]xf(t)',
  GenericTypes => [F,D],
  HandleBad    => 1,
  Code     => '
loop(t) %{
  $xf() = $x();
%}

  ',
  BadCode  => '
$GENERIC(x) sum, xx;
int i, n, max;
max = $SIZE(t) - 1;
loop(t) %{
  if ($ISBAD(x())) {
    n=0; sum=0;
    for (i=-$q(); i<=$q(); i++) {
      xx = (t+i < 0)?    $x(t=>0)
         : (t+i > max)?  $x(t=>max)
         :               $x(t=>t+i)
         ;
      if ($ISGOODVAR(xx,x)) {
        sum += xx;
        n ++;
      }
    }
    if (n) {
      $xf() = sum / n;
    }
    else {
      $SETBAD(xf());
    }
  }
  else {
    $xf() = $x();
  }
%}

  ',

  Doc   => undef,
);

pp_def('filter_exp',
  Pars  => 'x(t); a(); [o]xf(t)',
  GenericTypes => [F,D],
  Code  => '
$GENERIC(x) b, m;
b = 1 - $a();
loop(t) %{
  if (t) {
    m = $a() * $x() + b * m;
  }
  else {
    m = $x();
  }
  $xf() = m;
%}

  ',
  Doc   => '
=for ref

Filter, exponential smoothing. xf(t) = a * x(t) + (1-a) * xf(t-1)

=for usage

=cut

  ',
);

pp_def('filter_ma',
  Pars  => 'x(t); int q(); [o]xf(t)',
  GenericTypes => [F,D],
  Code  => '
$GENERIC(x) sum;
int i, n, max;
n = 2 * $q() + 1;
max = $SIZE(t) - 1;
loop(t) %{
  sum = 0;
  for (i=-$q(); i<=$q(); i++) {
    sum += (t+i < 0)?    $x(t=>0)
         : (t+i > max)?  $x(t=>max)
         :               $x(t=>t+i)
         ;
  }
  $xf() = sum / n;
%}

  ',
  Doc   => '
=for ref

Filter, moving average. xf(t) = sum(x(t-q .. t+q)) / (2q + 1)

=cut

  ',
);

pp_def('mae',
  Pars  => 'a(n); b(n); float+ [o]c()',
  GenericTypes => [F,D],
  HandleBad    => 1,
  Code  => '

$GENERIC(c) sum;
sum = 0;
int N = $SIZE(n);
loop(n) %{
  sum += fabs( $a() - $b() );
%}
$c() = sum / N;

',
  BadCode  => '

$GENERIC(c) sum;
sum = 0;
int N = 0;
loop(n) %{
  if ($ISBAD(a()) || $ISBAD(b())) { }
  else {
    sum += fabs( $a() - $b() );
    N ++;
  }
%}
if (N) {
  $c() = sum / N;
}
else {
  $SETBAD(c());
}

',
  Doc   => '

=for ref

Mean absolute error. MAE = 1/n * sum( abs(y - y_pred) )

=for usage

Usage:

    $mae = $y->mae( $y_pred );

=cut

',
);

pp_def('mape',
  Pars  => 'a(n); b(n); float+ [o]c()',
  GenericTypes => [F,D],
  HandleBad    => 1,
  Code  => '

$GENERIC(c) sum;
sum = 0;
int N = $SIZE(n);
loop(n) %{
  sum += fabs( ($a() - $b()) / $a() );
%}
$c() = sum / N;

',

  BadCode  => '

$GENERIC(c) sum;
sum = 0;
int N = 0;
loop(n) %{
  if ($ISBAD(a()) || $ISBAD(b())) { }
  else {
    sum += fabs( ($a() - $b()) / $a() );
    N ++;
  }
%}
if (N) {
  $c() = sum / N;
}
else {
  $SETBAD(c());
}

',
  Doc   => '

=for ref

Mean absolute percent error. MAPE = 1/n * sum(abs((y - y_pred) / y))

=for usage

Usage:

    $mape = $y->mape( $y_pred );

=cut

',
);

pp_def('wmape',
  Pars  => 'a(n); b(n); float+ [o]c()',
  GenericTypes => [F,D],
  HandleBad    => 1,
  Code  => '

$GENERIC(c) sum_e, sum;
sum_e=0; sum=0;
loop(n) %{
  sum_e += fabs( $a() - $b() );
  sum += fabs( $a() );
%}
$c() = sum_e / sum;

',

  BadCode  => '

$GENERIC(c) sum_e, sum;
sum_e=0; sum=0;
loop(n) %{
  if ($ISBAD(a()) || $ISBAD(b())) { }
  else {
    sum_e += fabs( $a() - $b() );
    sum += fabs( $a() );
  }
%}
if (sum) {
  $c() = sum_e / sum;
}
else {
  $SETBAD(c());
}

',
  Doc   => '

=for ref

Weighted mean absolute percent error. avg(abs(error)) / avg(abs(data)). Much more robust compared to mape with division by zero error (cf. Schütz, W., & Kolassa, 2006).

=for usage

Usage:

    $wmape = $y->wmape( $y_pred );

=cut

',
);


pp_def('portmanteau',
  Pars  => 'r(h); longlong t(); [o]Q()',
  GenericTypes => [F,D],
  Code  => '
$GENERIC(r) sum;

sum = 0;
loop(h) %{
  if (h)
    sum += pow($r(), 2) / ($t() - h);
%}
$Q() = $t() * ($t()+2) * sum;

  ',
  Doc   => '
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

    perldl> use PDLA::GSL::CDF
    perldl> p 1 - gsl_cdf_chisq_P( $chisq, 5 )
    0.0480112934306748

=cut

  ',
);

pp_addpm(<<'EOD');

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

sub PDLA::pred_ar {
  my ($x, $b, $t, $opt) = @_;
  my %opt = ( CONST => 1 );
  $opt and $opt{uc $_} = $opt->{$_} for (keys %$opt);

  $b = pdl $b
    unless ref $b eq 'PDLA';        # allows passing simple number

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

EOD

pp_def('_pred_ar',
  Pars  => 'x(p); b(p); [o]pred(t)',
  OtherPars => 'int end=>t;',
  GenericTypes => [F,D],
  Code  => '

int ord = $SIZE(p);
$GENERIC(x) xt, xp[ord];

loop (t) %{
  if (t < ord) {
    xp[t] = $x(p=>t);
    $pred() = xp[t];
  }
  else {
    xt = 0;
    loop(p) %{
      xt += xp[p] * $b(p=>ord-p-1);
      xp[p] = (p < ord - 1)?  xp[p+1] : xt;
    %}
    $pred() = xt;
  }
%}

  ',
  Doc   => undef
  ,
);


pp_addpm(<<'EOD');

=head2 season_m

Given length of season, returns seasonal mean and var for each period (returns seasonal mean only in scalar context).

=for options

Default options (case insensitive):

    START_POSITION => 0,     # series starts at this position in season
    MISSING        => -999,  # internal mark for missing points in season
    PLOT  => 1,              # boolean
      # see PDLA::Graphics::PGPLOT::Window for next options
    WIN   => undef,          # pass pgwin object for more plotting control
    DEV   => '/xs',          # open and close dev for plotting if no WIN
                             # defaults to '/png' in Windows
    COLOR => 1,

See PDLA::Graphics::PGPLOT for detailed graphing options.

=for usage

    my ($m, $ms) = $data->season_m( 24, { START_POSITION=>2 } );

=cut

*season_m = \&PDLA::season_m;
sub PDLA::season_m {
  my ($self, $d, $opt) = @_;
  my %opt = (
    START_POSITION => 0,     # series starts at this position in season
    MISSING        => -999,  # internal mark for missing points in season
    PLOT  => 1,
    WIN   => undef,          # pass pgwin object for more plotting control
    DEV   => $DEV,           # see PDLA::Graphics::PGPLOT for more info
    COLOR => 1,
  );
  $opt and $opt{uc $_} = $opt->{$_} for (keys %$opt);
  if ($opt{PLOT} and !$PGPLOT) {
    carp "No PDLA::Graphics::PGPLOT, no plot :(";
    $opt{PLOT} = 0;
  }

  my $n_season = ($self->dim(0) + $opt{START_POSITION}) / $d;
  $n_season = pdl($n_season)->ceil->sum;

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
      $w = pgwin( Dev=>$opt{DEV} );
      $w->env( 0, $d-1, $m->minmax,
              {XTitle=>'period', YTitle=>'mean'} );
    }
    $w->points( sequence($d), $m, {COLOR=>$opt{COLOR}, PLOTLINE=>1} );

    if ($m->squeeze->ndims < 2) {
      $w->errb( sequence($d), $m, sqrt( $ms / $s->sumover ),
               {COLOR=>$opt{COLOR}} );
    }
    else {
      carp "errb does not support multi dim pdl";
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

See PDLA::Graphics::PGPLOT for detailed graphing options.

=cut

*plot_dseason = \&PDLA::plot_dseason;
sub PDLA::plot_dseason {
  my ($self, $d, $opt) = @_;
  !defined($d) and croak "please set season period length";
  $self = $self->squeeze;

  my $dsea;
  if ($PGPLOT) {
    my %opt = (
        WIN   => undef,
        DEV   => $DEV,
        COLOR => 1,       # data point color
    );
    $opt and $opt{uc $_} = $opt->{$_} for (keys %$opt);

    $dsea = $self->dsea($d);

    my $w = $opt{WIN};
    if (!$opt{WIN}) {
      $w = pgwin( $opt{DEV} );
      $w->env( 0, $self->dim(0)-1, $self->minmax,
            {XTitle=>'T', YTitle=>'DV'} );
    }

    my $missn = ushort $self->max + 1;   # ushort in case precision issue
    $w->line( sequence($self->dim(0)), $dsea->setbadtoval( $missn ),
             {COLOR=>$opt{COLOR}+1, MISSING=>$missn} );
    $w->points( sequence($self->dim(0)), $self, {COLOR=>$opt{COLOR}} );
    $w->close
      unless $opt{WIN};
  }
  else {
    carp "Please install PDLA::Graphics::PGPLOT for plotting";
  }

  return $dsea; 
}

*filt_exp = \&PDLA::filt_exp;
sub PDLA::filt_exp {
  print STDERR "filt_exp() deprecated since version 0.5.0. Please use filter_exp() instead\n";
  return filter_exp( @_ );
}

*filt_ma = \&PDLA::filt_ma;
sub PDLA::filt_ma {
  print STDERR "filt_ma() deprecated since version 0.5.0. Please use filter_ma() instead\n";
  return filter_ma( @_ );
}

*dsea = \&PDLA::dsea;
sub PDLA::dsea {
  print STDERR "dsea() deprecated since version 0.5.0. Please use dseason() instead\n";
  return dseason( @_ );
}

*plot_season = \&PDLA::plot_season;
sub PDLA::plot_season {
  print STDERR "plot_season() deprecated since version 0.5.0. Please use season_m() instead\n";
  my ($self, $d, $opt) = @_;
  $opt and $opt{uc $_} = $opt->{$_} for (keys %$opt);
  $opt->{PLOT} = 1;
  return $self->season_m( $d, $opt );
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

*plot_acf = \&PDLA::plot_acf;
sub PDLA::plot_acf {
  my $opt = pop @_
    if ref $_[-1] eq 'HASH';
  my ($self, $h) = @_;
  my $r = $self->acf($h);
    
  if ($PGPLOT) {
    my %opt = (
        SIG => 0.05,
        DEV => $DEV,
    );
    $opt and $opt{uc $_} = $opt->{$_} for (keys %$opt);

    my $w = pgwin( Dev=>$opt{DEV} );
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
  }
  else {
    carp "Please install PDLA::Graphics::PGPLOT::Window for plotting";
  }

  return $r;
}

=head1 	REFERENCES

Brockwell, P.J., & Davis, R.A. (2002). Introcution to Time Series and Forecasting (2nd ed.). New York, NY: Springer.

Schütz, W., & Kolassa, S. (2006). Foresight: advantages of the MAD/Mean ratio over the MAPE. Retrieved Jan 28, 2010, from http://www.saf-ag.com/226+M5965d28cd19.html

=head1 AUTHOR

Copyright (C) 2009 Maggie J. Xiong <maggiexyz users.sourceforge.net>

All rights reserved. There is no warranty. You are allowed to redistribute this software / documentation as described in the file COPYING in the PDLA distribution.

=cut

EOD

pp_done();

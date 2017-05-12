package Statistics::Autocorrelation;
use 5.006;
use strict;
use warnings FATAL => 'all';
use Statistics::Data 0.08;
use base qw(Statistics::Data);
use Carp qw(croak);
use Statistics::Lite qw(mean);
use List::AllUtils qw(mesh);
$Statistics::Autocorrelation::VERSION = '0.06';

=head1 NAME

Statistics::Autocorrelation - Coefficients for any lag, as correlogram, with significance tests

=head1 VERSION

Version 0.06

=head1 SYNOPSIS

 use Statistics::Autocorrelation 0.06;
 $acorr = Statistics::Autocorrelation->new();
 $coeff = $acorr->coefficient(data => \@data, lag => integer (from 1 to N-1), exact => 0, unbias => 1);
 # or load one or more data, optionally update, and test each discretely:
 $acorr->load(\@data1, \@data2);
 $coeff = $acorr->coeff(index => 0, lag => 1); # default lag => 0

=head1 DESCRIPTION

Calculates autocorrelation coefficients for a single series of numerical data, for any valid length of I<lag>.

=head1 SUBROUTINES/METHODS

=head2 new

 $acorr = Statistics::Autocorrelation->new();

Return a new class object for accessing its methods. This ISA L<Statistics::Data|Statistics::Data> object, so all the methods for loading, adding, saving, dumping, etc., data in that package are available here.

=head2 coefficient

 $coeff = $autocorr->coefficient(data => \@data, lag => integer (from 1 to N-1), exact => 0|1, unbias => 1|0, circular => 1|0);
 $coeff = $autocorr->coefficient(lag => 1); # using loaded data, and default args (exact = 0, unbias = 1, circular = 0)

I<Alias>: C<coeff>, C<acf>

Returns the autocorrelation coefficient, the ratio of the autocovariance to variance of a sequence at any particular lag, ranging from -1 to +1, as in Chatfield (1975) and Kendall (1973). Specifically,

=for html <table cellpadding="0" cellspacing="0"><tr><td>&rho;<sub><i>k</i></sub> = </td><td><table cellpadding="0" cellspacing="0"><tr><td style="border-bottom:thin solid #000000;" valign="bottom" align="center">&gamma;<sub><i>k</i></sub></td></tr><tr><td valign="top" align="center"><i>&sigma;</i>&sup2;<sub><i>k</i></sub></td></tr></table></td></tr></table>

where I<k> is the lag (see below).

Data can be previously loaded or sent directly here (see L<Statistics::Data|Statistics::Data>). There must be at least two elements in the data array. A croak will be heard if no data have been loaded or given here.

Options are:

=over 4

=item B<lag>

An integer to define how many indices ahead or behind to start correlating the data to itself, as in how many time-intervals separate one value from another. If lag is greater than or equal to number of observations, returns empty string. If the value of B<lag> is less than zero, the calculation is made with its absolute value, given that

=for html <table><tr><td>&rho;<sub><i>k</i></sub> = </td><td>&rho;<sub>&ndash;<i>k</i></sub></td></tr></table>

for all I<k> (so that a coefficient for a lag of -I<k> is equal in magnitude I<and sign> to that for +I<k>). If a value is not given for lag, it is set to the default value of 0.

=item B<exact>

Boolean value, default = 0. In calculating the autocorrelation coefficient, the convention -- as in corporate stats programs (e.g., SPSS/PASW), and published examples of autocorrelation (e.g., L<nist.gov|http://www.itl.nist.gov/div898/handbook/eda/section3/eda35c.htm>), and texts such as Chatfield (1975), and Box and Jenkins (1976) -- is to calculate the sum-of-squares for the autocovariance (the numerator term in the autocorrelation coefficient) from the residuals for each observation I<x> from trial I<t> = 1 (index = 0) to I<N> - I<k> (the lag) relative to the mean of the whole sequence:

=for html <table cellpadding="0" cellspacing="0"><tr><td valign="middle" >&gamma;<sub><i>k</i></sub> =&nbsp;</td><td><table cellpadding="0" cellspacing="0"><tr><td style="border-bottom:thin solid #000000;" valign="bottom" align="center">1</td></tr><tr><td valign="top" align="center"><i>N</i></td></tr></table></td><td>&nbsp;</td><td valign="middle"><table cellpadding="0" cellspacing="0"><tr><td align="center"><sub><i>N</i>&ndash;<i>k</i></sub></td></tr><tr><td align="center">&Sigma;</td></tr><tr><td align="center"><sup><i>t</i>=1</sup></td></tr></table></td><td valign="middle">(<i>x</i><sub><i>t</i></sub> &ndash; <span style="text-decoration:overline;"><i>x</i></span>)(<i>x</i><sub><i>t</i>+<i>k</i></sub> &ndash; <span style="text-decoration:overline;"><i>x</i></span>)</td></tr></table>

rather than the means for each sub-sequence as lagged, and (2) the sum-of-squares for the variance in the denominator as that of the whole sequence:

=for html <table cellpadding="0" cellspacing="0"><tr><td valign="middle" align="center">&sigma;&sup2;<sub><i>k</i></sub> =&nbsp;</td><td><table cellpadding="0" cellspacing="0"><tr><td style="border-bottom:thin solid #000000;" valign="bottom" align="center">1</td></tr><tr><td valign="top" align="center"><i>N</i></td></tr></table></td><td>&nbsp;</td><td valign="middle"><table cellpadding="0" cellspacing="0"><tr><td align="center"><sub><i>N</i>&ndash;<i>k</i></sub></td></tr><tr><td align="center">&Sigma;</td></tr><tr><td align="center"><sup><i>t</i>=1</sup></td></tr></table></td><td valign="middle">(<i>x</i><sub><i>t</i></sub> &ndash; <span style="text-decoration:overline;"><i>x</i></span>)&sup2;</td></tr></table>

instead of using completely pairwise products. This convention assumes that the series is stationary (has no linear or curvilinear trend, no periodicity), and that the number of observations, I<N>, in the sample is "reasonably large". You get the autocorrelation coefficient with these assumptions, with the above formulations, by default; but if you specify B<exact> => 1, then you get the coefficient as calculated by Kendall (1973) Eq. 3.35, where the sums use not the overall sample mean, but the mean for the first to the I<N> - I<k> elements, and the mean from the I<k> to I<N> elements:

=for html <table><tr><td><table cellpadding="0" cellspacing="0"><tr><td valign="middle" ><span style="text-decoration:overline;"><i>x</i></span><sub><i>k</i></sub> =&nbsp;</td><td><table cellpadding="0" cellspacing="0"><tr><td style="border-bottom:thin solid #000000;" valign="bottom" align="center">1</td></tr><tr><td valign="top" align="center"><i>N</i>&ndash;<i>k</i></td></tr></table></td><td>&nbsp;</td><td valign="middle" align="center"><table cellpadding="0" cellspacing="0"><tr><td valign="bottom" align="center"><table cellpadding="0" cellspacing="0"><tr><td align="center"><sub><i>N</i>&ndash;<i>k</i></sub></td></tr><tr><td align="center">&Sigma;</td></tr><tr><td align="center"><sup><i>t</i>=1</sup></td></tr></table></td><td valign="middle"><i>x</i><sub><i>t</i></sub></td></tr></table></td></tr></table></td><td>, and </td><td><table cellpadding="0" cellspacing="0"><tr><td><span style="text-decoration:overline;"><i>x</i></span><sub><i>k</i>&acute;</sub> =&nbsp;</td><td><table cellpadding="0" cellspacing="0"><tr><td style="border-bottom:thin solid #000000;" valign="bottom" align="center">1</td></tr><tr><td valign="top" align="center"><i>N</i>&ndash;<i>k</i></td></tr></table></td><td>&nbsp;</td><td valign="middle" align="center"><table cellpadding="0" cellspacing="0"><tr><td valign="bottom" align="center"><table cellpadding="0" cellspacing="0"><tr><td align="center"><sub><i>N</i>&ndash;<i>k</i></sub></td></tr><tr><td align="center">&Sigma;</td></tr><tr><td align="center"><sup><i>t</i>=1</sup></td></tr></table></td><td valign="middle"><i>x</i><sub><i>t</i>+<i>k</i></sub></td></tr></table></td></tr></table></td></tr></table>

Taking each observation relative to these means, the autocovariance in the numerator, and variance in the denominator, are calculated as follows to give the autocorrelation coefficient:

=for html <table cellpadding="0" cellspacing="0"><tr><td rowspan="2" valign="middle">&rho;<sub><i>k</i></sub> =&nbsp;</td><td style="border-bottom:thin solid #000000;" valign="bottom" align="center"><table cellpadding="0" cellspacing="0"><tr><td align="center"><table><tr><td><sub><i>N</i>&ndash;<i>k</i></sub></td></tr><tr><td align="center">&Sigma;</td></tr><tr><td align="center"><sup><i>t</i>=1</sup></td></tr></table></td><td valign="middle">(<i>x</i><sub><i>t</i></sub> &ndash; <span style="text-decoration:overline;"><i>x</i></span><sub><i>k</i></sub>)(<i>x</i><sub><i>t</i>+<i>k</i></sub> &ndash; <span style="text-decoration:overline;"><i>x</i></span><sub><i>k</i>&acute;</sub>)</td></tr></table></td></tr><tr><td><table><tr><td>[</td><td valign="middle"><table cellpadding="0" cellspacing="0"><tr><td align="center"><sub><i>N</i>&ndash;<i>k</i></sub></td></tr><tr><td align="center">&Sigma;</td></tr><tr><td align="center"><sup><i>t</i>=1</sup></td></tr></table></td><td valign="middle">(<i>x</i><sub><i>t</i></sub> &ndash; <span style="text-decoration:overline;"><i>x</i></span><sub><i>k</i></sub>)&sup2;</td><td>]<sup>&frac12;</sup>&nbsp;[</td><td valign="middle"><table cellpadding="0" cellspacing="0"><tr><td align="center"><sub><i>N</i>&ndash;<i>k</i></sub></td></tr><tr><td align="center">&Sigma;</td></tr><tr><td align="center"><sup><i>t</i>=1</sup></td></tr></table></td><td valign="middle">(<i>x</i><sub><i>t</i>+<i>k</i></sub> &ndash; <span style="text-decoration:overline;"><i>x</i></span><sub><i>k</i>&acute;</sub>)&sup2;</td><td>]<sup>&frac12;</sup></tr></table></td></tr></table>

=item B<unbias>

Boolean, default = 1. In calculating the approximate autocovariance, it is conventional to divide the sum-product of residuals (as given above) by I<N>, but some sources divide by I<N> - I<lag> for less biased estimation, so that

=for html <table cellpadding="0" cellspacing="0"><tr><td valign="middle">&gamma;<sub><i>k</i></sub> =&nbsp;</td><td><table cellpadding="0" cellspacing="0"><tr><td style="border-bottom:thin solid #000000;" valign="bottom" align="center">1</td></tr><tr><td valign="top" align="center"><i>N</i>&ndash;<i>k</i></td></tr></table></td><td>&nbsp;</td><td valign="middle"><table cellpadding="0" cellspacing="0"><tr><td align="center"><sub><i>N</i>&ndash;<i>k</i></sub></td></tr><tr><td align="center">&Sigma;</td></tr><tr><td align="center"><sup><i>t</i>=1</sup></td></tr></table></td><td valign="middle">(<i>x</i><sub><i>t</i></sub> &ndash; <span style="text-decoration:overline;"><i>x</i></span>)(<i>x</i><sub><i>t</i>+<i>k</i></sub> &ndash; <span style="text-decoration:overline;"><i>x</i></span>)</td></tr></table>

For the latter, set B<unbias> => 0. This is only effective where B<circular> => 0 and B<exact> => 0.

=item B<circular>

Boolean value, default = 0: For circularized lagging, set B<circular> => 1.

=back

=cut

sub coefficient {
    my ( $self, $args, $data, $n, $k ) = _get_args(@_);
    return q{} if !$self;
    $args->{'unbias'} = defined $args->{'unbias'} ? $args->{'unbias'} : 0;
    $args->{'varp'} = 1 if !defined $args->{'varp'};

#croak "Can\'t autocorrelate with a lag of < $k > for only < $n > data" if $n - $k == 1 && !$args->{'circular'};
    return $args->{'exact'}
      ? _coeff_exact( $data, $n, abs($k), $args->{'circular'},
        $args->{'unbias'} )
      : _coeff_approx( $data, $n, abs($k), $args->{'circular'},
        $args->{'unbias'} );
}
*coeff = \&coefficient;
*acf   = \&coefficient;

=head2 autocovariance

 $covar = $autocorr->autocovariance(data => \@data, lag => integer (from 1 to N-1), exact => 0|1, unbias => 1|0, circular => 1|0);
 $covar = $autocorr->autocovariance(lag => 1); # using loaded data, and default args (exact = 0, unbias = 1, circular = 0)

I<Alias>: C<autocov>, C<acvf>

Returns the autocovariance; see L<coefficient|coefficient> for definition and options.

=cut

sub autocovariance {
    my ( $self, $args, $data, $n, $k ) = _get_args(@_);
    return q{} if !$self;
    my ( $circ, $m1, $m2, $sumprod, $div ) = ( $args->{'circular'} );
    if ( $args->{'exact'} )
    {    # use mean of the original and lagged sequences separately
        ( $m1, $m2 ) =
          $circ
          ? _comean_circ( $data, $n, $k )
          : _comean_uncirc( $data, $n, $k );
        $div = $circ ? $n : ( $n - $k );
    }
    else {    # use mean of the whole sequence
        $m1 = mean( @{$data} );
        $m2 = $m1;
        $div =
          $circ ? $n : $args->{'unbias'} ? ( $n - $k ) : $n; #variancep(@$data);
    }
    $sumprod =
      $circ
      ? _covarsum_circ( $data, $n, abs($k), $m1, $m2 )
      : _covarsum_uncirc( $data, $n, abs($k), $m1, $m2 );
    $sumprod /= $div;
    return $sumprod;
}
*autocov = \&autocovariance;
*acvf    = \&autocovariance;

=head2 correlogram

 $href = $autocorr->correlogram(nlags => integer, exact => 1|0, unbias => 1|0, circular => 1|0); # assuming data are loaded
 $href = $autocorr->correlogram(nlags => integer, exact => 1|0, unbias => 1|0, circular => 1|0); # assuming data are loaded
 $href = $autocorr->correlogram(); # use defaults, with loaded data
 $href = $autocorr->correlogram(data => \@data); # same as either of above, but give data here
 ($lags, $coeffs) = $autocorr->correlogram(); # with args as for either of the above 

I<Alias>: C<coeff_list>

Returns the autocorrelation coefficients for lags from 0 to a limit, or (by default) over all possible lags, from 0 to I<N> - 1. If called in array context, returns two references: to an array of the lags, and an array of their respsective coefficients. Otherwise, returns a hash-reference of the coefficients keyed by their respective lags. The limit is given by argument B<nlags> giving the number of lags to return, including the zero lag, as permitted by the data to be referenced. Options are B<exact>, B<unbias> and B<circular>, as defined above for L<coefficient|coefficient>. The autocorrelation function being symmetric about lag zero, the correlogram is based only on positive lags.

=cut

sub correlogram {
    my ( $self, $args, $data, $n ) = _get_args(@_);
    return q{} if !$self;
    my $m = $args->{'nlags'} ? $args->{'nlags'} : $n;
    $m--;
    croak
'Value given for argument \'nlags\' is not valid - should be no more than the number of data elements less 1'
      if $m > $n - 1;
    my @range  = ( 0 .. $m );
    my @coeffs = ();
    foreach (@range) {
        push @coeffs,
          $self->coefficient(
            data     => $data,
            lag      => $_,
            circular => $args->{'circular'},
            unbias   => $args->{'unbias'},
            exact    => $args->{'exact'}
          );
    }
    return wantarray ? ( \@range, \@coeffs ) : { mesh( @range, @coeffs ) };
}
*coeff_list = \&correlogram;

=head2 correlogram_chart

Experimental method to print a .png file of the correlogram.

=cut

sub correlogram_chart {
    my ( $lags, $coeffs ) = correlogram(@_);
    require GD::Graph::mixed;
    my $graph = GD::Graph::mixed->new( 400, 300 );
    $graph->set(
        types   => [qw(points bars lines)],
        markers => [7],                       # 7 = filled circle
          #line_types => [3], # 1 = solid, 2 = dashed, 3 = dotted, 4 = dot-dashed
        marker_size => 2,

        # bar_width => .9,
        # bar_spacing => 2,
        x_label          => 'Lags',
        x_label_position => 1 / 2,
        y_label          => 'Coeffs',
        title            => 'Correlogram',

        #y_max_value       => 8,
        #y_tick_number     => 8,
        y_label_skip => 2,
        dclrs        => [ 'white', 'white', 'white' ],

        #bgclr => 'lgray',
        #fgclr => 'black',
        #boxclr => 'lgray',
        #labelclr => 'black',
        #axislabelclr => 'black',
        #textclr => 'black',
    ) or croak $graph->error;
    $graph->set();
    my @zeroes = map { 0 } ( 1 .. scalar @{$coeffs} );
    my $gd = $graph->plot( [ $lags, $coeffs, $coeffs, \@zeroes ] )
      or croak $graph->error;
    open my $IMG, '>', 'file.png' or croak 'Cannot open file';
    binmode $IMG;
    print {$IMG} $gd->png or croak 'Cannot print image to file';
    close $IMG or warn;
    return;
}

=head2 ctest_bartlett

 $bool = $acorr->ctest_bartlett(lag => integer, tails => 1|2); # assuming data are loaded, or see above for alternative and extra options
 ($crit, $coeff, $bool) = $acorr->ctest_bartlett(lag => integer, tails => 1|2);

Performs a 95% confidence test of the null hypothesis of no autocorrelation, assuming that the series was generated by a Gaussian white noise process. Following Bartlett (1946), it compares the value of a single correlation coefficient for a given B<lag> with the critical values given B<tails> => 2 (default) or 1:

=for html <table cellpadding="0" cellspacing="0"><tr><td><i>r</i><sub><i>k</i>,.95</sub> =&nbsp;</td><td><table cellpadding="0" cellspacing="0"><tr><td style="border-bottom:thin solid #000000;" align="center" valign="bottom"><i>s</i></td></tr><tr><td align="center" valign="top"><i>N</i><sup>&frac12;</sup></td></tr></table></td></tr></table> 

where I<s> is a constant equalling 1.96 for a two-tailed, or 1.645 for a one-tailed test. If the absolute value of the sample correlation coefficient falls beyond this critical value, the null hypothesis is rejected at the 95% level.

Returns, if called in array context, a list comprising the critical value, the sample coefficient, and a boolean as to whether the null hypothesis is rejected; otherwise, just the latter boolean.

Accepts all the options as given for L<coefficient|Statistics::Autocorrelation/coefficient>. Note that the critical value is not calculated with respect to the particular value of B<lag> - see L<ctest_anderson|Statistics::Autocorrelation/ctest_anderson> for this.

=cut

sub ctest_bartlett {
    my ( $self, $args, $data, $n ) = _get_args(@_);
    my $coeff = $self->acf(
        data     => $data,
        lag      => $args->{'lag'},
        circular => $args->{'circular'},
        unbias   => $args->{'unbias'},
        exact    => $args->{'exact'}
    );
    my $tails = ( defined $args->{'tails'} and $args->{'tails'} == 1 ) ? 1 : 2;

    #my $c = _set_criterion($tails, $n - 1, $args->{'criteria'});
    my $c    = $tails == 2 ? 1.95996398454005 : 1.64485362695147;
    my $crit = $c / sqrt $n;
    my $bool = abs($coeff) > $crit ? 1 : 0;
    return wantarray ? ( $crit, $coeff, $bool ) : $bool;
}

=head2 ctest_anderson

 $bool = $acorr->ctest_bartlett(lag => integer, tails => 1|2); # assuming data are loaded, or see above for alternative and extra options
 ($crit, $coeff, $bool) = $acorr->ctest_b(lag => integer, tails => 1|2);

Performs a 95% confidence test of the null hypothesis of no autocorrelation, assuming that the series was generated by a Gaussian white noise process. Following Anderson (1941), it compares the value of a single correlation coefficient for a given B<lag> with the critical values given B<tails> => 2 (default) or 1:

=for html <table cellpadding="0" cellspacing="0"><tr><td><i>r</i><sub><i>k</i>,.95</sub>(2-tailed) =&nbsp;</td><td><table cellpadding="0" cellspacing="0"><tr><td style="border-bottom:thin solid #000000;" align="center" valign="bottom">&ndash;1 &plusmn;1.96(<i>N</i> &ndash; <i>k</i> &ndash; 1)<sup>&frac12;</sup></td></tr><tr><td align="center" valign="top"><i>N</i> &ndash; <i>k</i></td></tr></table></td></tr></table> 

=for html <table cellpadding="0" cellspacing="0"><tr><td><i>r</i><sub><i>k</i>,.95</sub>(1-tailed) =&nbsp;</td><td><table cellpadding="0" cellspacing="0"><tr><td style="border-bottom:thin solid #000000;" align="center" valign="bottom">&ndash;1 + 1.645(<i>N</i> &ndash; <i>k</i> &ndash; 1)<sup>&frac12;</sup></td></tr><tr><td align="center" valign="top"><i>N</i> &ndash; <i>k</i></td></tr></table></td></tr></table> 

If the sample correlation coefficient falls outside these bounds, the null hypothesis is rejected at the 95% level.

Returns, if called in array context, a list comprising the critical value, the sample coefficient, and a boolean as to whether the null hypothesis is rejected; otherwise, just the latter boolean.

Accepts all the options as given for L<coefficient|Statistics::Autocorrelation/coefficient>. Note that the critical value I<is> calculated with respect to the particular value of B<lag> - unlike L<ztest_bartlett|Statistics::Autocorrelation/ztest_bartlett>.

=cut

sub ctest_anderson {
    my ( $self, $args, $data, $n ) = _get_args(@_);
    my $coeff = $self->acf(
        data     => $data,
        lag      => $args->{'lag'},
        circular => $args->{'circular'},
        unbias   => $args->{'unbias'},
        exact    => $args->{'exact'}
    );
    my $tails = ( defined $args->{'tails'} and $args->{'tails'} == 1 ) ? 1 : 2;
    my $c = $tails == 2 ? 1.96 : 1.645;
    my $crit =
      ( -1 + ( $c * sqrt( $n - $args->{'lag'} - 1 ) ) ) /
      ( $n - $args->{'lag'} );
    my $bool = abs $coeff > $crit ? 1 : 0;
    return wantarray ? ( $crit, $coeff, $bool ) : $bool;
}

=head2 ztest_bartlett

 $p_value = $acorr->ztest_bartlett(lag => integer, tails => 1|2); # assuming data are loaded, or see above for alternative and extra options
 ($z_value, $p_value) = $acorr->ztest_bartlett(lag => integer, tails => 1|2);

Returns the 2- or 1-tailed probability, given B<tails> => 2 (default) or 1, respectively, for the deviation of the observed autocorrelation coefficient at the given B<lag> from the expected value of zero, relative to the variance 1 / I<N>, assuming that the series was generated by a Gaussian white noise process. If called in array context, returns both the actual I<Z>-value and then the I<p>-value. Other options, and methods of assigning the data to test, are as for L<coefficient|Statistics::Autocorrelation/coefficient>.

=cut

sub ztest_bartlett {
    my ( $self, $args, $data, $n ) = _get_args(@_);
    my $coeff = $self->acf(
        data     => $data,
        lag      => $args->{'lag'},
        circular => $args->{'circular'},
        unbias   => $args->{'unbias'},
        exact    => $args->{'exact'}
    );
    my $tails = ( defined $args->{'tails'} and $args->{'tails'} == 1 ) ? 1 : 2;
    require Statistics::Zed;
    my $zed = Statistics::Zed->new();
    my ( $zval, $pval ) = $zed->score(
        observed => $coeff,
        expected => 0,
        variance => 1 / $n,
        tails    => $tails,
        ccorr    => 0
    );
    return wantarray ? ( $zval, $pval ) : $pval;
}

=head2 qtest, boxpierce

 $p_value = $acorr->qtest(nlags => integer); # assuming data are loaded, or see above for alternative and extra options
 ($q_value, $df, $p_value) = $acorr->qtest(nlags => integer);

Returns the I<Q> statistic for testing whether a range of autocorrelation coefficients differs from zero, and so if the series was produced by a random process (Box & Pierce, 1970). If called in array context, returns a list giving the value of I<Q>, and, assuming I<chi>-square distribtution, its degrees of freedom (= B<nlags>) and I<p>-value; returns the I<p>-value only if called in scalar context. Other options, and methods of assigning the data to test, are as for L<coefficient|Statistics::Autocorrelation/coefficient>. The range is (by default) over all possible lags from 1 to I<N> - 1. The statistic is defined as follows:

=for html <table cellpadding="0" cellspacing="0"><tr><td valign="middle" align="center"><i>Q</i> =&nbsp;</td><td valign="middle"><i>N</i></td><td>&nbsp;</td><td><table cellpadding="0" cellspacing="0"><tr><td align="center" valign="middle"><sub><i>M</i></sub></td></tr><tr><td align="center">&Sigma;</td></tr><tr><td align="center" valign="middle"><sup><i>k</i>=1</sup></td></tr></table></td><td valign="middle"><i>&rho;</i><sub><i>k</i></sub>&sup2;</td></tr></table>

where I<M> is the largest lag-value to test (= B<nlags>).

=cut

sub qtest {
    my ( $self, $args, $data, $n ) = _get_args(@_);
    my ( $lags, $coeffs ) = $self->correlogram(
        data     => $data,
        nlags    => $args->{'nlags'},
        circular => $args->{'circular'},
        unbias   => $args->{'unbias'},
        exact    => $args->{'exact'}
    );
    my $df  = scalar @{$lags};
    my $sum = 0;
    foreach my $i ( 1 .. $df - 1 ) {
        $sum += $coeffs->[$i]**2;
    }
    my $q = $n * $sum;
    require Math::Cephes;
    my $pval = Math::Cephes::igamc( $df / 2, $q / 2 );
    return wantarray ? ( $q, $df, $pval ) : $pval;
}
*boxpierce = \&qtest;

sub _get_args {
    my $self = shift;
    my $args = ref $_[0] ? shift : {@_};
    my $data = ref $args->{'data'} ? $args->{'data'} : $self->access($args);
    my $n    = scalar @{$data} or croak 'No data are available';

 #croak __PACKAGE__, ': Can\'t handle dataset less than two elements' if $n < 2;
    $args->{'lag'} ||= 0;
    return $n <= abs $args->{'lag'}
      ? q{}
      : ( $self, $args, $data, $n, $args->{'lag'} );
}

# Kendall's (1973) Eq. 3.35., p. 40
sub _coeff_exact {
    my ( $data, $n, $k, $circ, $unbias ) = @_;
    my ( $m1, $m2 ) =
      $circ
      ? _comean_circ( $data, $n, $k )
      : _comean_uncirc( $data, $n, $k )
      ;    # means for original and lagged sub-sequence
    my $covar =
      $circ
      ? _covarsum_circ( $data, $n, $k, $m1, $m2 )
      : _covarsum_uncirc( $data, $n, $k, $m1, $m2 )
      ;    # numerator (autocovariance)
           # calc denominator (variance):
    my ( $sum_sq_ui, $sum_sq_uik ) = ( 0, 0 );
    for my $i ( 0 .. $n - $k - 1 ) {
        $sum_sq_ui  += ( $data->[$i] - $m1 )**2;
        $sum_sq_uik += ( $data->[ $i + $k ] - $m2 )**2;
    }
    my $var = sqrt($sum_sq_ui) * sqrt($sum_sq_uik);    # * 2 * ($n - $k);
    return $var ? $covar / $var : undef;
}

# Kendall (1973) Eq. 3.36
sub _coeff_approx {
    my ( $data, $n, $k, $circ, $unbias ) = @_;
    my ( $mean, $covar, $var ) = ();
    $mean = mean( @{$data} )
      ; # uses mean of the whole sequence, regardless of lag, in calculating autocovariance and variance
    $covar =
      $circ
      ? _covarsum_circ( $data, $n, $k, $mean )
      : _covarsum_uncirc( $data, $n, $k, $mean, undef );
    $var = _sumsq( $data, $n, $mean );
    if ($unbias) {
        $covar /= $n - $k;
        $var   /= $n;        #variancep(@$data);
    }
    return $var ? $covar / $var : undef;
}

sub _comean_circ {
    my ( $data, $n, $k ) = @_;
    my ( $sum1, $sum2 ) = (0);
    for my $i ( 0 .. $n - 1 ) {
        $sum1 += $data->[$i];
        $sum2 += $data->[ $i + $k >= $n ? abs( $n - $i - $k ) : $i + $k ];
    }
    return ( $sum1 / $n, $sum2 / $n );
}

sub _comean_uncirc {
    my ( $data, $n, $k ) = @_;
    $n -= $k;
    my ( $sum1, $sum2 ) = (0);
    for my $i ( 0 .. $n - 1 ) {
        $sum1 += $data->[$i];
        $sum2 += $data->[ $i + $k ];
    }
    return ( $sum1 / $n, $sum2 / $n );
}

sub _covarsum_circ {
    my ( $data, $n, $k, $m1, $m2 ) = @_;
    $m2 = $m1 if !defined $m2;
    my $sum = 0;
    for my $i ( 0 .. $n - 1 ) {
        $sum +=
          ( $data->[$i] - $m1 ) *
          ( $data->[ $i + $k >= $n ? abs( $n - $i - $k ) : $i + $k ] - $m2 );
    }
    return $sum;
}

sub _covarsum_uncirc {
    my ( $data, $n, $k, $m1, $m2 ) = @_;
    $m2 = $m1 if !defined $m2;
    my $sum = 0;
    for my $i ( 0 .. $n - $k - 1 ) {
        $sum += ( $data->[$i] - $m1 ) * ( $data->[ $i + $k ] - $m2 );
    }
    return $sum;
}

sub _sumsq {
    my ( $data, $n, $mean ) = @_;
    my $sum = 0;
    for my $i ( 0 .. $n - 1 ) {
        $sum += ( $data->[$i] - $mean )**2;
    }
    return $sum;
}

=head1 REFERENCES

Anderson, R.L. (1941). Distribution of the serial correlation coefficients. I<Annals of Mathematical Statistics>, I<8>, 1-13.

Bartlett M.S. (1946). On the theoretical specification of sampling properties of autocorrelated time series. I<Journal of the Royal Statistical Society>, I<27>.

Box, G.E, & Jenkins, G. (1976). I<Time series analysis: Forecasting and control>. San Francisco, US: Holden-Day.

Box, G.E., & Pierce D. (1970). Distribution of residual autocorrelations in ARIMA time series models. I<Journal of the American Statistical Association>, I<65>, 1509-1526.

Chatfield, C. (1975). I<The analysis of time series: Theory and practice>. London, UK: Chapman and Hall.

Kendall, M. G. (1973). I<Time-series>. London, UK: Griffin.

=head1 SEE ALSO

L<Statistics::SerialCorrelation|Statistics::SerialCorrelation> (L<at cpan|http://www.cpan.org/>). Returns single autocorrelation coefficient which, with the present modules, would be given by L<coefficient|Statistics::Autocorrelation/coefficient> given B<lag> => 1, B<circular> => 1 (and the defaults B<exact> => 0, B<unbias> => 0).

=head1 AUTHOR

Roderick Garton, C<< <rgarton at cpan.org> >>

=head1 DIAGNOSTICS

=over 4

=item No data are available

Croaked by most methods if they do not receive data as given in the call by an array ref, or as pre-loaded as per L<Statistics::Data|Statistics::Data>.

=item Value given for argument 'nlags' is not valid

Croaked by L<correlogram|Statistics::Autocorrelation/correlogram> when the nlags is not valid: should be no more than the number of data elements less 1.

=item file opening/printing errors

Croaked by L<correlogram_chart|Statistics::Autcorrelation/correlogram_chart> when it tries to print the chart.

=back

=head1 DEPENDENCIES

L<Statistics::Data|Statistics::Data> - used: base

L<Statistics::Lite|Statistics::Lite> - used: mean

L<List::AllUtils|List::AllUtils> - used: mesh

L<Statistics::Zed|Statistics::Zed> - required if calling L<ztest_bartlett|Statistics::Autocorrelation/ztest_bartlett>

L<Math::Cephes|Math::Cephes> - required for igamc method is calling L<qtest|Statistics::Autocorrelation/qtest>

=head1 BUGS AND LIMITATIONS

Report to C<bug-statistics-autocorrelation-0.06 at rt.cpan.org> or L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Statistics-Autocorrelation-0.06>.

To do: rho_ctest, rho_ztest

=head1 SUPPORT

Find documentation for this module with the perldoc command:

    perldoc Statistics::Autocorrelation

Also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-Autocorrelation-0.06>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Statistics-Autocorrelation-0.06>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Statistics-Autocorrelation-0.06>

=item * Search CPAN

L<http://search.cpan.org/dist/Statistics-Autocorrelation-0.06/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2014 Roderick Garton.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;    # End of Statistics::Autocorrelation

package Statistics::Sequences::Runs;
use 5.008008;
use strict;
use warnings FATAL => 'all';
use Carp qw(carp croak);
use base qw(Statistics::Sequences);
use List::AllUtils qw(all mesh sum uniq);
use Number::Misc qw(is_even is_numeric);
use Statistics::Zed 0.10;
use String::Numeric qw(is_int);
$Statistics::Sequences::Runs::VERSION = '0.22';

=pod

=head1 NAME

Statistics::Sequences::Runs - The Runs Test: Wald-Wolfowitz runs test descriptives, deviation and combinatorics

=head1 VERSION

This is documentation for B<Version 0.22> of Statistics::Sequences::Runs.

=head1 SYNOPSIS

 use strict;
 use Statistics::Sequences::Runs 0.22;
 my $runs = Statistics::Sequences::Runs->new();

 # Data are a sequence of dichotomous strings: 
 my @data = (qw/1 0 0 0 1 1 0 1 1 0 0 1 0 0 1 1 1 1 0 1/);
 my $val;

 # - Pre-load data to use for all methods:
 $runs->load(\@data);
 $val = $runs->observed();
 $val = $runs->expected();

 # - or give data as "data => $aref" to each method:
 $val = $runs->observed(data => AREF);
 
 # - or give frequencies of the 2 "states" in a sequence:
 $val = $runs->expected(freqs => [11, 9]); # works with other methods except observed()

 # Deviation ratio:
 $val = $runs->z_value(ccorr => 1);

 # Probability of deviation from expectation:
 my ($z, $p) = $runs->z_value(ccorr => 1, tails => 1); # dev. ratio with p-value
 $val = $runs->p_value(tails => 1); # normal dist. p-value itself
 $val = $runs->p_value(exact => 1, tails => 1); # p-value by combinatorics

 # Keyed list of descriptives etc.:
 my $href = $runs->stats_hash(values => [qw/observed p_value/], exact => 1);

 # Print descriptives etc. in the same way:
 $runs->dump(
  values => [qw/observed expected p_value/],
  exact => 1,
  flag => 1,
  precision_s => 3,
  precision_p => 7
 );
 # prints: observed = 11.000, expected = 10.900, p_value = 0.5700167

=head1 DESCRIPTION

The module returns statistical information re Wald-type runs across a sequence of dichotmous events on one or more consecutive trials. For example, given an accuracy-based sequence composed of matches (H) and misses (M) like (H, H, M, H, M, M, M, M, H), there are 5 runs: 3 for Hs, 2 for Ms. This observed number of runs can be compared with the number expected to occur by chance over the number of trials, relative to the expected variance. More runs than expected ("negative serial dependence") can denote irregularity, instability, mixing up of alternatives. Fewer runs than expected ("positive serial dependence") can denote cohesion, insulation, isolation of alternatives. Both can indicate sequential dependency: either negative (an alternation bias), or positive (a repetition bias).

The distribution of runs is asymptotically normal, and a deviation-based test of extra-chance occurrence when at least one alternative has more than 20 occurrences (Siegal rule), or both event occurrences exceed 10 (Kelly, 1982), is conventionally considered reliable; otherwise, the module provides an "exact test" based on combinatorics.

For non-dichotomous, continuous or multinomial data, see L<Statistics::Data::Dichotomize|Statistics::Data::Dichotomize> for potentially transforming them for runs descriptives/tests.

=head1 SUBROUTINES/METHODS

=head2 Data-handling

=head3 new

 $runs = Statistics::Sequences::Runs->new();

Returns a new Runs object. Expects/accepts no arguments but the classname.

=head3 load

 $runs->load(ARRAY);
 $runs->load(AREF);
 $runs->load(foodat => AREF); # named whatever

Loads a sequence anonymously or by name - see L<load|Statistics::Data/load> in the Statistics::Data manpage for details on the various ways data can be loaded, updated and then retrieved. Every load unloads all previous loads and any updates to them.

Alternatively, skip this action; data don't always have to be loaded to use the stats methods here. The sequence can be provided with each method call, as shown below, or by simply giving the observed counts of runs (apart, of course, for calculating these counts, when a specific sequence is needed).

=head3 add, access, unload

See L<Statistics::Data|Statistics::Data> for these additional operations on data that have been loaded.

=head2 Descriptives

=head3 observed

 $v = $runs->observed(); # use the data loaded anonymously
 $v = $runs->observed(name => 'foodat'); # ... or the name given on loading
 $v = $runs->observed(data => AREF); # ... or just give the data now

Returns the total observed number of runs in the loaded or given data. For example,

 $v = $runs->observed(data => [qw/H H H T T H H/]);

returns 3 (for the runs 'HHH', 'TT' and 'HH').

=cut

sub observed {
    my ( $self, @args ) = @_;
    my $args = ref $args[0] ? $args[0] : {@args};
    return $args->{'observed'} if defined $args->{'observed'};
    my $data = _get_data( $self, $args );
    my $observed = 0;
    for ( 0 .. scalar @{$data} - 1 ) {
        if ( $_ == 0 or $data->[$_] ne $data->[ $_ - 1 ] ) {
            $observed++;
        }
    }
    return $observed;
}

=head3 observed_per_state

 @freq = $runs->observed_per_state(data => AREF);
 $href = $runs->observed_per_state(data => AREF);

Returns the number of runs per state - as a two-dimensional array where the first element gives the count for the first state in the data, and so for the second. A hashref is returned if not called in list context, the frequencies keyed by state. For example:

 @ari = $runs->observed_per_state(data => [qw/H H H T T H H/]); # returns (2, 1)
 $ref = $runs->observed_per_state(data => [qw/H H H T T H H/]); # returns { H => 2, T => 1}

Exceptions: If there was only one state in the loaded/given sequence (e.g., data => [qw/H H H/]), there is only one run and so the returned array will be one-dimensional, i.e., (1), and the returned hashref has only a single key (for this example: { H => 1 }).  If there are no states, with an empty array loaded/given for the sequence, then the same applies, except the returned array is (0) and the returned hashref has the empty string as its single key ( q{} => 0 ).

=cut

sub observed_per_state {
    my ( $self, @args ) = @_;
    my $args = ref $args[0] ? $args[0] : {@args};
    my $data   = _get_data( $self, $args );
    my @states = uniq @{$data};
    my @freqs  = ();
    if ( scalar @{$data} ) {
        if ( scalar @states > 1 ) {
            @freqs = $data->[0] eq $states[0] ? ( 1, 0 ) : ( 0, 1 );
        }
        else {
            @freqs = (1);
        }
        for ( 1 .. scalar @{$data} - 1 ) {
            if ( $data->[$_] ne $data->[ $_ - 1 ] ) {
                if ( $data->[$_] eq $states[0] ) {
                    $freqs[0]++;
                }
                else {
                    $freqs[1]++;
                }
            }
        }
    }
    else {
        @states = (q{});
        @freqs  = (0);
    }
    return wantarray ? @freqs : { mesh @states, @freqs };
}

=head3 expected

 $v = $runs->expected(); # or specify loaded data by "name", or give as "data"
 $v = $runs->expected(data => AREF); # use these data
 $v = $runs->expected(freqs => [POS_INT, POS_INT]); # no actual data; calculate from these two Ns

Returns the expected number of runs across the loaded data. Expectation is given as follows: 

=for html <p>&nbsp;&nbsp;<i>E[R]</i> = ( (2<i>n</i><sub>1</sub><i>n</i><sub>2</sub>) / (<i>n</i><sub>1</sub> + <i>n</i><sub>2</sub>) ) + 1</p>

where I<n>(I<i)> is the number of observations of each element in the data.

=cut 

sub expected {
    my ( $self, @args ) = @_;
    my ( $sum, $n1, $n2 ) = _sum_bi_frequency( $self, @args );
    my $val;
    if ($sum) {
        $val = ( ( 2 * $n1 * $n2 ) / $sum ) + 1;
    }
    return $val;
}

=head3 variance

 $v = $runs->variance(); # use data already loaded - anonymously; or specify its "name" 
 $v = $runs->variance(data => AREF); # use these data
 $v = $runs->variance(freqs => [POS_INT, POS_INT]); # use these counts - not any particular sequence of data

Returns the variance in the number of runs for the given data.

=for html <p>&nbsp;&nbsp;<i>V[R]</i> = ( (2<i>n</i><sub>1</sub><i>n</i><sub>2</sub>)([2<i>n</i><sub>1</sub><i>n</i><sub>2</sub>] &ndash; [<i>n</i><sub>1</sub> + <i>n</i><sub>2</sub>]) ) / ( ((<i>n</i><sub>1</sub> + <i>n</i><sub>2</sub>)<sup>2</sup>)((<i>n</i><sub>1</sub> + <i>n</i><sub>2</sub>) &ndash; 1) ) </p>

defined as above for L<expected|Statistics::Sequences::Runs/expected>.

The data to test can already have been L<load|load>ed, or you send it directly as a flat referenced array keyed as B<data>.

=cut

sub variance {
    my ( $self, @args ) = @_;
    my ( $sum, $n1, $n2 ) = _sum_bi_frequency( $self, @args );
    my $val;
    if ($sum) {
        if ( $sum < 2 ) {
            $val = 0;
        }
        else {
            $val =
              ( ( 2 * $n1 * $n2 * ( ( 2 * $n1 * $n2 ) - $sum ) ) /
                  ( ( $sum**2 ) * ( $sum - 1 ) ) );
        }
    }
    return $val;
}

=head3 observed_deviation

 $v = $runs->obsdev(); # use data already loaded - anonymously; or specify its "name"
 $v = $runs->obsdev(data => AREF); # use these data

Returns the deviation of (difference between) observed and expected runs for the loaded/given sequence (I<O> - I<E>). 

I<Alias>: obsdev

=cut

sub observed_deviation {
    my ( $self, @args ) = @_;
    return $self->observed(@args) - $self->expected(@args);
}
*obsdev = \&observed_deviation;

=head3 standard_deviation

 $v = $runs->stdev(); # use data already loaded - anonymously; or specify its "name"
 $v = $runs->stdev(data => AREF);
 $v = $runs->stdev(freqs => [POS_INT, POS_INT]); # don't use actual data; calculate from these two Ns

Returns square-root of the variance.

I<Alias>: stdev, stddev

=cut

sub standard_deviation {
    my ( $self, @args ) = @_;
    return sqrt $self->variance(@args);
}
*stdev  = \&standard_deviation;
*stddev = \&standard_deviation;

=head3 skewness

 $v = $runs->skewness(); # use data already loaded - anonymously; or specify its "name"
 $v = $runs->skewness(data => AREF); # use these data

Returns run skewness as given by Barton & David (1958) based on the frequencies of the two different elements in the sequence.

=cut

sub skewness {
    my ( $self, @args ) = @_;
    my ( $sum, $n1, $n2 ) = _sum_bi_frequency( $self, @args );
    my $k3 = 0;
    if ( $sum && $n1 != $n2 ) {
        $k3 =
          ( ( 2 * $n1 * $n2 ) / $sum**3 ) *
          ( ( ( 16 * $n1**2 * $n2**2 ) / $sum**2 ) -
              ( ( 4 * $n1 * $n2 * ( $sum + 3 ) ) / $sum ) +
              3 * $sum );
    }
    return $k3;
}

=head3 kurtosis

 $v = $runs->kurtosis(); # use data already loaded - anonymously; or specify its "name"
 $v = $runs->kurtosis(data => AREF); # use these data

Returns run kurtosis as given by Barton & David (1958) based on the frequencies of the two different elements in the sequence.

=cut

sub kurtosis {
    my ( $self, @args ) = @_;
    my ( $sum, $n1, $n2 ) = _sum_bi_frequency( $self, @args );
    my $k4;
    if ( defined $sum ) {
        $k4 = ( ( 2 * $n1 * $n2 ) / $sum**4 ) * (
            (
                ( 48 * ( 5 * $sum - 6 ) * $n1**3 * $n2**3 ) /
                  ( $sum**2 * $sum**2 )
            ) - (
                ( 48 * ( 2 * $sum**2 + 3 * $sum - 6 ) * $n1**2 * $n2**2 ) /
                  ( $sum**2 * $sum )
              ) + (
                (
                    2 * ( 4 * $sum**3 + 45 * $sum**2 - 37 * $sum - 18 ) *
                      $n1 * $n2
                ) / $sum**2
              ) - ( 7 * $sum**2 + 13 * $sum - 6 )
        );
    }
    return $k4;
}

=head2 Distribution and tests

=head3 pmf

 $p = $runs->pmf(data => AREF); # or no args to use last pre-loaded data
 $p = $runs->pmf(observed => POS_INT, freqs => [POS_INT, POS_INT]);

Implements the runs probability mass function, returning the probability for a particular number of runs given so many dichotomous events (e.g., as in Swed & Eisenhart, 1943, p. 66); i.e., for I<u>' the observed number of runs, I<P>{I<u> = I<u>'}. The required function parameters are the observed number of runs, and the frequencies (counts) of each state in the sequence, which can be given directly, as above, in the arguments B<observed> and B<freqs>, respectively, or these will be worked out from a given data sequence itself (given here or as pre-loaded). For derivation, see its public internal methods L<n_max_seq|Statistics::Sequences::Runs/n_max_seq> and L<m_seq_k|Statistics::Sequences::Runs/m_seq_k>, which make use of the choose() method from Orwant et al. (1999).

=cut

sub pmf {
    my ( $self, @args ) = @_;
    my ( $n1,   $n2 )   = $self->bi_frequency(@args);
    return _pmf_num( $self->observed(@args), $n1, $n2 ) /
      _pmf_denom( $n1, $n2 );
}

=head3 cdf

 $p = $runs->cdf(data => AREF); # or no args to use last pre-loaded data
 $p = $runs->cdf(observed => POS_INT, freqs => [POS_INT, POS_INT]);

Implements the cumulative distribution function for runs, returning the probability of obtaining the observed number of runs or less down to the expected number of 2 (assuming that the two possible events are actually represented in the data), as per Swed & Eisenhart (1943), p. 66; i.e., for I<u>' the observed number of runs, I<P>{I<u> <= I<u>'}. The summation is over the probability mass function L<pmf|Statistics::Sequences::Runs/pmf>. The function parameters are the observed number of runs, and the frequencies (counts) of the two events, which can be given directly, as above, in the arguments B<observed> and B<freqs>, respectively, or these will be worked out from a given data sequence itself (given here or as pre-loaded).

=cut

sub cdf {
    my ( $self, @args ) = @_;
    my ( $n1,   $n2 )   = $self->bi_frequency(@args);
    my $u   = $self->observed(@args);
    my $sum = 0;
    for ( 2 .. $u ) {
        $sum += _pmf_num( $_, $n1, $n2 );
    }
    return $sum / _pmf_denom( $n1, $n2 );
}

=head3 cdfi

 $p = $runs->cdfi(data => AREF); # or no args for last pre-loaded data
 $p = $runs->cdfi(observed => POS_INT, freqs => [POS_INT, POS_INT]);

Implements the (inverse) cumulative distribution function for runs, returning the probability of obtaining more than the observed number of runs up from the expected number of 2 (assuming that the two possible events are actually represented in the data), as per Swed & Eisenhart (1943), p. 66; ; i.e., for I<u>' the observed number of runs, I<P> = 1 - I<P>{I<u> <= I<u>' - 1}. The summation is over the probability mass function L<pmf|Statistics::Sequences::Runs/pmf>. The function parameters are the observed number of runs, and the frequencies (counts) of the two events, which can be given directly, as above, in the arguments B<observed> and B<freqs>, respectively, or these will be worked out from a given data sequence itself (given here as B<data> or as pre-loaded).

=cut

sub cdfi {
    my ( $self, @args ) = @_;
    my ( $n1,   $n2 )   = $self->bi_frequency(@args);
    my $u   = $self->observed(@args);
    my $sum = 0;
    for ( 2 .. $u - 1 ) {
        $sum += _pmf_num( $_, $n1, $n2 );
    }
    return 1 - $sum / _pmf_denom( $n1, $n2 );
}

=head3 z_value

 $v = $runs->z_value(ccorr => BOOL); # use data already loaded - anonymously; or specify its "name"
 $v = $runs->z_value(data => AREF, ccorr => BOOL);
 ($zvalue, $pvalue) = $runs->z_value(data => AREF, ccorr => BOOL, tails => 1|2); # wanting an array, get p-value too

Returns the normal deviate from a test of runcount deviation, taking the runcount expected from that observed and dividing by the root variance, by default with a continuity correction to expectation. Called wanting an array, returns the I<Z>-value with its I<p>-value for the B<tails> (1 or 2) given. The returned value is an empty string if the variance is undefined, empty or equals 0 (as when there is only one state in the sequence).

The data to test can already have been L<load|load>ed, or sent directly as an aref keyed as B<data>.

Other options are B<precision_s> (for the z_value) and B<precision_p> (for the p_value).

I<Aliases>: zscore, zvalue

=cut

sub z_value {
    my ( $self, @args ) = @_;
    my $args = ref $args[0] ? $args[0] : {@args};
    my $observed = $self->observed($args);
    return q{} if $observed == 0;
    my $zed = Statistics::Zed->new();
    return $zed->z_value(
        observed => $observed,
        expected => $self->expected($args),
        variance => $self->variance($args),
        ccorr => ( defined $args->{'ccorr'} ? $args->{'ccorr'} : 1 ),
        tails => ( $args->{'tails'} || 2 ),
        precision_s => $args->{'precision_s'},
        precision_p => $args->{'precision_p'},
    );
}
*zvalue = \&z_value;
*zscore = \&z_value;

=head3 p_value

 $p = $runs->p_value(); # using loaded data and default args
 $p = $runs->p_value(ccorr => BOOL, tails => 1|2); # normal-approx. for last-loaded data
 $p = $runs->p_value(exact => BOOL); # calc combinatorially for observed >= or < than expectation
 $p = $runs->p_value(data => AREF, exact => BOOL); #  given data
 $p = $runs->p_value(observed => POS_INT, freqs => [POS_INT, POS_INT]); # no data sequence, specify known params

Returns the probability of getting the observed number of runs or a smaller number given the number of each of the two events. By default, a large sample is assumed, and the probability is obtained from the normalized deviation, as given by the L<z_value|Statistics::Sequences::Runs/z_value> method.

If the option B<exact> is defined and not zero, then the probability is worked out combinatorially, as per Swed & Eisenhart (1943), Eq. 1, p. 66 (and also Siegal, 1956, Eqs. 6.12a and 6.12b, p. 138). This is only implemented as a one-tailed test; the B<tails> option has no effect. This tests the hypotheses that there are either too many or too few runs relative to chance expectation; which of these hypotheses is tested is based on the expected value returned by the L<expected|Statistics::Sequences::Runs/expected> method, using L<cdfi|Statistics::Sequences::Runs/cdfi> if there are more runs than expected, or L<cdf||Statistics::Sequences::Runs/cdf> if there are fewer runs than expected; use these functions themselves to specify the hypothesis to be tested.

If there is only one state/event in the sequence, then the variance from the expected value of 1 is 0, and this method returns 1 (however long this single event sequence is, the observed number of runs cannot differ from the expected number of runs). If the sequence is empty, an empty string is returned.

Output from these tests has been checked against the tables and examples in Swed & Eisenhart (given to 7 decimal places), and found to agree.

The option B<precision_p> gives the returned I<p>-value to so many decimal places.

I<Aliases>: pvalue

=cut

sub p_value {
    my ( $self, @args ) = @_;
    my $args = ref $args[0] ? $args[0] : {@args};
    my $vals = {
        observed => $self->observed($args),
        expected => $self->expected($args),
        variance => $self->variance($args),
    };
    return $args->{'exact'}
      ? _p_exact( $self, $args, $vals )
      : _p_norm( $self, $args, $vals );
}
*pvalue = \&p_value;

=head3 ztest_ok

 $bool = $runs->ztest_ok(); # use data already loaded - anonymously; or specify its "name"
 $bool = $runs->ztest_ok(data => AREF);

Returns true for the loaded sequence if its constituent sample numbers are sufficient for their expected runs to be normally approximated - using Siegal's (1956, p. 140) rule - ok if I<either> of the two I<N>s are greater than 20.

=cut

sub ztest_ok {
    my ( $self, @args ) = @_;
    my ( $n1,   $n2 )   = $self->bi_frequency(@args);
    my $retval =
      $n1 > 20 || $n2 > 20
      ? 1
      : 0;
    return $retval;
}

=head2 Utils

Methods used internally, or for returning/printing descriptives, etc., in a bunch.

=head3 bi_frequency

 @freq = $runs->bi_frequency(data => AREF); # or no args if using last pre-loaded data

Returns frequency of the two elements - or croaks if there are more than 2, and gives zero for any absent.

=cut

sub bi_frequency {
    my ( $self, @args ) = @_;
    my $args = ref $args[0] ? $args[0] : {@args};

# might be called internally from a method where an array of frequencies per state is optionally already given:
    carp
'Argument named \'trials\' is deprecated; use \'freqs\' to give aref of frequencies per state'
      if $args->{'trials'};
    return @{ $args->{'freqs'} } if ref $args->{'freqs'};
    my $data = _get_data( $self, $args );

    # build hash keying each element with its frequency:
    my %states = ();
    for ( @{$data} ) {
        $states{$_}++;
    }

    # Check that number of states in the sequences are computable for Runs,
    # and ensure that there is at least zero frequency for the 2 states:
    my $nstates = scalar keys %states;
    my @vals    = values %states;

    if ( !$nstates ) {
        @vals = ( 0, 0 );
    }
    elsif ( $nstates == 1 ) {
        push @vals, 0;
    }
    elsif ( $nstates > 2 ) {
        croak
          'Cannot compute runs: More than two states were found in the data';
    }
    return @vals;
}

=head3 n_max_seq

 $n = $runs->n_max_seq(); # loaded data
 $n = $runs->n_max_seq(data => AREF); # this sequence
 $n = $runs->n_max_seq(observed => POS_INT, freqs => [POS_INT, POS_INT]); # these counts

Returns the number of possible sequences for the two given state frequencies. So the urn contains I<N>1 black balls and I<N>2 white balls, well mixed; taking I<N>1 + I<N>2 drawings from it without replacement, any sequence has the same probability of occurring; how many different sequences of black and white balls are possible? For the two counts, this is "sum of I<N>1 + I<N>2 I<choose> I<N>1", or:

=for html <p>&nbsp;&nbsp;&nbsp;<i>N</i><sub>max</sub> = ( <i>N</i><sub>1</sub> + <i>N</i><sub>2</sub> )! / <i>N</i><sub>1</sub>!<i>N</i><sub>2</sub>!</p>

This is the denominator term in the runs L<probability mass function (pmf)|Statistics::Sequences::Runs/pmf>; not taking into account probability of obtaining so many of each event, of the proportion of black and white balls in the urn.

=cut

sub n_max_seq {
    my ( $self, @args ) = @_;
    return _pmf_denom( $self->bi_frequency(@args) );
}

=head3 m_seq_k

 $n = $runs->m_seq_k(); # loaded data
 $n = $runs->m_seq_k(data => AREF); # this sequence
 $n = $runs->m_seq_k(observed => POS_INT, freqs => [POS_INT, POS_INT]); # these counts

Returns the number of sequences that can produce I<k> runs from I<m> elements of a single kind, with all other kinds of elements in the sequence assumed to be of a single kind, under the conditions of L<n_max_seq|n_max_seq>. See Swed and Eisenhart (1943), or Barton and David (1958, p. 253). With the frequentist probability M / N, this is the numerator term in the runs L<probability mass function (pmf)|Statistics::Sequences::Run/pmf>.

=cut

sub m_seq_k {
    my ( $self, @args ) = @_;
    return _pmf_num( $self->observed(@args), $self->bi_frequency(@args) );
}

=head3 stats_hash

 $href = $runs->stats_hash(values => [qw/observed expected z_value/], precision_s => POS_INT, ccorr => BOOL); # among other values/options
 $href = $runs->stats_hash(values =>
  {
   observed => BOOL,
   expected => BOOL,
   variance => BOOL,
   z_value => BOOL,
   p_value => BOOL,
  },
  exact => BOOL,    # for p_value
  ccorr => BOOL # for z_value
 );

Returns a hashref for the counts and stats as specified in its "values" argument, and with any options for calculating them (e.g., exact for p_value). See L<Statistics::Sequences/stats_hash> for details. If calling via a "runs" object, the option "stat => 'runs'" is not needed (unlike when using the parent "sequences" object).

=head3 dump

 $runs->dump(values => [qw/observed expected z_value/], precision_s => POS_INT, ccorr => BOOL); # among other values/options
 $runs->dump(values =>
  {
   observed => BOOL,
   expected => BOOL,
   variance => BOOL,
   z_value => BOOL,
   p_value => BOOL,
  },
  precision_s => POS_INT,
  precision_p => POS_INT,   # for p_value
  flag  => BOOL,    # for p_value
  exact => BOOL,    # for p_value
  ccorr => BOOL # for z_value
 );

Print Runs-test results to STDOUT, including the stats as given a true value by their method names in a referenced hash of B<values>, and with options relevant to thesemethods (see the template above). Default values to dump are observed() and p_value()). Optionally also give the data directly.

=cut

sub dump {
    my ( $self, @args ) = @_;
    my $args = ref $args[0] ? $args[0] : {@args};
    $args->{'stat'} = 'runs';
    $self->SUPER::dump($args);
    return;
}

=head3 dump_data

 $runs->dump_data(delim => "\n"); # print whatevers loaded (or specify by name, or as "data") 

See L<Statistics::Sequences/dump_data> for details.

=cut

# Private methods:

sub _p_exact {
    my ( $self, $args, $vals ) = @_;
    my $pval;
    if ( all { is_numeric($_) } ( $vals->{'observed'}, $vals->{'expected'} ) ) {
        $pval =
          ( $vals->{'observed'} - $vals->{'expected'} >= 0 )
          ? $self->cdfi($args)
          : $self->cdf($args);
        if ( $args->{'precision_p'} ) {
            $pval = sprintf q{%.} . $args->{'precision_p'} . qw{f}, $pval;
        }
    }
    else {
        $pval = q{};
    }
    return $pval;
}

sub _p_norm {
    my ( $self, $args, $vals ) = @_;
    my $pval;
    if ( !$vals->{'expected'} ) {
        $pval = q{};
    }
    elsif ( !$vals->{'variance'} ) {
        $pval = 1;
    }
    else {
        my $zed = Statistics::Zed->new();
        $pval = $zed->p_value(
            %{$vals},
            ccorr => ( defined $args->{'ccorr'} ? $args->{'ccorr'} : 1 ),
            tails => ( $args->{'tails'} || 2 ),
            precision_p => $args->{'precision_p'},
        );
    }
    return $pval;
}

sub _pmf_num {
    my ( $u, $m, $n ) = @_;
    my $f;
    if ( is_even($u) ) {
        my $k = $u / 2 - 1;
        $f = 2 * _choose( $m - 1, $k ) * _choose( $n - 1, $k );
    }
    else {
        my $k = ( $u + 1 ) / 2;
        $f =
          _choose( $m - 1, $k - 1 ) * _choose( $n - 1, $k - 2 ) +
          _choose( $m - 1, $k - 2 ) * _choose( $n - 1, $k - 1 );
    }
    return $f;
}

sub _pmf_denom {
    my @args = @_;
    return _choose( sum(@args), $args[0] );
}

sub _choose {    # from Orwant et al., p. 573
    my ( $n, $k ) = @_;
    my ( $res, $j ) = ( 1, 1 );
    return 0 if $k > $n || $k < 0;
    $k = ( $n - $k ) if ( $n - $k ) < $k;
    while ( $j <= $k ) {
        $res *= $n--;
        $res /= $j++;
    }
    return $res;
}

sub _sum_bi_frequency {
    my ( $self, @args ) = @_;
    my ( $n1,   $n2 )   = $self->bi_frequency(@args);
    my $sum;
    if ( all { is_int($_) } ( $n1, $n2 ) ) {
        $sum = $n1 + $n2;
    }
    return ( $sum, $n1, $n2 );
}

sub _get_data {
    my ( $self, $args ) = @_;
    return ref $args->{'data'} ? $args->{'data'} : $self->get_aref( %{$args} );
}

1;

__END__

=head1 EXAMPLE

=head2 Seating at the diner

Swed and Eisenhart (1943) list the occupied (O) and empty (E) seats in a row at a lunch counter. Have people taken up their seats on a random basis?

 use Statistics::Sequences::Runs;
 my $runs = Statistics::Sequences::Runs->new();
 my @seating = (qw/E O E E O E E E O E E E O E O E/); # data already form a single sequence with dichotomous observations
 $runs->dump(data => \@seating, exact => 1, tails => 1);

Suggesting some non-random basis for people taking their seats, this prints:

 observed = 11, p_value = 0.054834

But these data would fail Siegal's rule (L<ztest_ok|Statistics::Sequences::Runs/ztest_ok> = 0) (neither state has 20 observations). So just check exact probability of the hypothesis that the observed deviation is greater than zero (1-tailed):

 $runs->dump(data => \@seating, values => {'p_value'}, exact => 1, tails => 1);

This prints a I<p>-value of .0576923 (so the normal approximation seems good in any case).

These data are also used in an example of testing for L<Vnomes|Statistics::Sequences::Vnomes/EXAMPLE>.

=head2 Runs in multinomial matching

In a single run of a classic ESP test, there are 25 trials, each composed of a randomly generated event (typically, one of 5 possible geometric figures), and a human-generated event arbitrarily drawn from the same pool of alternatives. Tests of the match between the random and human data are typically for number of matches observed versus expected. The I<runs> of matches and misses can be tested by dichotomizing the data on the basis of the L<match|Statistics::Data::Dichotomize/match> of the random "targets" with the human "responses", as described by Kelly (1982):

 use Statistics::Sequences::Runs;
 use Statistics::Data::Dichotomize;
 my @targets = (qw/p c p w s p r w p c r c r s s s s r w p r w c w c/);
 my @responses = (qw/p c s c s s p r w r w c c s s r w s w p c r w p r/);

 # Test for runs of matches between targets and responses:
 my $runs = Statistics::Sequences::Runs->new();
 my $ddat = Statistics::Data::Dichotomize->new();
 $runs->load($ddat->match(data => [\@targets, \@responses]));
 $runs->dump_data(delim => ' '); # have a look at the match sequence; prints "1 1 0 0 1 0 0 0 0 0 0 1 0 1 1 0 0 0 1 1 0 0 0 0 0\n"
 print "Probability of these many runs vs expectation: ", $runs->test(), "\n"; # 0.51436
 # or test for runs in matching when responses are matched to targets one trial behind:
 print $runs->test(data => $ddat->match(data => [\@targets, \@responses], lag => -1)), "\n"; # 0.73766

=head1 DEPENDENCIES

L<List::AllUtils|List::AllUtils> : uses methods C<mesh>, C<sum> and C<uniq>

L<Number::Misc|Number::Misc> : uses method C<is_even> in the probability-mass-function computation

L<Statistics::Sequences|Statistics::Sequences> : base module

L<Statistics::Zed|Statistics::Zed> : for normality-wise statistical testing

=head1 SEE ALSO

L<Statistics::Sequences|Statistics::Sequences> : for other tests of sequences, for sharing data between these tests, such as ...

L<Statistics::Sequences::Pot|Statistics::Sequences::Pot> : another test of sequential structure, assessing exponential clustering of events.

=head1 REFERENCES

These papers provide the implemented algorithms and/or the sample data used in examples and tests.

Barton, D. E., & David, F. N. (1958). Non-randomness in a sequence of two alternatives: II. Runs test. I<Biometrika>, I<45>, 253-256. doi: L<10.2307/2333062|http://dx.doi.org/10.2307/2333062> 

Kelly, E. F. (1982). On grouping of hits in some exceptional psi performers. I<Journal of the American Society for Psychical Research>, I<76>, 101-142.

Orwant, J., Hietaniemi, J., & Macdonald, J. (1999). I<Mastering algorithms with Perl>. Sebastopol, CA, US: O'Reilly.

Siegal, S. (1956). I<Nonparametric statistics for the behavioral sciences>. New York, NY, US: McGraw-Hill.

Swed, F., & Eisenhart, C. (1943). Tables for testing randomness of grouping in a sequence of alternatives. I<Annals of Mathematical Statistics>, I<14>, 66-87. doi: L<10.1214/aoms/1177731494|http://dx.doi.org/10.1214/aoms/1177731494>

Wald, A., & Wolfowitz, J. (1940). On a test whether two samples are from the same population. I<Annals of Mathematical Statistics>, I<11>, 147-162. doi: L<10.1214/aoms/1177731909|http://dx.doi.org/10.1214/aoms/1177731909>

Wolfowitz, J. (1943). On the theory of runs with some applications to quality control. I<Annals of Mathematical Statistics>, I<14>, 280-288. doi: L<10.1214/aoms/1177731421|http://dx.doi.org/10.1214/aoms/1177731421>

The test scripts also implement the example data from L<www.reiter1.com|http://www.reiter1.com/Glossar/Wald_Wolfowitz.htm>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::Sequences::Runs

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-Sequences-Runs-0.22>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Statistics-Sequences-Runs-0.22>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Statistics-Sequences-Runs-0.22>

=item * Search CPAN

L<http://search.cpan.org/dist/Statistics-Sequences-Runs-0.22/>

=back

=head1 AUTHOR

Roderick Garton, C<< <rgarton at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

=over 4

=item Copyright (c) 2006-2017 Roderick Garton

This program is free software. It may be used, redistributed and/or modified under the same terms as Perl-5.6.1 (or later) (see L<http://www.perl.com/perl/misc/Artistic.html>).

=item Disclaimer

To the maximum extent permitted by applicable law, the author of this module disclaims all warranties, either express or implied, including but not limited to implied warranties of merchantability and fitness for a particular purpose, with regard to the software and the accompanying documentation.

=back

=cut

# end of Statistics::Sequences::Runs

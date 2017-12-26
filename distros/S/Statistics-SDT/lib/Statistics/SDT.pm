package Statistics::SDT;
use strict;
use warnings;
use Carp qw(carp croak);
use List::AllUtils qw(all any);
use Math::Cephes qw(:dists :explog);
use String::Numeric qw(is_int is_float);
use String::Util qw(hascontent nocontent);
$Statistics::SDT::VERSION = '0.06';

my %counts_dep = (
    hits               => [qw/signal_trials misses/],
    false_alarms       => [qw/noise_trials correct_rejections/],
    misses             => [qw/signal_trials hits/],
    correct_rejections => [qw/noise_trials false_alarms/],
);
my %trials_dep = (
    signal_trials => [qw/hits misses/],
    noise_trials  => [qw/false_alarms correct_rejections/]
);
my %rates_dep = (
    hr  => [qw/hits signal_trials/],
    far => [qw/false_alarms noise_trials/]
);

=head1 NAME

Statistics::SDT - Signal detection theory (SDT) measures of sensitivity and bias in frequency data

=head1 VERSION

This is documentation for B<Version 0.06> of Statistics::SDT.

=head1 SYNOPSIS

 use Statistics::SDT 0.06;
 use feature qw{say};

 my $sdt = Statistics::SDT->new(
  correction => 1,
  precision_s => 2,
 );

 $sdt->init(
  hits => 50,
  signal_trials => 50, # or misses => 0,
  false_alarms => 17,
  noise_trials => 25, # or correct_rejections => 8
 ); # or init these into 'new' &/or pass their values as 2nd arg. hashrefs in calling the following methods

 say 'Hit rate = ',            $sdt->rate('hr'); # or 'far', 'mr', 'crr'
 say 'Sensitivity d = ',       $sdt->sens('d');  # or 'Ad', 'A'
 say 'Bias beta = ',           $sdt->bias('b');  # or 'log', 'c', 'griers'
 say 'Criterion k = ',         $sdt->crit();            # -0.47
 say 'Hit rate by d & c = ',  $sdt->dc2hr();            # .99
 say 'FAR by d & c = ',       $sdt->dc2far();           # .68
 say 'LogBeta by d & c = ',   $sdt->dc2logbeta();       # -2.60

 # m-AFC:
 say 'd_fc = ', $sdt->sens('f' => {hr => .866, alternatives => 3, correction => 0, method => 'alexander'})); # or 'smith'

=head1 DESCRIPTION

This module implements algorithms for Signal Detection Theory (SDT) measures of sensitivity and response-bias, e.g., I<d'>, I<A'>, I<c>, as based on frequency data. These are largely as defined in Stanislav & Todorov (1999; see L<REFERENCES|Statistics::SDT/REFERENCES>), as well as other sources including Alexander (2006). Output from this module per method are tested for agreement with example data and calculation from those sources.

For any particular analysis, (1) create the SDT object with L<new|Statistics::SDT/new>, (2) initialise the object with relevant data with L<init|Statistics::SDT/init>, and then (3) call the measure wanted.

For those measures that involve I<Z>-score transformation of probabilities, this is made via the C<ndtri> function in L<Math::Cephes|Math::Cephes>, and this is denoted in the equations below by the Greek letter phi^-1 (for inverse phi). The function can be directly accessed by the present module as "Statistics::SDT::ndtri()". The complementary C<ndtr> for converting I<Z>-scores into probabilities is also used/available in this way.

Most methods assume a yes/no rather than I<m>-AFC design. For I<m>-AFC designs, only sensitivity measures are offered/relevant, approximated from the hit-rate for the given number of hits and signal trials, which are assumed to indicate all trials.

=head1 PARAMETERS

The following named parameters need to be given as a hash or hash-reference: either to the L<new|Statistics::SDT/new> constructor method, L<init|Statistics::SDT/init>, or into each measure-function. To calculate the hit-rate, provide the (i) count of hits and signal-trials, (ii) the counts of hits and misses, or (iii) the count of signal-trials and misses. To calculate the false-alarm-rate, provide (i) the count of false-alarms and noise-trials, (ii) the count of false-alarms and correct-rejections, or (iii) the count of noise-trials and correct-rejections. Or supply the hit-rate and false-alarm-rate. Or see L<dc2hr|Statistics::SDT/dc2hr> and L<dc2far|Statistics::SDT/dc2far> to get back the rates via given/calculated sensitivity and criterion. If a method depends on these counts/rates and they are not provided, or what it depends on cannot be calculated from the provided values, the methods will generally return an empty string.

=over 4

=item hits => POSINT

The number of hits.

=item false_alarms => POSINT

The number of false alarms.

=item signal_trials => POSINT

The number of signal trials. The hit-rate is derived by dividing the number of hits by the number of signal trials.

=item noise_trials => POSINT

The number of noise trials. The false-alarm-rate is derived by dividing the number of false-alarms by the number of noise trials.

=item hr => FLOAT [0 .. 1]

The hit-rate -- instead of passing the number of hits and signal trials, give the hit-rate directly.

=item far => FLOAT [0 .. 1]

The false-alarm-rate -- instead of passing the number of false alarms and noise trials, give the false-alarm-rate directly.

=item alternatives => POSINT

The number of response alternatives; when estimating for a forced-choice rather than yes/no design. If defined (and greater than or equal to 2), then, by default, Smith's (1982) estimate of I<d'> is used; otherwise Alexander's.

=item correction => POSINT [0, 1, 2, undef]

Indicate whether or not to perform a correction on the number of hits and false-alarms when the hit-rate or false-alarm-rate equals 0 or 1 (due, e.g., to strong inducements against false-alarms, or easy discrimination between signals and noise). This is relevant to all functions that make use of the I<inverse phi> function (all except I<aprime> option with L<sens|Statistics::SDT/sens>, and the L<griers|Statistics::SDT/griers> option with L<bias|Statistics::SDT/bias>). As C<ndtri> must die with an error if given 0 or 1, there is a default correction.

If B<correction> = 0, no correction is performed to calculation of rates. This should only be used when (1) using the parametric measures and the rates will never be at the extremes of 0 and 1; or (2) using only the nonparametric measures (L<aprime|Statistics::SDT/aprime> and L<griers|Statistics::SDT/griers>).

If B<correction> = 1 (default), extreme rates (of 0 and 1) are corrected: 0 is replaced with 0.5 / I<n>; 1 is replaced with (I<n> - 0.5) / I<n>, where I<n> = number of signal or noise trials. This is the most common method of handling extreme rates (Stanislav and Todorov, 1999) but it might bias sensitivity measures and not be as satisfactory as the loglinear transformation applied to all hits and false-alarms, as follows.

If B<correction> > 1, the loglinear transformation is applied to I<all> values: 0.5 is added to both the number of hits and false-alarms, and 1 is added to the number of signal and noise trials.

If B<correction> is undefined: To avoid errors thrown by the C<ndtri> function, any values that equal 1 or 0 will be corrected as if it equals 1.

=item precision_s => POSINT

Precision (I<n> decimal places) of any of the statistics. Default = 0 to have all possible decimals returned.

=item method => STR ['smith', 'alexander']

Method for estimating I<d'> for forced-choice design. Default is I<smith>; otherwise I<alexander>.

=back

=head1 SUBROUTINES/METHODS

=head2 new

Creates the class object that holds the values of the parameters, as above, and accesses the following methods (without having to pass the all values again).

As well as storing parameter values, the class-object returned by C<new> will stores B<hr>, the hit-rate, and B<far>, the false-alarm-rate. These can be specifically given as named arguments to the method (ensuring that they do not equal zero or 1 in order to avoid errors thrown by the inverse-phi function). Otherwise, calculation of the hit-rate and false-alarm-rate from the given number of signal/noise trials, and hits/misses (etc., as defined above) corrects for this limitation; i.e.,  correction can only be done by supplying the relevant counts, not just the rate - see the notes on the |<correction|Statistics::SDT/correction> option. 

=cut

sub new {
    my ( $class, @args ) = @_;
    my $self = {};
    bless $self, $class;
    $self->init(@args);
    return $self;
}

=head2 init

 $sdt->init(...)

Instead of passing the number of hits, signal-trials, etc., with every call to the measure-functions, or creating a new class object for every set of data, initialise the class object with the values for parameters, key => value pairs, as defined above. This method is called by L<new|Statistics::SDT/new> (if the parameter values are passed to it). The hit-rates and false-alarm rates are always calculated anew from the hits and signal trials, and the false-alarms and noise trials, respectively; unless a value for one or the other, or both (as hr and far) is passed in a call to L<init|Statistics::SDT/init>.

Each L<init|Statistics::SDT/init> replaces the values only of those attributes passed to it - any values set in previous L<init|Statistics::SDT/init>s are retained for those attributes that are not set in a call to L<init|Statistics::SDT/init>. To reset everything, first use L<clear|Statistics::SDT/clear>

The method also stores any given values for L<alternatives|Statistics::SDT/alternatives>, L<correction|Statistics::SDT/correction>, L<precision_s|Statistics::SDT/precision_s> and L<method|Statistics::SDT/method>.

=cut

sub init {
    my ( $self, @args ) = @_;
    if ( scalar @args ) {    # have some params?
        my $href = ref $args[0] ? $args[0] : {@args};

        # Initialise any given counts and arguments:
        foreach my $arg (
            qw/hits false_alarms misses correct_rejections signal_trials noise_trials hr far alternatives states correction precision_s method/
          )
        {
            if ( defined $href->{$arg} ) {
                if ( $arg eq 'states' ) {
                    carp
'Argument named <states> is deprecated - use the name <alternatives> instead';
                    $self->{'alternatives'} = $href->{$arg};
                }
                else {
                    $self->{$arg} = $href->{$arg};
                }
            }
        }
        $self->{'method'}      ||= 'smith';
        $self->{'precision_s'} ||= 0;

        _init_performance_counts($self);
        _init_trial_counts($self);
        _init_hr_far($self);
    }

    # no params - assume the values are already in $self
    return ( $self->{'hr'}, $self->{'far'}, $self->{'alternatives'} );
}

# Initialise any missing performance counts of hits, false-alarms, misses & correct rejections
## from what has just been given (just initialised)
## e.g., number of hits from the given number of signal-trials and misses:
sub _init_performance_counts {
    my $self = shift;
    foreach ( keys %counts_dep ) {
        if (   !defined $self->{$_}
            && $self->{ $counts_dep{$_}->[0] }
            && defined $self->{ $counts_dep{$_}->[1] } )
        {
            $self->{$_} =
              $self->{ $counts_dep{$_}->[0] } - $self->{ $counts_dep{$_}->[1] };
        }
    }
    return;
}

# Initialise any missing trial counts (of number of signal or noise trials) from what has been given,
## e.g., number of signal trials from the sum of hits and misses:
sub _init_trial_counts {
    my $self = shift;
    foreach ( keys %trials_dep ) {
        if (  !defined $self->{$_}
            && defined $self->{ $trials_dep{$_}->[0] }
            && defined $self->{ $trials_dep{$_}->[1] } )
        {
            $self->{$_} =
              $self->{ $trials_dep{$_}->[0] } + $self->{ $trials_dep{$_}->[1] };
        }
    }
    return;
}

# Initialise the rates of hits and false-alarms if not already done
## by given counts, e.g., HR from number of hits and signal trials:
sub _init_hr_far {
    my $self = shift;
    foreach ( keys %rates_dep ) {
        if (  !defined $self->{$_}
            && defined $self->{ $rates_dep{$_}->[0] }
            && $self->{ $rates_dep{$_}->[1] } )
        {
            $self->{$_} = _init_rate(
                $self->{ $rates_dep{$_}->[0] },
                $self->{ $rates_dep{$_}->[1] },
                $self->{'correction'}
            );
        }
    }
    return;
}

=head2 clear

 $sdt->clear()

Sets all attributes to undef: C<hits>, C<false_alarms>, C<signal_trials>, C<noise_trials>, C<hr>, C<far>, C<alternatives>, C<correction>, and C<method>.

=cut

sub clear {
    my $self = shift;
    foreach (
        qw/hits false_alarms misses correct_rejections signal_trials noise_trials hr far alternatives correction precision_s method/
      )
    {
        $self->{$_} = undef;
    }
    return;
}

=head2 rate

 $sdt->rate('hr|far|mr|crr') # return the indicated rate
 $sdt->rate(hr => PROB, far => PROB, mr => PROB, crr => PROB) # set 1 or more rate => probability pairs
 $sdt->rate('hr' => {signal_trials => INT, hits => INT}) # or misses instead of hits
 $sdt->rate('far' => {noise_trials => INT, false_alarms => INT}) # or correct_rejections instead of false_alarms
 $sdt->rate('mr' => {signal_trials => INT, misses => INT})  # or hits instead of misses
 $sdt->rate('crr' => {noise_trials => INT, correct_rejections => INT})  # or false_alarms instead of correct_rejections

Generic method to get or set the conditional response proportions:

=for html <p>&nbsp;&nbsp;HR (hit-rate) = <i>N</i>(R<sub>s</sub>|<i>S</i><sub>s</sub>) / <i>N</i>(<i>S</i><sub>s</sub>)</p>

=for html <p>&nbsp;&nbsp;FAR (false-alarm-rate) = <i>N</i>(R<sub>s</sub>|<i>S</i><sub>n</sub>) / <i>N</i>(<i>S</i><sub>n</sub>)</p>

=for html <p>&nbsp;&nbsp;MR (miss-rate) = <i>N</i>(R<sub>n</sub>|<i>S</i><sub>s</sub>) / <i>N</i>(<i>S</i><sub>s</sub>)</p>

=for html <p>&nbsp;&nbsp;CRR (correct-rejection-rate) = <i>N</i>(R<sub>n</sub>|<i>S</i><sub>n</sub>) / <i>N</i>(<i>S</i><sub>n</sub>)</p>

where S = stimulus (trial-type, expected response), R = response, subscript I<s> indicates signal-plus-noise trials and I<n> indicates noise-only trials.

To I<get> a rate, these string abbreviations do the trick; the method only checks the first letter, so any passable abbreviation will do, case-insensitively. The rate is returned to the precision indicated by the optional L<precision_s|Statistics::SDT/precision_s> argument (given here or in L<init|Statistics::SDT/init>).

To I<set> a rate for use by other methods (such as for sensitivity or bias), either give the actual proportion as key => value pairs, e.g., HR => .7, or a hashref giving sufficient info to calculate the rate (if this has not already been paased to L<init|Statistics::SDT/init>).

Also performs any required or requested corrections, depending on value of L<correction|Statistics::SDT/correction> (given here or in L<init|Statistics::SDT/init>).

Unless the values of the rates are directly given, then they will be calculated from the presently passed counts and trial-numbers, or whatever has been cached of these values. For the hit-rate, there must be a value for L<hits|Statistics::SDT/hits> and L<signal_trials|signal_trials>, and for the false-alarm-rate, there must be a value for L<false_alarms|Statistics::SDT/false_alarms> and L<noise_trials|Statistics::SDT/noise_trials>.  If these values are not passed, they will be taken from any prior value, unless this has been L<clear|Statistics::SDT/clear>ed or never existed - in which case expect a C<croak>.

=cut

sub rate {
    my ( $self, @args ) = @_;
    my $rate;
    if ( scalar @args == 1 ) {    # Get the rate:
        local $_ = $args[0];
      CASE: {
            /^h/ixsm && do { $rate = $self->_hr(); };
            /^f/ixsm && do { $rate = $self->_far(); };
            /^m/ixsm && do { $rate = $self->_mr(); };
            /^c/ixsm && do { $rate = $self->_crr() };
        }                         #end CASE
    }
    ##else {
    elsif ( scalar @args > 1 ) {    # Set the rate:
        my %params = @args;
        foreach ( keys %params ) {
            my @args2 = ref $params{$_} ? %{ $params{$_} } : $params{$_}; # hash(ref) to ari
          CASE: {
                /^h/ixsm && do { $rate = $self->_hr(@args2);  last CASE; };
                /^f/ixsm && do { $rate = $self->_far(@args2); last CASE; };
                /^m/ixsm && do { $rate = $self->_mr(@args2);  last CASE; };
                /^c/ixsm && do { $rate = $self->_crr(@args2) };
            }                       #end CASE
        }
    }
    return _precisioned( $self->{'precision_s'}, $rate );
}

sub _hr {
    my ( $self, @args ) = @_;
    if ( scalar @args > 1 ) {       # set the rate via params
        my (%params) = @args;
        foreach ( keys %params ) {
            $self->{$_} = $params{$_};
        }
        $self->{'hr'} = _init_rate( $self->{'hits'}, $self->{'signal_trials'},
            $self->{'correction'} );
    }
    elsif ( scalar @args == 1 ) {    # set the rate as given
        $self->{'hr'} = _valid_p( $args[0] ) ? $args[0] : croak __PACKAGE__,
          ' Rate needs to be between 0 and 1 inclusive';
    }
    return $self->{'hr'};
}

sub _far {
    my ( $self, @args ) = @_;
    if ( scalar @args > 1 ) {        # set the rate via params
        my %params = @args;
        foreach ( keys %params ) {
            $self->{$_} = $params{$_};
        }
        $self->{'far'} = _init_rate(
            $self->{'false_alarms'},
            $self->{'noise_trials'},
            $self->{'correction'}
        );
    }
    elsif ( scalar @args == 1 ) {    # set the rate as given
        $self->{'far'} = _valid_p( $args[0] ) ? $args[0] : croak __PACKAGE__,
          ' Rate needs to be between 0 and 1 inclusive';
    }
    return $self->{'far'};
}

sub _mr {
    my ( $self, %params ) = @_;
    foreach ( keys %params ) {
        $self->{$_} = $params{$_};
    }
    if ( !$self->{'signal_trials'} || !defined $self->{'misses'} ) {
        carp 'Uninitialised counts for calculating MR';
        return q{};
    }
    return $self->{'misses'} / $self->{'signal_trials'};
}

sub _crr {
    my ( $self, %params ) = @_;
    foreach ( keys %params ) {
        $self->{$_} = $params{$_};
    }
    if ( !$self->{'signal_trials'} || !defined $self->{'correct_rejections'} ) {
        carp 'Uninitialised counts for calculating CRR';
        return q{};
    }
    return $self->{'correct_rejections'} / $self->{'noise_trials'};
}

sub _init_rate {    # Initialise hit and false-alarm rates:
    my ( $count, $trials, $correction ) = @_;
    my $rate;
    if ( !defined $correction ) {
        $correction = 1;    # default correction
    }

# Need (i) no. of hits and signal trials, or (ii) no. of false alarms and noise trials:
    croak __PACKAGE__,
' Number of hits/false-alarms and signal/noise trials needed to calculate rate'
      if !defined $count || !defined $trials;
    return if not is_int($trials) or $trials == 0;

    if ( $correction > 1 ) {    # loglinear correction, regardless of values:
        $rate = _loglinear_correct( $count, $trials );
    }
    else
    { # get rate first, applying corrections if needed (unless explicitly verboten):
        $rate = $count / $trials;
        if ( $correction != 0 ) {
            $rate = _n_correct( $rate, $trials );
        }
    }
    return $rate;
}

=head2 zrate

 $z = $sdt->zrate('hr'); # or 'far', 'mr', 'crr'

Returns the I<Z>-transformation of the given rate using the inverse-phi function (C<ndtri> from L<Math::Cephes|Math::Cephes>).

=cut

sub zrate {
    my ( $self, @args ) = @_;
    return ndtri( $self->rate(@args) );
}

=head2 dc2hr

 $sdt->dc2hr() # assume d' and c can be calculated from already inited param values
 $sdt->dc2hr(d => FLOAT, c => FLOAT)

Returns the hit-rate estimated from given values of sensitivity I<d'> and bias I<c>, viz.:

=for html <p>&nbsp;&nbsp;HR = &phi;(<i>d</i>&rsquo; / 2 &ndash; <i>c</i>)</p>

=cut

sub dc2hr {
    my ( $self, %args ) = @_;
    my ( $d, $c ) = _get_dc( $self, %args );
    return (all { hascontent($_) } ($d, $c)) ? _precisioned( $self->{'precision_s'}, ndtr( $d / 2 - $c ) ) : q{};
}

=head2 dc2far

 $sdt->dc2far() # assume d' and c can be calculated from already inited param values
 $sdt->dc2far(d => FLOAT, c => FLOAT)

Returns the false-alarm-rate estimated from given values of sensitivity I<d'> and bias I<c>, viz.:

=for html <p>&nbsp;&nbsp;FAR = &phi;(&ndash;<i>d</i>&rsquo; / 2 &ndash; <i>c</i>)</p>

=cut

sub dc2far {
    my ( $self, %args ) = @_;
    my ( $d, $c ) = _get_dc( $self, %args );
    return (all { hascontent($_) } ($d, $c)) ? _precisioned( $self->{'precision_s'}, ndtr( -1 * $d / 2 - $c ) ) : q{};
}

# --------------------
# Sensitivity measures:
# --------------------

=head2 sens

 $s = $sdt->sens('dprime'); # or 'aprime', 'adprime'
 $s = $sdt->sens('dprime', { signal_trials => POSINT }); # set args, optionally
 $s = $sdt->sens('d_a', { stdev_n => POS_FLOAT, stdev_s => POS_FLOAT }); # required args

I<Alias>: C<sensitivity>

Returns one of the sensitivity measures, as indicated by the first argument string, optionally updating any of the measure variables and options with a subsequent hashref. The measures are as follows, accessed by giving the name (or at least its first two letters) as the first argument.

=over 4

=item dprime

Returns the index of standard deviation units of sensitivity, or discrimination, I<d'> (d prime). Assuming equal variances for the noise and signal+noise distributions, this is estimated by subtracting the I<z>-score units of the false-alarm rate (or 1 - the correct-rejection-rate) from the I<z>-score units of the hit rate: 

=for html <p>&nbsp;&nbsp;<i>d</i>&rsquo; = &phi;<sup>&ndash;1</sup>(HR)&nbsp;&ndash;&nbsp;&phi;<sup>&ndash;1</sup>(FAR)<br />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; = &phi;<sup>&ndash;1</sup>(HR)&nbsp;+&nbsp;&phi;<sup>&ndash;1</sup>(CR)</p>

Larger positive values indicate greater sensitivity. If both HR and FAR are either 0 or 1, then L<sens|Statistics::SDT/sens>itivity returns 0, indicating no sensitivity; the signal cannot be discriminated from noise. Values less than 0 (more false-alarms than hits) indicate a lack of sensitivity that might result from a consistent reponse-confusion or -inhibition.

For estimating dprime for I<m>-AFC tasks, the forced-choice design, there are two methods, as set by the L<method|Statistics::SDT/method> parameter in L<init|Statistics::SDT/init> or L<sens|Statistics::SDT/sens>itivity. The default method is I<smith>, the method cited by Stanislav & Todorov (1999); and there is the more generally applicable I<alexander> method.

The present interface to these methods is limited in that they are given, for proportion-correct, the hit-rate as for the yes/no design: as the count of hits divided by number of signal trials. Rather than give these methods a value for B<hr>, the L<init|Statistics::SDT/init> method could be used setting the number of hit and signal trials as appropriate, and setting the number of false alarms and noise trials to zero. This is not optimal (intuitive) as the proportion correct is something else in the yes/no design (see L<pcorrect|Statistics::SDT/pcorrect>), but simply works by present L<limitations|Statistics::SDT/BUGS AND LIMITATIONS>). So, in what follows, for HR, one should really read proportion-correct.

B<I<Smith (1982) method>>: satisfies "the 2% bound for all I<M> [alternatives] and all percentiles and, except for I<M> = 3 or 4, satisfies a 1% error bound" (p. 95). The specific algorithm used depends on number of alternatives: 

Smith's I<d>* applies when I<n> alternatives E<lt> 12:

=for html <p>&nbsp;&nbsp;<i>d</i>&rsquo; = <i>K</i>ln( [ (<i>n</i> &ndash;&nbsp;1)HR ] / [ 1 &ndash; HR ] )</p>

where

=for html <p>&nbsp;&nbsp;&nbsp;&nbsp;<i>K</i> = .86 &ndash; .085 * ln(<i>n</i>&nbsp;&ndash;&nbsp;1).</p>

Smith's I<d>** applies when I<n> >= 12:

=for html <p>&nbsp;&nbsp;&nbsp;&nbsp;<i>d</i>&rsquo; = (A + B)&phi;<sup>&ndash;1</sup>(HR)</p>

where

=for html <p>&nbsp;&nbsp;&nbsp;&nbsp;<i>A</i> = (&ndash;4 + sqrt[16 + 25 * ln(<i>n</i> &ndash; 1)]) / 3</p>

and

=for html <p>&nbsp;&nbsp;&nbsp;&nbsp;<i>B</i> = sqrt( [ln(<i>n</i> &ndash; 1) + 2] / [ln(<i>n</i> &ndash; 1) + 1] )</p>

The limits of the method can be noted in that, when I<n> >= 14, I<d'> does not equal zero when the proportion correct (HR) is simply 1/I<n>. 

B<I<Alexander (2006/1990) method>> (which never fails the latter elementary test): "gives values of I<d'> with an error of less than 2% (mostly less than 1%) from those obtained by integration for the range I<d'> = 0 (or 1% correct for I<n> [alternatives] > 1000) to 75% correct and an error of less than 4% up to 95% correct for I<n> up to at least 10000, and slightly greater maximum errors for I<n> = 100000. This approximation is comparable to the accuracy of Elliott's table (0.02 in proportion correct) but can be used for any I<n>." (Elliott's table being that in Swets, 1964, pp. 682-683). The estimation is offered by:

=for html <p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<i>d</i>&rsquo; = [ &phi;<sup>&ndash;1</sup>(HR) &ndash;&nbsp;&phi;<sup>&ndash;1</sup>(1/<i>n</i>) ] / <i>An</i></p>

where I<n> is the number of L<alternatives|Statistics::SDT/alternatives>, and I<An> is estimated by:

=for html <p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<i>An</i> = 1 - 1 / (1.93 + 4.75 * log<sub>10</sub>(<i>n</i>) + .63[log<sub>10</sub>(<i>n</i>)]<sup>2</sup>)</p>

=item d_a

Returns estimate of SDT sensitivity for without assuming equal variances, given values of B<stdev_n> for standard deviation of the noise distribution, and B<stdev_s> for standard deviation of the signal-plus-noise distribution.

=for html <p>&nbsp;&nbsp;<i>d</i>&rsquo; = sqrt[ 2 / (1 + <i>b</i><sup>2</sup>) ][&phi;<sup>&ndash;1</sup>(HR)&nbsp;&ndash;&nbsp;<i>b</i>&phi;<sup>&ndash;1</sup>(FAR)]</p>

where

=for html <p>&nbsp;&nbsp;<i>b</i> = &sigma;(<i>N</i>) / &sigma;(<i>S</i>)</p>

=item aprime

Returns the nonparametric index of sensitivity, I<A'>, a.k.a. I<Ag> (e.g., Pastore & Scheirer, Eq. 6). It makes no assumption about the homogeneity of variances of the underlying distributions, and is the average of the maximum and minimum possible areas under the receiver-operating-characteristic curve (based on one ROC point).

=for html <p>&nbsp;&nbsp;<i>a</i>&rsquo; = [ .5 + <i>d</i>(1 + <i>d</i>) ] / 4<i>j</i></p>

where, if HR >= FAR, I<d> = (HR - FAR), and I<j> = HR(1 - FAR), otherwise I<d> = (FAR - HR) and I<j> = FAR(1 - HR).

Ranges from 0 to 1. Values greater than 0.5 indicate positive discrimination (1 = perfect performance); a value of 0.5 indicates no sensitivity to the presence of the signal (it cannot be discriminated from noise); and values less than 0.5 indicate negative discrimination (perhaps given consistent response confusion or inhibition). 

=item adprime

Returns I<Ad'>, the area under the receiver-operator-characteristic (ROC) curve, estimating the proportion of correct responses for the task as a two-alternative forced-choice task.

=for html <p>&nbsp;&nbsp;<i>A</i><sub><i>d</i>&rsquo;</sub> = &phi;(<i>d</i>&rsquo; / sqrt(2))</p>

Ranges between 0 and 1, with a value of 0.5 reflecting no discriminative ability when comparing two stimuli. If both the hit-rate and false-alarm-rate are either 0 or 1, then the returned value of C<sensitivity> is 0.5.

=back

=cut

sub sens {
    my ( $self, $meas, $args ) = @_;
    local $_ = $meas;
    my $d;
  CASE: {
        /^d|f/ixsm    && do { $d = $self->_d_sensitivity( %{$args} ); };
        /^a[p\b]/ixsm && do { $d = $self->_a_sensitivity( %{$args} ) };
        /^ad/ixsm     && do { $d = $self->_ad_sensitivity( %{$args} ); };
        #/^h/ixsm      && do { $d = $self->_hthresh_sensitivity( %{$args} ); };
        #/^p/ixsm      && do { $d = $self->_pcorrect( %{$args} ); };
        #/^lp/ixsm     && do { $d = $self->_lpcorrect( %{$args} ); };
    }    #end CASE
    return _precisioned( $self->{'precision_s'}, $d );
}
*discriminability = \&sens;    # Alias
*sensitivity      = \&sens;

sub _d_sensitivity {
    my ( $self, %args ) = @_;
    my ( $h, $f, $m ) = $self->init(%args);
    #croak 'No hit-rate for calculating d-sensitivity' if ! defined $h;
    my $d;

    # If there are more than 2 alternatives, use a forced-choice method:
    if ( defined $m and $m >= 2 ) {

        #$self->rate(hr => $h, alternatives => $m);
        $d =
          $self->{'method'} eq 'smith'
          ? _fc_smith( $h, $m )
          : _fc_alexander( $h, $m );
    }
    elsif ( all { defined $args{$_} } qw/stdev_n stdev_s/ ) {
        $d = (all { hascontent($_) } ($h, $f))? _d_a( $h, $f, $args{'stdev_s'}, $args{'stdev_n'} ) : q{};
    }
    else {
        $d = (all { hascontent($_) } ($h, $f)) ? _dprime( $h, $f ) : q{};
    }
    return $d;
}

sub _dprime {
    my ( $hr, $far ) = @_;
    my $d;

    # Assume d' = 0 if both rates = 0 or both = 1:
    if ( ( !$hr && !$far ) || ( $hr == 1 && $far == 1 ) ) {
        $d = 0;
    }
    else {
        $d = ndtri($hr) - ndtri($far);
    }
    return $d;
}

sub _d_a {
    my ( $hr, $far, $stdev_s, $stdev_n ) = @_;
    my $d;

    # Assume d' = 0 if both rates = 0 or both = 1:
    if ( ( !$hr && !$far ) || ( $hr == 1 && $far == 1 ) ) {
        $d = 0;
    }
    else {
        my $z_hr  = ndtri($hr);
        my $z_far = ndtri($far);
        my $b     = $stdev_n / $stdev_s;
        $d = sqrt( 2 / ( 1 + $b**2 ) ) * ( $z_hr - $b * $z_far );
    }
    return $d;
}

# Smith (1982) method:
sub _fc_smith {
    my ( $h, $m ) = @_;
    my $d;
    if ( $m < 12 ) {
        my $km = .86 - .085 * log( $m - 1 );
        my $lm = ( ( $m - 1 ) * $h ) / ( 1 - $h );
        $d = $km * log $lm;
    }
    else {
        my $a = ( -4 + sqrt( 16 + 25 * log( $m - 1 ) ) ) / 3;
        my $b = sqrt( ( log( $m - 1 ) + 2 ) / ( log( $m - 1 ) + 1 ) );
        $d = $a + $b * ndtri($h);
    }
    return $d;
}

# Alexander (2006/1990) method:
sub _fc_alexander {
    my ( $h, $m ) = @_;
    my $an = 1 - ( 1 / ( 1.93 + 4.75 * log10($m) + .63 * ( log10($m)**2 ) ) );
    return ( ndtri($h) - ndtri( 1 / $m ) ) / $an;
}

sub _a_sensitivity {
    my ( $self, @args ) = @_;
    my ( $h,    $f )    = $self->init(@args);
    return q{} if any { nocontent($_) } ($h, $f);
    my $d;
    if ( $h >= $f ) {
        $d =
          ( .5 + ( ( $h - $f ) * ( 1 + $h - $f ) ) / ( 4 * $h * ( 1 - $f ) ) );
    }
    else {
        $d =
          ( .5 + ( ( $f - $h ) * ( 1 + $f - $h ) ) / ( 4 * $f * ( 1 - $h ) ) );
    }
    return $d;
}

sub _ad_sensitivity {
    my ( $self, @args ) = @_;
    my ( $h,    $f )    = $self->init(@args);
    return q{} if any { nocontent($_) } ($h, $f);
    my $d;

    # Assume A(d') = 0.5 if both rates = 0 or both = 1:
    if ( ( !$h && !$f ) || ( $h == 1 && $f == 1 ) ) {
        $d = 0.5;
    }
    else {
        $self->rate( h => $h, f => $f );
        $d = ndtr( $self->sensitivity('d') / sqrt 2 );
    }
    return $d;

}

# --------------------
# Bias measures:
# --------------------

=head2 bias

 $b = $sdt->bias('likelihood|loglikelihood|decision|griers') # based on values of the measure variables already inited or otherwise set 
 $b = $sdt->bias('likelihood' => { signal_trials => INT}) # pass to any of the measure variables

Returns an estimate of the SDT decision threshold/response-bias. The particular estimate is named by the first argument string (or at least its first two letters), as below. optionally updating any of the measure variables and options with a subsequent hashref (as given by example for L<signal_trials|Statistics::SDT/signal_trials>). 

With a I<yes> response indicating that the decision variable exceeds the criterion, and a I<no> response indicating that the decision variable is less than the criterion, the measures indicate if there is a bias toward the I<yes> response, and so a liberal/low criterion, or a bias toward the I<no> response, and so a conservative/high criterion.  

=over 4

=item beta, likelihood_bias

Returns the paramteric I<beta> measure of response bias, based on the ratio of the likelihood the decision variable obtains a certain value on signal trials, to the likelihood that it obtains the value on noise trials.

=for html <p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&beta; = exp( [&phi;<sup>&ndash;1</sup>(FAR)<sup>2</sup>&nbsp;&ndash;&nbsp;&phi;<sup>&ndash;1</sup>(HR)<sup>2</sup>] / 2 )</p>

Values less than 1 indicate a bias toward the I<yes> response (more hits and FAs than misses and CRs), values greater than 1 indicate a bias toward the I<no> response (more misses and CRs than hits and FAs), and the value of 1 indicates no bias toward I<yes> or I<no>.

=item log_likelihood_bias

Returns the natural logarithm of the likelihood bias, I<beta>.

=for html <p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;ln&beta; = [ &phi;<sup>&ndash;1</sup>(FAR)<sup>2</sup> &ndash; &phi;<sup>&ndash;1</sup>(HR)<sup>2</sup> ] / 2

Ranges from -1 to +1, with values less than 0 indicating a bias toward the I<yes> response (more hits and FAs than misses and CRs), values greater than 0 indicating a bias toward the I<no> response (more misses and CRs than hits and FAs), and a value of 0 indicating no response bias.

=item c, distance

Returns the I<c> parametric measure of response bias (Macmillan & Creelman, 1991, Eq. 12), defined as the distance between the criterion and the point where beta = 1 (crossing-point of the noise and signal distributions, with neither response favoured; where signal+noise is as likely as noise-only, and so how different the response criterion is from an unbiased criterion).

=for html <p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<i>c</i> = &ndash;[ &phi;<sup>&ndash;1</sup>(HR) + &phi;<sup>&ndash;1</sup>(FAR) ] / 2 

Ranges from -1 to +1, with deviations from zero, measured in standard deviation units. Values less than 0 indicate a bias toward the I<yes> response (more hits and FAs than misses and CRs); values greater than 0 indicate a bias toward the I<no> response (more misses and CRs than hits and FAs); and a value of 0 indicates unbiased responding.

=item griers

Returns Griers I<B''> nonparametric measure of response bias. Defining I<a> = HR(1 - HR) and I<b> = FAR(1 - FAR) if HR >= FAR, otherwise I<a> = FAR(1 - FAR) and I<b> = HR(1 - HR), then I<B''> = ( I<a> - I<b> ) / ( I<a> + I<b> ); or, summarily:

=for html <p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<i>B</i>&rdquo; = sign(HR &ndash; FAR)[ HR(1 &ndash; HR) &ndash; FAR(1 &ndash; FAR) ] / [ HR(1 &ndash; HR) + FAR(1 &ndash; FAR) ]

Ranges from -1 to +1, with values less than 0 indicating a bias toward the I<yes> response (more hits and FAs than misses and CRs), values greater than 0 indicating a bias toward the I<no> response (more misses and CRs than hits and FAs), and a value of 0 indicating no response bias.

=back

=cut

sub bias {
    my ( $self, $meas, $args ) = @_;
    local $_ = $meas;
    my $v;
  CASE: {
        /^b|li/ixsm && do { $v = $self->_likelihood_bias( %{$args} ); };
        /^lo/ixsm   && do { $v = $self->_log_likelihood_bias( %{$args} ); };
        /^c|d/ixsm  && do { $v = $self->_distance_bias( %{$args} ); };
        /^g/ixsm    && do { $v = $self->_griers_bias( %{$args} ) };
    }    #end CASE
    return _precisioned( $self->{'precision_s'}, $v );
}

sub _likelihood_bias {    # beta
    my ( $self, @args ) = @_;
    my ( $h,    $f )    = $self->init(@args);
    return q{} if any { nocontent($_) } ($h, $f);
    my $diff = ( ndtri($f)**2 - ndtri($h)**2 ) / 2;
    return exp $diff;
}

sub _log_likelihood_bias {    # ln(beta)
    my ( $self, @args ) = @_;
    my ( $h,    $f )    = $self->init(@args);
    return q{} if any { nocontent($_) } ($h, $f);
    return ( ndtri($f)**2 - ndtri($h)**2 ) / 2;
}

sub _distance_bias {          # c
    my ( $self, @args ) = @_;
    my ( $h,    $f )    = $self->init(@args);
    return q{} if any { nocontent($_) } ($h, $f);
    return -1 * ( ( ndtri($h) + ndtri($f) ) / 2 );
}

sub _griers_bias {            # B''
    my ( $self, @args ) = @_;
    my ( $h,    $f )    = $self->init(@args);
    return q{} if any { nocontent($_) } ($h, $f);
    my $v1 = $h * ( 1 - $h );
    my $v2 = $f * ( 1 - $f );
    return _sign( $h - $f ) * ( ( $v1 - $v2 ) / ( $v1 + $v2 ) );
}

=head2 dc2logbeta

 $sdt->dc2logbeta() # assume d' and c can be calculated from already inited param values
 $sdt->dc2logbeta(d => FLOAT, c => FLOAT)

Returns the log-likelihood (beta) bias estimated from given values of sensitivity I<d'> and bias I<c>, viz.:

=for html <p>&nbsp;&nbsp;ln&beta; = <i>d</i>&rsquo;<i>c</i></p>

=cut

sub dc2logbeta {
    my ( $self, %args ) = @_;
    my ( $d, $c ) = _get_dc( $self, %args );
    return q{} if any { nocontent($_) } ($d, $c);
    return _precisioned( $self->{'precision_s'}, $d * $c );
}

=head2 criterion

 $sdt->criterion() # from FAR or from d' and c from already inited param values
 $sdt->criterion(far => PROPORTION) # from FAR or from d' and c from already inited param values
 $sdt->criterion(d => FLOAT, c => FLOAT)

I<Alias>: C<crit>

Returns the value of the decision criterion (critical output value of the input process) on the basis of either:

(1) the false-alarm-rate: 

=for html <p>&nbsp;&nbsp;<i>x</i><sub>c</sub> = &ndash;&phi;<sup>&ndash;1</sup>(FAR)</p>

or (2) both sensitivity I<d'> and bias I<c> as:

=for html <p>&nbsp;&nbsp;<i>x</i><sub>c</sub> = <i>d</i>&rsquo; / 2 + <i>c</i></p>

The method firstly checks if FAR can be calculated from given data or specific argument B<far>, or similarly by I<d'> and I<c>.

=cut

sub criterion {
    my ( $self, %args ) = @_;
    my $xc;
    if ( defined $self->rate('far') ) {
        $xc = -1 * ndtri( $self->rate('far') );
    }
    else {
        my ( $d, $c ) = _get_dc( $self, %args );
        if (all { hascontent($_) } ($d, $c) ) {
            $xc = $d / 2 + $c;
        }
    }
    return hascontent($xc) ? _precisioned( $self->{'precision_s'}, $xc ) : q{};
}
*dc2k = \&criterion;    # Alias
*crit = \&criterion;

sub _get_dc {
    my ( $self, %params ) = @_;
    my $d = defined $params{'d'} ? $params{'d'} : $self->sensitivity('d');
    my $c = defined $params{'c'} ? $params{'c'} : $self->bias('c');
    return ( $d, $c );
}

# give count of either hits & signal_trials; or false_alarms and noise_trials
sub _loglinear_correct {
    my ( $count, $trials ) = @_;
    return ( $count + .5 ) / ( $trials + 1 );
}

sub _n_correct {
    my ( $rate, $trials ) = @_;
    my $retval;
    if ( !$rate ) {
        $retval = .5 / $trials;
    }
    elsif ( $rate == 1 ) {
        $retval = ( $trials - .5 ) / $trials;
    }
    else {
        $retval = $rate;
    }
    return $retval;
}

sub _precisioned {
    my ( $lim, $val ) = @_;
    return $lim ? sprintf( q{%.} . $lim . q{f}, $val ) : $val;
}

sub _valid_p {
    my $p = shift;
    return ( $p !~ /^ 0 ? [.] \d+ $/msx ) || ( $p < 0 || $p > 1 ) ? 0 : 1;
}

sub _sign {
    my $v = shift;
    return $v >= 0 ? 1 : -1;
}

1;

__END__

=head1 REFERENCES

Alexander, J. R. M. (2006). An approximation to I<d'> for I<n>-alternative forced choice. From L<http://eprints.utas.edu.au/475/>.

Lee, M. D. (2008). BayesSDT: Software for Bayesian inference with signal detection theory. I<Behavior Research Methods>, I<40>, 450-456. doi: L<10.3758/BRM.40.2.450|https://doi.org/10.3758/BRM.40.2.450>

Macmillan, N. A. & Creelman, C. D. (1991). I<Detection theory: A user's guide>. Cambridge, UK: Cambridge University Press.

Pastore, R. E., & Scheirer, C. J. (1974). Signal detection theory: Considerations for general application. I<Psychological Bulletin>, I<81>, 945-958. doi: L<10.1037/h0037357|http://dx.doi.org/10.1037/h0037357>

Smith, J. E. K. (1982). Simple algorithms for I<M>-alternative forced-choice calculations. I<Perception and Psychophysics>, I<31>, 95-96. doi: L<10.3758/BF03206208|https://doi.org/10.3758/BF03206208>

Stanislaw, H., & Todorov, N. (1999). Calculation of signal detection theory measures. I<Behavior Research Methods, Instruments, and Computers>, I<31>, 137-149. doi: L<10.3758/bf03207704|http://dx.doi.org/10.3758/bf03207704>

Swets, J. A. (1964). I<Signal detection and recognition by human observers>. New York, NY, US: Wiley.

=head1 DIAGNOSTICS

=over 4

=item Number of hits/false-alarms and signal/noise trials needed to calculate rate

Croaked when using L<init|Statistics::SDT/init> or L<rate|Statistics::SDT/rate> and the given arguments are insufficient (as indicated) to calculate hit-rate and/or false-alarm-rate.

=item Uninitialised counts for calculating MR [or CRR]

Croaked if a method depends on calculating the miss-rate (MR) or correct-rejection-rate (CRR) and the necessary counts of signal or noise trials (respectively), or number of misses or correct-rejections (respectively) have not been provided or cannot be inferred.

=back

=head1 DEPENDENCIES

L<List::AllUtils|List::AllUtils> : C<all> and C<any> methods

L<Math::Cephes|Math::Cephes> : C<ndtr> (I<phi>), C<ndtri> (I<inverse phi>) and C<log10> functions

L<String::Numeric|String::Numeric> : C<is_int> and C<is_float> methods

L<String::Util|String::Util> : C<hascontent> and C<nocontent> methods

=head1 SEE ALSO

L<Statistics::Contingency|Statistics::Contingency> : Measure of accuracy for data in the form of hits, misses, correct rejections and false alarms.

L<Statistics::ROC|Statistics::ROC> : Receiver-operator characteristic curves.

=head1 BUGS AND LIMITATIONS

Expects counts, not raw observations, let alone ratings, limiting the measures implemented.

Most methods assume yes/no design, not I<m>-AFC. The interface for the two m-AFC methods is not optimal - HR in their case stands for "percent correct" and is calculated as N(hits) / N(signal trials). This might have to change but fits with present limitations.

Smith (1982) method: his term "N^-1(Pc)" is defined as "the unit normal deviate corresponding to the right tail area P" (p. 95) rather than the left. This suggests using, for inverse-phi, C<ndtri>(1 - Pc) rather than C<ndtri>(Pc), which satisfies his example that "N^-1(.1586) = +1", which is equal to C<ndtri>(1 - .1586), not C<ndtri>(.1586). But to use C<ndtri>(1 - Pc) would produce sensitivity in the wrong direction, even negative (smaller probabilities, larger z-scores); e.g., I<d>' = -.37 when Pc = .96 and m = 13. So C<ndtri>(Pc) (or, rather HR, see above) is used.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::SDT

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-SDT-0.06>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Statistics-SDT-0.06>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Statistics-SDT-0.06>

=item * Search CPAN

L<http://search.cpan.org/dist/Statistics-SDT-0.06/>

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

# end of Statistics::SDT

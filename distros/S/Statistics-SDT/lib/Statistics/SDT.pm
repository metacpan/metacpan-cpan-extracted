package Statistics::SDT;

use strict;
use warnings;
use Carp qw(croak);
use Math::Cephes qw(:dists :explog);
use vars qw($VERSION);
$VERSION = 0.05;

my %counts_dep = (
    hits => [qw/signal_trials misses/], 
    false_alarms => [qw/noise_trials correct_rejections/],
    misses => [qw/signal_trials hits/],
    correct_rejections => [qw/noise_trials false_alarms/],
);
my %trials_dep = (
    signal_trials => [qw/hits misses/],
    noise_trials => [qw/false_alarms correct_rejections/]
);
my %rates_dep = (
    hr => [qw/hits signal_trials/],
    far => [qw/false_alarms noise_trials/]
);

=head1 NAME

Statistics::SDT - Signal detection theory (SDT) measures of sensitivity and response-bias

=head1 SYNOPSIS

The following is based on example data from Stanislav & Todorov (1999), and Alexander (2006), with which the module's results agree.

 use Statistics::SDT 0.05;

 my $sdt = Statistics::SDT->new(
  correction => 1,
  precision_s => 2,
 );

 $sdt->init(
  hits => 50,
  signal_trials => 50, # or misses => 0,
  false_alarms => 17,
  noise_trials => 25, # or correct_rejections => 8
 ); # or init these into 'new' &/or update any of their values as 2nd arg. hashrefs in calling the following methods

 printf("Hit rate = %s\n",            $sdt->rate('h') );          # .99
 printf("False-alarm rate = %s\n",    $sdt->rate('f') );          # .68
 printf("Miss rate = %s\n",           $sdt->rate('m') );          # .00
 printf("Correct-rej'n rate = %s\n",  $sdt->rate('c') );          # .32
 printf("Sensitivity d' = %s\n",      $sdt->sens('d') );          # 1.86
 printf("Sensitivity Ad' = %s\n",     $sdt->sens('Ad') );         # 0.91
 printf("Sensitivity A' = %s\n",      $sdt->sens('A') );          # 0.82
 printf("Bias beta = %s\n",           $sdt->bias('b') );          # 0.07
 printf("Bias logbeta = %s\n",        $sdt->bias('log') );        # -2.60
 printf("Bias c = %s\n",              $sdt->bias('c') );          # -1.40
 printf("Bias Griers B'' = %s\n",     $sdt->bias('g') );          # -0.91
 printf("Criterion k = %s\n",         $sdt->crit() );             # -0.47
 printf("Hit rate via d & c = %s\n",  $sdt->dc2hr() );            # .99
 printf("FAR via d & c = %s\n",       $sdt->dc2far() );           # .68
 printf("LogBeta via d & c = %s\n",   $sdt->dc2logbeta() );       # -2.60

 # If the number of alternatives is greater than 2, there are two method options:
 printf("JAlex. d_fc = %.2f\n", $sdt->sens('f' => {hr => .866, states => 3, correction => 0, method => 'alexander'})); # 2.00
 printf("JSmith d_fc = %.2f\n", $sdt->sens('f' => {hr => .866, states => 3, correction => 0, method => 'smith'})); # 2.05

=head1 DESCRIPTION

Signal Detection Theory (SDT) measures of sensitivity and response-bias, e.g., I<d'>, I<A'>, I<c>. For any particular analysis, you go through the stages of (1) creating the SDT object (see L<new|new>), (2) initialising the object with relevant data (see L<init|init>), and then (3) calling the statistic you want, with any statistic-specific arguments.

=head1 KEY NAMED PARAMS

The following named parameters need to be given as a hash or hash-reference: either to the L<new|new> constructor method, L<init|init>, or into each measure-function. To calculate the hit-rate, you need to feed the (i) count of hits and signal_trials, or (ii) the counts of hits and misses, or (iii) the count of signal_trials and misses. To calculate the false-alarm-rate, you need to feed (i) the count of false_alarms and noise_trials, or (ii) the count of false_alarms and correct_rejections, or (iii) the count of noise_trials and correct_rejections. Or you supply the hit-rate and false-alarm-rate. Or see L<dc2hr|dc2hr> and L<dc2far|dc2far> if you already have the measures, and want to get back to the rates.

=over 4

=item hits

The number of hits.

=item false_alarms

The number of false alarms.

=item signal_trials

The number of signal trials. The hit-rate is derived by dividing the number of hits by the number of signal trials.

=item noise_trials

The number of noise trials. The false-alarm-rate is derived by dividing the number of false-alarms by the number of noise trials.

=item states

The number of response states, or "alternatives", "options", etc.. Default = 2 (for the classic signal-detection situation of discriminating between signal+noise and noise-only). If the number of alternatives is greater than 2, when calling L<sens|sens>, Smith's (1982) estimation of I<d'> is used (otherwise Alexander's) - see L<forced_choice|forced_choice>.

=item correction

Indicate whether or not to perform a correction on the number of hits and false-alarms when the hit-rate or false-alarm-rate equals 0 or 1 (due, e.g., to strong inducements against false-alarms, or easy discrimination between signals and noise). This is relevant to all functions that make use of the I<inverse phi> function (all except I<aprime> option with L<sens|sens>, and the I<griers> option with L<bias|bias>). As C<ndtri> must die with an error if given 0 or 1, there is a default correction.

If C<correction> = 0, no correction is performed to calculation of rates. This should only be used when (1) using the parametric measures and the rates will never be at the extremes of 0 and 1; or (2) using only the nonparametric measures (I<aprime> and I<griers>).

If C<correction> = 1 (default), extreme rates (of 0 and 1) are corrected: 0 is replaced with 0.5 / I<n>; 1 is replaced with (I<n> - 0.5) / I<n>, where I<n> = number of signal or noise trials. This is the most common method of handling extreme rates (Stanislav and Todorov, 1999) but it might bias sensitivity measures and not be as satisfactory as the loglinear transformation applied to all hits and false-alarms, as follows.

If C<correction> > 1, the loglinear transformation is appliedt to I<all> values: 0.5 is added to both the number of hits and false-alarms, and 1 is added to the number of signal and noise trials.

If C<correction> is undefined: To avoid errors thrown by the C<ndtri> function, any values that equal 1 or 0 will be corrected as if it equals 1.

=item precision_s

Precision (I<n> decimal places) of any of the statistics. Default = 0, which actually means that you get all decimal bits possible.

=item method

Method for estimating I<d'> when number of states/alternatives is greater than 2. Default value is I<smith>; otherwise I<alexander>; see L<forced_choice|forced_choice> for application and description of these methods.

=item hr

The hit-rate. Instead of passing the number of hits and signal trials, give the hit-rate directly - but, if doing so, ensure the rate does not equal zero or 1 in order to avoid errors thrown by the inverse-phi function (which will be given as "ndtri domain error").

=item far

This is the false-alarm-rate. Instead of passing the number of false alarms and noise trials, give the false-alarm-rate directly - but, if doing so, ensure the rate does not equal zero or 1 in order to avoid errors thrown by the inverse-phi function (which will be given as "ndtri domain error").

=back

=head1 METHODS

=head2 new

Creates the class object that holds the values of the parameters, as above, and accesses the following methods, without having to resubmit all the values. 

As well as holding the values of the parameters submitted to it, the class-object returned by C<new> will hold two arguments, B<hr>, the hit-rate, and B<far>, the false-alarm-rate. You can supply the hit-rate and false-alarm-rate themselves, but ensure that they do not equal zero or 1 in order to avoid errors thrown by the inverse-phi function. The calculation of the hit-rate and false-alarm-rate by the module corrects for this limitation; correction can only be done by supplying the relevant counts, not just the rate - see the notes on the C<correction> parameter, above. 

=cut

sub new {
	my $class = shift;
	my $self = {};
	bless $self, $class;
    $self->init(@_);
    return $self;
}

=head2 init

 $sdt->init(
    hits => integer,
    misses => ?integer,
    false_alarms => integer,
    correct_rejections => ?integer,
    signal_trials => integer (>= hits), # or will be calculated from hits and misses
    noise_trials => integer (>= false_alarms), # or will be calculated from false_alarms and correction_rejections
    hr => probability 0 - 1,
    far => probablity 0 - 1,
    correction => 0|1|2 (default = 1),
    states => integer >= 2 (default = 2),
    precision_s => integer (default = 0),
    method => undef|smith|alexander (default = undef)
 )

Instead of sending the number of hits, signal-trials, etc., with every call to the measure-functions, or creating a new class object for every set of data, initialise the class object with these values, as named parameters, key => value pairs. This method is called by L<new|new> in case you pass the values to it in construction. The hit-rates and false-alarm rates are always calculated anew from the hits and signal trials, and the false-alarms and noise trials, respectively; unless you send a value for one or the other, or both (as hr and far) in a call to C<init>.

Each C<init> replaces the values only of those attributes that you pass to it - any values set in previous C<init>s are retained for those attributes that you do not set in a call to C<init>. If this is not what you want, and you actually want everything reset, first use L<clear|clear>

Optionally, the method also initialises any values you give it for L<states|states>, L<correction|correction>, L<precision_s|precision_s> and L<method|method>. If you have already set these values, and you do not do so in another call to C<init>; the previous values will be retained.

=cut

sub init {
    my $self = shift;
    if (scalar @_) { # have some params?
        my $args = ref $_[0] ? shift : {@_};
        foreach (qw/hits false_alarms misses correct_rejections signal_trials noise_trials states correction precision_s method hr far/) {
            $self->{$_} = $args->{$_} if defined $args->{$_}; # only (re)set those params given values in this call
        }
        $self->{'states'} ||= 2;
        $self->{'method'} ||= 'smith';
        $self->{'precision_s'} ||= 0;
        # Go round and round:
        foreach (keys %counts_dep) {
            if (! defined $self->{$_} && $self->{$counts_dep{$_}->[0]} && defined $self->{$counts_dep{$_}->[1]}) {
                $self->{$_} = $self->{$counts_dep{$_}->[0]} - $self->{$counts_dep{$_}->[1]};
            }
        }
        foreach (keys %trials_dep) {
            if (! defined $self->{$_} && defined $self->{$trials_dep{$_}->[0]} && defined $self->{$trials_dep{$_}->[1]}) {
                $self->{$_} = $self->{$trials_dep{$_}->[0]} + $self->{$trials_dep{$_}->[1]};
            }
        }
        foreach (keys %rates_dep) {
            if (! defined $args->{$_} && defined $self->{$rates_dep{$_}->[0]} && $self->{$rates_dep{$_}->[1]}) {
                $self->{$_} = _init_rate($self->{$rates_dep{$_}->[0]}, $self->{$rates_dep{$_}->[1]}, $self->{'correction'});
            }
        }
    }
    # no params - assume the values are already in $self
    return ($self->{'hr'}, $self->{'far'}, $self->{'states'});  
}

=head2 clear

 $sdt->clear()

Sets all attributes to undef: C<hits>, C<false_alarms>, C<signal_trials>, C<noise_trials>, C<hr>, C<far>, C<states>, C<correction>, and C<method>.

=cut

sub clear {
    my $self = shift;
    foreach (qw/hits false_alarms misses correct_rejections signal_trials noise_trials hr far states correction precision_s method/) {
        $self->{$_} = undef;
    }
}

=head2 rate

 $sdt->rate('hr|far|mr|crr') # scalar string to return the indicated rate
 $sdt->rate(hr => 'prob.', far => 'prob.', mr => 'prob.', crr => 'prob.') # one or more key => value pairs to set the rate
 $sdt->rate('h' => {signal_trials => integer, hits => integer}) # or misses instead of hits
 $sdt->rate('f' => {noise_trials => integer, false_alarms => integer}) # or correct_rejections instead of false_alarms
 $sdt->rate('m' => {signal_trials => integer, misses => integer})  # or hits instead of misses
 $sdt->rate('c' => {noise_trials => integer, correct_rejections => integer})  # or false_alarms instead of correct_rejections

Generic method to get or set any rate.

To I<get> a rate, pass only a string that indicates the rate: hit, false-alarm, miss, correct-rejection: only checks the first letter, so any passable abbreviation will do. The rate is returned to the precision indicated by the present value of L<precision_s|precision_s>, if anything.

To I<set> a rate, either give the actual probability as key => value pairs, or send a hashref giving sufficient info to calculate the rate (if this has not already been sent to L<init|init> or one of the measure-methods). 

Also performs any required or requested corrections, depending on the present value of L<correction|correction>.

Unless the values of the rates are directly given, then they will be calculated from the presently sent counts and trial-numbers, or whatever has been cached of these values. For the hit-rate, there must be a value for C<hits> and C<signal_trials>, and for the false_alarm_rate, there must be a value for C<false_alarms> and C<noise_trials>.  If these values are not sent, they will be taken from any prior value, unless this has been L<clear|clear>ed or never existed - in which case expect a C<croak>.

=cut

# --------------------
sub rate {
# --------------------
    my $self = shift;
    
    if (scalar(@_) == 1) { # Get the rate:
        local $_ = shift;
        CASE:{
            /^h/i && do { return $self->_hit_rate();};
            /^f/i && do { return $self->_false_alarm_rate(); };
            /^m/i && do { return $self->_miss_rate();};
            /^c/i && do { return $self->_correct_rejection_rate()};
        } #end CASE
    }
    ##else {
    elsif (scalar(@_) > 1) { # Set the rate:
        my %params = @_;
        foreach (keys %params) {
            my @args = ref $params{$_} ? %{$params{$_}} : $params{$_}; # optimistic
            CASE:{
                /^h/i && do { $self->_hit_rate(@args); last CASE; };
                /^f/i && do { $self->_false_alarm_rate(@args); last CASE; };
                /^m/i && do { $self->_miss_rate(@args); last CASE; };
                /^c/i && do { $self->_correct_rejection_rate(@args)};
            } #end CASE
        }
    }
}

sub _hit_rate {
    my $self = shift;
    if (@_ > 1) { # set the rate via params
        my (%params) = @_;
        $self->{$_} = $params{$_} foreach keys %params;
        $self->{'hr'} = _init_rate($self->{'hits'}, $self->{'signal_trials'}, $self->{'correction'});
    }
    elsif (@_ == 1) { # set the rate as given
        $self->{'hr'} = _valid_p($_[0]) ? shift : croak __PACKAGE__, ' Rate needs to be between 0 and 1 inclusive';
    }
    return _precisioned($self->{'precision_s'}, $self->{'hr'});
}

sub _false_alarm_rate {
    my $self = shift;
    if (@_ > 1) { # set the rate via params
        my (%params) = @_;
        $self->{$_} = $params{$_} foreach keys %params;
        $self->{'far'} = _init_rate($self->{'false_alarms'}, $self->{'noise_trials'}, $self->{'correction'});
     }
     elsif (@_ == 1) { # set the rate as given
        $self->{'far'} = _valid_p($_[0]) ? shift : croak __PACKAGE__, ' Rate needs to be between 0 and 1 inclusive';
     }
     return _precisioned($self->{'precision_s'}, $self->{'far'});
}

sub _miss_rate {
    my ($self, %params) = @_;
    $self->{$_} = $params{$_} foreach keys %params;
    ##$self->{'misses'} = $self->{'signal_trials'} - $self->{'hits'} if ! defined $self->{'misses'};# be optimistic
    return _precisioned($self->{'precision_s'}, $self->{'misses'} / $self->{'signal_trials'});
}

sub _correct_rejection_rate {
    my ($self, %params) = @_;
    $self->{$_} = $params{$_} foreach keys %params;
    #$self->{'correct_rejections'} = $self->{'noise_trials'} - $self->{'false_alarms'} if ! defined $self->{'correct_rejections'};# be optimistic
    return _precisioned($self->{'precision_s'}, $self->{'correct_rejections'} / $self->{'noise_trials'});
}

# --------------------
# Sensitivity measures:
# --------------------

=head2 sens

 $s = $sdt->sens('dprime|forcedchoice|area|aprime') # based on values of the measure variables already inited or otherwise set 
 $s = $sdt->sens('dprime' => { signal_trials => integer}) # update any of the measure variables

I<Alias>: C<sensitivity>, C<discriminability>

Get one of the sensitivity measures, as indicated by the first argument string, optionally updating any of the measure variables and options with a subsequent hashref. The measures are as follows, accessed by giving the name (or at least its first two letters) as the first argument.

=over 4

=item dprime

Returns the index of sensitivity, or discrimination, I<d'> (d prime), found by subtracting the I<z>-score that corresponds to the false-alarm rate (B<far>) from the I<z>-score that corresponds to the hit rate (B<hr>): 

=for html <p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<i>d'</i> = phi<sup>&ndash;1</sup>(hr)&nbsp;&ndash;&nbsp;phi<sup>&ndash;1</sup>(far)</p>

In this way, sensitivity is measured in standard deviation units, larger positive values indicating greater sensitivity. If both the hit-rate and false-alarm-rate are either 0 or 1, then L<sens|sens>itivity returns 0. A value of 0 indicates no sensitivity to the presence of the signal, i.e., it cannot be discriminated from noise. Values less than 0 indicate a lack of sensitivity that might result from a consistent, state-specific "mix-up" or inhibition of responses.

If there are more than two states (not only signal and noise-plus-signal), then I<d'> will be estimated by the following.

=item forced_choice

An estimate of I<d'> based on the percent correct in a forced-choice task with any number of alternatives. This method is automatically called via L<sens|sens>itivity if the value of C<states> is greater than 2. Only for this condition is it not necessary to calculate the false-alarm rate; the hit-rate is formed, as usual, as the count of hits divided by signal_trials.

At least a couple methods are available to estimate I<d'> when states > 2; accordingly, there is the option - set either in L<init|init> or L<sens|sens>itivity or otherwise - for C<method>: its default value is I<smith> (this is the method cited by Stanislav & Todorov (1999)); otherwise, you can use the more generally applicable I<alexander> method:

B<I<Smith (1982) method>>: satisfies "the 2% bound for all I<M> [states] and all percentiles and, except for I<M> = 3 or 4, satisfies a 1% error bound". The specific algorithm used depends on number of states: 

For I<n> states E<lt> 12:

=for html <p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<i>d'</i> = K<sub>M</sub>.log(  ( (<i>n</i>&ndash;&nbsp;1).<i>hr</i> ) / ( 1 &ndash; <i>hr</i> ) )</p>

where

=for html <p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;K<sub>M</sub> = .86 &ndash; .085 . log(<i>n</i>&nbsp;&ndash;&nbsp;1).</p>

If I<n> >= 12,

=for html <p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<i>d'</i> = A + B . phi<sup>&ndash;1</sup>(hr)</p>

where

=for html <p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<i>A</i> = (&ndash;4 + sqrt(16 + 25 . log(<i>n</i> &ndash; 1))) / 3</p>

and

=for html <p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<i>B</i> = sqrt( (log(<i>n</i> &ndash; 1) + 2) / (log(<i>n</i> &ndash; 1) + 1) )</p>

B<I<Alexander (2006/1990) method>>: "gives values of I<d'> with an error of less than 2% (mostly less than 1%) from those obtained by integration for the range I<d'> = 0 (or 1% correct for I<n> [states] > 1000) to 75% correct and an error of less than 4% up to 95% correct for I<n> up to at least 10000, and slightly greater maximum errors for I<n> = 100000. This approximation is comparable to the accuracy of Elliott's table (0.02 in proportion correct) but can be used for any I<n>." (Elliott's table being that in Swets, 1964, pp. 682-683). The estimation is offered by:

=for html <p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<i>d'</i> = ( phi<sup>&ndash;1</sup>(hr) &ndash;&nbsp;phi<sup>&ndash;1</sup>(1/<i>n</i>) ) / <i>An</i></p>

where I<n> is the number of L<states|states> (or alternatives, alphabet-size, etc.), and I<An> is estimated by:

=for html <p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<i>An</i> = 1 / (1.93 + 4.75.log<sub>10</sub>(<i>n</i>) + .63.[log<sub>10</sub>(<i>n</i>)]<sup>2</sup>)</p>

=item aprime

Returns the nonparametric index of sensitivity, I<A'>.

Ranges from 0 to 1. Values greater than 0.5 indicate positive discrimination (1 = perfect performance); values less than 0.5 indicate a failure of discrimination (perhaps due to consistent "mix-up" or inhibition of state-specific responses); and a value of 0.5 indicates no sensitivity to the presence of the signal, i.e., it cannot be discriminated from noise.

=item adprime

Returns I<Ad'>, the area under the receiver-operator-characteristic (ROC) curve, equalling the proportion of correct responses for the task as a two-alternative forced-choice task.

If both the hit-rate and false-alarm-rate are either 0 or 1, then C<sensitivity> with this argument returns 0.5.

=back

=cut

# --------------------
sub sens {
# --------------------
    my $self = shift;
    local $_ = shift;
    my %args = ref $_[0] ? %{(shift)} : (); # optimistic
    CASE:{
        /^d/i && do { return $self->_d_sensitivity(%args); };
        /^f/i && do { return $self->_d_sensitivity_fc(%args); };
        /^a(p|\b)/i && do { return $self->_a_sensitivity(%args)};
        /^ad/i && do { return $self->_ad_sensitivity(%args); };
    } #end CASE
}
*discriminability = \&sens; # Alias
*sensitivity =\&sens;

sub _d_sensitivity {
    my $self = shift;
    my ($h, $f, $m, $d) = $self->init(@_);
    $m ||= 2;
    # If there are more than 2 states, use a forced-choice method:
    if ($m > 2) {
        #croak 'No hit-rate for calculating d-sensitivity' if ! defined $h;
        $self->rate(hr => $h, states => $m);
        $d = $self->_sensitivity_fc();
    }
    else {
        # Assume d' = 0 if both rates = 0 or both = 1:
        if ( (!$h && !$f) || ($h == 1 && $f == 1) ) {
            $d = 0;
        }
        else {
            my ($a, $b) = ();
            $a = ndtri($h);
            $b = ndtri($f);
            $d = $a - $b;
        }
    }
    return _precisioned($self->{'precision_s'}, $d);
}

sub _d_sensitivity_fc {
    my $self = shift;
    my ($h, $f, $m, $d) = $self->init(@_); # $d is undefined
    croak "No hit-rate for calculating forced-choice sensitivity" if ! defined $h;
    croak "No number of alternative choices for calculating forced-choice sensitivity" if ! defined $m;
    if ($self->{'method'} eq 'smith') { # Smith (1982) method:
        if ($m < 12) {
            my $km = .86 - .085 * log($m - 1);
            my $lm = ( ($m - 1) * $h) / (1 - $h);
            $d = $km * log($lm);
        }
        else {
            my $a = ( -4 + sqrt(16 + 25 * log($m - 1) ) )/3;
            my $b = sqrt( ( log($m - 1) + 2) / (log($m - 1) + 1) );
            $d = $a + ($b * ndtri($h));
        }
    }
    else {# Alexander (2006/1990) method:
        my $An = _An($m);
        my $a = ndtri($h);
        my $b = ndtri(1/$m);
        $d = ($a - $b) / $An;
    }
    return _precisioned($self->{'precision_s'}, $d);
}

sub _An {
    my $n = shift;
    return 1 - ( 1 / ( 1.93 + 4.75 * log10($n) + .63 * (log10($n)**2 ) ) );
}

sub _a_sensitivity {
    my $self = shift;
    my ($h, $f, $d) = $self->init(@_);
    
    if ($h >= $f) {
        $d = (.5 + ( ($h - $f) * (1 + $h - $f) ) / ( 4 * $h * (1 - $f) ) );
    }
    else {
        $d = (.5 + ( ($f - $h) * (1 + $f - $h) ) / ( 4 * $f * (1 - $h) ) );
    }
    return _precisioned($self->{'precision_s'}, $d);
}

sub _ad_sensitivity {
    my $self = shift;
    my ($h, $f, $d) = $self->init(@_);
    
    # Assume A(d') = 0.5 if both rates = 0 or both = 1:
    if ( (!$h && !$f) || ($h == 1 && $f == 1) ) {
        $d = 0.5;
    }
    else {
        $self->rate(h => $h, f => $f);
        $d = ndtr($self->sensitivity('d') / sqrt(2));
    }
    return _precisioned($self->{'precision_s'}, $d);
    
}

# --------------------
# Bias measures:
# --------------------

=head2 bias

 $b = $sdt->bias('likelihood|loglikelihood|decision|griers') # based on values of the measure variables already inited or otherwise set 
 $b = $sdt->bias('likelihood' => { signal_trials => integer}) # update any of the measure variables

Get one of the decision/response-bias measures, as indicated below, by the first argument string, optionally updating any of the measure variables and options with a subsequent hashref (as given by example for C<signal_trials>, above). 

With a I<yes> response indicating that the decision variable exceeds the criterion, and a I<no> response indicating that the decision variable is less than the criterion, the measures indicate if there is a bias toward the I<yes> response, and so a liberal/low criterion, or a bias toward the I<no> response, and so a conservative/high criterion.  

The measures are as follows, accessed by giving the name (or at least its first two letters) as the first argument to C<bias>.

=over 4

=item beta (or) likelihood_bias

Returns the I<beta> measure of response bias, based on the ratio of the likelihood the decision variable obtains a certain value on signal trials, to the likelihood that it obtains the value on noise trials.

=for html <p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<i>beta</i> = exp( ( (phi<sup>&ndash;1</sup>(<i>far</i>)<sup>2</sup>&nbsp;&ndash;&nbsp;phi<sup>&ndash;1</sup>(<i>hr</i>)<sup>2</sup>) ) / 2 )</p>

Values less than 1 indicate a bias toward the I<yes> response, values greater than 1 indicate a bias toward the I<no> response, and the value of 1 indicates no bias toward I<yes> or I<no>.

=item log_likelihood_bias

Returns the natural logarithm of the likelihood bias, I<beta>. 

Ranges from -1 to +1, with values less than 0 indicating a bias toward the I<yes> response, values greater than 0 indicating a bias toward the I<no> response, and a value of 0 indicating no response bias.

=item c (or) decision_bias

Implements the I<c> parametric measure of response bias. Ranges from -1 to +1, with deviations from zero, measured in standard deviation units, indicating the position of the decision criterion with respect to the neutral point where the signal and noise distributions cross over, there is no response bias, and I<c> = 0.

Values less than 0 indicate a bias toward the I<yes> response; values greater than 0 indicate a bias toward the I<no> response; and a value of 0 indicates no response bias.

=item griers_bias

Implements Griers I<B''> nonparametric measure of response bias. 

Ranges from -1 to +1, with values less than 0 indicating a bias toward the I<yes> response, values greater than 0 indicating a bias toward the I<no> response, and a value of 0 indicating no response bias.

=back

=cut

# --------------------
sub bias {
# --------------------
    my $self = shift;
    local $_ = shift;
    my %args = ref $_[0] ? %{(shift)} : (); # optimistic
    CASE:{
        /^b|li/i && do { return $self->_likelihood_bias(%args); };
        /^lo/i && do { return $self->_log_likelihood_bias(%args); };
        /^c|d/i && do { return $self->_decision_bias(%args); };
        /^g/i && do { return $self->_griers_bias(%args)};
    } #end CASE
}

sub _likelihood_bias { # beta
    my $self = shift;print "args = ", join(', ', @_), "\n";
    my ($h, $f) = $self->init(@_);#print "init: hr = $h far = $f\n";
    return _precisioned($self->{'precision_s'}, exp( ( ( (ndtri($f)**2) - (ndtri($h)**2) ) / 2 ) ) );
}

sub _log_likelihood_bias { # ln(beta)
    my $self = shift;
    my ($h, $f) = $self->init(@_);
    return _precisioned($self->{'precision_s'}, ( ( (ndtri($f)**2) - (ndtri($h)**2) ) / 2 ));
}

sub _decision_bias { # c
    my $self = shift;
    my ($h, $f) = $self->init(@_);
    return _precisioned($self->{'precision_s'}, -1 *( ( ndtri($h) + ndtri($f) ) / 2 ) );
}

sub _griers_bias { # B''
    my $self = shift;
    my ($h, $f) = $self->init(@_);
    my ($a, $b, $c) = ();
    if ($h >= $f) {
        $a = ( $h * (1 - $h) );
        $b = ( $f * (1 - $f) );
        $c =  ( $a - $b ) /  ( $a + $b );
    }
    else {
        $a = ( $f * (1 - $f) );
        $b = ( $h * (1 - $h) );
        $c = ( $a - $b ) / ( $a + $b );
    }
    return _precisioned($self->{'precision_s'}, $c); 
}

=head2 criterion

 $sdt->criterion() # assume d' and c can be calculated from already inited param values
 $sdt->criterion(d => float, c => float)

I<Alias>: C<dc2k>, C<crit>

Returns the value of the criterion for given values of sensitivity I<d'> and bias I<c>, viz.: I<k> = I<d'> / 2 + I<c>.

=cut

# --------------------
sub criterion {
# --------------------
    my $dc = _get_dc(@_);
    return _precisioned($_[0]->{'precision_s'}, ($dc->{'d'} / 2) + $dc->{'c'} );
}
*dc2k = \&criterion; # Alias
*crit = \&criterion; 


=head2 dc2hr

 $sdt->dc2hr() # assume d' and c can be calculated from already inited param values
 $sdt->dc2hr(d => float, c => float)

Returns the hit-rate estimated from given values of sensitivity I<d'> and bias I<c>, viz.: I<hr> = phi(I<d'> / 2 - I<c>).

=cut

# --------------------
sub dc2hr {
# --------------------
    my $dc = _get_dc(@_);
    return _precisioned($_[0]->{'precision_s'}, ndtr(($dc->{'d'} / 2) - $dc->{'c'}) );
}

=head2 dc2far

 $sdt->dc2far() # assume d' and c can be calculated from already inited param values
 $sdt->dc2far(d => float, c => float)

Returns the false-alarm-rate estimated from given values of sensitivity I<d'> and bias I<c>, viz.: I<far> = phi(-I<d'> / 2 - I<c>).

=cut

# --------------------
sub dc2far {
# --------------------
    my $dc = _get_dc(@_);
    return _precisioned($_[0]->{'precision_s'},  ndtr(-1*($dc->{'d'} / 2) - $dc->{'c'}) );
}

=head2 dc2logbeta

 $sdt->dc2logbeta() # assume d' and c can be calculated from already inited param values
 $sdt->dc2logbeta(d => float, c => float)

Returns the log-likelihood (beta) bias estimated from given values of sensitivity I<d'> and bias I<c>, viz.: I<b> = I<d'> . I<c>.

=cut

# --------------------
sub dc2logbeta {
# --------------------
    my $dc = _get_dc(@_);
    return _precisioned($_[0]->{'precision_s'}, $dc->{'d'} * $dc->{'c'} );
}

sub _get_dc {
    my ($self, %params) = @_;
    my %dc = ();
    foreach (qw/d c/) {
        $dc{$_} = $params{$_} if defined $params{$_};
    }
    $dc{'d'} = $self->sensitivity('d') if !defined $dc{'d'};
    $dc{'c'} = $self->bias('c') if !defined $dc{'c'};
    return \%dc;
}

sub _init_rate {# Initialise hit and false-alarm rates:

    my ($count, $trials, $correction) = @_;
    my $rate;
    $correction = 1 if !defined $correction; # default correction

    # Need (i) no. of hits and signal trials, or (ii) no. of false alarms and noise trials:
    croak __PACKAGE__, " Number of hits/false-alarms and signal/noise trials needed to calculate rate" if ! defined $count || ! defined $trials;

    if ($correction > 1) { # loglinear correction, regardless of values:
         $rate = _loglinear_correct($count, $trials);
    }
    else { # get rate first, applying corrections if needed (unless explicitly verboten):
        $rate = $count / $trials;
        unless ($correction == 0) {
            $rate = _n_correct($rate, $trials);
        }
    }
    return $rate;
}

sub _loglinear_correct {
   return ($_[0] + .5) / ($_[1] + 1); # either hits & signal_trials; or false_alarms and noise_trials
}

sub _n_correct {
    my ($rate, $trials) = @_;
    my $retval;
    if (! $rate) {
        $retval = .5 / $trials;
    }
    elsif ($rate == 1) {
        $retval = ($trials - .5) / $trials;
    }
    else {
        $retval = $rate;
    }
    return $retval;
}

sub _precisioned {
    return $_[0] ? sprintf('%.' . $_[0] . 'f', $_[1]) : $_[1];
}

sub _valid_p {
    my $p = shift;
    return ($p !~ /^0?\.\d+$/) || ($p < 0 || $p > 1) ? 0 : 1;
}

1;

__END__

=head1 REFERENCES

Alexander, J. R. M. (2006). An approximation to I<d'> for I<n>-alternative forced choice. From L<http://eprints.utas.edu.au/475/>.

Lee, M. D. (2008). BayesSDT: Software for Bayesian inference with signal detection theory. I<Behavior Research Methods>, I<40>, 450-456.

Smith, J. E. K. (1982). Simple algorithms for I<M>-alternative forced-choice calculations. I<Perception and Psychophysics>, I<31>, 95-96.

Stanislaw, H., & Todorov, N. (1999). Calculation of signal detection theory measures. I<Behavior Research Methods, Instruments, and Computers>, I<31>, 137-149.

Swets, J. A. (1964). I<Signal detection and recognition by human observers>. New York, NY, US: Wiley.

=head1 SEE ALSO

L<Math::Cephes|lib::Math::Cephes> : The present module imports/depends upon the L<ndtr|lib::Math::Cephes> (I<phi>) and L<ndtri|lib::Math::Cephes> (I<inverse phi>) functions from this package.

L<Statistics::ROC|lib::Statistics::ROC> : Receiver-operator characteristic curves.

=head1 LIMITATIONS/TODO

Expects descriptive counts, not raw observations, confidence ratings; this limits the measures that can be implemented: methods C<load> and C<unload> are reserved to implement handling of data lists.

Perl's C<params> modules do not seem to effect the required validation of parameters needed for each measure; the present work-around is obsessive-compulsive, while not exhaustive of all wayward possibilities, and requires optimisation but extension. It is presently quite possible to suffer an inelegant death should anything too unsual, or impoverished of details, be attempted in the life of the module.

=head1 REVISION HISTORY

See Changes file in installation dist.

=head1 AUTHOR/LICENSE

=over 4

=item Copyright (c) 2006-2013 Roderick Garton

rgarton AT cpan DOT org

This program is free software. It may be used, redistributed and/or modified under the same terms as Perl-5.6.1 (or later) (see L<http://www.perl.com/perl/misc/Artistic.html>).

=item Disclaimer

To the maximum extent permitted by applicable law, the author of this module disclaims all warranties, either express or implied, including but not limited to implied warranties of merchantability and fitness for a particular purpose, with regard to the software and the accompanying documentation.

=back

=head1 END

This ends documentation for a Perl implementation of signal detection theory measures of sensitivity and bias.

=cut

package Statistics::Sequences::Pot;

use 5.008008;
use strict;
use warnings;
use Carp 'croak';
use vars qw($VERSION @ISA);
use Statistics::Sequences 0.10;
@ISA = qw(Statistics::Sequences);
$VERSION = '0.12';
use Statistics::Zed 0.072;
our $zed = Statistics::Zed->new();

=pod

=head1 NAME

Statistics::Sequences::Pot - Helmut Schmidt's test of force-like runs of a discrete state within a numerical or categorical sequence

=head1 SYNOPSIS

 use strict;
 use Statistics::Sequences::Pot 0.12; # methods/args here are not compatible with earlier versions
 my $pot = Statistics::Sequences::Pot->new();
 $pot->load([qw/2 0 8 5 3 5 2 3 1 1 9 4 4 1 5 5 6 5 8 7 5 3 8 5 6/]); # strings/numbers; or send as "data => $aref" with each stat call
 my $val = $pot->observed(state => 5); # other methods include: expected(), variance(), obsdev() and stdev()
 $val = $pot->zscore(state => 5, tails => 2, ccorr => 1); # # or want an array & get back both z- and p-value
 $val = $pot->p_value(state => 5, tails => 1); # assuming data are loaded; alias: test()
 my $href = $pot->stats_hash(values => {observed => 1, p_value => 1}, state => 5); # include any other stat-method as needed
 $pot->dump(values => {observed => 1, expected => 1, p_value => 1}, state => 5, flag => 1, precision_s => 3, precision_p => 7);
 # prints: observed = 4.310, expected = 4.529, p_value = 0.8090600

=head1 DESCRIPTION

The Pot statistic measures the bunching relative to the spacing of a single state within a series of other states, conceived by Helmut Schmidt as a targeted "potential" energy (or Pot) that dissipates exponentially between states. It's not limited to considering only clusters of I<consecutive> states (or bunches), as is the case with the more familiar Runs test of sequences.

Say you're interested in the occurrence of the state B<3> within an array of digits: note how, in the following arrays, there are increasing breaks between the B<3>s (separated by 0, 1 and then 2 other states):

 4, 7, 3, 3
 3, 4, 3, 7
 3, 8, 1, 3

The occurrence of B<3> is, with the Pot-test, of exponentially declining interest across these sequences, given the increasing breaks by other states between the occurrences of 3. The statistic does not ignore these ever remoter occurrences of the state of interest; it accounts for increased spacing between them as if there were an exponentially declining force, a I<pot>ential towards B<3>, within the data-stream (up to a theoretical or empirical asymptote that may be specified).

Running the Pot-test involves testing its significance as a standard "z" score; Schmidt (2000) provided data demonstrating Pot's conformance with the normal distribution. This will naturally be improved by repeated sampling, and by using block averages.

=head1 METHODS

Methods are essentially as described in L<Statistics::Sequences>

=head2 new

 $pot = Statistics::Sequences::Pot->new();

Returns a new Pot object. Expects/accepts no arguments but the classname.

=head2 load

 $pot->load(@data); # anonymously
 $pot->load(\@data);
 $pot->load('sample1' => \@data); # labelled whatever

Loads data anonymously or by name - see L<load|Statistics::Data/load, load_data> in the Statistics::Data manpage for details on the various ways data can be loaded and then retrieved (more than shown here). 

Data can be categorical or numerical, and multi-valued - i.e, unlike in tests of L<runs|Statistics::Sequences::Runs> and L<joins|Statistics::Sequences::Joins>, they do not have to be dichotomous.

=head2 add, read, unload

See L<Statistics::Data> for these additional operations on data that have been loaded.

=head2 observed, pot_observed, pvo

 $v = $pot->observed(state => 'x'); # use the first data loaded anonymously; specify a 'state' within it to test its pot
 $v = $pot->observed(index => 1, state => 'x'); # ... or give the required "index" for the loaded data
 $v = $pot->observed(label => 'mysequence', state => 'x'); # ... or its "label" value
 $v = $pot->observed(data => [qw/x z x x p c/], state => 'x'); # ... or just give the data now

Returns observed value of pot, a measure of the number and size of bunchings of the state that occurred within the array. The data to calculate this on can already have been L<load|load>ed, or you send it here as a flat referenced array keyed as B<data>. The observed value of pot is based on Schmidt (2000), Equations 6-7, and his Appended program, viz.:

=for html <p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<i>I</i>,<i>J</i>=1..<i>N</i><br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&Sigma;&nbsp;&nbsp;<i>r</i><sup>|<i>n</i>(<i>I</i>) - <i>n</i>(<i>J</i>)|</sup><br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<i>I</i>&lt;<i>J</i></p>

where 

=for html <p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<i>r</i> = <i>e</i><sup>&ndash;<i>N</i>/<i>MS</i></sup></p>

is the number of observations, and I<S> (for scale) is a constant determining the range I<r> of the potential energy between pairs of I<I> and I<J> states. These values are set as C<name =E<gt> value> pairs, as follows.

B<state> => I<string>

The state within the data whose bunching is to be tested. This is the only required argument; C<croak> if no state is specified. Returns 0 if this state does not exist in the data.

B<scale> => I<numeric> E<gt>= 1

Optionally, the scale of the range parameter, which should be greater than or equal to 1. Default = 1; values less than 1 are effected as 1.

In most situations, should all states be equiprobable, or their probability be proportionate to their number, I<r> would reflect the average distance, or delay, between I<successive> states, equal to the number of all observations divided by the number of states. For example, if there were 10 possible states, and 100 observations have been made, then the probability of re-occurrence of any one of the 10 states within any slot will be equal to 100/10, with I<S> = 1, i.e., expecting that any one of the states would mostly occur by a spacing of 10, and then by an exponentially declining tendency toward consecutive occurrence. In this way, with I<S> = 1, Pot is a measure of "short-range bunching," as Schmidt called it. Bunching over a larger range than this minimally expected range can be measured with I<S> > 1. This is specified, optionally, as the argument named B<scale> to L<test|test>. Hypothesis-testing might be made with respect to various values of the B<scale> parameter.

=cut

sub observed {# measure pot in the given data for given state, Schmidt (2000) Equations 6-7:
    my ($m, $n, $r, $scale, $state, $indices) = _set_terms(@_);
    my ($pvo, $i, $j) = (0);
    for $i (1 .. ($n - 1)) {
        for $j (0 .. $i - 1) {
            $pvo += $r**abs($indices->[$i] - $indices->[$j]);
        }
    }
    return $pvo;
}
*pot_observed = \&observed;
*pvo = \&observed;

=head2 expected, pot_expected, pve

 $v = $pot->expected(state => 'x'); # or specify loaded data by "index" or "label", or give it as "data" - see observed()
 $v = $pot->expected(data => [qw/x z x x p c/], state => 'x'); # use these data

Returns the theoretically expected value of Pot, given I<N> states among I<M> observations, and I<r> range of clustering within these observations. It is calculated as follows from Schmidt (2000) Eq. 8, given the above definitions.

=for html <p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Pot = ((<i>N</i>(<i>N</i> &ndash; 1))/(<i>M</i>(<i>M</i> &ndash; 1))) . (<i>r</i>/1 &ndash; <i>r</i>) . (<i>M</i> &ndash; (1/(1 &ndash; <i>r</i>)))</p>

=cut

sub expected { # calculate expected Pot: Schmidt (2000) Equation 8:
    my ($m, $n, $r) = _set_terms(@_);
    my $pve = 0;
    if ($m > 1 && $r < 1) {
        $pve = $n * ($n - 1) * $r * ( $m - 1 / (1 - $r) ) / ( $m * ($m - 1) * (1 - $r) );
    }
    return $pve;
}
*pot_expected = \&expected;
*pve = \&expected;

=head2 variance, pot_variance, pvv

 $v = $pot->variance(state => 'x'); # or specify loaded data by "index" or "label", or give it as "data" - see observed()
 $v = $pot->variance(data => [qw/x z x x p c/], state => 'x'); # use these data

Returns the variance in the theoretically expected value of pot, given by Schmidt (2000) Equation 9a:

=for html <p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Variance = (<i>r</i>&sup2;/ (1 &ndash; <i>r</i>&sup2;) . (<i>N</i> / <i>M</i>) . (1 &ndash; (<i>N</i> / <i>M</i>))&sup2; . <i>N</i></p>

=cut

sub variance {
   my ($m, $n, $r) = _set_terms(@_);
   my $var = 0;
   my $rsq = $r**2;
   if ($m && $rsq < 1) {
    $var = ( $rsq * $n**2 * (1 - $n / $m)**2 )
              /
           ( $m * (1 - $rsq) );
    }
    return $var;
}
*pot_variance = \&variance;
*pvv = \&variance;

=head2 obsdev, observed_deviation

 $v = $pot->obsdev(state => 'x'); # use data already loaded - anonymously; or specify its "label" or "index" - see observed()
 $v = $pot->obsdev(data => [qw/x z x x p c/], state => 'x'); # use these data

Returns the deviation of (difference between) observed and expected pot for the loaded/given sequence (I<O> - I<E>). 

=cut

sub obsdev {
    return observed(@_) - expected(@_);
}
*observed_deviation = \&obsdev;

=head2 stdev, standard_deviation

 $v = $pot->stdev(state => 'x'); # use data already loaded - anonymously; or specify its "label" or "index" - see observed()
 $v = $pot->stdev(data => [qw/x z x x p c/], state => 'x');

Returns square-root of the variance.

=cut

sub stdev {
    return sqrt(variance(@_));
}
*standard_deviation = \&stdev;

=head2 z_value, zscore, pot_zscore, pzs

 $v = $pot->z_value(ccorr => 1, state => 'x'); # use data already loaded - anonymously; or specify its "label" or "index" - see observed()
 $v = $pot->z_value(data => $aref, ccorr => 1, state => 'x');
 ($zvalue, $pvalue) = $pot->z_value(data => $aref, ccorr => 1, tails => 2, state => 'x'); # same but wanting an array, get the p-value too

Returns the zscore from a test of pot deviation, taking the pot expected away from that observed and dividing by the root expected pot variance, by default with a continuity correction to expectation. Called wanting an array, returns the z-value with its I<p>-value for the tails (1 or 2) given.

The data to test can already have been L<load|load>ed, or sent directly as an aref keyed as B<data>.

Other options are B<precision_s> (for the z_value) and B<precision_p> (for the p_value).

=cut

sub z_value {
   my $self = shift;
   my $args = ref $_[0] ? shift : {@_};
   my $ccorr = defined $args->{'ccorr'} ? $args->{'ccorr'} : 1;
   my $tails = $args->{'tails'} || 2;
   my $precision_s = $args->{'precision_s'};
   my $precision_p = $args->{'precision_p'};
   my $pvo = defined $args->{'observed'} ? $args->{'observed'} : $self->pvo($args);
   
   my ($zval, $pval) = $zed->zscore(
        observed => $pvo,
        expected => $self->pve($args),
        variance => $self->pvv($args),
        ccorr => $ccorr,
        tails => $tails,
        precision_s => $precision_s, 
        precision_p => $precision_p,
     );
    return wantarray ? ($zval, $pval) : $zval;
}
*pzs = \&z_value;
*pot_zscore = \&z_value;
*zscore = \&z_value;

=head2 p_value, test, pot_test, ptt

 $p = $pot->p_value(state => 'x'); # using loaded data and default args
 $p = $pot->p_value(ccorr => 0|1, tails => 1|2, state => 'x'); # normal-approximation based on loaded data
 $p = $pot->p_value(data => $aref, ccorr => 1, tails => 2, state => 'x'); #  using given data (by-passing load and read)

Test the currently loaded data for significance of the vale of pot. Returns the zscore from test of pot deviation, or, called wanting an array, the z-value with its I<p>-value for the tails (1 or 2) given. 

=cut

sub p_value {
   return (z_value(@_))[1];
}
*test = \&p_value;
*pot_test = \&p_value;
*ptt = \&p_value;


=head2 stats_hash

 $href = $pot->stats_hash(values => {observed => 1, expected => 1, variance => 1, z_value => 1, p_value => 1}, prob => .5, ccorr => 1);

Returns a hashref for the counts and stats as specified by hashref in its "values" argument, and with any options for calculating them. See L<Statistics::Sequences/stats_hash> for details.

=head2 dump

 $pot->dump(values => { observed => 1, variance => 1, p_value => 1}, exact => 1, flag => 1,  precision_s => 3); # among other options

Print Pot-test results to STDOUT. See L<dump|Statistics::Sequences/dump> in the Statistics::Sequences manpage for details.

=cut

sub dump {
    my $self = shift;
    my $args = ref $_[0] ? $_[0] : {@_};
    $args->{'stat'} = 'pot';
    $args->{'stat'} .= " ($args->{'state'})" if defined $args->{'state'};
    $self->SUPER::dump($args);
    #No. of bunches of state '$self->{'state'}' = " . $self->{'bunches'}->count() . 
    #    ', with a mean length of '. sprintf('%.2f', $self->{'bunches'}->mean()) .
    #    ', and a mean spacing of '. sprintf('%.2f', $self->{'spaces'}->mean()) ." between each bunch.\n" if $self->{'bunches'};
    #    $args->{'title'} .=  ' (Calculated with a range of ' . sprintf('%.2f', $self->{'range'}) . " over a scale of $self->{'scale'})";   
}

sub _set_terms {
    my $self = shift;
    my $args = ref $_[0] ? $_[0] : {@_};
    my $data = ref $args->{'data'} ? $args->{'data'} : $self->read($args);
    my ($m, $n, $r, $scale, $state, $indices, $bunches, $spaces) = ();
    $m = scalar(@{$data});
    #$m = defined $args->{'trials'} ? $args->{'trials'} : scalar(@{$data});
    #if (ref $args->{'indices'}) { # defunct by-pass from having data
    #    $n = scalar @{$args->{'indices'}};
    #    $indices = $args->{'indices'};
    #}
    #else {
        $state = defined $args->{'state'} ? $args->{'state'} : croak __PACKAGE__, '::test A state for pot-testing is needed';
        ($indices, $bunches, $spaces) = _state_indices($data, $state, $m);
        $n = scalar(@{$indices}); 
    #}
    $scale = (!$args->{'scale'} or $args->{'scale'} < 1) ? 1 : $args->{'scale'}; # assume scale = 1 if not specified or invalid
    $r = _range($n, $m, $scale);
    return ($m, $n, $r, $scale, $state, $indices, $bunches, $spaces);
}

sub _range { # init range parameter
    my ($n, $m, $scale) = @_;
    return exp(-$n / $m * $scale);
}

sub _state_indices {# Init an array holding the indices at which the state appears in the given data:
    my ($data, $state, $m) = @_;
    # Meanwhile, build arrays of bunch and space frequencies, should this be requested:
    my ($i, $j, $k, @indices, @bunches, @spaces) = (0, 0, 0);
    for ($i = 0; $i < $m; $i++) {
        # Allow for matching numerical or string values:
        if ($data->[$i] eq $state) {
             $k++ if $spaces[$k];
             $j++ if ( scalar @indices ) and ( $indices[-1] != ($i - 1) );
             $bunches[$j]++;
             push @indices, $i;
        }
        else {
            $spaces[$k]++;
        }
    }
    return (\@indices, \@bunches, \@spaces);
}

1;

__END__

=head1 EXAMPLE

Using Pot as a test of bunching of a particular state within a collection of quasi-random events.

 use strict;
 use Statistics::Sequences::Pot;
 my ($i, @data) = ();
 # Init random integers ranging from 0 to 15:
 for ($i = 0; $i < 960; $i++) { $data[$i] = int(rand(16)); }
 # Assess degree of bunching within these data with respect to a randomly selected target state:
 my $state = int(rand(16));
 my $pot = Statistics::Sequences::Pot->new();
 $pot->load(\@data);
 my %args = (state => $state, values => {p_value => 1, observed => 1, expected => 1, stdev => 1});
 my $statsref = $pot->stats_hash(\%args);
 # Access the results of this analysis:
 print "The probability of obtaining as much bunching of $state as observed is $statsref->{'p_value'}.\n";
 print "The observed value of Pot was $statsref->{'observed'}, with expected value $statsref->{'expected'} ($statsref->{'stdev'}).\n";
 # or print the lot, and more, in English:
 $pot->dump(%args, precision_s => 3, precision_p => 7,);

=head1 REFERENCES

Schmidt, H. (2000). A proposed measure for psi-induced bunching of randomly spaced events. I<Journal of Parapsychology>, I<64,> 301-316.

=head1 SEE ALSO

L<http://www.fourmilab.ch/rpkp/> for Schmidt's many papers on the physical conceptualisation and properties of psi.

L<Statistics::Descriptive|Statistics::Descriptive> : The present module adds data to "Full" objects of this package in order to access descriptives re bunches and spaces.

L<Statistics::Frequency|Statistics::Frequency> : the C<proportional_frequency()> method in this module could be informative when working with data of the kind used here.

=head1 BUGS/LIMITATIONS

No computational bugs as yet identfied. Hopefully this will change, given time.

Limitations of the code, perhaps, concern the non-unique storage of data arrays (compared to, say, C<Statistics::DependantTTest>, but see C<Statistics::TTest>). This would require a unique name for each array of data, and explicit reference to one or another array with each L<test|test> (when, perhaps, you'd have only one data-set, after all). In any case, the data are accepted as array references.

=head1 REVISION HISTORY

See CHANGES in installation dist for revisions.

=head1 AUTHOR/LICENSE

=over 4

=item Copyright (c) 2006-2013 Roderick Garton

rgarton AT cpan DOT org

This program is free software. It may be used, redistributed and/or modified under the same terms as Perl-5.6.1 (or later) (see L<http://www.perl.com/perl/misc/Artistic.html>).

=item Disclaimer

To the maximum extent permitted by applicable law, the author of this module disclaims all warranties, either express or implied, including but not limited to implied warranties of merchantability and fitness for a particular purpose, with regard to the software and the accompanying documentation.

=back

=head1 END

This ends documentation of a Perl implementation of Helmut Schmidt's test of pot (potential energy) of occurrence of a state among others in a categorical sequence.

=cut

package Statistics::Sequences::Joins;
use 5.008008;
use strict;
use warnings FATAL => 'all';
use Carp qw(carp croak);
use base qw(Statistics::Sequences);
use List::AllUtils qw(true uniq);
use Statistics::Zed 0.10;
$Statistics::Sequences::Joins::VERSION = '0.20';

=pod

=head1 NAME

Statistics::Sequences::Joins - The Joins Test: Wishart-Hirschfeld statistics for frequency of alternations in a dichotomous sequence

=head1 VERSION

This is documentation for B<Version 0.20> of Statistics::Sequences::Joins.

=head1 SYNOPSIS

 use Statistics::Sequences::Joins 0.20;
 my $joins = Statistics::Sequences::Joins->new();
 $joins->load([1, 0, 0, 0, 1, 1, 0, 1, 1, 1]); # bi-valued sequence
 my $val = $joins->observed(); # or give "data => AREF" to stat methods
 $val = $joins->expected(trials => 10, prob => .5); # sufficient, independent of data
 $val = $joins->variance(trials => 10, prob => .5); # same
 $val = $joins->z_value(tails => 1, ccorr => 1); # use loaded data
 my ($z, $p) = $joins->z_value(tails => 1, ccorr => 1); # as above, but wantarray for z- and p-value
 $p = $joins->p_value(tails => 1); # using loaded data
 $val = $joins->z_value(trials => 10, observed => 4, tails => 1, ccorr => 1); # sufficicent
 my $href = $joins->stats_hash(values => {observed => 1, p_value => 1}); # or other methods as attribs in the hashref
 # print values to STDOUT:
 $joins->dump(values => {observed => 1, expected => 1, p_value => 1}, format => 'line', flag => 1, precision_s => 3, precision_p => 7);

=head1 DESCRIPTION

A sequence of dichotomous, binary-valued, two-element events consists of zero or more alternations (or "joins") of those events. For example, joins are marked out with asterisks for the following sequence:

 0 0 1 0 0 0 1 0 0 0 0 1 1 0 0 0 1 1 1 1 0 0
    * *     * *       *   *     *       *

So there's a join (of 0 and 1) at indices 1 and 2 (from zero), then immediately another join (of 1 and 0) at indices 2 and 3, and then another join at 5 and 6 ... for a total joincount of eight.

This module provides methods to calculate and return this observed joincount, and also the expected joincount and its variance for the number of trials and probability of each event, following the limiting form of the probability distribution of the number of joins in a binary-valued sequence given by Wishart and Hirschfeld (1936). This assumes that the probability that an event can take one or another value at each trial is constant over all trials. The concept might seem similar to L<runs|Statistics::Sequences::Runs> but runs are counted for each continuous segment between alternations, while it is blind to the length of these repetitions and even to event-probabilities. 

=head1 METHODS

Methods include those described in L<Statistics::Sequences>, and have the same form as those in its other sub-modules, but naturally have specific operations as follows.

=head2 new

 $joins = Statistics::Sequences::Joins->new();

Returns a new Joins object. Expects/accepts no arguments but the classname.

=head2 load

 $joins->load(@data); # anonymously
 $joins->load(\@data);
 $joins->load('sample1' => \@data); # labelled whatever

Loads data anonymously or by name - see L<load|Statistics::Data/load, load_data> in the Statistics::Data manpage for details on the various ways data can be loaded and then retrieved (more than shown here). Here, the data are checked to ensure that they contain no more than two unique elements--if not, a C<carp> and return of 0 occurs. Every load unloads all previous loads and any additions to them.

Alternatively, skip this action; data don't have to be pre-loaded to use the stats methods here (see below).

=cut

sub load {
    my $self = shift;
    $self->SUPER::load(@_);
    my $data = $self->access( index => -1 );
    my @uniq = uniq( @{$data} );
    if ( scalar @uniq > 2 ) {
        carp __PACKAGE__, ' More than two elements were found in the data: '
          . join( ' ', @uniq );
        return 0;
    }
    else {
        return 1;
    }
}

=head2 add, access, unload

See L<Statistics::Data> for these additional operations on data that have been loaded. 

=head2 observed

 $count = $joins->observed(); # assumes data have already been loaded
 $count = $joins->observed(data => [1, 0, 0, 0, 1, 0, 0, 1, 0, 1, 1]);

Returns the number of joins (or alternations) in a sequence - i.e., when, from the second trial onwards, the event on trial I<i> doesn't equal the event on trial I<i> - 1. For example, the following sequence adds up to 7 joins:

 Sequence:  1 0 0 0 1 0 0 1 0 1 1 0 
 JoinCount: 0 1 1 1 2 3 3 4 5 6 6 7

Formally, for a sequence I<A> = {I<a>_I<i>} indexed from zero,

=for html <table cellpadding="0" cellspacing="0"><tr><td>&nbsp;&nbsp;</td><td valign="middle"><i>J</i> =&nbsp;</td><td valign="middle"><table cellpadding="0" cellspacing="0"><tr><td align="center"><sub><i>N</i>&ndash;1</sub></td></tr><tr><td align="center">&Sigma;</td></tr><tr><td align="center"><sup><i>i</i>=1</sup></td></tr></table></td><td valign="middle" style="font-size:large;">&nbsp;}&nbsp;</td><td valign="middle"><table cellpadding="0" cellspacing="0"><tr><td align="left">0,&nbsp;</td><td><i>a</i><sub><i>i</i></sub> =&nbsp;<i>a</i><sub><i>i</i>&ndash;1</sub></td></tr><tr><td align="left">1,&nbsp;</td><td>otherwise</td></tr></table></td></tr></table>

The sequence to test can have been already L<load|Statistics::Sequences::Joins/load>ed, or it can be sent directly to this method, keyed as B<data>. If no data are found by either of these ways, a C<croak> is heard.

=cut

sub observed {
    my $self = shift;
    my $args = ref $_[0] ? shift : {@_};
    my $data = ref $args->{'data'} ? $args->{'data'} : $self->access($args);
    croak 'No sequence of data to calculate joincout'
      if not ref $data
      or not scalar @{$data};
    my $sum = 0;
    for my $i ( 1 .. scalar @{$data} - 1 ) {
        $sum++
          if $data->[$i] ne $data->[ $i - 1 ]
          ;    # increment count if event is not same as last
    }
    return $sum;
}
*jco = \&observed;

=head2 expected

 $val = $joins->expected(); # assumes data already loaded, uses default prob value (.5)
 $val = $joins->expected(data => [1, 0, 0, 0, 1, 0, 0, 1, 0, 1]); # count these data, use default prob value (.5)
 $val = $joins->expected(data => [1, 0, 0, 0, 1, 0, 0, 1, 0, 1], prob => .2); # count these data, use given prob value
 $val = $joins->expected(data => [1, 0, 0, 0, 1, 0, 0, 1, 0, 1], state => 1); # count off trial numbers and prob. of event
 $val = $joins->expected(prob => .2, trials => 10); # use this trial number and probability of one of the 2 events

Returns the expected number of joins between the two possible elements of the given data, or for data of the given attributes, from Wishart and Hirschfeld (1936, p. 228):

=for html <p>&nbsp;&nbsp;<i>E[J]</i> = 2(<i>N</i> &ndash; 1)<i>p</i><i>q</i>

where I<N> is the number of observations/trials, I<p> is the expected probability of the joined event taking on its observed value, and I<q> is (1 - I<p>), the expected probability of the joined event I<not> taking on its observed value.

The data to test can already have been L<load|Statistics::Sequences::Joins/load>ed, or you send it directly keyed as B<data>. The data are only needed to count off the number of trials, and the proportion of 1s (or other given state of the two), if the B<trials> and B<prob> attributes are not defined. If B<state> is defined, then B<prob> is worked out from the actual data (as long as there are some, or 1/2 is assumed). If B<state> is not defined, B<prob> takes the value you give to it, or, if it too is not defined, then 1/2 (assuming equiprobability of the two events). 

Counting up the observed number of joins needs some data to count through, but getting the expectation and variance for the joincount can just be fed with the number of B<trials>, and the B<prob>ability of one of the two events.

=cut 

sub expected {
    my $self = shift;
    my $args = ref $_[0] ? shift : {@_};
    my ( $n, $p ) = _get_N_and_p( $self, $args );
    return 2 * ( $n - 1 ) * $p * ( 1 - $p );
}
*jce = \&expected;

=head2 variance

 $val = $joins->variance(); # assume data already "loaded" for counting
 $val = $joins->variance(data => $aref); # use inplace array reference, will use default prob of 1/2
 $val = $joins->variance(data => [1, 0, 0, 0, 1, 0, 0, 1, 0, 1]); # count off trial numbers and prob. of event
 $val = $joins->variance(data => [1, 0, 0, 0, 1, 0, 0, 1, 0, 1], prob => prob); # specify the event prob (recommended)
 $val = $joins->variance(trials => number, prob => prob); # sufficient statistics

Returns the expected variance in the number of joins for the given data, as estimated in Wishart and Hirschfeld (1936, p. 232), with a correction for small I<N> (the second term) given by Burdick and Kelly (1977, p. 106, Eq. 20) that is trivial for very large I<N>:

=for html <p>&nbsp;&nbsp;<i>V[J]</i> = 4<i>N</i><i>p</i><i>q</i>(1 &ndash; 3<i>p</i><i>q</i>) &ndash; 2<i>p</i><i>q</i>(3 &ndash; 10<i>p</i><i>q</i>)

with variables defined as above for L<expected|Statistics::Sequences::Joins/expected>. The default operation applies the Burdick-Kelly correction; this can be dodged by specifying B<ncorr> => 0.

The data to test can already have been L<load|Statistics::Sequences::Joins/load>ed, or it is given directly, keyed as B<data>. The data are only needed to count off the number of trials, and estimate the expected probability of the joined event, if the B<trials> and B<prob> attributes aren't defined. If B<state> is defined, then B<prob> is worked out from the actual data (as long as there are some, or expect a C<croak>). If B<state> is not defined, B<prob> takes the given value or, if it too is not defined, then 1/2 (assuming equiprobability of the two events).

=cut

sub variance {
    my $self = shift;
    my $args = ref $_[0] ? shift : {@_};
    my ( $n, $p ) = _get_N_and_p( $self, $args );
    my $pq = $p * ( 1 - $p );
    my $var = 4 * $n * $pq * ( 1 - 3 * $pq );
    $var -= 2 * $pq * ( 3 - 10 * $pq )
      if not defined $args->{'ncorr'}
      or $args->{'ncorr'} == 1;
    return $var;
}
*jcv = \&variance;

=head2 obsdev

 $v = $joins->obsdev(); # use data already loaded - anonymously; or specify its "label" or "index" - see observed()
 $v = $joins->obsdev(data => [qw/blah bing blah blah blah/]); # use these data
 $v = $joing->obsdev(observed => NUM, trials => NUM, prop => PROB); # sufficient

Returns the observed deviation: the observed I<less> expected joincount for the loaded/given sequence (I<O> - I<E>). Alias: C<observed_deviation>. Alternatively, the observed value might be given (as B<observed> => NUM), and so the method only has to get the expected value (as specified in L<expected|Statistics::Sequences::Joins/expected>).

=cut

sub obsdev {
    my $self = shift;
    my $args = ref $_[0] ? shift : {@_};
    my $obs =
      defined $args->{'observed'}
      ? $args->{'observed'}
      : $self->observed($args);
    return $obs - $self->expected($args);
}
*observed_deviation = \&obsdev;

=head2 stdev

 $v = $joins->stdev(); # use data already loaded - anonymously; or specify its "label" or "index" - see observed()
 $v = $joins->stdev(data => [qw/blah bing blah blah blah/]);

Returns the standard deviation (square-root of the variance). Alias: C<stantard_deviation>.

=cut

sub stdev {
    return sqrt( variance(@_) );
}
*standard_deviation = \&stdev;

=head2 z_value

 $val = $joins->z_value(); # data already loaded, use default windows and prob
 $val = $joins->z_value(data => $aref, prob => .5, ccorr => 1, ncorr => 1);
 ($zvalue, $pvalue) =  $joins->z_value(data => $aref, prob => .5, ccorr => 1, tails => 2); # same but wanting an array, get the p-value too

Returns the I<Z>-score from a test of joincount deviation, taking the joincount L<expected|Statistics::Sequences::Joins/expected> away from that L<observed|Statistics::Sequences::Joins/observed> and dividing by the root expected joincount L<variance|Statistics::Sequences::Joins/variance>, by default with a continuity correction (B<ccorr>) to expectation. Called in list context, returns the I<Z>-score with its I<p>-value for the B<tails> (1 or 2) specified (2 by default).

The data to test can already have been L<load|Statistics::Sequences::Joins/load>ed, or it is given directly, keyed as B<data>.

Other options are B<precision_s> (for the z_value) and B<precision_p> (for the p_value), and B<ncorr> for the (default) correction for small I<N>.

=cut

sub z_value {
    my $self = shift;
    my $args = ref $_[0] ? shift : {@_};
    my $obs =
      defined $args->{'observed'}
      ? $args->{'observed'}
      : $self->observed($args);
    my $ccorr = defined $args->{'ccorr'} ? $args->{'ccorr'} : 1;
    my $tails = $args->{'tails'} || 2;
    my $zed = Statistics::Zed->new();
    my ( $zval, $pval ) = $zed->zscore(
        observed    => $obs,
        expected    => $self->expected($args),
        variance    => $self->variance($args),
        ccorr       => $ccorr,
        tails       => $tails,
        precision_s => $args->{'precision_s'},
        precision_p => $args->{'precision_p'},
    );
    return wantarray ? ( $zval, $pval ) : $zval;
}
*jzs              = \&z_value;
*joincount_zscore = \&z_value;
*zscore           = \&z_value;

=head2 p_value

 $p = $joins->p_value(); # using loaded data and default args
 $p = $joins->p_value(ccorr => 0|1, tails => 1|2); # as above, with options
 $p = $joins->p_value(data => [1, 0, 1, 1, 0]); #  directly giving data (by-passing load and read)
 $p = $joins->p_value(trials => NUM, observed => NUM, prob => PROB); # without using data

Returns the normal probability value for I<Z>-value given by taking the joincount L<expected|Statistics::Sequences::Joins/expected> away from that L<observed|Statistics::Sequences::Joins/observed> and dividing by the root expected joincount L<variance|Statistics::Sequences::Joins/variance>, by default with a continuity correction (B<ccorr>) to expectation and with B<tails> => 2. Data are those already L<load|Statistics::Sequences::Joins/load>ed, or as directly keyed as B<data>. In the absence of "data", the sufficient statistics of B<trials> and B<prob> are required (or, by default, B<prob> => 1/2 is used).

=cut

sub p_value {
    return ( z_value(@_) )[1];
}
*test       = \&p_value;
*joins_test = \&p_value;
*jct        = \&p_value;

=head2 stats_hash

 $href = $joins->stats_hash(values => {observed => 1, expected => 1, variance => 1, z_value => 1, p_value => 1}, prob => .5, ccorr => 1);

Returns a hashref for the counts and stats as specified in its "values" argument, and with any options for calculating them (e.g., exact for p_value). See L<Statistics::Sequences/stats_hash> for details. If calling via a "joins" object, the option "stat => 'joins'" is not needed (unlike when using the parent "sequences" object).

=head2 dump

 $joins->dump(values => { observed => 1, variance => 1, p_value => 1}, exact => 1, flag => 1,  precision_s => 3); # among other options

Print Joins-test results to STDOUT. See L<dump|Statistics::Sequences/dump> in the Statistics::Sequences manpage for details.

=cut

sub dump {
    my $self = shift;
    my $args = ref $_[0] ? $_[0] : {@_};
    $args->{'stat'} = 'joins';
    $self->SUPER::dump($args);
    return;
}

# returns two vars: (1) number of elements in the given "data" (sequence), and (2) relative frequency of a given state in the data
sub _get_N_and_p {
    my ( $self, $args, $n, $data ) = @_;
    if ( defined $args->{'trials'} ) {
        $n = $args->{'trials'};
    }
    else {
        $data = ref $args->{'data'} ? $args->{'data'} : $self->access($args);
        $n = scalar @{$data};
    }
    my $p =
      defined $args->{'prob'} ? $args->{'prob'}
      : ( defined $args->{'state'} and defined $data )
      ? _count_pfrq( $data, $args->{'state'} )
      : .5;
    return ( $n, $p );
}

sub _count_pfrq {
    my ( $aref, $state, $count ) = @_;
    return .5 if not ref $aref or not scalar @{$aref};
    $count++ if true { $_ eq $state } @{$aref};
    return $count / scalar @{$aref};
}

1;

__END__

=head1 EXAMPLE

=head2 Seating at the diner

This is the data from Swed and Eisenhart (1943) also given as an example for the L<Runs test|Statistics::Sequences::Runs/EXAMPLE>, L<Vnomes (serial) test|Statistics::Sequences::Vnomes/EXAMPLE> and L<Turns test|Statistics::Sequences::Turns/EXAMPLE>. It lists the occupied (O) and empty (E) seats in a row at a lunch counter. Have people taken up their seats on a random basis - or do they show some social phobia (more sparsely seated than "chance"), or are they trying to pick up (more compactly seated than "chance")?

 use Statistics::Sequences::Joins;
 my $joins = Statistics::Sequences::Joins->new();
 $joins->load([qw/E O E E O E E E O E E E O E O E/]); # as per Statistics::Data
 $joins->dump(
    format => 'labline',
    flag => 1,
    precision_s => 3,
    precision_p => 3,
    verbose => 1,
 );

This prints: 
 
 Joins: observed = 10.000, p_value = 0.302

So, the observed number of joins in the seating arrangements did not differ from that expected within the bounds of chance, at the .05 level.This test is, then, more conservative for these data than the the Runs, Turns, and Vnomes (trinomes) tests, which showed marginal significance. Checking the number of joins expected ( = 7.5) suggests only a small and inconsistent tendency for people to take their seats apart from each other.

=head2 Score fluctuation

Rhine et al. (1943, App. 8, p. 381) describe an application of the Wishart-Hirschfeld test for testing the consistency of a sequence of values about a criterion value. Specifically, they test for fluctuation of a set of scores derived from runs of a guessing task with a constant probability of success. In their example, there are 25 trials-per-run, each run with a mean chance expectation (MCE) of 5. To test if the scores deviate about MCE more or less often than expected by chance, they count the joins as occurring when two consecutive scores fall below and then above, or above and then below, the MCE. So, with a bar in the following sequence of 15 run-scores, there are 4 joins: 78656|455012|6|45|8. The test can be made by transforming the data dichotomously (see L<Statistics::Data::Dichotomize>). The Joins test so becomes something akin to Kendall's L<Turns test|Statistics::Sequences::Turns> although that test is sensitive to trial-by-trial fluctuations, i.e., about neighbouring values in the sequence, rather than, as with this application of the Joins test, to fluctuations of each and every score about a criterion value (that might not necessarily even appear in the sequence).

=head1 REFERENCES

Burdick, D. S., & Kelly, E. F. (1977). Statistical methods in parapsychological research. In B. B. Wolman (Ed.), I<Handbook of parapsychology> (pp. 81-130). New York, NY, US: Van Nostrand Reinhold.

Pratt, J. G., Rhine, J. B., Smith, B. M., Stuart, C. E., & Greenwood, J. A. (1940). I<Extra-sensory perception after sixty years>. New York, NY, US: Henry Holt.

Wishart, J. & Hirschfeld, H. O. (1936). A theorem concerning the distribution of joins between line segments. I<Journal of the London Mathematical Society>, I<11>, 227-235.  doi:L<10.1112/jlms/s1-11.3.227|http://dx.doi.org/10.1112/jlms/s1-11.3.227>

=head1 SEE ALSO

L<Statistics::Sequences::Runs|Statistics::Sequences::Runs> : An analogous test.

L<Statistics::Sequences::Pot|Statistics::Sequences::Pot> : Another, more recent test of sequential structure.

L<Statistics::Data::Dichotomize> for transforming numerical or categorical non-dichotomous data into a dichotomous, two-element sequence.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::Sequences::Joins

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-Sequences-Joins-0.20>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Statistics-Sequences-Joins-0.20>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Statistics-Sequences-Joins-0.20>

=item * Search CPAN

L<http://search.cpan.org/dist/Statistics-Sequences-Joins-0.20/>

=back

=head1 AUTHOR

Roderick Garton, C<< <rgarton at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

=over 4

=item Copyright (c) 2006-2016 Roderick Garton

This program is free software. It may be used, redistributed and/or modified under the same terms as Perl-5.6.1 (or later) (see L<http://www.perl.com/perl/misc/Artistic.html>).

=item Disclaimer

To the maximum extent permitted by applicable law, the author of this module disclaims all warranties, either express or implied, including but not limited to implied warranties of merchantability and fitness for a particular purpose, with regard to the software and the accompanying documentation.

=back

=cut

# end of Statistics::Sequences::Joins


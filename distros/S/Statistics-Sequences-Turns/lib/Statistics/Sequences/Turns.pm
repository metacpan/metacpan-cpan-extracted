package Statistics::Sequences::Turns;
use 5.008008;
use strict;
use warnings;
use Carp 'croak';
use base qw(Statistics::Sequences);
$Statistics::Sequences::Turns::VERSION = '0.13';
use Statistics::Zed 0.10;

=pod

=head1 NAME

Statistics::Sequences::Turns - Kendall's turning-points test - of peaks and troughs in a numerical sequence

=head1 VERSION

This is documentation for B<Version 0.13> of Statistics::Sequences::Turns.

=head1 SYNOPSIS

 use strict;
 use Statistics::Sequences::Turns 0.13;
 my $turns = Statistics::Sequences::Turns->new();
 $turns->load([2, 0, 8.5, 5, 3, 5.01, 2, 2, 3]); # numbers; or give as "data => $aref" with each stat call
 my $val = $turns->observed(); # or descriptive methods: expected(), variance(), obsdev() and stdev()
 $val = $turns->z_value(); # # or in list context get both z- and p-value
 $val = $turns->p_value(); # as above, assume data are loaded
 my $href = $turns->stats_hash(values => [qw/observed p_value/], ccorr => 1); # incl. any other stat-method
 $turns->dump(values => [qw/observed expected p_value/], ccorr => 1, flag => 1, precision_s => 3, precision_p => 7);
 # prints: observed = 11.000, expected = 10.900, p_value = 0.5700167

=head1 DESCRIPTION

Implements Kendall's (1973) "turning point test" of sudden changes as peaks and troughs in the values of a numerical sequence. It is sometimes described as a test of "cyclicity", and often used as a test of randomness. Kendall (1973) introduced this as a test of ups and downs relative to linear progressions in a sequence (ahead of describing tests based on autocorrelation and Fourier analysis).

Specifically, for a sequence of numerical data (interval or ordinal) of size I<N>, a count of turns is incremented if the value on trial I<i>, for all I<i> greater than zero and less than I<N>, is, with respect to its immediate neighbours (the values on I<i> - 1 and I<i> + 1), greater than both neighbours (a peak) or less than both neighbours (a trough). The difference of this observed number from the mean expected number of turns for a randomly generated sequence, taken as a unit of the standard deviation, gives a I<Z>-score for assessing the "randomness" of the sequence, i.e., the absence of a factor systematically affecting the frequency of peaks/troughs, given that, for turns, there is "a fairly rapid tendency of the distribution to normality" (Kendall 1973, p. 24).

With these local fluctuations tested regardless of their spacing and magnitude, the test does not indicate if the changes actually cycle between highs and lows, if they are more or less balanced in magnitude, or if any cycling is periodic; only if oscillation in general is more common than linear progression. 

=head1 METHODS

=head2 new

 $turns = Statistics::Sequences::Turns->new();

Returns a new Turns object. Expects/accepts no arguments but the classname.

=head2 load

 $turns->load(@data);
 $turns->load(\@data);
 $turns->load('foodat' => \@data); # labelled whatever

Loads data anonymously or by name - see L<load|Statistics::Data/load, load_data> in the Statistics::Data manpage for details on the various ways data can be loaded and then retrieved (more than shown here). Data must be numerical (ordinal, interval type). All elements must be numerical of the method croaks.

=cut

sub load {
    my $self = shift;
    $self->SUPER::load(@_);
    croak __PACKAGE__, '::load All data must be numerical for turns statistics'
      if !$self->all_numeric( $self->access( index => -1 ) );
    return 1;
}

=head2 add, read, unload

See L<Statistics::Data> for these additional operations on data that have been loaded.

=head2 observed

 $v = $turns->observed(); # use anonymously loaded data
 $v = $turns->observed(name => 'mysequence'); # ... or by "name" given on loading
 $v = $turns->observed(data => \@data); # ... or just give the data now

Returns observed number of turns. This is the number of peaks and troughs, starting the count from index 1 of the sequence (a flat array), checking if both its immediate left/right (or past/future) neighbours are lesser than it (a peak) or greater than it (a trough). Wherever the values in successive indices in the sequence are equal, they are treated as a single observation/datum - so the following:

 0 0 1 1 0 1 1 1 0 1

is counted up for turns as

 0 1 0 1 0 1
   * * * *

This shows four turns - two peaks (0 1 0) and two troughs (1 0 1).

Returns 0 if the given list of is empty, or the number of its elements is less than 3.

=cut

sub observed {
    my $self   = shift;
    my $args   = ref $_[0] ? shift : {@_};
    my $data   = _set_data( $self, $args );
    my $trials = scalar @{$data};
    return 0 if not $trials or $trials < 3;
    my ( $count, $i ) = (0);
    for ( $i = 1 ; $i < $trials - 1 ; $i++ ) {
        if (   ( $data->[ $i - 1 ] > $data->[$i] )
            && ( $data->[ $i + 1 ] > $data->[$i] ) )
        {    # trough at $i
            $count++;
        }
        elsif (( $data->[ $i - 1 ] < $data->[$i] )
            && ( $data->[ $i + 1 ] < $data->[$i] ) )
        {    # peak at $i
            $count++;
        }
    }
    return $count;
}

=head2 expected

 $v = $turns->expected(); # use loaded data; or specify by "name"
 $v = $turns->expected(data => \@data); # use these data
 $v = $turns->expected(trials => POS_INT); # don't use actual data; calculate from this number of trials

Returns the expected number of turns, which is set by I<N> the number of trials/observations/sample-size ...:

=for html <p>&nbsp;&nbsp;<i>E[T]</i> = 2 / 3 (<i>N</i> &ndash; 2)

or, equivalently (in some sources),

=for html <p>&nbsp;&nbsp;<i>E[T]</i> = ( 2<i>N</i> &ndash; 4 ) / 3

=cut

sub expected {
    my $self = shift;
    my $args = ref $_[0] ? shift : {@_};
    my $trials =
      defined $args->{'trials'}
      ? $args->{'trials'}
      : scalar( @{ _set_data( $self, $args ) } );
    return 2 / 3 * ( $trials - 2 );

    #return (2 * $trials - 4) / 3;
}

=head2 variance

 $v = $turns->variance(); # use loaded data; or specify by "name"
 $v = $turns->variance(data => \@data); # use these data
 $v = $turns->variance(trials => POS_INT); # don't use actual data; calculate from this number of trials

Returns the expected variance in the number of turns for the given length of data I<N>.

=for html <p>&nbsp;&nbsp;<i>V[T]</i> = (16<i>N</i> &ndash; 29 ) / 90

=cut

sub variance {
    my $self = shift;
    my $args = ref $_[0] ? shift : {@_};
    my $trials =
      defined $args->{'trials'}
      ? $args->{'trials'}
      : scalar( @{ _set_data( $self, $args ) } );
    return ( 16 * $trials - 29 ) / 90;
}

=head2 obsdev

 $v = $turns->obsdev(); # use data already loaded - anonymously; or specify its "name"
 $v = $turns->obsdev(data => \@data); # use these data

Returns the observed deviation from expectation for the loaded/given sequence: observed I<less> expected turn-count (I<O> - I<E>). Alias of C<observed_deviation> is supported.

=cut

sub obsdev {
    return observed(@_) - expected(@_);
}
*observed_deviation = \&obsdev;

=head2 stdev

 $v = $turns->stdev(); # use data already loaded - anonymously; or specify its "name"
 $v = $turns->stdev(data => \@data);

Returns square-root of the variance. Aliases C<standard_deviation> and C<stddev> (common in other Statistics modules) are supported.

=cut

sub stdev {
    return sqrt variance(@_);
}
*standard_deviation = \&stdev;
*stddev             = \&stdev;

=head2 z_value

 $z = $turns->z_value(ccorr => 1); # use data already loaded - anonymously; or specify its "name"
 $z = $turns->z_value(data => $aref, ccorr => BOOL);
 ($z, $p) = $turns->z_value(data => $aref, ccorr => BOOL, tails => 2); # same but wanting an array, get the p-value too

Returns the deviation ratio, or I<Z>-score, taking the turncount expected from that observed and dividing by the root variance, by default with a continuity correction in the numerator. Called in list context, returns the I<Z>-score with its normal distribution, two-tailed I<p>-value.

The data to test can already have been L<load|load>ed, or sent directly as an aref keyed as B<data>.

Optional named arguments B<tails> (1 or 2), B<ccorr> (Boolean for the continuity-correction), B<precision_s> (for the statistic, i.e., I<Z>-score) and B<precision_p> (for the I<p>-value).

The method can all be called with "sufficient" data: giving, instead of actual data, the B<observed> number of turns, and the number of B<trials>, the latter being sufficient to compute the expected number of turns and its variance.

Alias C<z_score> is supported.

=cut

sub z_value {
    my $self = shift;
    my $args = ref $_[0] ? shift : {@_};
    my $data = _set_data( $self, $args );
    my $trials =
      defined $args->{'trials'} ? $args->{'trials'} : scalar @{$data};
    my $zed = Statistics::Zed->new();
    my ( $zval, $pval ) = $zed->zscore(
        observed => defined $args->{'observed'}
        ? $args->{'observed'}
        : $self->observed($args),
        expected => $self->expected( trials => $trials ),
        variance => $self->variance( trials => $trials ),
        ccorr => defined $args->{'ccorr'} ? $args->{'ccorr'} : 1,
        tails => $args->{'tails'} || 2,
        precision_s => $args->{'precision_s'},
        precision_p => $args->{'precision_p'},
    );
    return wantarray ? ( $zval, $pval ) : $zval;
}
*z_score = \&z_value;

=head2 p_value

 $p = $turns->p_value(); # using loaded data and default args
 $p = $turns->p_value(ccorr => BOOL, tails => 1|2); # normal-approximation based on loaded data
 $p = $turns->p_value(data => $aref, ccorr => BOOL, tails => 2); #  using given data

Returns the normal distribution I<p>-value for the deviation ratio (I<Z>-score) of the observed number of turns, 2-tailed and continuity-correct by default (or set B<tails> => 1 and B<ccorr> => 0, respectively). Other arguments are as for L<z_value|Statistics::Sequences::Turns/z_value>.

=cut

sub p_value {
    return ( z_value(@_) )[1];
}

=head2 stats_hash

 $href = $turns->stats_hash(values => [qw/observed expected variance z_value p_value/], ccorr => 1);

Returns a hashref for the counts and stats as specified in its "values" argument, and with any options for calculating them. See L<stats_hash|Statistics::Sequences/stats_hash> in the Statistics::Sequences manpage for details/options. If calling via a "turns" object, the option "stat => 'turns'" is not needed (unlike when using the parent Statistics::Sequences object).

=head2 dump

 $turns->dump(flag => BOOL, verbose => BOOL, format =>  'table|labline|csv');

Print test results to STDOUT. See L<dump|Statistics::Sequences/dump> in the Statistics::Sequences manpage for details/options.

=cut

sub dump {
    my $self = shift;
    my $args = ref $_[0] ? $_[0] : {@_};
    $args->{'stat'} = 'turns';
    $self->SUPER::dump($args);
    return $self;
}

sub _set_data {    # Get data via Statistics::Date
        # Remove equivalent successors: e.g., strip 2nd 2 from (3, 2, 2, 7, 2):
    my $self = shift;
    my $args = ref $_[0] ? $_[0] : {@_};
    my $data = $self->access($args)
      ;    # have been already checked to be numerical if previously load()'ed
    ref $data or croak __PACKAGE__, '::Data for counting up turns are needed';
    my @data_u = ();
    for my $i ( 0 .. ( scalar @{$data} - 1 ) ) {
        push @data_u, $data->[$i]
          if not scalar @data_u
          or $data->[$i] != $data_u[-1];
    }
    return \@data_u;
}

__END__

=head1 EXAMPLE

=head2 Seating at the diner

This is the data from Swed and Eisenhart (1943) also given as an example for the L<Runs test|Statistics::Sequences::Runs/EXAMPLE>, L<Joins test|Statistics::Sequences::Joins/EXAMPLE> and L<Vnomes (serial) test|Statistics::Sequences::Vnomes/EXAMPLE>. It lists the occupied (O) and empty (E) seats in a row at a lunch counter.
Have people taken up their seats on a random basis - or do they show some social phobia (more sparsely seated than "chance"), or are they trying to pick up (more compactly seated than "chance")? What does Kendall's test of turns reveal?

 use Statistics::Sequences::Turns;
 my $turns = Statistics::Sequences::Turns->new();
 # change the nominal data from Swed & Eisenhart (1943) into numerical values:
 my @seating = map { $_ eq 'E' ? 1 : 0 } (qw/E O E E O E E E O E E E O E O E/); 
 $turns->load(\@seating); # as per Statistics::Data
 $turns->dump_vals(delim => q{,}); # via Statistics::Data - prints the 1s and 0s:
 # 1,0,1,1,0,1,1,1,0,1,1,1,0,1,0,1
 $turns->dump(
    format => 'labline',
    flag => 1,
    precision_s => 3,
    precision_p => 3,
    verbose => 1,
 );

This prints: 
 
 Turns: observed = 9.000, p_value = 0.050

So, the observed number of turns in the seating arrangements differed from that expected within the bounds of chance, at the .05 level. The Vnomes test for trinomes was similarly marginal (I<p> = .044), as was the result for Runs (I<p> = 0.055), while the Joins test was clearly non-significant (I<p> = .302). Checking the number of turns expected ( = 6) suggests, perhaps, a tendency for people to take their seats further away from each other (leave more unoccupied seats between them) than expected on the basis of chance.

=head1 DEPENDENCIES

L<Statistics::Sequences|Statistics::Sequences>

L<Statistics::Zed|Statistics::Zed>

=head1 REFERENCES

Kendall, M. G. (1973). I<Time-series>. London, UK: Griffin. L<ISBN 0852642202|http://www.worldcat.org/title/time-series/oclc/21154075&referer=brief_results>. [The test is described on pages 22-24 of the 1973 edition; in the Example 2.1 for this test, the expected number of turns should be calculated with the value 52 (i.e., with I<N> - 2), not the misprinted value of 54.]

=head1 SEE ALSO

L<Statistics::Sequences|Statistics::Sequences> for other tests of sequences, and for sharing data between these tests.

L<Statistics::Sequences::Joins|Statistics::Sequences::Joins> : another test of consecutive values in a sequence, examining alternations.

L<Statistics::Sequences::Pot|Statistics::Sequences::Pot> : another trend-type test, examining relatively spaced clustering of particular events.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::Sequences::Turns

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-Sequences-Turns-0.13>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Statistics-Sequences-Turns-0.13>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Statistics-Sequences-Turns-0.13>

=item * Search CPAN

L<http://search.cpan.org/dist/Statistics-Sequences-Turns-0.13/>

=back

=head1 AUTHOR/LICENSE

=over 4

=item Copyright (c) 2006-2017 Roderick Garton

rgarton AT cpan DOT org

This program is free software. It may be used, redistributed and/or modified under the same terms as Perl-5.6.1 (or later) (see L<http://www.perl.com/perl/misc/Artistic.html>).

=back

=head1 DISCLAIMER

To the maximum extent permitted by applicable law, the author of this module disclaims all warranties, either express or implied, including but not limited to implied warranties of merchantability and fitness for a particular purpose, with regard to the software and the accompanying documentation.

=cut

1;    # End of Statistics::Sequences::Turns


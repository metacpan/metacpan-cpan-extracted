package Statistics::Data::Dichotomize;
use strict;
use warnings FATAL => 'all';
use base qw(Statistics::Data);
use Carp qw(croak);
use Number::Misc qw(is_numeric);
use Statistics::Lite qw(mean median mode);

$Statistics::Data::Dichotomize::VERSION = '0.05';

=head1 NAME

Statistics::Data::Dichotomize - Dichotomize one or more numerical or categorical sequences into a single two-valued sequence

=head1 VERSION

This is documentation for B<Version 0.05> of Statistics-Data-Dichotomize.

=head1 SYNOPSIS

 use Statistics::Data::Dichotomize 0.05;
 my $ddat = Statistics::Data::Dichotomize->new();
 my $aref;
 
 $ddat->load(23, 24, 7, 55); # numerical data
 $aref = $ddat->cut(value => 'median'); # - or by precise value or function
 $aref = $ddat->swing(); # by successive rises and falls of value
 $aref = $ddat->shrink(rule => sub { return $_->[0] >= 20 ? : 1 : 0 }, winlen => 1); # like "cut" if winlen only 1
 $aref = $ddat->binate(oneis => 7); # returns (0, 0, 1, 0)

 # - alternatively, call any method giving data directly, without prior load():
 $aref = $ddat->cut(data => [23, 24, 7, 55], value => 20);
 $aref = $ddat->pool(data => [$aref1, $aref2]);

 # or by a multi-sequence load: - by named arefs:
 $ddat->load(foodat =>[qw/c b c a a/], bardat => [qw/b b b c a/]); # arbitrary names
 $aref = $ddat->binate(data => 'foodat', oneis => 'c',); # returns (1, 0, 1, 0, 0)

 # - or by anonymous arefs:
 $ddat->load([qw/c b c a a/], [qw/b b b c a/]); # categorical (stringy) data
 $aref = $ddat->match(); # returns [0, 1, 0, 0, 1]
 
=head1 DESCRIPTION

A module for transforming one or more sequences of numerical or categorical data (array/s of numbers or strings) into a single binary-valued sequence.

Several methods, more or less applicable to numerical and categorical sequences of data, are implemented. These have been (to date) largely derived from the statistical study of sequential effects (as in Swed & Eisenhart, 1943; Wolfowitz, 1943), particularly as applied within the behavioural sciences (as in Siegal, 1956), including parapsychology (as in Burdick & Kelly, 1977). They are particularly relevant for statistical description and analysis of data by the L<Statistics::Sequences|Statistics::Sequences> modules.

Each method returns a binary-valued sequence as a reference to an array of 1s and 0s -- by default. However, most methods support the argument B<set> that controls the binary values of which to construct the dichotomous sequence; otherwise, the binary values are intrinsically user-controlled. Where applicable, this argument should key a 2-element array, where the first element (index = 0) replaces what would, by default, be returned as 0, and the second element (index = 1) replaces what would, by default, be returned as 1. So the dichotomous sequence might be comprised of, say, the values -1 and 1, "s" and "f" (success and failure), or "female" and "male", etc., rather than 1s and 0s.

There are methods to dichotomise data for:

=over 4

=item 1. I<a single numerical sequence>

that can be either (a) dichotomized ("L<cut|Statistics::Data::Dichotomize/cut>") about a specified or function-returned value, or a central statistic (mean, median or mode), or (b) dichtomotized according to successive rises and falls in value ("L<swing|Statistics::Data::Dichotomize/swing>");

=item 2. I<two numerical sequences>

which can be collapsed ("L<pool|Statistics::Data::Dichotomize/pool>ed") into a single dichotomous sequence according to the rank order of their values;

=item 3. I<a single categorical sequence>

where one value is set to equal 1 and all others equal 0 ("L<binate|Statistics::Data::Dichotomize/binate>");

=item 4. I<two categorical sequences>

which can be collapsed into a single dichotomous sequence according to their pairwise "L<match|Statistics::Data::Dichotomize/match>"; and

=item 5. a I<single numerical or categorical sequence>

which can be dichotomized according to whether or not independent slices of the data meet a specified Boolean rule ("L<shrink|Statistics::Data::Dichotomize/shrink>").

=back

All arguments are given as an anonymous hash of key => value pairs, or as a reference to such a hash (not shown in examples).

=head1 SUBROUTINES/METHODS

=head2 new

Returns the class object for this module, inheriting all the methods of L<Statistics::Data|Statistics::Data>, which it uses as a L<base>.

=head2 load, add, access, unload

Methods for loading, updating and retrieving data are inherited from L<Statistics::Data|Statistics::Data>. See that manpage for details of these and other inherently supported methods.

=cut

=head2 Numerical data: Single sequence dichotomization

=head3 cut

 ($aref, $val) = $ddat->cut(data => \@data, value => \&Statistics::Lite::median); # cut the given data at is median, getting back median too
 $aref = $ddat->cut(value => 'median', equal => 'gt'); # cut the last previously loaded data at its median
 $aref = $ddat->cut(value => 23); # cut anonymously cached data at a specific value
 $aref = $ddat->cut(value => 'mean', data => 'blues'); # cut named data (previously loaded as such) at its mean (or whatever)
 $aref = $ddat->cut(value => CODE); # cut by a user-defined function returning a data-descriptive value
 $aref = $ddat->cut(value => 23, set => [-1, 1]); # cut as above, but not into 0s and 1s, but -1s and 1s

Returns a reference to an array of dichotomously transformed values of a given array of numbers by categorizing its values as to whether they're numerically higher or lower than a particular value, e.g., their median, mean, mode or some given number, or some other function that returns a single value. Called in list context, returns a reference to the transformed values, and then the cut-value itself.

So the following data, when cut over values greater than or equal to 5, yield the binary-valued sequence:

 @orig_data  = (4, 3, 3, 5, 3, 4, 5, 6, 3, 5, 3, 3, 6, 4, 4, 7, 6, 4, 7, 3);
 @cut_data = (0, 0, 0, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 1, 0);

The order of the original values is reflected in the returned "cut data", but their order is not taken into account in making up the dichotomy - in contrast to the L<swing|Statistics::Data::Dichotomize/swing> method.

I<Optional arguments>, as follow, specify what value or measure to cut by (default is the median), and how to handle ties with the cut-value (default is to skip them).

=over 4

=item value => 'mean|median|mode' - or a specific numerical value, or code reference

Specifies the value at which the data will be cut. This could be the mean, median or mode (as calculated by L<Statistics::Lite|Statistics::Lite>), or a numerical value within the range of the data, or some appropriate subroutine -- one that takes an array (not a reference to one) and returns a single value (presumably a descriptive of the values in the array). The default is the I<median>. The cut-value, as specified by B<value>, can be retrieved as the second element returned if calling for an array.

=item equal => 'I<gt>|I<lt>|I<rpt>|I<skip>'

Specifies how to cut the data if the cut-value (as specified by B<value>) is present in the data. The logic applied takes on the following conventions:

=over 8

=item B<equal =E<gt> 'gt'> [default]

All values I<greater than or equal to> the cut-value take on one code (by default, 1), and all values I<less than> the cut-value take on another (by default, 0). This is (by convention) the default operation, preventing a given sequence that is fully composed of the cut-value returning an empty-list. So, e.g., given the data (5, 5, 5), and specifying that the cut-value is 5, the list (1, 1, 1) is returned, just as if the given data were, say, (8, 5, 212). 

=item B<equal =E<gt> 'lt'>

All values I<less than or equal to> the cut-value take on one code (by default, 0), and all higher values take on another code (by default, 1). For the prior example, the given data (5, 5, 5) now becomes (0, 0, 0).

=item B<equal =E<gt> 'rpt'>

The dichotomous sequence takes on the value that was taken in the immediately prior "cut". So now, given the data (5, 5, 5), the list (1, 1, 1) would be returned--as the first value is given the value of 1 (following the default operation to treat values greater than or equal to the cut-value as 1), and all subsequent values take on the same value. But if the given data were (4, 5, 6, 5), or (-400, 5, 600, 5), the returned list is (0, 0, 1, 1). This value/operation was introduced in Version 0.05.

=item B<equal =E<gt> 'skip'|0>

Values equal to the cut-value are skipped. So if the cut-value appears as the first value, it is simply skipped (it takes on no value), and an empty list is returned.

=back

Note that the operational logic here is different, in its default operation, from that following the same argument in the C<swing>() method. There, logically, and by convention, the default = 0, i.e., to skip neigbouring values with zero difference. The default operation for equality described here, for the C<cut>() method, perhaps should match the latter (and might well, following usage, feedback) for sake of consistency, but it seems most appropriate for now (as since Version 0.00) to make the default operation within the C<cut>() method follow convention/expectation, i.e., by its own logic, rather than to exact cross-method consistency for its own sake. In practice, it is advisable to compare results for a test based on the dichotomous sequence from different criteria for equality. If all results of a test are equal, there is no problem; otherwise, the average of the results from different methods can be taken (see Siegal, 1956, pp. 143-144, in discussion of "ties" in dichotomizing data for the two-sample L<Runs test|Statistics::Sequences::Runs>.)

=item set

The optional argument B<set>, keying a two-element array, controls the binary-values to return; instead of the default set of 0s and 1s, the set might be, say, -1s and 1s, or "male" and "female". The first (index = 0) element in the set array replaces what, by default, would be returned as 0, and the second (index = 1) element in the set array replaces what, by default, would be returned as 1.

=back

=cut

sub cut {
    my ( $self, @args ) = @_;
    my $args = ref $args[0]        ? $args[0]        : {@args};
    my $dat  = ref $args->{'data'} ? $args->{'data'} : $self->access($args);
    croak __PACKAGE__,
      '::cut All data must be numeric for dichotomizing about a cut-value'
      if !$self->all_numeric($dat);
    $args->{'value'} = 'median' if !defined $args->{'value'};

    #$args->{'equal'} = 0 if !defined $args->{'equal'};    #- no default??
    $args->{'equal'} = 'gt' if !defined $args->{'equal'};
    my ( $val, @seqs ) = ();

    # Get a cut-value:
    if ( !is_numeric( $args->{'value'} ) ) {
        my $code = \&{ delete $args->{'value'} };
        $val = $code->( @{$dat} );
    }
    else {
        $val = $args->{'value'};
    }

  # Categorize by number of observations above, below or equal to the cut_value:
    push @seqs,
        $_ > $val                ? 1
      : $_ < $val                ? 0
      : $args->{'equal'} eq 'gt' ? 1
      : $args->{'equal'} eq 'lt' ? 0
      : $args->{'equal'} eq 'rpt' ? ( exists $seqs[-1] ? $seqs[-1] : 1 )
      :                             next foreach @{$dat};
    _set( \@seqs, $args->{'set'} );
    return wantarray ? ( \@seqs, $val ) : \@seqs;
}

=head3 swing

 $aref = $ddat->swing(data => [3, 4, 7, 6, 5, 1, 2, 3, 2]); # "swing" these data
 $aref = $ddat->swing(label => 'reds'); # name a pre-loaded dataset for "swinging"
 $aref = $ddat->swing(); # use the last-loaded dataset
 $aref = $ddat->swing(set => [qw/male female/]); # for any of the above, optionally specify the dichotomous values

Returns a reference to an array of dichotomously transformed values of a single sequence of numerical values according to their consecutive rises and falls. Each value is subtracted from its successor, and the result is replaced with a 1 if the difference represents an increase, or 0 if it represents a decrease. For example (from Wolfowitz, 1943, p. 283), the following numerical sequence produces the subsequent dichotomous sequence.

 @values = (qw/3 4 7 6 5 1 2 3 2/);
 @dichot =   (qw/1 1 0 0 0 1 1 0/);

Dichotomously, the data commence with an ascending run of length 2 (from 3 to 4, and from 4 to 7), followed by a descending run of length 3 (from 7 to 6, 6 to 5, and 5 to 1), followed by an ascent of length 2 (from 1 to 2, from 2 to 3), and so on. The number of resulting dichotomous observations is 1 less than the original sample-size (elements in the given array).

I<Optional arguments> are as follow.

=over 4

=item equal => 'I<gt>|I<lt>|I<rpt>|I<skip>'

The default result when the difference between two successive values is zero is to skip the observation, and move onto the next succession. Alternatively, specify B<equal =E<gt> 'rpt'> to repeat the result for the previous succession; skipping only a difference of zero should it occur as the first result. Or, a difference greater than or equal to zero is counted as an increase (B<equal =E<gt> 'gt'>), or a difference less than or equal to zero is counted as a decrease. For example, 

 @values =    (qw/3 3 7 6 5 2 2/);
 @dicho_skip = (qw/1 0 0 0/); # First and final results (of 3 - 3, and 2 - 2) are skipped
 @dicho_rpt  = (qw/1 0 0 0 0/); # First result (of 3 - 3) is skipped, and final result repeats the former
 @dicho_gt   =  (qw/1 1 0 0 0 1/); # Greater than or equal to zero is an increase
 @dicho_lt   =  (qw/0 1 0 0 0 0/); # Less than or equal to zero is a decrease

See description of the same argument in the L<cut method|Statistics::Data::Dichotomize/cut> for more details (but for which the default value is 'gt').

=item set

The optional argument B<set>, keying a two-element array, controls the binary-values to return; instead of the default set of 0s and 1s, the set might be, say, -1s and 1s, or "male" and "female". The first (zero-indexed) element in the set array replaces what, by default, would be returned as 0, and the second (index = 1) element in the set array replaces what, by default, would be returned as 1.<b></b>

=back

=cut

sub swing {
    my ( $self, @args ) = @_;
    my $args = ref $args[0]        ? $args[0]        : {@args};
    my $dat  = ref $args->{'data'} ? $args->{'data'} : $self->access($args);
    croak __PACKAGE__, '::swing All data must be numeric for dichotomizing'
      if !$self->all_numeric($dat);
    $args->{'equal'} = 0 if !defined $args->{'equal'};    #- no default??
    my ( $i, $res, @seqs ) = ();

    # Replace observations with the succession of rises and falls:
    for ( $i = 0 ; $i < ( scalar @{$dat} - 1 ) ; $i++ ) {
        $res = $dat->[ ( $i + 1 ) ] - $dat->[$i];
        if ( $res > 0 ) {
            push @seqs, 1;
        }
        elsif ( $res < 0 ) {
            push @seqs, 0;
        }
        else {
            for ( $args->{'equal'} ) {
                if (/^rpt/xsm) {
                    push @seqs, $seqs[-1] if scalar @seqs;
                }
                elsif (/^gt/xsm) {
                    push @seqs, 1;
                }
                elsif (/^lt/xsm) {
                    push @seqs, 0;
                }
                else {
                    next;
                }
            }
        }
    }
    _set( \@seqs, $args->{'set'} );
    return \@seqs;
}

=head2 Numerical data: Two sequence dichotomization

See also the methods for categorical data where it is ok to ignore any order and intervals in numerical data.

=head3 pool

 $aref = $ddat->pool(data => [$aref1, $aref2]); # give data directly to function
 $aref = $ddat->pool(data => [$ddat->access(index => 0), $ddat->access(index => 1)]); # after $ddat->load(\@aref1, $aref2);
 $aref = $ddat->pool(data => [$ddat->access(label => '1'), $ddat->access(label => '2')]); # after $ddat->load(1 => $aref1, 2 => $aref2);
 $aref = $ddat->pool(data => [$aref1, $aref2], set => [-1, 1]); # for any of the above, optionally specify the binary set

Returns a reference to an array of dichotomously transformed values of two sequences of I<numerical> data as a ranked pool, i.e., by pooling the data from each sequence according to the magnitude of their values at each trial, from lowest to heighest. Specifically, the values from both sequences are pooled and ordered from lowest to highest, and then dichotomized into runs according to the sequence from which neighbouring values come from. Another run occurs wherever there is a change in the source of the values. A non-random effect of, say, higher or lower values consistently coming from one sequence rather than another would be reflected in fewer runs than expected by chance.

This is typically used for a Wald-Walfowitz test of difference between two samples -- ranking by median; as per Siegal (1956), and Swed and Eisenhart (1943).

The I<optional argument> B<set>, keying a two-element array, controls the binary-values to return; instead of the default set of 0s and 1s, the set might be, say, -1s and 1s, or "male" and "female". The first (zero-indexed) element in the set array replaces what, by default, would be returned as 0, and the second (index = 1) element in the set array replaces what, by default, would be returned as 1.

=cut

sub pool {
    my ( $self, @args ) = @_;
    my $args = ref $args[0]        ? $args[0]        : {@args};
    my $dat  = ref $args->{'data'} ? $args->{'data'} : $self->access($args);
    $self->all_numeric($_) foreach @{$dat};
    my ( $dat1, $dat2 ) = @{$dat};
    my $sum = scalar @{$dat1} + scalar @{$dat2};
    my @dat =
      ( [ sort { $a <=> $b } @{$dat1} ], [ sort { $a <=> $b } @{$dat2} ] );

    my ( $i, $x, $y, @seqs ) = (0);
    while ( scalar(@seqs) < $sum ) {
        $x = $dat[0]->[0];
        $y = $dat[1]->[0];
        $i = defined $x && defined $y ? $x < $y ? 0 : 1 : defined $x ? 0 : 1;
        shift @{ $dat[$i] };
        push @seqs, $i;
    }
    _set( \@seqs, $args->{'set'} );
    return \@seqs;
}
## DEV: consider: List::AllUtils::pairwise:
# @x = pairwise { $a + $b } @a, @b;   # returns index-by-index sums

=head2 Categorical data: Single sequence dichotomization

=head3 binate

 $aref = $ddat->binate(oneis => 'E'); # optionally specify a state in the sequence to be set as "1"
 $aref = $ddat->binate(oneis => 'E', set => [qw/a b/]); # optionally specify that Es be transformed to 'b', other events as 'a'
 $aref = $ddat->binate(data => \@ari, oneis => 'E'); # same but using pre-loaded data

Returns a reference to an array of dichotomously transformed values of an array by setting the first element in the list to 1 (by default, or whatever is specified as B<oneis>) on all its occurrences in the array, and all other values in the array as zero. 

The I<optional argument> B<set>, keying a referenced array, specifies that, in fact, the first element (or what might be specified as B<oneis>) should be transformed into what is given as the index 1 element in this array, and that all other elements should be transformed into what is given as its index 0 element.

=cut

sub binate {
    my ( $self, @args ) = @_;
    my $args = ref $args[0]        ? $args[0]        : {@args};
    my $dat  = ref $args->{'data'} ? $args->{'data'} : $self->access($args);
    my $oneis =
      defined $args->{'oneis'}
      ? delete $args->{'oneis'}
      : $dat->[0];    # What value set to 1 and others to zero?
    my @seqs = map { $_ eq $oneis ? 1 : 0 } @{$dat};
    ;                 # replace observations with 1s and 0s
    _set( \@seqs, $args->{'set'} );
    return \@seqs;
}

=head2 Categorical data: Two-sequence dichotomization

=head3 match

 $aref = $ddat->match(data => [\@aref1, \@aref2], lag => signed integer, loop => 0|1); # with optional crosslag of the two sequences
 $aref = $ddat->match(data => [$ddat->access(index => 0), $ddat->access(index => 1)]); # after $ddat->load(\@aref1, \@aref2);
 $aref = $ddat->match(data => [$ddat->access(label => '1'), $ddat->access(label => '2')]); # after $ddat->load(1 => \@aref1, 2 => \@aref2);

Returns a reference to an array of dichotomously transformed values of two paired arrays according to the match between the elements at each of their indices. Where the data-values are equal at a certain index, they are represented with a 1; otherwise a 0 (by default, but see the B<set> argument). Numerical or stringy data can be equated. For example, the following two arrays would be reduced to the third, where a 1 indicates a match (i.e., the values are "indexically equal").

 @foo_dat = (qw/1 3 3 2 1 5 1 2 4/);
 @bar_dat = (qw/4 3 1 2 1 4 2 2 4/);
 @bin_dat = (qw/0 1 0 1 1 0 0 1 1/);

I<Optional arguments> are as follow.

=over 4

=item lag => I<integer> (where I<integer> < number of observations I<or> I<integer> > -1 (number of observations) ) 

Match the two data-sets by shifting the first named set ahead or behind the other data-set by B<lag> observations. The default is zero. For example, one data-set might be targets, and another responses to the targets:

 targets   =	cbbbdacdbd
 responses =	daadbadcce

Matched as a single sequence of hits (1) and misses (0) where B<lag> = B<0> yields (for the match on "a" in the 6th index of both arrays):

 0000010000

With B<lag> => 1, however, each response is associated with the target one ahead of the trial for which it was observed; i.e., each target is shifted to its +1 index. So the first element in the above responses (I<d>) would be associated with the second element of the targets (I<b>), and so on. Now, matching the two data-sets with a B<+1> lag gives two hits, of the 4th and 7th elements of the responses to the 5th and 8th elements of the targets, respectively:

 000100100

making 5 runs. With B<lag> => 0, there are 3 runs. Lag values can be negative, so that B<lag> => -2 will give:

 00101010

Here, responses necessarily start at the third element (I<a>), the first hits occurring when the fifth response-element corresponds to the the third target element (I<b>). The last response (I<e>) could not be used, and the number of elements in the hit/miss sequence became n-B<lag> less the original target sequence. This means that the maximum value of lag must be one less the size of the data-sets, or there will be no data.

=item loop => 0|1

Implements circularized lagging if B<loop> => 1, where all lagged data are preserved by looping any excess to the start or end of the criterion data. The number of observations will then always be the same, regardless of the lag; i.e., the size of the returned array is the same as that of the given data. For example, matching the data in the example above with a lag of +1, with looping, creates an additional match between the final response and the first target (I<d>); i.e., the last element in the "response" array is matched to the first element of the "target" array:

 1000100100

=item set

The optional argument B<set>, keying a two-element array, controls the binary-values to return; instead of the default set of 0s and 1s, the set might be, say, -1s and 1s, or "male" and "female". The first (zero-indexed) element in the set array replaces what, by default, would be returned as 0, and the second (index = 1) element in the set array replaces what, by default, would be returned as 1.

=back

=cut

sub match {
    my ( $self, @args ) = @_;
    my $args = ref $args[0]        ? $args[0]        : {@args};
    my $dat  = ref $args->{'data'} ? $args->{'data'} : $self->access($args);
    $dat = $self->crosslag(
        lag  => $args->{'lag'},
        data => [ $dat->[0], $dat->[1] ],
        loop => $args->{'loop'}
    ) if $args->{'lag'};
    my $lim =
        scalar @{ $dat->[0] } <= scalar @{ $dat->[1] }
      ? scalar @{ $dat->[0] }
      : scalar @{ $dat->[1] };    # ensure criterion data-set is smallest
    my (@seqs) = ();
    for my $i ( 0 .. $lim ) {
        next if !defined $dat->[0]->[$i] || !defined $dat->[1]->[$i];
        $seqs[$i] = $dat->[0]->[$i] eq $dat->[1]->[$i] ? 1 : 0;
    }
    _set( \@seqs, $args->{'set'} );
    return \@seqs;
}

=head2 Numerical or categorical data: Single sequence dichotimisation

=head3 shrink

 $aref = $ddat->shrink(winlen => INT, rule => CODE)

Returns a reference to an array of dichotomously transformed values of a numerical or categorical sequence by taking I<non-overlapping> slices, or windows, as given in the argument B<winlen>, and making a true/false sequence out of them according to whether or not each slice passes a B<rule>. The B<rule> is a code reference that gets the data as a reference to an array, and so might be something like this: 

 sub { return Statistics::Lite::mean(@{$_}) > 2 ? 1 : 0; }

If B<winlen> is set to 3, this means-wise rule would make the following numerical sequence of 9 elements shrink into the following dichotomous sequence of 3 elements:

 @data =  (1, 2, 3, 3, 3, 3, 4, 2, 1);
 @means = (2,       3,       2.5    );
 @dico =  (0,       1,       1      );

For categorical data, a completely "stringy" rule might be specified in the following ways. If B<winlen> => 1, and the given data are (A, B, c, d), then the rule

 sub { my $aref = shift; $aref->[0] =~ /[A-Z]/ ? 1 : 0; }

would yield the sequence be (1, 1, 0, 0) -- because the elements A and B satisfy the regular expression (being within the set {A .. Z}), while the remainder (elements c and e) do not.

Yet if B<winlen> => 2 for the same given data, the same case-wise rule might be specified as

 sub { my $aref = shift; my $str = join q{}, @{$aref}; $str =~ /[A-Z]{2,}/ ? 1 : 0; }

and the returned sequence is (1, 0), given that (again) the first two elements (A, B) satisfy the rule (returning 1), and the second pair of elements (c, e) do not (returning 0).

The B<rule> must, of course, return dichotomous values to dichotomize the data, and B<winlen> should make up equally sized segments (no error is thrown if this isn't the case, the remainder just gets figured in the same way).

Unlike other methods, this method does not respect a B<set> argument -- because the given transformation rule has control of what the set is (1s and 0s, or 1s and -1s, etc.).

=cut

sub shrink {
    my ( $self, @args ) = @_;
    my $args = ref $args[0]        ? $args[0]        : {@args};
    my $dat  = ref $args->{'data'} ? $args->{'data'} : $self->access($args);
    my $lim  = scalar @{$dat};
    my $len  = int $args->{'winlen'};
    $len ||= 1;
    my $code = delete $args->{'rule'};
    croak __PACKAGE__, '::shrink Need a code to Boolean shrink'
      if not $code
      or ref $code ne 'CODE';
    my ( $i, @seqs );

    for ( $i = 0 ; $i < $lim ; $i += $len )
    {    # C-style for clear greater-than 1 increments per loop
        push @seqs, $code->( [ @{$dat}[ $i .. ( $i + $len - 1 ) ] ] );
    }
    return \@seqs;
}
*boolwin = \&shrink;

=head2 Utilities

=head3 crosslag

 @lagged_arefs = $ddat->crosslag(data => [\@ari1, \@ari2], lag => signed integer, loop => 0|1);
 $aref_of_arefs = $ddat->crosslag(data => [\@ari1, \@ari2], lag => signed integer, loop => 0|1); # same but not "wanting array" 

Takes two arrays and returns them cross-lagged against each other, shifting and popping values according to the number of "lags". Typically used when wanting to L<match|match> the two arrays against each other.

=over 4

=item lag => signed integer up to the number of elements

Takes the first array sent as "data" as the reference or "target" array for the second "response" array to be shifted so many lags before or behind it. With no looping of the lags, this means the returned arrays are "lag"-elements smaller than the original arrays. For example, with lag => +1 (and loop => 0, the default), and with data => [ [qw/c p w p s/], [qw/p s s w r/] ],

 (c p w p s) becomes (p w p s)
 (p s s w r) becomes (p s s w)

So, whereas the original data gave no matches across the two arrays, now, with the second of the two arrays shifted forward by one index, it has a match (of "p") at the first index with the first of the two arrays.

=item loop => 0|1

For circularized lagging, B<loop> => 1, and the size of the returned array is the same as those for the given data. For example, with a lag of +1, the last element in the "response" array is matched to the first element of the "target" array:

 (c p w p s) becomes (p w p s c) (looped with +1)
 (p s s w r) becomes (p s s w r) (no effect)

In this case, it might be more efficient to simply autolag the "target" sequence against itself.

=back

=cut

sub crosslag {
    my ( $self, @args ) = @_;
    my $args = ref $args[0] ? $args[0] : {@args};
    my $lag  = $args->{'lag'};
    my $dat1 = $args->{'data'}->[0];
    my $dat2 = $args->{'data'}->[1];
    my $loop = $args->{'loop'};
    return ( wantarray ? ( $dat1, $dat2 ) : [ $dat1, $dat2 ] )
      if not $lag
      or abs $lag >= scalar @{$dat1};

    my @dat1_lagged = @{$dat1};
    my @dat2_lagged = @{$dat2};

    if ( $lag > 0 ) {
        foreach ( 1 .. abs $lag ) {
            if ($loop) {
                unshift @dat1_lagged, pop @dat1_lagged;
            }
            else {
                shift @dat1_lagged;
                pop @dat2_lagged;
            }
        }
    }
    elsif ( $lag < 0 ) {
        foreach ( 1 .. abs $lag ) {
            if ($loop) {
                push @dat1_lagged, shift @dat1_lagged;
            }
            else {
                pop @dat1_lagged;
                shift @dat2_lagged;
            }
        }
    }
    return wantarray
      ? ( \@dat1_lagged, \@dat2_lagged )
      : [ \@dat1_lagged, \@dat2_lagged ];
}

sub _set {
    my ( $aref, $set ) = @_;
    return if not ref $set or scalar @{$set} != 2;
    for my $i ( 0 .. scalar @{$aref} - 1 ) {
        if ( $aref->[$i] == 0 ) {
            $aref->[$i] = $set->[0];
        }
        else {
            $aref->[$i] = $set->[1];
        }
    }
    return;
}

=head1 AUTHOR

Roderick Garton, C<< <rgarton at cpan.org> >>

=head1 REFERENCES

B<Burdick, D. S., & Kelly, E. F.> (1977). Statistical methods in parapsychological research. In B. B. Wolman (Ed.), I<Handbook of parapsychology> (pp. 81-130). New York, NY, US: Van Nostrand Reinhold. L<ISBN 0442295766 9780442295769|http://www.worldcat.org/title/handbook-of-parapsychology/oclc/3003119&referer=brief_results> [Describes the L<shrink|Statistics::Data::Dichotomize/shrink> method of windowed Boolean dichotomization.]

B<Siegal, S.> (1956). I<Nonparametric statistics for the behavioral sciences>. New York, NY, US: McGraw-Hill. L<ISBN  	0070856893 9780070856899|http://www.worldcat.org/title/nonparametric-statistics-for-the-behavioral-sciences/oclc/166020&referer=brief_results> [Re dichotomization for the two-sample L<Runs test|Statistics::Sequences::Runs>.]

B<Swed, F., & Eisenhart, C.> (1943). Tables for testing randomness of grouping in a sequence of alternatives. I<Annals of Mathematical Statistics>, I<14>, 66-87. doi: L<10.1214/aoms/1177731494|http://dx.doi.org/10.1214/aoms/1177731494> [Describes the L<pool|Statistics::Data::Dichotomize/pool> method and test example.]

B<Wolfowitz, J.> (1943). On the theory of runs with some applications to quality control. I<Annals of Mathematical Statistics>, I<14>, 280-288. doi: L<10.1214/aoms/1177731421|http://dx.doi.org/10.1214/aoms/1177731421> [Describes the L<swing|Statistics::Data::Dichotomize/swing> method ("runs up and down") and test example.]

=head1 BUGS

Please report any bugs or feature requests to C<bug-Statistics-Data-Dichotomize-0.05 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Statistics-Data-Dichotomize-0.05>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::Data::Dichotomize

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-Data-Dichotomize-0.05>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Statistics-Data-Dichotomize-0.05>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Statistics-Data-Dichotomize-0.05>

=item * Search CPAN

L<http://search.cpan.org/dist/Statistics-Data-Dichotomize-0.05/>

=back

=head1 LICENSE AND COPYRIGHT

=over 4

=item Copyright (c) 2012-2016 Roderick Garton

This program is free software. It may be used, redistributed and/or modified under the same terms as Perl-5.6.1 (or later) (see L<http://www.perl.com/perl/misc/Artistic.html>).

=item Disclaimer

To the maximum extent permitted by applicable law, the author of this module disclaims all warranties, either express or implied, including but not limited to implied warranties of merchantability and fitness for a particular purpose, with regard to the software and the accompanying documentation.

=back

=cut

1;    # End of Statistics::Data::Dichotomize

package Statistics::Sequences;
use strict;
use warnings FATAL => 'all';
use Carp qw(croak);
use Statistics::Data 0.11;
use base qw(Statistics::Data);
use Scalar::Util qw(looks_like_number);
use Statistics::Lite qw(max);
use String::Numeric qw(is_int);
$Statistics::Sequences::VERSION = '0.15';

=pod

=head1 NAME

Statistics::Sequences - Common methods/interface for sub-module sequential tests (of Runs, Joins, Pot, etc.)

=head1 VERSION

This is documentation for Version 0.15 of Statistics::Sequences.

=head1 SYNOPSIS

 use Statistics::Sequences 0.15;
 $seq = Statistics::Sequences->new();
 my @data = (1, 'a', 'a', 1); # ordered list
 $seq->load(\@data); # or @data or 'name' => \@data
 print $seq->observed(stat => 'runs'); # assuming sub-module Runs.pm is installed
 print $seq->test(stat => 'vnomes', length => 2); # assuming sub-module Vnomes.pm is installed
 $seq->dump(stat => 'runs', values => [qw/observed z_value p_value/], exact => 1, tails => 1);
 # see also Statistics::Data for inherited methods

=head1 DESCRIPTION

This module provides methods for loading, updating and accessing data as ordered list of scalar values (numbers, strings) for statistical tests of their sequential properties via sub-modules including L<Statistics::Sequences::Joins|Statistics::Sequences::Joins>, L<Statistics::Sequences::Pot|Statistics::Sequences::Pot>, L<Statistics::Sequences::Runs|Statistics::Sequences::Runs>, L<Statistics::Sequences::Turns|Statistics::Sequences::Turns> and L<Statistics::Sequences::Vnomes|Statistics::Sequences::Vnomes>. None of these sub-modules are installed by default.

It also provides a common interface to access the statistical values returned by these tests, so that several tests can be performed on the same data, with the same class object. Alternatively, L<use|perlfunc/use> each sub-module directly.

=head1 SUBROUTINES/METHODS

=head2 new

 $seq = Statistics::Sequences->new();

Returns a new Statistics::Sequences object (inherited from L<Statistics::Data|Statistics::Data>) by which all the methods for caching, reading and testing data can be accessed, including each of the methods for performing the L<Runs-|Statistics::Sequences::Runs>, L<Joins-|Statistics::Sequences::Joins>, L<Pot-|Statistics::Sequences::Pot>, L<Turns-|Statistics::Sequences::Turns> or L<Vnomes-|Statistics::Sequences::Vnomes>tests.

Sub-packages also have their own new method - so, e.g., L<Statistics::Sequences::Runs|Statistics::Sequences::Runs>, can be individually imported, and its own L<new|new> method can be called, e.g.:

 use Statistics::Sequences::Runs;
 $runs = Statistics::Sequences::Runs->new();

In this case, data are not automatically shared across packages, and only one test (in this case, the Runs-test) can be accessed through the class-object.

=head2 load, add, access, unload

All these operations on the basic data are inherited from L<Statistics::Data|Statistics::Data> - see this doc for details of these and other possible methods.

=head2 observed

 $v = $seq->observed(stat => 'joins|pot|runs|turns|vnomes', %args); # gets data from cache, with any args needed by the stat
 $v = $seq->observed(stat => 'joins|pot|runs|turns|vnomes', data => [qw/blah bing blah blah blah/]); # just needs args for partic.stats
 $v = $seq->observed(stat => 'joins|pot|runs|turns|vnomes', label => 'myLabelledLoadedData'); # just needs args for partic.stats

If this method is defined by the sub-module named in the argument B<stat>, returns the observed value of the statistic for the L<load|Statistics::Sequences/load>ed data, or data sent with this call, eg., how many runs in the sequence (1, 1, 0, 1). See the particular statistic's manpage for any other arguments needed or optional. 

=cut

sub observed { return _feed( 'observed', @_ ); }
*observation = \&observed;

=head2 expected

 $v = $seq->expected(stat => 'joins|pot|runs|turns|vnomes', %args); # gets data from cache, with any args needed by the stat
 $v = $seq->expected(stat => 'joins|pot|runs|turns|vnomes', data => [qw/blah bing blah blah blah/]); # just needs args for partic.stats

If this method is defined by the sub-module named in the argument B<stat>, returns the expected value of the statistic for the L<load|Statistics::Sequences/load>ed data, or data sent with this call, eg., how many runs should occur in a 4-length sequence of two possible events. See the statistic's manpage for any other arguments needed or optional.

=cut

sub expected { return _feed( 'expected', @_ ); }
*expectation = \&expected;

=head2 variance

 $seq->variance(stat => 'joins|pot|runs|turns|vnomes', %args); # gets data from cache, with any args needed by the stat
 $seq->variance(stat => 'joins|pot|runs|turns|vnomes', data => [qw/blah bing blah blah blah/]); # just needs args for partic.stats

Returns the expected range of deviation in the statistic's observed value for the given number of trials, if this method is defined by the sub-module named in the argument B<stat>.

=cut

sub variance { return _feed( 'variance', @_ ); }

=head2 obsdev

 $v = $seq->obsdev(stat => 'joins|pot|runs|turns|vnomes', %args); # gets data from cache, with any args needed by the stat
 $v = $seq->obsdev(stat => 'joins|pot|runs|turns|vnomes', data => [qw/blah bing blah blah blah/]); # just needs args for partic.stats

Returns the deviation of (difference between) observed and expected values of the statistic for the loaded/given sequence (I<O> - I<E>); if this method is defined by the sub-module named in the argument B<stat>.

=cut

sub obsdev {
    return observed(@_) - expected(@_);
}
*observed_deviation = \&obsdev;

=head2 stdev

 $v = $seq->stdev(stat => 'joins|pot|runs|turns|vnomes', %args); # gets data from cache, with any args needed by the stat
 $v = $seq->stdev(stat => 'joins|pot|runs|turns|vnomes', data => [qw/blah bing blah blah blah/]); # just needs args for partic.stats

Returns square-root of the variance, if this method is defined by the sub-module named in the argument B<stat>.

=cut

sub stdev {
    return sqrt variance(@_);
}
*standard_deviation = \&stdev;

=head2 z_value

 $v = $seq->z_value(stat => 'joins|pot|runs|turns|vnomes', %args); # gets data from cache, with any args needed by the stat
 $v = $seq->z_value(stat => 'joins|pot|runs|turns|vnomes', data => [qw/blah bing blah blah blah/]); # just needs args for partic.stats

Return the deviation ratio: observed deviation to standard deviation. Use argument B<ccorr> for continuity correction.

=cut

sub zscore { return _feed( 'zscore', @_ ); }
*z_value = \&zscore;

=head2 p_value

 $p = $seq->p_value(stat => 'runs'); # same for 'joins', 'turns'
 $p = $seq->p_value(stat => 'pot', state => 'a value appearing in the data');
 $p = $seq->p_value(stat => 'vnomes', length => 'an integer greater than zero and less than sample-size');

Returns the probability of observing so many runs, joins, etc., according to whatever such method is defined by the sub-module named in the argument B<stat>.

=cut

sub p_value { return _feed( 'p_value', @_ ); }
*test = \&p_value;

=head2 stats_hash

 $href = $seq->stats_hash(values => [qw/observed expected variance z_value p_value/]);
 $href = $seq->stats_hash(values => {observed => 1, expected => 1, variance => 1, z_value => 1, p_value => 1});

Returns a hashref with values for any of the methods for the specified B<stat>istic (e.g., observed() value for runs). The named argument B<values> is for an array-ref of stats that correspond to the method names for the given B<stat> (which is really a class name, e.g., runs, pot, for a Statistics::Sequences sub-module). The hash-reference of stat-values as keys (also shown in example above) is only in place for the purpose of setting optional args per value in a future version.

Include other required or optional arguments relevant to any of the values requested, as defined in the sub-module manpages, e.g., B<ccorr> if getting a z_value, B<tails> and B<exact> if getting a p_value, B<state> if testing pot, B<prob> if testing joins. The args B<precision_s> and B<precision_p> apply to all values, although the latter specifically applies to any C<p_value>.

=cut

sub stats_hash {
    my $self = shift;
    my $args = ref $_[0] ? $_[0] : {@_};
    croak 'No values requested to return in hash' if !ref $args->{'values'};
    my @methods = ();
    if ( ref $args->{'values'} eq 'ARRAY' ) {
        @methods = @{ $args->{'values'} };
    }
    else {    # assume hash
         # later version might check for optional args per value, not just == 1:
        @methods =
          grep { $args->{'values'}->{$_} == 1 } keys %{ $args->{'values'} };
    }

    my (%stats_hash) = ();
    no strict 'refs';
    foreach my $method (@methods) {
        eval { $stats_hash{$method} = $self->$method($args); };
        croak "Method <$method> is not defined or correctly called for "
          . __PACKAGE__
          if $@;
    }
    return \%stats_hash;
}

=head2 dump

 $seq->dump(stat => 'runs|joins|pot ...', values => {}, format => 'string|labline|table', flag => '1|0', precision_s => 'integer', precision_p => 'integer');

I<Alias>: B<print_summary>

Print results of the last-conducted test to STDOUT. By default, if no parameters to C<dump> are passed, a single line of test statistics is printed. Options are as follows.

=over 8

=item values => hashref

Hashref of the statistical parameters to dump. Default is observed value and p-value for the given B<stat>.

=item flag => I<boolean>

If true, the I<p>-value associated with the I<z>-value is appended with a single asterisk if the value if below .05, and with two asterisks if it is below .01.

If false (default), nothing is appended to the I<p>-value.

=item format => 'table|labline|csv'

Default is 'csv', to print the stats hash as a comma-separated string (no newline), e.g., '4.0000,0.8596800". If specifying 'labline', you get something like "observed = 4.0000, p_value = 0.8596800\n". If specifying "table", this is a dump from L<Text::SimpleTable|Text::SimpleTable> with the stat methods as headers and column length set to the maximum required for the given headers, level of precision, flag, etc. For example, with B<precision_s> => 4 and B<precision_p> => 7, you get:

 .-----------+-----------.
 | observed  | p_value   |
 +-----------+-----------+
 | 4.0000    | 0.8596800 |
 '-----------+-----------'

=item verbose => 1|0

If true, includes a title giving the name of the statistic, details about the hypothesis tested (if B<p_value> => 1 in the B<values> hashref), et al. No effect if B<format> is not defined or equals 'csv'.

=item precision_s => 'I<non-negative integer>'

Precision of the statistic values (observed, expected, variance, z_value).

=item precision_p => 'I<non-negative integer>'

Specify rounding of the probability associated with the I<z>-value to so many digits. If zero or undefined, you get everything available.

=back

=cut

sub dump {
    my $self       = shift;
    my $args       = ref $_[0] ? $_[0] : {@_};
    my $stats_hash = $self->stats_hash($args);
    $args->{'format'} ||= 'csv';
    my @standard_methods =
      (qw/observed expected variance obsdev stdev z_value psisq p_value/);
    my ( $maxlen, @strs, @headers ) = (0);

    # set up what has been requested in a meaningful order:
    my @wanted_methods = grep { defined $stats_hash->{$_} } @standard_methods;

    # add any extra "non-standard" methods
    foreach my $method ( keys %{$stats_hash} ) {
        if ( !grep /$method/, @wanted_methods ) {
            push @wanted_methods, $method;
        }
    }

    # format each value for printing, adjusting its length if necessary:
    foreach my $method (@wanted_methods) {
        my $val = delete $stats_hash->{$method};
        my $len;
        ( $val, $len ) = _format_output_value( $val, $method, $args );
        push @headers, $method;
        push @strs,    $val;
        $len    = length $val if !defined $len;
        $maxlen = $len        if $len > $maxlen;
    }

    if ( $args->{'format'} eq 'table' ) {
        _print_table( $maxlen, \@headers, \@strs, $args );
    }
    elsif ( $args->{'format'} eq 'labline' ) {
        _print_labline( \@headers, \@strs, $args );
    }
    else {    # csv
        print join( q{,}, @strs ) or croak 'Cannot print data-string';
    }
    return;
}
*print_summary = \&dump;

=head2 dump_data

 $seq->dump_data(delim => "\n");

Prints to STDOUT a space-separated line of the tested data - as dichotomized and put to test. Optionally, give a value for B<delim> to specify how the datapoints should be separated. Inherited from L<Statistics::Data|Statistics::Data/dump_data>.

=cut

# PRIVATMETHODEN

sub _feed {
    my $method   = shift;
    my $self     = shift;
    my $args     = ref $_[0] ? $_[0] : {@_};
    my $statname = $args->{'stat'} || q{};
    my $class    = __PACKAGE__ . q{::} . ucfirst($statname);
    eval {require $class};
    if ($@) {
        croak __PACKAGE__,
" error: Requested sequences module '$class' is not available";
    }
    my ( $val, $nself ) = ( q{}, {} );
    bless( $nself, $class );
    $nself->{$_} = $self->{$_} foreach keys %{$self};
    no strict 'refs';
    eval {$val = $nself->$method($args)}
      ;    # but does not trap "deep recursion" if method not defined
    if ($@) {
        croak __PACKAGE__,
      " error: Method '$method' is not defined or correctly called for $class";
    }
    return $val;
}

sub _precisioned {
    my ( $len, $val ) = @_;
    my $nval;
    if ( !defined $val ) {
        $nval = q{};
    }
    elsif ( is_int($val) ) {
        $nval = $val;
    }
    elsif ($len) {    # don't lose any zero
        $nval = sprintf( q{%.} . $len . q{f}, $val );
    }
    else {
        $nval = $val;
    }
    return $nval;
}

sub _format_output_value {
    my ( $val, $method, $args ) = @_;
    my $len;
    if ( $method eq 'p_value' ) {
        $val = _precisioned( $args->{'precision_p'}, $val );
        $val .= ( $val < .05 ? ( $val < .01 ? q{**} : q{*} ) : q{} )
          if $args->{'flag'};
    }
    else {
        if ( ref $val ) {
            if ( ref $val eq 'HASH' ) {
                my %vals = %{$val};
                $val = q{};
                my $delim = $args->{'format'} eq 'table' ? "\n" : q{,};
                my ( $str, $this_len ) = ();
                while ( my ( $k, $v ) = each %vals ) {
                    $str = "'$k' = $v";
                    $len = max( length($str), $len );
                    $val .= $str . $delim;
                }
                if ( $args->{'format'} ne 'table' ) {
                    chop $val;
                    $val = '(' . $val . ')';
                }
            }
            else {
                $val = join q{, }, @{$val};
            }
        }
        elsif ( looks_like_number($val) ) {
            $val = _precisioned( $args->{'precision_s'}, $val );
        }
    }
    return ( $val, $len );
}

sub _print_table {
    my ( $maxlen, $headers, $strs, $args ) = @_;
    $maxlen = 8 if $maxlen < 8;
    my $title =
      $args->{'verbose'}
      ? ucfirst( $args->{'stat'} ) . " statistics\n"
      : q{};
    my @hh = ();
    push( @hh, [ $maxlen, $_ ] ) foreach @{$headers};
    require Text::SimpleTable;
    my $tbl = Text::SimpleTable->new(@hh);
    $tbl->row( @{$strs} );
    print $title or croak 'Cannot print table title';
    print $tbl->draw or croak 'Cannot print data-table';
    return;
}

sub _print_labline {
    my ( $headers, $strs, $args ) = @_;

    my @hh;
    for my $i ( 0 .. ( scalar @{$strs} - 1 ) ) {
        $hh[$i] = "$headers->[$i] = $strs->[$i]";
    }
    my $str = join( q{, }, @hh );
    if ( $args->{'verbose'} ) {
        $str = ucfirst( $args->{'stat'} ) . ': ' . $str;
    }
    print {*STDOUT} $str, "\n" or croak 'Cannot print data-string';
    return;
}

=head1 DIAGNOSTICS

=over 8

=item Requested sequences module '$class' is not available

Croaked when any method is called that is not defined for the sub-module named as B<stat>.

=item Method '$method' is not defined or correctly called for $class

Method, like observed() called for a particular class (with the argument B<stat> in this parent module) might not exist, e.g., like 'kurtosis' among the 'pot' statistics; or the other arguments for the method are invalid, like calling them without any B<data>.

=item No values requested to return in hash

Croaked from L<stats_hash|Statistics::Sequences/stats_hash>, including va dump(), if array or hash ref named B<values> is not given in the call.

=item Cannot print data-string

Courtesy of the dump() method; when trying to C<print> a string as a single line or a table (via Text::SimpleTable's C<draw>).

=back

=head1 BUNDLING

This module C<use>s its sub-modules implicitly - so a bundled program using this module might need to explicitly C<use> its sub-modules if these need to be included in the bundle itself.

=head1 AUTHOR

Roderick Garton, C<< <rgarton at cpan.org> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::Sequences

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-Sequences-0.15>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Statistics-Sequences-0.15>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Statistics-Sequences-0.15>

=item * Search CPAN

L<http://search.cpan.org/dist/Statistics-Sequences-0.15/>

=back

=head1 LICENSE AND COPYRIGHT

=over 4

=item Copyright (c) 2006-2017 Roderick Garton

This program is free software. It may be used, redistributed and/or modified under the same terms as Perl-5.6.1 (or later) (see L<http://www.perl.com/perl/misc/Artistic.html>).

=item Disclaimer

To the maximum extent permitted by applicable law, the author of this module disclaims all warranties, either express or implied, including but not limited to implied warranties of merchantability and fitness for a particular purpose, with regard to the software and the accompanying documentation.

=back

=cut

1;    # end of Statistics::Sequences

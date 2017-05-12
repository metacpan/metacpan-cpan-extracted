package Statistics::ANOVA::JT;

use 5.006;
use strict;
use warnings FATAL => 'all';
use base qw(Statistics::Data);
use Algorithm::Combinatorics qw(combinations);
use List::AllUtils qw(sum0);
use Statistics::Data::Rank;
use Statistics::Lite qw(count max);

=head1 NAME

Statistics::ANOVA::JT - Jonckheere-Terpstra statistics and test

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

 use Statistics::ANOVA::JT;
 my $jt = Statistics::ANOVA::JT->new();
 $jt->load({1 => [2, 4, 6], 2 => [3, 3, 12], 3 => [5, 7, 11, 16]}); # note ordinal datanames
 my $j_value = $jt->observed(); # or expected(), variance()
 my ($z_value, $p_value) = $jt->zprob_test(ccorr => 2, tails => 1, correct_ties => 1);
 # or without pre-loading:
 $j_value = $jt->observed(data => {1 => [2, 4, 6], 2 => [5, 3, 12]});
 # or for subset of loaded data:
 $j_value = $jt->observed(lab => [1, 3]);
 
=head1 DESCRIPTION

Calculates Jonckheere-Terpstra statistics for sameness (common population) across given orders of independent variables. The statistics are based on a between-groups pooled ranking of the data, like the Kruskal-Wallis test, but, unlike Kruskall-Wallis that returns the same result regardless of order of levels, it takes into account ordinal value of the named data. As ordinal values, numerical intervals between the named values do not matter.

Data-loading and retrieval are as provided in L<Statistics::Data|Statistics::Data>, on which the JT object is C<base>d, so its other methods are available here.

Return values are tested on installation against published examples: in Hollander and Wolfe (1999), for sample MStat output on L<mcardle.wisc.edu|http://mcardle.wisc.edu/mstat/help/help/Notes-05.html>, and for the final I<Z>-value in the L<wikipedia|http://en.m.wikipedia.org/wiki/Jonckheere\'s_trend_test> example.

=head1 SUBROUTINES/METHODS

=head2 new

 $jt = Statistics::ANOVA::JT->new();

New object for accessing methods and storing results. This "isa" Statistics::Data object.

=head2 observed

 $val = $jt->observed(); # data pre-loaded
 $val = $jt->observed(data => $hashref_of_arefs);

Returns the statistic I<J>: From between-group rankings of all possible pairwise splits of the data, accumulates I<J> as the sum of I<k>(I<k> - 1)/2 Mann-Whitney I<U> counts.

Optionally, if the data have not been pre-loaded, send as named argument B<data>.

=cut

sub observed {
    my ( $self, %args ) = @_;
    return _calc_j_value( _get_data($self, %args) );
}

=head2 expected

 $val = $jt->expected(); # data pre-loaded
 $val = $jt->expected(data => $hashref_of_arefs);

Returns the expected value of the I<J> statistic for the given data.

=cut

sub expected {
    my ( $self, %args ) = @_;
    return _calc_jexp( _get_data($self, %args) );
}

=head2 variance

 $val = $jt->variance(); # data pre-loaded
 $val = $jt->variance(data => $hashref_of_arefs);

Return the variance expected to occur in the I<J> values for the given data.

By default, the method accounts for and corrects for ties, but if C<correct_ties> = 0, the returned value is the usual "null" distribution variance, otherwise with an elaborate correction accounting for the number of tied variables and each of their sizes, as offered by Hollander & Wolfe (1999) Eq 6.19, p. 204.

=cut

sub variance {
    my ( $self, %args ) = @_;
    if ( defined $args{'correct_ties'} and $args{'correct_ties'} == 0 ) {
        return _calc_jvar_ig_ties( _get_data($self, %args) );
    }
    else {
        return _calc_jvar_by_ties( _get_data($self, %args) );
    }
}

=head2 zprob_test

 $p_val = $jt->zprob_test(); # data pre-loaded
 $p_val = $jt->zprob_test(data => $hashref_of_arefs);
 ($z_val, $p_val) = $jt->zprob_test(); # get z-score too

Performs a z-test on the data and returns the associated probability; or, if called in array context, the z-value itself and then the probability value.

Rather than calculating the exact I<p>-value, calculates an expected I<J> value and variance, to provide a normalized I<J> for which the I<p>-value is read off the normal distribution. This is appropriate for "large" samples, e.g., greater-than 3 levels, with more than eight observations per level. Otherwise, read the value returned from C<$jt-E<gt>observed()> and look it up in a table of I<j>-values, such as in Hollander & Wolfe (1999), p. 649ff.

Optional arguments include B<correct_ties> (as above), and B<tails> and B<ccorr> as in L<Statistics::Zed|Statistics::Zed>. For example, to continuity correct by reducing the observed I<J>-value by 1 (recommended in some texts), set B<ccorr> => 2 (for half on either side of the expected value; if B<ccorr> => 1, then 0.5 is taken off the observed deviation, and so on). The default is not to continuity correct.

=cut

sub zprob_test {
    my ( $self, %args ) = @_;
    my $href =  _get_data($self, %args);
    require Statistics::Zed;
    my $zed = Statistics::Zed->new();
    my ( $z_value, $p_value ) = $zed->z_value(
        observed => _calc_j_value($href),
        expected => _calc_jexp($href),
        variance =>
          ( defined $args{'correct_ties'} and $args{'correct_ties'} == 0 )
        ? _calc_jvar_ig_ties($href)
        : _calc_jvar_by_ties($href),
        %args
    );
    return wantarray ? ( $z_value, $p_value ) : $p_value;
}

sub _calc_j_value {
    my $data    = shift;
    my $rankd   = Statistics::Data::Rank->new();
    my $j_value = 0;
    for my $pairs ( combinations( [ keys %{$data} ], 2 ) ) {
        my ( $p1, $p2 ) = @{$pairs};
        my $ranks_href = $rankd->ranks_between(
            data => { $p1 => $data->{$p1}, $p2 => $data->{$p2} } );
        my %counts = (
            $p1 => count( @{ $data->{$p1} } ),
            $p2 => count( @{ $data->{$p2} } )
        );
        my $nprod = $counts{$p1} * $counts{$p2};
        my @us    = ();
        for ( $p1, $p2 ) {
            my $n = $counts{$_};
            push @us,
              $nprod +
              ( ( $n * ( $n + 1 ) ) / 2 ) -
              sum0( @{ $ranks_href->{$_} } );
        }
        $j_value += max(@us);
    }
    return $j_value;
}

sub _calc_jexp {
    my ($data) = @_;
    my ( $nj, $sum_n ) = ( 0, 0 );
    for ( keys %{$data} ) {
        my $n = count( @{ $data->{$_} } );
        $sum_n += $n;
        $nj += $n**2;
    }
    return ( $sum_n**2 - $nj ) / 4;
}

sub _calc_jvar_ig_ties {
    my $data = shift;
    my ( $sum_n, $v ) = ( 0, 0 );
    for ( keys %{$data} ) {
        my $n = count( @{ $data->{$_} } );
        $sum_n += $n;
        $v += $n**2 * ( 2 * $n + 3 );
    }
    return ( $sum_n**2 * ( 2 * $sum_n + 3 ) - $v ) / 72;
}

sub _calc_jvar_by_ties {
    my $data  = shift;
    my $sum_n = 0;
    my @ns    = ();
    for ( keys %{$data} ) {
        my $n = count( @{ $data->{$_} } );
        $sum_n += $n;
        push @ns, $n;
    }
    my $ng    = scalar( keys( %{$data} ) );
    my $rankd = Statistics::Data::Rank->new();
    my ( $uranks_href, $xtied, $gn  ) =
      $rankd->ranks_between( data => $data );
    my $a2 = sum0( map { $_ * ( $_ - 1 ) * ( 2 * $_ + 5 ) } @ns );
    my $a3 = sum0( map { $_ * ( $_ - 1 ) * ( 2 * $_ + 5 ) } @{$xtied} );
    my $b2 = sum0( map { $_ * ( $_ - 1 ) * ( $_ - 2 ) } @ns );
    my $b3 = sum0( map { $_ * ( $_ - 1 ) * ( $_ - 2 ) } @{$xtied} );
    my $c2 = sum0( map { $_ * ( $_ - 1 ) } @ns );
    my $c3 = sum0( map { $_ * ( $_ - 1 ) } @{$xtied} );
    return ( 1 / 72 * ( $gn * ( $gn - 1 ) * ( 2 * $gn + 5 ) - $a2 - $a3 ) ) +
      ( 1 / ( 36 * $gn * ( $gn - 1 ) * ( $gn - 2 ) ) * $b2 * $b3 ) +
      ( 1 / ( 8 * $gn * ( $gn - 1 ) ) * $c2 * $c3 );
}

sub _get_data {
    my ($self, %args) = @_;
    my $hoa;
    if (ref $args{'data'}) {
        $hoa = delete $args{'data'};
    }
    else {
        $hoa = $self->get_hoa_by_lab(%args);
    }
    return $hoa;
}

=head1 REFERENCES

Hollander, M., & Wolfe, D. A. (1999). I<Nonparametric statistical methods>. New York, NY, US: Wiley.

=head1 DEPENDENCIES

L<Statistics::Data|Statistics::Data> : used as a C<base> for caching and retrieving data.

L<Statistics::Data::Rank|Statistics::Data::Rank> : used to implement between-sample ranking.

L<Statistics::Zed|Statistics::Zed> : for z-testing with optional continuity correction and tailing.

L<Algorithm::Combinatorics|Algorithm::Combinatorics> : provides the C<combinations> algorithm to provide all possible pairs of data-names to loop thru in calculating the observed I<J> value.

L<List::AllUtils|List::AllUtils> : provides the handy sum0() function

=head1 BUGS

Please report any bugs or feature requests to C<bug-statistics-anova-jt-0.01 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Statistics-ANOVA-JT-0.01>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::ANOVA::JT

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-ANOVA-JT-0.01>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Statistics-ANOVA-JT-0.01>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Statistics-ANOVA-JT-0.01>

=item * Search CPAN

L<http://search.cpan.org/dist/Statistics-ANOVA-JT-0.01/>

=back

=head1 AUTHOR

Roderick Garton, C<< <rgarton at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Roderick Garton.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;    # End of Statistics::ANOVA::JT

package Statistics::ANOVA::Page;

use 5.006;
use strict;
use warnings FATAL => 'all';
use base qw(Statistics::Data);
use Carp qw(croak);
use List::AllUtils qw(sum0);
use Math::Cephes qw(:dists);
use Statistics::Data::Rank;
use Statistics::Zed;
$Statistics::ANOVA::Page::VERSION = '0.02';

=head1 NAME

Statistics::ANOVA::Page - Nonparametric analysis of variance by ranks for trend across repeatedly measured variables (Page and sign tests).

=head1 VERSION

This is documentation for B<Version 0.02> of Statistics::ANOVA::Page.

=head1 SYNOPSIS

 use Statistics::ANOVA::Page;
 my $page = Statistics::ANOVA::Page->new();
 $page->load({1 => [2, 4, 6], 2 => [3, 3, 12], 3 => [5, 7, 11, 16]}); # note ordinal datanames
 my $l_value = $page->observed(); # or expected(), variance()
 my ($z_value, $p_value) = $page->zprob_test(ccorr => 2, tails => 1);
 # or without pre-loading:
 $l_value = $page->observed(data => {1 => [2, 4, 6], 2 => [5, 3, 12]});
 # or for subset of loaded data:
 $l_value = $page->observed(lab => [1, 3]);

=head1 DESCRIPTION

Calculates Page statistics for nonparametric analysis of variance across given orders of repeatedly measured variables. Ranks are computed exactly as for the L<Friedman|Statistics::ANOVA::Friedman> test, but the ranks are weighted according to the ordinal position of the group/level to which they pertain. Also, the test of significance is based on a standardized value, with the I<p>-value read off the normal distribution. Similarly to the relationship between the Kruskal-Wallis and L<Jonckheere-Terpstra|Statistics::ANOVA::JT> tests for non-dependent observations, the Friedman test returns the same value regardless of the ordinality of the variables as levels, but the Page test is of ranks in association with the ordinality of the variables (as levels rather than groups). These are weighted according to their Perl sort { $a <=> $b} order, so they should have sort-able names that reflect the ordering of the variables.

With only two groups, the test statistic is equivalent to that provided by a B<sign test>.

Build tests include comparison of return values with published data, viz. from Hollander and Wolfe (1999, p. 286ff); passing these tests means the results agree.

=head1 SUBROUTINES/METHODS

=head2 new

 $page = Statistics::ANOVA::Page->new();

New object for accessing methods and storing results. This "isa" Statistics::Data object.

=head2 load, add, unload

 $page->load(1 => [1, 4], 2 => [3, 7]);

The given data can now be used by any of the following methods. This is inherited from L<Statistics::Data|Statistics::Data>, and all its other methods are available here via the class object. Only passing of data as a hash of arrays (HOA) is supported for now. Alternatively, give each of the following methods the HOA for the optional named argument B<data>.

=head2 observed

 $val = $page->observed(); # data pre-loaded
 $val = $page->observed(data => $hashref_of_arefs);

Returns the observed statistic I<L> based on within-group rankings of the data weighted according to the ordinal position of the variable (by its numerical name) to which they pertain.

Optionally, if the data have not been pre-loaded, send as named argument B<data>.

=cut

sub observed {
    my ( $self, %args ) = @_;
    return _calc_l_value( _get_data( $self, %args ) );
}

=head2 observed_r

 $val = $page->observed_r(); # data pre-loaded
 $val = $page->observed_r(data => $hashref_of_arefs);

This implements a "l2r" transformation: Hollander and Wolfe (1999) describe how Page's I<L>-statistic is directly related to Spearman's rank-order correlation coefficient (see L<Statistics::RankCorrelation|Statistics::RankCorrelation>), based on the observed and predicted order of each associated group/level per observation.

=cut

sub observed_r {
    my ( $self, %args ) = @_;
    return _calc_l2r_value( _get_data( $self, %args ) );
}

=head2 expected

 $val = $page->expected(); # data pre-loaded
 $val = $page->expected(data => $hashref_of_arefs);

Returns the expected value of the I<L> statistic for the given data.

=cut

sub expected {
    my ( $self, %args ) = @_;
    return _calc_l_exp( _get_data( $self, %args ) );
}

=head2 variance

 $val = $page->variance(); # data pre-loaded
 $val = $page->variance(data => $hashref_of_arefs);

Return the variance expected to occur in the I<L> values for the given data.

=cut

sub variance {
    my ( $self, %args ) = @_;
    return _calc_l_var( _get_data( $self, %args ) );
}

=head2 zprob_test

 $p_val = $page->zprob_test(); # data pre-loaded
 $p_val = $page->zprob_test(data => $hashref_of_arefs);
 ($z_val, $p_val) = $page->zprob_test(); # get z-score too

Calculates an expected I<L> value and variance, to provide a normalized I<L> for which the I<p>-value is read off the normal distribution. This is appropriate for "large" samples. Optional arguments are B<tails> and B<ccorr> as in L<Statistics::Zed|Statistics::Zed>.

=cut

sub zprob_test {
    my ( $self, %args ) = @_;
    my $href = _get_data( $self, %args );
    my $zed = Statistics::Zed->new();
    my ( $z_value, $p_value ) = $zed->z_value(
        observed => _calc_l_value($href),
        expected => _calc_l_exp($href),
        variance => _calc_l_var($href),
        %args
    );
    return wantarray ? ( $z_value, $p_value ) : $p_value;
}

=head2 chiprob_test

 $p_val = $page->chiprob_test(); # data pre-loaded
 $p_val = $page->chiprob_test(data => $hashref_of_arefs);
 ($chi_val, $df, $num, $p_val) = $page->chiprob_test();

Calculates a chi-square statistic based on the observed value of I<L>, the number of ranked variables, and the number of replications; as per Page(1963, Eq. 4). This is a two-tailed test; if the optional argument B<tails> => 1, the returned probability, read off the chi-square distribution, is halved. Called in scalar context, returns the I<p>-value alone. Called in list context, returns the chi-square value, the degrees-of-freedom, number of observations, and then the I<p>-value.

=cut

sub chiprob_test {
    my ( $self, %args ) = @_;
    my $data_href = _get_data( $self, %args );
    my $l         = _calc_l_value($data_href);
    my $n_bt      = scalar keys %{$data_href};
    my $n_wt      = __PACKAGE__->equal_n( data => $data_href );
    my $num = ( ( 12 * $l ) - ( 3 * $n_wt * $n_bt ) * ( $n_bt + 1 )**2 )**2;
    my $den = ( ( $n_wt * $n_bt**2 ) * ( $n_bt**2 - 1 ) * ( $n_bt + 1 ) );
    croak 'Chi-square probability test not available given limited number of observations' if ! $den;
    my $chi = $num / $den;
    my $p_value = _set_tails( chdtrc( 1, $chi ), $args{'tails'} );    # Math::Cephes fn
    return wantarray ? ( $chi, 1, ( $n_bt * $n_wt ), $p_value ) : $p_value;
}

=head2 chiprob_str

 $str = $page->chiprob_str(data => HOA, correct_ties => 1);

Performs L<chiprob_test|Statistics::ANOVA::Friedman/chiprob_test> and returns a string of the conventional reporting form, e.g., chi^2(df, N = total observations) = chi_value, p = p_value.

=cut

sub chiprob_str {
    my ( $self, %args ) = @_;
    my ( $chi_value, $df, $count, $p_value ) = $self->chiprob_test(%args);
    return "chi^2($df, N = $count) = $chi_value, p = $p_value";
}

sub _calc_l_value {
    my $data  = shift;
    my $ranks = Statistics::Data::Rank->sum_of_ranks_within( data => $data );
    my $c     = 0;
    return sum0(
        map  { ++$c * $ranks->{$_} }
        sort { $a <=> $b } keys %{$ranks}
    );
}

sub _calc_l2r_value {
    my $data = shift;
    my $l    = _calc_l_value($data);
    my $n_bt = scalar keys %{$data};
    my $n_wt = __PACKAGE__->equal_n( data => $data );
    return ( ( ( 12 * $l ) / ( $n_wt * $n_bt * ( $n_bt**2 - 1 ) ) ) -
          ( ( 3 * ( $n_bt + 1 ) ) / ( $n_bt - 1 ) ) );
}

sub _calc_l_exp {
    my $data = shift;
    my $n_bt = scalar keys %{$data};
    my $n_wt = __PACKAGE__->equal_n( data => $data );
    return ( $n_wt * $n_bt * ( $n_bt + 1 )**2 ) / 4;
}

sub _calc_l_var {
    my $data = shift;
    my $n_bt = scalar keys %{$data};
    my $n_wt = __PACKAGE__->equal_n( data => $data );
    return ( $n_wt * $n_bt**2 * ( $n_bt + 1 ) * ( $n_bt**2 - 1 ) ) / 144;
}

sub _set_tails {
    my ($p_value, $tails) = @_;
    $tails ||= 2;
    if (defined $tails and $tails == 1) {
        $p_value /= 2;
    }
    return $p_value;
}

sub _get_data {
    my ( $self, %args ) = @_;
    my $hoa;
    if ( ref $args{'data'} ) {
        $hoa = delete $args{'data'};
    }
    else {
        $hoa = $self->get_hoa_by_lab(%args);
    }
    return $hoa;
}

=head1 DIAGNOSTICS

=over 4

=item Chi-square probability test not available given limited number of observations

C<croak>ed if the denominator value to calculate the chi-square statistic is not defined or zero, which would arise if there is only one between-group level, or zero observations within the levels.

=item Equal number of observations required for calculating ranks within groups

C<croak>ed via Statistics::Data::Rank *_ranks_within methods given that they need to have the same number of observations per group; as when the different factor levels are repeatedly measured on the same replicants. Most methods require this to be the case.

=back

=head1 REFERENCES

Hollander, M., & Wolfe, D. A. (1999). I<Nonparametric statistical methods>. New York, NY, US: Wiley.

Page, E. B. (1963). Ordered hypotheses for multiple treatments: A significance test for linear ranks. I<Journal of the American Statistical Association>, I<58>, 216-230. doi: L<10.1080/01621459.1963.10500843|http://dx.doi.org/10.1080/01621459.1963.10500843>. [L<JSTOR|http://www.jstor.org/stable/2282965>]

=head1 DEPENDENCIES

L<List::AllUtils|List::AllUtils> : provides the handy sum0() function

L<Math::Cephes|Math::Cephes> : used for probability functions.

L<Statistics::Data|Statistics::Data> : used as a C<base> for caching and retrieving data.

L<Statistics::Data::Rank|Statistics::Data::Rank> : used to implement cross-case ranking.

L<Statistics::Zed|Statistics::Zed> : for z-testing with optional continuity correction and tailing.

=head1 AUTHOR

Roderick Garton, C<< <rgarton at cpan.org> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-statistics-anova-page-0.02 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Statistics-ANOVA-Page-0.02>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::ANOVA::Page


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-ANOVA-Page-0.02>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Statistics-ANOVA-Page-0.02>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Statistics-ANOVA-Page-0.02>

=item * Search CPAN

L<http://search.cpan.org/dist/Statistics-ANOVA-Page-0.02/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015-2017 Roderick Garton.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1;    # End of Statistics::ANOVA::Page

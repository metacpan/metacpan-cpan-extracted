package Statistics::ANOVA::Friedman;

use 5.006;
use strict;
use warnings FATAL => 'all';
use base qw(Statistics::Data);
use Carp qw(croak);
use List::AllUtils qw(sum0);
use Math::Cephes qw(:dists);
use Statistics::Data::Rank;
$Statistics::ANOVA::Friedman::VERSION = '0.02';

=head1 NAME

Statistics::ANOVA::Friedman - Nonparametric repeated measures analysis of variance for dependent factorial measures (Friedman Test)

=head1 VERSION

This is documentation for version 0.02, released February 2017.

=head1 SYNOPSIS

 use Statistics::ANOVA::Friedman;
 my $fri = Statistics::ANOVA::Friedman->new();
 my ($chi_value, $df, $count, $p_value) = $fri->chiprob_test(data => HOA);
 $fri->load({1 => [2, 4, 6], 2 => [3, 3, 12], 3 => [5, 7, 11]}); # or pre-load with HOA
 ($chi_value, $df, $count, $p_value) = $fri->chiprob_test();
 my ($f_value, $df_b, $df_w, $p_value2) = $fri->fprob_test();

=head1 DESCRIPTION

Performs the B<Friedman> nonparametric analysis of variance - for dependent (correlated, matched) measures of two or more discrete (nominal) variables, such as when the measures are taken from the same source (e.g., person, plot) but under different conditions. A ranking procedure is used, but, unlike the case for independent measures, the ranks are taken at each common index of each measure, i.e., within-groups.

By default, the method accounts for and corrects for ties, but if B<correct_ties> => 0, the test-statistic is uncorrected. The correction involves accounting for the number of tied variables at each index, as per Hollander & Wolfe (1995), Eq. 7.8, p. 274.

Correctness of output is tested on installation using example data from Hollander & Wolfe (1999, p. 274ff), Rice (1995, p. 470), Sarantakos (1993, p. 404-405), and Siegal (1956, p. 167ff); tests fail if the published chi-values and degrees-of-freedom are not returned by the module.

The module uses L<Statistics::Data|Statistics::Data> as a base so that data can be pre-loaded and added to per that module's methods.

=head1 SUBROUTINES/METHODS

=head2 new

 $fri = Statistics::ANOVA::Friedman->new();

New object for accessing methods and storing results. This "isa" Statistics::Data object.

=head2 load, add, unload

 $fri->load('a' => [1, 4], 'b' => [3, 7]);

The given data can now be used by any of the following methods. This is inherited from L<Statistics::Data|Statistics::Data>, and all its other methods are available here via the class object. Only passing of data as a hash of arrays (HOA) is supported for now. Alternatively, give each of the following methods the HOA for the optional named argument B<data>.

=head2 chiprob_test

 ($chi_value, $df, $count, $p_value) = $fri->chiprob_test(data => HOA, correct_ties => 1);

Performs the ANOVA and returns the chi-square value, its degrees-of-freedom, the total number of observations, and associated probability value (or only the latter if called in scalar context). Default value of optional argument B<correct_ties> is 1.

=cut

sub chiprob_test {
    my ( $self, %args ) = @_;
    my $data = $args{'data'} ? delete $args{'data'} : $self->get_hoa(%args);
    my $n_bt = scalar keys %{$data};
    my $n_wt = $self->equal_n( data => $data );
    croak
'Need to have equal numbers of observations greater than 1 per two or more variables for chiprob_test'
      if not $n_wt
      or $n_wt == 1
      or $n_bt < 2;
    my $chi =
      _definitely_no( $args{'correct_ties'} )
      ? _chi_ig_ties( $n_bt, $n_wt,
        scalar Statistics::Data::Rank->sumsq_ranks_within( data => $data ) )
      : _chi_by_ties( $n_bt, $n_wt,
        Statistics::Data::Rank->sumsq_ranks_within( data => $data ) );
    my $df = $n_bt - 1;
    my $p_value = chdtrc( $df, $chi );    # Math::Cephes fn
    return wantarray ? ( $chi, $df, ( $n_bt * $n_wt ), $p_value ) : $p_value;
}

=head2 chiprob_str

 $str = $fri->chiprob_str(data => HOA, correct_ties => 1);

Performs the same test as for L<chiprob_test|Statistics::ANOVA::Friedman/chiprob_test> but returns not an array but a string of the conventional reporting form, e.g., chi^2(df, N = total observations) = chi_value, p = p_value.

=cut

sub chiprob_str {
    my ( $self, %args ) = @_;
    my ( $chi_value, $df, $count, $p_value ) = $self->chiprob_test(%args);
    return "chi^2($df, N = $count) = $chi_value, p = $p_value";
}

=head2 fprob_test

 ($f_value, $df_b, $df_w, $p_value) = $fri->fprob_test(data => HOA);
 $p_value = $fri->fprob_test(data => HOA);

Performs the same test as above but transforms the chi-value into an I<F>-distributed value, returning this I<F>-equivalent value, between and within groups degrees-of-freedom, and then the associated probability off the I<F>-distribution (or only the latter if called in scalar context). Default value of optional argument B<correct_ties> is 1. This method has not been tested against sample data as yet.

=cut

sub fprob_test {
    my ( $self, %args ) = @_;
    my $data = $args{'data'} ? delete $args{'data'} : $self->get_hoa(%args);
    my $n_bt = scalar keys %{$data};
    my $n_wt = $self->equal_n( data => $data );
    croak
'Need to have equal numbers of observations greater than 1 per two or more variables for fprob_test'
      if not $n_wt
      or $n_wt == 1
      or $n_bt < 2;
    my $chi =
      _definitely_no( $args{'correct_ties'} )
      ? _chi_ig_ties( $n_bt, $n_wt,
        scalar Statistics::Data::Rank->sumsq_ranks_within( data => $data ) )
      : _chi_by_ties( $n_bt, $n_wt,
        Statistics::Data::Rank->sumsq_ranks_within( data => $data ) );
    my $f_value = ( ( $n_wt - 1 ) * $chi ) / ( $n_wt * ( $n_bt - 1 ) - $chi );
    my $df_b    = $n_bt - 1;
    my $df_w    = ( $n_wt - 1 ) * ($df_b);
    my $p_value = fdtrc( $df_b, $df_w, $f_value );    # Math::Cephes fn
    return wantarray ? ( $f_value, $df_b, $df_w, $p_value ) : $p_value;
}

=head2 fprob_str

 $str = $fri->chiprob_str(data => HOA, correct_ties => 1);

Performs the same test as for L<fprob_test|Statistics::ANOVA::Friedman/fprob_test> but returns not an array but a string of the conventional reporting form, e.g., F(df_b, df_w) = f_value, p = p_value.

=cut

sub fprob_str {
    my ( $self, %args ) = @_;
    my ( $f_value, $df_b, $df_w, $p_value ) = $self->fprob_test(%args);
    return "F($df_b, $df_w) = $f_value, p = $p_value";
}

sub _chi_ig_ties {
    my ( $c, $n, $sumsq ) = @_;
    return ( 12 / ( $n * $c * ( $c + 1 ) ) ) * $sumsq - 3 * $n * ( $c + 1 );
}

sub _chi_by_ties {
    my ( $c, $n, $sumsq, $xtied ) = @_;
    my $num = 12 * $sumsq - 3 * $n**2 * $c * ( $c + 1 )**2;
    my $sum = sum0( map { _sumcubes($_) - $c } values %{$xtied} );
    my $den = $n * $c * ( $c + 1 ) - ( 1 / ( $c - 1 ) ) * $sum;
    my $chi = $num / $den;
    return $chi;
}

sub _sumcubes {
    my @v = @_;
    return sum0( map { $_**3 } @{ shift @v } );
}

sub _definitely_no {
    my @v = @_;
    return ( defined $v[0] and $v[0] == 0 ) ? 1 : 0;
}

=head1 DEPENDENCIES

L<List::AllUtils|List::AllUtils> : used for summing.

L<Math::Cephes|Math::Cephes> : used for probability functions.

L<Statistics::Data|Statistics::Data> : used as base.

L<Statistics::Data::Rank|Statistics::Data::Rank> : used to calculate the dependent sum-square of ranks. See this module for retrieving the actual arrays of ranks and sum-squares.

=head1 DIAGNOSTICS

=over 4

=item Need to have equal numbers of observations greater than 1 per two or variables for chiprob_test

C<croak>ed if there are not equal numbers of numerical values in each given variable, and if there are not at least two variables. Similarly for fprob_test.

=back

=head1 REFERENCES

Hollander, M., & Wolfe, D. A. (1999). I<Nonparametric statistical methods>. New York, NY, US: Wiley.

Rice, J. A. (1995). I<Mathematical statistics and data analysis>. Belmont, CA, US: Duxbury.

Sarantakos, S. (1993). I<Social research>. Melbourne, Australia: MacMillan.

Siegal, S. (1956). I<Nonparametric statistics for the behavioral sciences>. New York, NY, US: McGraw-Hill

=head1 AUTHOR

Roderick Garton, C<< <rgarton at cpan.org> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-statistics-anova-friedman-0.02 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Statistics-ANOVA-Friedman-0.02>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::ANOVA::Friedman

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-ANOVA-Friedman-0.02>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Statistics-ANOVA-Friedman-0.02>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Statistics-ANOVA-Friedman-0.02>

=item * Search CPAN

L<http://search.cpan.org/dist/Statistics-ANOVA-Friedman-0.02/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2015-2017 Roderick Garton.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;    # End of Statistics::ANOVA::Friedman

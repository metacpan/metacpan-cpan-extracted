package Statistics::ANOVA::KW;

use 5.006;
use strict;
use warnings FATAL => 'all';
use base qw(Statistics::Data);
use Carp qw(croak);
use List::AllUtils qw(sum0);
use Math::Cephes qw(:dists);
use Statistics::Data::Rank;
use Statistics::Lite qw(mean);
$Statistics::ANOVA::KW::VERSION = '0.01';

=head1 NAME

Statistics::ANOVA::KW - Kruskall-Wallis statistics and test (nonparametric independent analysis of variance by ranks for nominally grouped data)

=head1 VERSION

This is documentation for B<Version 0.01> of Statistics::ANOVA::KW.

=head1 SYNOPSIS

 use Statistics::ANOVA::KW;
 my $kw = Statistics::ANOVA::KW->new();
 $kw->load({1 => [2, 4, 6], 2 => [3, 3, 12], 3 => [5, 7, 11, 16]});
 my $h_value = $kw->h_value(); # default used to correct for ties
 my $p_value = $kw->chiprob_test(); # H taken as chi^2 distributed
 my ($h_value, $df, $count, $p_value_by_chi, $phi) = $kw->chiprob_test(); # same as above, called in array context
 my ($f_value, $df_b, $df_w, $p_value_by_f, $omega_sq) = $kw->fprob_test(); # F-equivalent value tests

 # or without pre-loading, and specify correct_ties as well:
 $h_value = $kw->h_value(data => {1 => [2, 4, 6], 2 => [5, 3, 12]}, correct_ties => 1);
 # or test only a subset of the loaded data:
 $h_value = $kw->h_value(lab => [1, 3]);

=head1 DESCRIPTION

Performs calculations for the Kruskal-Wallis one-way nonparametric analysis of variance by ranks. This is for (at least) ordinal-level measurements of two or more samples of a nominal/categorical variable with equality of variances across the samples. The test is unreliable for small number of observations per sample (conventionally, all samples should have more than five observations). See L<REFERENCES|Statistics::ANOVA::KW/REFERENCES> for more information, and discussions of the assumptions/interpretations, and pros/cons, of the test at L<laerd statistics|https://statistics.laerd.com/spss-tutorials/kruskal-wallis-h-test-using-spss-statistics.php> (pro) and L<biostathandbook|http://www.biostathandbook.com/kruskalwallis.html> (con). Note that the Kruskall-Wallis test is often described as a test for I<three> or more samples, in contrast to the Mann-Whitney test, which is restricted to two samples, but KW can also be used with only two samples: the absolute value of the I<z>-value from a Mann-Whitney test equals the square-root of the KW statistic for two factors.

Data-loading and retrieval are as provided in L<Statistics::Data|Statistics::Data>, on which this module's class object is C<base>d, so its other methods are available here.

Return values are tested on installation against published examples and output from other software (e.g., SPSS). 

=head2 new

 $kw = Statistics::ANOVA::KW->new();

New object for accessing methods and storing results. This "isa" Statistics::Data object.

=head2 load, add, unload

 $kw->load('a' => [1, 4, 3.2], 'b' => [6.5, 6.5, 9], 'c' => [3, 7, 4.4]);

The given data can now be used by any of the following methods. This is inherited from L<Statistics::Data|Statistics::Data>, and all its other methods are available here via the class object. Only passing of data as a hash of arrays (HOA) is supported for now. Once loaded, subsets of the loaded data can be tested by passing their names (or labels) in a referenced array to the argument B<lab> in the following methods (as supported by L<Statistics::Data|Statistics::Data/get_hoa_by_lab_numonly_indep>). Once loaded, any non-numeric values in the samples are culled ahead of running the following methods.

Alternatively, without pre-loading the data, directly give the following methods the HOA of data as the value for the optional named argument B<data>.

=cut

=head2 h_value

 $h_value = $kw->h_value(data => \%data, correct_ties => 1);
 $h_value = $kw->h_value(); # assuming data have already been loaded, & default of TRUE for correct_ties

Returns the Kruskall-Wallis I<H> statistic.

=cut

sub h_value {
    my ( $self, %args ) = ( shift, @_ );
    my $data =
      $args{'data'}
      ? delete $args{'data'}
      : $self->get_hoa_by_lab_numonly_indep(%args);
    my $correct_ties = defined $args{'correct_ties'}
      and $args{'correct_ties'} == 0 ? 0 : 1;
    return ( _kw_stats( $data, $correct_ties ) )[0];
}

=head2 chiprob_test

 ($chi_value, $df, $count, $p_value, $phi) = $kw->chiprob_test(data => HOA, correct_ties => 1); # H as chi-square
 $p_value = $kw->chiprob_test(data => HOA, correct_ties => 1);
 $p_value = $kw->chiprob_test(); # assuming data have already been loaded, & default of TRUE for correct_ties

Performs the ANOVA and, assuming I<chi>-square distribution of the Kruskall-Wallis I<H> value, returns its value, its degrees-of-freedom, the total number of observations (I<N>), its I<chi>-square probability value, and I<phi>-coefficient as an estimate of effect-size ( = square-root of  (I<chi>-square divided by I<N>) ). Returns only the I<p>-value if called in scalar context. Default value of optional argument B<correct_ties> is 1.

=cut

sub chiprob_test {
    my ( $self, %args ) = ( shift, @_ );
    my $data =
      $args{'data'}
      ? delete $args{'data'}
      : $self->get_hoa_by_lab_numonly_indep(%args);
    my $correct_ties = defined $args{'correct_ties'}
      and $args{'correct_ties'} == 0 ? 0 : 1;
    my ( $chi, $df_b, $count ) = _kw_stats( $data, $correct_ties );
    my $p_value = chdtrc( $df_b, $chi );    # Math::Cephes fn
    return
      wantarray
      ? ( $chi, $df_b, $count, $p_value, sqrt( $chi / $count ) )
      : $p_value;
}

=head2 chiprob_str

 $str = $kw->chiprob_str(data => HOA, correct_ties => 1);
 $str = $kw->chiprob_str(); # assuming data have already been loaded, & default of TRUE for correct_ties

Performs the same test as for L<chiprob_test|Statistics::ANOVA::KW/chiprob_test> but returns not an array but a string of the conventional reporting form, e.g., chi^2(df, N = total observations) = chi_value, p = p_value.

=cut

sub chiprob_str {
    my ( $self, %args ) = ( shift, @_ );
    my ( $chi_value, $df, $count, $p_value, $phi ) = $self->chiprob_test(%args);
    return "chi^2($df, N = $count) = $chi_value, p = $p_value, phi = $phi";
}

=head2 fprob_test

 ($f_value, $df_b, $df_w, $p_value, $es_omega) = $kw->fprob_test(data => HOA, correct_ties => BOOL);
 $p_value = $kw->fprob_test(data => HOA, correct_ties => BOOL);
 $p_value = $kw->fprob_test(); # assuming data have already been loaded, & default of TRUE for correct_ties

Performs the same test as above but transforms the I<chi>-square value into an I<F>-distributed value, returning an array comprised of (1) this I<F>-estimate value, its (2) between- and (3) within-groups degrees-of-freedom, (4) the associated probability of the value per the I<F>-distribution, and (5) an estimate of the effect-size statistic, (partial) I<omega>-squared. The latter is returned only if L<Statistics::ANOVA::EffectSize|Statistics::ANOVA::EffectSize> is installed and available. Called in scalar context, only the I<F>-estimated I<p>-value is returned. The default value of the optional argument B<correct_ties> is 1. This method has not been tested against sample/published data (not being provided in the usual software packages).

=cut

sub fprob_test {
    my ( $self, %args ) = ( shift, @_ );
    my $data =
      $args{'data'}
      ? delete $args{'data'}
      : $self->get_hoa_by_lab_numonly_indep(%args);
    my $correct_ties = defined $args{'correct_ties'}
      and $args{'correct_ties'} == 0 ? 0 : 1;
    my ( $f_value, $df_b, $df_w ) = _f_stats( $data, $correct_ties );
    my $p_value = fdtrc( $df_b, $df_w, $f_value );    # Math::Cephes fn
    return $p_value if !wantarray;

    my $es_omega;
    eval { require Statistics::ANOVA::EffectSize; };
    if ( !$@ ) {
        $es_omega = Statistics::ANOVA::EffectSize->omega_sq_partial_by_f(
            f_value => $f_value,
            df_b    => $df_b,
            df_w    => $df_w
        );
    }
    return ( $f_value, $df_b, $df_w, $p_value, $es_omega );
}

=head2 fprob_str

 $str = $kw->chiprob_str(data => HOA, correct_ties => BOOL);
 $str = $kw->chiprob_str(); # assuming data have already been loaded, using default of TRUE for correct_ties

Performs the same test as for L<fprob_test|Statistics::ANOVA::KW/fprob_test> but returns not an array but a string of the conventional reporting form, e.g., F(df_b, df_w) = f_value, p = p_value (and also, then, an estimate of partial I<omega>-squared, if available, see above).

=cut

sub fprob_str {
    my ( $self, %args ) = ( shift, @_ );
    my ( $f_value, $df_b, $df_w, $p_value, $es_omega ) =
      $self->fprob_test(%args);
    my $str = "F($df_b, $df_w) = $f_value, p = $p_value";
    if ( defined $es_omega ) {
        $str .= ', est_omega^2_p = ' . $es_omega;
    }
    return $str;
}

sub _kw_stats {
    my ( $data, $correct_ties ) = @_;
    my ( $ranks_href, $ties_aref, $gn, $ties_var ) =
      Statistics::Data::Rank->ranks_between( data => $data );
    my $num = sum0(
        map {
            scalar @{ $ranks_href->{$_} } *
              ( mean( @{ $ranks_href->{$_} } ) - ( ( $gn + 1 ) / 2 ) )**2
        } keys %{$ranks_href}
    );
    my $h = 12 / ( $gn * ( $gn + 1 ) ) * $num;

    # correction for ties:
    $h /= ( 1 - ( $ties_var / ( $gn**3 - $gn ) ) )
      unless defined $correct_ties and not $correct_ties;
    return ( $h, ( scalar keys %{$ranks_href} ) - 1, $gn ); # H, df, and grand N
}

sub _f_stats {
    my ( $data, $correct_ties ) = @_;
    my ( $h, $df_b, $n ) = _kw_stats( $data, $correct_ties );
    my $df_w  = sum0( map { scalar @{ $data->{$_} } - 1 } keys %{$data} );
    my $n_bt  = scalar keys( %{$data} );
    my $f_val = ( $h / ( $n_bt - 1 ) ) / ( ( $n - 1 - $h ) / ( $n - $n_bt ) );
    return ( $f_val, $df_b, $df_w );
}

=head1 DEPENDENCIES

L<List::AllUtils|List::AllUtils> : used for summing.

L<Math::Cephes|Math::Cephes> : used for probability functions.

L<Statistics::Data|Statistics::Data> : used as base.

L<Statistics::Data::Rank|Statistics::Data::Rank> : used to calculate between-group sum-of ranks.

=head1 REFERENCES

Hollander, M., & Wolfe, D. A. (1999). I<Nonparametric statistical methods>. New York, NY, US: Wiley.

Rice, J. A. (1995). I<Mathematical statistics and data analysis>. Belmont, CA, US: Duxbury.

Sarantakos, S. (1993). I<Social research>. Melbourne, Australia: MacMillan.

Siegal, S. (1956). I<Nonparametric statistics for the behavioral sciences>. New York, NY, US: McGraw-Hill

=head1 SEE ALSO

L<Statistics::ANOVA::JT|Statistics::ANOVA::JT> : Also a nonparametric ANOVA by ranks for independent samples, but where the ordinality of the numerical labels of the sample names (the order of the groups) is taken into account.

L<Statistics::KruskallWallis|Statistics::KruskallWallis> : Returns the I<H>-value and its I<chi>-square I<p>-value (only), and implements the Newman-Keuls test for pairwise comparison.

=head1 AUTHOR

Roderick Garton, C<< <rgarton at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-statistics-anova-kw-0.01 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Statistics-ANOVA-KW-0.01>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::ANOVA::KW

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-ANOVA-KW-0.01>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Statistics-ANOVA-KW-0.01>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Statistics-ANOVA-KW-0.01>

=item * Search CPAN

L<http://search.cpan.org/dist/Statistics-ANOVA-KW-0.01/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Roderick Garton.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1;    # End of Statistics::ANOVA::KW

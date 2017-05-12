package Statistics::ANOVA::Compare;

use 5.006;
use strict;
use warnings FATAL => 'all';
use base qw(Statistics::Data);
use Algorithm::Combinatorics qw(combinations);
use Carp qw(carp croak);
use List::AllUtils qw(sum0);
use Math::Cephes qw(:dists);
use Statistics::Lite qw(count mean variance);
$Statistics::ANOVA::Compare::VERSION = '0.01';

=head1 NAME

Statistics::ANOVA::Compare - Comparison procedures for ANOVA

=head1 VERSION

This is documentation for Version 0.01, released February 2015.

The methods here reproduce those previously incorporated as part of L<Statistics::ANOVA|Statistics::ANOVA> itself.

=head1 SYNOPSIS

 use Statistics::ANOVA::Compare;
 my $cmp = Statistics::ANOVA::Compare->new();
 $cmp->load(HOA); # hash of arefs preferably
 my $href = $cmp->run(parametric => BOOL, independent => BOOL);

=head1 SUBROUTINES/METHODS

=head2 new

 $cmp = Statistics::ANOVA::Compare->new();

New object for accessing methods and storing results. This "isa" Statistics::Data object.

=head2 load, add, unload

 $cmp->load(1 => [1, 4], 2 => [3, 7]);

The given data can now be used by any of the following methods. This is inherited from L<Statistics::Data|Statistics::Data>, and all its other methods are available here via the class object. Only passing of data as a hash of arrays (HOA) is supported for now. Alternatively, give each of the following methods the HOA for the optional named argument B<data>.

=head2 run

Performs all possible pairwise comparisons, with Bonferroni control of experiment-wise error-rate. The particular tests depend on whether or not you want parametric (default) or nonparametric tests, and if the observations have been made independently (between groups, the default) or by repeated measures.

If C<parametric> =E<gt> 1 (default), it firstly checks if the variances are unequal> (I<p> E<lt> .05) by the L<O'Brien method|Statistics::ANOVA/obrien>, and runs L<indep_param_by_contrasts|Statistics::ANOVA::Compare/indep_param_by_contrasts>. If the variances are equal, runs L<param_pairwise_eqvar|Statistics::ANOVA::Compare/param_pairwise_eqvar>. Alternatively, you get unadjusted use of the mean-square error, with no prior test of equality-of-variances, if the parameter C<adjust_e> =E<gt> 0. On the other hand, force the procedure to use separate variances, as if unequal variances, if C<adjust_e> =E<gt> 2.

If C<parametric> =E<gt> 1, performs non-parametric pairwise comparison. This derives the I<z>-value and associated I<p>-value for the standardized (a) Wilcoxon (between-groups) sum-of-ranks if C<independent> =E<gt> 1 (B<Dwass-Steel> procedure), or (b) (merely) paired I<t>-tests (TO DO: Friedman-type (within-groups) sum-of-ranks) if C<independent> =E<gt> 0.

Nominality is always assumed; there is no accounting for ordinality of the variables.

The I<p>-value is 2-tailed, by default, unless otherwise specified, as above.  If the value of the argument C<adjust_p> equals 1, then the probability values themselves will be adjusted according to the number of comparisons, alpha will remain as given or at .05. The correction is:

=for html <p>&nbsp;&nbsp;&nbsp; <i>p</i>' = 1 &ndash; (1 &ndash; <i>p</i>)<sup>N</sup></p>

where I<p> is the probability returned by the relevant comparison procedure, and I<N> is the number of pairwise comparisons performed.

By default, returns a hashref of hashrefs, the outer hash keyed by the pairs compared (as a comma-separated string), each with a hashref with keys named C<t_value>, C<p_value>, C<df>, C<sig> (= 1 or 0 depending on its being below or greater than/equal to C<alpha>).

Alternatively, if the value of C<str> =E<gt> 1, you just get back a referenced array of strings that describe the results, e.g., G1 - G2: t(39) = 2.378, 2p = 0.0224.

Give a value of 1 to C<dump> to automatically print these strings to STDOUT. (Distinct from earlier versions, there is no default dump to STDOUT of the results.)

The output strings are appended with an asterisk if the logical value of the optional attribute C<flag> equals 1 and the C<p_value> is less than the Bonferroni-adjusted alpha level. This alpha level, relative to the given or default alpha of .05, for the number of paired comparisons, is printed at the end of the list.

An alternative (actually, legacy from earlier version) is to use I<t>-tests, rather than I<F>-tests, and this you get if the argument C<use_t> =E<gt> 1. The module uses Perl's Statistics I<t>-test modules for this purpose, with no accounting for the variance issue.

=cut

sub run {
   my ($self, %args) = @_;
    foreach (qw/independent parametric nominal adjust_e/)
    {    # 'nominal' an option not yet implemented
        $args{$_} = 1 if !defined $args{$_};
    }
    my (
        $data,    $s_value,   $a3,      $a4,   $p_value, $cmp_fn,    $p_str,   $flag, $flag_str, $ms_w,
        $alpha,   @all_pairs, @strings, %res
    ) = ();
    $args{'tails'} ||= 2;

# Define the data and which routine to use based on values of independent and parametric:
    if ( $args{'independent'} ) {
        $data = $self->get_hoa_by_lab_numonly_indep(%args);
          croak 'Not enough variables, if any, in the data for performing ANOVA'
          if scalar( keys( %{$data} ) ) <= 1;
        if ( $args{'parametric'} ) {
            if ( !$args{'use_t'} ) {
                require Statistics::ANOVA;
                my $aov = Statistics::ANOVA->new;
                $aov->share($self);
                my %res = $aov->obrien(%args);
                my $eq_var = $res{'p_value'} < .05 ? 0 : 1;
                %res = $aov->anova(independent => 1, parametric => 1, ordinal => 0);
                $ms_w = $res{'ms_w'};
                if (defined $args{'adjust_e'} and $args{'adjust_e'} == 0) {
                    $cmp_fn = \&_cmp_indep_param_cat_by_poolederror;
                }
                else {
                   if (!$eq_var || $args{'adjust_e'}) {
                        $cmp_fn = \&_cmp_indep_param_cat_by_contrasts;
                    }
                    else {
                        $cmp_fn = \&_cmp_indep_param_cat_by_poolederror;
                    } 
                }
            }
            else {    # legacy offer:
                require Statistics::TTest;
                my $ttest = Statistics::TTest->new();
                $cmp_fn = sub {
                    my $data_pairs = shift;
                    $ttest->load_data( $data_pairs->[0]->[1],
                        $data_pairs->[1]->[1] );
                    $p_value = $ttest->{'t_prob'}
                      ; # returns the 2-tailed p_value via Statistics::Distributions
                    $p_value /= 2 if $args{'tails'} == 1;
                    return ( $ttest->t_statistic, $p_value, $ttest->df );
                };
            }
        }
        else {
 #$cmp_fn = !$args{'ordinal'} ? \&_cmp_indep_dfree_cat : \&_cmp_indep_dfree_ord;
            $cmp_fn = \&_cmp_indep_dfree_cat;
        }
    }
    else {
        $data = $self->get_hoa_by_lab_numonly_across(%args);
        my $n_wt = $self->equal_n( data => $data );
        croak
'Number of observations per variable need to be equal and greater than one for repeated measures ANOVA'
          if !$n_wt or $n_wt == 1;
        if ( $args{'parametric'} ) {
            $cmp_fn = \&_cmp_rmdep_param_cat;
        }
        else {
            carp
'Non-parametric multi-comparison procedure for dependent/repeated measures is not implemented';
        }
    }

    @all_pairs =
      combinations( [ keys( %{$data} ) ], 2 );    # Algorithm::Combinatorics fn
    $alpha = $args{'alpha'} || .05;
    $alpha /= scalar(@all_pairs)
      if !$args{'adjust_p'};    # divide by number of comparisons

    # Compare each pair:
    foreach my $pairs (@all_pairs) {
        $pairs = [ sort { $a cmp $b } @{$pairs} ];
        ( $s_value, $p_value, $a3, $a4 ) = $cmp_fn->(
            [
                [ $pairs->[0], $data->{ $pairs->[0] } ],
                [ $pairs->[1], $data->{ $pairs->[1] } ]
            ],
            ms_w => $ms_w,
            %args,
        );
        $p_value = _pcorrect( $p_value, scalar(@all_pairs) )
          if $args{'adjust_p'};
        $a3 = _precisioned( $args{'precision_s'}, $a3 );    # degrees-of-freedom
        $s_value = _precisioned( $args{'precision_s'}, $s_value );
        $p_value = _precisioned( $args{'precision_p'}, $p_value );
        $p_str = $args{'tails'} == 1 ? '1p' : '2p';
        $flag  = $p_value < $alpha   ? 1    : 0;
        $flag_str = $args{'flag'} ? $flag ? ' *' : '' : '';

        if ( $args{'parametric'} ) {
            $res{"$pairs->[0],$pairs->[1]"} = {
                t_value => $s_value,
                p_value => $p_value,
                df      => $a3,
                flag    => $flag
            };
            push @strings,
"($pairs->[0] - $pairs->[1]), t($a3) = $s_value, $p_str = $p_value"
              . $flag_str;
        }
        else {
            $res{"$pairs->[0],$pairs->[1]"} = {
                z_value => $s_value,
                p_value => $p_value,
                s_value => $a3,
                flag    => $flag
            };
            push @strings,
              "($pairs->[0] - $pairs->[1]), Z(W) = $s_value, $p_str = $p_value"
              . $flag_str;
        }
    }    # end loop

    if ( $args{'dump'} ) {
        print "$_\n" foreach @strings;
        print "Alpha = $alpha\n";
    }

    return $args{'str'} ? \@strings : \%res;
}

=head2 indep_param_by_contrasts

TO DO: use run() for now

Performs parametric pairwise comparison by I<F>-tests on each possible pair of observations, with respect to the value of C<independent>. This assumes that the variances are unequal, and uses the variance of each sample in the pair in the error-term of the I<F>-value, and the denominator degrees-of-freedom is adjusted accordingly. 

=head2 indep_param_by_mse

TO DO: use run() for now

Performs parametric pairwise comparison by I<F>-tests on each possible pair of observations, with respect to the value of C<independent>. This assumes that the variances are equal, so that the mean-square error ($aov-E<gt>{'ms_w'}) is used in the error-term of the I<F>-value. 

=cut

sub _cmp_indep_param_cat_by_contrasts {
    my ( $data_pairs, %args ) = @_;
    my @nn = (
        count( @{ $data_pairs->[0]->[1] } ),
        count( @{ $data_pairs->[1]->[1] } )
    );
    my @uu = ( mean( @{ $data_pairs->[0]->[1] } ),
        mean( @{ $data_pairs->[1]->[1] } ) );
    my @cc = ( 1, -1 )
      ;   # contrast coefficients for pairwise comparison of means (ui - uj = 0)
    my ( $f_value, $df_w ) = ();
    my $lu = sum0( map { $cc[$_] * $uu[$_] } ( 0, 1 ) )
      ;    # estimate of linear combo of means; s/= zero if no diff.
    my $ss_cc = sum0( map { $cc[$_]**2 / $nn[$_] } ( 0, 1 ) )
      ;    # weighted sum of squared contrast coefficients

    ( $f_value, $df_w ) =
              _var_by_contrasts( $data_pairs, $lu, $ss_cc, \@nn, \@cc );
    my $p_value =
      fdtrc( 1, $df_w, $f_value );    # s/be compared to alpha/nContrasts
    return ( $f_value, $p_value, 1, $df_w );
}

sub _cmp_indep_param_cat_by_poolederror {
    my ( $data_pairs, %args ) = @_;
    my @nn = (
        count( @{ $data_pairs->[0]->[1] } ),
        count( @{ $data_pairs->[1]->[1] } )
    );
    my @uu = ( mean( @{ $data_pairs->[0]->[1] } ),
        mean( @{ $data_pairs->[1]->[1] } ) );
    my @cc = ( 1, -1 )
      ;   # contrast coefficients for pairwise comparison of means (ui - uj = 0)
    my $lu = sum0( map { $cc[$_] * $uu[$_] } ( 0, 1 ) )
      ;    # estimate of linear combo of means; s/= zero if no diff.
    my $ss_cc = sum0( map { $cc[$_]**2 / $nn[$_] } ( 0, 1 ) )
      ;    # weighted sum of squared contrast coefficients
    # use the pooled error-term (MSe):
    my $f_value = $lu**2 / ( $ss_cc * $args{'ms_w'} )
      ;    # Maxwell & Delaney Eq 4.37 (p. 176); assumes equal variances
    ##$f_value = ( $nn[0] * $nn[1] * ( $uu[0] - $uu[1])**2 ) / ( ( $nn[0] + $nn[1] ) * $self->{'_stat'}->{'ms_w'} );
    my $df_w = ( $nn[0] + $nn[1] - 2 );
    my $p_value =
      fdtrc( 1, $df_w, $f_value );    # s/be compared to alpha/nContrasts
    return ( $f_value, $p_value, 1, $df_w );
}

sub _var_by_contrasts {   # permits unequal variances; sep. error terms/contrast
    my ( $data_pairs, $lu, $ss_cc, $nn, $cc ) = @_;

    #$cc ||= [1, -1];
    my $ss_u = $lu**2 / $ss_cc;
    my @vv   = (
        variance( @{ $data_pairs->[0]->[1] } ),
        variance( @{ $data_pairs->[1]->[1] } )
    );
    my $den_a = sum0( map { ( $cc->[$_]**2 / $nn->[$_] ) * $vv[$_] } ( 0, 1 ) );
    my $denom = $den_a / $ss_cc;
    my $f_value = $ss_u / $denom;    # Maxwell & Delaney Eq. 5.10 (p. 180)
    my $df_n = sum0( map { ( $cc->[$_]**2 * $vv[$_] / $nn->[$_] ) } ( 0, 1 ) );
    my $df_d = sum0(
        map { ( $cc->[$_]**2 * $vv[$_] / $nn->[$_] )**2 / ( $nn->[$_] - 1 ) }
          ( 0, 1 ) );
    my $df_w = $df_n**2 / $df_d;
    return ( $f_value, $df_w );
}

sub _cmp_rmdep_param_cat {  # not completed - only use Dependant t-test for now:
    my ( $data_pairs, %args ) = @_;
    require Statistics::DependantTTest;
    my $ttest = Statistics::DependantTTest->new();
    $ttest->load_data( $data_pairs->[0]->[0], @{ $data_pairs->[0]->[1] } );
    $ttest->load_data( $data_pairs->[1]->[0], @{ $data_pairs->[1]->[1] } );
    my ( $s_value, $df ) =
      $ttest->perform_t_test( $data_pairs->[0]->[0], $data_pairs->[1]->[0] );
    my $p_value =
      stdtr( $df, -1 * abs($s_value) );   # Math::Cephes - left 1-tailed p_value
    $p_value *= 2 unless $args{'tails'} == 1;
    return ( $s_value, $p_value, $df );
}

sub _cmp_indep_dfree_cat {                # Dwass-Steel procedure
    my ( $data_pairs, %args ) = @_;
    my ( $n1,         $n2 )   = (
        count( @{ $data_pairs->[0]->[1] } ),
        count( @{ $data_pairs->[1]->[1] } )
    );                                    # Ns/variable
    my $nm =
      $data_pairs->[1]->[0]; # arbitrarily use second variable as reference data
    require Statistics::Data::Rank;
    my ( $ranks_href, $xtied, $gn, $ties_var ) =
      Statistics::Data::Rank->ranks_between( data => _aref2href($data_pairs) )
      ;                      # get joint ranks
    my $sum = sum0( @{ $ranks_href->{$nm} } )
      ;    # calc. sum-of-ranks for (arbitrarily) second member of pair
    my $exp = ( $n2 * ( $gn + 1 ) ) / 2;    # expected value
    my $tie = sum0( map { ( $_ - 1 ) * $_ * ( $_ + 1 ) } @{$xtied} );
    my $var =
      ( ( $n1 * $n2 ) / 24 ) *
      ( ( $gn + 1 - ( $tie / ( ($gn) * ( $gn - 1 ) ) ) ) );    # variance
    my $z_value = ( $sum - $exp ) / sqrt($var);     # standardized sum-of-ranks
    my $p_value = ( 1 - ndtr( abs($z_value) ) );    # Math::Cephes fn
    $p_value *= 2 unless $args{'tails'} == 1;
    return ( $z_value, $p_value, $sum );
}

sub _aref2href {
    my $aref = shift;
    my %hash = ();
    $aref = [$aref] if !ref $aref->[0];
    foreach ( @{$aref} ) {
        if ( ref $_->[1] ) {
            $hash{ $_->[0] } = $_->[1];
        }
        else {
            my $name = shift( @{$_} );
            $hash{$name} = [ @{$_} ];
        }
    }
    return \%hash;
}

sub _is_significant {
    my ( $pvalue, $alpha, $exp_tail ) = @_;
    $exp_tail ||= 2;
    if ( ref $alpha ) {

        # Assume aref:
        if ( $pvalue > $alpha->[0] ) {
            if ($exp_tail) {

            }
        }
    }
    return;
}

sub _precisioned {
    return $_[0]
      ? sprintf( '%.' . $_[0] . 'f', $_[1] )
      : ( defined $_[1] ? $_[1] : q{} );    # don't lose any zero
}

=head1 AUTHOR

Roderick Garton, C<< <rgarton at cpan.org> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-statistics-anova-compare-0.01 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Statistics-ANOVA-Compare-0.01>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::ANOVA::Compare


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-ANOVA-Compare-0.01>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Statistics-ANOVA-Compare-0.01>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Statistics-ANOVA-Compare-0.01>

=item * Search CPAN

L<http://search.cpan.org/dist/Statistics-ANOVA-Compare-0.01/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Roderick Garton.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; # End of Statistics::ANOVA::Compare

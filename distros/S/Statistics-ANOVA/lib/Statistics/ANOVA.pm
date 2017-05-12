package Statistics::ANOVA;
use 5.008008;
use strict;
use warnings;
use base qw(Statistics::Data);
use Carp qw(croak carp);
use List::AllUtils qw(any sum0);
use Math::Cephes qw(:dists);
use Readonly;
use Scalar::Util qw(looks_like_number);
use Statistics::Data::Rank;
use Statistics::Lite qw(count max mean min sum stddev variance);

$Statistics::ANOVA::VERSION = '0.13';
Readonly my $ALPHA_DEFAULT => .05;

=head1 NAME

Statistics::ANOVA - Parametric and nonparametric 1-way analyses of variance for means-comparison and clustering per differences/trends over independent or repeated measures of variables or levels

=head1 VERSION

This is documentation for B<Version 0.13> of Statistics::ANOVA.

=head1 SYNOPSIS

 use Statistics::ANOVA 0.13;
 my $aov = Statistics::ANOVA->new();

 # Some data:
 my @gp1 = (qw/8 7 11 14 9/);
 my @gp2 = (qw/11 9 8 11 13/);
 my $res; # each anova method returns hash of F-value, p-value, ss_b, ss_w, etc., where relevant

 # Load the data:
 $aov->load_data({1 => \@gp1, 2 => \@gp2}); # NB: hashref
 # or $aov->load_data([ [1, \@gp1], [2, \@gp2] ]);
 # or $aov->load_data([ [1, @gp1], [2, @gp2] ]);
 my @gp3 = (qw/7 13 12 8 10/);
 $aov->add_data(3 => \@gp3);

 #  Test equality of variances before omnibus comparison:
 %res = $aov->obrien()->dump(title => 'O\'Brien\'s test of equality of variances');
 %res = $aov->levene()->dump(title => 'Levene\'s test of equality of variances');

 # 1.10 Independent nominal variables ANOVA - parametric testing:
 %res = $aov->anova(independent => 1, parametric => 1)->dump(title => 'Indep. variables parametric ANOVA', eta_squared => 1, omega_squared => 1);
 # 1.11 Independent nominal variables (groups) ANOVA - NON-parametric:
 %res = $aov->anova(independent => 1, parametric => 0)->dump(title => 'Kruskal-Wallis test');

 #  or if independent AND ordered variables (levels): test linear/non-linear trend:
 # 1.20 Independent ordinal variables ANOVA - parametric testing:
 %res = $aov->anova(independent => 1, parametric => 1, ordinal => 1)->dump(title => 'Indep. variables parametric ANOVA: Linear trend');
 %res = $aov->anova(independent => 1, parametric => 1, ordinal => 2)->dump(title => 'Indep. variables parametric ANOVA: Non-linear trend');
 # 1.21 Independent ordinal variables ANOVA - NONparametric testing:
 %res = $aov->anova(independent => 1, parametric => 0, ordinal => 1)->dump(title => 'Jonckheere-Terpstra test');
 
 #  If they are repeated measures:
 # 2.10 Dependent nominal variables ANOVA - parametric testing:
 %res = $aov->anova(independent => 0, parametric => 1)->dump(title => 'Dependent variables ANOVA');
 # 2.11 Dependent nominal variables ANOVA - NONparametric testing:
 %res = $aov->anova(independent => 0, parametric => 0, f_equiv => 0)->dump(title => 'Friedman test');

 # or if repeated AND ordinal measures:
 # 2.20 Dependent ordinal variables ANOVA - parametric testing: NOT IMPLEMENTED
 #$aov->anova(independent => 0, parametric => 1)->dump(title => '');
 # 2.21 Dependent ordinal variables test - NONparametric testing:
 %res = $aov->anova(independent => 0, parametric => 0, ordinal => 1, f_equiv => 0)->dump(title => 'Page test');

 # Get pairwise comparisons (nominality of the factor assumed):
 $aov->compare(independent => 1, parametric => 1, flag => 1, alpha => .05, dump => 1); # Indep. obs. F- (or t-)tests
 $aov->compare(independent => 0, parametric => 1, flag => 1, alpha => .05, dump => 1); # Paired obs. F (or t-)tests
 $aov->compare(independent => 1, parametric => 0, flag => 1, alpha => .05, dump => 1); # Wilcoxon (between-variables) sum-of-ranks (Dwass Procedure)
 $aov->compare(independent => 0, parametric => 0, flag => 1, alpha => .05, dump => 1); # Friedman-type (within-variables) sum-of-ranks
 
 print $aov->table(precision_p => 3, precision_s => 3);
 
 $aov->unload('g3'); # back to 2 datasets (g1 and g2)

=head1 DESCRIPTION

=for html <blockquote>&quot;If your predictor variables are categorical (ordered or unordered) and your response variables are continuous, your design is called an ANOVA (for <b>AN</b>alysis <b>O</b>f <b>VA</b>riance&quot;&mdash;Gotelli &amp; Ellison (2004, p. 171).</blockquote>

With that idea in mind, in order to actually perform an ANOVA, you really only need to define an analysis as based on (1) ordered or unordered predictors, (2) independent or repeated measurement of their effects on response variables (i.e., from different or the same data-sources), and then (3) whether parametric or nonparametric assumptions can be made about how the factors impact on the response variables. This module facilitates selecting the right type of ANOVA, by a mere true/false setting of three arguments based on the three latter concepts-- attempting to meet just about every possible combination of these analysis specs. More specifically ...

By setting the Boolean (0, 1) value of three parameters (B<independent>, B<parametric> and B<ordinal>), this module returns and memorizes results from oneway parametric or non-parametric analyses-of-variance (ANOVAs) for either nominal groups or ordinal levels of an independent factor, and for either independent or dependent (repeated measures) observations within each group/level of that factor. 

Parametric tests are of the traditional Fisher-type. Non-parametric tests comprise the Kruskal-Wallis, Jonckheere-Terpstra, Friedman and Page tests; all rank-based tests (with default accounting for ties in ranks).

Other, related routines are offered: for parametrically testing equality of variances (O'Brien and Levene tests); for estimating proportion of variance accounted for (I<eta>-squared) and effect-size (I<omega>-squared); and for making some rudimentary I<a priori> pairwise comparisons by independent/dependent I<t>-tests. 

Reliability of the implemented methods has been tested against at least two different published exemplars of the methods; and by comparing output with one or another open-source or commercial statistics package. That this module's stats and tests match these examplars is tested during installation (at least via CPAN, or when making a "manual" installation).

The API has been stable over all versions, but, ahead of versioning to 1.0, it might well be expected to change. News of method unreliabilities and/or limitations are welcome. Ones from Cathal Seoghie re version 0.01, and Patrick H. Degnan re version 0.07, have already helped this module's development.

=head1 METHODS

=head2 INTERFACE

Object-oriented. No subs are explicitly exported, no arguments are set for cross-method application. The class-object holds the myriad of statistics produced by the last ANOVA run.

=head3 new

 $aov = Statistics::ANOVA->new()

Create a new Statistics::ANOVA object for accessing the subs.

=head2 HANDLING DATA

=head3 load

 $aov->load('aname', @data1)
 $aov->load('aname', \@data1)
 $aov->load(['aname', @data1], ['another_name', @data2])
 $aov->load(['aname', \@data1], ['another_name', \@data2])
 $aov->load({'aname' => \@data1, 'another_name' => \@data2})

I<Alias>: C<load_data>

Accepts data for analysis in any of the above-shown forms, but always with the requirement that:

=over

=item 1.

a single set of observations (the "group" or "level") is given a unique name, and 

=item 2.

you do not mix the methods, e.g., a hashref here, an arrayref there.

=back

The reason for these options is that there are as many as it is practically and intuitively possible to make in Perl's Statistics modules that it's a cost and pain to traverse them; so multiple structures are permitted.

=over

=item 1. sample_name => AREF:

provide C<name =E<gt> value> pairs of data keyed by a stringy name, each with referenced array of values.

=item 2. data => AREF

a reference to an array of referenced arrays, where each of the latter arrays consists of a sample name occupying the first index, and then its sample data, as an array or yet another referenced array; e.g., [ ['group A', 20, 22, 18], ['group B', 18, 20, 16] ]

=item 3. { sample_name_A => AREF, sample_name_B => AREF}

a hash reference of named array references of data. This is the preferred method - the one that is first checked in the elongated C<if> clause that parses all this variety.

=back

The data are loaded into the class object by name, within a hash named C<data>, as flat arrays. So it's all up to you then what statistics and how follow from using this package.

The names of the data are up to you, the user; whatever can be set as the key in a hash. But if you intend to do trend analysis, you should, as a rule, give only I<numerical> names to your groups/levels, defining their ordinality (with respect to the limitations on algorithms presently offered for trend analysis).

Each call L<unload|unload>s any previous loads.

Returns the Statistics::ANOVA object - nothing but its blessed self.

=cut

sub load {
    my $self = shift;
    $self->unload();
    $self->add(@_);
    return;
}
*load_data = \&load;    # Alias

=head3 add, add_data

 $aov->add('another_name', \@data2);
 $aov->add(['another_name', \@data2]);
 $aov->add({'another_name' => \@data2});

Same as L<load|load> except that any previous loads are not L<unload|unload>ed. Again, the hash-referenced list is given preferential treatment.

=cut

sub add {
    my $self = shift;
    my ( $name, $data ) = ();

    if ( ref $_[0] eq 'HASH' ) {
        while ( ( $name, $data ) = each %{ $_[0] } ) {
            if ( ref $data ) {
                $self->SUPER::add( $name, $data );
            }
        }
    }
    elsif ( ref $_[0] eq 'ARRAY' ) {
        $self->add( _aref2href( $_[0] ) );
    }
    else {
        $name = shift;
        $data =
            ref $_[0] eq 'ARRAY' ? $_[0]
          : scalar(@_)           ? \@_
          :                        croak 'No list of data for ANOVA';
        $self->SUPER::add( $name, $data );
    }
    return;
}
*add_data = \&add;    # Alias

=head3 unload

 $aov->unload()     # bye to everything
 $aov->unload('g1') # so long data named "g1"

I<Alias>: C<delete_data>

With nil or no known arguments, empties all cached data and calculations upon them, ensuring these will not be used for testing. This will be automatically called with each new load, but, to take care of any development, it could be good practice to call it yourself whenever switching from one dataset for testing to another.

Alternatively, supply one or more names of already loaded data to clobber just them out of existence; preserving any other loads.

=cut

sub unload {
    my ($self) = shift;
    if ( scalar @_ ) {
        foreach (@_) {
            $self->SUPER::unload( name => $_ );
        }
    }
    else {
        $self->SUPER::unload();
    }
    $self->{'_cleared'} = 1;
    return 1;
}
*delete_data = \&unload;    # Alias

=head3 I<Missing/Invalid values>

Any data-points/observations sent to L<load|load> or L<add|add> that are undefined or not-a-number are marked for purging before being anova-tested or tested pairwise. The data arrays accessed as above, will still show the original values. When, however, you call one of the anova or pairwise methods, the data must and will be purged of these invalid values before testing. 

When the C<independent> parameter equals 1 when sent to L<anova|anova> or L<compare|compare>, each list is simply purged of any undefined or invalid values. This also occurs for the equality of variances tests.

When C<independent> parameter equals 0 when sent to L<anova|anova> and L<compare|compare>, each list is purged of any value at all indices that, in any list, contain invalid values. So if two lists are (1, 4, 2) and (2, ' ', 3), the lists will have to become (1, 2) and (2, 3) to account for the bung value in the second list, and to keep all the observations appropriately paired.

The number of indices that were subject to purging is cached thus: $aov->{'purged'}. The L<dump|dump> method can also reveal this value. 

The C<looks_like_number> method in L<Scalar::Util|Scalar::Util/looks_like_number> is used for checking validity of values. (Although Params::Classify::is_number might be stricter, looks_like_number benchmarks at least a few thousand %s faster.) 

=head2 PROBABILITY TESTING

One generic method L<anova|anova> (a.k.a. aov, test) is used to access the possible combitinations of parametric or nonparametric tests, for independent or dependent/related observations, and for categorical or ordinal analysis. Accessing the different statistical tests depends on setting I<three> parameters on a true/false basis: I<independent>, I<parametric> and I<ordinal>.

The attribute C<independent> refers to whether or not each level of the variable was yielded by independent or related sources of data; e.g., If the same people provided you with responses under the various factors, or if the factors were tested by different participants apiece; when respectively C<independent> => 0 or 1.

The following describes the particular tests you get upon each possible combination of these alternatives.

=head3 1. INDEPENDENT groups/levels

=head4 1.10 PARAMETRIC test for NOMINAL groups

 %res = $aov->anova(independent => 1, parametric => 1, ordinal => 0)

Offers the standard Fisher-type ANOVA for independent measures of the different levels of a factor. 

=head4 1.11 PARAMETRIC test for ORDINAL levels

 $aov->anova(independent => 1, parametric => 1, ordinal => 1) # test linear trend
 $aov->anova(independent => 1, parametric => 1, ordinal => -1) # test non-linear trend

If the independent/treatment/between groups variable is actually measured on a continuous scale/is a quantitative factor, assess their B<linear trend>: Instead of asking "How sure can we be that the means-per-group are equal?", ask "How sure can we be that there is a departure from flatness of the means-per-level?". 

The essential difference is that in place of the the between (treatment) mean sum-of-squares in the numerator is the linear sum of squares in which each "group" mean is weighted by the deviation of the level-value (the name of the "group") from the mean of the levels (and divided by the sum of the squares of these deviations).

If the number of observations per level is unequal, the module applies the simple I<unweighted> approach. This is recommended as a general rule by Maxwell and Delaney (1990), given that the I<weighted> approach might erroneously suggest a linear trend (unequal means) when, in fact, the trend is curvilinear (and by which the means balance out to equality); unless "there are strong theoretical reasons to believe that the only true population trend is linear" (p. 234). (But then you might be theoretically open to either. While remaining as the default, a future option might access the I<hierarchical, weighted> approach.)

To test if there is the possibility of a B<non-linear trend>, give the value of -1 to the C<ordinal> argument.

Note that the contrast coefficients are calculated directly from the values of the independent variable, rather than using a look-up table. This respects the actual distance between values, but requires that the names of the sample data, of the groups (or levels), are I<numerical> names when L<load|load>ed - i.e., such that the data-keys can be summed and averaged.

=head4 1.20 NONPARAMETRIC test for NOMINAL groups (Kruskal-Wallis test)

 %res = $aov->anova(independent => 1, parametric => 0, ordinal => 0)

Performs a one-way independent groups ANOVA using the non-parametric B<Kruskal-Wallis> sum-of-ranks method for a single factor with 2 or more levels. By default, instead of an I<F>-value, there is an I<H>-value. The I<p>-value is read off the chi-square distribution. The test is generally considered to be unreliable if there are no more than 3 groups and all groups comprise 5 or fewer observations. An estimate of I<F> can, alternatively be returned, if the optional argument B<f_equiv> => 1.

By default, this method accounts for and corrects for ties in ranks across the levels, but if C<correct_ties> = 0, I<H> is uncorrected. The correction involves giving each tied score the mean of the ranks for which it is tied (see Siegal, 1956, p. 188ff).

=head4 1.21 NONPARAMETRIC test for ORDINAL levels (Jonckheere-Terpstra test)

 $aov->anova(independent => 1, parametric => 0, ordinal => 1)

Performs the B<Jonckheere-Terpstra> nonparametric test for independent but ordered levels. The method returns:

 $res{'j_value'}   :  the observed value of J
 $res{'j_exp'}     :  the expected value of J
 $res{'j_var'}     :  the variance of J
 $res{'z_value'}   :  the normalized value of J
 $res{'p_value'}   :  the one-tailed probability of observing a value as great as or greater than z_value.

=head3 2. DEPENDENT groups/levels (REPEATED MEASURES)

=head4 2.10 PARAMETRIC test for NOMINAL groups

 %res = $aov->anova(independent => 0, parametric => 1, ordinal => 0, multivariate => 0|1)

Performs parametric repeated measures analysis of variance. This uses the traditional univariate, or "mixed-model," approach, with sphericity assumed (i.e., equal variances of all factor differences, within each factor and all possible pairs of factors). The assumption is met when there are only two levels of the repeated measures factor; but unequal variances might be a problem when there are more than two levels. No methods are presently applied to account for the possibility of non-sphericity.

=head4 2.11 PARAMETRIC test for ORDINAL levels

[Not implemented.]

=head4 2.20 NONPARAMETRIC test for NOMINAL groups (Friedman test)

 %res = $aov->anova(independent => 0, parametric => 0, ordinal => 0)

Performs the B<Friedman> nonparametric analysis of variance - for two or more dependent (matched, related) groups. The statistical attributes now within the class object (see L<anova|anova>) pertain to this test, e.g., $aov->{'chi_value'} gives the chi-square statistic from the Friedman test; and $aov->{'p_value'} gives the associated I<p>-value (area under the right-side, upper tail of the distribution). If B<f_equiv> => 1, then, instead of the I<chi>-value, and I<p>-value read off the I<chi>-square distribution, you get the I<F>-value equivalent, with the I<p>-value read off the I<F>-distribution.

=cut

=head4 2.21 NONPARAMETRIC test for ORDINAL levels (Page test)

 %res = $aov->anova(independent => 0, parametric => 0, ordinal => 1, tails => 1|2)

This implements the B<Page> (1963) analysis of variance by ranks for repeated measures of ordinally scaled variables; so requires - numerically named variables. The statistical attributes now within the class object (see L<anova|anova>) pertain to this test, and are chiefly:

 $res{'l_value'} : the observed test statistic (sum of ordered and weighted ranks)
 $res{'l_exp'}   : expected value of the test statistic
 $res{'l_var'}   : variance of the test statistic (given so many groups and observations)
 $res{'z_value'} : the standardized l_value
 $res{'p_value'} : the 2-tailed probability associated with the z_value (or 1-tailed if tails => 1).
 $res{'r_value'} : estimate of the Spearman rank-order correlation coefficient
  based on the observed and predicted order of each associated variable per observation.

=head3 anova

 $aov->anova(independent => 1|0, parametric => 1|0, ordinal => 0|1)

I<Aliases>: aov, test

Generic method to access all anova functions by specifying TRUE/FALSE values for C<independent>, C<parametric> and C<ordinal>. 

    Independent    Parametric  Ordinal    What you get
    1              1           0          Fisher-type independent groups ANOVA
    1              1           1          Fisher-type independent groups ANOVA with trend analysis
    1              0           0          Kruskal-Wallis independent groups ANOVA
    1              0           1          Jonckheere-Terpstra independent groups trend analysis    
    0              1           0          Fisher-type dependent groups ANOVA (univariate or multivariate)
    0              1           1          (Fisher-type dependent groups ANOVA with trend analysis; not implemented)
    0              0           0          Friedman's dependent groups ANOVA
    0              0           1          Page's dependent groups trend analysis

All methods return nothing but the class object after feeding it with the relevant statistics, which you can access by name, as follows:

 $res{'f_value'} (or $res{'chi_value'}, $res{'h_value'}, $res{'j_value'}, $res{'l_value'} and/or $res{'z_value'})
 $res{'p_value'} : associated with the test statistic
 $res{'df_b'} : between-groups/treatment/numerator degree(s) of freedom
 $res{'df_w'} : within-groups/error/denominator degree(s) of freedom (also given with F-equivalent Friedman test)
 $res{'ss_b'} : between-groups/treatment sum of squares
 $res{'ss_w'} : within-groups/error sum of squares
 $res{'ms_b'} : between-groups/treatment mean squares
 $res{'ms_w'} : within-groups/error mean squares

=cut

sub anova {
    my ( $self, %args ) = @_;
    foreach (qw/independent parametric/) {
        $args{$_} = 1 if !defined $args{$_};
    }
    $args{'ordinal'} = 0 if !defined $args{'ordinal'};

    if ( !$self->{'_cleared'} ) {
        $self->{$_} = undef foreach
          qw/df_b df_w f_value chi_value h_value j_value j_exp j_var l_value l_exp l_var z_value p_value ss_b ss_w ms_b ms_w eta_sq omega_sq purged/;
        $self->{'_cleared'} = 1;
    }

    if ( $args{'independent'} ) {
        _aov_indep( $self, %args );
    }
    else {
        _aov_rmdep( $self, %args );
    }
    return wantarray ? %{ $self->{'_stat'} } : $self;
}
*aov  = \&anova;
*test = \&anova;

sub _aov_indep {
    my ( $self, %args ) = @_;
    my $data = $self->get_hoa_numonly_indep(%args);
    croak 'Not enough variables for performing ANOVA'
      if scalar keys %{$data} < 2;
    if ( any { !scalar @{ $data->{$_} } } keys %{$data} ) {
        croak 'Empty data following purge of invalid value(s)';
    }
    if ( $args{'parametric'} ) {
        if ( !$args{'ordinal'} ) {
            (
                $self->{'_stat'}->{'f_value'},
                $self->{'_stat'}->{'df_b'}, $self->{'_stat'}->{'df_w'},
                $self->{'_stat'}->{'ss_b'}, $self->{'_stat'}->{'ss_w'},
                $self->{'_stat'}->{'ms_b'}, $self->{'_stat'}->{'ms_w'},
                $self->{'_stat'}->{'p_value'},

            ) = _aov_indep_param_cat($data);
            $self->{'_dfree'} = 0;
        }
        else {
            if ( $args{'ordinal'} == 1 ) {
                $self->_aov_indep_param_ord_linear($data);
            }
            else {
                $self->_aov_indep_param_ord_nonlinear($data);
            }
        }
    }
    else {
        $args{'correct_ties'} = 1 if !defined $args{'correct_ties'};
        if ( !$args{'ordinal'} ) {
            $args{'f_equiv'} = 0 if !defined $args{'f_equiv'};
            $self->_aov_indep_dfree_cat( $data, $args{'correct_ties'},
                $args{'f_equiv'} );
        }
        else {
            $args{'tails'} = 2 if !defined $args{'tails'};
            (
                $self->{'_stat'}->{'j_value'}, $self->{'_stat'}->{'j_exp'},
                $self->{'_stat'}->{'j_var'},   $self->{'_stat'}->{'z_value'},
                $self->{'_stat'}->{'p_value'}
              )
              = _aov_indep_dfree_ord( $data, $args{'correct_ties'},
                $args{'tails'} );
        }
    }
    return;
}

sub _aov_rmdep {
    my ( $self, %args ) = @_;
    my $data = $self->get_hoa_numonly_across(%args);
    my $n_bt = scalar keys %{$data};
    croak 'Not enough variables for performing ANOVA'
      if $n_bt < 2;
    my $n_wt = $self->equal_n( data => $data );
    croak
'Number of observations per variable need to be equal and greater than 1 for repeated measures ANOVA'
      if !$n_wt or $n_wt == 1;
    if ( $args{'parametric'} ) {
        if ( !$args{'ordinal'} ) {
            (
                $self->{'_stat'}->{'f_value'}, $self->{'_stat'}->{'df_b'},
                $self->{'_stat'}->{'df_w'},    $self->{'_stat'}->{'ss_b'},
                $self->{'_stat'}->{'ss_w'},    $self->{'_stat'}->{'ms_b'},
                $self->{'_stat'}->{'ms_w'},    $self->{'_stat'}->{'p_value'}
            ) = _aov_rmdep_cat_param( $data, $n_bt, $n_wt );
            $self->{'_dfree'} = 0;
        }
        else {
            _aov_rmdep_ord_param( $data, $n_bt, $n_wt );
        }
    }
    else {
        if ( !$args{'ordinal'} ) {
            $args{'correct_ties'} = 1 if !defined $args{'correct_ties'};
            $args{'f_equiv'}      = 0 if !defined $args{'f_equiv'};
            if ( $args{'f_equiv'} ) {
                (
                    $self->{'_stat'}->{'f_value'},
                    $self->{'_stat'}->{'df_b'},
                    $self->{'_stat'}->{'df_w'},
                    $self->{'_stat'}->{'p_value'}
                  )
                  = _aov_rmdep_cat_dfree_fequiv( $data, $args{'correct_ties'} );
                $self->{'_dfree'} = 1;
            }
            else {
                (
                    $self->{'_stat'}->{'chi_value'},
                    $self->{'_stat'}->{'df_b'}, $self->{'_stat'}->{'count'},
                    $self->{'_stat'}->{'p_value'},

                ) = _aov_rmdep_cat_dfree( $data, $args{'correct_ties'} );
                $self->{'_dfree'} = 1;
            }
        }
        else {
            $args{'tails'} = 2 if !defined $args{'tails'};
            (
                $self->{'_stat'}->{'l_value'}, $self->{'_stat'}->{'l_exp'},
                $self->{'_stat'}->{'l_var'},   $self->{'_stat'}->{'z_value'},
                $self->{'_stat'}->{'p_value'}, $self->{'_stat'}->{'r_value'}
            ) = _aov_rmdep_ord_dfree( $data, $args{'tails'} );
            $self->{'_dfree'} = 1;
        }
    }
    return;
}

sub _aov_indep_param_cat {
    my ($data) = @_;
    my ( $ss_w, $df_w ) = _sumsq_w_indep_param($data);
    croak 'No within-groups data for performing ANOVA' if !$ss_w || !$df_w;
    my $ss_b    = _sumsq_b_indep_param_cat($data);
    my $df_b    = _df_b_indep_param_cat($data);      # a - 1
    my $ms_b    = $ss_b / $df_b;
    my $ms_w    = $ss_w / $df_w;
    my $f_value = $ms_b / $ms_w;
    my $p_value = fdtrc( $df_b, $df_w, $f_value );
    return ( $f_value, $df_b, $df_w, $ss_b, $ss_w, $ms_b, $ms_w, $p_value );
}

sub _aov_indep_param_ord_linear {
    my ( $self, $data ) = @_;
    my ( $ss_w, $df_w ) = _sumsq_w_indep_param($data);
    croak 'No within-groups data for performing ANOVA' if !$ss_w || !$df_w;
    my $ss_l    = _sumsq_b_indep_param_ord($data);
    my $df_b    = _df_b_indep_param_ord_linear($data);   # a - 1
    my $ms_w    = $ss_w / $df_w;
    my $f_value = $ss_l / $ms_w;
    my $p_value = fdtrc( $df_b, $df_w, $f_value );       # Math::Cephes function
    (
        $self->{'_stat'}->{'f_value'}, $self->{'_stat'}->{'df_b'},
        $self->{'_stat'}->{'df_w'},    $self->{'_stat'}->{'ss_b'},
        $self->{'_stat'}->{'ss_w'},    $self->{'_stat'}->{'ms_w'},
        $self->{'_stat'}->{'p_value'}, $self->{'_dfree'}
    ) = ( $f_value, $df_b, $df_w, $ss_l, $ss_w, $ms_w, $p_value, 0 );
    return;
}

sub _aov_indep_param_ord_nonlinear {
    my ( $self, $data ) = @_;
    my ( $ss_w, $df_w ) = _sumsq_w_indep_param($data);
    croak 'No within-groups data for performing ANOVA' if !$ss_w || !$df_w;
    my $df_b    = _df_b_indep_param_ord_nonlinear($data);
    my $ss_b    = _sumsq_b_indep_param_ord_nonlinear($data);    # a - 2
    my $ms_b    = $ss_b / $df_b;
    my $ms_w    = $ss_w / $df_w;
    my $f_value = $ms_b / $ms_w;
    my $p_value = fdtrc( $df_b, $df_w, $f_value );    # Math::Cephes function
    (
        $self->{'_stat'}->{'f_value'}, $self->{'_stat'}->{'df_b'},
        $self->{'_stat'}->{'df_w'},    $self->{'_stat'}->{'ss_b'},
        $self->{'_stat'}->{'ss_w'},    $self->{'_stat'}->{'ms_b'},
        $self->{'_stat'}->{'ms_w'},    $self->{'_stat'}->{'p_value'},
        $self->{'_dfree'}
    ) = ( $f_value, $df_b, $df_w, $ss_b, $ss_w, $ms_b, $ms_w, $p_value, 0 );
    return;
}

sub _aov_indep_dfree_cat {
    my ( $self, $data, $correct_ties, $f_equiv ) = @_;
    eval { require Statistics::ANOVA::KW; };
    croak
'Don\'t know how to run Kruskall-Wallis test. Maybe you need to install Statistics::ANOVA::KW.'
      if $@;
    my $kw = Statistics::ANOVA::KW->new();
    $kw->load_data($data);
    if ($f_equiv) {
        my ( $f_value, $df_b, $df_w, $p_value ) =
          $kw->fprob_test( correct_ties => $correct_ties );
        (
            $self->{'_stat'}->{'f_value'}, $self->{'_stat'}->{'df_b'},
            $self->{'_stat'}->{'df_w'},    $self->{'_stat'}->{'p_value'},
            $self->{'_dfree'}
        ) = ( $f_value, $df_b, $df_w, $p_value, 0 );
    }
    else {
        my ( $chi_value, $df, $count, $p_value ) =
          $kw->chiprob_test( correct_ties => $correct_ties );
        (
            $self->{'_stat'}->{'h_value'}, $self->{'_stat'}->{'df_b'},
            $self->{'_stat'}->{'count'},   $self->{'_stat'}->{'p_value'},
            $self->{'_dfree'}
        ) = ( $chi_value, $df, $count, $p_value, 1 );
    }
    return;
}

sub _aov_indep_dfree_ord {
    my ( $data, $correct_ties, $tails ) = @_;
    eval { require Statistics::ANOVA::JT; };
    croak
'Don\'t know how to run Jonckheere-Terpstra test. Maybe you need to install Statistics::ANOVA::JT.'
      if $@;
    my $jt = Statistics::ANOVA::JT->new();
    $jt->load_data($data);
    my $j_obs = $jt->observed();
    my $j_exp = $jt->expected();
    my $j_var = $jt->variance( correct_ties => $correct_ties );
    my ( $z_value, $p_value ) = $jt->zprob_test(
        correct_ties => $correct_ties,
        tails        => $tails
    );
    return ( $j_obs, $j_exp, $j_var, $z_value, $p_value );
}

sub _aov_rmdep_cat_param {
    my ( $data, $n_bt, $n_wt, ) = @_;
    my ( $ss_b, $ss_w, $df_b, $df_w ) =
      _sumsq_bw_rmdep_param_uni( $data, $n_bt, $n_wt );
    my $ms_b    = $ss_b / $df_b;
    my $ms_w    = $ss_w / $df_w;
    my $f_value = $ms_b / $ms_w;
    my $p_value = fdtrc( $df_b, $df_w, $f_value );    # Math::Cephes
    return ( $f_value, $df_b, $df_w, $ss_b, $ss_w, $ms_b, $ms_w, $p_value );
}

sub _aov_rmdep_ord_param {
    carp
':-( Parametric trend analysis for dependent/repeated measures is not implemented';
    return;
}

sub _aov_rmdep_cat_dfree {
    my ( $data, $correct_ties ) = @_;
    eval { require Statistics::ANOVA::Friedman; };
    croak
'Don\'t know how to do Friedman ANOVA. Perhaps you need to install Statistics::ANOVA::Friedman.'
      if $@;
    my ( $chi, $df, $count, $p_value ) =
      Statistics::ANOVA::Friedman->chiprob_test(
        data         => $data,
        correct_ties => $correct_ties
      );
    return ( $chi, $df, $count, $p_value );
}

sub _aov_rmdep_cat_dfree_fequiv {
    my ( $data, $correct_ties ) = @_;
    eval { require Statistics::ANOVA::Friedman; };
    croak
'Don\'t know how to do Friedman ANOVA. Perhaps you need to install Statistics::ANOVA::Friedman.'
      if $@;
    my ( $f_value, $df_b, $df_w, $p_value ) =
      Statistics::ANOVA::Friedman->fprob_test(
        data         => $data,
        correct_ties => $correct_ties
      );
    return ( $f_value, $df_b, $df_w, $p_value );
}

sub _aov_rmdep_ord_dfree {
    my ( $data, $tails ) = @_;
    eval { require Statistics::ANOVA::Page; };
    croak
'Don\'t know how to do Page ANOVA. Perhaps you need to install Statistics::ANOVA::Page.'
      if $@;
    my $page = Statistics::ANOVA::Page->new();
    $page->load_data($data);
    my $l_obs = $page->observed();
    my $l_exp = $page->expected();
    my $l_var = $page->variance();
    my ( $z_value, $p_value ) = $page->zprob_test( tails => $tails );
    my $r_value = $page->observed_r();
    return ( $l_obs, $l_exp, $l_var, $z_value, $p_value, $r_value, 1 );
}

=head3 Tests for equality of variances

=head4 obrien

 $aov->obrien()

I<Alias>: obrien_test

Performs B<O'Brien's> (1981) test for equality of variances within each variable: based on transforming each observation in relation to its variance and its deviation from its mean; and performing an ANOVA on these values (for which the mean is equal to the variance of the original observations). The procedure is recognised to be robust against violations of normality (unlike I<F>-max) (Maxwell & Delaney, 1990).

The statistical attributes now within the class object (see L<anova|anova>) pertain to this test, e.g., $aov->{'f_value'} gives the I<F>-statistic for O'Brien's Test; and $aov->{'p_value'} gives the I<p>-value associated with the I<F>-statistic for O'Brien's Test.

=cut

sub obrien {
    my ( $self, %args ) = @_;

#ref $self->{'data'} eq 'HASH' ? %{$self->{'data'}} : croak 'No reference to a hash of data for performing ANOVA';
    my $tdata = $self->get_hoa_numonly_indep(%args);    # List-wise clean-up
    croak 'Not enough variables for performing ANOVA'
      if scalar( keys( %{$tdata} ) ) <= 1;
    if ( any { !scalar @{ $tdata->{$_} } } keys %{$tdata} ) {
        croak 'Empty data following purge of invalid value(s)';
    }
    my ( $m, $v, $n, $sname, $sdata, @r, @data ) = ();
    $self->{'obrien'} = {};

    # Traverse each sample of data:
    while ( ( $sname, $sdata ) = each %{$tdata} ) {

       # For each var, compute the sample mean and the unbiased sample variance:
        ( $m, $v, $n ) =
          ( mean( @{$sdata} ), variance( @{$sdata} ), count( @{$sdata} ) );

        # Transform each observation:
        foreach ( @{$sdata} ) {
            push @r,
              (
                (
                    ( ( $n - 1.5 ) * $n * ( ( $_ - $m )**2 ) ) -
                      ( .5 * $v * ( $n - 1 ) )
                ) / ( ( $n - 1 ) * ( $n - 2 ) )
              );
        }
        $self->{'obrien'}->{$sname} = [@r];
        @r = ();

# Check that each variable mean of the O'Briens are equal to the variance of the original data:
        if (
            sprintf( '%.2f', mean( @{ $self->{'obrien'}->{$sname} } ) ) !=
            sprintf( '%.2f', $v ) )
        {
            croak "Mean for sample $sname does not equal variance";
        }
    }

    # Perform an ANOVA using the O'Brien values as the DV:
    (
        $self->{'_stat'}->{'f_value'},
        $self->{'_stat'}->{'df_b'}, $self->{'_stat'}->{'df_w'},
        $self->{'_stat'}->{'ss_b'}, $self->{'_stat'}->{'ss_w'},
        $self->{'_stat'}->{'ms_b'}, $self->{'_stat'}->{'ms_w'},
        $self->{'_stat'}->{'p_value'},

    ) = _aov_indep_param_cat( $self->{'obrien'} );
    $self->{'_dfree'} = 0;
    return wantarray ? %{ $self->{'_stat'} } : $self;
}
*obrien_test = \&obrien;    # Alias

=head4 levene

 $aov->levene()

I<Alias>: levene_test

Performs B<Levene's> (1960) test for equality of variances within each variable: an ANOVA of the absolute deviations, i.e., absolute value of each observation less its mean.

The statistical attributes now within the class object (see L<anova|anova>) pertain to this test, e.g., $aov->{'f_value'} gives the I<F>-statistic for Levene's Test; and $aov->{'p_value'} gives the I<p>-value associated with the I<F>-statistic for Levene's Test.

=cut

sub levene {
    my ( $self, %args ) = @_;

#ref $self->{'data'} eq 'HASH' ? %{$self->{'data'}} : croak 'No reference to an associative array for performing ANOVA';
    my $tdata = $self->get_hoa_numonly_indep(%args);    # List-wise clean-up
    croak 'Not enough variables for performing ANOVA'
      if scalar( keys( %{$tdata} ) ) <= 1;
    if ( any { !scalar @{ $tdata->{$_} } } keys %{$tdata} ) {
        croak 'Empty data following purge of invalid value(s)';
    }
    my ( $m, $v, $n, @d ) = ();
    $self->{'levene'} = {};

    # Traverse each sample of data:
    while ( my ( $sname, $sdata ) = each %{$tdata} ) {

  # For each variable, compute the sample mean and the unbiased sample variance:
        $m = mean( @{$sdata} );
        $v = variance( @{$sdata} );
        $n = count( @{$sdata} );

        # For each observation, compute the absolute deviation:
        my $m = mean( @{$sdata} );
        push @d, abs( $_ - $m ) foreach @{$sdata};
        $self->{'levene'}->{$sname} = [@d];
        @d = ();
    }

    # Perform an ANOVA using the abs. deviations as the DV:
    (
        $self->{'_stat'}->{'f_value'},
        $self->{'_stat'}->{'df_b'}, $self->{'_stat'}->{'df_w'},
        $self->{'_stat'}->{'ss_b'}, $self->{'_stat'}->{'ss_w'},
        $self->{'_stat'}->{'ms_b'}, $self->{'_stat'}->{'ms_w'},
        $self->{'_stat'}->{'p_value'},

    ) = _aov_indep_param_cat( $self->{'levene'} );
    $self->{'_dfree'} = 0;
    return wantarray ? %{ $self->{'_stat'} } : $self;
}
*levene_test = \&levene;    # Alias

=head2 MEASURING EFFECT

Follow-up parametric ANOVAs. Note that for the one-way ANOVAs here tested, eta-squared is the same as partial eta-squared.

=head3 eta_squared

 $etasq = $aov->eta_squared(independent => BOOL, parametric => BOOL, ordinal => BOOL);

Returns the effect size estimate (partial) eta-squared, calculated using sums-of-squares via L<Statistics::ANOVA::EffectSize|Statistics::ANOVA::EffectSize/eta_sq_partial_by_ss>. Also feeds $aov with the value, named 'eta_sq'.

=cut

sub eta_squared {
    my ( $self, @args ) = @_;
    eval { require Statistics::ANOVA::EffectSize; };
    croak
'Don\'t know how to do ANOVA effect-sizes. Perhaps you need to install Statistics::ANOVA::EffectSize.'
      if $@;
    my $etasq = Statistics::ANOVA::EffectSize->eta_sq_partial_by_ss(
        $self->anova(@args) );
    $self->{'_stat'}->{'eta_sq'} = $etasq;
    return $etasq;
}

=head3 omega_squared

Returns the effect size estimate (partial) omega-squared, calculated using mean sums-of-squares via L<Statistics::ANOVA::EffectSize|Statistics::ANOVA::EffectSize/omega_sq_partial_by_ss>. Also feeds $aov with the value, named 'omega_sq'.

=cut

sub omega_squared {
    my ( $self, %args ) = @_;
    eval { require Statistics::ANOVA::EffectSize; };
    croak
'Don\'t know how to do ANOVA effect-sizes. Perhaps you need to install Statistics::ANOVA::EffectSize.'
      if $@;
    my $n = sum0( map { count( @{$_} ) } @{ $self->get_aoa() } );
    my $omg_sq = Statistics::ANOVA::EffectSize->omega_sq_partial_by_ss(
        $self->anova(%args) );
    $self->{'_stat'}->{'omega_sq'} = $omg_sq;
    return $omg_sq;
}

=head2 IDENTIFYING RELATIONSHIPS/DIFFERENCES

=head3 compare

 $aov->compare(independent => 1|0, parametric => 1|0, tails => 2|1, flag => 0|1, alpha => .05,
    adjust_p => 0|1, adjust_e => 1|0|2, use_t => 0|1, dump => 0|1, str => 0|1)

Performs all possible pairwise comparisons, with the Bonferroni approach to control experiment-wise error-rate. The particular tests depend on whether or not you want parametric (default) or nonparametric tests, and if the observations have been made independently (between groups, the default) or by repeated measures. See L<Statistics::ANOVA::Compare|Statistics::ANOVA::Compare>.

=cut

sub compare {
    my ( $self, %args ) = @_;
    eval { require Statistics::ANOVA::Compare; };
    croak
'Don\'t know how to do ANOVA comparisons. Perhaps you need to install Statistics::ANOVA::Compare.'
      if $@;
    my $cmp = Statistics::ANOVA::Compare->new();
    $cmp->share($self);
    return $cmp->run(%args);
}

=head3 confidence

 $itv_str = $aov->(independent => 1|0, alpha => .05, name => 'aname', limits => 0) # get interval for single variable as string
 $lim_aref = $aov->(independent => 1|0, alpha => .05, name => 'aname', limits => 1) # get upper & lower limits for single variable as aref
 $itv_href = $aov->(independent => 1|0, alpha => .05, name => ['aname', 'bname'], limits => 0) # get interval for 2 variables as hashref keyed by variable names
 $lim_href = $aov->(independent => 1|0, alpha => .05, name => ['aname','bname'], limits => 1) # get upper & lower limits for 2 variables as hashref of variable-named arefs
 $itv_href = $aov->(independent => 1|0, alpha => .05, name => undef, limits => 0) # get intervals for all variables as hashref keyed by variable names
 $lim_href = $aov->(independent => 1|0, alpha => .05, name => undef, limits => 1) # upper & lower limits for all variables as hashref 

Computes confidence intervals using (by default) the pooled estimate of variability over groups/levels, rather than the standard error within each group/level, as described by Masson and Loftus (2003). For a between groups design, the confidence interval (as usual) indicates that, at a certain level of probability, the true population mean is likely to be within the interval returned. For a within-subjects design, as any effect of the variability between subjects is eliminated, the confidence interval (alternatively) indicates the reliability of the how the sample means are distributed as an estimate of the how the population means are distributed.

In either case, there is an assumption that the variances within each condition are the same between the conditions (homogeneity of variances assumption).

Actual algorithm depends on whether the measures are obtained from indepedently (between-groups) (independent => 1) or by repeated measures (independent => 0) (i.e., whether between-groups or within-groups design). Default is between-groups.

The option C<use_mse> can be set to equal 0 so that the (typical) standard error of the mean is used in place of the mean-square error. This is one option to use when the variances are unequal.

The option C<conditions> can, optionally, include a referenced array naming the particular conditions that should be included when calculating I<MSe>. By default, this is all the conditions, using I<MSe> from the omnibus ANOVA. This is one option to handle the case of unequal variances between conditions.

=cut

sub confidence {
    my ( $self, %args ) = @_;

    croak 'Need to run ANOVA to obtain requested statistic'
      if !defined $self->{'_stat'}->{'df_w'}
      || !defined $self->{'_stat'}->{'ms_w'};

    my $data = $self->get_hoa_numonly_indep();  # List-wise clean-up of all data
    croak 'Not enough variables for performing ANOVA'
      if scalar( keys( %{$data} ) ) <= 1;
    if ( any { !scalar @{ $data->{$_} } } keys %{$data} ) {
        croak 'Empty data following purge of invalid value(s)';
    }

    # Init key params:
    my $indep = defined $args{'independent'} ? $args{'independent'} : 1;
    my $alpha = _init_alpha( $args{'alpha'} );    # default = .05
    my $tcrit   = abs( stdtri( $self->{'_stat'}->{'df_w'}, $alpha / 2 ) );
    my $limits  = delete $args{'limits'} or 0;
    my $use_mse = defined $args{'use_mse'} ? $args{'use_mse'} : 1;
    my @names =
        defined $args{'name'}
      ? ref $args{'name'}
          ? @{ $args{'name'} }
          : ( $args{'name'} )
      : keys( %{$data} );
    my @conditions =
      ref $args{'conditions'} ? @{ $args{'conditions'} } : @names;
    my ( $erv, $itv, %confints ) = ();

    foreach (@names) {
        if ($use_mse) {
            my $mse;
            $mse = $self->{'_stat'}->{'ms_w'};
            $erv = sqrt( $mse / count( @{ $data->{$_} } ) );
        }
        else {
            $erv =
              stddev( @{ $data->{$_} } ) / sqrt( count( @{ $data->{$_} } ) );
        }
        $itv = $erv * $tcrit;
        if ($limits) {
            $confints{$_} = [
                mean( @{ $data->{$_} } ) - $itv,
                mean( @{ $data->{$_} } ) + $itv
            ];
        }
        else {
            $confints{$_} = $itv;
        }
    }
    return scalar( keys(%confints) ) > 1 ? \%confints : $confints{ $names[0] };
}

=head2 ACCESSING RESULTS

=head3 string

 $str = $aov->string(mse => 1, eta_squared => 1, omega_squared => 1, precision_p => integer, precision_s => integer)

Returns a statement of result, in the form of C<F(df_b, df_w) = f_value, p = p_value>; or, for Friedman test C<chi^2(df_b) = chi_value, p = p_value> (to the value of I<precision_p>, if any); and so on for other test statistics. Optionally also get MSe, eta_squared and omega_squared values appended to the string, where relevant. These and the test statistic are "sprintf"'d to the I<precision_s> specified (or, by default, not at all).

=cut

sub string {
    my ( $self, %args ) = @_;
    my $str;
    my $p_value =
      $args{'precision_p'}
      ? sprintf(
        '%.' . $args{'precision_p'} . 'f',
        $self->{'_stat'}->{'p_value'}
      )
      : $self->{'_stat'}->{'p_value'};
    my $precision_s = $args{'precision_s'} || 0;
    if ( defined $self->{'_stat'}->{'f_value'} && !$self->{'_dfree'} ) {
        $str .= "F($self->{'_stat'}->{'df_b'}, $self->{'_stat'}->{'df_w'}) = ";
        $str .= _precisioned( $precision_s, $self->{'_stat'}->{'f_value'} );
        $str .= ", p = $p_value,";
        $str .=
          ' MSe = '
          . _precisioned( $precision_s, $self->{'_stat'}->{'ms_w'} ) . ','
          if $args{'mse'};
        $str .=
          ' eta^2_p = '
          . _precisioned( $precision_s, $self->eta_squared() ) . ','
          if $args{'eta_squared'};
        $str .=
          ' omega^2_p = '
          . _precisioned( $precision_s, $self->omega_squared() ) . ','
          if $args{'omega_squared'};
        chop($str);
    }
    elsif ( defined $self->{'_stat'}->{'h_value'} ) { # Kruskal-Wallis statistic
        $str .= "H($self->{'_stat'}->{'df_b'}) = ";
        $str .= _precisioned( $precision_s, $self->{'_stat'}->{'h_value'} );
        $str .= ", p = $p_value";
    }
    elsif ( defined $self->{'_stat'}->{'j_value'} )
    {    # Jonckheere-Terpstra statistic
        $str .= "J = ";
        $str .= _precisioned( $precision_s, $self->{'_stat'}->{'j_value'} );
        $str .= ", p = $p_value";
    }
    elsif ( defined $self->{'_stat'}->{'l_value'} ) {    # Page statistic
        $str .= "L = ";
        $str .= _precisioned( $precision_s, $self->{'_stat'}->{'l_value'} );
        $str .= ", p = $p_value";
    }
    elsif ( defined $self->{'_stat'}->{'chi_value'} ) {    # Friedman statistic
        $str .=
"chi^2($self->{'_stat'}->{'df_b'}, N = $self->{'_stat'}->{'count'}) = ";
        $str .= _precisioned( $precision_s, $self->{'_stat'}->{'chi_value'} );
        $str .= ", p = $p_value";
    }
    else {
        croak 'Need to run omnibus test (anova) to obtain results string';
    }
    return $str;
}

=head3 table

 $table = $aov->table(precision_p => integer, precision_s => integer);

Returns a table listing the degrees of freedom, sums of squares, and mean squares for the tested "factor" and "error" (between/within variables), and the I<F>- and I<p>-values. The test statistics are "sprintf"'d to the I<precision_s> specified (or, by default, not at all); the p value's precision can be specified by I<precision_p>. 

Up to this version, if calculating any of these values was not essential to calculation of the test statistic, the value will simply appear as a blank in the table. If the omnibus test last made was non-parametric, and no I<F>-value was calculated, then the table returned is entirely an empty string.

Formatting with right-justification where appropriate is left for user-joy.

=cut

sub table {
    my ( $self, %args ) = @_;
    my $tbl         = q{};
    my $precision_p = $args{'precision_p'} || 0;
    my $precision_s = $args{'precision_s'} || 0;

    # F-table:
    if ( defined $self->{'_stat'}->{'f_value'} && !$self->{'_dfree'} ) {
        $tbl .= "\t$_" foreach ( 'df', 'SumSq', 'MeanSq', 'F', 'Pr(>F)' );
        $tbl .= "\teta^2_p"   if defined $self->{'_stat'}->{'eta_sq'};
        $tbl .= "\tomega^2_p" if defined $self->{'_stat'}->{'omega_sq'};
        $tbl .= "\n";
        $tbl .= "$_\t" foreach ( 'Factor', $self->{'_stat'}->{'df_b'} );
        $tbl .= _precisioned( $precision_s, $_ )
          . "\t" foreach (
            $self->{'_stat'}->{'ss_b'},
            $self->{'_stat'}->{'ms_b'},
            $self->{'_stat'}->{'f_value'}
          );
        for my $es (qw/eta_sq omega_sq/) {
            $tbl .= "\t" . _precisioned( $precision_s, $self->{'_stat'}->{$es} )
              if defined $self->{'_stat'}->{$es};
        }
        $tbl .= _precisioned( $precision_p, $self->{'_stat'}->{'p_value'} );
        $tbl .= "\n";
        $tbl .= "$_\t" foreach ( 'Error', $self->{'_stat'}->{'df_w'} );
        $tbl .= _precisioned( $precision_s, $_ ) . "\t"
          foreach ( $self->{'_stat'}->{'ss_w'}, $self->{'_stat'}->{'ms_w'} );
        $tbl .= "\n";
    }
    return $tbl;
}

=head3 dump

 $aov->dump(title => 'ANOVA test', precision_p => integer, precision_s => integer, mse => 1, eta_squared => 1, omega_squared => 1, verbose => 1)

Prints the string returned by L<string|string>, or, if specified with the attribute I<table> => 1, the table returned by L<table|table>; and the string as well if I<string> => 1. A newline - "\n" - is appended at the end of the print of the string. Above this string or table, a title can also be printed, by giving a value to the optional C<title> attribute.

If I<verbose> => 1, then any curiosities arising in the calculations are noted at the end of other dumps. At the moment, this is only the number of observations that might have been purged were they identified as undefined or not-a-number upon loading/adding.

=cut

sub dump {
    my ( $self, %args ) = @_;
    print "$args{'title'}\n" if $args{'title'};
    if ( $args{'table'} ) {
        print $self->table(%args);
        print $self->string(%args), "\n" if $args{'string'};
    }
    else {
        print $self->string(%args), "\n";
    }
    print "Observations purged as undefined or not-a-number: "
      . $self->{'purged'} . "\n"
      if $self->{'purged'} && $args{'verbose'};
    return;
}

=head2 STATISTICS

=head3 ss_total

 $ss_tot = $aov(independent => BOOL, ordinal => BOOL);
 ($ss_tot, $s_b, $ss_w) = $aov(independent => BOOL, ordinal => BOOL);

Returns the total sum-of-squares, being the sum of the between- and within-groups sums-of-squares, and so definable as the "corrected" total sum-of-squares. Called in array context, also returns the between- and within-groups sums-of-squares themselves.

=cut

sub ss_total {
    my ( $self, %args ) = @_;
    $args{'independent'} = 1 if !defined $args{'independent'};
    $args{'ordinal'}     = 0 if !defined $args{'ordinal'};
    my $data = _get_data( $self, %args );

    my ( $ss_b, $ss_w ) = ();
    if ( $args{'independent'} ) {
        $ss_w = _sumsq_w_indep_param($data);
        if ( !$args{'ordinal'} ) {
            $ss_b = _sumsq_b_indep_param_cat($data);
        }
        else {
            if ( $args{'ordinal'} == 1 ) {
                $ss_b = _sumsq_b_indep_param_ord($data);
            }
            else {
                $ss_b = _sumsq_b_indep_param_ord_nonlinear($data);
            }
        }
    }
    else {
        my $n_bt = scalar keys %{$data};
        croak 'Not enough variables for performing ANOVA'
          if $n_bt < 2;
        my $n_wt = $self->equal_n( data => $data );
        croak
'Number of observations per variable need to be equal and greater than 1 for repeated measures ANOVA'
          if !$n_wt or $n_wt == 1;
        ( $ss_b, $ss_w ) = _sumsq_bw_rmdep_param_uni( $data, $n_bt, $n_wt );
    }
    return wantarray ? ( ( $ss_b + $ss_w ), $ss_b, $ss_w ) : $ss_b + $ss_w;
}

=head3 ss_b

 $ss_b = $anova->ss_b(independent => BOOL, ordinal => BOOL);

Returns the between-groups (aka treatment, effect, factor) sum-of-squares for the given data and the independence of the groups, and whether or not they have an ordinal relationship.

=cut

sub ss_b {
    my ( $self, %args ) = @_;
    $args{'independent'} = 1 if !defined $args{'independent'};
    $args{'ordinal'}     = 0 if !defined $args{'ordinal'};
    my $data = _get_data( $self, %args );
    my $ss;
    if ( $args{'independent'} ) {
        if ( !$args{'ordinal'} ) {
            $ss = _sumsq_b_indep_param_cat($data);
        }
        else {
            if ( $args{'ordinal'} == 1 ) {
                $ss = _sumsq_b_indep_param_ord($data);
            }
            else {
                $ss = _sumsq_b_indep_param_ord_nonlinear($data);
            }
        }
    }
    else {
        my $n_bt = scalar keys %{$data};
        croak 'Not enough variables for performing ANOVA'
          if $n_bt < 2;
        my $n_wt = $self->equal_n( data => $data );
        croak
'Number of observations per variable need to be equal and greater than 1 for repeated measures ANOVA'
          if !$n_wt or $n_wt == 1;
        ($ss) = _sumsq_bw_rmdep_param_uni( $data, $n_bt, $n_wt );
    }
    return $ss;
}

=head3 ss_w

 $ss_w = $anova->ss_w(independent => BOOL);

Returns the within-groups (aka error) sum-of-squares for the given data and according to whether the data per group are independent or dependent.

=cut

sub ss_w {
    my ( $self, %args ) = @_;
    $args{'independent'} = 1 if !defined $args{'independent'};
    my $data = _get_data( $self, %args );
    my $ss;
    if ( $args{'independent'} ) {
        $ss = _sumsq_w_indep_param($data);
    }
    else {
        my $n_bt = scalar keys %{$data};
        croak 'Not enough variables for performing ANOVA' if $n_bt < 2;
        my $n_wt = $self->equal_n( data => $data );
        croak
'Number of observations per variable need to be equal and greater than 1 for repeated measures ANOVA'
          if !$n_wt or $n_wt == 1;
        ( $_, $ss ) = _sumsq_bw_rmdep_param_uni( $data, $n_bt, $n_wt );
    }
    return $ss;
}

=head3 df_b

=cut

sub df_b {
    my ( $self, %args ) = @_;
    $args{'independent'} = 1 if !defined $args{'independent'};
    $args{'ordinal'}     = 0 if !defined $args{'ordinal'};
    my $data = _get_data( $self, %args );
    my $df;
    if ( $args{'independent'} ) {
        if ( !$args{'ordinal'} ) {
            $df = _df_b_indep_param_cat($data);
        }
        else {
            if ( $args{'ordinal'} == 1 ) {
                $df = _df_b_indep_param_ord_linear($data);
            }
            else {
                $df = _df_b_indep_param_ord_nonlinear($data);
            }
        }

        #_aov_indep_dfree_ord
    }
    else {
        my $n_bt = scalar keys %{$data};
        croak 'Not enough variables for performing ANOVA'
          if $n_bt < 2;
        my $n_wt = $self->equal_n( data => $data );
        croak
'Number of observations per variable need to be equal and greater than 1 for repeated measures ANOVA'
          if !$n_wt or $n_wt == 1;
        ($df) = _df_b_indep_dfree_cat($data);
    }
    return $df;
}

sub _df_b_indep_param_cat {
    my $data = shift;
    return ( scalar keys %{$data} ) - 1;
}

sub _df_b_indep_param_ord_linear {
    my $data = shift;
    return ( scalar keys %{$data} ) - 1;
}

sub _df_b_indep_param_ord_nonlinear {
    my $data = shift;
    return ( scalar keys %{$data} ) - 2;
}

sub _df_b_indep_dfree_cat {
    my $data = shift;
    return ( scalar keys %{$data} ) - 1;
}

=head3 grand_mean

 $mean = $anova->grand_mean();

Returns the mean of all observations.

=cut

sub grand_mean {
    my ( $self, %args ) = @_;
    my $data = _get_data( $self, %args );
    return mean( map { @{ $data->{$_} } } keys %{$data} );
}

=head3 grand_sum

 $sum = $anova->grand_sum($data);

Returns the sum of all observations.

=cut

sub grand_sum {
    my ( $self, %args ) = @_;
    my $data = _get_data( $self, %args );
    return sum0( map { @{ $data->{$_} } } keys %{$data} );
}

=head3 grand_n

 $count = $anova->grand_n();

Returns the number of all observations.

=cut

sub grand_n {
    my ( $self, %args ) = @_;
    my $data = _get_data( $self, %args );
    return count( map { @{ $data->{$_} } } keys %{$data} );
}

# Private methods

sub _get_data {
    my ( $self, %args ) = @_;
    my ($data) = ();
    if ( ref $args{'data'} ) {
        $data = delete $args{'data'};
    }
    elsif ( not defined $args{'independent'} or $args{'independent'} == 1 ) {
        $data = $self->get_hoa_numonly_indep(%args);
    }
    else {
        $data = $self->get_hoa_numonly_across(%args);
    }

    if ( any { !scalar @{ $data->{$_} } } keys %{$data} ) {
        croak 'Empty data following purge of invalid value(s)';
    }
    return $data;
}

sub _sumsq_b_indep_param_cat {
    my $data = shift;
    my @group_ns_and_means =
      map { [ count( @{ $data->{$_} } ), mean( @{ $data->{$_} } ) ] }
      keys %{$data};
    my $grand_mean = mean( map { @{ $data->{$_} } } keys %{$data} );
    return sum0( map { $_->[0] * ( $_->[1] - $grand_mean )**2 }
          @group_ns_and_means );
}

sub _sumsq_b_indep_param_ord {    # linear between-group sum-of-squares
    my $data  = shift;
    my @names = keys( %{$data} );
    croak
      "Check names for variables: All need to be numerical for trend analysis"
      if grep { !looks_like_number($_) } @names;
    my $mean_t = mean(@names);    # mean of the ordinal values
    my $sum_sample_contrasts =
      sum( map { mean( @{ $data->{$_} } ) * ( $_ - $mean_t ) } @names );
    my $sumsquared_coeffs =
      sum( map { ( $_ - $mean_t )**2 / count( @{ $data->{$_} } ) } @names )
      ;                           # unweighted
    return $sum_sample_contrasts**2 / $sumsquared_coeffs;
}

sub _sumsq_b_indep_param_ord_nonlinear {
    my $data = shift;
    return _sumsq_b_indep_param_cat($data) - _sumsq_b_indep_param_ord($data);
}

sub _sumsq_w_indep_param {        # within-group SS (and DF):
    my $data = shift;
    my ( $ss_w, $df_w ) = ( 0, 0 );
    foreach ( keys %{$data} ) {
        my $mean = mean( @{ $data->{$_} } );
        $ss_w += ( $_ - $mean )**2 foreach @{ $data->{$_} };
        $df_w += ( count( @{ $data->{$_} } ) - 1 );
    }
    return wantarray ? return ( $ss_w, $df_w ) : $ss_w;
}

sub _sumsq_bw_rmdep_param_uni
{    # error and treatment sums-of-squares for rm anovas (univariate method)
    my ( $data, $n_bt, $n_wt ) = @_;
    my ( $ss_b, $ss_w, $df_b, $df_w, $i, @i_means, %i_data, %j_means ) = ();

    # Mean over each index:
    for ( $i = 0 ; $i < $n_wt ; $i++ ) {
        push @{ $i_data{$i} }, $data->{$_}->[$i] foreach keys %{$data};
        $i_means[$i] = mean( @{ $i_data{$i} } );
    }
    croak 'No means to divide by' if !scalar @i_means;
    my $grand_mean = sum0(@i_means) / scalar @i_means;

    foreach ( keys %{$data} ) {
        $j_means{$_} = mean( @{ $data->{$_} } );
        $ss_b += ( $j_means{$_} - $grand_mean )**2;
    }
    $ss_b *= $n_wt;

    foreach ( keys %{$data} ) {
        for ( $i = 0 ; $i < $n_wt ; $i++ ) {
            $ss_w +=
              ( $data->{$_}->[$i] - $i_means[$i] - $j_means{$_} + $grand_mean )
              **2;
        }
    }
    $df_b = $n_bt - 1;
    $df_w = $df_b * ( $n_wt - 1 );
    return ( $ss_b, $ss_w, $df_b, $df_w );
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

sub _pcorrect {    # (1 - ( 1 - p)^N )
    return 1 - ( 1 - $_[0] )**$_[1];
}

sub _precisioned {
    return $_[0]
      ? sprintf( '%.' . $_[0] . 'f', $_[1] )
      : ( defined $_[1] ? $_[1] : q{} );    # don't lose any zero
}

sub _init_alpha {
    my $val = shift;
    if ( defined $val ) {
        if ( $val > 0 && $val < 1 ) {
            return $val;
        }
        else {
            croak "Alpha value should be between 0 and 1, not '$val'.";
        }
    }
    else {
        return $ALPHA_DEFAULT;
    }
}

sub cluster {
    croak 'cluster() method is deprecated. See Statistics::ANOVA::Cluster';
    return;
}

1;

__END__


=head1 DIAGNOSTICS

=over 4

=item Alpha value should be between 0 and 1, not '$val'.

Initialising an alpha-value for significance-testing was done but not with a valid value; it must be a probablity, but less than 1 and greater than 0.

=back

=head1 REFERENCES

Cohen, J. (1969). I<Statistical power analysis for the behavioral sciences>. New York, US: Academic.

Hollander, M., & Wolfe, D. A. (1999). I<Nonparametric statistical methods>. New York, NY, US: Wiley.

Levene, H. (1960). Robust tests for equality of variances. In I. Olkins (Ed.), I<Contributions to probability and statistics>. Stanford, CA, US: Stanford University Press.

Masson, M. E. J., & Loftus, G. R. (2003). Using confidence intervals for graphically based data interpretation. I<Canadian Journal of Experimental Psychology>, I<57>, 203-220.

Maxwell, S. E., & Delaney, H. D. (1990). I<Designing experiments and analyzing data: A model comparison perspective.> Belmont, CA, US: Wadsworth.

O'Brien, R. G. (1981). A simple test for variance effects in experimental designs. I<Psychological Bulletin>, I<89>, 570-574.

Siegal, S. (1956). I<Nonparametric statistics for the behavioral sciences>. New York, NY, US: McGraw-Hill

=head1 DEPENDENCIES

L<List::AllUtils|List::AllUtils>

L<Math::Cephes|Math::Cephes> Probabilities for all tests are computed using this module's functions, rather than the "in-house" L<Statistics::Distributions|Statistics::Distributions> module, as the former appears to be more accurate for larger values of I<F>.

L<Scalar::Util|Scalar::Util>

L<Statistics::ANOVA::Cluster|Statistics::ANOVA::Cluster> for determining parametric and nonparametric variable clusters by ANOVA.

L<Statistics::ANOVA::EffectSize|Statistics::ANOVA::EffectSize> for returning eta- and omega-squared.

L<Statistics::Data|Statistics::Data> : used as C<base>.

L<Statistics::Data::Rank|Statistics::Data::Rank>

L<Statistics::DependantTTest|Statistics::DependantTTest>

L<Statistics::Lite|Statistics::Lite>

L<Statistics::TTest|Statistics::TTest>

=head1 SEE ALSO

L<Statistics::FisherPitman|Statistics::FisherPitman> For an alternative to independent groups ANOVA when the variances are unequal.

L<Statistics::KruskalWallis|Statistics::KruskalWallis> Offers Newman-Keuls for pairwise comparison by ranks. Also offers non-parametric independent groups ANOVA, but note it does not handle ties in rank occurring between two or more observations, nor correct for them; an erroneous I<H>-value is calculated if ties exist in your data. Also does not handle missing/invalid values. Present module adapts its _grouped method.

L<Statistics::Table::F|Statistics::Table::F> Simply returns an I<F> value. Does not handle missing values, treating them as zero and thus returning an erroneous I<F>-value in these cases.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-statistics-anova-0.13 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Statistics-ANOVA-0.13>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::Data

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-ANOVA-0.13>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Statistics-ANOVA-0.13>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Statistics-ANOVA-0.13>

=item * Search CPAN

L<http://search.cpan.org/dist/Statistics-ANOVA-0.13/>

=back

=head1 AUTHOR

Roderick Garton, C<< <rgarton at cpan.org> >>

=head1 LICENSE AND COPYRIGHT AND DISCLAIMER

Copyright 2006-2015 Roderick Garton

This program is free software. It may be used, redistributed and/or modified under the same terms as Perl-5.6.1 (or later) (see L<http://www.perl.com/perl/misc/Artistic.html>).

To the maximum extent permitted by applicable law, the author of this module disclaims all warranties, either express or implied, including but not limited to implied warranties of merchantability and fitness for a particular purpose, with regard to the software and the accompanying documentation.

=cut

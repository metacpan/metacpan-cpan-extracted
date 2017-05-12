package Statistics::MVA::BayesianDiscrimination;

use warnings;
use strict;
use Carp;
use Statistics::MVA;
use Math::Cephes qw/:explog/;
use List::Util qw/sum/;
use Text::SimpleTable;

#=fs pod stuff
=head1 NAME

Statistics::MVA::BayesianDiscrimination - Two-Sample Linear Discrimination Analysis with Posterior Probability Calculation.

=cut

=head1 VERSION

This document describes Statistics::MVA::BayesianDiscrimination version 0.0.2

=cut

=head1 DESCRIPTION

Discriminant analysis is a procedure for classifying a set of observations each with k variables into predefined classes such as to allow the
determination of the class of new observations based upon the values of the k variables for these new observations. Group membership based on linear combinations of the variables. From the set of observations where group membership is know the procedure constructs a set of linear functions, termed
discriminant functions, such that: 

    L = B[0] + B[1] * x1 + B[2] * x2 +... ... + B[n] * x_n

Where B[0] is a constant, B[n's] are discriminant coefficients and x's are the input variables. These discriminant functions
(there is one for each group - consequently as this module only analyses data for two groups atm it generates two such
discriminant functions.

Before proceeding with the analysis you should: (1) Perform Bartlett´s test to see if the covariance matrices of the data
are homogenous for the populations used (see L<Statistics::MVA::Bartlett>. If they are not homogenous you should use Quadratic Discrimination analysis.
(2) test for equality of the group means using Hotelling's T^2 (see L<Statistics::MVA::HotellingTwoSample> or MANOVA. If
the groups do not differ significantly it is extremely unlikely that discrimination analysis with generate any useful
discrimination rules. (3) Specify the prior probabilities. This module allows you to do this in several ways - see
L</priors>.

This class automatically generates the discrimination coefficients at part of object construction. You can then either
use the C<output> method to access these values or use the C<discriminate> method to apply the equations to a new
observation. Both of these methods are context dependent - see L</METHODS>. See
http://en.wikipedia.org/wiki/Linear_discriminant_analysis for further details.

=cut

=head1 SYNOPSIS

    # we have two groups of data each with 3 variables and 10 observations - example data from http://www.stat.psu.edu/online/courses/stat505/data/insect.txt
    my $data_X = [
        [qw/ 191 131 53/],
        [qw/ 185 134 50/],
        [qw/ 200 137 52/],
        [qw/ 173 127 50/],
        [qw/ 171 128 49/],
        [qw/ 160 118 47/],
        [qw/ 188 134 54/],
        [qw/ 186 129 51/],
        [qw/ 174 131 52/],
        [qw/ 163 115 47/],
    ];

    my $data_Y = [
        [qw/ 186 107 49/],
        [qw/ 211 122 49/],
        [qw/ 201 144 47/],
        [qw/ 242 131 54/],
        [qw/ 184 108 43/],
        [qw/ 211 118 51/],
        [qw/ 217 122 49/],
        [qw/ 223 127 51/],
        [qw/ 208 125 50/],
        [qw/ 199 124 46/],
    ];
    
    use Statistics::MVA::BayesianDiscrimination;

    # Pass the data as a list of the two LISTS-of-LISTS above (termed X and Y). The module by default assumes equal prior probabilities.
    #my $bld = Statistics::MVA::BayesianDiscrimination->new($data_X,$data_Y);

    # Pass the data but telling the module to calculate the prior probabilities as the ratio of observations for the two groups (e.g. P(X) X_obs_num / Total_obs.
    #my $bld = Statistics::MVA::BayesianDiscrimination->new({priors => 1 },$data_X,$data_Y);

    # Pass the data but directly specifying the values of prior probability for X and Y to use as an anonymous array.
    #my $bld = Statistics::MVA::BayesianDiscrimination->new({priors => [ 0.25, 0.75 ] },$ins_a,$ins_b);

    # Print values for coefficients to STDOUT.
    $bld->output;

    # Pass the values as an ARRAY reference by calling in LIST context - see L</output>.
    my ($prior_x, $constant_x, $matrix_x, $prior_y, $constant_y, $matrix_y) = $bld->output;
   
    # Perform discriminantion analyis for a specific observation and print result to STDOUT.
    $bld->discriminate([qw/184 114 59/]);

    # Call in LIST context to obtain results directly - see L</discriminate>.
    my ($val_x, $p_x, $post_p_x, $val_y, $p_y, $post_p_y, $type) = $bld->discriminate([qw/194 124 49/]);

=cut

=head1 METHODS
=cut

=head2 new

Creates a new Statistics::MVA::BayesianDiscrimination. This accepts two references for List-of-Lists of values
corresponding to the two groups of data - termed X and Y. Within each List-of-Lists each nested array corresponds to a single set of observations. 
It also accepts an optional HASH reference of options preceding these values. The constructor automatically generates
the discrimination coefficients that are accessed using the C<output> method.

    # Pass data as ARRAY references.
    my $bld = Statistics::MVA::BayesianDiscrimination->new($data_X,$data_Y);

    # Passing optional HASH reference of options.
    my $bld = Statistics::MVA::BayesianDiscrimination->new({priors => 1 },$data_X,$data_Y);
   
=cut

=head2 output

Context-dependent method for accessing results of discrimination analysis. In void context it prints the coefficients to STDOUT.

    $bld->output;

In LIST-context it returns a list of the relevant data accessed as follows:

    my ($prior_x, $constant_x, $matrix_x, $prior_y, $constant_y, $matrix_y) = $bld->output;

    print qq{\nPrior probability of X = $prior_x and Y = $prior_y.}; 
    print qq{\nConstants for discrimination function for X = $constant_x and Y = $constant_y.};
    print qq{\nCoefficients for discrimination function X = @{$matrix_x}.};
    print qq{\nCoefficients for discrimination function Y = @{$matrix_y}.};

=cut

=head2 discriminate

Method for classification of a new observation. Pass it an ARRAY reference of SCALAR values appropriate for the original
data-sets passed to the constructor. In void context it prints a report to STDOUT:

    $bld->discriminate([qw/123 34 325/];

In LIST-context it returns a list of the relevant data as follows:

    my ($val_x, $p_x, $post_p_x, $val_y, $p_y, $post_p_y, $type) = $bld->discriminate([qw/123 34 325/];

    print qq{\nLinear score function for X = $val_x and Y = $val_y - the new observation is of type \x27$type\x27.};
    print qq{\nThe prior probability that the new observation is of type X = $p_x and the posterior probability = $post_p_x};
    print qq{\nThe prior probability that the new observation is of type X = $p_y and the posterior probability = $post_p_y};     

=cut

=head1 OPTIONS
=cut

=head2 priors

Pass within an anonymous HASH preceding the two data references during object construction:

    my $bld = Statistics::MVA::BayesianDiscrimination->new({priors => option_value },$data_X,$data_Y);

Passing '0' causes the module to assume equal prior probabilities for the two groups (prior_x = prior_y = 0.5). Passing
'1' causes the module to generate priors depending on the ratios of the two data-sets e.g. X has 15 observations and Y
has 27 observations gives prior_x = 15 / (15 + 27). Alternatively you may specify the values to use by passing an anonymous ARRAY reference of length 2
where the first value is prior_x and the second is prior_y. There are currently no checks on priors directly passed so
ensure that prior_x + prior_y = 1 if you supply you own.

    # Use prior_x = prior_y = 0.5.
    my $bld = Statistics::MVA::BayesianDiscrimination->new({priors => 0 },$data_X,$data_Y);

    # Generate priors depending on rations of observation numbers.
    my $bld = Statistics::MVA::BayesianDiscrimination->new({priors => 1 },$data_X,$data_Y);

    # Specify your own priors.
    my $bld = Statistics::MVA::BayesianDiscrimination->new({priors => [$prior_x, $prior_y] },$data_X,$data_Y);

=cut

#=fe

use version; our $VERSION = qv('0.0.2');

#/ with these new modules object creation directly checks data and performs analysis. storing just the essential results. can access directly or print them

sub new { 
    my $class = shift;
    #y grab an options hash if there is one
    my $options_ref = shift if ( ref $_[0] eq q{HASH} );
    #y the rest is data
    my @data = @_;
    my $p_x;
    my $p_y;

    my $self = [];

    my $k = scalar @data;
    croak qq{\nThis only accepts two groups of data} if $k != 2;
    #y if there´s an options hash with priors check it - otherwise default...
    if ( defined $options_ref ) { ($p_x, $p_y) = &_priors($options_ref, @data) }
    else {
        print qq{\nDefaulting to priors of 0.5 for both x and y.};
        $p_x = 0.5;
        $p_y = 0.5; 
    }
    #y check they have good matrix format - need to check compatibility too
    croak qq{\nbad data} if &Statistics::MVA::CVMat::_check($data[0]);
    croak qq{\nbad data} if &Statistics::MVA::CVMat::_check($data[1]);
    #y data is passed in table format - i.e. nested arrays (rows) correspond to observations and not variables
    my $lol1 = &Statistics::MVA::CVMat::transpose($data[0]);
    my $lol2 = &Statistics::MVA::CVMat::transpose($data[1]);
    #y get variable number
    my $p = scalar @{$lol1};
    croak qq{\nThese data sets are not compatible} if ($p != scalar @{$lol2});
    #y combine the data for overall means calculations - if using single data with names could use adjust in MVA
    my $full = [];
    $full = &_combine($lol1,$lol2, $p);
    #y copy vars and we will do in place mean calculation - no need to deep copy references here
    #my $first = &_deep_copy($lol1);
    my $first = [@{$lol1}];
    my $second = [@{$lol2}];
    #y in place calculation of the means
    &_means($full,$p);
    &_means($first,$p);
    &_means($second,$p);
    #y in place subtraction of means from raw data
    &_subtract($lol1, $full);
    &_subtract($lol2, $full);
    #y for MVA cv_calculations the data needs to be in table format - this is wastefull as it just transpose - thus is unecessary transposes - IN PLACE - should modify this?!?
    $lol1 = &Statistics::MVA::CVMat::transpose($lol1);
    $lol2 = &Statistics::MVA::CVMat::transpose($lol2);
    my $mva;
    #y if we have a twat who likes this annoying method
    if (defined $options_ref && defined $options_ref->{cv} && $options_ref->{cv} == 0) { $mva = &_twats($lol1, $lol2); }
    else {
        #y create MVA object - these are defaults parameters so don´t need to pass them...
        $mva = Statistics::MVA->new([ $lol1, $lol2 ], {standardise => 0, divisor => 1});
    }
    #r CV matrix data - loose last [0] for realmatrix object
    #print Dumper $mva->[0][0][0][0];
    #print Dumper $mva->[0][1][0][0];
    #y create empty matrix of same dimensions
    my $c = $mva->[0][0][0]->shadow;

    #/ its 2x not divided by priors?!? - only constant takes into account priors
    #$mva->[0][0][0]->multiply_scalar($mva->[0][0][0],$p_x);
    #$mva->[0][1][0]->multiply_scalar($mva->[0][1][0],$p_y);
    $mva->[0][0][0]->multiply_scalar($mva->[0][0][0],0.5);
    $mva->[0][1][0]->multiply_scalar($mva->[0][1][0],0.5);

    $c->add($mva->[0][0][0],$mva->[0][1][0]); 

    #y no need for transpose just build from rows...
    my $averages_a = Math::MatrixReal->new_from_rows([$first]);
    my $averages_b = Math::MatrixReal->new_from_rows([$second]);
    #y calculate b_0 - constant discrimination coefficients
    my $constant_x = 0.5 * $averages_a * $c->inverse * ~$averages_a;
    my $constant_y = 0.5 * $averages_b * $c->inverse * ~$averages_b;

    #/ you must add the priors to the constant - only the constant takes into account the priors.
    #$constant_x->[0][0][0] = $constant_x->[0][0][0] - log($p_x);
    #$constant_y->[0][0][0] = $constant_y->[0][0][0] - log($p_y);
    #y now should be -0.5...
    $constant_x->[0][0][0] = -$constant_x->[0][0][0] + log($p_x);
    $constant_y->[0][0][0] = -$constant_y->[0][0][0] + log($p_y);

    #y calculate the rest of the discrimination coeficients
    #~$averages_a * $c->inverse * $averages_a;
    my $matrix_x = $averages_a * $c->inverse;
    my $matrix_y = $averages_b * $c->inverse;

    #y feed the objectvv- this is only done for persistance - otherwise we loose the data...
    $self->[0][0][0] = $constant_x;
    $self->[0][0][1] = $matrix_x;
    $self->[0][1][0] = $constant_y;
    $self->[0][1][1] = $matrix_y;
    $self->[1][0] = $p_x;
    $self->[1][1] = $p_y;
    $self->[2] = $p;

    bless $self, $class;
    return $self;
}

sub _priors {
    my ($options_ref, @data) = @_;
    my $p_x;
    my $p_y;
    if ($options_ref->{priors} ==  1 ) {
        my $n_x = scalar @{$data[0]};
        my $n_y = scalar @{$data[1]};
        my $n_total = $n_x + $n_y;
        $p_x = sprintf (q{%.5f}, $n_x / $n_total);
        $p_y = sprintf (q{%.5f}, $n_y / $n_total);
    }
    elsif (ref $options_ref->{priors} eq q{ARRAY} ) {
        my @priors = @{$options_ref->{priors}};
        croak qq{\nIf passing an ARRAY ref of priors it must have length two.} if ( scalar @priors != 2 );
        croak qq{\nThe priors must sum to 1.} if ( $priors[0] + $priors[1] < 0.95 || $priors[0] + $priors[1] > 1.05 );
        $p_x = $priors[0];
        $p_y = $priors[1];
    }
    elsif ($options_ref->{priors} == 0) {
        $p_x = 0.5;
        $p_y = 0.5; 
    }
    else { croak qq{\nI do not recognise that value for the priors option} }
    return ($p_x, $p_y);
}

sub _subtract {
    my ($lol, $full) = @_;
    for my $var (0..$#{$lol}) { 
        for my $cell (0..$#{$lol->[$var]}) {
            $lol->[$var][$cell] = $lol->[$var][$cell] - $full->[$var];
        }
    }
}

sub _combine{
    my ($lol1, $lol2, $p) = @_;
    my $full = [];
    for my $i (0..$p-1) {
        push @{$full->[$i]}, @{$lol1->[$i]}, @{$lol2->[$i]};
    }
    return $full;
}

sub _means {
    my ($full, $p) = @_;
    for my $i (0..$p-1) {
        my $sum = sum @{$full->[$i]};
        my $n = scalar @{$full->[$i]};
        $full->[$i] = $sum/$n;
    }
}

sub _twats {
    my ($lol1, $lol2) = @_;
    my $lol1_mat = Math::MatrixReal->new_from_rows($lol1);
    my $n_1 = scalar @{$lol1};
    $lol1_mat = (~$lol1_mat * $lol1_mat) / $n_1;
    my $lol2_mat = Math::MatrixReal->new_from_rows($lol2);
    my $n_2 = scalar @{$lol2};
    $lol2_mat = (~$lol2_mat * $lol2_mat) / $n_2;
    my $mva = [];
    $mva->[0][0][0] = $lol1_mat;
    $mva->[0][1][0] = $lol2_mat;
    print $mva->[0][0][0];
    print $mva->[0][1][0];
    return $mva;
}

sub output {
    my $self = shift;
    my $constant_x = $self->[0][0][0];
    my $constant_y = $self->[0][1][0];
    my $matrix_x = $self->[0][0][1];
    my $matrix_y = $self->[0][1][1];
    my $p_x = $self->[1][0]; 
    my $p_y = $self->[1][1]; 
    my $p_var_num = $self->[2]; 
    if (!wantarray) {
        print qq{\nTwo-groups with $p_var_num variables each and prior probabilities of p(x) = $p_x and p(y) = $p_y.\n\n};
        my @config = ( [17, q{}], [15, q{X}], [15, q{Y}] );
        my $tbl = Text::SimpleTable->new(@config);
        $tbl->row( qq{Constant B[0]}, sprintf(q{%.5f}, $constant_x->[0][0][0]), sprintf(q{%.5f}, $constant_y->[0][0][0]) );
        $tbl->hr;
        for my $row (0..$#{$matrix_x->[0][0]}) { 
            my $coeff = $row+1;
            $tbl->row( qq{Coefficient B[$coeff]}, sprintf(q{%.5f}, $matrix_x->[0][0][$row]), sprintf(q{%.5f}, $matrix_y->[0][0][$row]) );
            $tbl->hr if $row != $#{$matrix_x->[0][0]};
        }
        print $tbl->draw;
        return;
    }
    else { return ( $p_x, $constant_x->[0][0][0], $matrix_x->[0][0], $p_y, $constant_y->[0][0][0], $matrix_y->[0][0] ); }
}

sub discriminate {
    my ($self, $ex) = @_;
    my $context = wantarray;
    my $constant_x = $self->[0][0][0];
    my $constant_y = $self->[0][1][0];
    my $matrix_x = $self->[0][0][1];
    my $matrix_y = $self->[0][1][1];
    my $p_x = $self->[1][0]; 
    my $p_y = $self->[1][1]; 
    my $p_var_num = $self->[2]; 
    
    croak qq{\nData must be passed as an ARRAY ref} if (ref $ex ne q{ARRAY});
    croak qq{\nThis example has the wrong variable number} if scalar @{$ex} != $p_var_num;

    my $example = Math::MatrixReal->new_from_cols([$ex]);
    my $val_x = ( $matrix_x * $example ) + $constant_x;#; + log($p_x);

    #r when adding log(p) its the linear score function and not simply the linear discrimination result
    #$val_x = $val_x->[0][0][0];#+log($p_x);
    $val_x = $val_x->[0][0][0];
    my $val_y = ( $matrix_y * $example ) + $constant_y;#; + log($p_x);
    #$val_y = $val_y->[0][0][0];#+log($p_y);
    $val_y = $val_y->[0][0][0];

    my $type    = $val_x > $val_y ? q{X}
                : $val_y > $val_x ? q{Y} 
                :                   undef;

    my $post_p_x = exp($val_x) / (exp($val_x) + exp($val_y));
    my $post_p_y = exp($val_y) / (exp($val_x) + exp($val_y));

    if (!$context) {
        print qq{\nLinear score function for x = $val_x\nLinear score function for y = $val_y\n};
        if ( defined $type  ) { print qq{\nExample (@{$ex}) is a \x27$type\x27.} } 
        else { print qq{\nCannot distinguish which group the example belongs to.} }
        print qq{\n\nPrior probability of being an x = $p_x\nPosterior probability of being an x = $post_p_x\n};
        print qq{\nPrior probability of being a y = $p_y\nPosterior probability of being a y = $post_p_y\n};
        return;
    }
    else {
        return ($val_x, $p_x, $post_p_x, $val_y, $p_y, $post_p_y, $type); 
    }
}

1; # Magic true value required at end of module

__END__

# It is different from the cluster analysis because prior knowledge of the classes, usually in the form of a sample from each class is required
# DA is reversed multivariate analysis of variance, MANOVA - In MANOVA, the independent variables are the groups and the dependent variables are the predictors, while in DA, the independent variables are the predictors

#If you prefer to use (X^T) %*% (X) in place of Covariance Calculations pass option cv => 0 as in
#http://people.revoledu.com/kardi/tutorial/LDA/Numerical%20Example.html

#Linear Discriminant Analysis is for homogeneous variance-covariance matrices and in this case the
#variance-covariance matrix does not depend on the population from which the data are obtained.

=head1 DEPENDENCIES

'Statistics::MVA' => '0.0.1',
'Carp' => '1.08', 
'Math::Cephes' => '0.47', 
'List::Util' => '1.19',
'Text::SimpleTable' => '2.0',

=cut

=head1 BUGS

Let me know.

=cut

=head1 AUTHOR

Daniel S. T. Hughes  C<< <dsth@cantab.net> >>

=cut

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Daniel S. T. Hughes C<< <dsth@cantab.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

=head1 DISCLAIMER OF WARRANTY

Because this software is licensed free of charge, there is no warranty
for the software, to the extent permitted by applicable law. Except when
otherwise stated in writing the copyright holders and/or other parties
provide the software "as is" without warranty of any kind, either
expressed or implied, including, but not limited to, the implied
warranties of merchantability and fitness for a particular purpose. The
entire risk as to the quality and performance of the software is with
you. Should the software prove defective, you assume the cost of all
necessary servicing, repair, or correction.

In no event unless required by applicable law or agreed to in writing
will any copyright holder, or any other party who may modify and/or
redistribute the software as permitted by the above licence, be
liable to you for damages, including any general, special, incidental,
or consequential damages arising out of the use or inability to use
the software (including but not limited to loss of data or data being
rendered inaccurate or losses sustained by you or third parties or a
failure of the software to operate with any other software), even if
such holder or other party has been advised of the possibility of
such damages.
=cut

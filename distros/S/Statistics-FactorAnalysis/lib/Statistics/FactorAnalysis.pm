package Statistics::FactorAnalysis;
use strict;
use warnings;
use Carp;
use List::Util qw(sum);
use Moose; # automatically turns on strict and warnings
use MooseX::NonMoose;
use Statistics::PCA::Varimax;

# have an print pca that gives eigenvalues too?

=head1 NAME

Statistics::FactorAnalysis - A Perl implementation of Factor Analysis using the Principal Component Method.

=cut
=head1 VERSION

This document describes Statistics::FactorAnalysis version 0.0.2

=cut
=head1 SYNOPSIS

    use Statistics::FactorAnalysis;

    # Data is entered as a reference to a LoL. In this case each nested LIST corresponds to a separate variable - thus 'format' option is set to 'variable'. 
    my $data = [
                    [qw/ 1038 369  622  1731 1109 1274 517  2043 1106 201  665  593  1117 563  2448 2201 1036 2715 700  593  394  1097 212  /],
                    [qw/ 1348 1483 749  1658 401  952  1039 1488 791  1344 488  591  744  1472 1076 1475 784  1170 384  450  1035 938  1179 /],
                    [qw/ 4472 4388 2174 3527 5587 3454 2560 6247 2238 2778 4399 1750 4738 2918 6680 3141 3872 6634 2017 3458 1922 3374 2768 /],
                    [qw/ 2627 3407 2299 3094 2721 2705 2814 2804 2155 2500 2503 2701 3058 2914 2940 2596 2723 2710 3022 2557 2652 2920 2687 /],
                    [qw/ 6466 3596 153  3335 1921 3255 437  4486 2769 755  91   155  480  1954 5697 5327 1263 9577 52   268  68   2797 122  /],
                    [qw/ 2366 3984 300  837  1304 1909 3800 1994 2135 2089 5148 1956 1513 2160 1943 1918 2036 4800 1100 816  937  1327 918  /],
                    [qw/ 6862 5746 4220 5739 5646 4848 7089 5160 5514 6083 5187 4491 5154 6029 5870 4923 5287 5901 4055 4765 6213 3894 4694 /],
            ];

    # Create Statistics::FactorAnalysis object with checking of variable distributions.
    my $fac = Statistics::FactorAnalysis->new(dist_check => 1);

    # Set compulsory format option - can be set in constructor as with any Moose attribute.
    $fac->format('variable');

    # Set compulsory LoL option. Points to reference of LoL of the data.
    $fac->LoL($data); 

    # Load the data. 
    $fac->load_data;

    # Loading complained so log transform data.
    use Math::Cephes qw(:explog);
    for my $row (@{$data}) { for my $col (@{$row}) { $col = log10($col); }}

    # Re-load data.
    $fac->load_data;

    # We'll perform PCA to have a look at the PC variances so perform PCA analysis.
    $fac->pca;

    # Have a look at the variances.
    $fac->pca_print_variance;

    # If the first 2 PCs explain more than 75% of the variance we use 2 factors else we use 3.
    my @cumulative = $fac->return_pca_cumulative_variances;
    my $factors = $cumulative[1] > 0.75 ? 2 : 3; 

    # Set our choice of factor number.
    $fac->factors($factors);

    # We will compute the rotated matrix.
    $fac->rotate(1);

    # Perform the factor analysis.
    $fac->fac();

    # Have a look at the results - if you want to access data directly use the return methods (see DIRECT DATA ACCESS/RETURN METHODS).
    $fac->fac_print_summary;

    # Have a look at the results with the rotated loadings - can only call this method if the 'rotate' => 1.
    $fac->fac_print_rotated_summary;

    # create a reference containing a LoL of the loadings.
    $fac->return_loadings;
  
=cut
=head1 DESCRIPTION

Factor analysis is a statistical method by which the variability of a large set of observed variables is described in
terms of a smaller set of unobserved variables termed factors. Factor analysis uses the premise that data observed from
such a large number of variables are in some way a function of these factors that cannot be measured directly.
The observed variables are modeled as linear combinations of the factors. Factor analysis is related to principal
component analysis (PCA). However, unlike PCA that takes into account all variability in the variables, factor analysis 
estimates how much of the variability is due to common factors ("communality"). See http://en.wikipedia.org/wiki/Factor_analysis.

=cut

=head1 METHODS

=head3 new

Object constructor. May pass arguments upon object construction - see OBJECT CONSTRUCTOR OPTIONS.

    my $pca = Statistics::FactorAnalysis->new(dist_check => 1);

=head3 load_data

Used to load the data into the object. Requires you to set 'LoL' and 'format' options (can set these during object
creation if you wish). LoL is a reference to a LoL containing the data. While, 'format' option specifies the nature of
the LoL. If your data is in the format of a table (i.e. each nested reference corresponds to an observation) use
'table'. Thus in this case of 7 variables with 23 observations (of random data) we load as:

    my $data = [
            # Variables: 1,   2,   3,   4,   5,   6,   7,
                    [qw/ 1038 1348 4472 2627 6466 2366 6862 /],     # obs1
                    [qw/ 369  1483 4388 3407 3596 3984 5746 /],     # obs2
                    [qw/ 622  749  2174 2299 153  300  4220 /],     # obs3
                    [qw/ 1731 1658 3527 3094 3335 837  5739 /],     # ...
                    [qw/ 1109 401  5587 2721 1921 1304 5646 /],
                    [qw/ 1274 952  3454 2705 3255 1909 4848 /],
                    [qw/ 517  1039 2560 2814 437  3800 7089 /],
                    [qw/ 2043 1488 6247 2804 4486 1994 5160 /],
                    [qw/ 1106 791  2238 2155 2769 2135 5514 /],
                    [qw/ 201  1344 2778 2500 755  2089 6083 /],
                    [qw/ 665  488  4399 2503 91   5148 5187 /],
                    [qw/ 593  591  1750 2701 155  1956 4491 /],
                    [qw/ 1117 744  4738 3058 480  1513 5154 /],
                    [qw/ 563  1472 2918 2914 1954 2160 6029 /],
                    [qw/ 2448 1076 6680 2940 5697 1943 5870 /],
                    [qw/ 2201 1475 3141 2596 5327 1918 4923 /],
                    [qw/ 1036 784  3872 2723 1263 2036 5287 /],
                    [qw/ 2715 1170 6634 2710 9577 4800 5901 /],
                    [qw/ 700  384  2017 3022 52   1100 4055 /],
                    [qw/ 593  450  3458 2557 268  816  4765 /],
                    [qw/ 394  1035 1922 2652 68   937  6213 /],
                    [qw/ 1097 938  3374 2920 2797 1327 3894 /],
                    [qw/ 212  1179 2768 2687 122  918  4694 /],     # obs23
            ];

    $fac->format(q{table});
    $fac->LoL($data);
    $fac->load_data;

For the same sample of 7 variables with 23 observations if each nested LIST corresponds to a reference as below we use
the 'variable' argument to the format option:

    my $data = [   # obs 1,   2,   3,   ...,                                                                                           23
                    [qw/ 1038 369  622  1731 1109 1274 517  2043 1106 201  665  593  1117 563  2448 2201 1036 2715 700  593  394  1097 212  /],
                    [qw/ 1348 1483 749  1658 401  952  1039 1488 791  1344 488  591  744  1472 1076 1475 784  1170 384  450  1035 938  1179 /],
                    [qw/ 4472 4388 2174 3527 5587 3454 2560 6247 2238 2778 4399 1750 4738 2918 6680 3141 3872 6634 2017 3458 1922 3374 2768 /],
                    [qw/ 2627 3407 2299 3094 2721 2705 2814 2804 2155 2500 2503 2701 3058 2914 2940 2596 2723 2710 3022 2557 2652 2920 2687 /],
                    [qw/ 6466 3596 153  3335 1921 3255 437  4486 2769 755  91   155  480  1954 5697 5327 1263 9577 52   268  68   2797 122  /],
                    [qw/ 2366 3984 300  837  1304 1909 3800 1994 2135 2089 5148 1956 1513 2160 1943 1918 2036 4800 1100 816  937  1327 918  /],
                    [qw/ 6862 5746 4220 5739 5646 4848 7089 5160 5514 6083 5187 4491 5154 6029 5870 4923 5287 5901 4055 4765 6213 3894 4694 /],
            ];

    $fac->format(q{variable});
    $fac->LoL($data);
    $fac->load_data;

=head2 PRINCIPAL COMPONENT ANALYSIS METHODS

This module performs PCA using the Statistics::PCA module. However, it introduced some additional options to give added
flexibility e.g. C<standardise>, C<divisor> - see OPTIONS. Performing PCA analysis may be useful for making initial decisions about factor number to use.

=head3 pca

Performs optional PCA analysis. 

=head3 pca_print_variance

Alias for original Statistics::PCA C<print_variance> method. Prints a table of PC standard deviations, proportion of variance and
cumulative variance to STDOUT.

=head3 pca_print_eigenvectors

Alias for original Statistics::PCA C<print_eigenvectors> method. Prints a table of the individual eigenvectors to STDOUT .

=head3 pca_print_transform

Alias for original Statistics::PCA C<print_transform> method. Prints a table of the PCA transformed data to STDOUT.

=head3 pca_summary

Alias for original Statistics::PCA C<results> method. Prints summary of PCA analysis results to STDOUT.

=head2 FACTOR ANALYSIS METHODS

=head3 fac

Estimates parameters for factor model using the Principal Component Method.

=head3 fac_print_loadings

Prints a table to STDOUT of the loadings generated by C<fac> method.

=head3 fac_print_rotated_loadings

Prints a table to STDOUT of the rotated loadings generated by C<fac> method with C<rotation> option set to '1'.

=head3 fac_print_communalities

Prints a table to STDOUT of the communalities generated by C<fac> method.

=head3 fac_print_variance_explained

Prints a table to STDOUT of the variances explained by the individual factors generated by C<fac> method.

=head3 fac_print_summary

Prints a table to STDOUT summarising all data generated by C<fac> method.

=head3 fac_print_rotated_summary

Prints a table to STDOUT summarising all data generated by C<fac> method from rotated loadings.

=head2 DIRECT DATA ACCESS/RETURN METHODS

=head3 return_variable_number

    Description:    Returns total number of variables.
    Usage:          my $var_num = $fac->return_variable_number;
    Return type:    Number.

=head3 return_variable_measurements

    Description:    Returns the total number of observations. 
    Usage:          my $obs_num = $fac->return_variable_measurements;
    Return type:    Number.

=head3 return_total_variance

    Description:    Returns sum of variances of analysed data.
    Usage:          my $variance = $fac->return_total_variance;
    Return type:    Number.

=head3 return_total_communality 

    Description:    Returns the sum of the communalities of the analysed data.
    Usage:          my $communality = $fac->return_total_communality;
    Return type:    Number.

=head3 return_total_percentage_explained_by_factors

    Description:    Returns the total percentage of variance explained by the factors.
    Usage:          my $percentage = $fac->return_total_percentage_explained_by_factors;
    Return type:    Number.

=head3 return_variances

    Description:    Returns the variances of the analysed variables.
    Usage:          my @variances - $fac->return_variances_explained_by_factors;
    Return type:    LIST.

=head3 return_communalities

    Description:    Returns the individual communalities for the variables.
    Usage:          my @communalities = $fac->return_communalities;
    Return type:    LIST.

=head3 return_variances_explained_by_factors

    Description:    Returns the variance explained each of the factors for the loadings generated by the PC method.
    Usage:          my @variances_explained = $fac->return_variances_explained_by_rotated_factors;
    Return type:    LIST.

=head3 return_variances_explained_by_rotated_factors

    Description:    Returns the variance explained each of the factors for the rotated loadings generated by Varimax rotation of the original loadings.
    Usage:          my @@variances_explained = $fac->return_variances_explained_by_rotated_factors;
    Return type:    LIST.

=head3 return_percentages_explained_by_factors

    Description:    Returns the percentage of variance explained by the factors for each of observed variables.
    Usage:          my @percentage = $fac->return_percentages_explained_by_factors;
    Return type:    LIST.

=head3 return_pca_cumulative_variances

    Description:    Returns the cumulative variances for each successive Principal Component generated by a PCA analysis.
    Usage:          my @cumulative_variance = $fac->return_pca_cumulative_variances;
    Return type:    LIST.

=head3 return_orthogonal_matrix

    Description:    Returns a LoL of the orthogonal matrix generated by Varimax rotation.
    Usage:          for ($pca->return_orthogonal_matrix) { print @{$_}, qq{\n} }
    Return type:    LoL.

=head3 return_loadings

    Description:    Returns a LoL of the loadings generated by PC method factor analysis - each nested array contains the loadings for a single factor.
    Usage:          for ($pca->return_loadings) { print @{$_}, qq{\n} }
    Return type:    LoL.

=head3 return_rotated_loadings

    Description:    Returns a LoL of the rotated loadings generated by Varimax rotation - each nested array contains the rotated loadings for a single factor.
    Usage:          for ($pca->return_rotated_loadings) { print @{$_}, qq{\n} }
    Return type:    LoL.

=cut

=head1 OPTIONS

=head2 COMPULSORY DATA INPUT OPTIONS

=head3 format

    Purpose:        Defines format of LoL being passed to object. If the nested arrays contain the data of the different variables or of the different observations 
                    use 'variable', or 'table' respectively. See METHODS.
    Values:         'table', 'variable'. 
    Default value: 

=head3 LoL
    
    Purpose:        Used for passing the data to the object. Accepts a reference to a LoL containing the data. 
    Values:         Reference to LoL. 
    Default value:  

=head2 OPTIONAL DATA CHECKS

=head3 dist_check
    
    Purpose:        Tells object whether to perform checks on the skewness and kurtosis of the data of the variables during the load_data method call. It prints 
                    warnings to STDOUT if any variable deviates beyond acceptable cutoffs. 
    Values:         '1', '0'. 
    Default value:  '0'.

=head3 dist_croak
    
    Purpose:        Causes Statistics::FactorAnalysis to croak on load_data method calls instead of print to STDOUT if variables deviate beyond acceptable cutoffs
    Values:         '1', '0'. 
    Default value:  '0'.

=head3 skewness
    
    Purpose:        Sets the cutoff value for skewness. 
    Values:         Numeric.
    Default value:  0.8.

=head3 kurtosis
    
    Purpose:        Sets the cutoff value for kurtosis.
    Values:         Numeric.
    Default value:  3.

=head2 OPTIONAL DATA ANALYSIS OPTIONS.

=head3 standardise
    
    Purpose:        Used to tell the object whether to standardise the variables prior to subjecting them to the principal component method such that all have mean 
                    zero and variance equal to one. 
    Values:         'Y', 'N'. 
    Default value:  'Y'.

=head3 factors
    
    Purpose:        Sets the number of factors to be used for the factor model. 
    Values:         Numeric. 
    Default value:  3.

=head3 rotate
 
    Purpose:        Tells object whether to perform Varimax rotation of the PC generated loadings using the Statistics::PCA::Varimax module.
    Values:         'Y', 'N'. 
    Default value:  'N'.

=head3 divisor
    
    Purpose:        Used to set the divisor for covariant matrix generation. To use N pass '0'. To use N-1 pass '-1'.
    Values:         '0', '-1'.
    Default value:  '0'.

=head3 eigen_method
    
    Purpose:        Used to define which module will be used to perform the eigen decomposition. To use Math::Cephes pass 'C'. For Math::MatrixReal pass 'M'. For the 
                    gsl C library procedure implemented by Math::GSL::Linalg::SVD pass 'G'.
    Values:         'M', 'C', 'G'. 
    Default value:  'M'.

=head2 TABLE PRINTING METHOD OPTIONS

=head3 cutoff 

    Purpose:        Turns on cutoffs for printing loading values - if the loading value is below the cutoff value cutoff_null will be printed instead.
    Values:         '0', '-1'. 
    Default value:  '0'.

=head3 cutoff_value 

    Purpose:        Sets the cutoff value for printing loadings.
    Values:         Numeric. 
    Default value:  0.1

=head3 cutoff_null 

    Purpose:        Sets the string to print in place of the loading if the loading is below the cutoff value.
    Values:         String.
    Default value:  ''.

=cut

use version; our $VERSION = qv('0.0.2');

# extends 'Statistics::PCA', 'Moose::Object';
extends 'Statistics::PCA';

#=fs***METHOD ALIASES***
sub pca_print_variance { shift->print_variance }
sub pca_print_eigenvectors { shift->print_eigenvectors }
sub pca_print_transform { shift->print_transform }
sub pca_summary { shift->results }
#=fe

#///////////////////////////////////////////////////// ATTRIBUTES /////////////////////////////////////////////////////////

#=fs***ATTRIBUTE DECLARATIONS***
has 'data'                      => ( is => 'rw', isa => q{HashRef}, );
has 'eigen_method'              => ( is => 'rw', isa => q{Str}, default => q{M}, );
has 'flags'                     => ( is => 'rw', isa => q{HashRef}, );
has 'summaries'                 => ( is => 'rw', isa => q{HashRef}, );
has 'communalities_for'         => ( is => 'rw', isa     => 'ArrayRef', );
has 'communalities_trans'       => ( is => 'rw', isa     => 'ArrayRef', );
has 'divisor'                   => ( is => 'rw', isa => q{Num}, default => q{0}, );
has 'factors'                   => ( is => 'rw', isa     => 'Num', default => 3, );
has 'loadings'                  => ( is => 'rw', isa     => 'ArrayRef', ); # required => 1,  #auto_deref => 1,
has 'overall_variance'          => ( is => 'rw', isa     => 'Num', );
has 'overall_communality'       => ( is => 'rw', isa     => 'Num', );
has 'overall_percentage'          => ( is => 'rw', isa     => 'Num', );
has 'percent_explained'         => ( is => 'rw', isa     => 'ArrayRef', );
has 'standardise'               => ( is => 'rw', isa => q{Str}, default => q{Y}, );
has 'sum_of_squared_loadings'   => ( is => 'rw', isa     => 'ArrayRef', );
has 'variance_new'              => ( is => 'rw', isa     => 'ArrayRef', );
has 'variance_old'              => ( is => 'rw', isa     => 'ArrayRef', );
has 'variance_adj'              => ( is => 'rw', isa     => 'ArrayRef', );
has 'format'                            => ( is => 'rw', isa     => 'Str');
has 'LoL'                               => ( is => 'rw', isa     => 'ArrayRef');
has 'rotate'                            => ( is => 'rw', isa     => 'Str', default => 0 );
has 'rotated_loadings'                  => ( is => 'rw', isa     => 'ArrayRef' ); 
has 'orthogonal_matrix'                 => ( is => 'rw', isa     => 'ArrayRef' ); 
has 'cutoff'                            => ( is => 'rw', isa     => 'Num', default => 0 );
has 'cutoff_value'                      => ( is => 'rw', isa     => 'Num', default => 0.1 );
has 'cutoff_null'                              => ( is => 'rw', isa     => 'Str', default => q{ } );
has 'sum_of_squared_rotated_loadings'   => ( is => 'rw', isa     => 'ArrayRef', );
has 'communalities_for_rotated'         => ( is => 'rw', isa     => 'ArrayRef', );
has 'percent_explained_rotated'         => ( is => 'rw', isa     => 'ArrayRef', );
has 'overall_variance_rotated'          => ( is => 'rw', isa     => 'Num', );
has 'overall_communality_rotated'       => ( is => 'rw', isa     => 'Num', );
has 'overall_percentage_rotated'          => ( is => 'rw', isa     => 'Num', );
has 'dist_check'                              => ( is => 'rw', isa     => 'Num', default => 0 );
has 'dist_croak'                              => ( is => 'rw', isa     => 'Num', default => 0 );
has 'skewness'                              => ( is => 'rw', isa     => 'Num', default => 0.8 );
has 'kurtosis'                              => ( is => 'rw', isa     => 'Num', default => 3);
#=fe

#////////////////////////////////////////////////////// OVERRIDES /////////////////////////////////////////////////////////

#=fs***OVERRIDING***
override (q{_calculate_CVs}, \&calculate_CVs_n_not_n_minus_1);
override (q{_calculate_adjustment}, \&_calculate_adjustment_standardise_or_not);
override (q{pca}, \&_pca_new);
override (q{_calculate_averages}, \&_calculate_averages_arg);

#r this does divisor n and n-1
sub calculate_CVs_n_not_n_minus_1 {
    my $self = shift;
    
    my $div = $self->divisor;
    croak qq{\nI don\'t recognise that value for the \'divisor\' option - requires \'0\' or \'-1\' (defaults to \'Y\' without option).} 
        if ( $div !~ /\A(0|-1)\z/xms );
   
    my $adjusted = $self->{data}{adjusted};
    
    my $var_num = $self->{summaries}{var_num};
    my $length = $self->{summaries}{var_length};
    my $covariance_matrix_ref = [];
    
    if ( $div == 0 ) {
    
        for my $row ( 0..($var_num-1) ) {
            for my $col ( 0..($var_num-1) ) {
                my $sum = 0;
                for my $iteration (0..$#{$adjusted->[0]}) {
                    my $val = $adjusted->[$col][$iteration] * $adjusted->[$row][$iteration];
                    $sum += $val;
                }
                #my $cv = $sum / ($length-1);
                my $cv = $sum / $length;
                $covariance_matrix_ref->[$col][$row] = $cv;
            }
        }
        
        $self->{summaries}{covariate_matrix} = $covariance_matrix_ref;
    
    }
    elsif ( $div == -1 ) {
        
        for my $row ( 0..($var_num-1) ) {
            for my $col ( 0..($var_num-1) ) {
                my $sum = 0;
                for my $iteration (0..$#{$adjusted->[0]}) {
                    my $val = $adjusted->[$col][$iteration] * $adjusted->[$row][$iteration];
                    $sum += $val;
                }
                my $cv = $sum / ($length-1);
                #my $cv = $sum / $length;
                $covariance_matrix_ref->[$col][$row] = $cv;
            }
        }
        
        $self->{summaries}{covariate_matrix} = $covariance_matrix_ref;
    
    }

    else { croak qq{\nI wanted an option for divisor}; }
    
    return;
}

#r this has standardise versus not-standardise
sub _calculate_adjustment_standardise_or_not {
    my $self = shift;

    my $trans = $self->{data}{transpose};
    my $totals = $self->{summaries}{totals};
    my $variances = $self->variance_new;

    my $adjust = [];
 
    my $stand = $self->standardise;
    croak qq{\nI don\'t recognise that value for the \'standardise\' option - requires \'Y\' or \'N\' (defaults to \'Y\' without option).} if ( $stand !~ /\A[YN]\z/xms );
  
    if ( $stand eq q{Y} ) {
        
        for my $row ( 0..($self->{summaries}{var_num}-1) ) {
            
            @{$adjust->[$row]} = map { ( $_ - $totals->[$row]{average}) / sqrt($variances->[$row]) } @{$trans->[$row]};
        
        }
        
        $self->{data}{adjusted} = $adjust;
    
    } 
    
    elsif ($stand eq q{N} ) {
        
        for my $row ( 0..($self->{summaries}{var_num}-1) ) {
        
            @{$adjust->[$row]} = map { ( $_ - $totals->[$row]{average}) } @{$trans->[$row]};
        
        }
        
        $self->{data}{adjusted} = $adjust;
    
    }
    else { croak qq{\nI asked whether to standardise or not?}; }

    return;
}

#r this is generic - accepts transpose and adjusted as args - allows re-calculation of ave/var after standardisation
sub _calculate_averages_arg {
    
    my ($self, $which) = @_;
    croak qq{\nyou called the method wrong} if ( ( $which ne q{transpose} ) && ( $which ne q{adjusted} ) );
    
    my $new_data = $self->{data}{$which};

    my $totals_ref = [];

    for my $row ( 0..($self->{summaries}{var_num}-1) ) { 

    my $sum = sum @{$new_data->[$row]};
    my $length = scalar ( @{$new_data->[$row]} );
    my $average = $sum / $length;

    push @{$totals_ref}, { sum => $sum, length => $length, average => $average};

    }

    $self->{summaries}{totals} = $totals_ref;
    return;
}

#r this is generic - accepts transpose and adjusted as args - allows re-calculation of ave/var after standardisation
sub _calculate_variance_new {
    
    my ($self, $which) = @_;
    
    croak qq{\nyou called the method wrong} if ( ( $which ne q{transpose} ) && ( $which ne q{adjusted} ) );

    my $new_data = $self->{data}{$which};
    my $totals = $self->{summaries}{totals};
    my $var = [];

    for my $row ( 0..($self->{summaries}{var_num}-1) ) { 

        my $sum = sum map { ($_ - $totals->[$row]{average})**2 } @{$new_data->[$row]};
        my $length = scalar ( @{$new_data->[$row]} );
        my $variance = $sum / $length;

        push @{$var}, $variance;

    }
    
    $self->variance_new($var); 

    return;
}

#=fe

#/////////////////////////////////////////////////////// LOADING //////////////////////////////////////////////////////////

#=fs***LOADING*** - includes wrapping load_data to make consistent attribute passing
#/ we change the calling manner of the original procedure and add a couple of extra checks afterwards
around load_data => sub {
    my $load_data_ref = shift;
    my $self = shift;
    
    croak qq{\nYou must set the \x27format\x27 option} if ( !defined $self->format );
    croak qq{\nYou must set the \x27LoL\x27 option} if ( !defined $self->LoL );

    my $LoL = $self->LoL;

    #/ the original sub
    $self->$load_data_ref( { format => $self->format, data => $LoL } );

    # matrixreal has very good data checking to make sure its a real numeric matrix - so lets make one just as a final check - let it fall out of scope and be recycled immediately
    croak qq{\nThere\x27s a problem with your data.} if (!Math::MatrixReal->new_from_cols ($LoL));

    croak qq{\nI don\'t recognise that value for the \'dist_check\' option - requires \'1\' or \'0\x27 (defaults to \'0\' without option).} 
          if ( $self->dist_check !~ /\A[01]\z/xms );

    $self->_check_distributions if ( $self->dist_check == 1 )

};

sub _check_distributions {
    my $self = shift;
    
    croak qq{\nI don\'t recognise that value for the \'dist_croak\' option - requires \'1\' or \'0\x27 (defaults to \'0\' without option).} 
          if ( $self->dist_croak !~ /\A[01]\z/xms );
    
    #my $vars = $self->data->transpose;
    my $vars = $self->data->{transpose};

    my $count=1;
    for my $var (@{$vars}) {
    
        my ($skew, $kur) =_check_distribution ( $var );

        if ( ( abs($skew) > $self->skewness ) || ( abs($kur) > $self->kurtosis )) {
            # data has issue
            if ( $self->dist_croak == 1 ) { croak qq{\nVariable $count has skewness $skew and kurtosis $kur - perhaps transform?}; }
            else { print qq{\nVariable $count has skewness $skew and kurtosis $kur - perhaps transform?} }
        }
        $count++;
    }
    return;
}

sub _check_distribution {

    croak qq{\nYou called method incorrectly} if !wantarray;
    my $a_ref = shift;

    my $n = scalar (@{$a_ref});
    my $mean = ( sum @{$a_ref} ) / $n ;
    # pow( $x, power )
    my $m3 = ( ( sum map { ( $_ - $mean )**3 } @{$a_ref} ) / $n );
    my $m2 = ( ( sum map { ( $_ - $mean )**2 } @{$a_ref} ) / $n );
    my $m2_2 = $m2**2;
    my $m2_3_2 = $m2**(3/2);
    my $m4 = ( ( sum map { ( $_ - $mean )**4 } @{$a_ref} ) / $n );
    my $skewness = $m3 / ($m2**(3/2));
    my $kurtosis = ( $m4 / ($m2**2) ) - 3;

    return $skewness, $kurtosis;
}

#=fe

#////////////////////////////////////////////////////// ANALYSIS //////////////////////////////////////////////////////////

#=fs***ANALYSIS***
sub _calculate_variance_old{
    my $self = shift;
    my $adjusted = $self->{data}{adjusted};
    my $length = $self->{summaries}{var_length};
    my $stdev = [];
    for my $adjust ( @{$adjusted} ) {
        #y if you want to use basic data here need to means adjuste here
        my $sum = sum map { $_**2 } @{$adjust};
        my $variance = $sum / ($length);
        push @{$stdev}, $variance;    
    }
    $self->variance_old($stdev);
    return;
}

sub _pca_new {
        
    my $self = shift;
    my $eigen = $self->eigen_method;
    croak qq{\nI don\'t recognise that value for the \'eigen\' option - requires \'M\' or \'C\', \x27G\x27 (defaults to \'M\' without option).} if ( $eigen !~ /\A[MCG]\z/xms );
    $self->_calculate_averages (q{transpose});
   
    #y on the if standardise eq q{Y}
    $self->_calculate_variance_new (q{transpose}) if ($self->standardise eq q{Y});
    
    $self->_calculate_adjustment;
    $self->_calculate_CVs;
    if ( $eigen eq q{M} ) { $self->_calculate_eigens_matrixreal; }
    elsif ( $eigen eq q{C} ) { $self->_calculate_eigens_cephes; }
    elsif ( $eigen eq q{G} ) { $self->_calculate_eigens_gsl; }
    #y re-orders eigenvalues and eigenvectors according to eigenvalue - thus everything from here is in correct order 
    $self->_rank_eigenvalues;
    #y we have ranked data - should put in new positions? so now we do the calculations
    $self->_calculate_components;
    #y generates the prcomp eigenvectors calculation - returns it as an object and also stores the raw data as self->{self}{eigen}
    $self->_transform;
    return;
}

sub fac {
    my $self = shift;
    my $eigen = $self->eigen_method;
    croak qq{\nI don\'t recognise that value for the \'eigen\' option - requires \'M\' or \'C\', \x27G\x27 (defaults to \'M\' without option).} 
          if ( $eigen !~ /\A[MCG]\z/xms );
    
    croak qq{\nI don\'t recognise that value for the \'rotate\' option - requires \'1\' or \'0\x27 (defaults to \'0\' without option).} 
          if ( $self->rotate !~ /\A[01]\z/xms );

    #///////////////// check factor number against var number /////////////////////////
    croak qq{\nWhy are you bothering doing factor analysis with the same number of factors as variables?} 
          if ( $self->summaries->{var_num} <= $self->factors );
    
    $self->_calculate_averages (q{transpose});
    
    $self->_calculate_variance_new (q{transpose});

    #/ this is overridedn for standardise - vs- not standardise
    $self->_calculate_adjustment;

    #/ this is over-riden - i.e. for divisor n versus divisor n-1
    $self->_calculate_CVs;
    
    if ( $eigen eq q{M} ) { $self->_calculate_eigens_matrixreal; }
    elsif ( $eigen eq q{C} ) { $self->_calculate_eigens_cephes; }
    elsif ( $eigen eq q{G} ) { $self->_calculate_eigens_gsl; }
   
    #y re-orders eigenvalues and eigenvectors according to eigenvalue - thus everything from here is in correct order 
    $self->_rank_eigenvalues;
    
    #y we have ranked data - should put in new positions? so now we do the calculations
    #   $self->_calculate_components;

    $self->_calculate_loadings();
    $self->_calculate_sum_of_squared_loadings;
    $self->_calculate_communalities_for;
    $self->_calculate_communalities_trans;
 
    
    #/ if used standardise we need to recalculate the variances
    if ( $self->standardise eq q{Y} ) {
        $self->_calculate_averages (q{adjusted});
        $self->_calculate_variance_new (q{adjusted});
    }
    
    $self->_calculate_percent_explained;

    $self->_calculate_overalls;
   
    if ( $self->rotate == 1 ) {
        $self->_rotate_loadings;
        $self->_calculate_sum_of_squared_loadings (q{rotate});

        #r/ THERE IS NO NEED BUT WE WILL RECALCULATE COMM and PERC and OVERALL AGAIN.
        $self->_calculate_communalities_for (q{rotate});
        $self->_calculate_percent_explained (q{rotate});
        $self->_calculate_overalls (q{rotate});
    }

    return;
}

sub _calculate_eigens_gsl {
    my $self = shift;
    my $covariance_matrix_ref = $self->{summaries}{covariate_matrix};

    my $svd = Math::GSL::Linalg::SVD->new();
    $svd->load_data( { data => $covariance_matrix_ref } );
    $svd->decompose( { algorithm => q{eigen} } );
    my ($e_val_ref, $e_vec_ref) = $svd->results;

    my $overall = [];
    # matrixreal stores data in ->[0] hence additional notation
    @{$overall} = map { +{ solution => $_+1, eigenvalue => $e_val_ref->[$_], eigenvector => $e_vec_ref->[$_] } } (0..$#{$e_val_ref});

    $self->{summaries}{eigen}{raw} = $overall;

    return;
}

sub _rotate_loadings {
    my $self = shift;
    my ($rotated_loadings_ref, $orthogonal_matrix_ref) = Statistics::PCA::Varimax::rotate($self->loadings);
    
    $self->rotated_loadings($rotated_loadings_ref);
    $self->orthogonal_matrix($orthogonal_matrix_ref);
    return;
}

sub _calculate_loadings {
    my $self = shift;

    #/ unecessary clean-up but whatever
    my $clean = _deep_copy_references ($self->{summaries}{eigen}{sorted});
    
    my $loadings = [];
    for my $i ( 0..($self->factors-1) ) {
        
        my $eigenvalue = $clean->[$i]{eigenvalue};

        my @loads = map { $_ * sqrt($eigenvalue) } @{$clean->[$i]{eigenvector}};
        push @{$loadings}, [@loads];

    }
   
    $self->loadings($loadings);

    return;
}

sub _deep_copy_references { 
    my $ref = shift;
    if (!ref $ref) { $ref; } 
    elsif (ref $ref eq q{ARRAY} ) { 
        [ map { _deep_copy_references($_) } @{$ref} ]; 
    } 
    elsif (ref $ref eq q{HASH} )  { 
        + {   map { $_ => _deep_copy_references($ref->{$_}) } (keys %{$ref}) }; 
    } 
    else { die "what type is $_?" }

    #/ do not return on this reciprocally called sub
}

#r this always does standard procedure - unless send extra arg eq q{rotate}
sub _calculate_sum_of_squared_loadings {
    my ( $self, $which )  = @_;
   
    #/ need the value more than once so we actually take it
    #r prefer no default behaviour - I DON´T LIKE DEFAULTS ON THIS SORT OF THING!
    #if (@_ == 1) { my $loadings = $self->loadings; }
    #elsif (@_ ==2 {my $loadings = $self->rotated_loadings; }

    #my $loadings    =   @_ == 1     ?   $loadings = $self->loadings
    #                :   @_ == 2     ?   $self->rotated_loadings
    #                :                   0;

    $which ||= 0; # stop a warning
    my $loadings = $which eq q{rotate} ? $self->rotated_loadings : $self->loadings;

    my $communalities = [];
     
    @{$communalities} = map { sum map { $_**2 } @{$_} } @{$loadings};

    if ( $which eq q{rotate} ) { $self->sum_of_squared_rotated_loadings($communalities); }
    else { $self->sum_of_squared_loadings($communalities); }
}

#r this always does standard procedure - unless send extra arg eq q{rotate}
sub _calculate_communalities_for {
    
    my ( $self, $which )  = @_;
    $which ||= 0; # stop a warning

    my $loadings = $which eq q{rotate} ? $self->rotated_loadings : $self->loadings;

    my $rows = scalar ( @{$loadings} );
    my $cols = scalar ( @{$loadings->[0]} );

    my $communalities = [];

    for my $col ( 0..$cols-1) {

        my $sum = 0;
        for my $row (0..$rows-1) {

            my $val = ($loadings->[$row][$col])**2;
            $sum += $val
        }
    push @{$communalities}, $sum;
    }

    if ( $which eq q{rotate} ) { $self->communalities_for_rotated($communalities); }
    else { $self->communalities_for($communalities); }

    return; 
}

#r this always does standard procedure - unless send extra arg eq q{rotate}
sub _calculate_percent_explained {

    my ( $self, $which )  = @_;
    $which ||= 0; # stop a warning

    my $com = $which eq q{rotate} ? $self->communalities_for_rotated : $self->communalities_for;

    my $var = $self->variance_new;

    my $per = [];
    @{$per} = map { ($com->[$_] / $var->[$_]) * 100 } (0..$#{$var});

    if ( $which eq q{rotate} ) { $self->percent_explained_rotated($per); }
    else { $self->percent_explained($per); }

    return;
}

sub _calculate_overalls {
    my ( $self, $which )  = @_;
    $which ||= 0; # stop a warning

    #r/ variance is always the same!!!
    my $var = $self->variance_new;
    
    my $com = $which eq q{rotate} ? $self->communalities_for_rotated : $self->communalities_for;

    my $var_sum = sum @{$var};
    my $com_sum = sum @{$com};

    if ( $which eq q{rotate} ) { 
        $self->overall_variance_rotated($var_sum);
        $self->overall_communality_rotated($com_sum);
        
        $self->overall_percentage_rotated(100 * ( $com_sum / $var_sum ));
    }
    else { 
        $self->overall_variance($var_sum);
        $self->overall_communality($com_sum);
        
        $self->overall_percentage(100 * ( $com_sum / $var_sum ));
    }

    return;
}

sub transpose {
        
    my $a_ref = shift;

    my $done = [];
    for my $col ( 0..$#{$a_ref->[0]} ) {
    push @{$done}, [ map { $_->[$col] } @{$a_ref} ];
    }

    return $done;
}

sub _calculate_communalities_trans {
    my $self = shift;
    my $loadings = $self->loadings;

    my $trans = transpose($loadings);

    my $communalities = [];
     
    @{$communalities} = map { sum map { $_**2 } @{$_} } @{$trans};
    $self->communalities_trans($communalities);

    return;
}

#=fe

#////////////////////////////////////////////////////// PRINTING //////////////////////////////////////////////////////////

#=fs***PRINTING***
sub fac_print_loadings { shift->_print_lol_ref(q{loadings}); }

sub fac_print_rotated_loadings { shift->_print_lol_ref(q{rotated_loadings}); }

sub _print_lol_ref {
    my ( $self, $arg ) = @_;

    $arg ||= 0; # just stop warnings moaning
    
    croak qq{\nYou can only call this method if you set \x27rotate\x27 to \x271\x27} 
          if ( ( $arg eq q{rotated_loadings} ) && ( $self->rotate == 0 ) );


    #r/ I DON´T LIKE DEFAULTS - in this case loadings
    my $lol =   $arg eq q{loadings}             ?   $self->loadings
            :   $arg eq q{rotated_loadings}     ?   $self->rotated_loadings
            :                                       0;

    croak qq{\nyou called method incorrectly: $lol} if ($lol == 0);

    print qq{\nTable of $arg.\n};

    my @config_full = ( [11, q{}] );

    my @config = map { [ 12, q{Factor_}.$_ ] } ( 1..(scalar (@{$lol})) );
    push @config_full, @config;

    my $t2 = Text::SimpleTable->new(@config_full);

    #/ probably ought to use iterator var and not numeric here
    for my $row (0..$#{$lol->[0]}) {
        
        my @data;
        
        for my $col (0..$#{$lol}) {

            if ( ( $self->cutoff == 1 ) && ( abs ( $lol->[$col][$row] ) < $self->cutoff_value ) ) { push @data, $self->cutoff_null; }
            else { push @data, sprintf (q{%.8f}, $lol->[$col][$row] ); }
        
    }
    my $row_num = $row + 1;
    my $row_name = qq{Variable_$row_num};
    $t2->row( $row_name, @data );
    }
    print $t2->draw;
    return;
}

sub fac_print_communalities {
    my ( $self, $arg ) = @_;
    $arg ||= 0; # just stop warnings moaning

    #r/ must decided between com_for and trans
    my $list_ref = $self->communalities_for;

    my @config_full = ( [11, q{}], [12, q{Communality}] );
    my $t2 = Text::SimpleTable->new(@config_full);

    for my $row (0..$#{$list_ref}) {
        
        my $row_num = $row + 1;
        my $row_name = qq{Variable_$row_num};
        $t2->row( $row_name, sprintf (q{%.8f}, $list_ref->[$row] ) );
    }
    $t2->hr;
    $t2->row( q{Total}, sprintf (q{%.8f}, $self->overall_communality ) );
    print qq{\nTable of Communalities.\n};
    print $t2->draw;
    return;
}

sub fac_print_variance_explained {
    my $self = shift;
    my @list = ();

    push @list, $self->sum_of_squared_loadings;
    push @list, $self->sum_of_squared_rotated_loadings if ( $self->rotate == 1 );

    my @config_full = ( [11, q{}] );

    my @config = map { [ 12, q{Factor_}.$_ ] } ( 1..(scalar (@{$list[0]})) );
    push @config_full, @config, [11, qq{Total}];

    my $t2 = Text::SimpleTable->new(@config_full);

    my $count = 1;    
    for my $ss_loadings (@list) {
        
        my @data;
        for my $i (0..$#{$ss_loadings}) {

            push @data, sprintf (q{%.8f}, $ss_loadings->[$i] );
            
        }
        my $name = $count == 1 ? q{Loadings} : q{Rotated};
        my $sum = sum @data;
        $t2->row( $name, @data, $sum );
    $count++;
        
    }
    print qq{\nTable of variance explained by factors.\n};
    print $t2->draw;
    return;
}

#/ convert normal behaviour 
sub fac_print_rotated_summary { shift->fac_print_summary(q{rotate}) }

#r as with others will have a simple extra arg - can either use @_ = 2 or $arg eq q{rotate} to change behaviour
sub fac_print_summary {
    #my ( $self ) = @_;
    #if (@_ > 1) {...
    my ($self, $arg) = @_;

    $arg ||= 0; # just stop warnings moaning
    
    croak qq{\nYou can only call this method if you set \x27rotate\x27 to \x271\x27} 
          if ( ( $arg eq q{rotate} ) && ( $self->rotate == 0 ) );

    # unecesssary checking that they haven´t passed some stupid option - probably ought to regexp this early on in 
    #my $message1 = $self->rotate == 0           ? q{Varimax rotation} 
    #             : $self->rotate == 1           ? q{Principal component solution}
    #             :                                q{prob};

    #my $message1 = $self->rotate == 0 ? q{Principal component solution} : q{Varimax rotation};

    my $message1 = $arg eq q{rotate} ? q{Varimax rotation} : q{Principal component solution};

    my $message2 = $self->standardise eq q{Y} ? q{standardized variables} : q{unstandardized variables};
    
    print qq{\n$message1 for $message2\n};

    my $variances_ref = $self->variance_new;
    
    #/ no point in evaulating the same damned BOOLEAN more than once or twice - really ought to put the message1 part in here
  
    #r/ twat!!! you MUST declare these variables first outside of the if!!! otherwise they are not visible outside - just allocate values inside
    my $loadings_ref;
    my $comms_ref;
    my $pers_ref;
    my $overall_variance;
    my $overall_communality;
    my $overall_percentage;
    my $sum_of_squared_loadings;

    if ( $arg eq q{rotate} ) {
        $loadings_ref = $self->rotated_loadings;
        $comms_ref = $self->communalities_for_rotated;
        $pers_ref = $self->percent_explained_rotated;
        $overall_variance = $self->overall_variance_rotated;
        $overall_communality = $self->overall_communality_rotated;
        $overall_percentage = $self->overall_percentage_rotated;
        $sum_of_squared_loadings = $self->sum_of_squared_rotated_loadings;
    }
    else {
        $loadings_ref = $self->loadings;
        $comms_ref = $self->communalities_for;
        $pers_ref = $self->percent_explained;
        $overall_variance = $self->overall_variance;
        $overall_communality = $self->overall_communality;
        $overall_percentage = $self->overall_percentage;
        $sum_of_squared_loadings = $self->sum_of_squared_loadings;
    }

    #/ the row names
    my @config_full = ( [11, q{}], [9, q{Variance}] );

    my @config = map { [ 12, q{Factor_}.$_ ] } ( 1..(scalar (@{$loadings_ref})) );
   
    push @config_full, @config, [14, q{Communalities}], [9, q{Percent Explained}];

    my $t2 = Text::SimpleTable->new(@config_full);

    for my $row (0..$#{$loadings_ref->[0]}) {
        
        my @data;
        
        for my $col (0..$#{$loadings_ref}) {

            if ( ( $self->cutoff == 1 ) && ( abs ( $loadings_ref->[$col][$row] ) < $self->cutoff_value ) ) { push @data, $self->cutoff_null; }
            else { push @data, sprintf (q{%.8f}, $loadings_ref->[$col][$row] ); }
        
        }
        my $row_num = $row + 1;
        my $row_name = qq{Variable_$row_num};
        
        #/ the data 
        $t2->row( $row_name, sprintf (q{%.3f}, $variances_ref->[$row]), @data, sprintf (q{%.9f}, $comms_ref->[$row]), sprintf (q{%.3f}, $pers_ref->[$row]) );

    }
    $t2->hr;
    my @sums = map { sprintf (q{%.9f}, $_) } @{$sum_of_squared_loadings};
    $t2->row( q{Overall}, sprintf (q{%.3f}, $overall_variance), @sums, sprintf (q{%.9f}, $overall_communality), sprintf (q{%.3f}, $overall_percentage) );
    print $t2->draw;
    return;
}

#=fe

#////////////////////////////////////////////////////// RETURNS ///////////////////////////////////////////////////////////

#=fs***RETURNS***

# return scalars
sub return_total_communality { return shift->overall_communality; }
sub return_total_variance { return shift->overall_variance; }
sub return_total_percentage_explained_by_factors { return shift->overall_percentage; }
sub return_variable_number { return shift->summaries->{var_num}; }
sub return_variable_measurements { return shift->summaries->{var_length}; }

# return lists - could put wantarray in but that´s their fault if they don´t read at least part of the pod
sub return_communalities { return @{shift->communalities_for}; }
sub return_variances_explained_by_factors { return @{shift->sum_of_squared_loadings}; }
sub return_variances_explained_by_rotated_factors { return @{shift->sum_of_squared_rotated_loadings}; }
sub return_variances { return @{shift->variance_new}; }
sub return_percentages_explained_by_factors { return @{shift->percent_explained}; }
# performing factor analysis will wipe data in object so need to check if they exist first
sub return_pca_cumulative_variances { 
    my $self = shift;
    $self->_calculate_components if ( !defined $self->summaries->{eigen}{sorted}[0]{cumulative_variance} );
    #/ return LIST
    return map { $_->{cumulative_variance} } @{$self->summaries->{eigen}{sorted}};
    #/ return LIST ref
    # return [ map { $_->{cumulative_variance} } @{$self->summaries->{eigen}{sorted}}] ;
}

# return LoL_ref - reference to a LoL
#sub return_orthogonal_matrix { return shift->orthogonal_matrix; }
# return LoL 
sub return_orthogonal_matrix { return @{shift->orthogonal_matrix}; }
sub return_loadings { return @{shift->loadings}; }
sub return_rotated_loadings { return @{shift->rotated_loadings}; }

#=fe

no Moose;
# no need to fiddle with inline_constructor here
__PACKAGE__->meta->make_immutable;

1; # Magic true value required at end of module

__END__

=head1 DEPENDENCIES

'Carp'                      =>  '1.08',
'Moose'                     =>  '0.93',
'MooseX::NonMoose'          =>  '0.07',
'Statistics::PCA'           =>  '0.0.1',
'Statistics::PCA::Varimax'  =>  '0.0.2',
'Math::GSL::Linalg::SVD'    =>  '0.0.2', 
'List::Util'                =>  '1.22',

=cut

=head1 AUTHOR

Daniel S. T. Hughes  C<< <dsth@cantab.net> >>

=cut 

=head1 SEE ALSO

L<Statistics::PCA>, L<Statistics::PCA::Varimax>,L<Math::GSL::Linalg::SVD>.

=cut

=head1 BUGS

This software is in early stage of development. I´m sure there will be bugs.

=cut

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Daniel S. T. Hughes C<< <dsth@cantab.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

=head1 DISCLAIMER OF WARRANTY

because this software is licensed free of charge, there is no warranty
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

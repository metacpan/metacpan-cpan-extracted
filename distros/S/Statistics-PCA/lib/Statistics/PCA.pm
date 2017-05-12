#!/usr/bin/perl -w
package Statistics::PCA;
#package Statistics::PCA;
use strict;
use warnings;
use Carp;
use Math::Cephes::Matrix qw(mat);
use List::Util qw(sum);
use Math::MatrixReal;
use Text::SimpleTable;
use Math::Cephes qw(:utils);
use Contextual::Return;
=head1 NAME

Statistics::PCA - A simple Perl implementation of Principal Component Analysis.

=cut
=head1 VERSION

This document describes Statistics::PCA version 0.0.1

=cut
=head1 SYNOPSIS

    use Statistics::PCA;

    # Create new Statistics::PCA object.
    my $pca = Statistics::PCA->new;

    #                  Var1    Var2    Var3    Var4...
    my @Obs1 = (qw/    32      26      51      12    /);
    my @Obs2 = (qw/    17      13      34      35    /);
    my @Obs3 = (qw/    10      94      83      45    /);
    my @Obs4 = (qw/    3       72      72      67    /);
    my @Obs5 = (qw/    10      63      35      34    /);

    # Load data. Data is loaded as a LIST-of-LISTS (LoL) pointed to by a named argument 'data'. Requires argument for format (see METHODS).
    $pca->load_data ( { format => 'table', data => [ \@Obs1, \@Obs2, \@Obs3, \@Obs4, \@Obs5 ], } ) ;

    # Perform the PCA analysis. Takes optional argument 'eigen' (see METHODS). 
    #$pca->pca( { eigen => 'C' } );
    $pca->pca();

    # Access results. The return value of this method is context-dependent (see METHODS). To print a report to STDOUT call in VOID-context.
    $pca->results();
  
=cut
=head1 DESCRIPTION

Principal component analysis (PCA) transforms higher-dimensional data consisting of a number of possibly correlated variables into a smaller number of
uncorrelated variables termed principal components (PCs). The higher the ranking of the PCs the greater the amount of
variability that the PC accounts for. This PCA procedure involves the calculation of the eigenvalue decomposition using either the Math::Cephes::Matrix or
Math::MatrixReal modules (see METHODS) from a data covariance matrix after mean centering the data. See
http://en.wikipedia.org/wiki/Principal_component_analysis for more details.

=cut
=head1 METHODS

=cut
use version; our $VERSION = qv('0.0.1');


#y////////////////////////////////////////////// CONSTRUCTOR AND DATA LOADING /////////////////////////////////////////
#=fs CONSTRUCTOR AND DATA LOADING

#sub diag {
#    my $self = shift;
#    print Dumper $self;
#    return;
#}

=head2 new

Create a new Statistics::PCA object.

    my $pca = Statistics::PCA->new;

=cut
sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}
    
#/ this will work for a matrix of values where ALL data is complete - i.e. 
=head2 load_data

Used for loading data into object. Data is fed as a reference to a LoL within an anonymous hash using the
named argument 'data'. Data may be entered in one of two forms specified by the obligatory named argument 'format'.
Data may either be entered in standard 'table' fashion (with rows corresponding to observations and columns corresponding
to variables). Thus to enter the following table of data:

            Var1    Var2    Var3    Var4

    Obs1    32      26      51      12  
    Obs2    17      13      34      35        
    Obs3    10      94      83      45        
    Obs4    3       72      72      67        
    Obs5    10      63      35      34 ...

The data is passed as an LoL with the with each nested ARRAY reference corresponding to a row of observations in the
data table and the 'format' argument value 'table' as follows:

    #                       Var1    Var2    Var3    Var4 ...
    my $data  =   [   
                    [qw/    32      26      51      12    /],     # Obs1
                    [qw/    17      13      34      35    /],     # Obs2
                    [qw/    10      94      83      45    /],     # Obs3
                    [qw/    3       72      72      67    /],     # Obs4
                    [qw/    10      63      35      34    /],     # Obs5 ...
                ];

    $pca->load_data ( { format => 'table', data => $data, } );

Alternatively you may enter the data in a variable-centric fashion where each nested ARRAY reference corresponds to a 
single variable within the data (i.e. the transpose of the above table-fashion). To pass the above data in this fashion
use the 'format' argument with value 'variable' as follows:

    #                           Obs1    Obs2    Obs3    Obs4    Obs5 ...
    my $transpose = [
                        [qw/    32      17      10      3       10    /],   # Var1
                        [qw/    26      13      94      72      63    /],   # Var2
                        [qw/    51      34      83      72      35    /],   # Var3
                        [qw/    12      35      45      67      34    /],   # Var4 ...
                    ];

    $pca->load_data ( { format => 'variable', data => $transpose, } ) ;

=cut
sub load_data {
    #my ( $self, $data ) = @_;
    my ( $self, $h_ref ) = @_;
    croak qq{\nArguments must be passed as HASH reference.} if ( ( $h_ref ) && ( ref $h_ref ne q{HASH} ) );
    
    my $data_dirty = $h_ref->{data};
    
    #y clean it now to stop strange internal references
    my $data = _deep_copy_references($data_dirty);

    croak qq{\nYou must specify a data format} if ( !exists $h_ref->{format} );
    my $format_val = $h_ref->{format};

    my %formating = (   table       =>  sub {   $self->_transpose($data);                           },
                        #y no point in have direct method its so short just put it here
                        #variable    =>  sub {   $self->_direct              },      # just do the calculations directly and put the data in
                        variable    =>  sub {
                                                $self->{summaries}{var_num} = scalar ( @{$data} ); 
                                                $self->{summaries}{var_length} = scalar ( @{$data->[0]} );
                                                $self->{data}{transpose_temp} = $data; return;     },
                    );

    my $format = $formating{$format_val};
    croak qq{\nYou must pass a recognised option: \"table\", \"variable\"} if ( !defined $format );

    #y &{$cd}() = &$cd() = &$cd = $cd->();
    $format->();

    $self->_data_checks;

    #y adjust flag
    $self->{flags}{data_loaded} = 1;

    return;

}

sub _direct {
    my ( $self, $a_ref ) = @_;

    my $var_num = scalar ( @{$a_ref} );
   
    my $var_length = scalar ( @{$a_ref->[0]} );

    $self->{data}{transpose_temp} = $a_ref;
    $self->{summaries}{var_num} = $var_num;
    $self->{summaries}{var_length} = $var_length;

    return;
}

sub _transpose {
    
    my ( $self, $a_ref ) = @_;

    my $var_length = scalar ( @{$a_ref} );

    my $done = [];
    for my $col ( 0..$#{$a_ref->[0]} ) {
        push @{$done}, [ map { $_->[$col] } @{$a_ref} ];
        }

    my $var_num = scalar ( @{$done} );
    
    $self->{data}{transpose_temp} = $done;
    $self->{summaries}{var_num} = $var_num;
    $self->{summaries}{var_length} = $var_length;
    
    return;
}

sub _data_checks {

    my $self = shift; 

    my $data_a_ref = $self->{data}{transpose_temp};

    my $rows = $self->{summaries}{var_num};
    croak qq{\nI need some data - there are too few rows in your data.\n} if ( !$rows || $rows == 1 );

    my $cols = $self->{summaries}{var_length};
    croak qq{\nI need some data - there are too few columns in your data.\n} if ( !$cols || $cols == 1 );

    for my $row (@{$data_a_ref}) {

        croak qq{\n\nData set must be passed as ARRAY references.\n} if ( ref $row ne q{ARRAY} );
        croak qq{\n\nAll rows must have the same number of columns.\n} if ( scalar( @{$row} ) != $cols );

    }
  
    #/ all fine and dandy.
    print qq{\nData has $rows variables and $cols observations. Passing data to object.};
    $self->{data}{transpose} = $data_a_ref;
    delete $self->{data}{transpose_temp};

    return;
}

#=fe


#y/////////////////////////////////////////////////////// ANALYSIS ////////////////////////////////////////////////////
#=fs ANALYSIS

=head2 pca

To perform the PCA analysis. This method takes the optional named argument 'eigen' that takes the values 'M' or 'C' to
calculate the eigenvalue decomposition using either the Math::MatrixReal or Math::Cephes::Matrix modules respectively
(defaults to 'M' without argument).

    $pca->pca();   
    $pca->pca( { eigen => 'M' } );
    $pca->pca( { eigen => 'C' } );

=cut
sub pca {
    
    my ( $self, $h_ref ) = @_;
    croak qq{\nArguments must be passed as HASH reference.} if ( ( $h_ref ) && ( ref $h_ref ne q{HASH} ) );
    
    exists $h_ref->{eigen} || print qq{\nUsing default option of Math::MatrixReal to calculate eigen values.};
    
    my $eigen = exists $h_ref->{eigen} ? $h_ref->{eigen} : q{M};

    croak qq{\nI don\'t recognise that value for the \'eigen\' option - requires \'M\' or \'C\' (defaults to \'M\' without option).}
          if ( $eigen !~ /\A[MC]\z/xms );

    $self->_calculate_averages;
    $self->_calculate_adjustment;
    $self->_calculate_CVs;

    if ( $eigen eq q{M} ) { $self->_calculate_eigens_matrixreal; }
    # overkill here
    elsif ( $eigen eq q{C} ) { $self->_calculate_eigens_cephes; }

    #y re-orders eigenvalues and eigenvectors according to eigenvalue - thus everything from here is in correct order 
    $self->_rank_eigenvalues;

    #y we have ranked data - should put in new positions? so now we do the calculations
    $self->_calculate_components;

    #y generates the prcomp eigenvectors calculation - returns it as an object and also stores the raw data as self->{self}{eigen}
    $self->_transform;

    return;
}

sub _calculate_averages {
    my $self = shift;
    my $new_data = $self->{data}{transpose};

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

sub _calculate_adjustment {
    my $self = shift;
    
    my $trans = $self->{data}{transpose};

    my $totals = $self->{summaries}{totals};

    my $adjust = [];

    for my $row ( 0..($self->{summaries}{var_num}-1) ) {

        @{$adjust->[$row]} = map { $_ - $totals->[$row]{average} } @{$trans->[$row]};

    }

    $self->{data}{adjusted} = $adjust;
}

sub _calculate_CVs {
    my $self = shift;

    my $adjusted = $self->{data}{adjusted};
    my $var_num = $self->{summaries}{var_num};
    my $length = $self->{summaries}{var_length};
    my $sum = 0;
    my $covariance_matrix_ref = [];

    for my $row ( 0..($var_num-1) ) {

        for my $col ( 0..($var_num-1) ) {
               
            my $sum = 0;
            for my $iteration (0..$#{$adjusted->[0]}) {

                my $val = $adjusted->[$col][$iteration] * $adjusted->[$row][$iteration];
                    
                $sum += $val;
            }
                
            my $cv = $sum / ($length-1);

            $covariance_matrix_ref->[$col][$row] = $cv;
        }
    }

    $self->{summaries}{covariate_matrix} = $covariance_matrix_ref;
    return;

}

sub _calculate_eigens_matrixreal {
    my $self = shift;

    my $covariance_matrix_ref = $self->{summaries}{covariate_matrix};

    my $covariance_matrix_perl = Math::MatrixReal->new_from_cols ( $covariance_matrix_ref ) ;
    my ($eigen_val_perl, $eigen_vec_perl) = $covariance_matrix_perl->sym_diagonalize();
    my $eigen_vec_perl_T = ~$eigen_vec_perl;
    my $eigen_val_perl_T = ~$eigen_val_perl;

    my $overall_alt = [];
    @{$overall_alt} = map { +{ solution => $_+1, eigenvalue => $eigen_val_perl_T->[0][0][$_], eigenvector => $eigen_vec_perl_T->[0][$_] } } (0..$#{$eigen_val_perl_T->[0][0]});
    
    $self->{summaries}{eigen}{raw} = $overall_alt;
    
    return;
}

sub _calculate_eigens_cephes {
    my $self = shift;
    
    my $covariance_matrix_ref = $self->{summaries}{covariate_matrix};
    my $covariance_matrix = mat ( $covariance_matrix_ref ) ;

    my ($eigen_val, $eigen_vec) = $covariance_matrix->eigens();
    my $eigen_vec_ref = $eigen_vec->coef;

#print Dumper       $eigen_val,                       $eigen_vec_ref;
#print Dumper       $eigen_val_perl_T->[0][0],        $eigen_vec_perl_T->[0];

    #y we don´t need it but we will force perl to intepret {} as anon HASH and not BATCH with '+' 
    my $overall = [];

    #@{$overall} = map { +{ solution => $_, eigenvalue => $eigen_val->[$_], eigenvector => $eigen_vec_ref->[$_] } } (0..$#{$eigen_val});
    @{$overall} = map { +{ solution => $_+1, eigenvalue => $eigen_val->[$_], eigenvector => $eigen_vec_ref->[$_] } } (0..$#{$eigen_val});

    $self->{summaries}{eigen}{raw} = $overall;
    return;
}

sub _deep_copy_references { 
     my $ref = shift;
     if (!ref $ref) { $ref; } 
     #y/ this check for a_refs in which case we will access the whole thing as @{$a_ref}
     elsif (ref $ref eq q{ARRAY} ) { 
       [ map { _deep_copy_references($_) } @{$ref} ]; 
    } 
    #y/ this checks for hash refs - in which case it will be handled by fully derferencing: %{$ref}
    elsif (ref $ref eq q{HASH} )  { 
    #y intepreter forced to read this as an anon HASH and not BATCH  by prepending +
    + {   map { $_ => _deep_copy_references($ref->{$_}) } (keys %{$ref})    }; 
    } 
    else { die "what type is $_?" }
}

sub _rank_eigenvalues {
    my $self = shift;
    my $overall = $self->{summaries}{eigen}{raw}; 

    #/ deep copy to stop fuss!
    my $overall_clean = _deep_copy_references($overall);

    my $overall_sorted = [];
    #/ Can't use "my $a" in sort comparison at The_PCA_method.pl line 255 - cos $a was declared as lexical and $a/$b are globals...
    @{$overall_sorted} = sort { $b->{eigenvalue} <=> $a->{eigenvalue} } @{$overall_clean};

    $self->{summaries}{eigen}{sorted} = $overall_sorted; 

    $self->_add_rank;
    return;
}

sub _add_rank {
    my $self = shift;
    my $overall_sorted = $self->{summaries}{eigen}{sorted};

#@{$overall_sorted} = sort { $b->{eigenvalue} <=> $a->{eigenvalue} } map { my $temp = $_; $overall_sorted->[$temp]{rank} = $temp+1 } (0..$#{$overall_clean});

    for my $pos ( (0..$#{$overall_sorted}) ) {
                #my $overall_sorted->[$pos]{rank} = $pos;
    $overall_sorted->[$pos]{PC} = $pos+1;
    }
    return;
}

sub _calculate_components {
    my $self = shift;
    my $sorted_eigen = $self->{summaries}{eigen}{sorted};

# we will calculate stdev - this is EITHER stdev of the transformed data OR more generally the stdev of the eigenvalue of the solution. 

    my $total_variance = sum map { $_->{eigenvalue} } @{$sorted_eigen};

    my $cumulative_variance = 0;

    for my $hash_ref (@{$sorted_eigen}) {
        
        # use this twice to unpack it
        my $variance_aka_eigenvalue = $hash_ref->{eigenvalue};
        
        #my $stdev = sqrt($variance_aka_eigenvalue);
        $hash_ref->{stdev} = sqrt($variance_aka_eigenvalue);
        
        # use this twice so put it in variable
        #$hash_ref->{proportion_of_variance} = ( $variance_aka_eigenvalue / $total_variance );
        my $proportion_of_variance = ($variance_aka_eigenvalue / $total_variance);
        $hash_ref->{proportion_of_variance} = $proportion_of_variance;

        $cumulative_variance += $proportion_of_variance;
        $hash_ref->{cumulative_variance} = $cumulative_variance;
    }   
    
    $self->{summaries}{total_variance} = $total_variance;
    
    return;
}

sub _create_row_matrix_of_eigenvectors {

    my $self = shift;
    
    my $sorted_eigen = $self->{summaries}{eigen}{sorted};
    my $eigen_vectors = [];
    
    @{$eigen_vectors} = map { $_->{eigenvector} } @{$sorted_eigen};
  
    #y we turn it into a matrix object - should use _from_rows?
    my $eigen_matrix_object = Math::MatrixReal->new_from_cols( $eigen_vectors );
  
    #y we take the transpose which will be multiplied by the row_adjusted_matrix_object - i.e. transpose
    my $row_eigen_matrix_object = ~$eigen_matrix_object;
    
    my $eigen_vectors_copy = _deep_copy_references ($eigen_vectors);
    $self->{pca}{eigenvectors} = $eigen_vectors_copy;

    return $row_eigen_matrix_object;
}

sub _create_row_matrix_of_adjusted {
    my $self = shift;

    # unpack adjusted data
    my $adjusted = $self->{data}{adjusted};

    #my $adjusted_data_m = Math::MatrixReal->new_from_cols( $pca->{data}{adjusted} );
    my $adjusted_data_matrix_object = Math::MatrixReal->new_from_cols( $adjusted );

    #y take transpose
    my $row_adjusted_data_matrix = ~$adjusted_data_matrix_object;

    return $row_adjusted_data_matrix;

}

sub _transform {

    my $self = shift;
    my $row_mat_Eigen_object = $self->_create_row_matrix_of_eigenvectors;
    my $row_mat_Adjust_object = $self->_create_row_matrix_of_adjusted;

    #y this is the actual pca output - but needs to be transposed    
    my $product_matrix = $row_mat_Eigen_object->multiply($row_mat_Adjust_object);
    
        #y/ code from MatrixReal: map { $this->[0][$_] = [ @$empty ] } ( 0 .. $rows-1);
        #y/ i.e. all matrix data is put into ->[0]
    $self->{pca}{transform} = $product_matrix->[0];

    return;

}

#=fe


#y/////////////////////////////////////////////////////// RESULTS /////////////////////////////////////////////////////
#=fs RESULTS

=head2 results

Used to access the results of the PCA analysis. This method is context-dependent and will return a variety of different
values depending on whether it is called in VOID or LIST context and the arguments its passed. 
In VOID-context it prints a formated table of the computed results to STDOUT.

    $pca->results;

In LIST context this method takes an obligatory argument that determines its return values. To return an ordered list
(ordered by PC ranking) of the proportions of total variance of each PC pass 'proportion' to the method.

    my @list = $pca->results('proportion');
    print qq{\nOrdered list of individual proportions of variance: @list};

To return an ordered list of the cumulative variance of the PCs pass argument 'cumulative'.

    @list = $pca->results('cumulative');
    print qq{\nOrdered list of cumulative variance of the PCs: @list};

To return an ordered list of the individual standard deviations of the PCs pass argument 'stdev'.

    @list = $pca->results('stdev');
    print qq{\nOrdered list of individual standard deviations of the PCs: @list};

To return an ordered list of the individual eigenvalues of the PCs pass argument 'eigenvalue'.

    @list = $pca->results('eigenvalue');
    print qq{\nOrdered list of individual eigenvalues of the PCs: @list};

To return an ordered list of ARRAY references containing the eigenvectors of the PCs pass argument 'eigenvector'.

    # Returns an ordered list of array references containing the eigenvectors for the components
    @list = $pca->results('eigenvector');
    use Data::Dumper;
    print Dumper \@list;

To return an ordered list of ARRAY references containing more detailed information about each PC use the 'full'
argument. Each nested ARRAY reference consists of an ordered list of: PC rank, PC stdev, PC proportion of variance, 
PC cumulative_variance, PC eigenvalue and a further nested ARRAY reference containing the PC eigenvector.
    
    @list = $pca->results('full');
    for my $i (@list) {
        print qq{\nPC rank: $i->[0]}
              . qq{\nPC stdev $i->[1]}
              . qq{\nPC proportion of variance $i->[2]}
              . qq{\nPC cumulative variance $i->[3]}
              . qq{\nPC eigenvalue $i->[4]}
        }

To return an ordered LoL of the transformed data for each of the PCs pass 'transformed' to the method. 

    @list = $pca->results('transformed');
    print qq{\nThe transformed data for 'the' principal component (first PC): @{$list[0]} };

=cut
sub results {
    my ( $self, $arg ) = @_;
    return  (  
    VOID    { $self->_print           }  
    # either have specific methods for type of return! or simply have this and an arguement
    LIST    { $self->_results_in_list($arg) } 
    #y total variance is popintless without individual and if you´ve got individual total is trivial so leave these returns are they are.
    # nao faz sentido - nao eh uma teste
    #BOOL    { $F > $standard_F ? 1 : undef;    } 
            );                          
}

sub _print { 

    my $self = shift;
    print qq{\n=======================\nRESULTS OF PCA ANALYSIS\n=======================\n};

    $self->print_total_variance;
    $self->print_variance;
    $self->print_eigenvectors;
    $self->print_transform;
    
    return;
}

#/ should really get the vectors directly from summaries and not re-enter them in the object!!! - especially now that you can just use rank for PC number
sub print_eigenvectors {
    my $self = shift;
    $self->_print_private(q{eigenvectors});
}

sub print_transform {
    my $self = shift;
    $self->_print_private(q{transform});
}

sub print_total_variance {
    my $self = shift;
    print qq{\nTotal Variance = }, sprintf (q{%.8f}, $self->{summaries}{total_variance}), qq{\n};
    return;
}

sub print_variance {
    my $self = shift;
    
    my $sorted_eigen = $self->{summaries}{eigen}{sorted};
    
    print qq{\nTable of Standard Deviations and Variances:\n};

    # just create a first columnm that´s empty for names of rows
    my @config_full = ( [22, q{}] );

    # column calculations... 
    #/ really ought to get PC name from rank attribute
    #my @config = map { [ 12, q{PC_}.$_ ] } ( 1..(scalar (@{$sorted_eigen})) );
    #my @config = map { [ 12, q{PC_}.$_->{rank} ] } ( 0..(scalar ($#{$sorted_eigen})) );

    #r/ PC is rank - i.e. it is the 'principal' compoenent 
    my @config = map { [ 12, q{PC_}.$_->{PC} ] } (@{$sorted_eigen});

    # make the actual configuring array
    push @config_full, @config;
    
    my $table = Text::SimpleTable->new(@config_full);

    my @row1 = (); # no need to initialise, but whatever...
    for my $hash_ref (@{$sorted_eigen}) { push @row1, sprintf (q{%.8f}, $hash_ref->{stdev}); }
    $table->row( q{Standard Deviation}, @row1 );
    $table->hr;

    my @row2 = (); # no need to initialise, but whatever...
    for my $hash_ref (@{$sorted_eigen}) { push @row2, sprintf (q{%.8f}, $hash_ref->{proportion_of_variance}); }
    $table->row( q{Proportion of Variance}, @row2 );
    $table->hr;

    my @row3 = (); # no need to initialise, but whatever...
    for my $hash_ref (@{$sorted_eigen}) { push @row3, sprintf (q{%.8f}, $hash_ref->{cumulative_variance}); }
    $table->row( q{Cumulative Variance}, @row3 );
    
    print $table->draw;
    return;
}

sub _print_private {
    my ( $self, $arg ) = @_;

    #/ twat used numeric ==
    $arg eq q{eigenvectors} and print qq{\nTable of vectors:\n};
    $arg eq q{transform} and print qq{\nTable of Transformed data:\n};

    my $blah = $self->{pca}{$arg};

    my @config_full = ( [5, q{}] );
    #y column calculations...
    my @config = map { [ 12, q{PC_}.$_ ] } ( 1..(scalar (@{$blah})) );
    push @config_full, @config;
    
    my $t2 = Text::SimpleTable->new(@config_full);

    #y all have same component number so who gives a shit
    for my $row (0..$#{$blah->[0]}) {
        my @data;
        for my $col (0..$#{$blah}) {
            push @data, sprintf (q{%.8f}, $blah->[$col][$row] );
        }
            $t2->row( $row+1, @data );
    }
    print $t2->draw;
    return;
}

sub _results_in_list {
    my ( $self, $arg ) = @_;

    #/ twat need to make ALL of sorted an array and dereference each for key using map 
    #y really need to re-write the first ref of these due to code re-usage
    my %options = ( cumulative  =>  sub { ( map { $_->{cumulative_variance}     } @{$self->{summaries}{eigen}{sorted}} )   },
                    proportion  =>  sub { ( map { $_->{proportion_of_variance}  } @{$self->{summaries}{eigen}{sorted}} )   },
                    stdev       =>  sub { ( map { $_->{stdev}                   } @{$self->{summaries}{eigen}{sorted}} )   },
                    eigenvalue  =>  sub { ( map { $_->{eigenvalue}              } @{$self->{summaries}{eigen}{sorted}} )   },
                    #y these are already in the form of array refs
                    #eigenvector =>  sub { ( map { $_->{eigenvector}             } @{$self->{summaries}{eigen}{sorted}} )   },
                    eigenvector =>  sub { ( @{$self->{pca}{eigenvectors}} )                                                 },
                    #y put it into ordered list
                    # to convert this one we need to convert the whole thing to a numeric iterator and dereference each accordingly - not worth it
                    full        =>  sub { ( map { [ $_->{PC}, $_->{stdev}, $_->{proportion_of_variance}, 
                                                    $_->{cumulative_variance}, $_->{eigenvalue}, $_->{eigenvector}, ] 
                                                                                } @{$self->{summaries}{eigen}{sorted}} )   },
                    transformed =>  sub { ( @{$self->{pca}{transform}} )                                                   },
   
                 );

   #/ either use exists on the key value - OR - assign it to a variable and check the variable for defindness... e.g. my $setting =....
    #croak qq{\nYou must pass a recognised option: \"cumulative\", \"proportion\"} if ( !exists   
    my $setting = $options{$arg};
    croak qq{\nYou must pass a recognised option: \"cumulative\", \"proportion\", \"stdev\", \"eigenvalue\"...} if ( !defined $setting );

    #y &{$cd}();
    #y &$cd();
    #y &$cd;
    #y $cd->();

    $setting->();
    # return;
}

#=fe


1; # Magic true value required at end of module

__END__

#=over
#=item C<< Error message here, perhaps with %s placeholders >>
#=item C<< Another error message here >>
#=back

=head1 DEPENDENCIES

'version'                   =>  '0',
'Carp'                      => '1.08', 
'Math::Cephes::Matrix'      => '0.47', 
'Math::Cephes'              => '0.47', 
'List::Util'                => '1.19', 
'Math::MatrixReal'          => '2.05', 
'Text::SimpleTable'         => '2.0',
'Contextual::Return'        => '0.2.1',

=cut

=head1 AUTHOR

Daniel S. T. Hughes  C<< <dsth@cpan.org> >>

=cut

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Daniel S. T. Hughes C<< <dsth@cantab.net> >>. All rights reserved.

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

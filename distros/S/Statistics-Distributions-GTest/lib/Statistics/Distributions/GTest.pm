package Statistics::Distributions::GTest;

use warnings;
use strict;
use Carp;
use List::Util qw( sum max );
use Math::Cephes qw(:explog);
use Statistics::Distributions qw( chisqrdistr chisqrprob );
use Text::SimpleTable;
use Contextual::Return;
=head1 NAME

Statistics::Distributions::GTest - Perl implementation of the Log-Likelihood Ratio Test (G-test) of Independence.

=cut
=head1 VERSION

This document describes Statistics::Distributions::GTest version 0.1.5.

=cut
use version; our $VERSION = qv('0.1.5'); # next release 0.1.1...
=head1 SYNOPSIS

    use Statistics::Distributions::GTest;

    # Create an GTest object.
    my $gtest = Statistics::Distributions::GTest->new();

    # A 3x3 example. Data is sent to object a reference to a LoL.
    my $a_ref = [
                    [ 458, 537 ,345],
                    [ 385, 457 ,456],
                    [ 332, 376 ,364 ],
                ];

    # Feed the object the data by passing reference with named argument 'table'.
    $gtest->read_data ( { table => $a_ref } );

    # Perform the analysis using one of the two methods - see DESCRIPTION.
    $gtest->G();
    #$gtest->G_alt();

    # Print a table of the calculated expected values.
    $gtest->print_expected();

    # To access results use results method. The return of this method is context dependent (see METHODS). 
    # To print a report to STDOUT call results in VOID context - may also call in BOOLEAN, NUMERIC and LIST (see METHODS).
    $gtest->results();

=cut
=head1 DESCRIPTION

The G-test of independence is an alternative to the chi-square test of independence for testing for independence in
contingency tables. G-tests are coming into increasing use and as with the chi-square test for independence the G-test
for independence is used when you have two nominal variables each with two or more possible values. The null hypothesis
is that the relative proportions of one variable are independent of the second variable. This module implements two two 
equivalent, but marginally different approaches to calculate G scores (that described in 
http://en.wikipedia.org/wiki/G-test and that used by http://udel.edu/~mcdonald/statgtestind.html). Benchmarking 
indicates that first approach works about a third faster than the alternative. However, this difference 
diminishes as the categories increase. See http://en.wikipedia.org/wiki/G-test and 
http://udel.edu/~mcdonald/statgtestind.html.

=cut
=head1 METHODS

=cut

#######################################################################################################################

sub new {

    my ($class, $all_h_ref ) = @_;
    croak qq{\nArguments must be passed as HASH reference.} 
      if ( ( $all_h_ref ) && ( ref $all_h_ref ne q{HASH} ) );
    my $self = {};
    bless $self, $class;
    return $self;
}
=head2 new

Create a new Statistics::Distributions::GTest object.

    my $gtest = Statistics::Distributions::GTest->new();

=cut

sub read_data {
    my ( $self, $all_h_ref ) = @_;

    $all_h_ref or croak qq{\nYou must pass me some data};
    croak qq{\nThe data must be passed within HASH reference pointed to by key \'table\'.} 
           if ( ( ref $all_h_ref ne q{HASH} ) || ( !exists $all_h_ref->{table} ) );
    
    #y unpack data
    my $data_a_ref = $all_h_ref->{table};
    
    $data_a_ref or croak qq{\nkey \'table\' points to nothing}; 
    croak qq{\nThe data pointed to by key \'table\' must be passed as ARRAY reference.} if ( ref $data_a_ref ne q{ARRAY} );

    $self->_data_checks($data_a_ref);

    #r/ WE MUST DEEP COPY THIS STRUCTURE
    my $deep_copied_ref = _deep_copy_arrays ($data_a_ref);

    #y convert the numeric values to hashes that store various values
    $self->_inplace_conversion($deep_copied_ref);
    
    #y simple flag for data reading
    $self->{properties}{analysis}{obs_table} = 1;
    return;
}
=head2 read_data

Used for loading data into object. Data is fed as a reference to a list of lists within an anonymous hash using the
named argument 'table'.
 
    $gtest->read_data ( { table => $LoL_ref } );

=cut

sub _data_checks {
    my ($self, $data_a_ref) = @_;
    #/ get rows
    my $rows = scalar(@{$data_a_ref});
    croak qq{\nI need some data - there are too few rows in your data.\n} if ( !$rows || $rows == 1 );

    #/ get cols - check first and then compare the rest
    my $cols = scalar(@{$data_a_ref->[0]});
    croak qq{\nI need some data - there are too few columns in your data.\n} if ( !$cols || $cols == 1 );

    for my $row (@{$data_a_ref}) {

        croak qq{\n\nData set must be passed as ARRAY references.\n} if ( ref $row ne q{ARRAY} );
        croak qq{\n\nAll rows must have the same number of columns.\n} if ( scalar( @{$row} ) != $cols );

        }

    # feed the object
    $self->{properties}{rows} = $rows;
    $self->{properties}{cols} = $cols;

    return;
}

#/ beware: this is a prototype and only used for deep-copying - don´t return at end as its called recursively and you´ll kill the deep copy
sub _deep_copy_arrays (\@) {
    my $data_structure = shift;

    if (!ref $data_structure) { $data_structure }
    elsif (ref $data_structure eq q{ARRAY} ) { 
        [ map { _deep_copy_arrays ($_) } @{$data_structure} ]; 
    } 
    else { croak qq{\nYou must hand in an array ref. } }

    #/ THIS METHOD IS CALLED RECURSIVELY! DON´T PUT RETURN IN HERE
    # return;
}

sub _inplace_conversion {
    #/ in place converstion to 2-d matrix to cells
    my ($self, $a_ref) = @_;
    
    for my $row (0..$#{$a_ref}) {
        for my $col (0..$#{$a_ref->[0]}) {

            # unpack value
            my $observation = $a_ref->[$row][$col];
            
            my $cell_h_ref = { observation => $observation,
                            };

            $a_ref->[$row][$col] = $cell_h_ref;
        }
    }

    #y feed the object the deep-copied inplace modified array
    print qq{\n\nData passed all checks. Feeding $self->{properties}{rows} x $self->{properties}{cols} matrix to object.\n};
    $self->{table} = $a_ref;

    return;
}

sub diag {
    my $self = shift;
    print qq{\n-------------------------------------------------------\nobject dumper:\n}, Dumper $self;
    print qq{-------------------------------------------------------\n\n};

    return;
}

sub _sum_a_row {
    my ( $self, $row ) = @_; # para de esquecer a colocar @_ quando unpacking!!!
    my $table_a_ref = $self->{table};

    #y basically the NW way
    my $row_sum = sum map { $table_a_ref->[$row][$_]{observation} } ( 0..($self->{properties}{cols}-1) ); 
    #y my way
    my $row_sum2 = sum map { $_->{observation} } @{$self->{table}[$row]};
    
    #y basically the NW way
#    my $col_sum1 = sum map { $table_a_ref->[$_][$col]{observation} } ( 0..($self->{properties}{rows}-1) ); 
    #y my way
#    my $col_sum2 = sum map { $_->[$col]{observation} } @{$self->{table}};

    return $row_sum;
}

sub _sum_rows {

    my $self = shift;
    my $table_a_ref = $self->{table};
    my @row_sums = ();

    for my $row (0..$#{$table_a_ref}) {

        push @row_sums, $self->_sum_a_row($row);

    }

    $self->{properties}{row_sums} = [@row_sums];

    return;
}

sub _sum_a_col {
    my ( $self, $col ) = @_; # para de esquecer a colocar @_ quando unpacking!!!
    my $table_a_ref = $self->{table};

    #y basically the NW way
    my $col_sum = sum map { $table_a_ref->[$_][$col]{observation} } ( 0..($self->{properties}{rows}-1) ); 
    #y my way
    my $col_sum2 = sum map { $_->[$col]{observation} } @{$self->{table}};

    return $col_sum;

}

sub _sum_cols {
    my $self = shift;
    my $table_a_ref = $self->{table};
    my @col_sums = ();
   
    #/ still need to fix this!!! use $self-{properties}{col}-1?!? - that way its all the same figure
    for my $col (0..$#{$table_a_ref->[0]}) {
        push @col_sums, $self->_sum_a_col($col);
    }
    $self->{properties}{col_sums} = [@col_sums];

    return;
}

sub _total {
    my $self = shift;
    my $total_from_rows = sum @{$self->{properties}{row_sums}};
    my $total_from_cols = sum @{$self->{properties}{col_sums}};
    $self->{properties}{total} = $total_from_rows;

    return;
}

sub _calculate_expected {
    my $self = shift;
    my $a_ref = $self->{table};

    my @row_sums = @{$self->{properties}{row_sums}};
    my @col_sums = @{$self->{properties}{col_sums}};
    my $total = $self->{properties}{total};

    for my $row ( 0..($self->{properties}{rows}-1) ) {

        for my $col (0..($self->{properties}{cols}-1) ) {
            
            my $expected = ( $row_sums[$row] * $col_sums[$col] ) / $total;

            $a_ref->[$row][$col]{expected} = $expected;
        }
    }

    $self->{properties}{analysis}{expect_table} = 1;
    return;
}

sub _calculate_f_ln_f {
    my $self = shift;
    my $a_ref = $self->{table};
    for my $row ( 0..($self->{properties}{rows}-1) ) {
        for my $col (0..($self->{properties}{cols}-1) ) {
            
            my $observed = $a_ref->[$row][$col]{observation};
            my $f_ln_f = _f_ln_f ($observed);
            $a_ref->[$row][$col]{f_ln_f} = $f_ln_f;
        }
    }

    return;
}

#/ beware: this is a prototype and not for use as an object method
sub _f_ln_f($) {
    my $value = shift;
    $value = $value > 0.5 ? $value * ( log ( $value ) ) : 0 ;
    return $value;
}

sub _calculate_G_traditional {
    my $self = shift;
    my $table_a_ref = $self->{table};

    my $sum = 0;

    for my $row ( 0..($self->{properties}{rows}-1) ) {
        for my $col (0..($self->{properties}{cols}-1) ) {

            my $cell = $table_a_ref->[$row][$col]{observation} * 
              ( log ( $table_a_ref->[$row][$col]{observation} / $table_a_ref->[$row][$col]{expected} ) );

            $sum += $cell;
        }
    }
    my $G = 2 * $sum;

    $self->{properties}{G} = $G;

    return;
}

sub _calculate_G_alternative {
    my $self = shift;
    my $table_a_ref = $self->{table};
    my $sum = 0;

    #/ don´t need this part###################################################
    my @f_ln_f_for_row_sums = map { _f_ln_f($_) } @{$self->{properties}{row_sums}};
    my @f_ln_f_for_col_sums = map { _f_ln_f($_) } @{$self->{properties}{col_sums}};
            $self->{properties}{f_ln_f_for_row_sums} = [@f_ln_f_for_row_sums];
            $self->{properties}{f_ln_f_for_col_sums} = [@f_ln_f_for_col_sums];
    ##########################################################################

    my $sum_of_f_ln_f_for_row_sums = sum map { _f_ln_f($_) } @{$self->{properties}{row_sums}};
    my $sum_of_f_ln_f_for_col_sums = sum map { _f_ln_f($_) } @{$self->{properties}{col_sums}};

    my $f_ln_f_for_total = _f_ln_f ($self->{properties}{total});

            $self->{properties}{f_ln_f_for_total} = [$f_ln_f_for_total];
    
    my $sum_f_ln_f = 0;

    for my $row ( 0..($self->{properties}{rows}-1) ) {
    
        #/ either
        #for my $col (0..($self->{properties}{cols}-1) ) {
        #$row = $table_a_ref->[$row][$col]{observation};
        #/ or
        $row = sum map { $_->{f_ln_f} } @{$self->{table}[$row]};

        $sum_f_ln_f += $row;
    }

    my $G = 2 * ( ( $sum_f_ln_f + $f_ln_f_for_total ) - 
      ( $sum_of_f_ln_f_for_row_sums + $sum_of_f_ln_f_for_col_sums ) );

    $self->{properties}{G} = $G;
   
    return;
}

sub G {
    my $self = shift;
    #y check data loaded flag
    croak qq{\nYou have to load some data before calling this method} if ( !exists $self->{properties}{analysis}{obs_table} );
    $self->_sum_rows();
    $self->_sum_cols();
    $self->_total();
    $self->_calculate_expected();
    $self->_calculate_G_traditional();
    
    $self->_df();
    $self->_calculate_p_value();
    
    #y flag to check this has run
    $self->{properties}{analysis}{G} = 1;
    return;

}
=head2 G

To calculate G value. This method implements the calculation described in http://en.wikipedia.org/wiki/G-test.
   
   $gtest->G();

=cut

#/ make this redundant and using self->{prop}{G} for both G calculation methods - create a method to compare the two computed values.
sub G_alt {
    my $self = shift;
    #y check data loaded flag
    croak qq{\nYou have to load some data before calling this method} if ( !exists $self->{properties}{analysis}{obs_table} );
    $self->_sum_rows();
    $self->_sum_cols();
    $self->_total();
    $self->_calculate_f_ln_f();
    $self->_calculate_G_alternative();

    $self->_df();
    $self->_calculate_p_value();
    
    #y flag to check this has run
    $self->{properties}{analysis}{G_alt} = 1;
    return;

}
=head2 G_alt

To calculate G you may also use this method. This method implements procedure described in 
http://udel.edu/~mcdonald/statgtestind.html. This approach does not directly generate a table of expected values.
    
    $gtest->G_alt();

=cut

sub _df {
    my $self = shift;
    my $df = ( $self->{properties}{rows}-1 ) * ( $self->{properties}{cols}-1 );
    $self->{properties}{df} = $df;

    return;
}

sub _calculate_p_value {
    my $self = shift;
    my $chisprob = chisqrprob ($self->{properties}{df}, $self->{properties}{G});
    $self->{properties}{p_value} = $chisprob;

    return;
}

sub _configure_table {
    my ( $self, $which ) = @_;
    my $max_len = 0;
    for my $row (@{$self->{table}}) {
            my $temp = max map { length( sprintf ( q{%.0f}, $_->{$which}) ) } @{$row} ;
            $max_len = $temp > $max_len ? $temp : $max_len;
        }
    return ($max_len) x $self->{properties}{cols};
}

sub _print_table {
    my  ( $self, $which ) = @_;

            ( $which eq q{observation}  ||  $which eq q{expected} ) || 
                 croak qq{\nUsage is \$object->print_observed or \$object->print_expected};

            #croak qq{\nUsage is \$object->print_observed or \$object->print_expected}
                  #unless ( ( $which eq q{observed} ) || ( $which eq q{expected} ) );
                  #if !( ( $which eq q{observed} ) || ( $which eq q{expected} ) );

    my $table = Text::SimpleTable->new($self->_configure_table($which));
    my $count = 0;
    for my $row (@{$self->{table}}) {
            $table->hr if ( $count != 0 );
            $table->row( ( map { sprintf ( q{%.0f}, $_->{$which} ) } @{$row} ) );
            $count++;
        }
    print qq{\nTable of $which values:\n}, $table->draw;

    return;
}

sub print_expected {
# convinience method - stops calling of private _print_table
    my $self = shift;

    #y check data loaded flag
    croak qq{\nYou have to load some data before calling this method} if ( !exists $self->{properties}{analysis}{obs_table} );
   
    #y check whether _calculated_expected was called
    if ( ( exists $self->{properties}{analysis}{G_alt} ) && ( !exists $self->{properties}{analysis}{expect_table} ) ) { 
        print qq{\nIt appears you ran the alternative procedure that does not directly generate an expected values table. }
          .qq{\nGenerating expected values table now.\n};
        $self->_calculate_expected();
    }

    #y check the analysis flags
    #y !$x and !$y and croak
    croak qq{\nYou must run the analysis with either method G or G_alt first} 
      if ( ( !exists $self->{properties}{analysis}{G} ) && ( !exists $self->{properties}{analysis}{G_alt} ) );

    $self->_print_table(q{expected});
    return;
}
=head2 print_expected

Prints a table of the calculated expected values to STDOUT. If you used G_alt to calculate G it will first generated the
table of excpeted values.
   
   $gtest->print_expected();

=cut

sub print_observed {
# convinience method - stops calling of private _print_table
    my $self = shift;
    #y check data loaded flag
    croak qq{\nYou have to load some data before calling this method} if ( !exists $self->{properties}{analysis}{obs_table} );
    $self->_print_table(q{observation});
    return;
}
=head2 print_observed

Prints a table of the observation values to STDOUT. 
   
   $gtest->print_observed();

=cut

sub results {
    my ($self, $thing ) = @_;
    #y check the analysis flags
    croak qq{\nYou must run the analysis with either method G or G_alt first} 
      if ( ( !exists $self->{properties}{analysis}{G} ) && ( !exists $self->{properties}{analysis}{G_alt} ) );

    #y preferentially grab the traditional method result
    
    #my $G = ( !exists $self->{properties}{G} ) ? $self->{properties}{G} : $self->{properties}{G_alt};
    #/ twat!
    #my $G = exists $self->{properties}{G};
    my $G = $self->{properties}{G};
    
    my $df = $self->{properties}{df};
    my $p_val = $self->{properties}{p_value};

    if ( $p_val < 1e-05 ) { $p_val = sprintf (q{%e}, $p_val) }

    $G = sprintf ( q{%.5f}, $G );

return  (    
    VOID    { $self->_void ($G, $df, $p_val)    }  
    LIST    { ($G, $df, $p_val )                } 
    BOOL    { $self->_boolean($G, $df, $thing)  } 
    NUM     { $G ;                              }    
    );                          

}
=head2 results

Used to access the results of the G-test calculation. This method is context-dependent and will return a variety of
different values depending on its calling context. In VOID context it simply prints the calculated value of G, df and
the p_value in a table to STDOUT.
   
    $gtest->results();

In BOOLEAN context it requires you to pass it a value for the significance level of the test you wish to apply e.g.
0.05. It returns True or False depending on whether the null hypothesis is rejected at that significance level.

    # test if the result is significant at the p = 0.05 level.
    if ($gtest->results( 0.05 )) { print qq{\nthis is significant } } else { print qq{\nthis is not significant} }

In LIST context it simply returns a LIST of the calculated values of G, df and p for the observation data.

    my ($G, $df, $p) = $gtest->results();

In NUMERIC context it returns the calculated value of G.

    print qq{\n\nG in numeric is: }, 0+$gtest->results();

=cut

sub _void {
    my ( $self, $G, $df, $p_val ) = @_;

    my $g_len = length ($G) > 7 ? length ($G) : 7;
    my $df_len = length ($df) > 3 ? length ($df) : 3;
    my $p_len = length ($p_val) > 7 ? length ($p_val) : 7;

    my $table = Text::SimpleTable->new($g_len, $df_len, $p_len);
    $table->row( qw/ G_value df p_value / );
    $table->hr;
    $table->row( $G, $df, $p_val );
    print qq{\nTable of results:\n}, $table->draw;

    return;
}

sub _boolean {
    my ($self, $G, $df, $sig) = @_;
   
    $sig or croak qq{\nYou must pass a p_value in BOOLEAN context};
    
print qq{\nsig $sig};

    croak qq{\nThe p value must be numeric and in the range > 0 and < 1.} if ( $sig !~ /\A \d* \.? \d+ ([eE][+-]?\d+)? \z/xms || $sig <= 0 || $sig >= 1) ;
      #/ forgot to check for exponential numbers
      #if ( $sig !~ /\A[01]?\.\d{1,7}\z/xms || $sig <= 0 || $sig >= 1) ;
    
      $G = $G > chisqrdistr ( $df, $sig ) ? 1 : undef;
    return $G;
}

1; # Magic true value required at end of module

__END__

=head1 DEPENDENCIES

'version'                   => 0,
'Statistics::Distributions' => '1.02',
'Math::Cephes'              => '0.47', 
'Carp'                      => '1.08', 
'Contextual::Return'        => '0.2.1',
'List::Util'                => '1.19', 
'Text::SimpleTable'         => '2.0',

=cut
=head1 AUTHOR

Daniel S. T. Hughes  C<< <dsth@cpan.net> >>

=cut
=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Daniel S. T. Hughes C<< <dsth@cantab.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
=head1 SEE ALSO

L<Statistics::Descriptive>, L<Statistics::Distributions>, L<Statistics::Distributions::Analyze>, L<Statistics::ANOVA>,
L<Statistics::Distributions::Ancova>, L<Statistics::ChiSquare>.

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

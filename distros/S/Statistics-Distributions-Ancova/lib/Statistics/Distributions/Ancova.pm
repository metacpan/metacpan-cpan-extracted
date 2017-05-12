package Statistics::Distributions::Ancova;
use 5.008;

use strict;
use warnings;
use Carp;
use List::Util;
use Math::Cephes qw(:utils);
use Contextual::Return;
use Perl6::Form;
use Statistics::Distributions qw( fprob fdistr);

=head1 NAME

Statistics::Distributions::Ancova - Perl implementation of One-Way Analysis of Covariance for Independent Samples.

=cut
=head1 VERSION

This document describes Statistics::Distributions::Ancova version 0.32.2.

=cut
use version; our $VERSION = qv('0.32.2'); 
=head1 SYNOPSIS

    use Statistics::Distributions::Ancova;

    # Create an Ancova object and set significance value of p = 0.05 for statistical test. See METHODS for optional named arguments and default values.
    my $anc = Statistics::Distributions::Ancova->new ( { significance => 0.005, input_verbosity => 1, output_verbosity => 1 } );

    # Example using k=3 groups. Data includes our dependent variable of interest (Y) and covariant data (X) that is used to eliminate obscuring effects of covariance.
    my @Drug_A_Y =  ('29','27','31','33','32','24','16');
    my @Drug_A_X = ('53','64','55','67','55','45','35');
    my @Drug_B_Y = ('39','34','20','35','57','28','32','17');
    my @Drug_B_X = ('24','19','13','18','25','16','16','13');
    my @Drug_C_Y = ('12','21','26','17','25','9','12');
    my @Drug_C_X = ('5','12','12','9','12','3','3');

    # Data is sent to object as nested HASH reference. Individual group names are option, but to distinguish IV/DV, the names Y and X for the variables are compulsory.
    my $h_ref = { 'group_A' =>  {
                                    Y => \@Drug_A_Y,
                                    X => \@Drug_A_X,
                            }, 
                'group_B' =>  { 
                                    Y => \@Drug_B_Y,
                                    X => \@Drug_B_X,
                            }, 
                'group_C' =>  { 
                                    Y => \@Drug_C_Y,
                                    X => \@Drug_C_X,
                            }, 
                };

    # Feed the object the data pass data HASH reference with named argument 'data'.
    $anc->load_data ( { data => $h_ref } );

    # Perform analysis
    $anc->ancova_analysis;

    # To access results use results method. The return of this method is context dependent (see METHODS). 
    # To print a report to STDOUT call results in VOID context.
    $anc->results();

=cut
=head1 DESCRIPTION

ANCOVA is a merger of ANOVA and regression for continuous variables. As with paired t-test and repeated-measures ANOVA 
this test removes the obscuring effects of pre-existing individual differences among subjects and thus may increase
statistical power. In cases where a substantial portion of the variability that occurs within each of the set of a dependent variable Y is 
actually covariance with another concomitant variable X measures, this test removes the covariance with X from Y thus 
removing a portion of the irrelevant variability of individual differences. See http://en.wikipedia.org/wiki/Analysis_of_covariance for more info.

=cut
=head1 Methods

=cut

#######################################################################################################################

sub new {
    my ($class, $args_h_ref ) = @_;
    croak qq{\nArguments must be passed as HASH reference.} if ( ( $args_h_ref ) && ( ref $args_h_ref ne q{HASH} ) );

    my $self = {};
    bless $self, $class;
   
    $self->_set_significance($args_h_ref);
    $self->_set_verbosity($args_h_ref);

    return $self;
}
=head2 new

Creates new Statistics::Distributions::Ancova object. Without arguments defaults to a significance test value of p = 0.05.
    
    my $anc = Statistics::Distributions::Ancova->new ();

Use significance option to set the significance level for the test to values other than 0.05.
    
    my $anc = Statistics::Distributions::Ancova->new ( { significance => 0.005 } );

To print data-checking step messages (upon data loading with C<load_data>) to STDOUT set input_verbosity to 1.     

    my $anc = Statistics::Distributions::Ancova->new ( { input_verbosity => 1 } );

To print a detailed report when C<result> method is called in VOID context to STDOUT set output_verbosity to 1.     

    my $anc = Statistics::Distributions::Ancova->new ( { output_verbosity => 1 } );

=cut

#/ now made this private 
sub _set_significance {
    my ($self, $args_h_ref) = @_;

    croak qq{\nArguments must be passed as HASH reference.} if ( ( $args_h_ref ) && ( ref $args_h_ref ne q{HASH} ) );
    if (!exists $args_h_ref->{significance}) { print qq{\n\nFalling back on default 0.05 significance value.\n} }
    my $sig = exists $args_h_ref->{significance} ? $args_h_ref->{significance} : q{0.05}; 

    # included exponential number check
    croak qq{\nThe p value must be numeric and in the range > 0 and < 1.} if ( $sig !~ /\A \d* \.? \d+ ([eE][+-]?\d+)? \z/xms || $sig <= 0 || $sig >= 1) ; 
    #croak qq{\nThe p value must be numeric and in the range > 0 and < 1.} if ( $sig !~ /\A \d{1,7} \.? \d+ ([eE][+-]?\d+)? \z/xms || $sig <= 0 || $sig >= 1) ; 
    
    $self->{significance} = $sig;
    return;
}

sub set_significance {

    my ( $self, $sig ) = @_;
    #/ in this case we must distinguish between 0 and no arugement!
    #y the 0 detector
    croak qq{\nThe p value cannot be 0.} if ( defined $sig && $sig == 0 ) ; 
    #y the no arg detector/empty string - already forced numeric
    $sig || print qq{\n\nFalling back on default 0.05 significance value.\n};
    $sig ||= 0.05;
    #y no need to check for 0 again
    #/ we don´t need to check the regexp part as we´ve already forced only numeric args with the above ==0...
   
    # check for exponentials
    croak qq{\nThe p value must be numeric and in the range > 0 and < 1.} if ( $sig !~ /\A \d* \.? \d+ ([eE][+-]?\d+)? \z/xms || $sig <= 0 || $sig >= 1) ; 
    #croak qq{\nThe p value must be numeric and in the range > 0 and < 1.} if ( $sig !~ /\A \d{1,7} \.? \d+ ([eE][+-]?\d+)? \z/xms || $sig <= 0 || $sig >= 1) ; 
    #croak qq{\nThe p value must be numeric and in the range > 0 and < 1.} if ( $sig !~ /\A[01]?\.\d+([eE][+-]?\d+)?\z/xms || $sig <= 0 || $sig >= 1) ; 

    $self->{significance} = $sig;
    return;

}
=head2 set_significance

Convenience method to reset significance level. Without a value it defaults to p = 0.05 to change this use set_significance. 
    
    $anc->set_significance();
    $anc->set_significance( 0.0005 );

=cut

#/ now a private method - only called by new and unload
sub _set_verbosity {
    my ($self, $args_h_ref) = @_;

    croak qq{\nArguments must be passed as HASH reference.} if ( ( $args_h_ref ) && ( ref $args_h_ref ne q{HASH} ) );
    
    my $input_verbosity = exists $args_h_ref->{input_verbosity} ? $args_h_ref->{input_verbosity} : 0 ;
    my $output_verbosity = exists $args_h_ref->{output_verbosity} ? $args_h_ref->{output_verbosity} : 0 ;

    croak qq{\nInput verbosity must be set to 1 or 0.} if ( $input_verbosity !~ /\A[01]\z/xms ) ; 
    croak qq{\nOutput verbosity must be set to 1 or 0.} if ( $output_verbosity !~ /\A[01]\z/xms ) ; 
    
    $self->{verbosity}  = { input => $input_verbosity,
                            output => $output_verbosity };
    
    #$self->{verbosity} = %{$verbosity};
    #$self->{verbosity}{input} = $input_verbosity;
    #$self->{verbosity}{output} = $output_verbosity;
    
    return;
}

sub set_input_verbosity {
    #/ convinience method to reset output verbosity
    my ( $self, $verb ) = @_;
    #y don´t care about distinguishing default no arg and 0 here - unlike in set_significance - so just existince
    $verb ||= 0;
    croak qq{\nYou must pass set_output_verbosity 1 or 0 (without an arguement it defaults to 0).} if ( $verb !~ /\A[01]\z/xms ) ; 
    $self->{verbosity}{input} = $verb;
    return;
}
=head2 set_input_verbosity

Convenience method to reset the input verbosity level. Pass it 1 for verbose and 0 or no argument to leave default
silent state.

    $anc->set_input_verbosity (1); # Turns on verbosity
    $anc->set_input_verbosity (0);
    $anc->set_input_verbosity ();

=cut

sub set_output_verbosity {
    #/ convinience method to reset output verbosity
    my ( $self, $verb ) = @_;
    #y don´t care about distinguishing default no arg and 0 here - unlike in set_significance - so just existince
    $verb ||= 0;
    croak qq{\nYou must pass set_output_verbosity 1 or 0 (without an arguement it defaults to 0).} if ( $verb !~ /\A[01]\z/xms ) ; 
    $self->{verbosity}{output} = $verb;
    return;
}
=head2 set_output_verbosity

Convinience method to reset the output verbosity level. Pass it 1 for verbose and 0 or no argument to leave default
silent state.

    $anc->set_output_verbosity (1); # Turns on verbosity
    $anc->set_output_verbosity (0);
    $anc->set_output_verbosity ();

=cut

sub load_data {
    my ($self, $h_ref) = @_;

    $self->_pre_check($h_ref);
    #y unpack the data
    my $data_ref = $h_ref->{data};

    $data_ref or croak qq{\nkey \'data\' points to nothing};
    croak qq{\nThe data pointed to by key \'data\' must be passed as HASH reference.} if ( ref $data_ref ne q{HASH} );
    
    $self->_groups_info($data_ref);
    
    #/ there is no need to deep copy the data - we just use it...
    $self->_data_check($data_ref);

    #y construct the array consisting off ALL the data
    $self->_all_array($data_ref);
 
    #y set flag 
    $self->{analysis_state}{load} = 1;
    return;
}
=head2 load_data
    
To load or re-load data. Pass the data as named arguement 'data' within an anonymous HASH pointing to nested HASH
reference containing the data. Within this HASH reference each subsequent nested HASH corresponds to a separate
individual/group. The names of these groups are arbitrary. Within each nested group HASH there must be exactly to keys.
One called 'Y' (corresponding to the Dependent Variable that we wish to adjust using covariance) that points to an
array ref or directly as an anonymous array of the corresponding data. The other key must be termed 'X' and corresponds 
to the concomitant variable whose covariation will be used to adjust Y. X is also passed as an array ref/anonymous 
array.
    
  $anc->load_data ( { data => { 'GroupA' => {   Y => [qw/ 29 27 31 33 32 24 16 /],      X => [qw/ 53 64 55 67 55 45 35 /], },
                                'GroupB' => {   Y => [qw/ 39 34 20 35 57 28 32 17 /],   X => [qw/ 24 19 13 18 25 16 16 13 /], }, 
                                'GroupC' => {   Y => [qw/ 12 21 26 17 25 9 12 /],       X => [qw/ 5 12 12 9 12 3 3 /], }, }, 
                  } );

=cut

sub _pre_check {

    my ($self, $h_ref) = @_;

    #croak qq{\nThe data must be passed as HASH reference.} if ( ( $h_ref ) && ( ref $h_ref ne q{HASH} ) );
    #croak qq{\nThe data must be passed as HASH reference pointed to by key \'data\'.} if (!exists $h_ref->{data});
    #croak qq{\nYou must pass me some data} if ( !$h_ref );
    #croak qq{\nThe data must be passed as HASH reference.} if ( ref $h_ref ne q{HASH} );
    #croak qq{\nThe data must be passed as HASH reference pointed to by key \'data\'.} if ( !exists $h_ref->{data});
   
    if ( !$h_ref ) { croak qq{\nYou must pass me some data}; }
    #elsif ( ( ref $h_ref ne q{HASH} ) || (!exists $h_ref->{data}) ) { croak qq{\nThe data must be passed as HASH
    #elsif ( ref $h_ref ne q{HASH} ) { croak qq{\nThe data must be passed as HASH reference.}; }
    #elsif ( !exists $h_ref->{data}) { croak qq{\nThe data must be passed as HASH reference pointed to by key \'data\'.}; }
    elsif ( ( ref $h_ref ne q{HASH} ) || ( !exists $h_ref->{data} ) ) { croak qq{\nThe data must be passed within a HASH reference pointed to by key \'data\'.}; }

    return;

}

sub _groups_info {
    my ($self, $h_ref ) = @_;
    my @groups = (keys %{$h_ref});
    # exist syntax is exists $hash{blah} thus use ${$h_ref->...}{blah}
    croak qq{\n\'T\' is not a permitted name for a group.\n} if ( exists ${$h_ref}{q{T}} );
    #y do things this way for safety
    my $k = scalar(@groups);
    croak qq{\nI need at least 2 groups of data.\n} if ( !$k || $k == 1 );
    $self->{groups} = [@groups];
    $self->{k} = $k;
    return;
}

sub _data_check {
    my ($self, $h_ref) = @_;
    my $verbose = $self->{verbosity}{input};
    my @groups = @{$self->{groups}};
    my %group_lengths;
    my $k = $self->{k};
    print qq{\n\nData has k = $k (group number).\n} if $verbose;
    for my $group (@groups) {
        croak qq{\n\nEach group must have two sets of data - one for DV and one for IV.\n\n} if ( ( scalar ( keys %{$h_ref->{$group}} ) ) != 2 );
        print qq{\n* Group $group has: }, 0+(keys %{$h_ref->{$group}}), q{ sets of data.} if $verbose;
        croak qq{\n\nWe need to distinguish independent and dependent variables so force names of data sets to \x27X/y\047 and \x27Y/y\047.\n} if ( !exists ${$h_ref->{$group}}{q/X/} );
        print qq{\n* Group $group has independent variable X} if $verbose;
        croak qq{\n\nWe need to distinguish independent and dependent variables so force names of data sets to \x27X/y\047 and \x27Y/y\047.\n} if ( !exists ${$h_ref->{$group}}{q/Y/} );
        print qq{\n* Group $group has dependent variable Y.} if $verbose;
        croak qq{\n\nData set must be passed as ARRAY references.\n} if ( ( ref $h_ref->{$group}{q/Y/} ne q{ARRAY} ) || ( ref $h_ref->{$group}{q/X/} ne q{ARRAY} ) );
        print qq{\n* Group $group Y and X are both ARRAY references.} if $verbose;
  
        my $n_check = scalar(@{$h_ref->{$group}{q/Y/}});
        croak qq{\nI need some actual data - sample number is too low.\n} if ( !$n_check || $n_check == 1 );
        print qq{\n* Group $group Y has $n_check data points.} if $verbose;
        croak qq{\n\nBoth X and Y data sets must have equal length.\n} if scalar(@{$h_ref->{$group}{q/X/}}) != $n_check;
        print qq{\n* Group $group Y also has $n_check data points.} if $verbose;

        $group_lengths{$group} = $n_check; 
    
        print qq{\n\nData for group $group looks good.\n} if $verbose;
    }

    print qq{\nData passed. Feeding it to Ancova object.} if $verbose;

    $self->{lengths} = {%group_lengths};
    
    #/ we haven´t deep copied so this is pointless!
    ##s we aren´t actually using that hash passed at all - we are copying it - that way they can use that same hash name again later - i.e. we allocate NEW memory location
    #y point is data passed checks so we put it into object
    
    #y that is while we create a new higher level copy we don´t deep copy so its pointless using this syntax and not
    #y simply $self->{data} = $h_ref - if we deep copy then we are safe from this issue - clearly T is new data...
    $self->{data} = {%{$h_ref}};

    return;
}

sub _all_array {
    my ($self, $h_ref ) = @_;
    #my @groups = (keys %{$h_ref}) == (keys %{$h_ref}) == (keys %{$self->{data}})
    my @groups = @{$self->{groups}};
    
    #my $T_list = {};
    #@{$T_list->{X}} = ();
    #@{$T_list->{Y}} = ();
    my $T = {};

    for my $xy( qw/ X Y / ) {

        for my $group (@groups) {
   
            #y needs pre-initialisation of everything!
            #@{$T_list->{$xy}} = (@{$T_list->{$xy}}, @{$h_ref->{$group}{$xy}});
            push @{$T->{$xy}}, @{$h_ref->{$group}{$xy}};

        }
    }

    $self->{data}{T} = {%{$T}};
    return;
}

sub print_data {
    my $self = shift;
    croak qq{\nYou have to load some data first.} if !defined ${$self}{groups};
    my @groups = @{$self->{groups}};
    for my $group (@groups) {
        for my $xy ( qw / X Y / ) {
            my @array = @{$self->{data}{$group}{$xy}};
            print qq{\n\nGroup $group - data set $xy\n@array.};
        }
    }
    return;
}

sub unload {
    my $self = shift;
    croak qq{\nYou have to load some data before calling this method} if ( !exists $self->{analysis_state}{load} );
    my @object_keys = keys %{$self};
    OBJECT:
    foreach (@object_keys) {
        next OBJECT if $_ eq q{data};
        $self->{$_} = undef;
    }
    $self->{data} = {}; # empty h_ref - thus wipe out old data.
    $self->{significance} = 0.05;
    $self->_set_verbosity;
    return;
}
=head2 unload

To clear the object use unload.

    $anc->unload;
    
=cut

sub load_data_old {
    my ($self, $h_ref ) = @_;
    my $T_y_ref = [ (@{$h_ref->{A}{Y}}, @{$h_ref->{B}{Y}}) ];
    my $T_x_ref = [ (@{$h_ref->{A}{X}}, @{$h_ref->{B}{X}}) ];
    $self->{data} = $h_ref;
    $self->{data}{T} =  {   X   =>  $T_x_ref,
                            Y   =>  $T_y_ref,
                        };
    return;
}

sub ancova_analysis {
    my $self = shift;
    croak qq{\nYou have to load some data before calling this method} if ( !exists $self->{analysis_state}{load} );
    $self->all_SS;
    $self->all_SC;
    $self->adjustments_for_correlation;

    #y set flag
    $self->{analysis_state}{analysis} = 1;
    return;
}
=head2 ancova_analysis
    
To perform the analysis.
   
    $anc->ancova_analysis;

=cut

sub all_SS {
    my $self = shift;
    for my $xy ( qw / X Y / ) {
        $self->group_SS($xy);
        $self->SS_variants($xy);
    }
    return;
}
       
sub group_SS {
    my ($self, $xy) = @_;
    my @groups = @{$self->{groups}};
    for my $group ( @groups, qq{T} ) {
        $self->SS( $group, $xy );
    }
    return;
}

sub SS { 
    my ($self, $subject, $variable) = @_;
    my $a_ref = $self->{data}{$subject}{$variable};
    #my $n = @{$a_ref};
    my $n = scalar(@{$a_ref});
    my $sum = List::Util::sum @{$a_ref};
    #my $mean = ( $sum / @{$a_ref} );
    my $mean = ( $sum / scalar(@{$a_ref}) );
    my $square_of_sum = Math::Cephes::pow ( $sum, 2 );
    ##e SS = ( sum ( Xi**2 ) ) - ( sum ( Xi ) )**2 / n
    my $sum_of_squares = List::Util::sum map { Math::Cephes::pow ( $_, 2 ) } @{$a_ref};
    my $SS = $sum_of_squares - ( $square_of_sum / @{$a_ref} );
    #my $_SS = $_sum_of_squares - ( $_square_of_sum / $#{$a_ref}+1 );
    
    # feed the object
    $self->{SS}{$subject}{$variable}{sum} = $sum;
    $self->{SS}{$subject}{$variable}{mean} = $mean;
    $self->{SS}{$subject}{$variable}{square_of_sum} = $square_of_sum;
    $self->{SS}{$subject}{$variable}{sum_of_squares} = $sum_of_squares;
    $self->{SS}{$subject}{$variable}{SS} = $SS;
    $self->{SS}{$subject}{$variable}{n} = $n;
    # return $sum, $square_of_sum, $sum_of_squares, $SS;    
    return;
}

sub SS_variants {
    my ($self, $variable) = @_;

    ##o the calculation involves getting SS_total - i.e. just the SS applied to ALL values of Y or X. then requires SS_within_group - just the sum of each groups SS and then
    ##o finally the SS_back_ground (though not for X - just Y) - this is just the SS_toatl - SS_within_group

    ##s pull the SS_total - i.e. SS method was called on T array containing all X or Y entries
    my $SS_Total = $self->{SS}{T}{$variable}{SS};
    #y call wg method - needs to know which variable we´re using
    my $SS_wg = $self->_SS_wg($variable);    
    $self->{SS}{$variable}{between_group} = ( $SS_Total - $SS_wg );     # parenthesis are just to make it easier to see what´s happening
    $self->{SS}{$variable}{within_group} = $SS_wg;
    $self->{SS}{$variable}{total} = $SS_Total;
    return;
}

sub _SS_wg {
    my ($self, $variable) = @_;
    ##s we need to sum the group SS scores for SS_within_group
    my @groups = @{$self->{groups}};
    my $SS_wg = 0;
    for my $group (@groups) {
        
        my $SS_group = $self->{SS}{$group}{$variable}{SS};
        $SS_wg += $SS_group;
    
    }
    return $SS_wg;
} 

sub all_SC {
    my ($self, $xy) = @_;
    $self->group_SC;
    $self->{SC}{T}{sum_of_X_and_Y_SC_within_group} = $self->_SC_wg;
    return;
}

sub group_SC {
    my $self = shift;
    my @groups = @{$self->{groups}};
    #y loop through all the groups and the Total array
    for my $group ( @groups, qq{T} ) {
        $self->SC ( $group );
    }
    return;
}

sub _SC_wg {
    my ($self) = @_;
    ##s we need to sum the group SC scores for SS_within_group
    my @groups = @{$self->{groups}};
    my $SC_wg = 0;
   
    for my $group (@groups) {
        my $SC_group = $self->{SC}{$group}{SC_within_group};
        $SC_wg += $SC_group;
    }
    return $SC_wg;
} 

sub SC {
    ##o just calculate covariates - i.e. X * Y in place of X**2...
    my ( $self, $subject ) = @_;
    my $subject_y = $self->{data}{$subject}{Y};
    my $subject_x = $self->{data}{$subject}{X};
    my $product_xy_sum;

    for (0..$#{$subject_x}) {
        my $val = $subject_x->[$_] * $subject_y->[$_];
        $product_xy_sum += $val;
    }

    my $subject_x_sum = List::Util::sum @{$subject_x};
    my $subject_y_sum = List::Util::sum @{$subject_y};

    my $SC = $product_xy_sum - ( $subject_x_sum * $subject_y_sum ) / @{$subject_x};

    # feed object - probably ought to always use this syntax to feed multiple values
    $self->{SC}{$subject} = {   sum_of_xy_products  =>  $product_xy_sum,
                                sum_of_x            =>  $subject_x_sum, 
                                sum_of_y            =>  $subject_y_sum, 
                                SC_within_group     =>  $SC
                            };
    return;
}

sub adjustments_for_correlation {
    ##o this runs all the adjustment methods as nested private methods
    my $self = shift;
    $self->_adjust_SS_Y_total;
    $self->_adjust_SS_Y_wg;
    $self->_adjust_SS_Y_bg;
    $self->_adjust_Y_means;
    $self->_analysis_covariance_with_adjusted_SS;
    return;
}

sub _adjust_SS_Y_total {
    ##o Adjusting SS_Y_total in light of covariance with X - 4a
    my $self = shift;
    
    ##e r_T = SC_T (this is the within group measure for all data = SC_T_SC_within_group) / ( sqrt ( SS_(X)_Total * SS_Y_Total )

    my $SS_Y_total = $self->{SS}{Y}{total};
    my $r_T = $self->{SC}{T}{SC_within_group} / sqrt ( $self->{SS}{X}{total} * $SS_Y_total );

    ##e The proportion of the total variability of Y attributable to its covariance with X / r_T_sq = r_T**2

    my $r_T_sq = Math::Cephes::pow ( $r_T, 2);
    
    ##s we adjust SS_Y_Total by removing from it this proportion of covariance. (1) we get this proportion of covariance proportion_of_SS_Y_Total = SS_Y_Total * r_T_sq.
    ##s (2) we subtract that from SS_Y_Total to get SS_Y_Total_Adj
    
    my $SS_Y_total_Adj = $SS_Y_total - ( $SS_Y_total * $r_T_sq );
    
    ##e - this is an algerbraic equivalent to prevent excessive rounding of r__T_sq: SS_Y_Total_Adj = SS_Y_Total - ( SC_Total / SS_X_Total )

    # send to object
    $self->{SS}{Y}{total_adjusted} = $SS_Y_total_Adj;
    $self->{output}{r_T} = $r_T;
    $self->{output}{r_T_sq} = $r_T_sq;

     return;    
}

sub _adjust_SS_Y_wg {
    ##o Adjusting SS_Y_wg on basis of covariance - 4b
    my $self = shift;
    
    ##e r_wg = SC_Total_wg / sqrt (SS_X_wg * SS_Y_wg )
    
    my $SS_Y_wg = $self->{SS}{Y}{within_group};
    my $r_wg = $self->{SC}{T}{sum_of_X_and_Y_SC_within_group} / sqrt ($self->{SS}{X}{within_group} * $SS_Y_wg );

    ##e The proportion of the within-groups variability of Y attributable to covariance with X / r_wg_sq = r_wg**2

    my $r_wg_sq = Math::Cephes::pow ( $r_wg, 2);

    my $SS_Y_wg_Adj = $SS_Y_wg - ( $SS_Y_wg * $r_wg_sq );

    # send to object
    $self->{SS}{Y}{within_group_adjusted} = $SS_Y_wg_Adj;
    $self->{output}{r_wg} = $r_wg;
    $self->{output}{r_wg_sq} = $r_wg_sq;

    return;
    
}

sub _adjust_SS_Y_bg {
    ##o Adjustment of SS_Y_bg - 4c
    my $self = shift;

    ##e SS_Y_bg_Adj = SS_Y_Total_Adj — SS_Y_wg_Adj

    my $SS_Y_bg_Adj = $self->{SS}{Y}{total_adjusted} - $self->{SS}{Y}{within_group_adjusted};

    # send to object
    $self->{SS}{Y}{between_group_adjusted} = $SS_Y_bg_Adj;
    return;
}

sub _adjust_Y_means {
    ##o Adjustment of the Means of Y for Groups A and B - 4d
    my $self = shift;
       
    ##e bwg / slope_aggreage_wg = SC_wg / SS_X_wg

    my $slope_aggregate_wg = $self->{SC}{T}{sum_of_X_and_Y_SC_within_group} / $self->{SS}{X}{within_group};
    
    $self->_adjust_each_mean($slope_aggregate_wg);
    return;
}

sub _adjust_each_mean {
    my ($self, $slope_aggregate_wg) = @_;

    ##s $self->{SS}{T}{X}{mean} will be used for each group
    my $Mean_X_for_all_samples = $self->{SS}{T}{X}{mean};    

    my @groups = @{$self->{groups}};

    for my $group (@groups) {    

        ##e Mean_Y_for_A_Adj = Mean_Y_for_A — slope_aggregate_wg (Mean_X_for_A — Mean_X_for_Total - i.e. all samples)
        my $Mean_group_Y_Adj = $self->{SS}{$group}{Y}{mean} - ( $slope_aggregate_wg * ( $self->{SS}{$group}{X}{mean} - $Mean_X_for_all_samples ) );

        #s send to object
        $self->{SS}{$group}{Y}{mean_adjusted} = $Mean_group_Y_Adj;

    }
    return;
}

sub _analysis_covariance_with_adjusted_SS {
    ##o Analysis of Covariance Using Adjusted Values of SS - calculating F - 4e
    my $self = shift;
    my $k = $self->{k}; 
    
    ##o In ANOVA the within-group variance df is: Nt (total number of subjects — k (number of groups). 
    ##o In ANCOVA the within-groups df is reduced by 1 due accomodate the fact that the CV portion of within-groups variability has been removed from the analysis. 
    
    ##e df_Y_wg_Adj = df_Y_wg - 1; = NT (total number of measurements)  — k (total number of groups/individuals/things) — 1 - here = 20 - 2 - 1) = 17

    my $df_wg_Y_Adj = $self->{SS}{T}{X}{n} - $k - 1; 
    
    ##o The df for between-groups remains the same as for one-way ANOVA

    ##e df_Y_bg = k — 1 - here = 2 — 1 = 1

    my $df_bg_Y = $k - 1;   

    ##e we use F = ( SS_bg_Y_Adj / df_bg_Y ) / ( SS_wg_Y_Adj / df_wg_Y_Adj )

    ##e MS_bg is SS_bg_Y_Adj / df_bg_Y and 

    my $MS_bg = ( $self->{SS}{Y}{between_group_adjusted} / $df_bg_Y );
    
    ##e MS_wg is SS_wg_Y_Adj / df_wg_Y_Adj
    
    my $MS_wg = ( $self->{SS}{Y}{within_group_adjusted} / $df_wg_Y_Adj );
    
    ##e F is usually expressed as MS_bg / MS_wg - 
    
    my $F = ( $MS_bg / $MS_wg );
    
    # feed to $self
    $self->{output}{df_Y_wg_Adj} = $df_wg_Y_Adj;
    $self->{output}{df_Y_bg} = $df_bg_Y;
    $self->{output}{MS_bg} = $MS_bg;
    $self->{output}{MS_wg} = $MS_wg;
    $self->{output}{F_score} = $F;

#    $self->{output} = { df_Y_wg_Adj => $df_wg_Y_Adj,
#                        df_Y_bg => $df_bg_Y,
#                        MS_bg => $MS_bg,
#                        MS_wg => $MS_wg,
#                        F_score => $F,
#                      };
    return;

}

sub results {                                     
 
    # unpack rest of @_ - may go to verbose or list printing
    my @other_args = @_;
    my $self = shift @other_args;
    
    croak qq{\nYou have to load some data before calling this method} if ( !exists $self->{analysis_state}{load} );
    croak qq{\nYou have to run ancova_analysis before calling this method} if ( !exists $self->{analysis_state}{analysis} );
    ##o get standard F values and generate messages
    
    #my ( $self, $verbose ) = @_;
    #$verbose ||= 0;
    #my $self = shift;
    #my $verbose = shift ||= 0;
    #$verbose = $verbose eq q{verbose} ? 1 : 0 ;
    
    my $df_wg_Y_Adj = $self->{output}{df_Y_wg_Adj};
    my $df_bg_Y = $self->{output}{df_Y_bg};
    my $F = $self->{output}{F_score};

    #@{$self->{output}{standard_F_values}} = map { my $standard_F = fdistr ( $df_bg_Y, $df_wg_Y_Adj, $_ ) ; { standard_F => $standard_F, p_val => $_ } } 
    #    (0.005, 0.01, 0.05, 0.1);   # using standard values of p

    #if ( $F > Statistics::Distributions::fdistr ($df_bg_Y,$df_wg_Y_Adj,0.01) ) { print qq{\n\nthis value of F is significant at the p=0.01 level} }
    #elsif ( $F > Statistics::Distributions::fdistr ($df_bg_Y,$df_wg_Y_Adj,0.05) ) { print qq{\n\nthis value of F is significant at the p=0.05 level} }
    #else { print qq{\n\nthis value of F is not significant } }
                                                                                                                                                        
    my $chosen_p_val = $self->{significance};
    my $standard_F = fdistr ($df_bg_Y,$df_wg_Y_Adj,$chosen_p_val);

    #/ this approach confuses people! have it simply pass of fail at their selected p_value - it already has a default value
#    my $message     =   $F > $standard_F                             ?   qq{This value of F is significant at your chosen p = $chosen_p_val level. }
#                    :   $F > fdistr ($df_bg_Y,$df_wg_Y_Adj,0.01)     ?   qq{This value of F is significant at the p = 0.01 level. }
#                    :   $F > fdistr ($df_bg_Y,$df_wg_Y_Adj,0.05)     ?   qq{This value of F is significant at the p = 0.05 level. }
#                    :                                                    qq{This is not a significant value of F. } # default behaviour
#    ;   

    my $message = $F > $standard_F ? qq{This value of F is significant at the p = $chosen_p_val level. } :
      qq{This is not a significant value of F at the p = $chosen_p_val level. };   

      
    my $p_for_F = fprob ( $df_bg_Y, $df_wg_Y_Adj, $F ) ;    
    $self->{output}{message} = $message;
    $self->{output}{standard_F} = $standard_F;
    $self->{output}{p_for_F} = $p_for_F;

    return  (                                        
            #VOID    { $self->_print_form(@other_args)  }  
            VOID    { $self->_print_form()              }  

#            LIST    { ( sprintf (qq{%.3f},$F), sprintf (qq{%.3f},$p_for_F), sprintf (qq{%.3f},$self->{output}{MS_bg}), 
#                        sprintf (qq{%.3f},$self->{SS}{Y}{between_group_adjusted}), $df_bg_Y, 
#                        sprintf (qq{%.3f},$self->{output}{MS_wg}), sprintf (qq{%.3f},$self->{SS}{Y}{within_group_adjusted}), 
#                        $df_wg_Y_Adj, sprintf (qq{%.3f},$self->{SS}{Y}{total_adjusted}), )                                      }    

            LIST    { $self->_return_list(@other_args) } 
            BOOL    { $F > $standard_F ? 1 : undef;    } 
            NUM     { $F ;                             }    
            STR     { $message                         }     
    );                          
}
=head2 results

Used to access the results of the ANCOVA analysis. This method is context-dependent and will return a variety of 
different values depending on its calling context. In VOID context prints a report to STDOUT (use 
C<set_output_verbosity> to print more detailed report). 

    # To print a short report to STDOUT
    $anc->results();
    # To print a detailed report set output_verbosity to 1 on object creation or using the set_output_verbosity> method.
    $anc->set_output_verbosity(1);
    $anc->results();


In LIST context it either returns the full list of all relevant values of F, p, df, MS... or returns an ordered subset of the values
depending on whether you call it without or with numbered arguments respectively (see below). 

    # Calling results in LIST without arguments returns the full list of relevant values of F, p, df, MS...
    my %hash;
    @hash{qw($F_score, $p_value, $MS_bg, $SS_bg_Adj, $df_bg_Y, $MS_wg, $SS_wg_Adj, $df_wg_Y_Adj, $SS_total_Adj)} = $anc->results();
    for (keys %hash) { print qq{\n$_ = $hash{$_} } };

However, calling C<results> in LIST context with numbered arguments corresponding to those below returns those arguments 
in the order passed to the method.

    #      0         1        2        3          4         5        6            7              8      
    # ($F_score, $p_value, $MS_bg, $SS_bg_Adj, $df_bg_Y, $MS_wg, $SS_wg_Adj, $df_wg_Y_Adj, $SS_total_Adj) = $anc->results(2,3,5)   
    print qq{\n\nCalling in LIST context. The F value, p_value, MS_bg and MS_wg are: @{$anc->results(0,1,2,,5)}};

In BOOLEAN context it returns true or false depending on whether the obtained F score was significant at the p_value chosen
upon object creation or set using the C<set_significance> method (defaults to p = 0.05). 

    if ($anc->results) { print qq{\nThis result is significant.} } else { print qq{\nThis result is not significant.} } 

In STRING context it returns a string message about whether the obtained F score was significant at the chosen p_value. 
    
    print qq{\n\nCall result in string returns a message : }, ''.$anc->results;  # Prints 'This value of F is significant at your chosen .05 level'... 

=cut

sub _print_form {
    #my ( $self, $verbose ) = @_;
    my $self = shift; 

    #$verbose ||= 0;
    #my $self = shift;
    #my $verbose = shift ||= 0;
    #$verbose = $verbose eq q{verbose} ? 1 : 0 ;
    
    my $verbose = $self->{verbosity}{output};
    
    my @groups = @{$self->{groups}};    
    
    #$verbose or print form { bullet => q{*} }, 
    $verbose and print form { bullet => q{*} }, 
    qq{\n\n ============================================================================= },
        qq{| Sum of squared          | Sum of squared          | Sum of co-deviates      |},
        qq{| deviates for X          | deviates for Y          |                         |},
        qq{|-------------------------|-------------------------|-------------------------|},
        qq{| SS_T_x  = {<<<<<<<<<<<} | SS_T_y  = {<<<<<<<<<<<} | SC_T  = {<<<<<<<<<<<<<} |},   
        sprintf (qq{%.3f},$self->{SS}{X}{total}), sprintf (qq{%.3f},$self->{SS}{Y}{total}), sprintf (qq{%.3f},$self->{SC}{T}{SC_within_group}),
        qq{|-----------------------------------------------------------------------------|},
        qq{| SS_wg_x = {<<<<<<<<<<<} | SS_wg_y = {<<<<<<<<<<<} | SC_wg = {<<<<<<<<<<<<<} |},  
        sprintf (qq{%.3f},$self->{SS}{X}{within_group}), sprintf (qq{%.3f},$self->{SS}{Y}{within_group}), sprintf (qq{%.3f},$self->{SC}{T}{sum_of_X_and_Y_SC_within_group}),
        qq{|-----------------------------------------------------------------------------|},
        qq{|                         | SS_bg_y = {<<<<<<<<<<<} |                         |}, 
        sprintf (qq{%.3f},$self->{SS}{Y}{between_group}),
        qq{ ============================================================================= },
        qq{                                                                               },
        qq{ ============================================================================= },
        qq{| Overall correlation and adjustment of SS_T_Y                                |},
        qq{|-------------------------|-------------------------|-------------------------|},
        qq{| r_T = {<<<<<<<<<<<<<<<} | r_T_sq = {<<<<<<<<<<<<} | SS_T_y_Adj  = {<<<<<<<} |},
        sprintf (qq{%.9f},$self->{output}{r_T}), sprintf (qq{%.9f},$self->{output}{r_T_sq}), sprintf (qq{%.3f},$self->{SS}{Y}{total_adjusted}),
        qq{|-----------------------------------------------------------------------------|},
        qq{| Aggregate correlation and adjustment of SS_wg_y                             |},
        qq{|-------------------------|-------------------------|-------------------------|},
        qq{| r_wg = {<<<<<<<<<<<<<<} | r_wg_sq = {<<<<<<<<<<<} | SS_wg_y_Adj = {<<<<<<<} |},
        sprintf (qq{%.9f},$self->{output}{r_wg}), sprintf (qq{%.9f},$self->{output}{r_wg_sq}), sprintf (qq{%.3f},$self->{SS}{Y}{within_group_adjusted}),
        qq{|-----------------------------------------------------------------------------|},
        qq{| Adjustment of SS_bg_y                                                       |},
        qq{|-----------------------------------------------------------------------------|},
        qq{|                         | SS_bg_y_Adj = {<<<<<<<} |                         |},   # this specifies locations and formating of variables
        sprintf (qq{%.3f},$self->{SS}{Y}{between_group_adjusted}),
        qq{ ============================================================================= },
        qq{                                                                               },
        qq{ ============================================================================= },
        qq{| Overall Means for X and Y variables                                         |},
        qq{|-----------------------------------------------------------------------------|},
        qq{| Mean_X_overall = {<<<<<<<<<<<<<<<<<<} | Mean_Y_overall = {<<<<<<<<<<<<<<<<} |},
        sprintf (qq{%.3f},$self->{SS}{T}{X}{mean}), sprintf (qq{%.3f},$self->{SS}{T}{Y}{mean}),
        qq{ ============================================================================= },
;        

    #if (!$verbose) {
    if ($verbose) {
        for my $group ( (sort {$a cmp $b} @groups) ) {
            print form { bullet => q{*} },
                qq{                                                                               },
                qq{ ============================================================================= },
                qq{| Means for group {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}                  |},
                $group,
                qq{|-----------------------------------------------------------------------------|},
                qq{| Mean_X = {<<<<<<<<<<<<} | Mean_Y = {<<<<<<<<<<<<} | Mean_Y_Adj = {<<<<<<<<} |},
                sprintf (qq{%.3f},$self->{SS}{$group}{X}{mean}), sprintf (qq{%.3f},$self->{SS}{$group}{Y}{mean}), sprintf (qq{%.3f},$self->{SS}{$group}{Y}{mean_adjusted}),
                qq{ ============================================================================= },
;
        }
    }

    print form { bullet => q{*} }, 
      qq{\n ============================================================================= },
        qq{| ANCOVA                                                                      |},
        qq{|-----------------------------------------------------------------------------|},
        qq{|                    | df       | SS       | MS       | F        |  p         |},
        qq{|-----------------------------------------------------------------------------|},
        qq{| Adjusted means be- | {<<<<<<} | {<<<<<<} | {<<<<<<} | {<<<<<<} | {<<<<<<<<} |},
        $self->{output}{df_Y_bg}, sprintf (qq{%.3f},$self->{SS}{Y}{between_group_adjusted}), 
        sprintf (qq{%.3f},$self->{output}{MS_bg}), sprintf (qq{%.3f},$self->{output}{F_score}), $self->{output}{p_for_F},
        qq{| teen groups effect |          |          |          |          |            |},
        qq{|-----------------------------------------------------------------------------|},
        qq{| Adjusted error     | {<<<<<<} | {<<<<<<} | {<<<<<<} |          |            |},
        $self->{output}{df_Y_wg_Adj}, sprintf (qq{%.3f},$self->{SS}{Y}{within_group_adjusted}), sprintf (qq{%.3f},$self->{output}{MS_wg}),
        qq{| within groups      |          |          |          |          |            |},
        qq{|-----------------------------------------------------------------------------|},
        qq{| Adjusted total     |          | {<<<<<<} |          |          |            |},
        sprintf (qq{%.3f},$self->{SS}{Y}{total_adjusted}),
        qq{|                    |          |          |          |          |            |},
        qq{ ============================================================================= },
;

    $verbose and print form { bullet => q{*} }, 
        qq{                                                                               },
        qq{ ============================================================================= },
        qq{| Overview                                                                    |},
        qq{|-----------------------------------------------------------------------------|},
        qq{| your chosen p value = {<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<} |},
        $self->{significance},       
        qq{|-----------------------------------------------------------------------------|},
        qq{| standard F value for these df and p = {<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<} |},
        sprintf (qq{%.3f},$self->{output}{standard_F}),        
        qq{|-----------------------------------------------------------------------------|},
        qq{| {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} |},
        $self->{output}{message},     
        qq{ ============================================================================= },
;

    return;
}

sub _return_list {
    
    my @list = @_;
    my $self = shift @list;
    # unpack the rest of @_
    #print qq{\n\nlist is: @list};
    my @returns = ();
    #if ( scalar(@list) > 0 ) {
    if ( scalar(@list) ) {
        #while (my $parameter = @list) 

        my %mapping = (     0   =>  q{F_score}, 
                            1   =>  q{p_for_F}, 
                            2   =>  q{MS_bg}, 
                            3   =>  q{between_group_adjusted}, 
                            4   =>  q{df_Y_bg}, 
                            5   =>  q{MS_wg}, 
                            6   =>  q{within_group_adjusted}, 
                            7   =>  q{df_Y_wg_Adj}, 
                            8   =>  q{total_adjusted},
                    );
                    
                    #print qq{\nhere is the list @list};

        for my $parameter (@list)   {

            croak qq{\nThe parameters passed must be numeric corresponding to those documented in the synopsis.} if ($parameter !~ /\A[0-8]\z/xms);
           
            #print qq{\npushing $parameter};
           
            my $named_param = $mapping{$parameter};
            #print qq{\nmy named $named_param};

            if ( $parameter == 3 || $parameter == 6 || $parameter == 8 )    {

                push @returns, sprintf(qq{%.3f},$self->{SS}{Y}{$named_param});
            }
            else    {

                my $value = $self->{output}{$named_param};
                $value = sprintf(qq{%.3f},$value) if ($parameter != 1);
                push @returns, $value;
            }

        }
    return @returns;
    }

    else {

            @returns = ( sprintf (qq{%.3f},$self->{output}{F_score}),       $self->{output}{p_for_F}, 
                sprintf (qq{%.3f},$self->{output}{MS_bg}),                  sprintf (qq{%.3f},$self->{SS}{Y}{between_group_adjusted}), 
                $self->{output}{df_Y_bg},                                   sprintf (qq{%.3f},$self->{output}{MS_wg}), 
                sprintf (qq{%.3f},$self->{SS}{Y}{within_group_adjusted}),   $self->{output}{df_Y_wg_Adj}, 
                sprintf (qq{%.3f},$self->{SS}{Y}{total_adjusted}) ); 

    }
    return @returns;
}

1; # Magic true value required at end of module
__END__

=head1 DEPENDENCIES

'version'                   => 0,
'Statistics::Distributions' => '1.02',
'Math::Cephes'              => '0.47', 
'Carp'                      => '1.08', 
'Perl6::Form'               => '0.04',
'Contextual::Return'        => '0.2.1',
'List::Util'                => '1.19', 

=cut
=head1 AUTHOR

Daniel S. T. Hughes  C<< <dsth@cpan.org> >>.

=cut
=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Daniel S. T. Hughes C<< <dsth@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
=head1 SEE ALSO

L<Statistics::Descriptive>, L<Statistics::Distributions>, L<Statistics::Distributions::Analyze>, L<Statistics::ANOVA>.

=cut
=head1 DISCLAIMER OF WARRANTY

Because this software is licensed free of charge, there is no warranty
for the software, to the extent permitted by applicable law. except when
otherwise stated in writing the copyright holders and/or other parties
provide the software "as is" without warranty of any kind, either
expressed or implied, including, but not limited to, the implied
warranties of merchantability and fitness for a particular purpose. The
entire risk as to the quality and performance of the software is with
you. should the software prove defective, you assume the cost of all
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

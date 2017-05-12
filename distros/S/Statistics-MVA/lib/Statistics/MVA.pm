package Statistics::MVA;
use strict;
use warnings;
use Carp;
use Math::MatrixReal;

#r/ while this module is intended to be the base module and dependency for - and eventually... YOU CAN USE IT TO GENERATE GROUPS OF CV_MATRICES
#y standardise - i.e. make sig=1 and mu=0?!? while div - these are more for factor and PCA... so are largely irrelevant

#/ need to confirm these are defaults: {standardise => 0, divisor => 1}

use version; our $VERSION = qv('0.0.2');

=head1 NAME

Statistics::MVA - Base module/Dependency for other modules in Statistics::MVA namespace.

=cut
=head1 VERSION

This document describes Statistics::MVA version 0.0.2

=cut

#/ perhaps add something about generating CV_matrices using Statistics::MVA::CVMat and groups of them with Statistics::MVA

=head1 DESCRIPTION

This module is a base module for the other modules in the Statistics::MVA namespace (e.g. Statistics::MVA::Bartlett,
Statistics::MVA::Hotelling etc.). It is not intended for direct use - though it may be used for generating covariance matrices directly.

This set of modules is still very much in development. Please let me know if you find any bugs.

The constructor accepts an array containing a series of List-of-Lists (LoL) references and returns an object of the form
(modified output from Data::TreeDraw):
    
    ARRAY REFERENCE (0)
      |  
      |__ARRAY REFERENCE (1) [ '->[0]' ]     
      |    |  
      |    |__ARRAY REFERENCE (2) [ '->[0][0]' ]
      |    |    |  
      |    |    |__BLESSED OBJECT BELONGING TO CLASS: Math::MatrixReal (3)  [ '->[0][0][0]' ]    
      |    |    |  MatrixReal object containing covariance matrix for first LoL passed.
      |    |    |  
      |    |    |__SCALAR = '7' (3)  [ '->[0][0][1]' ]                                           
      |    |    |  p for first LoL.
      |    |    |  
      |    |    |__ARRAY REFERENCE (3) [ '->[0][0][2]' ]
      |    |       LoL of the raw data passed.
      |    |  
      |    Continues for all other LoLs refs passed.
      |  
      |__SCALAR = '3' (1)  [ '->[1]' ]                                                          
      |  k.
      |  
      |__SCALAR = '3' (1)  [ '->[2]' ]                                                       
      |  Overall p - i.e. only allows completes if all individual p´s are equal.
      |  
      |__SCALAR = '0' (1)  [ '->[3]' ]                                                          
      |  Value of standardise option.
      |  
      |__SCALAR = '1' (1)  [ '->[4]' ]                                                         
         Value of divisor option.

=cut

sub new {
    my ($class, $groups, $options) = @_;
    my $k = scalar @{$groups};
    croak qq{\nThere must be more than one group} if ($k < 2);
    croak qq{\nArguments must be passed as HASH reference.} if ( ( $options ) && ( ref $options ne q{HASH} ) );

    my ($s_ref, $p, $stand, $div) = &_cv_matrices($groups, $k, $options);
   
    #y feed object - still need data, but this is messy
    my $self = [$s_ref, $k, $p, $stand, $div];
    #my $self = [$s_ref, $k, $p, $groups];

    bless $self, $class;
    return $self;
}

sub _cv_matrices {
    my ( $groups, $k, $options ) = @_;
    my $stand = defined $options && exists $options->{standardise} ? $options->{standardise} : 0;
    my $div = exists $options->{divisor} ? $options->{divisor} : 1;
    my @p;
    my $a_ref = [];
    #for my $i (0..$self->[1]-1) {
    for my $i (0..$k-1) {
        # this will be combined into single step
        my $mva = Statistics::MVA::CVMat->new($groups->[$i],{standardise => $stand, divisor => $div});
        #my $mva = Statistics::MVA->new($self->[0][$i],{standardise => 0, divisor => 1});
        my $mva_matrix = my $a = Math::MatrixReal->new_from_rows($mva->[0]);
        push @p, $mva->[1];
        #y don´t want the adjusted scores anymore
        #$a_ref->[$i] = [ $mva_matrix, $mva->[2], $mva->[3] ]; 
        #$a_ref->[$i] = [ $mva_matrix, $mva->[2] ]; 
        #y let´s feed data in too
        $a_ref->[$i] = [ $mva_matrix, $mva->[2], $groups->[$i] ]; 
    }
    my $p_check = shift @p;
    #croak qq{\nAll groups must have the same variable number} if &_p_notall(@p);
    croak qq{\nAll groups must have the same variable number} if &_p_notall($p_check, \@p);
    return ($a_ref, $p_check, $stand, $div);
}

sub _p_notall {
    my ($p_check, $p_ref) = @_;
    #my @p = @_;
    #my $p_check = shift @p;
    #for (@p) {
    for (@{$p_ref}) {
        # return 0 if $_ != $p_check;
        return 1 if $_ != $p_check;
    } 
    return 0;
}

1;

package Statistics::MVA::CVMat;
use strict;
use warnings;
use Carp;
use List::Util qw/sum/;

# covariance matrix or dispersion matrix is a matrix of covariances between elements
sub new {
    my ( $class, $lol, $h_ref ) = @_;

    croak qq{\nData must be passed as ARRAY reference.} if ( !$lol || ( ref $lol ne q{ARRAY} ) );
    croak qq{\nArguments must be passed as HASH reference.} if ( ( $h_ref ) && ( ref $h_ref ne q{HASH} ) );
    croak qq{\nAll data must be a matrix of numbers} if &_check($lol);
    
    my $stand = exists $h_ref->{standardise} ? $h_ref->{standardise} : 0;
    my $div = exists $h_ref->{divisor} ? $h_ref->{divisor} : 1;
    $lol = &transpose($lol);
    # need to have adjusted atm
    # my ( $cv, $p, $n ) = &_cv($lol, $stand, $div);
    #y not using adjusted anymore here
    my ( $cv, $p, $n ) = &_cv($lol, $stand, $div);
    #my ( $cv, $p, $n, $adjusted ) = &_cv($lol, $stand, $div);
    #y not using adjusted anymore here
    my $self = [$cv,$p,$n];
    # my $self = [$cv,$p,$n, $adjusted];
    bless $self, $class;
    return $self;
}

sub _check {
    # we already checked $lol is an array. 
    my $lol = shift;
    my @lol = @{$lol};
    my $l_check = shift @lol;
    $l_check = scalar ( @{$l_check} );
    for my $r (@lol) { 
        return 1 if ( scalar ( @{$r} ) != $l_check );
        for my $cell (@{$r}) {
            #/ No need to check that $cells are scalars - i.e. ref \$cell eq q{SCALAR} etc as regexp checks it a number!
            return 1 if ( $cell !~ /\A[+-]?\ *(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?\z/xms );
        }
    }
    return 0;
}

sub transpose {
    my $a_ref = shift;
    my $done = [];
    for my $col ( 0..$#{$a_ref->[0]} ) {
    push @{$done}, [ map { $_->[$col] } @{$a_ref} ];
    }
    return $done;
}

sub _cv {
    my ( $lol, $stand, $div ) = @_;
    # only accepts table format
    my ( $averages, $var_num, $var_length) = &_averages($lol);
    my $variances = &_variances ( $lol, $averages, $var_num );
    my $adjusted = &_adjust ($lol, $averages, $variances, $var_num, $stand);
    my $cv_mat = &_CVs($adjusted, $var_num, $var_length, $div);
    #y not using adjusted anymore here
    return ($cv_mat, $var_num, $var_length);
    # return ($cv_mat, $var_num, $var_length, $adjusted);
}

sub _averages {
    my $lol = shift;
    my $var_num = scalar ( @{$lol} );
    my $var_length = scalar ( @{$lol->[0]} );
    my $totals_ref = [];
    for my $row (0..$var_num-1) { 
        my $sum = sum @{$lol->[$row]};
        my $length = scalar ( @{$lol->[$row]} );
        my $average = $sum / $length;
        push @{$totals_ref}, { sum => $sum, length => $length, average => $average};
    }
    #$self->{averages} = $totals_ref;
    #$self->{var_num} = $var_num;
    #$self->{var_length} = $var_length;
    return ($totals_ref, $var_num, $var_length);
}

sub _variances {
    my ( $data, $avs, $n ) = @_;
    #my $self = shift;
    #my $data = $self->{data};
    #my $avs = $self->{averages};
    my $var = [];
    for my $row ( 0..$n-1 ) { 
        my $sum = sum map { ($_ - $avs->[$row]{average})**2 } @{$data->[$row]};
        my $length = scalar ( @{$data->[$row]} );
        my $variance = $sum / $length;
        push @{$var}, $variance;
    }
    return $var;
}

sub _adjust {

    my ($trans, $totals, $variances, $n, $stand) = @_;
    my $adjust = [];
    croak qq{\nI don\'t recognise that value for the \'standardise\' option - requires \'1\' or \'0\' (defaults to \'0\' without option).} 
      if ( $stand !~ /\A[01]\z/xms );
  
    # if ( $stand == 1 ) { for my $row ( 0..$n-1 ) { @{$adjust->[$row]} = map { ( $_ - $totals->[$row]{average}) / sqrt($variances->[$row]) } @{$trans->[$row]}; } 
    # $self->{adjusted} = $adjust; return $adjust; } 
    # elsif ($stand == 0 ) { for my $row ( 0..$n-1 ) { @{$adjust->[$row]} = map { ( $_ - $totals->[$row]{average}) } @{$trans->[$row]}; }
    # $self->{adjusted} = $adjust; return $adjust }

    for my $row ( 0..$n-1 ) {
        my $divisor = $stand == 1 ? sqrt($variances->[$row]) : 1;
        @{$adjust->[$row]} = 
            #map { ( $_ - $totals->[$row]{average}) / sqrt($variances->[$row]) } @{$trans->[$row]};
            map { ( $_ - $totals->[$row]{average}) / $divisor } @{$trans->[$row]};
    }
    return $adjust;
}

sub _CVs {

    my ($adjusted, $var_num, $length, $div) = @_;
    croak qq{\nI don\'t recognise that value for the \'divisor\' option - requires \'1\' for n-1  or \'0\' for n (defaults to \'1\').} 
      if ( $div !~ /\A[01]\z/xms );
    my $covariance_matrix_ref = [];
   
    #/ this is silly - just have divisor: $divisor = $div == 1 ? $length-1 : $length;
    # if ( $div == 0 ) { for my $row ( 0..($var_num-1) ) { for my $col ( 0..($var_num-1) ) { my $sum = 0; for my $iteration (0..$#{$adjusted->[0]}) { 
    # my $val = $adjusted->[$col][$iteration] * $adjusted->[$row][$iteration]; $sum += $val; } my $cv = $sum / ($length-1); my $cv = $sum / $length; 
    # $covariance_matrix_ref->[$col][$row] = $cv; } } $self->{covariance_matrix} = $covariance_matrix_ref; return $covariance_matrix_ref; }
    # elsif ( $div == 1 ) { for my $row ( 0..($var_num-1) ) { for my $col ( 0..($var_num-1) ) { my $sum = 0; for my $iteration (0..$#{$adjusted->[0]}) {
    # my $val = $adjusted->[$col][$iteration] * $adjusted->[$row][$iteration]; $sum += $val; } my $cv = $sum / ($length-1); my $cv = $sum / $length;
    # $covariance_matrix_ref->[$col][$row] = $cv; } } $self->{covariance_matrix} = $covariance_matrix_ref; return $covariance_matrix_ref; }

    my $divisor = $div == 1 ? $length-1 : $length;

    for my $row ( 0..($var_num-1) ) {
        for my $col ( 0..($var_num-1) ) {
            my $sum = 0;
            for my $iteration (0..$#{$adjusted->[0]}) {
                my $val = $adjusted->[$col][$iteration] * $adjusted->[$row][$iteration];
                $sum += $val;
            }
            #my $cv = $sum / ($length-1);
            my $cv = $sum / $divisor;
            #my $cv = $sum / $length;
            $covariance_matrix_ref->[$col][$row] = $cv;
        }
    }
    #$self->{covariance_matrix} = $covariance_matrix_ref;
    return $covariance_matrix_ref;
}

1;

__END__

=head1 DEPENDENCIES

'Carp' => '1.08',
'Math::MatrixReal' => '2.05',

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
=CUT

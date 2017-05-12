package Statistics::PCA::Varimax;

use warnings;
use strict;
use Carp;
use Math::GSL::Linalg::SVD;
use Math::MatrixReal;
use List::Util qw(sum);

=head1 NAME

Statistics::PCA::Varimax - A Perl implementation of Varimax rotation.

=cut

=head1 VERSION

This document describes Statistics::PCA::Varimax version 0.0.2


=cut

=head1 SYNOPSIS

    use Statistics::PCA::Varimax;
    
    # Each nested array ref corresponds to the loadings for a single factor.
    my $loadings = [
                        [qw/  0.28681878905  0.69807334810  0.74438876316  0.47052419229  0.68079195447  0.49817011866  0.86049803480  0.64178962603 0.29784558460 /],
                        [qw/  0.07560334830  0.15335493657 -0.40959477002  0.52231277744 -0.15586396086 -0.49832262559 -0.11502014276  0.32160898539 0.59537280152 /],
                        [qw/ -0.84084848877 -0.08371208961  0.02047721303 -0.13507580587  0.14832508991  0.25345619152 -0.01159349490 -0.04396749541 0.53340721684 /],
                   ];

    # Calculate the rotated loadings and orthogonal matrix.
    my ($rotated_loadings_ref, $orthogonal_matrix_ref) = &rotate($loadings);

    print qq{\nRotated Loadings:\n};
    for my $c (0..$#{$rotated_loadings_ref->[0]}) { for my $r (0..$#{$rotated_loadings_ref}) { 
        #print qq{$rotated_loadings_ref->[$r][$c], and r: $r and c: $c\t} }; print qq{\n}; 
        print qq{$rotated_loadings_ref->[$r][$c]\t} }; print qq{\n}; 
        }

    print qq{\nOrthogonal Matrix:\n};
    for my $r (0..$#{$orthogonal_matrix_ref}) { for my $c (0..$#{$orthogonal_matrix_ref->[$r]}) { 
        print qq{$orthogonal_matrix_ref->[$r][$c]\t} }; print qq{\n}; 
        }

=cut

=head1 DESCRIPTION

Varimax rotation is a change of coordinates used in principal component analysis and factor analysis that maximizes the
sum of the variances of the squared loadings matrix. This module exports a single routine 'rotate'. This routine is
called in LIST context and accepts a LIST-of-LISTS (LoL) corresponding to the loadings matrix of a factor analysis and
returns two references to LoLs (NOTE: each nested LIST corresponds to the loadings for a single factor). The first is a 
LoL of the rotated loadings and the seconds is a LoL of the orthogonal matrix. See http://en.wikipedia.org/wiki/Varimax_rotation.

=cut

=head1 DEPENDENCIES

'Math::GSL::Linalg::SVD'    =>  '0.0.2',
'Math::MatrixReal'          =>  '2.05',
'List::Util'                =>  '1.22',

=cut

=head1 AUTHOR

Daniel S. T. Hughes  C<< <dsth@cpan.net> >>

=cut

use version; our $VERSION = qv('0.0.2');

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(rotate);            # symbols to export by default

sub rotate {
    my $var = shift;

    croak qq{\nCall me in LIST context} if !wantarray;

    &_data_checks($var);

    # (1a) normalise

    #y calculate - the sqrt of the sum of the squares of each row
    my $sc_vec = &_calc_sc_vec($var);

    #y divide each entry in each row by the normalising values - not matrix multiplication - i.e. in this case it is 9x3 devided by 1x9 - i.e. could only give 1x3 or 3x1

    my $mat_t = &_transpose($var);

    #/ call with 3rd arg for multiplification
    #$mat_t = _devide_normalise($mat_t,$sc_vec);
    $mat_t = &_normalise($mat_t,$sc_vec);

    my $normalised_data = &_transpose($mat_t);

    #y transpose before or after?!?
    my $norm_mat = Math::MatrixReal->new_from_cols ( $normalised_data );

    # (1b) initialise others - p and nc - i.e. variable and factor number

    my $p_variables = scalar ( @{$mat_t} );
    my $nc_factors = scalar ( @{$mat_t->[0]} );

    # (1c) initialise TT diagonal array
    #my @ar = (1) x scalar ( @{$mat_t->[0]} );
    my @ar = (1) x $nc_factors;
    my $TT = Math::MatrixReal->new_diag( [ @ar ] );

    #/ iterations
    $TT = &_iterate($TT, $p_variables, $nc_factors, $norm_mat );

    #y we repeat step 2a of loop for z generation one final time - i.e. z = x * TT
    my $z = $norm_mat->multiply($TT);

    #my ($rows,$columns) = $TT->dim();
    #my ($rows1,$columns1) = $norm_mat->dim();
    #my ($rows2,$columns2) = $z->dim();

    #y we now reverse the normalisation step: 
    my $z_last = _deep_copy($z->[0]);
  
    #/ call with 3rd argument to multiply
    #$z_last = &_multiply_normalise($z_last, $sc_vec);
    $z_last = &_normalise($z_last, $sc_vec, 1);

    #y use from_rows instead of cols...
    #my $z_last_mat = Math::MatrixReal->new_from_cols ( $z_last );
    #$z_last_mat = ~$z_last_mat;
    my $z_last_mat = Math::MatrixReal->new_from_rows ( $z_last );

    my $rotated_loadings = _transpose($z_last_mat->[0]);

    return $rotated_loadings, $TT->[0];
    # return $z_last_mat, $TT;
}

sub _data_checks {
    my $data_a_ref = shift;

    my $rows = scalar ( @{$data_a_ref} );
    croak qq{\nI need some data - there are too few rows in your data.\n} if ( !$rows || $rows == 1 );
    my $cols = scalar ( @{$data_a_ref->[0]} );
    croak qq{\nI need some data - there are too few columns in your data.\n} if ( !$cols || $cols == 1 );
    for my $row (@{$data_a_ref}) {
        croak qq{\n\nData set must be passed as ARRAY references.\n} if ( ref $row ne q{ARRAY} );
        croak qq{\n\nAll rows must have the same number of columns.\n} if ( scalar( @{$row} ) != $cols );
    }
    #/ was lazy and cut-n-pasted inappropriate tests - i.e. don´t check for auto-assigning of undef... use matrixreal tests!
    my $test = Math::MatrixReal->new_from_rows($data_a_ref) ;    
    return;
}

sub _iterate {
    my ( $TT, $p_variables, $nc_factors, $norm_mat ) = @_;
    
    # (1d) initialise d
    my $d = 0;

    # (1e) initialise looping params;
    my $z;
    my $param = 1e-05;
    my $count = 1;

    
    LOOP_LABEL: for (1..3000) {

        # (2a) create z matrix: z <- x * TT 
        $z = $norm_mat->multiply($TT);

        # (2b) create matrix B

        #r (1) - create array of 1´s
        #my @ar_var = (1) x scalar ( @{$mat_t} );
        my @ar_var = (1) x $p_variables;
        # make matrix out of single array/vector
        my $vector_of_ones_mat = Math::MatrixReal->new_from_rows( [ [@ar_var] ] );

        #print qq{\n\nwe have diagonal matrix\n}, $vector_of_ones;

        #r (2) create matrices of z to powers
        my $z_3_mat = _raise_to_power($z,3);
        my $z_2_mat = _raise_to_power($z,2);

        #r (3) multiply vector_of_ones_mat by z_2_mat - vector of ones is 1x9 and z´s are same as loadings e.g. 9x3 - thus we generate 1xfactor-number
        my $vec1s_z2 = $vector_of_ones_mat->multiply($z_2_mat);

        #r (4) we want to generate a matrix from a vector of diagonals - the vector of diagonals is in the single row  
        my $vec1s_z2_diag = Math::MatrixReal->new_diag( [ @{_deep_copy($vec1s_z2->[0])->[0]} ] );

        #r (5) divide each by factor number - do inplace
        #$vec1s_z2_diag->multiply_scalar($vec1s_z2_diag,1/9);
        $vec1s_z2_diag->multiply_scalar($vec1s_z2_diag,1/$p_variables);

        #r (6) multiply z  by vec1s_z2_diag 
        my $vec1s_z2_diag_z_prod = $z->multiply($vec1s_z2_diag);

        #r (7) subtract vec1s_z2_diag_z_prod from z^3
        # must initialise a matrix to use subtract
        #my $z3_subtracted = new Math::MatrixReal(9,3); 
        my $z3_subtracted = new Math::MatrixReal($p_variables,$nc_factors); # matrix must already exist to use subtract
        $z3_subtracted->subtract($z_3_mat,$vec1s_z2_diag_z_prod);

        #r (7) t(x) %*% (z^3 - z %*% diag(drop(rep(1, p) %*% z^2))/p)
        #y instead of transposing x we transpode z3_subtracted to allow multiplification... then transpose... - probably best to tranpose other to directly get B

        #/ mult syntax is mat1(blah1,n) x mat2(n,blah2) mat1->multiply(mat2) - thus: $z3_subtracted = ~$z3_subtracted; my $B= $z3_subtracted->multiply($norm_mat);
        #/ resulting in a need to transpose B should be identical to reversing process
        #        $z3_subtracted = ~$z3_subtracted;
        #        #y z3_subtracted is now 3x9 - norm is still 9x3
        #        #$norm_mat = ~$norm_mat;
        #        #y 3x9 * 9x3
        #        my $B = $z3_subtracted->multiply($norm_mat);
        #        
        #        $B = ~$B;
        #/////////////////////////////////////////////////////////////////////////////////////
        #y norm is 9x3
        my $norm_mat_alt = ~$norm_mat;
        #y norm_alt is 3x9
        my $B = $norm_mat_alt->multiply($z3_subtracted);
        #print qq{\n\nwe have B\n}, $B;
        #/////////////////////////////////////////////////////////////////////////////////////

        # (2c) SVD - uses PDL and SDV GSL module
        #r sB <- La.svd(B)
        my $b = $B->[0];

        my $svd = Math::GSL::Linalg::SVD->new;
        $svd->load_data( {data => $b});
        $svd->decompose({ algorithm => q{gd} });
        my ($d_vec, $u, $v) = $svd->results;

        my $u_mat = Math::MatrixReal->new_from_cols($u);
        my $v_mat = Math::MatrixReal->new_from_cols($v);
        $u_mat = ~$u_mat;

        # (2d) TT <- sB$u %*% sB$vt
        $TT = $u_mat->multiply($v_mat);

        # (2e) we save old d
        my $d_old = $d;
        #my $d_old = deep_copy($d);

        # (2f) calculate new d - don´t re-declare - over-writing previous value
        $d = sum @{$d_vec};

        # (2g) possible premature loop exit
        $count++;
        #if ( $d < ( $d_old * ( 1 + $param ) ) ) { print qq{\n\nEXITING EARLY AT ITERATION $count\n\n};last LOOP_LABEL; }
        last LOOP_LABEL if ( $d < ( $d_old * ( 1 + $param ) ) );

    }
    return $TT;
}

sub _deep_copy { 
    my $ref = shift;
    if (!ref $ref) { $ref; } 
    elsif (ref $ref eq q{ARRAY} ) { [ map { _deep_copy($_) } @{$ref} ];    } 
    elsif (ref $ref eq q{HASH} )  { 
    + {   map { $_ => _deep_copy($ref->{$_}) } (keys %{$ref})   };    } 
    else { die "what type is $_?" }
}

sub _transpose {
    my $a_ref = shift;
    my $done = [];
    for my $col ( 0..$#{$a_ref->[0]} ) {
    push @{$done}, [ map { $_->[$col] } @{$a_ref} ];
    }
    return $done;
}

sub _calc_sc_vec {
    my $lol = shift;
    my $sc_vec = [];
    $lol = &_transpose ($lol);
    for my $i ( @{$lol} ) {
            my $val = sqrt (sum map { $_**2 } @{$i} );
            push @{$sc_vec}, $val;
    }
    return $sc_vec;
}

sub _raise_to_power {
    my ($z, $power) = @_;
    # making a new matrix so best to deep_copy rather than fuck up the whole thing - just the data of the matrix
    my $z_3 = _deep_copy($z->[0]);
    for my $rows (0..$#{$z_3}) {
        for my $col (@{$z_3->[$rows]}) {
            $col = $col**$power }}
    my $z_3_mat = Math::MatrixReal->new_from_rows( $z_3 );
    #print qq{\n\nwe have z^3 in R\n}, $z_3_mat;
    return $z_3_mat;
}


#print qq{\ncalling with 3rd arg:\n }, &_normalise(1,2,q{ee});
#print qq{\ncalling without 3rd arg:\n }, &_normalise(1,2,);

#/ call with any 3rd arg to make multiplification
sub _normalise {
    my ( $mat_t, $sc_vec, $mult ) = @_;
    for my $rows (0..$#{$mat_t}) {
        for my $col (@{$mat_t->[$rows]}) {
            #if (@_ > 2) { print qq{long } } else { print qq{not long } };
            #if (defined $mult) { print qq{defined } } else { print qq{not defined } };
            if (@_ == 2) {
                $col = $col / $sc_vec->[$rows];
            }
            elsif (@_ ==3) {
                $col = $col * $sc_vec->[$rows];
            }
        }
    }
    return $mat_t;
}

#my ($z_last_mat, $TT) = &rotate($var);
#print qq{\n\n\nwe are done\n\nloadings:\n}, $z_last_mat, qq{\n\nand rotmat:\n}, $TT;


1; # Magic true value required at end of module
__END__

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

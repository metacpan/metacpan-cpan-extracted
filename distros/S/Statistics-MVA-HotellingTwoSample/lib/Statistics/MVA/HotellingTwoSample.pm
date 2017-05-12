package Statistics::MVA::HotellingTwoSample;

use base Statistics::MVA;
use warnings;
use strict;
use Carp;
use Statistics::Distributions qw/fprob/;

=head1 NAME

Statistics::MVA::HotellingTwoSample - Two-Sample Hotelling's T-Square Test Statistic.

=cut

=head1 VERSION

This document describes Statistics::MVA::HotellingTwoSample version 0.0.2

=cut

=head1 SYNOPSIS

    use Statistics::MVA::HotellingTwoSample;

    # we have two groups of data each with 4 variables and 9 observations.
    my $data_x = [ 
                    [qw/ 292 222 52 57/],
                    [qw/ 100 227 51 45/],
                    [qw/ 272 218 49 36/],
                    [qw/ 101 221 17 47/],
                    [qw/ 181 208 12 35/],
                    [qw/ 111 118 51 54/],
                    [qw/ 288 321 51 49/],
                    [qw/ 286 219 52 45/],
                    [qw/ 262 225 47 44/],
                 ];
    my $data_y = [
                    [qw/ 286 107 29 62/],
                    [qw/ 311 122 29 63/],
                    [qw/ 272 131 52 86/],
                    [qw/ 182  88 23 69/],
                    [qw/ 211 118 61 57/],
                    [qw/ 323 127 51 79/],
                    [qw/ 385 332 70 63/],
                    [qw/ 373 127 85 60/],
                    [qw/ 408  95 57 71/],
                 ];
    
    # Create a Statistics::MVA::HotellingTwoSample object and pass the data as two Lists-of-Lists within an anonymous array.
    my $mva = Statistics::MVA::HotellingTwoSample->new([ $data_x, $data_y ]);

    # Generate results and print a report to STDOUT by calling hotelling_two_sample in void context.
    $mva->hotelling_two_sample;

    # Call hotelling_two_sample in LIST-context to access the results directly.
    my ($T2, $F, $pval, $df1, $df2) = $mva->hotelling_two_sample;

=cut

=head1 DESCRIPTION

Hotelling's T-square statistics is a generalisation of Student's t statistic that is used for multivariate hypothesis
testing. See http://en.wikipedia.org/wiki/Hotelling%27s_T-square_distribution.

=cut

use version; our $VERSION = qv('0.0.2');

sub hotelling_two_sample {

    my $self = shift;

    my $k = $self->[1];
    croak qq{\nThis is a two-sample test - you must give two samples} if $k != 2;  

    my $n_x = $self->[0][0][1];
    my $n_y = $self->[0][1][1];


    #y just variable number - again will need to check its equal for sample 2 - Statistics::MVA already checked p is same for all matrices...
    my $p = $self->[2];
    #print qq{\ntesting $n_x, $n_y and $p};

    #y Just averages of for each variable - naughty changed interface to MVA
    #my @bar_x = &_bar($self->[3][0]);
    #my @bar_y = &_bar($self->[3][1]);
    my @bar_x = &_bar($self->[0][0][2]);
    my @bar_y = &_bar($self->[0][1][2]);

    #y covariance matrices - this is already done!!! as part of MVA object creation
    my $V_x = $self->[0][0][0];
    my $V_y = $self->[0][1][0];
    
    my $V_x_adj = $V_x->shadow;
    my $V_y_adj = $V_y->shadow;
    my $V_p = $V_x->shadow; 

    $V_x_adj->multiply_scalar($V_x,$n_x-1);
    $V_y_adj->multiply_scalar($V_y,$n_y-1);
    $V_p->add($V_x_adj,$V_y_adj); 

    my $divisor = 1 / ($n_x + $n_y - 2);
    $V_p->multiply_scalar($V_p,$divisor);
    
    #y subtract means...
    my @bar_diff = map { $bar_x[$_] - $bar_y[$_] } (0..$#bar_x);

    my $bar_diff_mat = Math::MatrixReal->new_from_cols([[@bar_diff]]);

    my $dim;
    my $x;
    my $B_matreal;

    #/ using matrixreal - solve equation 'a %*% x = b' for 'x', - 'b' can be either a vector or a matrix.
    my $LR = $V_p->decompose_LR();
    if (!(($dim,$x,$B_matreal) = $LR->solve_LR($bar_diff_mat))) { croak qq{\nsystem has no solution} }
    #print qq{\n\nhere is the matrixreal solution\n}, $x;

    #/ using Cephes 
    #my $M = Math::Cephes::Matrix->new($V_p->[0]);
    #my $B = [@bar_diff];
    #my $solution = $M->simq($B);
    #print qq{\nhere is the cephes solution @{$solution}\n};
    
    my $crossprod = ~$bar_diff_mat * $x;
    my $df1 = $p;
    my $df2 = $n_x + $n_y-$p-1;
    my $other = $n_x + $n_y - 2;

    my $T2 = ($crossprod->[0][0][0] * $df2 * (($n_x * $n_y)/($n_x+$n_y)) * $other * $p) / (($n_x+$n_y-2) * $p * $df2);
    my $F = ( $df2 * $T2 ) /  ($other * $df1);
    my $pval = &fprob($df1,$df2,$F);
    $pval = $pval < 1e-8 ? q{< 1e-8} : $pval;
    
    if ( !wantarray ) { print qq{\nT^2 = $T2\nF = $F \ndf1 = $df1\ndf2 = $df2 \np.value = $pval}; }
    else { return ( $T2, $F, $pval, $df1, $df2 ) }
    return;
}

sub _bar {
    my $lol = shift;
    my $rows = scalar @{$lol};
    my $cols = scalar @{$lol->[0]};
    my @bar;
    for my $col (0..$cols-1) {
        my $sum = 0;
        for my $row (0..$rows-1) {
            $sum += $lol->[$row][$col];
        }
        push @bar, $sum/$rows;
    }
    $, = q{, };
    return @bar;
}

1; # Magic true value required at end of module

__END__

=head1 DEPENDENCIES

'Statistics::MVA' => '0.0.1',
'Carp' => '1.08',
'Statistics::Distributions' => '1.02',

=cut

=head1 BUGS AND LIMITATIONS

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

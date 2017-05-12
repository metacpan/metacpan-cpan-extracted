package Statistics::MVA::MultipleRegression;

use warnings;
use strict;
use Carp;
# re-implement with Cepehes?
use Statistics::MVA;
use Math::MatrixReal;
use List::Util qw/sum/;

require Exporter;  
our @ISA = qw(Exporter);
our @EXPORT = qw(linear_regression);

=head1 NAME

Statistics::MVA::MultipleRegression - Simple Least Squares Linear Multiple Regression Module.

=cut
=head1 VERSION

This document describes Statistics::MVA::MultipleRegression version 0.0.1

=cut
=head1 SYNOPSIS

    my $lol = [
        [qw/745  36  66/],
        [qw/895  37  68/],
        [qw/442  47  64/],
        [qw/440  32  53/],
        [qw/1598 1   101/],
     ];

    use Statistics::MVA::MultipleRegression;

    # Call exported routine on List-of-List of data (each nested list - row - corresponds to a set of observations. In void-context it prints a report to STDOUT.
    linear_regression($lol);

    # In LIST-context the routine returns an ARRAY reference of the coefficients and R^2.
    my ($Array_ref_of_coefficients, $R_sq) = linear_regression($d);

=cut
=head1 DESCRIPTION

    The general purpose of multiple regression is to gain information about the relationship between several independent
    variables (x_i) and a dependent variable (y). The procedure involves fitting an equation of the form:
    
        y = b_o + x_1 * b_1 + x_2 * b_2 +... ... x_n * b_n

    This is a minimal implementation of least squares procedure that accepts a List-of-Lists in which each nested list
    corresponds to a single set of observations. The single exported routine returns the coefficients (b_i) and R^2.

=cut

use version; our $VERSION = qv('0.0.1');


#/ at this moment this is a minimal version that just calculates the coefficients. i will expand it there is interest.

sub linear_regression {
    my $lol = shift;

    croak qq{\nAll data must be a matrix of numbers} if &Statistics::MVA::CVMat::_check($lol);

    $lol = &Statistics::MVA::CVMat::transpose($lol);

    croak qq{\nYou have no dependent variables - if you want to calculate the mean of Y do not use this module.} if (scalar @{$lol} == 1);
    carp qq{\nYou have one dependent variables - why use a multivariate procedure?} if (scalar @{$lol} == 2);

    my $y = [@{$lol->[0]}];
    my $n = scalar @{$y};
    my $y_mean = (sum @{$y}) / $n;
    my $x = [@{$lol}[1..$#{$lol}]];

    my $y_mat = Math::MatrixReal->new_from_cols([$lol->[0]]);

    #y can either build a vector of 1´s using x - i.e. 1 x scalar $lol1->[0] and combine it with everything after ->[0] 
    #y or can simply in place modify the whole of ->[0] in place now that it´s been copied to a matrix

    # in place modification
    for my $i (0..$#{$lol->[0]}) { $lol->[0][$i] = 1 }

    my $x_mat = Math::MatrixReal->new_from_cols($lol);
    my $b_mat = $y_mat->shadow;

    $b_mat =  (((~$x_mat * $x_mat)**-1) * ~$x_mat) * $y_mat ;

    # constant is $Bs[0] then coefficients are @Bs[1..$#Bs]
    my @Bs = map { $b_mat->[0][$_][0] } (0..$#{$b_mat->[0]});

    my $ss_y = sum map { ($_-$y_mean)**2 } @{$y}; 

    my @Bs_copy = @Bs;
    my $con = shift @Bs_copy;

    my $y_prime = [];

    #for my $r (0..$#{$x->[0]}) {
    for my $r (0..$#{$y}) {
        my $val = sum $con, map { $Bs_copy[$_] * $x->[$_][$r] } (0..$#Bs_copy);
        push @{$y_prime }, $val;
    }

    #my $ss_error = sum map { ($y->[$_]-$y_prime->[$_])**2 } (0..$#{$y});
    # can use ss_y_prime / ss_y or (ss_y - ss_error) / ss_y
    my $ss_y_prime = sum map { ($_-$y_mean)**2 } @{$y_prime}; 

    my $R2 = $ss_y_prime/$ss_y; 

    if (!wantarray) { 
        print qq{\nThe coefficients are: }; 
        for (0..$#Bs) { 
            my $punct = $_ == $#Bs ? q{.} : q{, };  
            print qq{B[$_] = $Bs[$_]$punct};
        }
        print qq{\nR^2 is $R2};
        return;
    }
    else { return ([@Bs], $R2); }
}

1; # Magic true value required at end of module
__END__

=head1 DEPENDENCIES

'Carp' => '1.08', 
'Statistics::MVA' => '0.0.1',
'List::Util' => '1.19',
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
=cut

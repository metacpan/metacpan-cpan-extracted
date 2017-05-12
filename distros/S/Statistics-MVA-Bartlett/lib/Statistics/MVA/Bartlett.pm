package Statistics::MVA::Bartlett;
use base Statistics::MVA;

use strict;
use warnings;
use Carp;
use Math::Cephes qw(:explog);
use Statistics::Distributions qw( chisqrdistr chisqrprob );

=head1 NAME

Statistics::MVA::Bartlett - Multivariate Test of Equality of Population Covariance Matrices.

=cut

=head1 VERSION

This document describes Statistics::MVA::Bartlett version 0.0.4

=cut

=head1 SYNOPSIS

    # we have several groups of data each with 3 variables
    my $data_X = [
        [qw/ 191 131 53/],
        [qw/ 200 137 52/],
        [qw/ 173 127 50/],
        [qw/ 160 118 47/],
        [qw/ 188 134 54/],
        [qw/ 186 129 51/],
        [qw/ 163 115 47/],
    ];

    my $data_Y = [
        [qw/ 211 122 49/],
        [qw/ 201 144 47/],
        [qw/ 242 131 54/],
        [qw/ 184 108 43/],
        [qw/ 223 127 51/],
        [qw/ 208 125 50/],
        [qw/ 199 124 46/],
    ];
    
    my $data_Z = [
        [qw/ 185 134 50/],
        [qw/ 171 128 49/],
        [qw/ 174 131 52/],
        [qw/ 186 107 49/],
        [qw/ 211 118 51/],
        [qw/ 217 122 49/],
    ];

    use Statistics::MVA::Bartlett;
 
    # Create a Statistics::MVA::Bartlett object and pass it the data as a series of Lists-of-Lists within an anonymous array. 
    my $bart1 = Statistics::MVA::Bartlett->new([$data_X, $data_Y, $data_Z]);

    # Access the output using the bartlett_mva method. In void context it prints a report to STDOUT.
    $bart->bartlett_mva;

    # In LIST-context it returns the relevant parameters.
    my ($chi, $df, $p) = $bart->bartlett_mva;

=cut

=head1 DESCRIPTION

Bartlett's test is used to test if k samples have equal variances. This multivariate form
tests for homogeneity of the variance-covariance matrices across samples. Some statistical tests assume such homogeneity
across groups or samples. This test allows you to check that assumption. See
http://www.itl.nist.gov/div898/handbook/eda/section3/eda357.htm.

=cut

use version; our $VERSION = qv('0.0.4');

sub bartlett_mva {
    my $self = shift;
    my $context = wantarray;
    my $s_ref = $self->[0];
    my $k = $self->[1];
    my $p = $self->[2];
    
    my $c_ref = &_Cs($s_ref, $k, $p);
    my $d_ref = &_dets($c_ref, $k);
    my $chi = &_final($d_ref, $k, $p);
    my $df = $p*($p+1)*($k-1)/2; 
    my $chisprob = &chisqrprob($df,$chi);

    if ( !$context ) { print qq{\nChi = $chi, df = $df and p = $chisprob}; return; }
    else { return ($chi, $df, $chisprob); }
}

sub _dets {
    my ($c_ref, $k) = @_;
    # d<-det(c) # d_a<-det(c_a) # d_b<-det(c_b)
    my $det_ref = [];
    for my $i (0..$k) {
        my $determinant = $c_ref->[$i][0]->det;
        $det_ref->[$i] = [$determinant, $c_ref->[$i][1]];
    }
    return $det_ref;
}

sub _final {
    my ($d_ref, $k, $p) = @_;
    my $d = ( ( $d_ref->[$k][1] - $k ) * ( log ( $d_ref->[$k][0] ) ) );
    my $d_sum = 0;
    for my $i (0..$k-1) { $d_sum += ( ( $d_ref->[$i][1] - 1 ) * ( log ( $d_ref->[$i][0] ) ) ); }
    my $m = $d - $d_sum;
    my $n_sum = 0;
    for my $i (0..$k-1) { $n_sum += 1 / ( $d_ref->[$i][1] - 1 ); } # print 1/($d_ref->[$i][1]-1) }
    my $h = 1 - ( ( 2 * $p* $p+3 * $p-1 ) / (6 * ($p+1) * ($k-1) ) * ( $n_sum - (1/($d_ref->[$k][1]-$k))) );
    my $chi = $m * $h;
    return $chi;
}

sub _Cs {
    my ( $s_ref, $k, $p ) = @_;
    my $c_ref = [];
    #/ matrices are initialised as zero! so we can just use addition... and not shadow or initialise a p*p structure of 0s
    my $c_total = Math::MatrixReal->new($p, $p);
    # $new_matrix = $some_matrix->shadow();
    my $n_total = 0;
    for my $i (0..$k-1) {
        my $c_mat = Math::MatrixReal->new($p, $p);
        my $factor = (1/($s_ref->[$i][1]-1));
        $c_mat->multiply_scalar($s_ref->[$i][0],$factor);
        $c_total->add($c_total,$s_ref->[$i][0]);
        $n_total += $s_ref->[$i][1];
        $c_ref->[$i] = [$c_mat, $s_ref->[$i][1]];
    }
    my $factor = (1/($n_total-$k));
    $c_total->multiply_scalar($c_total,$factor);
    $c_ref->[$k] = [$c_total,$n_total];
    return $c_ref;
}

sub _cv_matrices {
    my ( $groups, $k ) = @_;
    my @p;
    my $a_ref = [];
    #for my $i (0..$self->[1]-1) {
    for my $i (0..$k-1) {
        #my $mva = Statistics::MVA->new($groups->[$i],{standardise => 0, divisor => 1});
        my $mva = Statistics::MVA->new($groups->[$i]);
        my $mva_matrix = my $a = Math::MatrixReal->new_from_rows($mva->[0]);
        push @p, $mva->[1];
        $a_ref->[$i] = [ $mva_matrix, $mva->[2] ]; 
    }
    #/ should make sure than p for all entries is the same!!!
    my $p_check = shift @p;
    croak qq{\nAll groups must have the same variable number} if &_p_notall($p_check, \@p);
    #croak qq{\nAll groups must have the same variable number} if &_p_notall(@p);
    return ($a_ref, $p_check);
}

sub _p_notall {
    my ($p_check, $p_ref) = @_;
    #for (@p) {
    for (@{$p_ref}) {
        # return 0 if $_ != $p_check;
        return 1 if $_ != $p_check;
    } 
    return 0;
}

1; # Magic true value required at end of module

__END__

=head1 DEPENDENCIES

'Statistics::MVA' => '0.0.1',
'Carp' => '1.08',
'Math::Cephes' => '0.47',
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


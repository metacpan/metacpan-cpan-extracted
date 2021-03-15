package Photonic::ExtraUtils;

use strict;
use warnings;
use Carp;
use PDL::Complex;
require PDL::LinearAlgebra::Complex;
use Exporter;

our $VERSION = '0.015';
our @ISA = 'Exporter';
our @EXPORT = qw(cgtsv);

=encoding UTF-8

=head1 NAME

Photonic::ExtraUtils - Glue for utility Fortran routines

=head1 VERSION

version 0.015

=head1 COPYRIGHT NOTICE

Photonic - A perl package for calculations on photonics and
metamaterials.

Copyright (C) 2016 by W. Luis Mochán

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 1, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA  02110-1301 USA

    mochan@fis.unam.mx

    Instituto de Ciencias Físicas, UNAM
    Apartado Postal 48-3
    62251 Cuernavaca, Morelos
    México

=cut

=head1 SYNOPSIS

       use Photonic::ExtraUtils;
       ($b, my $info) = cgtsv($c, $d, $e, $b);

=head1 DESCRIPTION

Call some fortran routines from perl code.

=head2 cgtsv

=for ref

Solves a general complex tridiagonal system of equations.
Uses an LAPACK function, L<PDL::LinearAlgebra::Complex/cgtsv>.

       ($b, my $info) = cgtsv($c, $d, $e, $b);

where C<$c(2,0..$n-2)> is the subdiagonal, C<$d(2,0..$n-1)> the diagonal and
C<$e(2,0..$n-2)> the supradiagonal of an $nX$n tridiagonal complex
double precision matrix. C<$b(2,0..$n-1)> is the right hand side
vector. C<$b> is replaced by the solution. C<$info> returns 0 for success
or k if the k-1-th element of the diagonal became zero. Either 2Xn pdl's
are used to represent complex numbers, as in PDL::Complex.

B<NB> The LAPACK function, like its LINPACK equivalent, mutates its
inputs. This function is a wrapper that copies its inputs so they are
not mutated, and instead returns results.

=cut

sub cgtsv {
    confess "Wrong number of arguments" unless scalar(@_)==4;
    my ($c, $d, $e, $b) = @_;
    my $i = PDL->null;
    for (grep $_->is_inplace, $c, $d, $e, $b) {
        $_ = $_->copy;
        $_->set_inplace(0);
    }
    PDL::LinearAlgebra::Complex::cgtsv($c, $d, $e, $b, $i);
    ($b->isa("PDL::Complex") ? $b->complex : $b, $i);
}

1;

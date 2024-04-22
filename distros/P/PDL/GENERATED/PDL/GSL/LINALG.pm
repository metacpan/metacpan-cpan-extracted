#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::GSL::LINALG;

our @EXPORT_OK = qw(LU_decomp LU_solve LU_det solve_tridiag );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::GSL::LINALG ;







#line 4 "gsl_linalg.pd"

use strict;
use warnings;

=head1 NAME

PDL::GSL::LINALG - PDL interface to linear algebra routines in GSL

=head1 SYNOPSIS

  use PDL::LiteF;
  use PDL::MatrixOps; # for 'x'
  use PDL::GSL::LINALG;
  my $A = pdl [
    [0.18, 0.60, 0.57, 0.96],
    [0.41, 0.24, 0.99, 0.58],
    [0.14, 0.30, 0.97, 0.66],
    [0.51, 0.13, 0.19, 0.85],
  ];
  my $B = sequence(2,4); # column vectors
  LU_decomp(my $lu=$A->copy, my $p=null, my $signum=null);
  # transpose so first dim means is vector, higher dims broadcast
  LU_solve($lu, $p, $B->transpose, my $x=null);
  $x = $x->inplace->transpose; # now can be matrix-multiplied

=head1 DESCRIPTION

This is an interface to the linear algebra package present in the
GNU Scientific Library. Functions are named as in GSL, but with the
initial C<gsl_linalg_> removed. They are provided in both real and
complex double precision.

Currently only LU decomposition interfaces here. Pull requests welcome!
#line 60 "LINALG.pm"


=head1 FUNCTIONS

=cut






=head2 LU_decomp

=for sig

  Signature: ([io,phys]A(n,m); indx [o,phys]ipiv(p=CALC($PDL(A)->ndims > 1 ? PDLMIN($PDL(A)->dims[0], $PDL(A)->dims[1]) : 1)); int [o,phys]signum())

=for ref

LU decomposition of the given (real or complex) matrix.

=for bad

LU_decomp ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*LU_decomp = \&PDL::LU_decomp;






=head2 LU_solve

=for sig

  Signature: ([phys]LU(n,m); indx [phys]ipiv(p); [phys]B(n); [o,phys]x(n))

=for ref

Solve C<A x = B> using the LU and permutation from L</LU_decomp>, real
or complex.

=for bad

LU_solve ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*LU_solve = \&PDL::LU_solve;






=head2 LU_det

=for sig

  Signature: ([phys]LU(n,m); int [phys]signum(); [o]det())

=for ref

Find the determinant from the LU decomp.

=for bad

LU_det ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*LU_det = \&PDL::LU_det;






=head2 solve_tridiag

=for sig

  Signature: ([phys]diag(n); [phys]superdiag(n); [phys]subdiag(n); [phys]B(n); [o,phys]x(n))

=for ref

Solve C<A x = B> where A is a tridiagonal system. Real only, because
GSL does not have a complex function.

=for bad

solve_tridiag ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*solve_tridiag = \&PDL::solve_tridiag;







#line 40 "gsl_linalg.pd"

=head1 SEE ALSO

L<PDL>

The GSL documentation for linear algebra is online at
L<https://www.gnu.org/software/gsl/doc/html/linalg.html>

=cut
#line 193 "LINALG.pm"

# Exit with OK status

1;

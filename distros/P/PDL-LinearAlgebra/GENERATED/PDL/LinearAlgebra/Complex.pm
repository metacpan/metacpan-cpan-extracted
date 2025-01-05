#
# GENERATED WITH PDL::PP from lib/PDL/LinearAlgebra/Complex.pd! Don't modify!
#
package PDL::LinearAlgebra::Complex;

our @EXPORT_OK = qw(cgtsv cgesvd cgesdd cggsvd cgeev cgeevx cggev cggevx cgees cgeesx cgges cggesx cheev cheevd cheevx cheevr chegv chegvd chegvx cgesv cgesvx csysv csysvx chesv chesvx cposv cposvx cgels cgelsy cgelss cgelsd cgglse cggglm cgetrf cgetf2 csytrf csytf2 cchetrf chetf2 cpotrf cpotf2 cgetri csytri chetri cpotri ctrtri ctrti2 cgetrs csytrs chetrs cpotrs ctrtrs clatrs cgecon csycon checon cpocon ctrcon cgeqp3 cgeqrf cungqr cunmqr cgelqf cunglq cunmlq cgeqlf cungql cunmql cgerqf cungrq cunmrq ctzrzf cunmrz cgehrd cunghr chseqr ctrevc ctgevc cgebal clange clansy clantr cgemm cmmult ccrossprod csyrk cdot cdotc caxpy cnrm2 casum cscal csscal crotg clacpy claswp ccharpol );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   our $VERSION = '0.432';
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::LinearAlgebra::Complex $VERSION;







#line 85 "lib/PDL/LinearAlgebra/Complex.pd"

use strict;
use PDL::LinearAlgebra::Real;

=encoding utf8

=head1 NAME

PDL::LinearAlgebra::Complex - PDL interface to the lapack linear algebra programming library (complex number)

=head1 SYNOPSIS

 use PDL;
 use PDL::LinearAlgebra::Complex;
 $a = random(cdouble, 100, 100);
 $s = zeroes(cdouble, 100);
 $u = zeroes(cdouble, 100, 100);
 $v = zeroes(cdouble, 100, 100);
 $info = 0;
 $job = 0;
 cgesdd($a, $job, $info, $s , $u, $v);

=head1 DESCRIPTION

This module provides an interface to parts of the lapack library (complex numbers).
These routines accept either float or double ndarrays.

=cut
#line 55 "lib/PDL/LinearAlgebra/Complex.pm"


=head1 FUNCTIONS

=cut






=head2 cgtsv

=for sig

  Signature: (complex [io]DL(n);complex  [io]D(n);complex  [io]DU(n);complex  [io]B(n,nrhs); int [o]info())

=for ref

Solves the equation

	A * X = B

where A is an C<n> by C<n> tridiagonal matrix, by Gaussian elimination with
partial pivoting, and B is an C<n> by C<nrhs> matrix.

Note that the equation C<A**T*X = B>  may be solved by interchanging the
order of the arguments DU and DL.

B<NB> This differs from the LINPACK function C<cgtsl> in that C<DL>
starts from its first element, while the LINPACK equivalent starts from
its second element.

    Arguments
    =========

    DL:   On entry, DL must contain the (n-1) sub-diagonal elements of A.

          On exit, DL is overwritten by the (n-2) elements of the
          second super-diagonal of the upper triangular matrix U from
          the LU factorization of A, in DL(1), ..., DL(n-2).

    D:    On entry, D must contain the diagonal elements of A.

          On exit, D is overwritten by the n diagonal elements of U.

    DU:   On entry, DU must contain the (n-1) super-diagonal elements of A.

          On exit, DU is overwritten by the (n-1) elements of the
          first super-diagonal of the U.

    B:    On entry, the n by nrhs matrix of right hand side matrix B.
          On exit, if info = 0, the n by nrhs solution matrix X.

    info:   = 0:  successful exit
            < 0:  if info = -i, the i-th argument had an illegal value
            > 0:  if info = i, U(i,i) is exactly zero, and the solution
                  has not been computed.  The factorization has not been
                  completed unless i = n.

=for example

 $dl = random(float, 9) + random(float, 9) * i;
 $d = random(float, 10) + random(float, 10) * i;
 $du = random(float, 9) + random(float, 9) * i;
 $b = random(10,5) + random(10,5) * i;
 cgtsv($dl, $d, $du, $b, ($info=null));
 print "X is:\n$b" unless $info;

=for bad

cgtsv ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgtsv = \&PDL::cgtsv;






=head2 cgesvd

=for sig

  Signature: (complex [io]A(m,n); int jobu(); int jobvt(); [o]s(minmn=CALC(PDLMIN($SIZE(m),$SIZE(n))));complex  [o]U(p,p);complex  [o]VT(s,s); int [o]info(); [t]rwork(rworkn=CALC(5*$SIZE(minmn))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gesvd>.

The SVD is written

 A = U * SIGMA * ConjugateTranspose(V)

=for bad

cgesvd ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgesvd = \&PDL::cgesvd;






=head2 cgesdd

=for sig

  Signature: (complex [io]A(m,n); int jobz(); [o]s(minmn=CALC(PDLMIN($SIZE(m),$SIZE(n))));complex  [o]U(p,p);complex  [o]VT(s,s); int [o]info(); int [t]iwork(iworkn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gesdd>.

The SVD is written

 A = U * SIGMA * ConjugateTranspose(V)

=for bad

cgesdd ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgesdd = \&PDL::cgesdd;






=head2 cggsvd

=for sig

  Signature: (complex [io]A(m,n); int jobu(); int jobv(); int jobq();complex  [io]B(p,n); int [o]k(); int [o]l();[o]alpha(n);[o]beta(n);complex  [o]U(q,q);complex  [o]V(r,r);complex  [o]Q(s,s); int [o]iwork(n); int [o]info(); [t]rwork(rworkn=CALC(2*$SIZE(n))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ggsvd>

=for bad

cggsvd ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cggsvd = \&PDL::cggsvd;






=head2 cgeev

=for sig

  Signature: (complex [io]A(n,n); int jobvl(); int jobvr();complex  [o]w(n);complex  [o]vl(m,m);complex  [o]vr(p,p); int [o]info(); [t]rwork(rworkn=CALC(2*$SIZE(n))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/geev>

=for bad

cgeev ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgeev = \&PDL::cgeev;






=head2 cgeevx

=for sig

  Signature: (complex [io]A(n,n);  int jobvl(); int jobvr(); int balance(); int sense();complex  [o]w(n);complex  [o]vl(m,m);complex  [o]vr(p,p); int [o]ilo(); int [o]ihi(); [o]scale(n); [o]abnrm(); [o]rconde(q); [o]rcondv(r); int [o]info(); [t]rwork(rworkn=CALC(2*$SIZE(n))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/geevx>

=for bad

cgeevx ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgeevx = \&PDL::cgeevx;






=head2 cggev

=for sig

  Signature: (complex [io]A(n,n); int jobvl();int jobvr();complex [io]B(n,n);complex [o]alpha(n);complex [o]beta(n);complex [o]VL(m,m);complex [o]VR(p,p);int [o]info(); [t]rwork(rworkn=CALC(8*$SIZE(n))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ggev>

=for bad

cggev ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cggev = \&PDL::cggev;






=head2 cggevx

=for sig

  Signature: (complex [io]A(n,n);int balanc();int jobvl();int jobvr();int sense();complex [io]B(n,n);complex [o]alpha(n);complex [o]beta(n);complex [o]VL(m,m);complex [o]VR(p,p);int [o]ilo();int [o]ihi();[o]lscale(n);[o]rscale(n);[o]abnrm();[o]bbnrm();[o]rconde(r);[o]rcondv(s);int [o]info(); [t]rwork(rworkn=CALC(6*$SIZE(n))); int [t]bwork(bworkn); int [t]iwork(iworkn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ggevx>

=for bad

cggevx ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cggevx = \&PDL::cggevx;






=head2 cgees

=for sig

  Signature: (complex [io]A(n,n);  int jobvs(); int sort();complex  [o]w(n);complex  [o]vs(p,p); int [o]sdim(); int [o]info(); [t]rwork(n); int [t]bwork(bworkn); SV* select_func)

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gees>

    select_func:
            If sort = 1, select_func is used to select eigenvalues to sort
            to the top left of the Schur form.
            If sort = 0, select_func is not referenced.
            An complex eigenvalue w is selected if
            select_func(complex(w)) is true;
            Note that a selected complex eigenvalue may no longer
            satisfy select_func(complex(w)) = 1 after ordering, since
            ordering may change the value of complex eigenvalues
            (especially if the eigenvalue is ill-conditioned); in this
            case info is set to N+2.

=for bad

cgees ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgees = \&PDL::cgees;






=head2 cgeesx

=for sig

  Signature: (complex [io]A(n,n);  int jobvs(); int sort(); int sense();complex  [o]w(n);complex [o]vs(p,p); int [o]sdim(); [o]rconde();[o]rcondv(); int [o]info(); [t]rwork(n); int [t]bwork(bworkn); SV* select_func)

=for ref

Complex version of L<PDL::LinearAlgebra::Real/geesx>

    select_func:
            If sort = 1, select_func is used to select eigenvalues to sort
            to the top left of the Schur form.
            If sort = 0, select_func is not referenced.
            An complex eigenvalue w is selected if
            select_func(complex(w)) is true;
            Note that a selected complex eigenvalue may no longer
            satisfy select_func(complex(w)) = 1 after ordering, since
            ordering may change the value of complex eigenvalues
            (especially if the eigenvalue is ill-conditioned); in this
            case info is set to N+2.

=for bad

cgeesx ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgeesx = \&PDL::cgeesx;






=head2 cgges

=for sig

  Signature: (complex [io]A(n,n); int jobvsl();int jobvsr();int sort();complex [io]B(n,n);complex [o]alpha(n);complex [o]beta(n);complex [o]VSL(m,m);complex [o]VSR(p,p);int [o]sdim();int [o]info(); [t]rwork(rworkn=CALC(8*$SIZE(n))); int [t]bwork(bworkn); SV* select_func)

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ggees>

    select_func:
            If sort = 1, select_func is used to select eigenvalues to sort
            to the top left of the Schur form.
            If sort = 0, select_func is not referenced.
            An eigenvalue w = w/beta is selected if
            select_func(complex(w), complex(beta)) is true;
            Note that a selected complex eigenvalue may no longer
            satisfy select_func(complex(w),complex(beta)) = 1 after ordering, since
            ordering may change the value of complex eigenvalues
            (especially if the eigenvalue is ill-conditioned); in this
            case info is set to N+2.

=for bad

cgges ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgges = \&PDL::cgges;






=head2 cggesx

=for sig

  Signature: (complex [io]A(n,n); int jobvsl();int jobvsr();int sort();int sense();complex [io]B(n,n);complex [o]alpha(n);complex [o]beta(n);complex [o]VSL(m,m);complex [o]VSR(p,p);int [o]sdim();[o]rconde(q=2);[o]rcondv(q=2);int [o]info(); [t]rwork(rworkn=CALC(8*$SIZE(n))); int [t]bwork(bworkn); int [t]iwork(iworkn=CALC($SIZE(n)+2)); SV* select_func)

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ggeesx>

    select_func:
            If sort = 1, select_func is used to select eigenvalues to sort
            to the top left of the Schur form.
            If sort = 0, select_func is not referenced.
            An eigenvalue w = w/beta is selected if
            select_func(complex(w), complex(beta)) is true;
            Note that a selected complex eigenvalue may no longer
            satisfy select_func(complex(w),complex(beta)) = 1 after ordering, since
            ordering may change the value of complex eigenvalues
            (especially if the eigenvalue is ill-conditioned); in this
            case info is set to N+3.

=for bad

cggesx ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cggesx = \&PDL::cggesx;






=head2 cheev

=for sig

  Signature: (complex [io]A(n,n); int jobz(); int uplo(); [o]w(n); int [o]info(); [t]rwork(rworkn=CALC(3*($SIZE(n)-2))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/syev> for Hermitian matrix

=for bad

cheev ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cheev = \&PDL::cheev;






=head2 cheevd

=for sig

  Signature: (complex [io]A(n,n);  int jobz(); int uplo(); [o]w(n); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/syevd> for Hermitian matrix

=for bad

cheevd ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cheevd = \&PDL::cheevd;






=head2 cheevx

=for sig

  Signature: (complex [io]A(n,n);  int jobz(); int range(); int uplo(); vl(); vu(); int il(); int iu(); abstol(); int [o]m(); [o]w(n);complex  [o]z(p,p);int [o]ifail(n); int [o]info(); [t]rwork(rworkn=CALC(7*$SIZE(n))); int [t]iwork(iworkn=CALC(5*$SIZE(n))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/syevx> for Hermitian matrix

=for bad

cheevx ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cheevx = \&PDL::cheevx;






=head2 cheevr

=for sig

  Signature: (complex [io]A(n,n);  int jobz(); int range(); int uplo(); vl(); vu(); int il(); int iu(); abstol(); int [o]m(); [o]w(n);complex  [o]z(p,q);int [o]isuppz(r); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/syevr> for Hermitian matrix

=for bad

cheevr ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cheevr = \&PDL::cheevr;






=head2 chegv

=for sig

  Signature: (complex [io]A(n,n);int itype();int jobz(); int uplo();complex [io]B(n,n);[o]w(n); int [o]info(); [t]rwork(rworkn=CALC(3*($SIZE(n)-2))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sygv> for Hermitian matrix

=for bad

chegv ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*chegv = \&PDL::chegv;






=head2 chegvd

=for sig

  Signature: (complex [io]A(n,n);int itype();int jobz(); int uplo();complex [io]B(n,n);[o]w(n); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sygvd> for Hermitian matrix

=for bad

chegvd ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*chegvd = \&PDL::chegvd;






=head2 chegvx

=for sig

  Signature: (complex [io]A(n,n);int itype();int jobz();int range();
	  int uplo();complex [io]B(n,n);vl();vu();int il();
	  int iu();abstol();int [o]m();[o]w(n);complex 
	  [o]Z(p,p);int [o]ifail(n);int [o]info(); [t]rwork(rworkn=CALC(7*$SIZE(n))); int [t]iwork(iworkn=CALC(5*$SIZE(n)));
	)

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sygvx> for Hermitian matrix

=for bad

chegvx ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*chegvx = \&PDL::chegvx;






=head2 cgesv

=for sig

  Signature: (complex [io]A(n,n);complex   [io]B(n,m); int [o]ipiv(n); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gesv>

=for bad

cgesv ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgesv = \&PDL::cgesv;






=head2 cgesvx

=for sig

  Signature: (complex [io]A(n,n); int trans(); int fact();complex  [io]B(n,m);complex  [io]af(n,n); int [io]ipiv(n); int [io]equed(); [o]r(p); [o]c(q);complex  [o]X(n,m); [o]rcond(); [o]ferr(m); [o]berr(m); [o]rpvgrw(); int [o]info(); [t]rwork(rworkn=CALC(4*$SIZE(n))); [t]work(rworkn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gesvx>.

    trans:  Specifies the form of the system of equations:
            = 0:  A * X = B     (No transpose)
            = 1:  A' * X = B  (Transpose)
            = 2:  A**H * X = B  (Conjugate transpose)

=for bad

cgesvx ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgesvx = \&PDL::cgesvx;






=head2 csysv

=for sig

  Signature: (complex [io]A(n,n);  int uplo();complex  [io]B(n,m); int [o]ipiv(n); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sysv>

=for bad

csysv ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*csysv = \&PDL::csysv;






=head2 csysvx

=for sig

  Signature: (complex A(n,n); int uplo(); int fact();complex  B(n,m);complex  [io]af(n,n); int [io]ipiv(n);complex  [o]X(n,m); [o]rcond(); [o]ferr(m); [o]berr(m); int [o]info(); [t]rwork(n))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sysvx>

=for bad

csysvx ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*csysvx = \&PDL::csysvx;






=head2 chesv

=for sig

  Signature: (complex [io]A(n,n);  int uplo();complex  [io]B(n,m); int [o]ipiv(n); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sysv> for Hermitian matrix

=for bad

chesv ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*chesv = \&PDL::chesv;






=head2 chesvx

=for sig

  Signature: (complex A(n,n); int uplo(); int fact();complex  B(n,m);complex  [io]af(n,n); int [io]ipiv(n);complex  [o]X(n,m); [o]rcond(); [o]ferr(m); [o]berr(m); int [o]info(); [t]rwork(n))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sysvx> for Hermitian matrix

=for bad

chesvx ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*chesvx = \&PDL::chesvx;






=head2 cposv

=for sig

  Signature: (complex [io]A(n,n);  int uplo();complex  [io]B(n,m); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/posv> for Hermitian positive definite matrix

=for bad

cposv ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cposv = \&PDL::cposv;






=head2 cposvx

=for sig

  Signature: (complex [io]A(n,n); int uplo(); int fact();complex  [io]B(n,m);complex  [io]af(n,n); int [io]equed(); [o]s(p);complex  [o]X(n,m); [o]rcond(); [o]ferr(m); [o]berr(m); int [o]info(); [t]rwork(rworkn=CALC(2*$SIZE(n))); [t]work(workn=CALC(4*$SIZE(n))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/posvx> for Hermitian positive definite matrix

=for bad

cposvx ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cposvx = \&PDL::cposvx;






=head2 cgels

=for sig

  Signature: (complex [io]A(m,n); int trans();complex  [io]B(p,q);int [o]info())

=for ref

Solves overdetermined or underdetermined complex linear systems
involving an M-by-N matrix A, or its conjugate-transpose.
Complex version of L<PDL::LinearAlgebra::Real/gels>.

    trans:  = 0: the linear system involves A;
            = 1: the linear system involves A**H.

=for bad

cgels ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgels = \&PDL::cgels;






=head2 cgelsy

=for sig

  Signature: (complex [io]A(m,n);complex  [io]B(p,q); rcond(); int [io]jpvt(n); int [o]rank();int [o]info(); [t]rwork(rworkn=CALC(2*$SIZE(n))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gelsy>

=for bad

cgelsy ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgelsy = \&PDL::cgelsy;






=head2 cgelss

=for sig

  Signature: (complex [io]A(m,n);complex  [io]B(p,q); rcond(); [o]s(r); int [o]rank();int [o]info(); [t]rwork(rworkn=CALC(5*PDLMIN($SIZE(m),$SIZE(n)))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gelss>

=for bad

cgelss ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgelss = \&PDL::cgelss;






=head2 cgelsd

=for sig

  Signature: (complex [io]A(m,n);complex  [io]B(p,q); rcond(); [o]s(minmn=CALC(PDLMAX(1,PDLMIN($SIZE(m),$SIZE(n))))); int [o]rank();int [o]info(); int [t]iwork(iworkn); [t]rwork(rworkn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gelsd>

=for bad

cgelsd ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgelsd = \&PDL::cgelsd;






=head2 cgglse

=for sig

  Signature: (complex [io]A(m,n);complex  [io]B(p,n);complex [io]c(m);complex [io]d(p);complex [o]x(n);int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gglse>

=for bad

cgglse ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgglse = \&PDL::cgglse;






=head2 cggglm

=for sig

  Signature: (complex [io]A(n,m);complex  [io]B(n,p);complex [io]d(n);complex [o]x(m);complex [o]y(p);int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ggglm>

=for bad

cggglm ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cggglm = \&PDL::cggglm;






=head2 cgetrf

=for sig

  Signature: (complex [io]A(m,n); int [o]ipiv(p=CALC(PDLMIN($SIZE(m),$SIZE(n)))); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/getrf>

=for bad

cgetrf ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgetrf = \&PDL::cgetrf;






=head2 cgetf2

=for sig

  Signature: (complex [io]A(m,n); int [o]ipiv(p=CALC(PDLMIN($SIZE(m),$SIZE(n)))); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/getf2>

=for bad

cgetf2 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgetf2 = \&PDL::cgetf2;






=head2 csytrf

=for sig

  Signature: (complex [io]A(n,n); int uplo(); int [o]ipiv(n); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytrf>

=for bad

csytrf ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*csytrf = \&PDL::csytrf;






=head2 csytf2

=for sig

  Signature: (complex [io]A(n,n); int uplo(); int [o]ipiv(n); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytf2>

=for bad

csytf2 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*csytf2 = \&PDL::csytf2;






=head2 cchetrf

=for sig

  Signature: (complex [io]A(n,n); int uplo(); int [o]ipiv(n); int [o]info(); [t]work(workn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytrf> for Hermitian matrix

=for bad

cchetrf ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cchetrf = \&PDL::cchetrf;






=head2 chetf2

=for sig

  Signature: (complex [io]A(n,n); int uplo(); int [o]ipiv(n); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytf2> for Hermitian matrix

=for bad

chetf2 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*chetf2 = \&PDL::chetf2;






=head2 cpotrf

=for sig

  Signature: (complex [io]A(n,n); int uplo(); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/potrf> for Hermitian positive definite matrix

=for bad

cpotrf ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cpotrf = \&PDL::cpotrf;






=head2 cpotf2

=for sig

  Signature: (complex [io]A(n,n); int uplo(); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/potf2> for Hermitian positive definite matrix

=for bad

cpotf2 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cpotf2 = \&PDL::cpotf2;






=head2 cgetri

=for sig

  Signature: (complex [io]A(n,n); int ipiv(n); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/getri>

=for bad

cgetri ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgetri = \&PDL::cgetri;






=head2 csytri

=for sig

  Signature: (complex [io]A(n,n); int uplo(); int ipiv(n); int [o]info(); [t]work(workn=CALC(2*$SIZE(n))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytri>

=for bad

csytri ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*csytri = \&PDL::csytri;






=head2 chetri

=for sig

  Signature: (complex [io]A(n,n); int uplo(); int ipiv(n); int [o]info(); [t]work(workn=CALC(2*$SIZE(n))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytri> for Hermitian matrix

=for bad

chetri ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*chetri = \&PDL::chetri;






=head2 cpotri

=for sig

  Signature: (complex [io]A(n,n); int uplo(); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/potri>

=for bad

cpotri ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cpotri = \&PDL::cpotri;






=head2 ctrtri

=for sig

  Signature: (complex [io]A(n,n); int uplo(); int diag(); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/trtri>

=for bad

ctrtri ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*ctrtri = \&PDL::ctrtri;






=head2 ctrti2

=for sig

  Signature: (complex [io]A(n,n); int uplo(); int diag(); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/trti2>

=for bad

ctrti2 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*ctrti2 = \&PDL::ctrti2;






=head2 cgetrs

=for sig

  Signature: (complex A(n,n); int trans();complex  [io]B(n,m); int ipiv(n); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/getrs>

    Arguments
    =========
	trans:   = 0:  No transpose;
		 = 1:  Transpose;
		 = 2:  Conjugate transpose;

=for bad

cgetrs ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgetrs = \&PDL::cgetrs;






=head2 csytrs

=for sig

  Signature: (complex A(n,n); int uplo();complex [io]B(n,m); int ipiv(n); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytrs>

=for bad

csytrs ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*csytrs = \&PDL::csytrs;






=head2 chetrs

=for sig

  Signature: (complex A(n,n); int uplo();complex [io]B(n,m); int ipiv(n); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytrs> for Hermitian matrix

=for bad

chetrs ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*chetrs = \&PDL::chetrs;






=head2 cpotrs

=for sig

  Signature: (complex A(n,n); int uplo();complex  [io]B(n,m); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/potrs> for Hermitian positive definite matrix

=for bad

cpotrs ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cpotrs = \&PDL::cpotrs;






=head2 ctrtrs

=for sig

  Signature: (complex A(n,n); int uplo(); int trans(); int diag();complex [io]B(n,m); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/trtrs>

    Arguments
    =========
	trans:   = 0:  No transpose;
		 = 1:  Transpose;
		 = 2:  Conjugate transpose;

=for bad

ctrtrs ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*ctrtrs = \&PDL::ctrtrs;






=head2 clatrs

=for sig

  Signature: (complex A(n,n); int uplo(); int trans(); int diag(); int normin();complex [io]x(n); [o]scale();[io]cnorm(n);int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/latrs>

    Arguments
    =========
	trans:   = 0:  No transpose;
		 = 1:  Transpose;
		 = 2:  Conjugate transpose;

=for bad

clatrs ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*clatrs = \&PDL::clatrs;






=head2 cgecon

=for sig

  Signature: (complex A(n,n); int norm(); anorm(); [o]rcond();int [o]info(); [t]rwork(rworkn=CALC(2*$SIZE(n))); [t]work(workn=CALC(4*$SIZE(n))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gecon>

=for bad

cgecon ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgecon = \&PDL::cgecon;






=head2 csycon

=for sig

  Signature: (complex A(n,n); int uplo(); int ipiv(n); anorm(); [o]rcond();int [o]info(); [t]work(workn=CALC(4*$SIZE(n))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sycon>

=for bad

csycon ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*csycon = \&PDL::csycon;






=head2 checon

=for sig

  Signature: (complex A(n,n); int uplo(); int ipiv(n); anorm(); [o]rcond();int [o]info(); [t]work(workn=CALC(4*$SIZE(n))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sycon> for Hermitian matrix

=for bad

checon ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*checon = \&PDL::checon;






=head2 cpocon

=for sig

  Signature: (complex A(n,n); int uplo(); anorm(); [o]rcond();int [o]info(); [t]work(workn=CALC(4*$SIZE(n))); [t]rwork(n))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/pocon> for Hermitian positive definite matrix

=for bad

cpocon ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cpocon = \&PDL::cpocon;






=head2 ctrcon

=for sig

  Signature: (complex A(n,n); int norm();int uplo();int diag(); [o]rcond();int [o]info(); [t]work(workn=CALC(4*$SIZE(n))); [t]rwork(n))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/trcon>

=for bad

ctrcon ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*ctrcon = \&PDL::ctrcon;






=head2 cgeqp3

=for sig

  Signature: (complex [io]A(m,n); int [io]jpvt(n);complex  [o]tau(k); int [o]info(); [t]rwork(rworkn=CALC(2*$SIZE(n))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/geqp3>

=for bad

cgeqp3 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgeqp3 = \&PDL::cgeqp3;






=head2 cgeqrf

=for sig

  Signature: (complex [io]A(m,n);complex  [o]tau(k); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/geqrf>

=for bad

cgeqrf ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgeqrf = \&PDL::cgeqrf;






=head2 cungqr

=for sig

  Signature: (complex [io]A(m,n);complex  tau(k); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/orgqr>

=for bad

cungqr ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cungqr = \&PDL::cungqr;






=head2 cunmqr

=for sig

  Signature: (complex A(p,k); int side(); int trans();complex  tau(k);complex  [io]C(m,n);int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ormqr>. Here trans = 1 means conjugate transpose.

=for bad

cunmqr ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cunmqr = \&PDL::cunmqr;






=head2 cgelqf

=for sig

  Signature: (complex [io]A(m,n);complex  [o]tau(k); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gelqf>

=for bad

cgelqf ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgelqf = \&PDL::cgelqf;






=head2 cunglq

=for sig

  Signature: (complex [io]A(m,n);complex  tau(k); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/orglq>

=for bad

cunglq ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cunglq = \&PDL::cunglq;






=head2 cunmlq

=for sig

  Signature: (complex A(k,p); int side(); int trans();complex  tau(k);complex  [io]C(m,n);int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ormlq>. Here trans = 1 means conjugate transpose.

=for bad

cunmlq ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cunmlq = \&PDL::cunmlq;






=head2 cgeqlf

=for sig

  Signature: (complex [io]A(m,n);complex  [o]tau(k); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/geqlf>

=for bad

cgeqlf ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgeqlf = \&PDL::cgeqlf;






=head2 cungql

=for sig

  Signature: (complex [io]A(m,n);complex  tau(k); int [o]info())

=for ref
Complex version of L<PDL::LinearAlgebra::Real/orgql>.

=for bad

cungql ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cungql = \&PDL::cungql;






=head2 cunmql

=for sig

  Signature: (complex A(p,k); int side(); int trans();complex  tau(k);complex  [io]C(m,n);int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ormql>. Here trans = 1 means conjugate transpose.

=for bad

cunmql ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cunmql = \&PDL::cunmql;






=head2 cgerqf

=for sig

  Signature: (complex [io]A(m,n);complex  [o]tau(k); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gerqf>

=for bad

cgerqf ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgerqf = \&PDL::cgerqf;






=head2 cungrq

=for sig

  Signature: (complex [io]A(m,n);complex  tau(k); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/orgrq>.

=for bad

cungrq ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cungrq = \&PDL::cungrq;






=head2 cunmrq

=for sig

  Signature: (complex A(k,p); int side(); int trans();complex  tau(k);complex  [io]C(m,n);int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ormrq>. Here trans = 1 means conjugate transpose.

=for bad

cunmrq ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cunmrq = \&PDL::cunmrq;






=head2 ctzrzf

=for sig

  Signature: (complex [io]A(m,n);complex  [o]tau(k); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/tzrzf>

=for bad

ctzrzf ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*ctzrzf = \&PDL::ctzrzf;






=head2 cunmrz

=for sig

  Signature: (complex A(k,p); int side(); int trans();complex  tau(k);complex  [io]C(m,n);int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ormrz>. Here trans = 1 means conjugate transpose.

=for bad

cunmrz ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cunmrz = \&PDL::cunmrz;






=head2 cgehrd

=for sig

  Signature: (complex [io]A(n,n); int ilo();int ihi();complex [o]tau(k); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gehrd>

=for bad

cgehrd ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgehrd = \&PDL::cgehrd;






=head2 cunghr

=for sig

  Signature: (complex [io]A(n,n); int ilo();int ihi();complex tau(k); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/orghr>

=for bad

cunghr ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cunghr = \&PDL::cunghr;






=head2 chseqr

=for sig

  Signature: (complex [io]H(n,n); int job();int compz();int ilo();int ihi();complex [o]w(n);complex  [o]Z(m,m); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/hseqr>

=for bad

chseqr ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*chseqr = \&PDL::chseqr;






=head2 ctrevc

=for sig

  Signature: (complex T(n,n); int side();int howmny();int select(q);complex [o]VL(m,m);complex  [o]VR(p,p);int [o]m(); int [o]info(); [t]work(workn=CALC(5*$SIZE(n))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/trevc>

=for bad

ctrevc ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*ctrevc = \&PDL::ctrevc;






=head2 ctgevc

=for sig

  Signature: (complex A(n,n); int side();int howmny();complex  B(n,n);int select(q);complex [o]VL(m,m);complex  [o]VR(p,p);int [o]m(); int [o]info(); [t]work(workn=CALC(6*$SIZE(n))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/tgevc>

=for bad

ctgevc ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*ctgevc = \&PDL::ctgevc;






=head2 cgebal

=for sig

  Signature: (complex [io]A(n,n); int job(); int [o]ilo();int [o]ihi();[o]scale(n); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gebal>

=for bad

cgebal ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgebal = \&PDL::cgebal;






=head2 clange

=for sig

  Signature: (complex A(n,m); int norm(); [o]b(); [t]work(workn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/lange>

=for bad

clange ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*clange = \&PDL::clange;






=head2 clansy

=for sig

  Signature: (complex A(n,n); int uplo(); int norm(); [o]b(); [t]work(workn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/lansy>

=for bad

clansy ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*clansy = \&PDL::clansy;






=head2 clantr

=for sig

  Signature: (complex A(m,n); int uplo(); int norm();int diag(); [o]b(); [t]work(workn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/lantr>

=for bad

clantr ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*clantr = \&PDL::clantr;






=head2 cgemm

=for sig

  Signature: (complex A(m,n); int transa(); int transb();complex  B(p,q);complex alpha();complex  beta();complex  [io]C(r,s))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gemm>.

    Arguments
    =========
	transa:  = 0:  No transpose;
		 = 1:  Transpose;
		 = 2:  Conjugate transpose;

	transb:  = 0:  No transpose;
		 = 1:  Transpose;
		 = 2:  Conjugate transpose;

=for bad

cgemm ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgemm = \&PDL::cgemm;






=head2 cmmult

=for sig

  Signature: (complex A(m,n);complex  B(p,m);complex  [o]C(p,n))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/mmult>

=for bad

cmmult ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cmmult = \&PDL::cmmult;






=head2 ccrossprod

=for sig

  Signature: (complex A(n,m);complex  B(p,m);complex  [o]C(p,n))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/crossprod>

=for bad

ccrossprod ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*ccrossprod = \&PDL::ccrossprod;






=head2 csyrk

=for sig

  Signature: (complex A(m,n); int uplo(); int trans();complex  alpha();complex  beta();complex  [io]C(p,p))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/syrk>

=for bad

csyrk ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*csyrk = \&PDL::csyrk;






=head2 cdot

=for sig

  Signature: (complex a(n);complex b(n);complex [o]c())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/dot>

=for bad

cdot ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cdot = \&PDL::cdot;






=head2 cdotc

=for sig

  Signature: (complex a(n);complex b(n);complex [o]c())

=for ref

Forms the dot product of two vectors, conjugating the first
vector.

=for bad

cdotc ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cdotc = \&PDL::cdotc;






=head2 caxpy

=for sig

  Signature: (complex a(n);complex  alpha();complex [io]b(n))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/axpy>

=for bad

caxpy ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*caxpy = \&PDL::caxpy;






=head2 cnrm2

=for sig

  Signature: (complex a(n);[o]b())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/nrm2>

=for bad

cnrm2 ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cnrm2 = \&PDL::cnrm2;






=head2 casum

=for sig

  Signature: (complex a(n);[o]b())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/asum>

=for bad

casum ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*casum = \&PDL::casum;






=head2 cscal

=for sig

  Signature: (complex [io]a(n);complex scale())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/scal>

=for bad

cscal ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cscal = \&PDL::cscal;






=head2 csscal

=for sig

  Signature: (complex [io]a(n);scale())

=for ref

Scales a complex vector by a real constant.

=for bad

csscal ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*csscal = \&PDL::csscal;






=head2 crotg

=for sig

  Signature: (complex [io]a();complex b();[o]c();complex  [o]s())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/rotg>

=for bad

crotg ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*crotg = \&PDL::crotg;






=head2 clacpy

=for sig

  Signature: (complex A(m,n); int uplo();complex  [o]B(p,n))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/lacpy>

=for bad

clacpy ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*clacpy = \&PDL::clacpy;






=head2 claswp

=for sig

  Signature: (complex [io]A(m,n); int k1(); int k2(); int ipiv(p))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/laswp>

=for bad

claswp ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*claswp = \&PDL::claswp;






=head2 ccharpol

=for sig

  Signature: (A(c=2,n,n);[o]Y(c=2,n,n);[o]out(c=2,p=CALC($SIZE(n)+1)); [t]rwork(rworkn=CALC(2*$SIZE(n)*$SIZE(n))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/charpol>

=for bad

ccharpol does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*ccharpol = \&PDL::ccharpol;







#line 4951 "lib/PDL/LinearAlgebra/Complex.pd"

=head1 AUTHOR

Copyright (C) Grégory Vanuxem 2005-2018.

This library is free software; you can redistribute it and/or modify
it under the terms of the Perl Artistic License as in the file Artistic_2
in this distribution.

=cut
#line 2844 "lib/PDL/LinearAlgebra/Complex.pm"

# Exit with OK status

1;

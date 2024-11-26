#
# GENERATED WITH PDL::PP from complex.pd! Don't modify!
#
package PDL::LinearAlgebra::Complex;

our @EXPORT_OK = qw(__Ncgtsv cgtsv __Ncgesvd cgesvd __Ncgesdd cgesdd __Ncggsvd cggsvd __Ncgeev cgeev __Ncgeevx cgeevx __Ncggev cggev __Ncggevx cggevx __Ncgees cgees __Ncgeesx cgeesx __Ncgges cgges __Ncggesx cggesx __Ncheev cheev __Ncheevd cheevd __Ncheevx cheevx __Ncheevr cheevr __Nchegv chegv __Nchegvd chegvd __Nchegvx chegvx __Ncgesv cgesv __Ncgesvx cgesvx __Ncsysv csysv __Ncsysvx csysvx __Nchesv chesv __Nchesvx chesvx __Ncposv cposv __Ncposvx cposvx __Ncgels cgels __Ncgelsy cgelsy __Ncgelss cgelss __Ncgelsd cgelsd __Ncgglse cgglse __Ncggglm cggglm __Ncgetrf cgetrf __Ncgetf2 cgetf2 __Ncsytrf csytrf __Ncsytf2 csytf2 __Ncchetrf cchetrf __Nchetf2 chetf2 __Ncpotrf cpotrf __Ncpotf2 cpotf2 __Ncgetri cgetri __Ncsytri csytri __Nchetri chetri __Ncpotri cpotri __Nctrtri ctrtri __Nctrti2 ctrti2 __Ncgetrs cgetrs __Ncsytrs csytrs __Nchetrs chetrs __Ncpotrs cpotrs __Nctrtrs ctrtrs __Nclatrs clatrs __Ncgecon cgecon __Ncsycon csycon __Nchecon checon __Ncpocon cpocon __Nctrcon ctrcon __Ncgeqp3 cgeqp3 __Ncgeqrf cgeqrf __Ncungqr cungqr __Ncunmqr cunmqr __Ncgelqf cgelqf __Ncunglq cunglq __Ncunmlq cunmlq __Ncgeqlf cgeqlf __Ncungql cungql __Ncunmql cunmql __Ncgerqf cgerqf __Ncungrq cungrq __Ncunmrq cunmrq __Nctzrzf ctzrzf __Ncunmrz cunmrz __Ncgehrd cgehrd __Ncunghr cunghr __Nchseqr chseqr __Nctrevc ctrevc __Nctgevc ctgevc __Ncgebal cgebal __Nclange clange __Nclansy clansy __Nclantr clantr __Ncgemm cgemm __Ncmmult cmmult __Nccrossprod ccrossprod __Ncsyrk csyrk __Ncdot cdot __Ncdotc cdotc __Ncaxpy caxpy __Ncnrm2 cnrm2 __Ncasum casum __Ncscal cscal __Ncsscal csscal __Ncrotg crotg __Nclacpy clacpy __Nclaswp claswp __Nccharpol ccharpol );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   our $VERSION = '0.14';
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::LinearAlgebra::Complex $VERSION;







#line 79 "complex.pd"

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
#line 55 "Complex.pm"

*__Ncgtsv = \&PDL::__Ncgtsv;





#line 22 "../pp_defc.pl"

=head2 cgtsv

=for sig

  Signature: (complex [phys]DL(n);complex  [phys]D(n);complex  [phys]DU(n);complex  [io,phys]B(n,nrhs); int [o,phys]info())

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

=cut

sub PDL::cgtsv {
  goto &PDL::__Ncgtsv;
}
*cgtsv = \&PDL::cgtsv;
#line 129 "Complex.pm"

*__Ncgesvd = \&PDL::__Ncgesvd;





#line 22 "../pp_defc.pl"

=head2 cgesvd

=for sig

  Signature: (complex [io]A(m,n); int jobu(); int jobvt(); [o]s(minmn=CALC(PDLMIN($SIZE(m),$SIZE(n))));complex  [o]U(p,p);complex  [o]VT(s,s); int [o]info(); [t]rwork(rworkn=CALC(5*$SIZE(minmn))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gesvd>.

The SVD is written

 A = U * SIGMA * ConjugateTranspose(V)

=cut

sub PDL::cgesvd {
  goto &PDL::__Ncgesvd;
}
*cgesvd = \&PDL::cgesvd;
#line 159 "Complex.pm"

*__Ncgesdd = \&PDL::__Ncgesdd;





#line 22 "../pp_defc.pl"

=head2 cgesdd

=for sig

  Signature: (complex [io]A(m,n); int jobz(); [o]s(minmn=CALC(PDLMIN($SIZE(m),$SIZE(n))));complex  [o]U(p,p);complex  [o]VT(s,s); int [o]info(); int [t]iwork(iworkn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gesdd>.

The SVD is written

 A = U * SIGMA * ConjugateTranspose(V)

=cut

sub PDL::cgesdd {
  goto &PDL::__Ncgesdd;
}
*cgesdd = \&PDL::cgesdd;
#line 189 "Complex.pm"

*__Ncggsvd = \&PDL::__Ncggsvd;





#line 22 "../pp_defc.pl"

=head2 cggsvd

=for sig

  Signature: (complex [io]A(m,n); int jobu(); int jobv(); int jobq();complex  [io]B(p,n); int [o]k(); int [o]l();[o]alpha(n);[o]beta(n);complex  [o]U(q,q);complex  [o]V(r,r);complex  [o]Q(s,s); int [o]iwork(n); int [o]info(); [t]rwork(rworkn=CALC(2*$SIZE(n))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ggsvd>

=cut

sub PDL::cggsvd {
  goto &PDL::__Ncggsvd;
}
*cggsvd = \&PDL::cggsvd;
#line 215 "Complex.pm"

*__Ncgeev = \&PDL::__Ncgeev;





#line 22 "../pp_defc.pl"

=head2 cgeev

=for sig

  Signature: (complex A(n,n); int jobvl(); int jobvr();complex  [o]w(n);complex  [o]vl(m,m);complex  [o]vr(p,p); int [o]info(); [t]rwork(rworkn=CALC(2*$SIZE(n))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/geev>

=cut

sub PDL::cgeev {
  goto &PDL::__Ncgeev;
}
*cgeev = \&PDL::cgeev;
#line 241 "Complex.pm"

*__Ncgeevx = \&PDL::__Ncgeevx;





#line 22 "../pp_defc.pl"

=head2 cgeevx

=for sig

  Signature: (complex [io]A(n,n);  int jobvl(); int jobvr(); int balance(); int sense();complex  [o]w(n);complex  [o]vl(m,m);complex  [o]vr(p,p); int [o]ilo(); int [o]ihi(); [o]scale(n); [o]abnrm(); [o]rconde(q); [o]rcondv(r); int [o]info(); [t]rwork(rworkn=CALC(2*$SIZE(n))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/geevx>

=cut

sub PDL::cgeevx {
  goto &PDL::__Ncgeevx;
}
*cgeevx = \&PDL::cgeevx;
#line 267 "Complex.pm"

*__Ncggev = \&PDL::__Ncggev;





#line 22 "../pp_defc.pl"

=head2 cggev

=for sig

  Signature: (complex A(n,n); int [phys]jobvl();int [phys]jobvr();complex B(n,n);complex [o]alpha(n);complex [o]beta(n);complex [o]VL(m,m);complex [o]VR(p,p);int [o]info(); [t]rwork(rworkn=CALC(8*$SIZE(n))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ggev>

=cut

sub PDL::cggev {
  goto &PDL::__Ncggev;
}
*cggev = \&PDL::cggev;
#line 293 "Complex.pm"

*__Ncggevx = \&PDL::__Ncggevx;





#line 22 "../pp_defc.pl"

=head2 cggevx

=for sig

  Signature: (complex [io,phys]A(n,n);int balanc();int jobvl();int jobvr();int sense();complex [io,phys]B(n,n);complex [o]alpha(n);complex [o]beta(n);complex [o]VL(m,m);complex [o]VR(p,p);int [o]ilo();int [o]ihi();[o]lscale(n);[o]rscale(n);[o]abnrm();[o]bbnrm();[o]rconde(r);[o]rcondv(s);int [o]info(); [t]rwork(rworkn=CALC(6*$SIZE(n))); int [t]bwork(bworkn); int [t]iwork(iworkn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ggevx>

=cut

sub PDL::cggevx {
  goto &PDL::__Ncggevx;
}
*cggevx = \&PDL::cggevx;
#line 319 "Complex.pm"

*__Ncgees = \&PDL::__Ncgees;





#line 22 "../pp_defc.pl"

=head2 cgees

=for sig

  Signature: (complex [io]A(n,n);  int jobvs(); int sort();complex  [o]w(n);complex  [o]vs(p,p); int [o]sdim(); int [o]info(); [t]rwork(n); int [t]bwork(bworkn);SV* select_func)

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

=cut

sub PDL::cgees {
  goto &PDL::__Ncgees;
}
*cgees = \&PDL::cgees;
#line 357 "Complex.pm"

*__Ncgeesx = \&PDL::__Ncgeesx;





#line 22 "../pp_defc.pl"

=head2 cgeesx

=for sig

  Signature: (complex [io]A(n,n);  int jobvs(); int sort(); int sense();complex  [o]w(n);complex [o]vs(p,p); int [o]sdim(); [o]rconde();[o]rcondv(); int [o]info(); [t]rwork(n); int [t]bwork(bworkn);SV* select_func)

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

=cut

sub PDL::cgeesx {
  goto &PDL::__Ncgeesx;
}
*cgeesx = \&PDL::cgeesx;
#line 395 "Complex.pm"

*__Ncgges = \&PDL::__Ncgges;





#line 22 "../pp_defc.pl"

=head2 cgges

=for sig

  Signature: (complex [io]A(n,n); int jobvsl();int jobvsr();int sort();complex [io]B(n,n);complex [o]alpha(n);complex [o]beta(n);complex [o]VSL(m,m);complex [o]VSR(p,p);int [o]sdim();int [o]info(); [t]rwork(rworkn=CALC(8*$SIZE(n))); int [t]bwork(bworkn);SV* select_func)

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

=cut

sub PDL::cgges {
  goto &PDL::__Ncgges;
}
*cgges = \&PDL::cgges;
#line 433 "Complex.pm"

*__Ncggesx = \&PDL::__Ncggesx;





#line 22 "../pp_defc.pl"

=head2 cggesx

=for sig

  Signature: (complex [io]A(n,n); int jobvsl();int jobvsr();int sort();int sense();complex [io]B(n,n);complex [o]alpha(n);complex [o]beta(n);complex [o]VSL(m,m);complex [o]VSR(p,p);int [o]sdim();[o]rconde(q=2);[o]rcondv(q=2);int [o]info(); [t]rwork(rworkn=CALC(8*$SIZE(n))); int [t]bwork(bworkn); int [t]iwork(iworkn=CALC($SIZE(n)+2));SV* select_func)

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

=cut

sub PDL::cggesx {
  goto &PDL::__Ncggesx;
}
*cggesx = \&PDL::cggesx;
#line 471 "Complex.pm"

*__Ncheev = \&PDL::__Ncheev;





#line 22 "../pp_defc.pl"

=head2 cheev

=for sig

  Signature: (complex [io]A(n,n); int jobz(); int uplo(); [o]w(n); int [o]info(); [t]rwork(rworkn=CALC(3*($SIZE(n)-2))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/syev> for Hermitian matrix

=cut

sub PDL::cheev {
  goto &PDL::__Ncheev;
}
*cheev = \&PDL::cheev;
#line 497 "Complex.pm"

*__Ncheevd = \&PDL::__Ncheevd;





#line 22 "../pp_defc.pl"

=head2 cheevd

=for sig

  Signature: (complex [io,phys]A(n,n);  int jobz(); int uplo(); [o,phys]w(n); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/syevd> for Hermitian matrix

=cut

sub PDL::cheevd {
  goto &PDL::__Ncheevd;
}
*cheevd = \&PDL::cheevd;
#line 523 "Complex.pm"

*__Ncheevx = \&PDL::__Ncheevx;





#line 22 "../pp_defc.pl"

=head2 cheevx

=for sig

  Signature: (complex A(n,n);  int jobz(); int range(); int uplo(); vl(); vu(); int il(); int iu(); abstol(); int [o]m(); [o]w(n);complex  [o]z(p,p);int [o]ifail(n); int [o]info(); [t]rwork(rworkn=CALC(7*$SIZE(n))); int [t]iwork(iworkn=CALC(5*$SIZE(n))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/syevx> for Hermitian matrix

=cut

sub PDL::cheevx {
  goto &PDL::__Ncheevx;
}
*cheevx = \&PDL::cheevx;
#line 549 "Complex.pm"

*__Ncheevr = \&PDL::__Ncheevr;





#line 22 "../pp_defc.pl"

=head2 cheevr

=for sig

  Signature: (complex [phys]A(n,n);  int jobz(); int range(); int uplo(); [phys]vl(); [phys]vu(); int [phys]il(); int [phys]iu(); [phys]abstol(); int [o,phys]m(); [o,phys]w(n);complex  [o,phys]z(p,q);int [o,phys]isuppz(r); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/syevr> for Hermitian matrix

=cut

sub PDL::cheevr {
  goto &PDL::__Ncheevr;
}
*cheevr = \&PDL::cheevr;
#line 575 "Complex.pm"

*__Nchegv = \&PDL::__Nchegv;





#line 22 "../pp_defc.pl"

=head2 chegv

=for sig

  Signature: (complex [io]A(n,n);int itype();int jobz(); int uplo();complex [io]B(n,n);[o]w(n); int [o]info(); [t]rwork(rworkn=CALC(3*($SIZE(n)-2))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sygv> for Hermitian matrix

=cut

sub PDL::chegv {
  goto &PDL::__Nchegv;
}
*chegv = \&PDL::chegv;
#line 601 "Complex.pm"

*__Nchegvd = \&PDL::__Nchegvd;





#line 22 "../pp_defc.pl"

=head2 chegvd

=for sig

  Signature: (complex [io,phys]A(n,n);int [phys]itype();int jobz(); int uplo();complex [io,phys]B(n,n);[o,phys]w(n); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sygvd> for Hermitian matrix

=cut

sub PDL::chegvd {
  goto &PDL::__Nchegvd;
}
*chegvd = \&PDL::chegvd;
#line 627 "Complex.pm"

*__Nchegvx = \&PDL::__Nchegvx;





#line 22 "../pp_defc.pl"

=head2 chegvx

=for sig

  Signature: (complex [io]A(n,n);int itype();int jobz();int range();
	  int uplo();complex [io]B(n,n);vl();vu();int il();
	  int iu();abstol();int [o]m();[o]w(n);complex 
	  [o]Z(p,p);int [o]ifail(n);int [o]info(); [t]rwork(rworkn=CALC(7*$SIZE(n))); int [t]iwork(iworkn=CALC(5*$SIZE(n)));
	)

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sygvx> for Hermitian matrix

=cut

sub PDL::chegvx {
  goto &PDL::__Nchegvx;
}
*chegvx = \&PDL::chegvx;
#line 657 "Complex.pm"

*__Ncgesv = \&PDL::__Ncgesv;





#line 22 "../pp_defc.pl"

=head2 cgesv

=for sig

  Signature: (complex [io,phys]A(n,n);complex   [io,phys]B(n,m); int [o,phys]ipiv(n); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gesv>

=cut

sub PDL::cgesv {
  goto &PDL::__Ncgesv;
}
*cgesv = \&PDL::cgesv;
#line 683 "Complex.pm"

*__Ncgesvx = \&PDL::__Ncgesvx;





#line 22 "../pp_defc.pl"

=head2 cgesvx

=for sig

  Signature: (complex [io]A(n,n); int trans(); int fact();complex  [io]B(n,m);complex  [io]af(n,n); int [io]ipiv(n); int [io]equed(); [o]r(p); [o]c(q);complex  [o]X(n,m); [o]rcond(); [o]ferr(m); [o]berr(m); [o]rpvgrw(); int [o]info(); [t]rwork(rworkn=CALC(4*$SIZE(n))); [t]work(rworkn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gesvx>.

    trans:  Specifies the form of the system of equations:
            = 0:  A * X = B     (No transpose)
            = 1:  A' * X = B  (Transpose)
            = 2:  A**H * X = B  (Conjugate transpose)

=cut

sub PDL::cgesvx {
  goto &PDL::__Ncgesvx;
}
*cgesvx = \&PDL::cgesvx;
#line 714 "Complex.pm"

*__Ncsysv = \&PDL::__Ncsysv;





#line 22 "../pp_defc.pl"

=head2 csysv

=for sig

  Signature: (complex [io,phys]A(n,n);  int uplo();complex  [io,phys]B(n,m); int [o]ipiv(n); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sysv>

=cut

sub PDL::csysv {
  goto &PDL::__Ncsysv;
}
*csysv = \&PDL::csysv;
#line 740 "Complex.pm"

*__Ncsysvx = \&PDL::__Ncsysvx;





#line 22 "../pp_defc.pl"

=head2 csysvx

=for sig

  Signature: (complex [phys]A(n,n); int uplo(); int fact();complex  [phys]B(n,m);complex  [io,phys]af(n,n); int [io,phys]ipiv(n);complex  [o]X(n,m); [o]rcond(); [o]ferr(m); [o]berr(m); int [o]info(); [t]rwork(n))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sysvx>

=cut

sub PDL::csysvx {
  goto &PDL::__Ncsysvx;
}
*csysvx = \&PDL::csysvx;
#line 766 "Complex.pm"

*__Nchesv = \&PDL::__Nchesv;





#line 22 "../pp_defc.pl"

=head2 chesv

=for sig

  Signature: (complex [io,phys]A(n,n);  int uplo();complex  [io,phys]B(n,m); int [o,phys]ipiv(n); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sysv> for Hermitian matrix

=cut

sub PDL::chesv {
  goto &PDL::__Nchesv;
}
*chesv = \&PDL::chesv;
#line 792 "Complex.pm"

*__Nchesvx = \&PDL::__Nchesvx;





#line 22 "../pp_defc.pl"

=head2 chesvx

=for sig

  Signature: (complex A(n,n); int uplo(); int fact();complex  B(n,m);complex  [io]af(n,n); int [io]ipiv(n);complex  [o]X(n,m); [o]rcond(); [o]ferr(m); [o]berr(m); int [o]info(); [t]rwork(n))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sysvx> for Hermitian matrix

=cut

sub PDL::chesvx {
  goto &PDL::__Nchesvx;
}
*chesvx = \&PDL::chesvx;
#line 818 "Complex.pm"

*__Ncposv = \&PDL::__Ncposv;





#line 22 "../pp_defc.pl"

=head2 cposv

=for sig

  Signature: (complex [io,phys]A(n,n);  int uplo();complex  [io,phys]B(n,m); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/posv> for Hermitian positive definite matrix

=cut

sub PDL::cposv {
  goto &PDL::__Ncposv;
}
*cposv = \&PDL::cposv;
#line 844 "Complex.pm"

*__Ncposvx = \&PDL::__Ncposvx;





#line 22 "../pp_defc.pl"

=head2 cposvx

=for sig

  Signature: (complex [io]A(n,n); int uplo(); int fact();complex  [io]B(n,m);complex  [io]af(n,n); int [io]equed(); [o]s(p);complex  [o]X(n,m); [o]rcond(); [o]ferr(m); [o]berr(m); int [o]info(); [t]rwork(rworkn=CALC(2*$SIZE(n))); [t]work(workn=CALC(4*$SIZE(n))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/posvx> for Hermitian positive definite matrix

=cut

sub PDL::cposvx {
  goto &PDL::__Ncposvx;
}
*cposvx = \&PDL::cposvx;
#line 870 "Complex.pm"

*__Ncgels = \&PDL::__Ncgels;





#line 22 "../pp_defc.pl"

=head2 cgels

=for sig

  Signature: (complex [io,phys]A(m,n); int trans();complex  [io,phys]B(p,q);int [o,phys]info())

=for ref

Solves overdetermined or underdetermined complex linear systems
involving an M-by-N matrix A, or its conjugate-transpose.
Complex version of L<PDL::LinearAlgebra::Real/gels>.

    trans:  = 0: the linear system involves A;
            = 1: the linear system involves A**H.

=cut

sub PDL::cgels {
  goto &PDL::__Ncgels;
}
*cgels = \&PDL::cgels;
#line 901 "Complex.pm"

*__Ncgelsy = \&PDL::__Ncgelsy;





#line 22 "../pp_defc.pl"

=head2 cgelsy

=for sig

  Signature: (complex [io]A(m,n);complex  [io]B(p,q); rcond(); int [io]jpvt(n); int [o]rank();int [o]info(); [t]rwork(rworkn=CALC(2*$SIZE(n))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gelsy>

=cut

sub PDL::cgelsy {
  goto &PDL::__Ncgelsy;
}
*cgelsy = \&PDL::cgelsy;
#line 927 "Complex.pm"

*__Ncgelss = \&PDL::__Ncgelss;





#line 22 "../pp_defc.pl"

=head2 cgelss

=for sig

  Signature: (complex [io]A(m,n);complex  [io]B(p,q); rcond(); [o]s(r); int [o]rank();int [o]info(); [t]rwork(rworkn=CALC(5*PDLMIN($SIZE(m),$SIZE(n)))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gelss>

=cut

sub PDL::cgelss {
  goto &PDL::__Ncgelss;
}
*cgelss = \&PDL::cgelss;
#line 953 "Complex.pm"

*__Ncgelsd = \&PDL::__Ncgelsd;





#line 22 "../pp_defc.pl"

=head2 cgelsd

=for sig

  Signature: (complex [io]A(m,n);complex  [io]B(p,q); rcond(); [o]s(minmn=CALC(PDLMAX(1,PDLMIN($SIZE(m),$SIZE(n))))); int [o]rank();int [o]info(); int [t]iwork(iworkn); [t]rwork(rworkn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gelsd>

=cut

sub PDL::cgelsd {
  goto &PDL::__Ncgelsd;
}
*cgelsd = \&PDL::cgelsd;
#line 979 "Complex.pm"

*__Ncgglse = \&PDL::__Ncgglse;





#line 22 "../pp_defc.pl"

=head2 cgglse

=for sig

  Signature: (complex [phys]A(m,n);complex  [phys]B(p,n);complex [io,phys]c(m);complex [phys]d(p);complex [o,phys]x(n);int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gglse>

=cut

sub PDL::cgglse {
  goto &PDL::__Ncgglse;
}
*cgglse = \&PDL::cgglse;
#line 1005 "Complex.pm"

*__Ncggglm = \&PDL::__Ncggglm;





#line 22 "../pp_defc.pl"

=head2 cggglm

=for sig

  Signature: (complex [phys]A(n,m);complex  [phys]B(n,p);complex [phys]d(n);complex [o,phys]x(m);complex [o,phys]y(p);int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ggglm>

=cut

sub PDL::cggglm {
  goto &PDL::__Ncggglm;
}
*cggglm = \&PDL::cggglm;
#line 1031 "Complex.pm"

*__Ncgetrf = \&PDL::__Ncgetrf;





#line 22 "../pp_defc.pl"

=head2 cgetrf

=for sig

  Signature: (complex [io]A(m,n); int [o]ipiv(p=CALC(PDLMIN($SIZE(m),$SIZE(n)))); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/getrf>

=cut

sub PDL::cgetrf {
  goto &PDL::__Ncgetrf;
}
*cgetrf = \&PDL::cgetrf;
#line 1057 "Complex.pm"

*__Ncgetf2 = \&PDL::__Ncgetf2;





#line 22 "../pp_defc.pl"

=head2 cgetf2

=for sig

  Signature: (complex [io]A(m,n); int [o]ipiv(p=CALC(PDLMIN($SIZE(m),$SIZE(n)))); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/getf2>

=cut

sub PDL::cgetf2 {
  goto &PDL::__Ncgetf2;
}
*cgetf2 = \&PDL::cgetf2;
#line 1083 "Complex.pm"

*__Ncsytrf = \&PDL::__Ncsytrf;





#line 22 "../pp_defc.pl"

=head2 csytrf

=for sig

  Signature: (complex [io,phys]A(n,n); int uplo(); int [o,phys]ipiv(n); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytrf>

=cut

sub PDL::csytrf {
  goto &PDL::__Ncsytrf;
}
*csytrf = \&PDL::csytrf;
#line 1109 "Complex.pm"

*__Ncsytf2 = \&PDL::__Ncsytf2;





#line 22 "../pp_defc.pl"

=head2 csytf2

=for sig

  Signature: (complex [io,phys]A(n,n); int uplo(); int [o,phys]ipiv(n); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytf2>

=cut

sub PDL::csytf2 {
  goto &PDL::__Ncsytf2;
}
*csytf2 = \&PDL::csytf2;
#line 1135 "Complex.pm"

*__Ncchetrf = \&PDL::__Ncchetrf;





#line 22 "../pp_defc.pl"

=head2 cchetrf

=for sig

  Signature: (complex [io]A(n,n); int uplo(); int [o]ipiv(n); int [o]info(); [t]work(workn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytrf> for Hermitian matrix

=cut

sub PDL::cchetrf {
  goto &PDL::__Ncchetrf;
}
*cchetrf = \&PDL::cchetrf;
#line 1161 "Complex.pm"

*__Nchetf2 = \&PDL::__Nchetf2;





#line 22 "../pp_defc.pl"

=head2 chetf2

=for sig

  Signature: (complex [io]A(n,n); int uplo(); int [o]ipiv(n); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytf2> for Hermitian matrix

=cut

sub PDL::chetf2 {
  goto &PDL::__Nchetf2;
}
*chetf2 = \&PDL::chetf2;
#line 1187 "Complex.pm"

*__Ncpotrf = \&PDL::__Ncpotrf;





#line 22 "../pp_defc.pl"

=head2 cpotrf

=for sig

  Signature: (complex [io,phys]A(n,n); int uplo(); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/potrf> for Hermitian positive definite matrix

=cut

sub PDL::cpotrf {
  goto &PDL::__Ncpotrf;
}
*cpotrf = \&PDL::cpotrf;
#line 1213 "Complex.pm"

*__Ncpotf2 = \&PDL::__Ncpotf2;





#line 22 "../pp_defc.pl"

=head2 cpotf2

=for sig

  Signature: (complex [io,phys]A(n,n); int uplo(); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/potf2> for Hermitian positive definite matrix

=cut

sub PDL::cpotf2 {
  goto &PDL::__Ncpotf2;
}
*cpotf2 = \&PDL::cpotf2;
#line 1239 "Complex.pm"

*__Ncgetri = \&PDL::__Ncgetri;





#line 22 "../pp_defc.pl"

=head2 cgetri

=for sig

  Signature: (complex [io,phys]A(n,n); int [phys]ipiv(n); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/getri>

=cut

sub PDL::cgetri {
  goto &PDL::__Ncgetri;
}
*cgetri = \&PDL::cgetri;
#line 1265 "Complex.pm"

*__Ncsytri = \&PDL::__Ncsytri;





#line 22 "../pp_defc.pl"

=head2 csytri

=for sig

  Signature: (complex [io]A(n,n); int uplo(); int ipiv(n); int [o]info(); [t]work(workn=CALC(2*$SIZE(n))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytri>

=cut

sub PDL::csytri {
  goto &PDL::__Ncsytri;
}
*csytri = \&PDL::csytri;
#line 1291 "Complex.pm"

*__Nchetri = \&PDL::__Nchetri;





#line 22 "../pp_defc.pl"

=head2 chetri

=for sig

  Signature: (complex [io]A(n,n); int uplo(); int ipiv(n); int [o]info(); [t]work(workn=CALC(2*$SIZE(n))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytri> for Hermitian matrix

=cut

sub PDL::chetri {
  goto &PDL::__Nchetri;
}
*chetri = \&PDL::chetri;
#line 1317 "Complex.pm"

*__Ncpotri = \&PDL::__Ncpotri;





#line 22 "../pp_defc.pl"

=head2 cpotri

=for sig

  Signature: (complex [io,phys]A(n,n); int uplo(); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/potri>

=cut

sub PDL::cpotri {
  goto &PDL::__Ncpotri;
}
*cpotri = \&PDL::cpotri;
#line 1343 "Complex.pm"

*__Nctrtri = \&PDL::__Nctrtri;





#line 22 "../pp_defc.pl"

=head2 ctrtri

=for sig

  Signature: (complex [io,phys]A(n,n); int uplo(); int diag(); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/trtri>

=cut

sub PDL::ctrtri {
  goto &PDL::__Nctrtri;
}
*ctrtri = \&PDL::ctrtri;
#line 1369 "Complex.pm"

*__Nctrti2 = \&PDL::__Nctrti2;





#line 22 "../pp_defc.pl"

=head2 ctrti2

=for sig

  Signature: (complex [io,phys]A(n,n); int uplo(); int diag(); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/trti2>

=cut

sub PDL::ctrti2 {
  goto &PDL::__Nctrti2;
}
*ctrti2 = \&PDL::ctrti2;
#line 1395 "Complex.pm"

*__Ncgetrs = \&PDL::__Ncgetrs;





#line 22 "../pp_defc.pl"

=head2 cgetrs

=for sig

  Signature: (complex [phys]A(n,n); int trans();complex  [io,phys]B(n,m); int [phys]ipiv(n); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/getrs>

    Arguments
    =========
	trans:   = 0:  No transpose;
		 = 1:  Transpose;
		 = 2:  Conjugate transpose;

=cut

sub PDL::cgetrs {
  goto &PDL::__Ncgetrs;
}
*cgetrs = \&PDL::cgetrs;
#line 1427 "Complex.pm"

*__Ncsytrs = \&PDL::__Ncsytrs;





#line 22 "../pp_defc.pl"

=head2 csytrs

=for sig

  Signature: (complex [phys]A(n,n); int uplo();complex [io,phys]B(n,m); int [phys]ipiv(n); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytrs>

=cut

sub PDL::csytrs {
  goto &PDL::__Ncsytrs;
}
*csytrs = \&PDL::csytrs;
#line 1453 "Complex.pm"

*__Nchetrs = \&PDL::__Nchetrs;





#line 22 "../pp_defc.pl"

=head2 chetrs

=for sig

  Signature: (complex [phys]A(n,n); int uplo();complex [io,phys]B(n,m); int [phys]ipiv(n); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytrs> for Hermitian matrix

=cut

sub PDL::chetrs {
  goto &PDL::__Nchetrs;
}
*chetrs = \&PDL::chetrs;
#line 1479 "Complex.pm"

*__Ncpotrs = \&PDL::__Ncpotrs;





#line 22 "../pp_defc.pl"

=head2 cpotrs

=for sig

  Signature: (complex [phys]A(n,n); int uplo();complex  [io,phys]B(n,m); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/potrs> for Hermitian positive definite matrix

=cut

sub PDL::cpotrs {
  goto &PDL::__Ncpotrs;
}
*cpotrs = \&PDL::cpotrs;
#line 1505 "Complex.pm"

*__Nctrtrs = \&PDL::__Nctrtrs;





#line 22 "../pp_defc.pl"

=head2 ctrtrs

=for sig

  Signature: (complex [phys]A(n,n); int uplo(); int trans(); int diag();complex [io,phys]B(n,m); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/trtrs>

    Arguments
    =========
	trans:   = 0:  No transpose;
		 = 1:  Transpose;
		 = 2:  Conjugate transpose;

=cut

sub PDL::ctrtrs {
  goto &PDL::__Nctrtrs;
}
*ctrtrs = \&PDL::ctrtrs;
#line 1537 "Complex.pm"

*__Nclatrs = \&PDL::__Nclatrs;





#line 22 "../pp_defc.pl"

=head2 clatrs

=for sig

  Signature: (complex [phys]A(n,n); int uplo(); int trans(); int diag(); int normin();complex [io,phys]x(n); [o,phys]scale();[io,phys]cnorm(n);int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/latrs>

    Arguments
    =========
	trans:   = 0:  No transpose;
		 = 1:  Transpose;
		 = 2:  Conjugate transpose;

=cut

sub PDL::clatrs {
  goto &PDL::__Nclatrs;
}
*clatrs = \&PDL::clatrs;
#line 1569 "Complex.pm"

*__Ncgecon = \&PDL::__Ncgecon;





#line 22 "../pp_defc.pl"

=head2 cgecon

=for sig

  Signature: (complex A(n,n); int norm(); anorm(); [o]rcond();int [o]info(); [t]rwork(rworkn=CALC(2*$SIZE(n))); [t]work(workn=CALC(4*$SIZE(n))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gecon>

=cut

sub PDL::cgecon {
  goto &PDL::__Ncgecon;
}
*cgecon = \&PDL::cgecon;
#line 1595 "Complex.pm"

*__Ncsycon = \&PDL::__Ncsycon;





#line 22 "../pp_defc.pl"

=head2 csycon

=for sig

  Signature: (complex A(n,n); int uplo(); int ipiv(n); anorm(); [o]rcond();int [o]info(); [t]work(workn=CALC(4*$SIZE(n))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sycon>

=cut

sub PDL::csycon {
  goto &PDL::__Ncsycon;
}
*csycon = \&PDL::csycon;
#line 1621 "Complex.pm"

*__Nchecon = \&PDL::__Nchecon;





#line 22 "../pp_defc.pl"

=head2 checon

=for sig

  Signature: (complex A(n,n); int uplo(); int ipiv(n); anorm(); [o]rcond();int [o]info(); [t]work(workn=CALC(4*$SIZE(n))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sycon> for Hermitian matrix

=cut

sub PDL::checon {
  goto &PDL::__Nchecon;
}
*checon = \&PDL::checon;
#line 1647 "Complex.pm"

*__Ncpocon = \&PDL::__Ncpocon;





#line 22 "../pp_defc.pl"

=head2 cpocon

=for sig

  Signature: (complex A(n,n); int uplo(); anorm(); [o]rcond();int [o]info(); [t]work(workn=CALC(4*$SIZE(n))); [t]rwork(n))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/pocon> for Hermitian positive definite matrix

=cut

sub PDL::cpocon {
  goto &PDL::__Ncpocon;
}
*cpocon = \&PDL::cpocon;
#line 1673 "Complex.pm"

*__Nctrcon = \&PDL::__Nctrcon;





#line 22 "../pp_defc.pl"

=head2 ctrcon

=for sig

  Signature: (complex A(n,n); int norm();int uplo();int diag(); [o]rcond();int [o]info(); [t]work(workn=CALC(4*$SIZE(n))); [t]rwork(n))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/trcon>

=cut

sub PDL::ctrcon {
  goto &PDL::__Nctrcon;
}
*ctrcon = \&PDL::ctrcon;
#line 1699 "Complex.pm"

*__Ncgeqp3 = \&PDL::__Ncgeqp3;





#line 22 "../pp_defc.pl"

=head2 cgeqp3

=for sig

  Signature: (complex [io]A(m,n); int [io]jpvt(n);complex  [o]tau(k); int [o]info(); [t]rwork(rworkn=CALC(2*$SIZE(n))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/geqp3>

=cut

sub PDL::cgeqp3 {
  goto &PDL::__Ncgeqp3;
}
*cgeqp3 = \&PDL::cgeqp3;
#line 1725 "Complex.pm"

*__Ncgeqrf = \&PDL::__Ncgeqrf;





#line 22 "../pp_defc.pl"

=head2 cgeqrf

=for sig

  Signature: (complex [io,phys]A(m,n);complex  [o,phys]tau(k); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/geqrf>

=cut

sub PDL::cgeqrf {
  goto &PDL::__Ncgeqrf;
}
*cgeqrf = \&PDL::cgeqrf;
#line 1751 "Complex.pm"

*__Ncungqr = \&PDL::__Ncungqr;





#line 22 "../pp_defc.pl"

=head2 cungqr

=for sig

  Signature: (complex [io,phys]A(m,n);complex  [phys]tau(k); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/orgqr>

=cut

sub PDL::cungqr {
  goto &PDL::__Ncungqr;
}
*cungqr = \&PDL::cungqr;
#line 1777 "Complex.pm"

*__Ncunmqr = \&PDL::__Ncunmqr;





#line 22 "../pp_defc.pl"

=head2 cunmqr

=for sig

  Signature: (complex [phys]A(p,k); int side(); int trans();complex  [phys]tau(k);complex  [io,phys]C(m,n);int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ormqr>. Here trans = 1 means conjugate transpose.

=cut

sub PDL::cunmqr {
  goto &PDL::__Ncunmqr;
}
*cunmqr = \&PDL::cunmqr;
#line 1803 "Complex.pm"

*__Ncgelqf = \&PDL::__Ncgelqf;





#line 22 "../pp_defc.pl"

=head2 cgelqf

=for sig

  Signature: (complex [io,phys]A(m,n);complex  [o,phys]tau(k); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gelqf>

=cut

sub PDL::cgelqf {
  goto &PDL::__Ncgelqf;
}
*cgelqf = \&PDL::cgelqf;
#line 1829 "Complex.pm"

*__Ncunglq = \&PDL::__Ncunglq;





#line 22 "../pp_defc.pl"

=head2 cunglq

=for sig

  Signature: (complex [io,phys]A(m,n);complex  [phys]tau(k); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/orglq>

=cut

sub PDL::cunglq {
  goto &PDL::__Ncunglq;
}
*cunglq = \&PDL::cunglq;
#line 1855 "Complex.pm"

*__Ncunmlq = \&PDL::__Ncunmlq;





#line 22 "../pp_defc.pl"

=head2 cunmlq

=for sig

  Signature: (complex [phys]A(k,p); int side(); int trans();complex  [phys]tau(k);complex  [io,phys]C(m,n);int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ormlq>. Here trans = 1 means conjugate transpose.

=cut

sub PDL::cunmlq {
  goto &PDL::__Ncunmlq;
}
*cunmlq = \&PDL::cunmlq;
#line 1881 "Complex.pm"

*__Ncgeqlf = \&PDL::__Ncgeqlf;





#line 22 "../pp_defc.pl"

=head2 cgeqlf

=for sig

  Signature: (complex [io,phys]A(m,n);complex  [o,phys]tau(k); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/geqlf>

=cut

sub PDL::cgeqlf {
  goto &PDL::__Ncgeqlf;
}
*cgeqlf = \&PDL::cgeqlf;
#line 1907 "Complex.pm"

*__Ncungql = \&PDL::__Ncungql;





#line 22 "../pp_defc.pl"

=head2 cungql

=for sig

  Signature: (complex [io,phys]A(m,n);complex  [phys]tau(k); int [o,phys]info())

=for ref
Complex version of L<PDL::LinearAlgebra::Real/orgql>.

=cut

sub PDL::cungql {
  goto &PDL::__Ncungql;
}
*cungql = \&PDL::cungql;
#line 1932 "Complex.pm"

*__Ncunmql = \&PDL::__Ncunmql;





#line 22 "../pp_defc.pl"

=head2 cunmql

=for sig

  Signature: (complex [phys]A(p,k); int side(); int trans();complex  [phys]tau(k);complex  [io,phys]C(m,n);int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ormql>. Here trans = 1 means conjugate transpose.

=cut

sub PDL::cunmql {
  goto &PDL::__Ncunmql;
}
*cunmql = \&PDL::cunmql;
#line 1958 "Complex.pm"

*__Ncgerqf = \&PDL::__Ncgerqf;





#line 22 "../pp_defc.pl"

=head2 cgerqf

=for sig

  Signature: (complex [io,phys]A(m,n);complex  [o,phys]tau(k); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gerqf>

=cut

sub PDL::cgerqf {
  goto &PDL::__Ncgerqf;
}
*cgerqf = \&PDL::cgerqf;
#line 1984 "Complex.pm"

*__Ncungrq = \&PDL::__Ncungrq;





#line 22 "../pp_defc.pl"

=head2 cungrq

=for sig

  Signature: (complex [io,phys]A(m,n);complex  [phys]tau(k); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/orgrq>.

=cut

sub PDL::cungrq {
  goto &PDL::__Ncungrq;
}
*cungrq = \&PDL::cungrq;
#line 2010 "Complex.pm"

*__Ncunmrq = \&PDL::__Ncunmrq;





#line 22 "../pp_defc.pl"

=head2 cunmrq

=for sig

  Signature: (complex [phys]A(k,p); int side(); int trans();complex  [phys]tau(k);complex  [io,phys]C(m,n);int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ormrq>. Here trans = 1 means conjugate transpose.

=cut

sub PDL::cunmrq {
  goto &PDL::__Ncunmrq;
}
*cunmrq = \&PDL::cunmrq;
#line 2036 "Complex.pm"

*__Nctzrzf = \&PDL::__Nctzrzf;





#line 22 "../pp_defc.pl"

=head2 ctzrzf

=for sig

  Signature: (complex [io,phys]A(m,n);complex  [o,phys]tau(k); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/tzrzf>

=cut

sub PDL::ctzrzf {
  goto &PDL::__Nctzrzf;
}
*ctzrzf = \&PDL::ctzrzf;
#line 2062 "Complex.pm"

*__Ncunmrz = \&PDL::__Ncunmrz;





#line 22 "../pp_defc.pl"

=head2 cunmrz

=for sig

  Signature: (complex [phys]A(k,p); int side(); int trans();complex  [phys]tau(k);complex  [io,phys]C(m,n);int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ormrz>. Here trans = 1 means conjugate transpose.

=cut

sub PDL::cunmrz {
  goto &PDL::__Ncunmrz;
}
*cunmrz = \&PDL::cunmrz;
#line 2088 "Complex.pm"

*__Ncgehrd = \&PDL::__Ncgehrd;





#line 22 "../pp_defc.pl"

=head2 cgehrd

=for sig

  Signature: (complex [io,phys]A(n,n); int [phys]ilo();int [phys]ihi();complex [o,phys]tau(k); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gehrd>

=cut

sub PDL::cgehrd {
  goto &PDL::__Ncgehrd;
}
*cgehrd = \&PDL::cgehrd;
#line 2114 "Complex.pm"

*__Ncunghr = \&PDL::__Ncunghr;





#line 22 "../pp_defc.pl"

=head2 cunghr

=for sig

  Signature: (complex [io,phys]A(n,n); int [phys]ilo();int [phys]ihi();complex [phys]tau(k); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/orghr>

=cut

sub PDL::cunghr {
  goto &PDL::__Ncunghr;
}
*cunghr = \&PDL::cunghr;
#line 2140 "Complex.pm"

*__Nchseqr = \&PDL::__Nchseqr;





#line 22 "../pp_defc.pl"

=head2 chseqr

=for sig

  Signature: (complex [io,phys]H(n,n); int job();int compz();int [phys]ilo();int [phys]ihi();complex [o,phys]w(n);complex  [o,phys]Z(m,m); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/hseqr>

=cut

sub PDL::chseqr {
  goto &PDL::__Nchseqr;
}
*chseqr = \&PDL::chseqr;
#line 2166 "Complex.pm"

*__Nctrevc = \&PDL::__Nctrevc;





#line 22 "../pp_defc.pl"

=head2 ctrevc

=for sig

  Signature: (complex [io]T(n,n); int side();int howmny();int select(q);complex [o]VL(m,m);complex  [o]VR(p,p);int [o]m(); int [o]info(); [t]work(workn=CALC(5*$SIZE(n))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/trevc>

=cut

sub PDL::ctrevc {
  goto &PDL::__Nctrevc;
}
*ctrevc = \&PDL::ctrevc;
#line 2192 "Complex.pm"

*__Nctgevc = \&PDL::__Nctgevc;





#line 22 "../pp_defc.pl"

=head2 ctgevc

=for sig

  Signature: (complex [io]A(n,n); int side();int howmny();complex  [io]B(n,n);int select(q);complex [o]VL(m,m);complex  [o]VR(p,p);int [o]m(); int [o]info(); [t]work(workn=CALC(6*$SIZE(n))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/tgevc>

=cut

sub PDL::ctgevc {
  goto &PDL::__Nctgevc;
}
*ctgevc = \&PDL::ctgevc;
#line 2218 "Complex.pm"

*__Ncgebal = \&PDL::__Ncgebal;





#line 22 "../pp_defc.pl"

=head2 cgebal

=for sig

  Signature: (complex [io,phys]A(n,n); int job(); int [o,phys]ilo();int [o,phys]ihi();[o,phys]scale(n); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gebal>

=cut

sub PDL::cgebal {
  goto &PDL::__Ncgebal;
}
*cgebal = \&PDL::cgebal;
#line 2244 "Complex.pm"

*__Nclange = \&PDL::__Nclange;





#line 22 "../pp_defc.pl"

=head2 clange

=for sig

  Signature: (complex A(n,m); int norm(); [o]b(); [t]work(workn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/lange>

=cut

sub PDL::clange {
  goto &PDL::__Nclange;
}
*clange = \&PDL::clange;
#line 2270 "Complex.pm"

*__Nclansy = \&PDL::__Nclansy;





#line 22 "../pp_defc.pl"

=head2 clansy

=for sig

  Signature: (complex A(n,n); int uplo(); int norm(); [o]b(); [t]work(workn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/lansy>

=cut

sub PDL::clansy {
  goto &PDL::__Nclansy;
}
*clansy = \&PDL::clansy;
#line 2296 "Complex.pm"

*__Nclantr = \&PDL::__Nclantr;





#line 22 "../pp_defc.pl"

=head2 clantr

=for sig

  Signature: (complex A(m,n); int uplo(); int norm();int diag(); [o]b(); [t]work(workn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/lantr>

=cut

sub PDL::clantr {
  goto &PDL::__Nclantr;
}
*clantr = \&PDL::clantr;
#line 2322 "Complex.pm"

*__Ncgemm = \&PDL::__Ncgemm;





#line 22 "../pp_defc.pl"

=head2 cgemm

=for sig

  Signature: (complex [phys]A(m,n); int transa(); int transb();complex  [phys]B(p,q);complex [phys]alpha();complex  [phys]beta();complex  [io,phys]C(r,s))

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

=cut

sub PDL::cgemm {
  goto &PDL::__Ncgemm;
}
*cgemm = \&PDL::cgemm;
#line 2358 "Complex.pm"

*__Ncmmult = \&PDL::__Ncmmult;





#line 22 "../pp_defc.pl"

=head2 cmmult

=for sig

  Signature: (complex [phys]A(m,n);complex  [phys]B(p,m);complex  [o,phys]C(p,n))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/mmult>

=cut

sub PDL::cmmult {
  goto &PDL::__Ncmmult;
}
*cmmult = \&PDL::cmmult;
#line 2384 "Complex.pm"

*__Nccrossprod = \&PDL::__Nccrossprod;





#line 22 "../pp_defc.pl"

=head2 ccrossprod

=for sig

  Signature: (complex [phys]A(n,m);complex  [phys]B(p,m);complex  [o,phys]C(p,n))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/crossprod>

=cut

sub PDL::ccrossprod {
  goto &PDL::__Nccrossprod;
}
*ccrossprod = \&PDL::ccrossprod;
#line 2410 "Complex.pm"

*__Ncsyrk = \&PDL::__Ncsyrk;





#line 22 "../pp_defc.pl"

=head2 csyrk

=for sig

  Signature: (complex [phys]A(m,n); int uplo(); int trans();complex  [phys]alpha();complex  [phys]beta();complex  [io,phys]C(p,p))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/syrk>

=cut

sub PDL::csyrk {
  goto &PDL::__Ncsyrk;
}
*csyrk = \&PDL::csyrk;
#line 2436 "Complex.pm"

*__Ncdot = \&PDL::__Ncdot;





#line 22 "../pp_defc.pl"

=head2 cdot

=for sig

  Signature: (complex [phys]a(n);complex [phys]b(n);complex [o]c())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/dot>

=cut

sub PDL::cdot {
  goto &PDL::__Ncdot;
}
*cdot = \&PDL::cdot;
#line 2462 "Complex.pm"

*__Ncdotc = \&PDL::__Ncdotc;





#line 22 "../pp_defc.pl"

=head2 cdotc

=for sig

  Signature: (complex [phys]a(n);complex [phys]b(n);complex [o,phys]c())

=for ref

Forms the dot product of two vectors, conjugating the first
vector.

=cut

sub PDL::cdotc {
  goto &PDL::__Ncdotc;
}
*cdotc = \&PDL::cdotc;
#line 2489 "Complex.pm"

*__Ncaxpy = \&PDL::__Ncaxpy;





#line 22 "../pp_defc.pl"

=head2 caxpy

=for sig

  Signature: (complex [phys]a(n);complex [phys] alpha();complex [io,phys]b(n))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/axpy>

=cut

sub PDL::caxpy {
  goto &PDL::__Ncaxpy;
}
*caxpy = \&PDL::caxpy;
#line 2515 "Complex.pm"

*__Ncnrm2 = \&PDL::__Ncnrm2;





#line 22 "../pp_defc.pl"

=head2 cnrm2

=for sig

  Signature: (complex [phys]a(n);[o]b())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/nrm2>

=cut

sub PDL::cnrm2 {
  goto &PDL::__Ncnrm2;
}
*cnrm2 = \&PDL::cnrm2;
#line 2541 "Complex.pm"

*__Ncasum = \&PDL::__Ncasum;





#line 22 "../pp_defc.pl"

=head2 casum

=for sig

  Signature: (complex [phys]a(n);[o]b())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/asum>

=cut

sub PDL::casum {
  goto &PDL::__Ncasum;
}
*casum = \&PDL::casum;
#line 2567 "Complex.pm"

*__Ncscal = \&PDL::__Ncscal;





#line 22 "../pp_defc.pl"

=head2 cscal

=for sig

  Signature: (complex [io,phys]a(n);complex scale())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/scal>

=cut

sub PDL::cscal {
  goto &PDL::__Ncscal;
}
*cscal = \&PDL::cscal;
#line 2593 "Complex.pm"

*__Ncsscal = \&PDL::__Ncsscal;





#line 22 "../pp_defc.pl"

=head2 csscal

=for sig

  Signature: (complex [io,phys]a(n);scale())

=for ref

Scales a complex vector by a real constant.

=cut

sub PDL::csscal {
  goto &PDL::__Ncsscal;
}
*csscal = \&PDL::csscal;
#line 2619 "Complex.pm"

*__Ncrotg = \&PDL::__Ncrotg;





#line 22 "../pp_defc.pl"

=head2 crotg

=for sig

  Signature: (complex [io,phys]a();complex [phys]b();[o,phys]c();complex  [o,phys]s())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/rotg>

=cut

sub PDL::crotg {
  goto &PDL::__Ncrotg;
}
*crotg = \&PDL::crotg;
#line 2645 "Complex.pm"

*__Nclacpy = \&PDL::__Nclacpy;





#line 22 "../pp_defc.pl"

=head2 clacpy

=for sig

  Signature: (complex [phys]A(m,n); int uplo();complex  [o,phys]B(p,n))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/lacpy>

=cut

sub PDL::clacpy {
  goto &PDL::__Nclacpy;
}
*clacpy = \&PDL::clacpy;
#line 2671 "Complex.pm"

*__Nclaswp = \&PDL::__Nclaswp;





#line 22 "../pp_defc.pl"

=head2 claswp

=for sig

  Signature: (complex [io,phys]A(m,n); int [phys]k1(); int [phys]k2(); int [phys]ipiv(p))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/laswp>

=cut

sub PDL::claswp {
  goto &PDL::__Nclaswp;
}
*claswp = \&PDL::claswp;
#line 2697 "Complex.pm"

*__Nccharpol = \&PDL::__Nccharpol;





#line 22 "../pp_defc.pl"

=head2 ccharpol

=for sig

  Signature: (A(c=2,n,n);[o]Y(c=2,n,n);[o]out(c=2,p=CALC($SIZE(n)+1)); [t]rwork(rworkn=CALC(2*$SIZE(n)*$SIZE(n))))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/charpol>

=cut

sub PDL::ccharpol {
  goto &PDL::__Nccharpol;
}
*ccharpol = \&PDL::ccharpol;

#line 4945 "complex.pd"

=head1 AUTHOR

Copyright (C) Grégory Vanuxem 2005-2018.

This library is free software; you can redistribute it and/or modify
it under the terms of the Perl Artistic License as in the file Artistic_2
in this distribution.

=cut
#line 2735 "Complex.pm"

# Exit with OK status

1;

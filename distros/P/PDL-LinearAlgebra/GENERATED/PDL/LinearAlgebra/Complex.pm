#
# GENERATED WITH PDL::PP from lib/PDL/LinearAlgebra/Complex.pd! Don't modify!
#
package PDL::LinearAlgebra::Complex;

our @EXPORT_OK = qw(cgtsv cgesvd cgesdd cggsvd cgeev cgeevx cggev cggevx cgees cgeesx cgges cggesx cheev cheevd cheevx cheevr chegv chegvd chegvx cgesv cgesvx csysv csysvx chesv chesvx cposv cposvx cgels cgelsy cgelss cgelsd cgglse cggglm cgetrf cgetf2 csytrf csytf2 cchetrf chetf2 cpotrf cpotf2 cgetri csytri chetri cpotri ctrtri ctrti2 cgetrs csytrs chetrs cpotrs ctrtrs clatrs cgecon csycon checon cpocon ctrcon cgeqp3 cgeqrf cungqr cunmqr cgelqf cunglq cunmlq cgeqlf cungql cunmql cgerqf cungrq cunmrq ctzrzf cunmrz cgehrd cunghr chseqr ctrevc ctgevc cgebal clange clansy clantr cgemm cmmult ccrossprod csyrk cdot cdotc caxpy cnrm2 casum cscal csscal crotg clacpy claswp ccharpol );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   our $VERSION = '0.436';
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::LinearAlgebra::Complex $VERSION;








#line 73 "lib/PDL/LinearAlgebra/Complex.pd"

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
#line 56 "lib/PDL/LinearAlgebra/Complex.pm"


=head1 FUNCTIONS

=cut






=head2 cgtsv

=for sig

 Signature: (complex [io]DL(n);complex  [io]D(n);complex  [io]DU(n);complex  [io]B(n,nrhs); int [o]info())
 Types: (float double)

=for usage

 $info = cgtsv($DL, $D, $DU, $B);
 cgtsv($DL, $D, $DU, $B, $info);  # all arguments given
 $info = $DL->cgtsv($D, $DU, $B); # method call
 $DL->cgtsv($D, $DU, $B, $info);

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

=pod

Broadcasts over its inputs.

=for bad

C<cgtsv> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgtsv = \&PDL::cgtsv;






=head2 cgesvd

=for sig

 Signature: (complex [io]A(m,n); [o]s(minmn=CALC(PDLMIN($SIZE(m),$SIZE(n))));complex  [o]U(p,p);complex  [o]VT(s,s); int [o]info(); [t]rwork(rworkn=CALC(5*$SIZE(minmn))); int jobu; int jobvt)
 Types: (float double)

=for usage

 ($s, $U, $VT, $info) = cgesvd($A, $jobu, $jobvt);
 cgesvd($A, $jobu, $jobvt, $s, $U, $VT, $info);    # all arguments given
 ($s, $U, $VT, $info) = $A->cgesvd($jobu, $jobvt); # method call
 $A->cgesvd($jobu, $jobvt, $s, $U, $VT, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gesvd>.

The SVD is written

 A = U * SIGMA * ConjugateTranspose(V)

=pod

Broadcasts over its inputs.

=for bad

C<cgesvd> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgesvd = \&PDL::cgesvd;






=head2 cgesdd

=for sig

 Signature: (complex [io]A(m,n); [o]s(minmn=CALC(PDLMIN($SIZE(m),$SIZE(n))));complex  [o]U(p,p);complex  [o]VT(s,s); int [o]info(); int [t]iwork(iworkn); int jobz)
 Types: (float double)

=for usage

 ($s, $U, $VT, $info) = cgesdd($A, $jobz);
 cgesdd($A, $jobz, $s, $U, $VT, $info);    # all arguments given
 ($s, $U, $VT, $info) = $A->cgesdd($jobz); # method call
 $A->cgesdd($jobz, $s, $U, $VT, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gesdd>.

The SVD is written

 A = U * SIGMA * ConjugateTranspose(V)

=pod

Broadcasts over its inputs.

=for bad

C<cgesdd> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgesdd = \&PDL::cgesdd;






=head2 cggsvd

=for sig

 Signature: (complex [io]A(m,n);complex  [io]B(p,n); int [o]k(); int [o]l();[o]alpha(n);[o]beta(n);complex  [o]U(q,q);complex  [o]V(r,r);complex  [o]Q(s,s); int [o]iwork(n); int [o]info(); [t]rwork(rworkn=CALC(2*$SIZE(n))); int jobu; int jobv; int jobq)
 Types: (float double)

=for usage

 ($k, $l, $alpha, $beta, $U, $V, $Q, $iwork, $info) = cggsvd($A, $jobu, $jobv, $jobq, $B);
 cggsvd($A, $jobu, $jobv, $jobq, $B, $k, $l, $alpha, $beta, $U, $V, $Q, $iwork, $info);    # all arguments given
 ($k, $l, $alpha, $beta, $U, $V, $Q, $iwork, $info) = $A->cggsvd($jobu, $jobv, $jobq, $B); # method call
 $A->cggsvd($jobu, $jobv, $jobq, $B, $k, $l, $alpha, $beta, $U, $V, $Q, $iwork, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ggsvd>

=pod

Broadcasts over its inputs.

=for bad

C<cggsvd> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cggsvd = \&PDL::cggsvd;






=head2 cgeev

=for sig

 Signature: (complex [io]A(n,n);complex  [o]w(n);complex  [o]vl(m,m);complex  [o]vr(p,p); int [o]info(); [t]rwork(rworkn=CALC(2*$SIZE(n))); int jobvl; int jobvr)
 Types: (float double)

=for usage

 ($w, $vl, $vr, $info) = cgeev($A, $jobvl, $jobvr);
 cgeev($A, $jobvl, $jobvr, $w, $vl, $vr, $info);    # all arguments given
 ($w, $vl, $vr, $info) = $A->cgeev($jobvl, $jobvr); # method call
 $A->cgeev($jobvl, $jobvr, $w, $vl, $vr, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/geev>

=pod

Broadcasts over its inputs.

=for bad

C<cgeev> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgeev = \&PDL::cgeev;






=head2 cgeevx

=for sig

 Signature: (complex [io]A(n,n);complex  [o]w(n);complex  [o]vl(m,m);complex  [o]vr(p,p); int [o]ilo(); int [o]ihi(); [o]scale(n); [o]abnrm(); [o]rconde(q); [o]rcondv(r); int [o]info(); [t]rwork(rworkn=CALC(2*$SIZE(n))); int jobvl; int jobvr; int balance; int sense)
 Types: (float double)

=for usage

 ($w, $vl, $vr, $ilo, $ihi, $scale, $abnrm, $rconde, $rcondv, $info) = cgeevx($A, $jobvl, $jobvr, $balance, $sense);
 cgeevx($A, $jobvl, $jobvr, $balance, $sense, $w, $vl, $vr, $ilo, $ihi, $scale, $abnrm, $rconde, $rcondv, $info);    # all arguments given
 ($w, $vl, $vr, $ilo, $ihi, $scale, $abnrm, $rconde, $rcondv, $info) = $A->cgeevx($jobvl, $jobvr, $balance, $sense); # method call
 $A->cgeevx($jobvl, $jobvr, $balance, $sense, $w, $vl, $vr, $ilo, $ihi, $scale, $abnrm, $rconde, $rcondv, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/geevx>

=pod

Broadcasts over its inputs.

=for bad

C<cgeevx> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgeevx = \&PDL::cgeevx;






=head2 cggev

=for sig

 Signature: (complex [io]A(n,n);complex [io]B(n,n);complex [o]alpha(n);complex [o]beta(n);complex [o]VL(m,m);complex [o]VR(p,p);int [o]info(); [t]rwork(rworkn=CALC(8*$SIZE(n))); int jobvl; int jobvr)
 Types: (float double)

=for usage

 ($alpha, $beta, $VL, $VR, $info) = cggev($A, $jobvl, $jobvr, $B);
 cggev($A, $jobvl, $jobvr, $B, $alpha, $beta, $VL, $VR, $info);    # all arguments given
 ($alpha, $beta, $VL, $VR, $info) = $A->cggev($jobvl, $jobvr, $B); # method call
 $A->cggev($jobvl, $jobvr, $B, $alpha, $beta, $VL, $VR, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ggev>

=pod

Broadcasts over its inputs.

=for bad

C<cggev> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cggev = \&PDL::cggev;






=head2 cggevx

=for sig

 Signature: (complex [io]A(n,n);complex [io]B(n,n);complex [o]alpha(n);complex [o]beta(n);complex [o]VL(m,m);complex [o]VR(p,p);int [o]ilo();int [o]ihi();[o]lscale(n);[o]rscale(n);[o]abnrm();[o]bbnrm();[o]rconde(r);[o]rcondv(s);int [o]info(); [t]rwork(rworkn=CALC(6*$SIZE(n))); int [t]bwork(bworkn); int [t]iwork(iworkn); int balanc; int jobvl; int jobvr; int sense)
 Types: (float double)

=for usage

 ($alpha, $beta, $VL, $VR, $ilo, $ihi, $lscale, $rscale, $abnrm, $bbnrm, $rconde, $rcondv, $info) = cggevx($A, $balanc, $jobvl, $jobvr, $sense, $B);
 cggevx($A, $balanc, $jobvl, $jobvr, $sense, $B, $alpha, $beta, $VL, $VR, $ilo, $ihi, $lscale, $rscale, $abnrm, $bbnrm, $rconde, $rcondv, $info);    # all arguments given
 ($alpha, $beta, $VL, $VR, $ilo, $ihi, $lscale, $rscale, $abnrm, $bbnrm, $rconde, $rcondv, $info) = $A->cggevx($balanc, $jobvl, $jobvr, $sense, $B); # method call
 $A->cggevx($balanc, $jobvl, $jobvr, $sense, $B, $alpha, $beta, $VL, $VR, $ilo, $ihi, $lscale, $rscale, $abnrm, $bbnrm, $rconde, $rcondv, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ggevx>

=pod

Broadcasts over its inputs.

=for bad

C<cggevx> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cggevx = \&PDL::cggevx;






=head2 cgees

=for sig

 Signature: (complex [io]A(n,n);complex  [o]w(n);complex  [o]vs(p,p); int [o]sdim(); int [o]info(); [t]rwork(n); int [t]bwork(bworkn); int jobvs; int sort; SV* select_func)
 Types: (float double)

=for usage

 ($w, $vs, $sdim, $info) = cgees($A, $jobvs, $sort, $select_func);
 cgees($A, $jobvs, $sort, $select_func, $w, $vs, $sdim, $info);    # all arguments given
 ($w, $vs, $sdim, $info) = $A->cgees($jobvs, $sort, $select_func); # method call
 $A->cgees($jobvs, $sort, $select_func, $w, $vs, $sdim, $info);

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

=pod

Broadcasts over its inputs.

=for bad

C<cgees> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgees = \&PDL::cgees;






=head2 cgeesx

=for sig

 Signature: (complex [io]A(n,n);complex  [o]w(n);complex [o]vs(p,p); int [o]sdim(); [o]rconde();[o]rcondv(); int [o]info(); [t]rwork(n); int [t]bwork(bworkn); int jobvs; int sort; int sense; SV* select_func)
 Types: (float double)

=for usage

 ($w, $vs, $sdim, $rconde, $rcondv, $info) = cgeesx($A, $jobvs, $sort, $sense, $select_func);
 cgeesx($A, $jobvs, $sort, $sense, $select_func, $w, $vs, $sdim, $rconde, $rcondv, $info);    # all arguments given
 ($w, $vs, $sdim, $rconde, $rcondv, $info) = $A->cgeesx($jobvs, $sort, $sense, $select_func); # method call
 $A->cgeesx($jobvs, $sort, $sense, $select_func, $w, $vs, $sdim, $rconde, $rcondv, $info);

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

=pod

Broadcasts over its inputs.

=for bad

C<cgeesx> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgeesx = \&PDL::cgeesx;






=head2 cgges

=for sig

 Signature: (complex [io]A(n,n);complex [io]B(n,n);complex [o]alpha(n);complex [o]beta(n);complex [o]VSL(m,m);complex [o]VSR(p,p);int [o]sdim();int [o]info(); [t]rwork(rworkn=CALC(8*$SIZE(n))); int [t]bwork(bworkn); int jobvsl; int jobvsr; int sort; SV* select_func)
 Types: (float double)

=for usage

 ($alpha, $beta, $VSL, $VSR, $sdim, $info) = cgges($A, $jobvsl, $jobvsr, $sort, $B, $select_func);
 cgges($A, $jobvsl, $jobvsr, $sort, $B, $select_func, $alpha, $beta, $VSL, $VSR, $sdim, $info);    # all arguments given
 ($alpha, $beta, $VSL, $VSR, $sdim, $info) = $A->cgges($jobvsl, $jobvsr, $sort, $B, $select_func); # method call
 $A->cgges($jobvsl, $jobvsr, $sort, $B, $select_func, $alpha, $beta, $VSL, $VSR, $sdim, $info);

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

=pod

Broadcasts over its inputs.

=for bad

C<cgges> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgges = \&PDL::cgges;






=head2 cggesx

=for sig

 Signature: (complex [io]A(n,n);complex [io]B(n,n);complex [o]alpha(n);complex [o]beta(n);complex [o]VSL(m,m);complex [o]VSR(p,p);int [o]sdim();[o]rconde(q=2);[o]rcondv(q=2);int [o]info(); [t]rwork(rworkn=CALC(8*$SIZE(n))); int [t]bwork(bworkn); int [t]iwork(iworkn=CALC($SIZE(n)+2)); int jobvsl; int jobvsr; int sort; int sense; SV* select_func)
 Types: (float double)

=for usage

 ($alpha, $beta, $VSL, $VSR, $sdim, $rconde, $rcondv, $info) = cggesx($A, $jobvsl, $jobvsr, $sort, $sense, $B, $select_func);
 cggesx($A, $jobvsl, $jobvsr, $sort, $sense, $B, $select_func, $alpha, $beta, $VSL, $VSR, $sdim, $rconde, $rcondv, $info);    # all arguments given
 ($alpha, $beta, $VSL, $VSR, $sdim, $rconde, $rcondv, $info) = $A->cggesx($jobvsl, $jobvsr, $sort, $sense, $B, $select_func); # method call
 $A->cggesx($jobvsl, $jobvsr, $sort, $sense, $B, $select_func, $alpha, $beta, $VSL, $VSR, $sdim, $rconde, $rcondv, $info);

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

=pod

Broadcasts over its inputs.

=for bad

C<cggesx> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cggesx = \&PDL::cggesx;






=head2 cheev

=for sig

 Signature: (complex [io]A(n,n); int jobz(); int uplo(); [o]w(n); int [o]info(); [t]rwork(rworkn=CALC(3*($SIZE(n)-2))))
 Types: (float double)

=for usage

 ($w, $info) = cheev($A, $jobz, $uplo);
 cheev($A, $jobz, $uplo, $w, $info);    # all arguments given
 ($w, $info) = $A->cheev($jobz, $uplo); # method call
 $A->cheev($jobz, $uplo, $w, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/syev> for Hermitian matrix

=pod

Broadcasts over its inputs.

=for bad

C<cheev> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cheev = \&PDL::cheev;






=head2 cheevd

=for sig

 Signature: (complex [io]A(n,n);  int jobz(); int uplo(); [o]w(n); int [o]info())
 Types: (float double)

=for usage

 ($w, $info) = cheevd($A, $jobz, $uplo);
 cheevd($A, $jobz, $uplo, $w, $info);    # all arguments given
 ($w, $info) = $A->cheevd($jobz, $uplo); # method call
 $A->cheevd($jobz, $uplo, $w, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/syevd> for Hermitian matrix

=pod

Broadcasts over its inputs.

=for bad

C<cheevd> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cheevd = \&PDL::cheevd;






=head2 cheevx

=for sig

 Signature: (complex [io]A(n,n); vl(); vu(); int il(); int iu(); abstol(); int [o]m(); [o]w(n);complex  [o]z(p,p);int [o]ifail(n); int [o]info(); [t]rwork(rworkn=CALC(7*$SIZE(n))); int [t]iwork(iworkn=CALC(5*$SIZE(n))); int jobz; int range; int uplo)
 Types: (float double)

=for usage

 ($m, $w, $z, $ifail, $info) = cheevx($A, $jobz, $range, $uplo, $vl, $vu, $il, $iu, $abstol);
 cheevx($A, $jobz, $range, $uplo, $vl, $vu, $il, $iu, $abstol, $m, $w, $z, $ifail, $info);    # all arguments given
 ($m, $w, $z, $ifail, $info) = $A->cheevx($jobz, $range, $uplo, $vl, $vu, $il, $iu, $abstol); # method call
 $A->cheevx($jobz, $range, $uplo, $vl, $vu, $il, $iu, $abstol, $m, $w, $z, $ifail, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/syevx> for Hermitian matrix

=pod

Broadcasts over its inputs.

=for bad

C<cheevx> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cheevx = \&PDL::cheevx;






=head2 cheevr

=for sig

 Signature: (complex [io]A(n,n);  int jobz(); int range(); int uplo(); vl(); vu(); int il(); int iu(); abstol(); int [o]m(); [o]w(n);complex  [o]z(p,q);int [o]isuppz(r); int [o]info())
 Types: (float double)

=for usage

 ($m, $w, $z, $isuppz, $info) = cheevr($A, $jobz, $range, $uplo, $vl, $vu, $il, $iu, $abstol);
 cheevr($A, $jobz, $range, $uplo, $vl, $vu, $il, $iu, $abstol, $m, $w, $z, $isuppz, $info);    # all arguments given
 ($m, $w, $z, $isuppz, $info) = $A->cheevr($jobz, $range, $uplo, $vl, $vu, $il, $iu, $abstol); # method call
 $A->cheevr($jobz, $range, $uplo, $vl, $vu, $il, $iu, $abstol, $m, $w, $z, $isuppz, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/syevr> for Hermitian matrix

=pod

Broadcasts over its inputs.

=for bad

C<cheevr> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cheevr = \&PDL::cheevr;






=head2 chegv

=for sig

 Signature: (complex [io]A(n,n);int itype();int jobz(); int uplo();complex [io]B(n,n);[o]w(n); int [o]info(); [t]rwork(rworkn=CALC(3*($SIZE(n)-2))))
 Types: (float double)

=for usage

 ($w, $info) = chegv($A, $itype, $jobz, $uplo, $B);
 chegv($A, $itype, $jobz, $uplo, $B, $w, $info);    # all arguments given
 ($w, $info) = $A->chegv($itype, $jobz, $uplo, $B); # method call
 $A->chegv($itype, $jobz, $uplo, $B, $w, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sygv> for Hermitian matrix

=pod

Broadcasts over its inputs.

=for bad

C<chegv> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*chegv = \&PDL::chegv;






=head2 chegvd

=for sig

 Signature: (complex [io]A(n,n);int itype();int jobz(); int uplo();complex [io]B(n,n);[o]w(n); int [o]info())
 Types: (float double)

=for usage

 ($w, $info) = chegvd($A, $itype, $jobz, $uplo, $B);
 chegvd($A, $itype, $jobz, $uplo, $B, $w, $info);    # all arguments given
 ($w, $info) = $A->chegvd($itype, $jobz, $uplo, $B); # method call
 $A->chegvd($itype, $jobz, $uplo, $B, $w, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sygvd> for Hermitian matrix

=pod

Broadcasts over its inputs.

=for bad

C<chegvd> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*chegvd = \&PDL::chegvd;






=head2 chegvx

=for sig

 Signature: (complex [io]A(n,n);int itype();complex 
    [io]B(n,n);vl();vu();int il();
    int iu();abstol();int [o]m();[o]w(n);complex 
    [o]Z(p,p);int [o]ifail(n);int [o]info(); [t]rwork(rworkn=CALC(7*$SIZE(n))); int [t]iwork(iworkn=CALC(5*$SIZE(n)));
  ; int jobz; int range; int uplo)
 Types: (float double)

=for usage

 ($m, $w, $Z, $ifail, $info) = chegvx($A, $itype, $jobz, $range, $uplo, $B, $vl, $vu, $il, $iu, $abstol);
 chegvx($A, $itype, $jobz, $range, $uplo, $B, $vl, $vu, $il, $iu, $abstol, $m, $w, $Z, $ifail, $info);    # all arguments given
 ($m, $w, $Z, $ifail, $info) = $A->chegvx($itype, $jobz, $range, $uplo, $B, $vl, $vu, $il, $iu, $abstol); # method call
 $A->chegvx($itype, $jobz, $range, $uplo, $B, $vl, $vu, $il, $iu, $abstol, $m, $w, $Z, $ifail, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sygvx> for Hermitian matrix

=pod

Broadcasts over its inputs.

=for bad

C<chegvx> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*chegvx = \&PDL::chegvx;






=head2 cgesv

=for sig

 Signature: (complex [io]A(n,n);complex   [io]B(n,m); int [o]ipiv(n); int [o]info())
 Types: (float double)

=for usage

 ($ipiv, $info) = cgesv($A, $B);
 cgesv($A, $B, $ipiv, $info);    # all arguments given
 ($ipiv, $info) = $A->cgesv($B); # method call
 $A->cgesv($B, $ipiv, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gesv>

=pod

Broadcasts over its inputs.

=for bad

C<cgesv> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgesv = \&PDL::cgesv;






=head2 cgesvx

=for sig

 Signature: (complex [io]A(n,n); int trans(); int fact();complex  [io]B(n,m);complex  [io]af(n,n); int [io]ipiv(n); int [io]equed(); [o]r(p); [o]c(q);complex  [o]X(n,m); [o]rcond(); [o]ferr(m); [o]berr(m); [o]rpvgrw(); int [o]info(); [t]rwork(rworkn=CALC(4*$SIZE(n))); [t]work(rworkn))
 Types: (float double)

=for usage

 ($r, $c, $X, $rcond, $ferr, $berr, $rpvgrw, $info) = cgesvx($A, $trans, $fact, $B, $af, $ipiv, $equed);
 cgesvx($A, $trans, $fact, $B, $af, $ipiv, $equed, $r, $c, $X, $rcond, $ferr, $berr, $rpvgrw, $info);    # all arguments given
 ($r, $c, $X, $rcond, $ferr, $berr, $rpvgrw, $info) = $A->cgesvx($trans, $fact, $B, $af, $ipiv, $equed); # method call
 $A->cgesvx($trans, $fact, $B, $af, $ipiv, $equed, $r, $c, $X, $rcond, $ferr, $berr, $rpvgrw, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gesvx>.

    trans:  Specifies the form of the system of equations:
            = 0:  A * X = B     (No transpose)
            = 1:  A' * X = B  (Transpose)
            = 2:  A**H * X = B  (Conjugate transpose)

=pod

Broadcasts over its inputs.

=for bad

C<cgesvx> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgesvx = \&PDL::cgesvx;






=head2 csysv

=for sig

 Signature: (complex [io]A(n,n);  int uplo();complex  [io]B(n,m); int [o]ipiv(n); int [o]info())
 Types: (float double)

=for usage

 ($ipiv, $info) = csysv($A, $uplo, $B);
 csysv($A, $uplo, $B, $ipiv, $info);    # all arguments given
 ($ipiv, $info) = $A->csysv($uplo, $B); # method call
 $A->csysv($uplo, $B, $ipiv, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sysv>

=pod

Broadcasts over its inputs.

=for bad

C<csysv> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*csysv = \&PDL::csysv;






=head2 csysvx

=for sig

 Signature: (complex A(n,n); int uplo(); int fact();complex  B(n,m);complex  [io]af(n,n); int [io]ipiv(n);complex  [o]X(n,m); [o]rcond(); [o]ferr(m); [o]berr(m); int [o]info(); [t]rwork(n))
 Types: (float double)

=for usage

 ($X, $rcond, $ferr, $berr, $info) = csysvx($A, $uplo, $fact, $B, $af, $ipiv);
 csysvx($A, $uplo, $fact, $B, $af, $ipiv, $X, $rcond, $ferr, $berr, $info);    # all arguments given
 ($X, $rcond, $ferr, $berr, $info) = $A->csysvx($uplo, $fact, $B, $af, $ipiv); # method call
 $A->csysvx($uplo, $fact, $B, $af, $ipiv, $X, $rcond, $ferr, $berr, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sysvx>

=pod

Broadcasts over its inputs.

=for bad

C<csysvx> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*csysvx = \&PDL::csysvx;






=head2 chesv

=for sig

 Signature: (complex [io]A(n,n);  int uplo();complex  [io]B(n,m); int [o]ipiv(n); int [o]info())
 Types: (float double)

=for usage

 ($ipiv, $info) = chesv($A, $uplo, $B);
 chesv($A, $uplo, $B, $ipiv, $info);    # all arguments given
 ($ipiv, $info) = $A->chesv($uplo, $B); # method call
 $A->chesv($uplo, $B, $ipiv, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sysv> for Hermitian matrix

=pod

Broadcasts over its inputs.

=for bad

C<chesv> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*chesv = \&PDL::chesv;






=head2 chesvx

=for sig

 Signature: (complex A(n,n); int uplo(); int fact();complex  B(n,m);complex  [io]af(n,n); int [io]ipiv(n);complex  [o]X(n,m); [o]rcond(); [o]ferr(m); [o]berr(m); int [o]info(); [t]rwork(n))
 Types: (float double)

=for usage

 ($X, $rcond, $ferr, $berr, $info) = chesvx($A, $uplo, $fact, $B, $af, $ipiv);
 chesvx($A, $uplo, $fact, $B, $af, $ipiv, $X, $rcond, $ferr, $berr, $info);    # all arguments given
 ($X, $rcond, $ferr, $berr, $info) = $A->chesvx($uplo, $fact, $B, $af, $ipiv); # method call
 $A->chesvx($uplo, $fact, $B, $af, $ipiv, $X, $rcond, $ferr, $berr, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sysvx> for Hermitian matrix

=pod

Broadcasts over its inputs.

=for bad

C<chesvx> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*chesvx = \&PDL::chesvx;






=head2 cposv

=for sig

 Signature: (complex [io]A(n,n);  int uplo();complex  [io]B(n,m); int [o]info())
 Types: (float double)

=for usage

 $info = cposv($A, $uplo, $B);
 cposv($A, $uplo, $B, $info);  # all arguments given
 $info = $A->cposv($uplo, $B); # method call
 $A->cposv($uplo, $B, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/posv> for Hermitian positive definite matrix

=pod

Broadcasts over its inputs.

=for bad

C<cposv> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cposv = \&PDL::cposv;






=head2 cposvx

=for sig

 Signature: (complex [io]A(n,n); int uplo(); int fact();complex  [io]B(n,m);complex  [io]af(n,n); int [io]equed(); [o]s(p);complex  [o]X(n,m); [o]rcond(); [o]ferr(m); [o]berr(m); int [o]info(); [t]rwork(rworkn=CALC(2*$SIZE(n))); [t]work(workn=CALC(4*$SIZE(n))))
 Types: (float double)

=for usage

 ($s, $X, $rcond, $ferr, $berr, $info) = cposvx($A, $uplo, $fact, $B, $af, $equed);
 cposvx($A, $uplo, $fact, $B, $af, $equed, $s, $X, $rcond, $ferr, $berr, $info);    # all arguments given
 ($s, $X, $rcond, $ferr, $berr, $info) = $A->cposvx($uplo, $fact, $B, $af, $equed); # method call
 $A->cposvx($uplo, $fact, $B, $af, $equed, $s, $X, $rcond, $ferr, $berr, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/posvx> for Hermitian positive definite matrix

=pod

Broadcasts over its inputs.

=for bad

C<cposvx> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cposvx = \&PDL::cposvx;






=head2 cgels

=for sig

 Signature: (complex [io]A(m,n); int trans();complex  [io]B(p,q);int [o]info())
 Types: (float double)

=for usage

 $info = cgels($A, $trans, $B);
 cgels($A, $trans, $B, $info);  # all arguments given
 $info = $A->cgels($trans, $B); # method call
 $A->cgels($trans, $B, $info);

=for ref

Solves overdetermined or underdetermined complex linear systems
involving an M-by-N matrix A, or its conjugate-transpose.
Complex version of L<PDL::LinearAlgebra::Real/gels>.

    trans:  = 0: the linear system involves A;
            = 1: the linear system involves A**H.

=pod

Broadcasts over its inputs.

=for bad

C<cgels> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgels = \&PDL::cgels;






=head2 cgelsy

=for sig

 Signature: (complex [io]A(m,n);complex  [io]B(p,q); rcond(); int [io]jpvt(n); int [o]rank();int [o]info(); [t]rwork(rworkn=CALC(2*$SIZE(n))))
 Types: (float double)

=for usage

 ($rank, $info) = cgelsy($A, $B, $rcond, $jpvt);
 cgelsy($A, $B, $rcond, $jpvt, $rank, $info);    # all arguments given
 ($rank, $info) = $A->cgelsy($B, $rcond, $jpvt); # method call
 $A->cgelsy($B, $rcond, $jpvt, $rank, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gelsy>

=pod

Broadcasts over its inputs.

=for bad

C<cgelsy> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgelsy = \&PDL::cgelsy;






=head2 cgelss

=for sig

 Signature: (complex [io]A(m,n);complex  [io]B(p,q); rcond(); [o]s(r); int [o]rank();int [o]info(); [t]rwork(rworkn=CALC(5*PDLMIN($SIZE(m),$SIZE(n)))))
 Types: (float double)

=for usage

 ($s, $rank, $info) = cgelss($A, $B, $rcond);
 cgelss($A, $B, $rcond, $s, $rank, $info);    # all arguments given
 ($s, $rank, $info) = $A->cgelss($B, $rcond); # method call
 $A->cgelss($B, $rcond, $s, $rank, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gelss>

=pod

Broadcasts over its inputs.

=for bad

C<cgelss> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgelss = \&PDL::cgelss;






=head2 cgelsd

=for sig

 Signature: (complex [io]A(m,n);complex  [io]B(p,q); rcond(); [o]s(minmn=CALC(PDLMAX(1,PDLMIN($SIZE(m),$SIZE(n))))); int [o]rank();int [o]info(); int [t]iwork(iworkn); [t]rwork(rworkn))
 Types: (float double)

=for usage

 ($s, $rank, $info) = cgelsd($A, $B, $rcond);
 cgelsd($A, $B, $rcond, $s, $rank, $info);    # all arguments given
 ($s, $rank, $info) = $A->cgelsd($B, $rcond); # method call
 $A->cgelsd($B, $rcond, $s, $rank, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gelsd>

=pod

Broadcasts over its inputs.

=for bad

C<cgelsd> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgelsd = \&PDL::cgelsd;






=head2 cgglse

=for sig

 Signature: (complex [io]A(m,n);complex  [io]B(p,n);complex [io]c(m);complex [io]d(p);complex [o]x(n);int [o]info())
 Types: (float double)

=for usage

 ($x, $info) = cgglse($A, $B, $c, $d);
 cgglse($A, $B, $c, $d, $x, $info);    # all arguments given
 ($x, $info) = $A->cgglse($B, $c, $d); # method call
 $A->cgglse($B, $c, $d, $x, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gglse>

=pod

Broadcasts over its inputs.

=for bad

C<cgglse> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgglse = \&PDL::cgglse;






=head2 cggglm

=for sig

 Signature: (complex [io]A(n,m);complex  [io]B(n,p);complex [io]d(n);complex [o]x(m);complex [o]y(p);int [o]info())
 Types: (float double)

=for usage

 ($x, $y, $info) = cggglm($A, $B, $d);
 cggglm($A, $B, $d, $x, $y, $info);    # all arguments given
 ($x, $y, $info) = $A->cggglm($B, $d); # method call
 $A->cggglm($B, $d, $x, $y, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ggglm>

=pod

Broadcasts over its inputs.

=for bad

C<cggglm> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cggglm = \&PDL::cggglm;






=head2 cgetrf

=for sig

 Signature: (complex [io]A(m,n); int [o]ipiv(p=CALC(PDLMIN($SIZE(m),$SIZE(n)))); int [o]info())
 Types: (float double)

=for usage

 ($ipiv, $info) = cgetrf($A);
 cgetrf($A, $ipiv, $info);    # all arguments given
 ($ipiv, $info) = $A->cgetrf; # method call
 $A->cgetrf($ipiv, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/getrf>

=pod

Broadcasts over its inputs.

=for bad

C<cgetrf> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgetrf = \&PDL::cgetrf;






=head2 cgetf2

=for sig

 Signature: (complex [io]A(m,n); int [o]ipiv(p=CALC(PDLMIN($SIZE(m),$SIZE(n)))); int [o]info())
 Types: (float double)

=for usage

 ($ipiv, $info) = cgetf2($A);
 cgetf2($A, $ipiv, $info);    # all arguments given
 ($ipiv, $info) = $A->cgetf2; # method call
 $A->cgetf2($ipiv, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/getf2>

=pod

Broadcasts over its inputs.

=for bad

C<cgetf2> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgetf2 = \&PDL::cgetf2;






=head2 csytrf

=for sig

 Signature: (complex [io]A(n,n); int uplo(); int [o]ipiv(n); int [o]info())
 Types: (float double)

=for usage

 ($ipiv, $info) = csytrf($A, $uplo);
 csytrf($A, $uplo, $ipiv, $info);    # all arguments given
 ($ipiv, $info) = $A->csytrf($uplo); # method call
 $A->csytrf($uplo, $ipiv, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytrf>

=pod

Broadcasts over its inputs.

=for bad

C<csytrf> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*csytrf = \&PDL::csytrf;






=head2 csytf2

=for sig

 Signature: (complex [io]A(n,n); int uplo(); int [o]ipiv(n); int [o]info())
 Types: (float double)

=for usage

 ($ipiv, $info) = csytf2($A, $uplo);
 csytf2($A, $uplo, $ipiv, $info);    # all arguments given
 ($ipiv, $info) = $A->csytf2($uplo); # method call
 $A->csytf2($uplo, $ipiv, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytf2>

=pod

Broadcasts over its inputs.

=for bad

C<csytf2> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*csytf2 = \&PDL::csytf2;






=head2 cchetrf

=for sig

 Signature: (complex [io]A(n,n); int uplo(); int [o]ipiv(n); int [o]info(); [t]work(workn))
 Types: (float double)

=for usage

 ($ipiv, $info) = cchetrf($A, $uplo);
 cchetrf($A, $uplo, $ipiv, $info);    # all arguments given
 ($ipiv, $info) = $A->cchetrf($uplo); # method call
 $A->cchetrf($uplo, $ipiv, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytrf> for Hermitian matrix

=pod

Broadcasts over its inputs.

=for bad

C<cchetrf> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cchetrf = \&PDL::cchetrf;






=head2 chetf2

=for sig

 Signature: (complex [io]A(n,n); int uplo(); int [o]ipiv(n); int [o]info())
 Types: (float double)

=for usage

 ($ipiv, $info) = chetf2($A, $uplo);
 chetf2($A, $uplo, $ipiv, $info);    # all arguments given
 ($ipiv, $info) = $A->chetf2($uplo); # method call
 $A->chetf2($uplo, $ipiv, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytf2> for Hermitian matrix

=pod

Broadcasts over its inputs.

=for bad

C<chetf2> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*chetf2 = \&PDL::chetf2;






=head2 cpotrf

=for sig

 Signature: (complex [io]A(n,n); int uplo(); int [o]info())
 Types: (float double)

=for usage

 $info = cpotrf($A, $uplo);
 cpotrf($A, $uplo, $info);  # all arguments given
 $info = $A->cpotrf($uplo); # method call
 $A->cpotrf($uplo, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/potrf> for Hermitian positive definite matrix

=pod

Broadcasts over its inputs.

=for bad

C<cpotrf> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cpotrf = \&PDL::cpotrf;






=head2 cpotf2

=for sig

 Signature: (complex [io]A(n,n); int uplo(); int [o]info())
 Types: (float double)

=for usage

 $info = cpotf2($A, $uplo);
 cpotf2($A, $uplo, $info);  # all arguments given
 $info = $A->cpotf2($uplo); # method call
 $A->cpotf2($uplo, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/potf2> for Hermitian positive definite matrix

=pod

Broadcasts over its inputs.

=for bad

C<cpotf2> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cpotf2 = \&PDL::cpotf2;






=head2 cgetri

=for sig

 Signature: (complex [io]A(n,n); int ipiv(n); int [o]info())
 Types: (float double)

=for usage

 $info = cgetri($A, $ipiv);
 cgetri($A, $ipiv, $info);  # all arguments given
 $info = $A->cgetri($ipiv); # method call
 $A->cgetri($ipiv, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/getri>

=pod

Broadcasts over its inputs.

=for bad

C<cgetri> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgetri = \&PDL::cgetri;






=head2 csytri

=for sig

 Signature: (complex [io]A(n,n); int uplo(); int ipiv(n); int [o]info(); [t]work(workn=CALC(2*$SIZE(n))))
 Types: (float double)

=for usage

 $info = csytri($A, $uplo, $ipiv);
 csytri($A, $uplo, $ipiv, $info);  # all arguments given
 $info = $A->csytri($uplo, $ipiv); # method call
 $A->csytri($uplo, $ipiv, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytri>

=pod

Broadcasts over its inputs.

=for bad

C<csytri> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*csytri = \&PDL::csytri;






=head2 chetri

=for sig

 Signature: (complex [io]A(n,n); int uplo(); int ipiv(n); int [o]info(); [t]work(workn=CALC(2*$SIZE(n))))
 Types: (float double)

=for usage

 $info = chetri($A, $uplo, $ipiv);
 chetri($A, $uplo, $ipiv, $info);  # all arguments given
 $info = $A->chetri($uplo, $ipiv); # method call
 $A->chetri($uplo, $ipiv, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytri> for Hermitian matrix

=pod

Broadcasts over its inputs.

=for bad

C<chetri> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*chetri = \&PDL::chetri;






=head2 cpotri

=for sig

 Signature: (complex [io]A(n,n); int uplo(); int [o]info())
 Types: (float double)

=for usage

 $info = cpotri($A, $uplo);
 cpotri($A, $uplo, $info);  # all arguments given
 $info = $A->cpotri($uplo); # method call
 $A->cpotri($uplo, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/potri>

=pod

Broadcasts over its inputs.

=for bad

C<cpotri> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cpotri = \&PDL::cpotri;






=head2 ctrtri

=for sig

 Signature: (complex [io]A(n,n); int uplo(); int diag(); int [o]info())
 Types: (float double)

=for usage

 $info = ctrtri($A, $uplo, $diag);
 ctrtri($A, $uplo, $diag, $info);  # all arguments given
 $info = $A->ctrtri($uplo, $diag); # method call
 $A->ctrtri($uplo, $diag, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/trtri>

=pod

Broadcasts over its inputs.

=for bad

C<ctrtri> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*ctrtri = \&PDL::ctrtri;






=head2 ctrti2

=for sig

 Signature: (complex [io]A(n,n); int uplo(); int diag(); int [o]info())
 Types: (float double)

=for usage

 $info = ctrti2($A, $uplo, $diag);
 ctrti2($A, $uplo, $diag, $info);  # all arguments given
 $info = $A->ctrti2($uplo, $diag); # method call
 $A->ctrti2($uplo, $diag, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/trti2>

=pod

Broadcasts over its inputs.

=for bad

C<ctrti2> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*ctrti2 = \&PDL::ctrti2;






=head2 cgetrs

=for sig

 Signature: (complex A(n,n); int trans();complex  [io]B(n,m); int ipiv(n); int [o]info())
 Types: (float double)

=for usage

 $info = cgetrs($A, $trans, $B, $ipiv);
 cgetrs($A, $trans, $B, $ipiv, $info);  # all arguments given
 $info = $A->cgetrs($trans, $B, $ipiv); # method call
 $A->cgetrs($trans, $B, $ipiv, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/getrs>

    Arguments
    =========
  trans:   = 0:  No transpose;
     = 1:  Transpose;
     = 2:  Conjugate transpose;

=pod

Broadcasts over its inputs.

=for bad

C<cgetrs> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgetrs = \&PDL::cgetrs;






=head2 csytrs

=for sig

 Signature: (complex A(n,n); int uplo();complex [io]B(n,m); int ipiv(n); int [o]info())
 Types: (float double)

=for usage

 $info = csytrs($A, $uplo, $B, $ipiv);
 csytrs($A, $uplo, $B, $ipiv, $info);  # all arguments given
 $info = $A->csytrs($uplo, $B, $ipiv); # method call
 $A->csytrs($uplo, $B, $ipiv, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytrs>

=pod

Broadcasts over its inputs.

=for bad

C<csytrs> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*csytrs = \&PDL::csytrs;






=head2 chetrs

=for sig

 Signature: (complex A(n,n); int uplo();complex [io]B(n,m); int ipiv(n); int [o]info())
 Types: (float double)

=for usage

 $info = chetrs($A, $uplo, $B, $ipiv);
 chetrs($A, $uplo, $B, $ipiv, $info);  # all arguments given
 $info = $A->chetrs($uplo, $B, $ipiv); # method call
 $A->chetrs($uplo, $B, $ipiv, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytrs> for Hermitian matrix

=pod

Broadcasts over its inputs.

=for bad

C<chetrs> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*chetrs = \&PDL::chetrs;






=head2 cpotrs

=for sig

 Signature: (complex A(n,n); int uplo();complex  [io]B(n,m); int [o]info())
 Types: (float double)

=for usage

 $info = cpotrs($A, $uplo, $B);
 cpotrs($A, $uplo, $B, $info);  # all arguments given
 $info = $A->cpotrs($uplo, $B); # method call
 $A->cpotrs($uplo, $B, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/potrs> for Hermitian positive definite matrix

=pod

Broadcasts over its inputs.

=for bad

C<cpotrs> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cpotrs = \&PDL::cpotrs;






=head2 ctrtrs

=for sig

 Signature: (complex A(n,n); int uplo(); int trans(); int diag();complex [io]B(n,m); int [o]info())
 Types: (float double)

=for usage

 $info = ctrtrs($A, $uplo, $trans, $diag, $B);
 ctrtrs($A, $uplo, $trans, $diag, $B, $info);  # all arguments given
 $info = $A->ctrtrs($uplo, $trans, $diag, $B); # method call
 $A->ctrtrs($uplo, $trans, $diag, $B, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/trtrs>

    Arguments
    =========
  trans:   = 0:  No transpose;
     = 1:  Transpose;
     = 2:  Conjugate transpose;

=pod

Broadcasts over its inputs.

=for bad

C<ctrtrs> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*ctrtrs = \&PDL::ctrtrs;






=head2 clatrs

=for sig

 Signature: (complex A(n,n); int uplo(); int trans(); int diag(); int normin();complex [io]x(n); [o]scale();[io]cnorm(n);int [o]info())
 Types: (float double)

=for usage

 ($scale, $info) = clatrs($A, $uplo, $trans, $diag, $normin, $x, $cnorm);
 clatrs($A, $uplo, $trans, $diag, $normin, $x, $scale, $cnorm, $info);    # all arguments given
 ($scale, $info) = $A->clatrs($uplo, $trans, $diag, $normin, $x, $cnorm); # method call
 $A->clatrs($uplo, $trans, $diag, $normin, $x, $scale, $cnorm, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/latrs>

    Arguments
    =========
  trans:   = 0:  No transpose;
     = 1:  Transpose;
     = 2:  Conjugate transpose;

=pod

Broadcasts over its inputs.

=for bad

C<clatrs> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*clatrs = \&PDL::clatrs;






=head2 cgecon

=for sig

 Signature: (complex A(n,n); int norm(); anorm(); [o]rcond();int [o]info(); [t]rwork(rworkn=CALC(2*$SIZE(n))); [t]work(workn=CALC(4*$SIZE(n))))
 Types: (float double)

=for usage

 ($rcond, $info) = cgecon($A, $norm, $anorm);
 cgecon($A, $norm, $anorm, $rcond, $info);    # all arguments given
 ($rcond, $info) = $A->cgecon($norm, $anorm); # method call
 $A->cgecon($norm, $anorm, $rcond, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gecon>

=pod

Broadcasts over its inputs.

=for bad

C<cgecon> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgecon = \&PDL::cgecon;






=head2 csycon

=for sig

 Signature: (complex A(n,n); int uplo(); int ipiv(n); anorm(); [o]rcond();int [o]info(); [t]work(workn=CALC(4*$SIZE(n))))
 Types: (float double)

=for usage

 ($rcond, $info) = csycon($A, $uplo, $ipiv, $anorm);
 csycon($A, $uplo, $ipiv, $anorm, $rcond, $info);    # all arguments given
 ($rcond, $info) = $A->csycon($uplo, $ipiv, $anorm); # method call
 $A->csycon($uplo, $ipiv, $anorm, $rcond, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sycon>

=pod

Broadcasts over its inputs.

=for bad

C<csycon> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*csycon = \&PDL::csycon;






=head2 checon

=for sig

 Signature: (complex A(n,n); int uplo(); int ipiv(n); anorm(); [o]rcond();int [o]info(); [t]work(workn=CALC(4*$SIZE(n))))
 Types: (float double)

=for usage

 ($rcond, $info) = checon($A, $uplo, $ipiv, $anorm);
 checon($A, $uplo, $ipiv, $anorm, $rcond, $info);    # all arguments given
 ($rcond, $info) = $A->checon($uplo, $ipiv, $anorm); # method call
 $A->checon($uplo, $ipiv, $anorm, $rcond, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sycon> for Hermitian matrix

=pod

Broadcasts over its inputs.

=for bad

C<checon> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*checon = \&PDL::checon;






=head2 cpocon

=for sig

 Signature: (complex A(n,n); int uplo(); anorm(); [o]rcond();int [o]info(); [t]work(workn=CALC(4*$SIZE(n))); [t]rwork(n))
 Types: (float double)

=for usage

 ($rcond, $info) = cpocon($A, $uplo, $anorm);
 cpocon($A, $uplo, $anorm, $rcond, $info);    # all arguments given
 ($rcond, $info) = $A->cpocon($uplo, $anorm); # method call
 $A->cpocon($uplo, $anorm, $rcond, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/pocon> for Hermitian positive definite matrix

=pod

Broadcasts over its inputs.

=for bad

C<cpocon> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cpocon = \&PDL::cpocon;






=head2 ctrcon

=for sig

 Signature: (complex A(n,n); int norm();int uplo();int diag(); [o]rcond();int [o]info(); [t]work(workn=CALC(4*$SIZE(n))); [t]rwork(n))
 Types: (float double)

=for usage

 ($rcond, $info) = ctrcon($A, $norm, $uplo, $diag);
 ctrcon($A, $norm, $uplo, $diag, $rcond, $info);    # all arguments given
 ($rcond, $info) = $A->ctrcon($norm, $uplo, $diag); # method call
 $A->ctrcon($norm, $uplo, $diag, $rcond, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/trcon>

=pod

Broadcasts over its inputs.

=for bad

C<ctrcon> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*ctrcon = \&PDL::ctrcon;






=head2 cgeqp3

=for sig

 Signature: (complex [io]A(m,n); int [io]jpvt(n);complex  [o]tau(k); int [o]info(); [t]rwork(rworkn=CALC(2*$SIZE(n))))
 Types: (float double)

=for usage

 ($tau, $info) = cgeqp3($A, $jpvt);
 cgeqp3($A, $jpvt, $tau, $info);    # all arguments given
 ($tau, $info) = $A->cgeqp3($jpvt); # method call
 $A->cgeqp3($jpvt, $tau, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/geqp3>

=pod

Broadcasts over its inputs.

=for bad

C<cgeqp3> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgeqp3 = \&PDL::cgeqp3;






=head2 cgeqrf

=for sig

 Signature: (complex [io]A(m,n);complex  [o]tau(k); int [o]info())
 Types: (float double)

=for usage

 ($tau, $info) = cgeqrf($A);
 cgeqrf($A, $tau, $info);    # all arguments given
 ($tau, $info) = $A->cgeqrf; # method call
 $A->cgeqrf($tau, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/geqrf>

=pod

Broadcasts over its inputs.

=for bad

C<cgeqrf> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgeqrf = \&PDL::cgeqrf;






=head2 cungqr

=for sig

 Signature: (complex [io]A(m,n);complex  tau(k); int [o]info())
 Types: (float double)

=for usage

 $info = cungqr($A, $tau);
 cungqr($A, $tau, $info);  # all arguments given
 $info = $A->cungqr($tau); # method call
 $A->cungqr($tau, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/orgqr>

=pod

Broadcasts over its inputs.

=for bad

C<cungqr> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cungqr = \&PDL::cungqr;






=head2 cunmqr

=for sig

 Signature: (complex A(p,k); int side(); int trans();complex  tau(k);complex  [io]C(m,n);int [o]info())
 Types: (float double)

=for usage

 $info = cunmqr($A, $side, $trans, $tau, $C);
 cunmqr($A, $side, $trans, $tau, $C, $info);  # all arguments given
 $info = $A->cunmqr($side, $trans, $tau, $C); # method call
 $A->cunmqr($side, $trans, $tau, $C, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ormqr>. Here trans = 1 means conjugate transpose.

=pod

Broadcasts over its inputs.

=for bad

C<cunmqr> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cunmqr = \&PDL::cunmqr;






=head2 cgelqf

=for sig

 Signature: (complex [io]A(m,n);complex  [o]tau(k); int [o]info())
 Types: (float double)

=for usage

 ($tau, $info) = cgelqf($A);
 cgelqf($A, $tau, $info);    # all arguments given
 ($tau, $info) = $A->cgelqf; # method call
 $A->cgelqf($tau, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gelqf>

=pod

Broadcasts over its inputs.

=for bad

C<cgelqf> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgelqf = \&PDL::cgelqf;






=head2 cunglq

=for sig

 Signature: (complex [io]A(m,n);complex  tau(k); int [o]info())
 Types: (float double)

=for usage

 $info = cunglq($A, $tau);
 cunglq($A, $tau, $info);  # all arguments given
 $info = $A->cunglq($tau); # method call
 $A->cunglq($tau, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/orglq>

=pod

Broadcasts over its inputs.

=for bad

C<cunglq> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cunglq = \&PDL::cunglq;






=head2 cunmlq

=for sig

 Signature: (complex A(k,p); int side(); int trans();complex  tau(k);complex  [io]C(m,n);int [o]info())
 Types: (float double)

=for usage

 $info = cunmlq($A, $side, $trans, $tau, $C);
 cunmlq($A, $side, $trans, $tau, $C, $info);  # all arguments given
 $info = $A->cunmlq($side, $trans, $tau, $C); # method call
 $A->cunmlq($side, $trans, $tau, $C, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ormlq>. Here trans = 1 means conjugate transpose.

=pod

Broadcasts over its inputs.

=for bad

C<cunmlq> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cunmlq = \&PDL::cunmlq;






=head2 cgeqlf

=for sig

 Signature: (complex [io]A(m,n);complex  [o]tau(k); int [o]info())
 Types: (float double)

=for usage

 ($tau, $info) = cgeqlf($A);
 cgeqlf($A, $tau, $info);    # all arguments given
 ($tau, $info) = $A->cgeqlf; # method call
 $A->cgeqlf($tau, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/geqlf>

=pod

Broadcasts over its inputs.

=for bad

C<cgeqlf> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgeqlf = \&PDL::cgeqlf;






=head2 cungql

=for sig

 Signature: (complex [io]A(m,n);complex  tau(k); int [o]info())
 Types: (float double)

=for usage

 $info = cungql($A, $tau);
 cungql($A, $tau, $info);  # all arguments given
 $info = $A->cungql($tau); # method call
 $A->cungql($tau, $info);

=for ref
Complex version of L<PDL::LinearAlgebra::Real/orgql>.

=pod

Broadcasts over its inputs.

=for bad

C<cungql> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cungql = \&PDL::cungql;






=head2 cunmql

=for sig

 Signature: (complex A(p,k); int side(); int trans();complex  tau(k);complex  [io]C(m,n);int [o]info())
 Types: (float double)

=for usage

 $info = cunmql($A, $side, $trans, $tau, $C);
 cunmql($A, $side, $trans, $tau, $C, $info);  # all arguments given
 $info = $A->cunmql($side, $trans, $tau, $C); # method call
 $A->cunmql($side, $trans, $tau, $C, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ormql>. Here trans = 1 means conjugate transpose.

=pod

Broadcasts over its inputs.

=for bad

C<cunmql> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cunmql = \&PDL::cunmql;






=head2 cgerqf

=for sig

 Signature: (complex [io]A(m,n);complex  [o]tau(k); int [o]info())
 Types: (float double)

=for usage

 ($tau, $info) = cgerqf($A);
 cgerqf($A, $tau, $info);    # all arguments given
 ($tau, $info) = $A->cgerqf; # method call
 $A->cgerqf($tau, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gerqf>

=pod

Broadcasts over its inputs.

=for bad

C<cgerqf> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgerqf = \&PDL::cgerqf;






=head2 cungrq

=for sig

 Signature: (complex [io]A(m,n);complex  tau(k); int [o]info())
 Types: (float double)

=for usage

 $info = cungrq($A, $tau);
 cungrq($A, $tau, $info);  # all arguments given
 $info = $A->cungrq($tau); # method call
 $A->cungrq($tau, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/orgrq>.

=pod

Broadcasts over its inputs.

=for bad

C<cungrq> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cungrq = \&PDL::cungrq;






=head2 cunmrq

=for sig

 Signature: (complex A(k,p); int side(); int trans();complex  tau(k);complex  [io]C(m,n);int [o]info())
 Types: (float double)

=for usage

 $info = cunmrq($A, $side, $trans, $tau, $C);
 cunmrq($A, $side, $trans, $tau, $C, $info);  # all arguments given
 $info = $A->cunmrq($side, $trans, $tau, $C); # method call
 $A->cunmrq($side, $trans, $tau, $C, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ormrq>. Here trans = 1 means conjugate transpose.

=pod

Broadcasts over its inputs.

=for bad

C<cunmrq> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cunmrq = \&PDL::cunmrq;






=head2 ctzrzf

=for sig

 Signature: (complex [io]A(m,n);complex  [o]tau(k); int [o]info())
 Types: (float double)

=for usage

 ($tau, $info) = ctzrzf($A);
 ctzrzf($A, $tau, $info);    # all arguments given
 ($tau, $info) = $A->ctzrzf; # method call
 $A->ctzrzf($tau, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/tzrzf>

=pod

Broadcasts over its inputs.

=for bad

C<ctzrzf> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*ctzrzf = \&PDL::ctzrzf;






=head2 cunmrz

=for sig

 Signature: (complex A(k,p); int side(); int trans();complex  tau(k);complex  [io]C(m,n);int [o]info())
 Types: (float double)

=for usage

 $info = cunmrz($A, $side, $trans, $tau, $C);
 cunmrz($A, $side, $trans, $tau, $C, $info);  # all arguments given
 $info = $A->cunmrz($side, $trans, $tau, $C); # method call
 $A->cunmrz($side, $trans, $tau, $C, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ormrz>. Here trans = 1 means conjugate transpose.

=pod

Broadcasts over its inputs.

=for bad

C<cunmrz> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cunmrz = \&PDL::cunmrz;






=head2 cgehrd

=for sig

 Signature: (complex [io]A(n,n); int ilo();int ihi();complex [o]tau(k); int [o]info())
 Types: (float double)

=for usage

 ($tau, $info) = cgehrd($A, $ilo, $ihi);
 cgehrd($A, $ilo, $ihi, $tau, $info);    # all arguments given
 ($tau, $info) = $A->cgehrd($ilo, $ihi); # method call
 $A->cgehrd($ilo, $ihi, $tau, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gehrd>

=pod

Broadcasts over its inputs.

=for bad

C<cgehrd> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgehrd = \&PDL::cgehrd;






=head2 cunghr

=for sig

 Signature: (complex [io]A(n,n); int ilo();int ihi();complex tau(k); int [o]info())
 Types: (float double)

=for usage

 $info = cunghr($A, $ilo, $ihi, $tau);
 cunghr($A, $ilo, $ihi, $tau, $info);  # all arguments given
 $info = $A->cunghr($ilo, $ihi, $tau); # method call
 $A->cunghr($ilo, $ihi, $tau, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/orghr>

=pod

Broadcasts over its inputs.

=for bad

C<cunghr> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cunghr = \&PDL::cunghr;






=head2 chseqr

=for sig

 Signature: (complex [io]H(n,n); int job();int compz();int ilo();int ihi();complex [o]w(n);complex  [o]Z(m,m); int [o]info())
 Types: (float double)

=for usage

 ($w, $Z, $info) = chseqr($H, $job, $compz, $ilo, $ihi);
 chseqr($H, $job, $compz, $ilo, $ihi, $w, $Z, $info);    # all arguments given
 ($w, $Z, $info) = $H->chseqr($job, $compz, $ilo, $ihi); # method call
 $H->chseqr($job, $compz, $ilo, $ihi, $w, $Z, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/hseqr>

=pod

Broadcasts over its inputs.

=for bad

C<chseqr> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*chseqr = \&PDL::chseqr;






=head2 ctrevc

=for sig

 Signature: (complex T(n,n);int select(q);complex [o]VL(m,m);complex  [o]VR(p,p);int [o]m(); int [o]info(); [t]work(workn=CALC(5*$SIZE(n))); int side; int howmny)
 Types: (float double)

=for usage

 ($VL, $VR, $m, $info) = ctrevc($T, $side, $howmny, $select);
 ctrevc($T, $side, $howmny, $select, $VL, $VR, $m, $info);    # all arguments given
 ($VL, $VR, $m, $info) = $T->ctrevc($side, $howmny, $select); # method call
 $T->ctrevc($side, $howmny, $select, $VL, $VR, $m, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/trevc>

=pod

Broadcasts over its inputs.

=for bad

C<ctrevc> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*ctrevc = \&PDL::ctrevc;






=head2 ctgevc

=for sig

 Signature: (complex A(n,n);complex  B(n,n);int select(q);complex [o]VL(m,m);complex  [o]VR(p,p);int [o]m(); int [o]info(); [t]work(workn=CALC(6*$SIZE(n))); int side; int howmny)
 Types: (float double)

=for usage

 ($VL, $VR, $m, $info) = ctgevc($A, $side, $howmny, $B, $select);
 ctgevc($A, $side, $howmny, $B, $select, $VL, $VR, $m, $info);    # all arguments given
 ($VL, $VR, $m, $info) = $A->ctgevc($side, $howmny, $B, $select); # method call
 $A->ctgevc($side, $howmny, $B, $select, $VL, $VR, $m, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/tgevc>

=pod

Broadcasts over its inputs.

=for bad

C<ctgevc> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*ctgevc = \&PDL::ctgevc;






=head2 cgebal

=for sig

 Signature: (complex [io]A(n,n); int job(); int [o]ilo();int [o]ihi();[o]scale(n); int [o]info())
 Types: (float double)

=for usage

 ($ilo, $ihi, $scale, $info) = cgebal($A, $job);
 cgebal($A, $job, $ilo, $ihi, $scale, $info);    # all arguments given
 ($ilo, $ihi, $scale, $info) = $A->cgebal($job); # method call
 $A->cgebal($job, $ilo, $ihi, $scale, $info);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gebal>

=pod

Broadcasts over its inputs.

=for bad

C<cgebal> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgebal = \&PDL::cgebal;






=head2 clange

=for sig

 Signature: (complex A(n,m); [o]b(); [t]work(workn); int norm)
 Types: (float double)

=for usage

 $b = clange($A, $norm);
 clange($A, $norm, $b);  # all arguments given
 $b = $A->clange($norm); # method call
 $A->clange($norm, $b);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/lange>

=pod

Broadcasts over its inputs.

=for bad

C<clange> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*clange = \&PDL::clange;






=head2 clansy

=for sig

 Signature: (complex A(n,n); [o]b(); [t]work(workn); int uplo; int norm)
 Types: (float double)

=for usage

 $b = clansy($A, $uplo, $norm);
 clansy($A, $uplo, $norm, $b);  # all arguments given
 $b = $A->clansy($uplo, $norm); # method call
 $A->clansy($uplo, $norm, $b);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/lansy>

=pod

Broadcasts over its inputs.

=for bad

C<clansy> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*clansy = \&PDL::clansy;






=head2 clantr

=for sig

 Signature: (complex A(m,n); [o]b(); [t]work(workn); int uplo; int norm; int diag)
 Types: (float double)

=for usage

 $b = clantr($A, $uplo, $norm, $diag);
 clantr($A, $uplo, $norm, $diag, $b);  # all arguments given
 $b = $A->clantr($uplo, $norm, $diag); # method call
 $A->clantr($uplo, $norm, $diag, $b);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/lantr>

=pod

Broadcasts over its inputs.

=for bad

C<clantr> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*clantr = \&PDL::clantr;






=head2 cgemm

=for sig

 Signature: (complex A(m,n); int transa(); int transb();complex  B(p,q);complex alpha();complex  beta();complex  [io]C(r,s))
 Types: (float double)

=for usage

 cgemm($A, $transa, $transb, $B, $alpha, $beta, $C); # all arguments given
 $A->cgemm($transa, $transb, $B, $alpha, $beta, $C); # method call

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

=pod

Broadcasts over its inputs.

=for bad

C<cgemm> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cgemm = \&PDL::cgemm;






=head2 cmmult

=for sig

 Signature: (complex A(m,n);complex  B(p,m);complex  [o]C(p,n))
 Types: (float double)

=for usage

 $C = cmmult($A, $B);
 cmmult($A, $B, $C);  # all arguments given
 $C = $A->cmmult($B); # method call
 $A->cmmult($B, $C);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/mmult>

=pod

Broadcasts over its inputs.

=for bad

C<cmmult> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cmmult = \&PDL::cmmult;






=head2 ccrossprod

=for sig

 Signature: (complex A(n,m);complex  B(p,m);complex  [o]C(p,n))
 Types: (float double)

=for usage

 $C = ccrossprod($A, $B);
 ccrossprod($A, $B, $C);  # all arguments given
 $C = $A->ccrossprod($B); # method call
 $A->ccrossprod($B, $C);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/crossprod>

=pod

Broadcasts over its inputs.

=for bad

C<ccrossprod> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*ccrossprod = \&PDL::ccrossprod;






=head2 csyrk

=for sig

 Signature: (complex A(m,n); int uplo(); int trans();complex  alpha();complex  beta();complex  [io]C(p,p))
 Types: (float double)

=for usage

 csyrk($A, $uplo, $trans, $alpha, $beta, $C); # all arguments given
 $A->csyrk($uplo, $trans, $alpha, $beta, $C); # method call

=for ref

Complex version of L<PDL::LinearAlgebra::Real/syrk>

=pod

Broadcasts over its inputs.

=for bad

C<csyrk> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*csyrk = \&PDL::csyrk;






=head2 cdot

=for sig

 Signature: (complex a(n);complex b(n);complex [o]c())
 Types: (float double)

=for usage

 $c = cdot($a, $b);
 cdot($a, $b, $c);  # all arguments given
 $c = $a->cdot($b); # method call
 $a->cdot($b, $c);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/dot>

=pod

Broadcasts over its inputs.

=for bad

C<cdot> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cdot = \&PDL::cdot;






=head2 cdotc

=for sig

 Signature: (complex a(n);complex b(n);complex [o]c())
 Types: (float double)

=for usage

 $c = cdotc($a, $b);
 cdotc($a, $b, $c);  # all arguments given
 $c = $a->cdotc($b); # method call
 $a->cdotc($b, $c);

=for ref

Forms the dot product of two vectors, conjugating the first
vector.

=pod

Broadcasts over its inputs.

=for bad

C<cdotc> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cdotc = \&PDL::cdotc;






=head2 caxpy

=for sig

 Signature: (complex a(n);complex  alpha();complex [io]b(n))
 Types: (float double)

=for usage

 caxpy($a, $alpha, $b); # all arguments given
 $a->caxpy($alpha, $b); # method call

=for ref

Complex version of L<PDL::LinearAlgebra::Real/axpy>

=pod

Broadcasts over its inputs.

=for bad

C<caxpy> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*caxpy = \&PDL::caxpy;






=head2 cnrm2

=for sig

 Signature: (complex a(n);[o]b())
 Types: (float double)

=for usage

 $b = cnrm2($a);
 cnrm2($a, $b);  # all arguments given
 $b = $a->cnrm2; # method call
 $a->cnrm2($b);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/nrm2>

=pod

Broadcasts over its inputs.

=for bad

C<cnrm2> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cnrm2 = \&PDL::cnrm2;






=head2 casum

=for sig

 Signature: (complex a(n);[o]b())
 Types: (float double)

=for usage

 $b = casum($a);
 casum($a, $b);  # all arguments given
 $b = $a->casum; # method call
 $a->casum($b);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/asum>

=pod

Broadcasts over its inputs.

=for bad

C<casum> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*casum = \&PDL::casum;






=head2 cscal

=for sig

 Signature: (complex [io]a(n);complex scale())
 Types: (float double)

=for usage

 cscal($a, $scale); # all arguments given
 $a->cscal($scale); # method call

=for ref

Complex version of L<PDL::LinearAlgebra::Real/scal>

=pod

Broadcasts over its inputs.

=for bad

C<cscal> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cscal = \&PDL::cscal;






=head2 csscal

=for sig

 Signature: (complex [io]a(n);scale())
 Types: (float double)

=for usage

 csscal($a, $scale); # all arguments given
 $a->csscal($scale); # method call

=for ref

Scales a complex vector by a real constant.

=pod

Broadcasts over its inputs.

=for bad

C<csscal> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*csscal = \&PDL::csscal;






=head2 crotg

=for sig

 Signature: (complex [io]a();complex b();[o]c();complex  [o]s())
 Types: (float double)

=for usage

 ($c, $s) = crotg($a, $b);
 crotg($a, $b, $c, $s);    # all arguments given
 ($c, $s) = $a->crotg($b); # method call
 $a->crotg($b, $c, $s);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/rotg>

=pod

Broadcasts over its inputs.

=for bad

C<crotg> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*crotg = \&PDL::crotg;






=head2 clacpy

=for sig

 Signature: (complex A(m,n); int uplo();complex  [o]B(p,n))
 Types: (float double)

=for usage

 $B = clacpy($A, $uplo);
 clacpy($A, $uplo, $B);  # all arguments given
 $B = $A->clacpy($uplo); # method call
 $A->clacpy($uplo, $B);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/lacpy>

=pod

Broadcasts over its inputs.

=for bad

C<clacpy> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*clacpy = \&PDL::clacpy;






=head2 claswp

=for sig

 Signature: (complex [io]A(m,n); int k1(); int k2(); int ipiv(p))
 Types: (float double)

=for usage

 claswp($A, $k1, $k2, $ipiv); # all arguments given
 $A->claswp($k1, $k2, $ipiv); # method call

=for ref

Complex version of L<PDL::LinearAlgebra::Real/laswp>

=pod

Broadcasts over its inputs.

=for bad

C<claswp> ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*claswp = \&PDL::claswp;






=head2 ccharpol

=for sig

 Signature: (A(c=2,n,n);[o]Y(c=2,n,n);[o]out(c=2,p=CALC($SIZE(n)+1)); [t]rwork(rworkn=CALC(2*$SIZE(n)*$SIZE(n))))
 Types: (float double)

=for usage

 ($Y, $out) = ccharpol($A);
 ccharpol($A, $Y, $out);    # all arguments given
 ($Y, $out) = $A->ccharpol; # method call
 $A->ccharpol($Y, $out);

=for ref

Complex version of L<PDL::LinearAlgebra::Real/charpol>

=pod

Broadcasts over its inputs.

=for bad

C<ccharpol> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*ccharpol = \&PDL::ccharpol;







#line 4956 "lib/PDL/LinearAlgebra/Complex.pd"

=head1 AUTHOR

Copyright (C) Grégory Vanuxem 2005-2018.

This library is free software; you can redistribute it and/or modify
it under the terms of the Perl Artistic License as in the file Artistic_2
in this distribution.

=cut
#line 3997 "lib/PDL/LinearAlgebra/Complex.pm"

# Exit with OK status

1;

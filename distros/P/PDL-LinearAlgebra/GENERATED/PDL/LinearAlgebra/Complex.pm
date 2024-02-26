#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::LinearAlgebra::Complex;

our @EXPORT_OK = qw(__Ccgtsv __Ncgtsv cgtsv __Ccgesvd __Ncgesvd cgesvd __Ccgesdd __Ncgesdd cgesdd __Ccggsvd __Ncggsvd cggsvd __Ccgeev __Ncgeev cgeev __Ccgeevx __Ncgeevx cgeevx __Ccggev __Ncggev cggev __Ccggevx __Ncggevx cggevx __Ccgees __Ncgees cgees __Ccgeesx __Ncgeesx cgeesx __Ccgges __Ncgges cgges __Ccggesx __Ncggesx cggesx __Ccheev __Ncheev cheev __Ccheevd __Ncheevd cheevd __Ccheevx __Ncheevx cheevx __Ccheevr __Ncheevr cheevr __Cchegv __Nchegv chegv __Cchegvd __Nchegvd chegvd __Cchegvx __Nchegvx chegvx __Ccgesv __Ncgesv cgesv __Ccgesvx __Ncgesvx cgesvx __Ccsysv __Ncsysv csysv __Ccsysvx __Ncsysvx csysvx __Cchesv __Nchesv chesv __Cchesvx __Nchesvx chesvx __Ccposv __Ncposv cposv __Ccposvx __Ncposvx cposvx __Ccgels __Ncgels cgels __Ccgelsy __Ncgelsy cgelsy __Ccgelss __Ncgelss cgelss __Ccgelsd __Ncgelsd cgelsd __Ccgglse __Ncgglse cgglse __Ccggglm __Ncggglm cggglm __Ccgetrf __Ncgetrf cgetrf __Ccgetf2 __Ncgetf2 cgetf2 __Ccsytrf __Ncsytrf csytrf __Ccsytf2 __Ncsytf2 csytf2 __Ccchetrf __Ncchetrf cchetrf __Cchetf2 __Nchetf2 chetf2 __Ccpotrf __Ncpotrf cpotrf __Ccpotf2 __Ncpotf2 cpotf2 __Ccgetri __Ncgetri cgetri __Ccsytri __Ncsytri csytri __Cchetri __Nchetri chetri __Ccpotri __Ncpotri cpotri __Cctrtri __Nctrtri ctrtri __Cctrti2 __Nctrti2 ctrti2 __Ccgetrs __Ncgetrs cgetrs __Ccsytrs __Ncsytrs csytrs __Cchetrs __Nchetrs chetrs __Ccpotrs __Ncpotrs cpotrs __Cctrtrs __Nctrtrs ctrtrs __Cclatrs __Nclatrs clatrs __Ccgecon __Ncgecon cgecon __Ccsycon __Ncsycon csycon __Cchecon __Nchecon checon __Ccpocon __Ncpocon cpocon __Cctrcon __Nctrcon ctrcon __Ccgeqp3 __Ncgeqp3 cgeqp3 __Ccgeqrf __Ncgeqrf cgeqrf __Ccungqr __Ncungqr cungqr __Ccunmqr __Ncunmqr cunmqr __Ccgelqf __Ncgelqf cgelqf __Ccunglq __Ncunglq cunglq __Ccunmlq __Ncunmlq cunmlq __Ccgeqlf __Ncgeqlf cgeqlf __Ccungql __Ncungql cungql __Ccunmql __Ncunmql cunmql __Ccgerqf __Ncgerqf cgerqf __Ccungrq __Ncungrq cungrq __Ccunmrq __Ncunmrq cunmrq __Cctzrzf __Nctzrzf ctzrzf __Ccunmrz __Ncunmrz cunmrz __Ccgehrd __Ncgehrd cgehrd __Ccunghr __Ncunghr cunghr __Cchseqr __Nchseqr chseqr __Cctrevc __Nctrevc ctrevc __Cctgevc __Nctgevc ctgevc __Ccgebal __Ncgebal cgebal __Cclange __Nclange clange __Cclansy __Nclansy clansy __Cclantr __Nclantr clantr __Ccgemm __Ncgemm cgemm __Ccmmult __Ncmmult cmmult __Cccrossprod __Nccrossprod ccrossprod __Ccsyrk __Ncsyrk csyrk __Ccdot __Ncdot cdot __Ccdotc __Ncdotc cdotc __Ccaxpy __Ncaxpy caxpy __Ccnrm2 __Ncnrm2 cnrm2 __Ccasum __Ncasum casum __Ccscal __Ncscal cscal __Ccsscal __Ncsscal csscal __Ccrotg __Ncrotg crotg __Cclacpy __Nclacpy clacpy __Cclaswp __Nclaswp claswp ctricpy cmstack __Cccharpol __Nccharpol ccharpol );
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

{ 
  package # hide from CPAN
    PDL::Complex;
	my $warningFlag;
	BEGIN{
		$warningFlag = $^W;
		$^W = 0;
	}
	use overload (
		'x'     =>  sub {UNIVERSAL::isa($_[1],'PDL::Complex') ? PDL::cmmult($_[0], $_[1]) :
						PDL::cmmult($_[0], PDL::Complex::r2C($_[1]));
				},
	);
	BEGIN{ $^W = $warningFlag ; }
}

=encoding Latin-1

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
#line 71 "Complex.pm"


=head1 FUNCTIONS

=cut




*__Ccgtsv = \&PDL::__Ccgtsv;




*__Ncgtsv = \&PDL::__Ncgtsv;





#line 23 "../pp_defc.pl"

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
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccgtsv if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncgtsv;
}
*cgtsv = \&PDL::cgtsv;
#line 162 "Complex.pm"

*__Ccgesvd = \&PDL::__Ccgesvd;




*__Ncgesvd = \&PDL::__Ncgesvd;





#line 23 "../pp_defc.pl"

=head2 cgesvd

=for sig

  Signature: (complex [io]A(m,n); int jobu(); int jobvt(); [o]s(minmn);complex  [o]U(p,p);complex  [o]VT(s,s); int [o]info(); [t]rwork(rworkn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gesvd>.

The SVD is written

 A = U * SIGMA * ConjugateTranspose(V)

=cut

sub PDL::cgesvd {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccgesvd if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncgesvd;
}
*cgesvd = \&PDL::cgesvd;
#line 201 "Complex.pm"

*__Ccgesdd = \&PDL::__Ccgesdd;




*__Ncgesdd = \&PDL::__Ncgesdd;





#line 23 "../pp_defc.pl"

=head2 cgesdd

=for sig

  Signature: (complex [io]A(m,n); int jobz(); [o]s(minmn);complex  [o]U(p,p);complex  [o]VT(s,s); int [o]info(); int [t]iwork(iworkn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gesdd>.

The SVD is written

 A = U * SIGMA * ConjugateTranspose(V)

=cut

sub PDL::cgesdd {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccgesdd if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncgesdd;
}
*cgesdd = \&PDL::cgesdd;
#line 240 "Complex.pm"

*__Ccggsvd = \&PDL::__Ccggsvd;




*__Ncggsvd = \&PDL::__Ncggsvd;





#line 23 "../pp_defc.pl"

=head2 cggsvd

=for sig

  Signature: (complex [io]A(m,n); int jobu(); int jobv(); int jobq();complex  [io]B(p,n); int [o]k(); int [o]l();[o]alpha(n);[o]beta(n);complex  [o]U(q,q);complex  [o]V(r,r);complex  [o]Q(s,s); int [o]iwork(n); int [o]info(); [t]rwork(rworkn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ggsvd>

=cut

sub PDL::cggsvd {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccggsvd if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncggsvd;
}
*cggsvd = \&PDL::cggsvd;
#line 275 "Complex.pm"

*__Ccgeev = \&PDL::__Ccgeev;




*__Ncgeev = \&PDL::__Ncgeev;





#line 23 "../pp_defc.pl"

=head2 cgeev

=for sig

  Signature: (complex A(n,n); int jobvl(); int jobvr();complex  [o]w(n);complex  [o]vl(m,m);complex  [o]vr(p,p); int [o]info(); [t]rwork(rworkn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/geev>

=cut

sub PDL::cgeev {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccgeev if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncgeev;
}
*cgeev = \&PDL::cgeev;
#line 310 "Complex.pm"

*__Ccgeevx = \&PDL::__Ccgeevx;




*__Ncgeevx = \&PDL::__Ncgeevx;





#line 23 "../pp_defc.pl"

=head2 cgeevx

=for sig

  Signature: (complex [io]A(n,n);  int jobvl(); int jobvr(); int balance(); int sense();complex  [o]w(n);complex  [o]vl(m,m);complex  [o]vr(p,p); int [o]ilo(); int [o]ihi(); [o]scale(n); [o]abnrm(); [o]rconde(q); [o]rcondv(r); int [o]info(); [t]rwork(rworkn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/geevx>

=cut

sub PDL::cgeevx {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccgeevx if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncgeevx;
}
*cgeevx = \&PDL::cgeevx;
#line 345 "Complex.pm"

*__Ccggev = \&PDL::__Ccggev;




*__Ncggev = \&PDL::__Ncggev;





#line 23 "../pp_defc.pl"

=head2 cggev

=for sig

  Signature: (complex A(n,n); int [phys]jobvl();int [phys]jobvr();complex B(n,n);complex [o]alpha(n);complex [o]beta(n);complex [o]VL(m,m);complex [o]VR(p,p);int [o]info(); [t]rwork(rworkn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ggev>

=cut

sub PDL::cggev {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccggev if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncggev;
}
*cggev = \&PDL::cggev;
#line 380 "Complex.pm"

*__Ccggevx = \&PDL::__Ccggevx;




*__Ncggevx = \&PDL::__Ncggevx;





#line 23 "../pp_defc.pl"

=head2 cggevx

=for sig

  Signature: (complex [io,phys]A(n,n);int balanc();int jobvl();int jobvr();int sense();complex [io,phys]B(n,n);complex [o]alpha(n);complex [o]beta(n);complex [o]VL(m,m);complex [o]VR(p,p);int [o]ilo();int [o]ihi();[o]lscale(n);[o]rscale(n);[o]abnrm();[o]bbnrm();[o]rconde(r);[o]rcondv(s);int [o]info(); [t]rwork(rworkn); int [t]bwork(bworkn); int [t]iwork(iworkn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ggevx>

=cut

sub PDL::cggevx {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccggevx if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncggevx;
}
*cggevx = \&PDL::cggevx;
#line 415 "Complex.pm"

*__Ccgees = \&PDL::__Ccgees;




*__Ncgees = \&PDL::__Ncgees;





#line 23 "../pp_defc.pl"

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
            select_func(PDL::Complex(w)) is true;
            Note that a selected complex eigenvalue may no longer
            satisfy select_func(PDL::Complex(w)) = 1 after ordering, since
            ordering may change the value of complex eigenvalues
            (especially if the eigenvalue is ill-conditioned); in this
            case info is set to N+2.
	

=cut

sub PDL::cgees {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccgees if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncgees;
}
*cgees = \&PDL::cgees;
#line 463 "Complex.pm"

*__Ccgeesx = \&PDL::__Ccgeesx;




*__Ncgeesx = \&PDL::__Ncgeesx;





#line 23 "../pp_defc.pl"

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
            select_func(PDL::Complex(w)) is true; 
            Note that a selected complex eigenvalue may no longer
            satisfy select_func(PDL::Complex(w)) = 1 after ordering, since
            ordering may change the value of complex eigenvalues
            (especially if the eigenvalue is ill-conditioned); in this
            case info is set to N+2.

=cut

sub PDL::cgeesx {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccgeesx if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncgeesx;
}
*cgeesx = \&PDL::cgeesx;
#line 510 "Complex.pm"

*__Ccgges = \&PDL::__Ccgges;




*__Ncgges = \&PDL::__Ncgges;





#line 23 "../pp_defc.pl"

=head2 cgges

=for sig

  Signature: (complex [io]A(n,n); int jobvsl();int jobvsr();int sort();complex [io]B(n,n);complex [o]alpha(n);complex [o]beta(n);complex [o]VSL(m,m);complex [o]VSR(p,p);int [o]sdim();int [o]info(); [t]rwork(rworkn); int [t]bwork(bworkn);SV* select_func)

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ggees>

    select_func:
            If sort = 1, select_func is used to select eigenvalues to sort
            to the top left of the Schur form.
            If sort = 0, select_func is not referenced.
            An eigenvalue w = w/beta is selected if
            select_func(PDL::Complex(w), PDL::Complex(beta)) is true; 
            Note that a selected complex eigenvalue may no longer
            satisfy select_func(PDL::Complex(w),PDL::Complex(beta)) = 1 after ordering, since
            ordering may change the value of complex eigenvalues
            (especially if the eigenvalue is ill-conditioned); in this
            case info is set to N+2.

=cut

sub PDL::cgges {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccgges if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncgges;
}
*cgges = \&PDL::cgges;
#line 557 "Complex.pm"

*__Ccggesx = \&PDL::__Ccggesx;




*__Ncggesx = \&PDL::__Ncggesx;





#line 23 "../pp_defc.pl"

=head2 cggesx

=for sig

  Signature: (complex [io]A(n,n); int jobvsl();int jobvsr();int sort();int sense();complex [io]B(n,n);complex [o]alpha(n);complex [o]beta(n);complex [o]VSL(m,m);complex [o]VSR(p,p);int [o]sdim();[o]rconde(q=2);[o]rcondv(q=2);int [o]info(); [t]rwork(rworkn); int [t]bwork(bworkn); int [t]iwork(iworkn);SV* select_func)

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ggeesx>

    select_func:
            If sort = 1, select_func is used to select eigenvalues to sort
            to the top left of the Schur form.
            If sort = 0, select_func is not referenced.
            An eigenvalue w = w/beta is selected if
            select_func(PDL::Complex(w), PDL::Complex(beta)) is true; 
            Note that a selected complex eigenvalue may no longer
            satisfy select_func(PDL::Complex(w),PDL::Complex(beta)) = 1 after ordering, since
            ordering may change the value of complex eigenvalues
            (especially if the eigenvalue is ill-conditioned); in this
            case info is set to N+3.

=cut

sub PDL::cggesx {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccggesx if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncggesx;
}
*cggesx = \&PDL::cggesx;
#line 604 "Complex.pm"

*__Ccheev = \&PDL::__Ccheev;




*__Ncheev = \&PDL::__Ncheev;





#line 23 "../pp_defc.pl"

=head2 cheev

=for sig

  Signature: (complex [io]A(n,n); int jobz(); int uplo(); [o]w(n); int [o]info(); [t]rwork(rworkn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/syev> for Hermitian matrix

=cut

sub PDL::cheev {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccheev if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncheev;
}
*cheev = \&PDL::cheev;
#line 639 "Complex.pm"

*__Ccheevd = \&PDL::__Ccheevd;




*__Ncheevd = \&PDL::__Ncheevd;





#line 23 "../pp_defc.pl"

=head2 cheevd

=for sig

  Signature: (complex [io,phys]A(n,n);  int jobz(); int uplo(); [o,phys]w(n); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/syevd> for Hermitian matrix

=cut

sub PDL::cheevd {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccheevd if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncheevd;
}
*cheevd = \&PDL::cheevd;
#line 674 "Complex.pm"

*__Ccheevx = \&PDL::__Ccheevx;




*__Ncheevx = \&PDL::__Ncheevx;





#line 23 "../pp_defc.pl"

=head2 cheevx

=for sig

  Signature: (complex A(n,n);  int jobz(); int range(); int uplo(); vl(); vu(); int il(); int iu(); abstol(); int [o]m(); [o]w(n);complex  [o]z(p,p);int [o]ifail(n); int [o]info(); [t]rwork(rworkn); int [t]iwork(iworkn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/syevx> for Hermitian matrix

=cut

sub PDL::cheevx {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccheevx if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncheevx;
}
*cheevx = \&PDL::cheevx;
#line 709 "Complex.pm"

*__Ccheevr = \&PDL::__Ccheevr;




*__Ncheevr = \&PDL::__Ncheevr;





#line 23 "../pp_defc.pl"

=head2 cheevr

=for sig

  Signature: (complex [phys]A(n,n);  int jobz(); int range(); int uplo(); [phys]vl(); [phys]vu(); int [phys]il(); int [phys]iu(); [phys]abstol(); int [o,phys]m(); [o,phys]w(n);complex  [o,phys]z(p,q);int [o,phys]isuppz(r); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/syevr> for Hermitian matrix

=cut

sub PDL::cheevr {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccheevr if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncheevr;
}
*cheevr = \&PDL::cheevr;
#line 744 "Complex.pm"

*__Cchegv = \&PDL::__Cchegv;




*__Nchegv = \&PDL::__Nchegv;





#line 23 "../pp_defc.pl"

=head2 chegv

=for sig

  Signature: (complex [io]A(n,n);int itype();int jobz(); int uplo();complex [io]B(n,n);[o]w(n); int [o]info(); [t]rwork(rworkn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sygv> for Hermitian matrix

=cut

sub PDL::chegv {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Cchegv if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Nchegv;
}
*chegv = \&PDL::chegv;
#line 779 "Complex.pm"

*__Cchegvd = \&PDL::__Cchegvd;




*__Nchegvd = \&PDL::__Nchegvd;





#line 23 "../pp_defc.pl"

=head2 chegvd

=for sig

  Signature: (complex [io,phys]A(n,n);int [phys]itype();int jobz(); int uplo();complex [io,phys]B(n,n);[o,phys]w(n); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sygvd> for Hermitian matrix

=cut

sub PDL::chegvd {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Cchegvd if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Nchegvd;
}
*chegvd = \&PDL::chegvd;
#line 814 "Complex.pm"

*__Cchegvx = \&PDL::__Cchegvx;




*__Nchegvx = \&PDL::__Nchegvx;





#line 23 "../pp_defc.pl"

=head2 chegvx

=for sig

  Signature: (complex [io]A(n,n);int itype();int jobz();int range();
	  int uplo();complex [io]B(n,n);vl();vu();int il();
	  int iu();abstol();int [o]m();[o]w(n);complex 
	  [o]Z(p,p);int [o]ifail(n);int [o]info(); [t]rwork(rworkn); int [t]iwork(iworkn);
	)

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sygvx> for Hermitian matrix

=cut

sub PDL::chegvx {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Cchegvx if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Nchegvx;
}
*chegvx = \&PDL::chegvx;
#line 853 "Complex.pm"

*__Ccgesv = \&PDL::__Ccgesv;




*__Ncgesv = \&PDL::__Ncgesv;





#line 23 "../pp_defc.pl"

=head2 cgesv

=for sig

  Signature: (complex [io,phys]A(n,n);complex   [io,phys]B(n,m); int [o,phys]ipiv(n); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gesv>

=cut

sub PDL::cgesv {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccgesv if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncgesv;
}
*cgesv = \&PDL::cgesv;
#line 888 "Complex.pm"

*__Ccgesvx = \&PDL::__Ccgesvx;




*__Ncgesvx = \&PDL::__Ncgesvx;





#line 23 "../pp_defc.pl"

=head2 cgesvx

=for sig

  Signature: (complex [io]A(n,n); int trans(); int fact();complex  [io]B(n,m);complex  [io]af(n,n); int [io]ipiv(n); int [io]equed(); [o]r(p); [o]c(q);complex  [o]X(n,m); [o]rcond(); [o]ferr(m); [o]berr(m); [o]rpvgrw(); int [o]info(); [t]rwork(rworkn); [t]work(rworkn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gesvx>.

    trans:  Specifies the form of the system of equations:
            = 0:  A * X = B     (No transpose)   
            = 1:  A' * X = B  (Transpose)
            = 2:  A**H * X = B  (Conjugate transpose)  

=cut

sub PDL::cgesvx {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccgesvx if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncgesvx;
}
*cgesvx = \&PDL::cgesvx;
#line 928 "Complex.pm"

*__Ccsysv = \&PDL::__Ccsysv;




*__Ncsysv = \&PDL::__Ncsysv;





#line 23 "../pp_defc.pl"

=head2 csysv

=for sig

  Signature: (complex [io,phys]A(n,n);  int uplo();complex  [io,phys]B(n,m); int [o]ipiv(n); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sysv>

=cut

sub PDL::csysv {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccsysv if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncsysv;
}
*csysv = \&PDL::csysv;
#line 963 "Complex.pm"

*__Ccsysvx = \&PDL::__Ccsysvx;




*__Ncsysvx = \&PDL::__Ncsysvx;





#line 23 "../pp_defc.pl"

=head2 csysvx

=for sig

  Signature: (complex [phys]A(n,n); int uplo(); int fact();complex  [phys]B(n,m);complex  [io,phys]af(n,n); int [io,phys]ipiv(n);complex  [o]X(n,m); [o]rcond(); [o]ferr(m); [o]berr(m); int [o]info(); [t]rwork(n))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sysvx>

=cut

sub PDL::csysvx {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccsysvx if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncsysvx;
}
*csysvx = \&PDL::csysvx;
#line 998 "Complex.pm"

*__Cchesv = \&PDL::__Cchesv;




*__Nchesv = \&PDL::__Nchesv;





#line 23 "../pp_defc.pl"

=head2 chesv

=for sig

  Signature: (complex [io,phys]A(n,n);  int uplo();complex  [io,phys]B(n,m); int [o,phys]ipiv(n); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sysv> for Hermitian matrix

=cut

sub PDL::chesv {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Cchesv if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Nchesv;
}
*chesv = \&PDL::chesv;
#line 1033 "Complex.pm"

*__Cchesvx = \&PDL::__Cchesvx;




*__Nchesvx = \&PDL::__Nchesvx;





#line 23 "../pp_defc.pl"

=head2 chesvx

=for sig

  Signature: (complex A(n,n); int uplo(); int fact();complex  B(n,m);complex  [io]af(n,n); int [io]ipiv(n);complex  [o]X(n,m); [o]rcond(); [o]ferr(m); [o]berr(m); int [o]info(); [t]rwork(n))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sysvx> for Hermitian matrix

=cut

sub PDL::chesvx {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Cchesvx if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Nchesvx;
}
*chesvx = \&PDL::chesvx;
#line 1068 "Complex.pm"

*__Ccposv = \&PDL::__Ccposv;




*__Ncposv = \&PDL::__Ncposv;





#line 23 "../pp_defc.pl"

=head2 cposv

=for sig

  Signature: (complex [io,phys]A(n,n);  int uplo();complex  [io,phys]B(n,m); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/posv> for Hermitian positive definite matrix

=cut

sub PDL::cposv {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccposv if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncposv;
}
*cposv = \&PDL::cposv;
#line 1103 "Complex.pm"

*__Ccposvx = \&PDL::__Ccposvx;




*__Ncposvx = \&PDL::__Ncposvx;





#line 23 "../pp_defc.pl"

=head2 cposvx

=for sig

  Signature: (complex [io]A(n,n); int uplo(); int fact();complex  [io]B(n,m);complex  [io]af(n,n); int [io]equed(); [o]s(p);complex  [o]X(n,m); [o]rcond(); [o]ferr(m); [o]berr(m); int [o]info(); [t]rwork(rworkn); [t]work(workn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/posvx> for Hermitian positive definite matrix

=cut

sub PDL::cposvx {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccposvx if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncposvx;
}
*cposvx = \&PDL::cposvx;
#line 1138 "Complex.pm"

*__Ccgels = \&PDL::__Ccgels;




*__Ncgels = \&PDL::__Ncgels;





#line 23 "../pp_defc.pl"

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
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccgels if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncgels;
}
*cgels = \&PDL::cgels;
#line 1178 "Complex.pm"

*__Ccgelsy = \&PDL::__Ccgelsy;




*__Ncgelsy = \&PDL::__Ncgelsy;





#line 23 "../pp_defc.pl"

=head2 cgelsy

=for sig

  Signature: (complex [io]A(m,n);complex  [io]B(p,q); rcond(); int [io]jpvt(n); int [o]rank();int [o]info(); [t]rwork(rworkn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gelsy>

=cut

sub PDL::cgelsy {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccgelsy if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncgelsy;
}
*cgelsy = \&PDL::cgelsy;
#line 1213 "Complex.pm"

*__Ccgelss = \&PDL::__Ccgelss;




*__Ncgelss = \&PDL::__Ncgelss;





#line 23 "../pp_defc.pl"

=head2 cgelss

=for sig

  Signature: (complex [io]A(m,n);complex  [io]B(p,q); rcond(); [o]s(r); int [o]rank();int [o]info(); [t]rwork(rworkn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gelss>

=cut

sub PDL::cgelss {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccgelss if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncgelss;
}
*cgelss = \&PDL::cgelss;
#line 1248 "Complex.pm"

*__Ccgelsd = \&PDL::__Ccgelsd;




*__Ncgelsd = \&PDL::__Ncgelsd;





#line 23 "../pp_defc.pl"

=head2 cgelsd

=for sig

  Signature: (complex [io]A(m,n);complex  [io]B(p,q); rcond(); [o]s(minmn); int [o]rank();int [o]info(); int [t]iwork(iworkn); [t]rwork(rworkn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gelsd>

=cut

sub PDL::cgelsd {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccgelsd if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncgelsd;
}
*cgelsd = \&PDL::cgelsd;
#line 1283 "Complex.pm"

*__Ccgglse = \&PDL::__Ccgglse;




*__Ncgglse = \&PDL::__Ncgglse;





#line 23 "../pp_defc.pl"

=head2 cgglse

=for sig

  Signature: (complex [phys]A(m,n);complex  [phys]B(p,n);complex [io,phys]c(m);complex [phys]d(p);complex [o,phys]x(n);int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gglse>

=cut

sub PDL::cgglse {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccgglse if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncgglse;
}
*cgglse = \&PDL::cgglse;
#line 1318 "Complex.pm"

*__Ccggglm = \&PDL::__Ccggglm;




*__Ncggglm = \&PDL::__Ncggglm;





#line 23 "../pp_defc.pl"

=head2 cggglm

=for sig

  Signature: (complex [phys]A(n,m);complex  [phys]B(n,p);complex [phys]d(n);complex [o,phys]x(m);complex [o,phys]y(p);int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ggglm>

=cut

sub PDL::cggglm {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccggglm if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncggglm;
}
*cggglm = \&PDL::cggglm;
#line 1353 "Complex.pm"

*__Ccgetrf = \&PDL::__Ccgetrf;




*__Ncgetrf = \&PDL::__Ncgetrf;





#line 23 "../pp_defc.pl"

=head2 cgetrf

=for sig

  Signature: (complex [io]A(m,n); int [o]ipiv(p); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/getrf>

=cut

sub PDL::cgetrf {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccgetrf if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncgetrf;
}
*cgetrf = \&PDL::cgetrf;
#line 1388 "Complex.pm"

*__Ccgetf2 = \&PDL::__Ccgetf2;




*__Ncgetf2 = \&PDL::__Ncgetf2;





#line 23 "../pp_defc.pl"

=head2 cgetf2

=for sig

  Signature: (complex [io]A(m,n); int [o]ipiv(p); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/getf2>

=cut

sub PDL::cgetf2 {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccgetf2 if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncgetf2;
}
*cgetf2 = \&PDL::cgetf2;
#line 1423 "Complex.pm"

*__Ccsytrf = \&PDL::__Ccsytrf;




*__Ncsytrf = \&PDL::__Ncsytrf;





#line 23 "../pp_defc.pl"

=head2 csytrf

=for sig

  Signature: (complex [io,phys]A(n,n); int uplo(); int [o,phys]ipiv(n); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytrf>

=cut

sub PDL::csytrf {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccsytrf if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncsytrf;
}
*csytrf = \&PDL::csytrf;
#line 1458 "Complex.pm"

*__Ccsytf2 = \&PDL::__Ccsytf2;




*__Ncsytf2 = \&PDL::__Ncsytf2;





#line 23 "../pp_defc.pl"

=head2 csytf2

=for sig

  Signature: (complex [io,phys]A(n,n); int uplo(); int [o,phys]ipiv(n); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytf2>

=cut

sub PDL::csytf2 {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccsytf2 if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncsytf2;
}
*csytf2 = \&PDL::csytf2;
#line 1493 "Complex.pm"

*__Ccchetrf = \&PDL::__Ccchetrf;




*__Ncchetrf = \&PDL::__Ncchetrf;





#line 23 "../pp_defc.pl"

=head2 cchetrf

=for sig

  Signature: (complex [io]A(n,n); int uplo(); int [o]ipiv(n); int [o]info(); [t]work(workn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytrf> for Hermitian matrix

=cut

sub PDL::cchetrf {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccchetrf if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncchetrf;
}
*cchetrf = \&PDL::cchetrf;
#line 1528 "Complex.pm"

*__Cchetf2 = \&PDL::__Cchetf2;




*__Nchetf2 = \&PDL::__Nchetf2;





#line 23 "../pp_defc.pl"

=head2 chetf2

=for sig

  Signature: (complex [io]A(n,n); int uplo(); int [o]ipiv(n); int [o]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytf2> for Hermitian matrix

=cut

sub PDL::chetf2 {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Cchetf2 if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Nchetf2;
}
*chetf2 = \&PDL::chetf2;
#line 1563 "Complex.pm"

*__Ccpotrf = \&PDL::__Ccpotrf;




*__Ncpotrf = \&PDL::__Ncpotrf;





#line 23 "../pp_defc.pl"

=head2 cpotrf

=for sig

  Signature: (complex [io,phys]A(n,n); int uplo(); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/potrf> for Hermitian positive definite matrix

=cut

sub PDL::cpotrf {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccpotrf if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncpotrf;
}
*cpotrf = \&PDL::cpotrf;
#line 1598 "Complex.pm"

*__Ccpotf2 = \&PDL::__Ccpotf2;




*__Ncpotf2 = \&PDL::__Ncpotf2;





#line 23 "../pp_defc.pl"

=head2 cpotf2

=for sig

  Signature: (complex [io,phys]A(n,n); int uplo(); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/potf2> for Hermitian positive definite matrix

=cut

sub PDL::cpotf2 {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccpotf2 if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncpotf2;
}
*cpotf2 = \&PDL::cpotf2;
#line 1633 "Complex.pm"

*__Ccgetri = \&PDL::__Ccgetri;




*__Ncgetri = \&PDL::__Ncgetri;





#line 23 "../pp_defc.pl"

=head2 cgetri

=for sig

  Signature: (complex [io,phys]A(n,n); int [phys]ipiv(n); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/getri>

=cut

sub PDL::cgetri {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccgetri if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncgetri;
}
*cgetri = \&PDL::cgetri;
#line 1668 "Complex.pm"

*__Ccsytri = \&PDL::__Ccsytri;




*__Ncsytri = \&PDL::__Ncsytri;





#line 23 "../pp_defc.pl"

=head2 csytri

=for sig

  Signature: (complex [io]A(n,n); int uplo(); int ipiv(n); int [o]info(); [t]work(workn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytri>

=cut

sub PDL::csytri {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccsytri if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncsytri;
}
*csytri = \&PDL::csytri;
#line 1703 "Complex.pm"

*__Cchetri = \&PDL::__Cchetri;




*__Nchetri = \&PDL::__Nchetri;





#line 23 "../pp_defc.pl"

=head2 chetri

=for sig

  Signature: (complex [io]A(n,n); int uplo(); int ipiv(n); int [o]info(); [t]work(workn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytri> for Hermitian matrix

=cut

sub PDL::chetri {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Cchetri if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Nchetri;
}
*chetri = \&PDL::chetri;
#line 1738 "Complex.pm"

*__Ccpotri = \&PDL::__Ccpotri;




*__Ncpotri = \&PDL::__Ncpotri;





#line 23 "../pp_defc.pl"

=head2 cpotri

=for sig

  Signature: (complex [io,phys]A(n,n); int uplo(); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/potri>

=cut

sub PDL::cpotri {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccpotri if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncpotri;
}
*cpotri = \&PDL::cpotri;
#line 1773 "Complex.pm"

*__Cctrtri = \&PDL::__Cctrtri;




*__Nctrtri = \&PDL::__Nctrtri;





#line 23 "../pp_defc.pl"

=head2 ctrtri

=for sig

  Signature: (complex [io,phys]A(n,n); int uplo(); int diag(); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/trtri>

=cut

sub PDL::ctrtri {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Cctrtri if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Nctrtri;
}
*ctrtri = \&PDL::ctrtri;
#line 1808 "Complex.pm"

*__Cctrti2 = \&PDL::__Cctrti2;




*__Nctrti2 = \&PDL::__Nctrti2;





#line 23 "../pp_defc.pl"

=head2 ctrti2

=for sig

  Signature: (complex [io,phys]A(n,n); int uplo(); int diag(); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/trti2>

=cut

sub PDL::ctrti2 {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Cctrti2 if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Nctrti2;
}
*ctrti2 = \&PDL::ctrti2;
#line 1843 "Complex.pm"

*__Ccgetrs = \&PDL::__Ccgetrs;




*__Ncgetrs = \&PDL::__Ncgetrs;





#line 23 "../pp_defc.pl"

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
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccgetrs if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncgetrs;
}
*cgetrs = \&PDL::cgetrs;
#line 1884 "Complex.pm"

*__Ccsytrs = \&PDL::__Ccsytrs;




*__Ncsytrs = \&PDL::__Ncsytrs;





#line 23 "../pp_defc.pl"

=head2 csytrs

=for sig

  Signature: (complex [phys]A(n,n); int uplo();complex [io,phys]B(n,m); int [phys]ipiv(n); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytrs>

=cut

sub PDL::csytrs {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccsytrs if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncsytrs;
}
*csytrs = \&PDL::csytrs;
#line 1919 "Complex.pm"

*__Cchetrs = \&PDL::__Cchetrs;




*__Nchetrs = \&PDL::__Nchetrs;





#line 23 "../pp_defc.pl"

=head2 chetrs

=for sig

  Signature: (complex [phys]A(n,n); int uplo();complex [io,phys]B(n,m); int [phys]ipiv(n); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytrs> for Hermitian matrix

=cut

sub PDL::chetrs {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Cchetrs if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Nchetrs;
}
*chetrs = \&PDL::chetrs;
#line 1954 "Complex.pm"

*__Ccpotrs = \&PDL::__Ccpotrs;




*__Ncpotrs = \&PDL::__Ncpotrs;





#line 23 "../pp_defc.pl"

=head2 cpotrs

=for sig

  Signature: (complex [phys]A(n,n); int uplo();complex  [io,phys]B(n,m); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/potrs> for Hermitian positive definite matrix

=cut

sub PDL::cpotrs {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccpotrs if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncpotrs;
}
*cpotrs = \&PDL::cpotrs;
#line 1989 "Complex.pm"

*__Cctrtrs = \&PDL::__Cctrtrs;




*__Nctrtrs = \&PDL::__Nctrtrs;





#line 23 "../pp_defc.pl"

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
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Cctrtrs if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Nctrtrs;
}
*ctrtrs = \&PDL::ctrtrs;
#line 2030 "Complex.pm"

*__Cclatrs = \&PDL::__Cclatrs;




*__Nclatrs = \&PDL::__Nclatrs;





#line 23 "../pp_defc.pl"

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
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Cclatrs if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Nclatrs;
}
*clatrs = \&PDL::clatrs;
#line 2071 "Complex.pm"

*__Ccgecon = \&PDL::__Ccgecon;




*__Ncgecon = \&PDL::__Ncgecon;





#line 23 "../pp_defc.pl"

=head2 cgecon

=for sig

  Signature: (complex A(n,n); int norm(); anorm(); [o]rcond();int [o]info(); [t]rwork(rworkn); [t]work(workn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gecon>

=cut

sub PDL::cgecon {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccgecon if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncgecon;
}
*cgecon = \&PDL::cgecon;
#line 2106 "Complex.pm"

*__Ccsycon = \&PDL::__Ccsycon;




*__Ncsycon = \&PDL::__Ncsycon;





#line 23 "../pp_defc.pl"

=head2 csycon

=for sig

  Signature: (complex A(n,n); int uplo(); int ipiv(n); anorm(); [o]rcond();int [o]info(); [t]work(workn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sycon>

=cut

sub PDL::csycon {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccsycon if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncsycon;
}
*csycon = \&PDL::csycon;
#line 2141 "Complex.pm"

*__Cchecon = \&PDL::__Cchecon;




*__Nchecon = \&PDL::__Nchecon;





#line 23 "../pp_defc.pl"

=head2 checon

=for sig

  Signature: (complex A(n,n); int uplo(); int ipiv(n); anorm(); [o]rcond();int [o]info(); [t]work(workn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/sycon> for Hermitian matrix

=cut

sub PDL::checon {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Cchecon if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Nchecon;
}
*checon = \&PDL::checon;
#line 2176 "Complex.pm"

*__Ccpocon = \&PDL::__Ccpocon;




*__Ncpocon = \&PDL::__Ncpocon;





#line 23 "../pp_defc.pl"

=head2 cpocon

=for sig

  Signature: (complex A(n,n); int uplo(); anorm(); [o]rcond();int [o]info(); [t]work(workn); [t]rwork(n))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/pocon> for Hermitian positive definite matrix

=cut

sub PDL::cpocon {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccpocon if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncpocon;
}
*cpocon = \&PDL::cpocon;
#line 2211 "Complex.pm"

*__Cctrcon = \&PDL::__Cctrcon;




*__Nctrcon = \&PDL::__Nctrcon;





#line 23 "../pp_defc.pl"

=head2 ctrcon

=for sig

  Signature: (complex A(n,n); int norm();int uplo();int diag(); [o]rcond();int [o]info(); [t]work(workn); [t]rwork(n))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/trcon>

=cut

sub PDL::ctrcon {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Cctrcon if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Nctrcon;
}
*ctrcon = \&PDL::ctrcon;
#line 2246 "Complex.pm"

*__Ccgeqp3 = \&PDL::__Ccgeqp3;




*__Ncgeqp3 = \&PDL::__Ncgeqp3;





#line 23 "../pp_defc.pl"

=head2 cgeqp3

=for sig

  Signature: (complex [io]A(m,n); int [io]jpvt(n);complex  [o]tau(k); int [o]info(); [t]rwork(rworkn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/geqp3>

=cut

sub PDL::cgeqp3 {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccgeqp3 if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncgeqp3;
}
*cgeqp3 = \&PDL::cgeqp3;
#line 2281 "Complex.pm"

*__Ccgeqrf = \&PDL::__Ccgeqrf;




*__Ncgeqrf = \&PDL::__Ncgeqrf;





#line 23 "../pp_defc.pl"

=head2 cgeqrf

=for sig

  Signature: (complex [io,phys]A(m,n);complex  [o,phys]tau(k); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/geqrf>

=cut

sub PDL::cgeqrf {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccgeqrf if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncgeqrf;
}
*cgeqrf = \&PDL::cgeqrf;
#line 2316 "Complex.pm"

*__Ccungqr = \&PDL::__Ccungqr;




*__Ncungqr = \&PDL::__Ncungqr;





#line 23 "../pp_defc.pl"

=head2 cungqr

=for sig

  Signature: (complex [io,phys]A(m,n);complex  [phys]tau(k); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/orgqr>

=cut

sub PDL::cungqr {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccungqr if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncungqr;
}
*cungqr = \&PDL::cungqr;
#line 2351 "Complex.pm"

*__Ccunmqr = \&PDL::__Ccunmqr;




*__Ncunmqr = \&PDL::__Ncunmqr;





#line 23 "../pp_defc.pl"

=head2 cunmqr

=for sig

  Signature: (complex [phys]A(p,k); int side(); int trans();complex  [phys]tau(k);complex  [io,phys]C(m,n);int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ormqr>. Here trans = 1 means conjugate transpose.

=cut

sub PDL::cunmqr {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccunmqr if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncunmqr;
}
*cunmqr = \&PDL::cunmqr;
#line 2386 "Complex.pm"

*__Ccgelqf = \&PDL::__Ccgelqf;




*__Ncgelqf = \&PDL::__Ncgelqf;





#line 23 "../pp_defc.pl"

=head2 cgelqf

=for sig

  Signature: (complex [io,phys]A(m,n);complex  [o,phys]tau(k); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gelqf>

=cut

sub PDL::cgelqf {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccgelqf if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncgelqf;
}
*cgelqf = \&PDL::cgelqf;
#line 2421 "Complex.pm"

*__Ccunglq = \&PDL::__Ccunglq;




*__Ncunglq = \&PDL::__Ncunglq;





#line 23 "../pp_defc.pl"

=head2 cunglq

=for sig

  Signature: (complex [io,phys]A(m,n);complex  [phys]tau(k); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/orglq>

=cut

sub PDL::cunglq {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccunglq if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncunglq;
}
*cunglq = \&PDL::cunglq;
#line 2456 "Complex.pm"

*__Ccunmlq = \&PDL::__Ccunmlq;




*__Ncunmlq = \&PDL::__Ncunmlq;





#line 23 "../pp_defc.pl"

=head2 cunmlq

=for sig

  Signature: (complex [phys]A(k,p); int side(); int trans();complex  [phys]tau(k);complex  [io,phys]C(m,n);int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ormlq>. Here trans = 1 means conjugate transpose.

=cut

sub PDL::cunmlq {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccunmlq if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncunmlq;
}
*cunmlq = \&PDL::cunmlq;
#line 2491 "Complex.pm"

*__Ccgeqlf = \&PDL::__Ccgeqlf;




*__Ncgeqlf = \&PDL::__Ncgeqlf;





#line 23 "../pp_defc.pl"

=head2 cgeqlf

=for sig

  Signature: (complex [io,phys]A(m,n);complex  [o,phys]tau(k); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/geqlf>

=cut

sub PDL::cgeqlf {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccgeqlf if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncgeqlf;
}
*cgeqlf = \&PDL::cgeqlf;
#line 2526 "Complex.pm"

*__Ccungql = \&PDL::__Ccungql;




*__Ncungql = \&PDL::__Ncungql;





#line 23 "../pp_defc.pl"

=head2 cungql

=for sig

  Signature: (complex [io,phys]A(m,n);complex  [phys]tau(k); int [o,phys]info())

=for ref
Complex version of L<PDL::LinearAlgebra::Real/orgql>.

=cut

sub PDL::cungql {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccungql if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncungql;
}
*cungql = \&PDL::cungql;
#line 2560 "Complex.pm"

*__Ccunmql = \&PDL::__Ccunmql;




*__Ncunmql = \&PDL::__Ncunmql;





#line 23 "../pp_defc.pl"

=head2 cunmql

=for sig

  Signature: (complex [phys]A(p,k); int side(); int trans();complex  [phys]tau(k);complex  [io,phys]C(m,n);int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ormql>. Here trans = 1 means conjugate transpose.

=cut

sub PDL::cunmql {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccunmql if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncunmql;
}
*cunmql = \&PDL::cunmql;
#line 2595 "Complex.pm"

*__Ccgerqf = \&PDL::__Ccgerqf;




*__Ncgerqf = \&PDL::__Ncgerqf;





#line 23 "../pp_defc.pl"

=head2 cgerqf

=for sig

  Signature: (complex [io,phys]A(m,n);complex  [o,phys]tau(k); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gerqf>

=cut

sub PDL::cgerqf {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccgerqf if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncgerqf;
}
*cgerqf = \&PDL::cgerqf;
#line 2630 "Complex.pm"

*__Ccungrq = \&PDL::__Ccungrq;




*__Ncungrq = \&PDL::__Ncungrq;





#line 23 "../pp_defc.pl"

=head2 cungrq

=for sig

  Signature: (complex [io,phys]A(m,n);complex  [phys]tau(k); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/orgrq>.

=cut

sub PDL::cungrq {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccungrq if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncungrq;
}
*cungrq = \&PDL::cungrq;
#line 2665 "Complex.pm"

*__Ccunmrq = \&PDL::__Ccunmrq;




*__Ncunmrq = \&PDL::__Ncunmrq;





#line 23 "../pp_defc.pl"

=head2 cunmrq

=for sig

  Signature: (complex [phys]A(k,p); int side(); int trans();complex  [phys]tau(k);complex  [io,phys]C(m,n);int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ormrq>. Here trans = 1 means conjugate transpose.

=cut

sub PDL::cunmrq {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccunmrq if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncunmrq;
}
*cunmrq = \&PDL::cunmrq;
#line 2700 "Complex.pm"

*__Cctzrzf = \&PDL::__Cctzrzf;




*__Nctzrzf = \&PDL::__Nctzrzf;





#line 23 "../pp_defc.pl"

=head2 ctzrzf

=for sig

  Signature: (complex [io,phys]A(m,n);complex  [o,phys]tau(k); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/tzrzf>

=cut

sub PDL::ctzrzf {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Cctzrzf if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Nctzrzf;
}
*ctzrzf = \&PDL::ctzrzf;
#line 2735 "Complex.pm"

*__Ccunmrz = \&PDL::__Ccunmrz;




*__Ncunmrz = \&PDL::__Ncunmrz;





#line 23 "../pp_defc.pl"

=head2 cunmrz

=for sig

  Signature: (complex [phys]A(k,p); int side(); int trans();complex  [phys]tau(k);complex  [io,phys]C(m,n);int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/ormrz>. Here trans = 1 means conjugate transpose.

=cut

sub PDL::cunmrz {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccunmrz if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncunmrz;
}
*cunmrz = \&PDL::cunmrz;
#line 2770 "Complex.pm"

*__Ccgehrd = \&PDL::__Ccgehrd;




*__Ncgehrd = \&PDL::__Ncgehrd;





#line 23 "../pp_defc.pl"

=head2 cgehrd

=for sig

  Signature: (complex [io,phys]A(n,n); int [phys]ilo();int [phys]ihi();complex [o,phys]tau(k); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gehrd>

=cut

sub PDL::cgehrd {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccgehrd if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncgehrd;
}
*cgehrd = \&PDL::cgehrd;
#line 2805 "Complex.pm"

*__Ccunghr = \&PDL::__Ccunghr;




*__Ncunghr = \&PDL::__Ncunghr;





#line 23 "../pp_defc.pl"

=head2 cunghr

=for sig

  Signature: (complex [io,phys]A(n,n); int [phys]ilo();int [phys]ihi();complex [phys]tau(k); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/orghr>

=cut

sub PDL::cunghr {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccunghr if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncunghr;
}
*cunghr = \&PDL::cunghr;
#line 2840 "Complex.pm"

*__Cchseqr = \&PDL::__Cchseqr;




*__Nchseqr = \&PDL::__Nchseqr;





#line 23 "../pp_defc.pl"

=head2 chseqr

=for sig

  Signature: (complex [io,phys]H(n,n); int job();int compz();int [phys]ilo();int [phys]ihi();complex [o,phys]w(n);complex  [o,phys]Z(m,m); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/hseqr>

=cut

sub PDL::chseqr {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Cchseqr if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Nchseqr;
}
*chseqr = \&PDL::chseqr;
#line 2875 "Complex.pm"

*__Cctrevc = \&PDL::__Cctrevc;




*__Nctrevc = \&PDL::__Nctrevc;





#line 23 "../pp_defc.pl"

=head2 ctrevc

=for sig

  Signature: (complex [io]T(n,n); int side();int howmny();int select(q);complex [o]VL(m,m);complex  [o]VR(p,p);int [o]m(); int [o]info(); [t]work(workn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/trevc>

=cut

sub PDL::ctrevc {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Cctrevc if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Nctrevc;
}
*ctrevc = \&PDL::ctrevc;
#line 2910 "Complex.pm"

*__Cctgevc = \&PDL::__Cctgevc;




*__Nctgevc = \&PDL::__Nctgevc;





#line 23 "../pp_defc.pl"

=head2 ctgevc

=for sig

  Signature: (complex [io]A(n,n); int side();int howmny();complex  [io]B(n,n);int select(q);complex [o]VL(m,m);complex  [o]VR(p,p);int [o]m(); int [o]info(); [t]work(workn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/tgevc>

=cut

sub PDL::ctgevc {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Cctgevc if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Nctgevc;
}
*ctgevc = \&PDL::ctgevc;
#line 2945 "Complex.pm"

*__Ccgebal = \&PDL::__Ccgebal;




*__Ncgebal = \&PDL::__Ncgebal;





#line 23 "../pp_defc.pl"

=head2 cgebal

=for sig

  Signature: (complex [io,phys]A(n,n); int job(); int [o,phys]ilo();int [o,phys]ihi();[o,phys]scale(n); int [o,phys]info())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/gebal>

=cut

sub PDL::cgebal {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccgebal if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncgebal;
}
*cgebal = \&PDL::cgebal;
#line 2980 "Complex.pm"

*__Cclange = \&PDL::__Cclange;




*__Nclange = \&PDL::__Nclange;





#line 23 "../pp_defc.pl"

=head2 clange

=for sig

  Signature: (complex A(n,m); int norm(); [o]b(); [t]work(workn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/lange>

=cut

sub PDL::clange {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Cclange if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Nclange;
}
*clange = \&PDL::clange;
#line 3015 "Complex.pm"

*__Cclansy = \&PDL::__Cclansy;




*__Nclansy = \&PDL::__Nclansy;





#line 23 "../pp_defc.pl"

=head2 clansy

=for sig

  Signature: (complex A(n,n); int uplo(); int norm(); [o]b(); [t]work(workn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/lansy>

=cut

sub PDL::clansy {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Cclansy if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Nclansy;
}
*clansy = \&PDL::clansy;
#line 3050 "Complex.pm"

*__Cclantr = \&PDL::__Cclantr;




*__Nclantr = \&PDL::__Nclantr;





#line 23 "../pp_defc.pl"

=head2 clantr

=for sig

  Signature: (complex A(m,n); int uplo(); int norm();int diag(); [o]b(); [t]work(workn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/lantr>

=cut

sub PDL::clantr {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Cclantr if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Nclantr;
}
*clantr = \&PDL::clantr;
#line 3085 "Complex.pm"

*__Ccgemm = \&PDL::__Ccgemm;




*__Ncgemm = \&PDL::__Ncgemm;





#line 23 "../pp_defc.pl"

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
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccgemm if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncgemm;
}
*cgemm = \&PDL::cgemm;
#line 3130 "Complex.pm"

*__Ccmmult = \&PDL::__Ccmmult;




*__Ncmmult = \&PDL::__Ncmmult;





#line 23 "../pp_defc.pl"

=head2 cmmult

=for sig

  Signature: (complex [phys]A(m,n);complex  [phys]B(p,m);complex  [o,phys]C(p,n))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/mmult>

=cut

sub PDL::cmmult {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccmmult if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncmmult;
}
*cmmult = \&PDL::cmmult;
#line 3165 "Complex.pm"

*__Cccrossprod = \&PDL::__Cccrossprod;




*__Nccrossprod = \&PDL::__Nccrossprod;





#line 23 "../pp_defc.pl"

=head2 ccrossprod

=for sig

  Signature: (complex [phys]A(n,m);complex  [phys]B(p,m);complex  [o,phys]C(p,n))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/crossprod>

=cut

sub PDL::ccrossprod {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Cccrossprod if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Nccrossprod;
}
*ccrossprod = \&PDL::ccrossprod;
#line 3200 "Complex.pm"

*__Ccsyrk = \&PDL::__Ccsyrk;




*__Ncsyrk = \&PDL::__Ncsyrk;





#line 23 "../pp_defc.pl"

=head2 csyrk

=for sig

  Signature: (complex [phys]A(m,n); int uplo(); int trans();complex  [phys]alpha();complex  [phys]beta();complex  [io,phys]C(p,p))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/syrk>

=cut

sub PDL::csyrk {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccsyrk if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncsyrk;
}
*csyrk = \&PDL::csyrk;
#line 3235 "Complex.pm"

*__Ccdot = \&PDL::__Ccdot;




*__Ncdot = \&PDL::__Ncdot;





#line 23 "../pp_defc.pl"

=head2 cdot

=for sig

  Signature: (complex [phys]a(n);complex [phys]b(n);complex [o]c())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/dot>

=cut

sub PDL::cdot {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccdot if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncdot;
}
*cdot = \&PDL::cdot;
#line 3270 "Complex.pm"

*__Ccdotc = \&PDL::__Ccdotc;




*__Ncdotc = \&PDL::__Ncdotc;





#line 23 "../pp_defc.pl"

=head2 cdotc

=for sig

  Signature: (complex [phys]a(n);complex [phys]b(n);complex [o,phys]c())

=for ref

Forms the dot product of two vectors, conjugating the first   
vector.

=cut

sub PDL::cdotc {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccdotc if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncdotc;
}
*cdotc = \&PDL::cdotc;
#line 3306 "Complex.pm"

*__Ccaxpy = \&PDL::__Ccaxpy;




*__Ncaxpy = \&PDL::__Ncaxpy;





#line 23 "../pp_defc.pl"

=head2 caxpy

=for sig

  Signature: (complex [phys]a(n);complex [phys] alpha();complex [io,phys]b(n))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/axpy>

=cut

sub PDL::caxpy {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccaxpy if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncaxpy;
}
*caxpy = \&PDL::caxpy;
#line 3341 "Complex.pm"

*__Ccnrm2 = \&PDL::__Ccnrm2;




*__Ncnrm2 = \&PDL::__Ncnrm2;





#line 23 "../pp_defc.pl"

=head2 cnrm2

=for sig

  Signature: (complex [phys]a(n);[o]b())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/nrm2>

=cut

sub PDL::cnrm2 {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccnrm2 if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncnrm2;
}
*cnrm2 = \&PDL::cnrm2;
#line 3376 "Complex.pm"

*__Ccasum = \&PDL::__Ccasum;




*__Ncasum = \&PDL::__Ncasum;





#line 23 "../pp_defc.pl"

=head2 casum

=for sig

  Signature: (complex [phys]a(n);[o]b())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/asum>

=cut

sub PDL::casum {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccasum if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncasum;
}
*casum = \&PDL::casum;
#line 3411 "Complex.pm"

*__Ccscal = \&PDL::__Ccscal;




*__Ncscal = \&PDL::__Ncscal;





#line 23 "../pp_defc.pl"

=head2 cscal

=for sig

  Signature: (complex [io,phys]a(n);complex scale())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/scal>

=cut

sub PDL::cscal {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccscal if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncscal;
}
*cscal = \&PDL::cscal;
#line 3446 "Complex.pm"

*__Ccsscal = \&PDL::__Ccsscal;




*__Ncsscal = \&PDL::__Ncsscal;





#line 23 "../pp_defc.pl"

=head2 csscal

=for sig

  Signature: (complex [io,phys]a(n);scale())

=for ref

Scales a complex vector by a real constant.

=cut

sub PDL::csscal {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccsscal if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncsscal;
}
*csscal = \&PDL::csscal;
#line 3481 "Complex.pm"

*__Ccrotg = \&PDL::__Ccrotg;




*__Ncrotg = \&PDL::__Ncrotg;





#line 23 "../pp_defc.pl"

=head2 crotg

=for sig

  Signature: (complex [io,phys]a();complex [phys]b();[o,phys]c();complex  [o,phys]s())

=for ref

Complex version of L<PDL::LinearAlgebra::Real/rotg>

=cut

sub PDL::crotg {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Ccrotg if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Ncrotg;
}
*crotg = \&PDL::crotg;
#line 3516 "Complex.pm"

*__Cclacpy = \&PDL::__Cclacpy;




*__Nclacpy = \&PDL::__Nclacpy;





#line 23 "../pp_defc.pl"

=head2 clacpy

=for sig

  Signature: (complex [phys]A(m,n); int uplo();complex  [o,phys]B(p,n))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/lacpy>

=cut

sub PDL::clacpy {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Cclacpy if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Nclacpy;
}
*clacpy = \&PDL::clacpy;
#line 3551 "Complex.pm"

*__Cclaswp = \&PDL::__Cclaswp;




*__Nclaswp = \&PDL::__Nclaswp;





#line 23 "../pp_defc.pl"

=head2 claswp

=for sig

  Signature: (complex [io,phys]A(m,n); int [phys]k1(); int [phys]k2(); int [phys]ipiv(p))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/laswp>

=cut

sub PDL::claswp {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Cclaswp if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Nclaswp;
}
*claswp = \&PDL::claswp;
#line 3586 "Complex.pm"

*ctricpy = \&PDL::ctricpy;






=head2 cmstack

=for sig

  Signature: (x(c,n,m);y(c,n,p);[o]out(c,n,q))

=for ref

Combine two 3D ndarrays into a single ndarray.
This routine does backward and forward dataflow automatically.

=for bad

cmstack does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cmstack = \&PDL::cmstack;




*__Cccharpol = \&PDL::__Cccharpol;




*__Nccharpol = \&PDL::__Nccharpol;





#line 23 "../pp_defc.pl"

=head2 ccharpol

=for sig

  Signature: (A(c=2,n,n);[o]Y(c=2,n,n);[o]out(c=2,p); [t]rwork(rworkn))

=for ref

Complex version of L<PDL::LinearAlgebra::Real/charpol>

=cut

sub PDL::ccharpol {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref($_) eq 'PDL::Complex', @_) and
    (grep UNIVERSAL::isa($_, 'PDL') && !$_->type->real, @_);
  goto &PDL::__Cccharpol if grep ref($_) eq 'PDL::Complex', @_;
  goto &PDL::__Nccharpol;
}
*ccharpol = \&PDL::ccharpol;

#line 5093 "complex.pd"

=head1 AUTHOR

Copyright (C) Grégory Vanuxem 2005-2018.

This library is free software; you can redistribute it and/or modify
it under the terms of the Perl Artistic License as in the file Artistic_2
in this distribution.

=cut
#line 3666 "Complex.pm"

# Exit with OK status

1;

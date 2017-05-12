
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::LinearAlgebra::Complex;

@EXPORT_OK  = qw( PDL::PP cgesvd PDL::PP cgesdd PDL::PP cggsvd PDL::PP cgeev PDL::PP cgeevx PDL::PP cggev PDL::PP cggevx PDL::PP cgees PDL::PP cgeesx PDL::PP cgges PDL::PP cggesx PDL::PP cheev PDL::PP cheevd PDL::PP cheevx PDL::PP cheevr PDL::PP chegv PDL::PP chegvd PDL::PP chegvx PDL::PP cgesv PDL::PP cgesvx PDL::PP csysv PDL::PP csysvx PDL::PP chesv PDL::PP chesvx PDL::PP cposv PDL::PP cposvx PDL::PP cgels PDL::PP cgelsy PDL::PP cgelss PDL::PP cgelsd PDL::PP cgglse PDL::PP cggglm PDL::PP cgetrf PDL::PP cgetf2 PDL::PP csytrf PDL::PP csytf2 PDL::PP cchetrf PDL::PP chetf2 PDL::PP cpotrf PDL::PP cpotf2 PDL::PP cgetri PDL::PP csytri PDL::PP chetri PDL::PP cpotri PDL::PP ctrtri PDL::PP ctrti2 PDL::PP cgetrs PDL::PP csytrs PDL::PP chetrs PDL::PP cpotrs PDL::PP ctrtrs PDL::PP clatrs PDL::PP cgecon PDL::PP csycon PDL::PP checon PDL::PP cpocon PDL::PP ctrcon PDL::PP cgeqp3 PDL::PP cgeqrf PDL::PP cungqr PDL::PP cunmqr PDL::PP cgelqf PDL::PP cunglq PDL::PP cunmlq PDL::PP cgeqlf PDL::PP cungql PDL::PP cunmql PDL::PP cgerqf PDL::PP cungrq PDL::PP cunmrq PDL::PP ctzrzf PDL::PP cunmrz PDL::PP cgehrd PDL::PP cunghr PDL::PP chseqr PDL::PP ctrevc PDL::PP ctgevc PDL::PP cgebal PDL::PP clange PDL::PP clansy PDL::PP clantr PDL::PP cgemm PDL::PP cmmult PDL::PP ccrossprod PDL::PP csyrk PDL::PP cdot PDL::PP cdotc PDL::PP caxpy PDL::PP cnrm2 PDL::PP casum PDL::PP cscal PDL::PP sscal PDL::PP crotg PDL::PP clacpy PDL::PP claswp PDL::PP ctricpy PDL::PP cmstack PDL::PP ccharpol );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   $PDL::LinearAlgebra::Complex::VERSION = '0.12';
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::LinearAlgebra::Complex $VERSION;




use strict;
use PDL::Complex;
use PDL::LinearAlgebra::Real;

{ 
  package # hide from CPAN
    PDL;
	my $warningFlag;
  	BEGIN{
  		$warningFlag = $^W;
		$^W = 0;
	}
	use overload (
		'x'     =>  sub {UNIVERSAL::isa($_[1],'PDL::Complex') ? PDL::cmmult(PDL::Complex::r2C($_[0]), $_[1]):
								PDL::mmult($_[0], $_[1]);
				});
	BEGIN{ $^W = $warningFlag ; }	
}
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

 use PDL::Complex
 use PDL::LinearAlgebra::Complex;

 $a = r2C random (100,100);
 $s = r2C zeroes(100);
 $u = r2C zeroes(100,100);
 $v = r2C zeroes(100,100);
 $info = 0;
 $job = 0;
 cgesdd($a, $job, $info, $s , $u, $v);


=head1 DESCRIPTION

This module provides an interface to parts of the lapack library (complex numbers).
These routines accept either float or double piddles.








=head1 FUNCTIONS



=cut






=head2 cgesvd

=for sig

  Signature: ([io,phys]A(2,m,n); int jobu(); int jobvt(); [o,phys]s(r); [o,phys]U(2,p,q); [o,phys]VT(2,s,t); int [o,phys]info())



=for ref

Complex version of gesvd.

The SVD is written

 A = U * SIGMA * ConjugateTranspose(V)



=for bad

cgesvd ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cgesvd = \&PDL::cgesvd;





=head2 cgesdd

=for sig

  Signature: ([io,phys]A(2,m,n); int job(); [o,phys]s(r); [o,phys]U(2,p,q); [o,phys]VT(2,s,t); int [o,phys]info())



=for ref

Complex version of gesdd.

The SVD is written

 A = U * SIGMA * ConjugateTranspose(V)



=for bad

cgesdd ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cgesdd = \&PDL::cgesdd;





=head2 cggsvd

=for sig

  Signature: ([io,phys]A(2,m,n); int jobu(); int jobv(); int jobq(); [io,phys]B(2,p,n); int [o,phys]k(); int [o,phys]l();[o,phys]alpha(n);[o,phys]beta(n); [o,phys]U(2,q,r); [o,phys]V(2,s,t); [o,phys]Q(2,u,v); int [o,phys]iwork(n); int [o,phys]info())



=for ref

Complex version of ggsvd



=for bad

cggsvd ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cggsvd = \&PDL::cggsvd;





=head2 cgeev

=for sig

  Signature: ([phys]A(2,n,n); int jobvl(); int jobvr(); [o,phys]w(2,n); [o,phys]vl(2,m,m); [o,phys]vr(2,p,p); int [o,phys]info())



=for ref

Complex version of geev



=for bad

cgeev ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cgeev = \&PDL::cgeev;





=head2 cgeevx

=for sig

  Signature: ([io,phys]A(2,n,n);  int jobvl(); int jobvr(); int balance(); int sense(); [o,phys]w(2,n); [o,phys]vl(2,m,m); [o,phys]vr(2,p,p); int [o,phys]ilo(); int [o,phys]ihi(); [o,phys]scale(n); [o,phys]abnrm(); [o,phys]rconde(q); [o,phys]rcondv(r); int [o,phys]info())



=for ref

Complex version of geevx



=for bad

cgeevx ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cgeevx = \&PDL::cgeevx;





=head2 cggev

=for sig

  Signature: ([phys]A(2,n,n); int jobvl();int jobvr();[phys]B(2,n,n);[o,phys]alpha(2,n);[o,phys]beta(2,n);[o,phys]VL(2,m,m);[o,phys]VR(2,p,p);int [o,phys]info())



=for ref

Complex version of ggev



=for bad

cggev ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cggev = \&PDL::cggev;





=head2 cggevx

=for sig

  Signature: ([io,phys]A(2,n,n);int balanc();int jobvl();int jobvr();int sense();[io,phys]B(2,n,n);[o,phys]alpha(2,n);[o,phys]beta(2,n);[o,phys]VL(2,m,m);[o,phys]VR(2,p,p);int [o,phys]ilo();int [o,phys]ihi();[o,phys]lscale(n);[o,phys]rscale(n);[o,phys]abnrm();[o,phys]bbnrm();[o,phys]rconde(r);[o,phys]rcondv(s);int [o,phys]info())



=for ref

Complex version of ggevx



=for bad

cggevx ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cggevx = \&PDL::cggevx;





=head2 cgees

=for sig

  Signature: ([io,phys]A(2,n,n);  int jobvs(); int sort(); [o,phys]w(2,n); [o,phys]vs(2,p,p); int [o,phys]sdim(); int [o,phys]info(); SV* select_func)



=for ref

Complex version of gees

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
	



=for bad

cgees ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cgees = \&PDL::cgees;





=head2 cgeesx

=for sig

  Signature: ([io,phys]A(2,n,n);  int jobvs(); int sort(); int sense(); [o,phys]w(2,n);[o,phys]vs(2,p,p); int [o,phys]sdim(); [o,phys]rconde();[o,phys]rcondv(); int [o,phys]info(); SV* select_func)



=for ref

Complex version of geesx

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
	



=for bad

cgeesx ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cgeesx = \&PDL::cgeesx;





=head2 cgges

=for sig

  Signature: ([io,phys]A(2,n,n); int jobvsl();int jobvsr();int sort();[io,phys]B(2,n,n);[o,phys]alpha(2,n);[o,phys]beta(2,n);[o,phys]VSL(2,m,m);[o,phys]VSR(2,p,p);int [o,phys]sdim();int [o,phys]info(); SV* select_func)



=for ref

Complex version of ggees

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




=for bad

cgges ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cgges = \&PDL::cgges;





=head2 cggesx

=for sig

  Signature: ([io,phys]A(2,n,n); int jobvsl();int jobvsr();int sort();int sense();[io,phys]B(2,n,n);[o,phys]alpha(2,n);[o,phys]beta(2,n);[o,phys]VSL(2,m,m);[o,phys]VSR(2,p,p);int [o,phys]sdim();[o,phys]rconde(q);[o,phys]rcondv(r);int [o,phys]info(); SV* select_func)



=for ref

Complex version of ggeesx

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




=for bad

cggesx ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cggesx = \&PDL::cggesx;





=head2 cheev

=for sig

  Signature: ([io,phys]A(2,n,n);  int jobz(); int uplo(); [o,phys]w(n); int [o,phys]info())



=for ref

Complex version of syev for Hermitian matrix



=for bad

cheev ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cheev = \&PDL::cheev;





=head2 cheevd

=for sig

  Signature: ([io,phys]A(2,n,n);  int jobz(); int uplo(); [o,phys]w(n); int [o,phys]info())



=for ref

Complex version of syevd for Hermitian matrix



=for bad

cheevd ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cheevd = \&PDL::cheevd;





=head2 cheevx

=for sig

  Signature: ([phys]A(2,n,n);  int jobz(); int range(); int uplo(); [phys]vl(); [phys]vu(); int [phys]il(); int [phys]iu(); [phys]abstol(); int [o,phys]m(); [o,phys]w(n); [o,phys]z(2,p,q);int [o,phys]ifail(r); int [o,phys]info())



=for ref

Complex version of syevx for Hermitian matrix



=for bad

cheevx ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cheevx = \&PDL::cheevx;





=head2 cheevr

=for sig

  Signature: ([phys]A(2,n,n);  int jobz(); int range(); int uplo(); [phys]vl(); [phys]vu(); int [phys]il(); int [phys]iu(); [phys]abstol(); int [o,phys]m(); [o,phys]w(n); [o,phys]z(2,p,q);int [o,phys]isuppz(r); int [o,phys]info())



=for ref

Complex version of syevr for Hermitian matrix



=for bad

cheevr ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cheevr = \&PDL::cheevr;





=head2 chegv

=for sig

  Signature: ([io,phys]A(2,n,n);int [phys]itype();int jobz(); int uplo();[io,phys]B(2,n,n);[o,phys]w(n); int [o,phys]info())



=for ref

Complex version of sygv for Hermitian matrix



=for bad

chegv ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*chegv = \&PDL::chegv;





=head2 chegvd

=for sig

  Signature: ([io,phys]A(2,n,n);int [phys]itype();int jobz(); int uplo();[io,phys]B(2,n,n);[o,phys]w(n); int [o,phys]info())



=for ref

Complex version of sygvd for Hermitian matrix



=for bad

chegvd ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*chegvd = \&PDL::chegvd;





=head2 chegvx

=for sig

  Signature: ([io,phys]A(2,n,n);int [phys]itype();int jobz();int range(); int uplo();[io,phys]B(2,n,n);[phys]vl();[phys]vu();int [phys]il();int [phys]iu();[phys]abstol();int [o,phys]m();[o,phys]w(n); [o,phys]Z(2,p,q);int [o,phys]ifail(r);int [o,phys]info())



=for ref

Complex version of sygvx for Hermitian matrix



=for bad

chegvx ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*chegvx = \&PDL::chegvx;





=head2 cgesv

=for sig

  Signature: ([io,phys]A(2,n,n);  [io,phys]B(2,n,m); int [o,phys]ipiv(n); int [o,phys]info())



=for ref

Complex version of gesv



=for bad

cgesv ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cgesv = \&PDL::cgesv;





=head2 cgesvx

=for sig

  Signature: ([io,phys]A(2,n,n); int trans(); int fact(); [io,phys]B(2,n,m); [io,phys]af(2,n,n); int [io,phys]ipiv(n); int [io]equed(); [io,phys]r(n); [io,phys]c(n); [o,phys]X(2,n,m); [o,phys]rcond(); [o,phys]ferr(m); [o,phys]berr(m); [o,phys]rpvgrw(); int [o,phys]info())



=for ref

Complex version of gesvx.

    trans:  Specifies the form of the system of equations:
            = 0:  A * X = B     (No transpose)   
            = 1:  A' * X = B  (Transpose)   
            = 2:  A**H * X = B  (Conjugate transpose)  



=for bad

cgesvx ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cgesvx = \&PDL::cgesvx;





=head2 csysv

=for sig

  Signature: ([io,phys]A(2,n,n);  int uplo(); [io,phys]B(2,n,m); int [o,phys]ipiv(n); int [o,phys]info())



=for ref

Complex version of sysv



=for bad

csysv ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*csysv = \&PDL::csysv;





=head2 csysvx

=for sig

  Signature: ([phys]A(2,n,n); int uplo(); int fact(); [phys]B(2,n,m); [io,phys]af(2,n,n); int [io,phys]ipiv(n); [o,phys]X(2,n,m); [o,phys]rcond(); [o,phys]ferr(m); [o,phys]berr(m); int [o,phys]info())



=for ref

Complex version of sysvx



=for bad

csysvx ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*csysvx = \&PDL::csysvx;





=head2 chesv

=for sig

  Signature: ([io,phys]A(2,n,n);  int uplo(); [io,phys]B(2,n,m); int [o,phys]ipiv(n); int [o,phys]info())



=for ref

Complex version of sysv for Hermitian matrix



=for bad

chesv ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*chesv = \&PDL::chesv;





=head2 chesvx

=for sig

  Signature: ([phys]A(2,n,n); int uplo(); int fact(); [phys]B(2,n,m); [io,phys]af(2,n,n); int [io,phys]ipiv(n); [o,phys]X(2,n,m); [o,phys]rcond(); [o,phys]ferr(m); [o,phys]berr(m); int [o,phys]info())



=for ref

Complex version of sysvx for Hermitian matrix



=for bad

chesvx ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*chesvx = \&PDL::chesvx;





=head2 cposv

=for sig

  Signature: ([io,phys]A(2,n,n);  int uplo(); [io,phys]B(2,n,m); int [o,phys]info())



=for ref

Complex version of posv for Hermitian positive definite matrix



=for bad

cposv ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cposv = \&PDL::cposv;





=head2 cposvx

=for sig

  Signature: ([io,phys]A(2,n,n); int uplo(); int fact(); [io,phys]B(2,n,m); [io,phys]af(2,n,n); int [io]equed(); [io,phys]s(n); [o,phys]X(2,n,m); [o,phys]rcond(); [o,phys]ferr(m); [o,phys]berr(m); int [o,phys]info())



=for ref

Complex version of posvx for Hermitian positive definite matrix



=for bad

cposvx ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cposvx = \&PDL::cposvx;





=head2 cgels

=for sig

  Signature: ([io,phys]A(2,m,n); int trans(); [io,phys]B(2,p,q);int [o,phys]info())



=for ref

Solves overdetermined or underdetermined complex linear systems   
involving an M-by-N matrix A, or its conjugate-transpose.
Complex version of gels.

    trans:  = 0: the linear system involves A;
            = 1: the linear system involves A**H.



=for bad

cgels ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cgels = \&PDL::cgels;





=head2 cgelsy

=for sig

  Signature: ([io,phys]A(2,m,n); [io,phys]B(2,p,q); [phys]rcond(); int [io,phys]jpvt(n); int [o,phys]rank();int [o,phys]info())



=for ref

Complex version of gelsy



=for bad

cgelsy ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cgelsy = \&PDL::cgelsy;





=head2 cgelss

=for sig

  Signature: ([io,phys]A(2,m,n); [io,phys]B(2,p,q); [phys]rcond(); [o,phys]s(r); int [o,phys]rank();int [o,phys]info())



=for ref

Complex version of gelss



=for bad

cgelss ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cgelss = \&PDL::cgelss;





=head2 cgelsd

=for sig

  Signature: ([io,phys]A(2,m,n); [io,phys]B(2,p,q); [phys]rcond(); [o,phys]s(r); int [o,phys]rank();int [o,phys]info())



=for ref

Complex version of gelsd



=for bad

cgelsd ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cgelsd = \&PDL::cgelsd;





=head2 cgglse

=for sig

  Signature: ([phys]A(2,m,n); [phys]B(2,p,n);[io,phys]c(2,m);[phys]d(2,p);[o,phys]x(2,n);int [o,phys]info())



=for ref

Complex version of gglse



=for bad

cgglse ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cgglse = \&PDL::cgglse;





=head2 cggglm

=for sig

  Signature: ([phys]A(2,n,m); [phys]B(2,n,p);[phys]d(2,n);[o,phys]x(2,m);[o,phys]y(2,p);int [o,phys]info())



=for ref

Complex version of ggglm



=for bad

cggglm ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cggglm = \&PDL::cggglm;





=head2 cgetrf

=for sig

  Signature: ([io,phys]A(2,m,n); int [o,phys]ipiv(p); int [o,phys]info())



=for ref

Complex version of getrf



=for bad

cgetrf ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cgetrf = \&PDL::cgetrf;





=head2 cgetf2

=for sig

  Signature: ([io,phys]A(2,m,n); int [o,phys]ipiv(p); int [o,phys]info())



=for ref

Complex version of getf2



=for bad

cgetf2 ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cgetf2 = \&PDL::cgetf2;





=head2 csytrf

=for sig

  Signature: ([io,phys]A(2,n,n); int uplo(); int [o,phys]ipiv(n); int [o,phys]info())



=for ref

Complex version of sytrf



=for bad

csytrf ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*csytrf = \&PDL::csytrf;





=head2 csytf2

=for sig

  Signature: ([io,phys]A(2,n,n); int uplo(); int [o,phys]ipiv(n); int [o,phys]info())



=for ref

Complex version of sytf2



=for bad

csytf2 ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*csytf2 = \&PDL::csytf2;





=head2 cchetrf

=for sig

  Signature: ([io,phys]A(2,n,n); int uplo(); int [o,phys]ipiv(n); int [o,phys]info())



=for ref

Complex version of sytrf for Hermitian matrix



=for bad

cchetrf ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cchetrf = \&PDL::cchetrf;





=head2 chetf2

=for sig

  Signature: ([io,phys]A(2,n,n); int uplo(); int [o,phys]ipiv(n); int [o,phys]info())



=for ref

Complex version of sytf2 for Hermitian matrix



=for bad

chetf2 ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*chetf2 = \&PDL::chetf2;





=head2 cpotrf

=for sig

  Signature: ([io,phys]A(2,n,n); int uplo(); int [o,phys]info())



=for ref

Complex version of potrf for Hermitian positive definite matrix



=for bad

cpotrf ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cpotrf = \&PDL::cpotrf;





=head2 cpotf2

=for sig

  Signature: ([io,phys]A(2,n,n); int uplo(); int [o,phys]info())



=for ref

Complex version of potf2 for Hermitian positive definite matrix



=for bad

cpotf2 ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cpotf2 = \&PDL::cpotf2;





=head2 cgetri

=for sig

  Signature: ([io,phys]A(2,n,n); int [phys]ipiv(n); int [o,phys]info())



=for ref

Complex version of getri



=for bad

cgetri ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cgetri = \&PDL::cgetri;





=head2 csytri

=for sig

  Signature: ([io,phys]A(2,n,n); int uplo(); int [phys]ipiv(n); int [o,phys]info())



=for ref

Complex version of sytri



=for bad

csytri ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*csytri = \&PDL::csytri;





=head2 chetri

=for sig

  Signature: ([io,phys]A(2,n,n); int uplo(); int [phys]ipiv(n); int [o,phys]info())



=for ref

Complex version of sytri for Hermitian matrix



=for bad

chetri ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*chetri = \&PDL::chetri;





=head2 cpotri

=for sig

  Signature: ([io,phys]A(2,n,n); int uplo(); int [o,phys]info())



=for ref

Complex version of potri



=for bad

cpotri ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cpotri = \&PDL::cpotri;





=head2 ctrtri

=for sig

  Signature: ([io,phys]A(2,n,n); int uplo(); int diag(); int [o,phys]info())



=for ref

Complex version of trtri



=for bad

ctrtri ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ctrtri = \&PDL::ctrtri;





=head2 ctrti2

=for sig

  Signature: ([io,phys]A(2,n,n); int uplo(); int diag(); int [o,phys]info())



=for ref

Complex version of trti2



=for bad

ctrti2 ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ctrti2 = \&PDL::ctrti2;





=head2 cgetrs

=for sig

  Signature: ([phys]A(2,n,n); int trans(); [io,phys]B(2,n,m); int [phys]ipiv(n); int [o,phys]info())



=for ref

Complex version of getrs

    Arguments   
    =========   
	trans:   = 0:  No transpose;
            	 = 1:  Transpose; 
            	 = 2:  Conjugate transpose;



=for bad

cgetrs ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cgetrs = \&PDL::cgetrs;





=head2 csytrs

=for sig

  Signature: ([phys]A(2,n,n); int uplo();[io,phys]B(2,n,m); int [phys]ipiv(n); int [o,phys]info())



=for ref

Complex version of sytrs



=for bad

csytrs ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*csytrs = \&PDL::csytrs;





=head2 chetrs

=for sig

  Signature: ([phys]A(2,n,n); int uplo();[io,phys]B(2,n,m); int [phys]ipiv(n); int [o,phys]info())



=for ref

Complex version of sytrs for Hermitian matrix



=for bad

chetrs ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*chetrs = \&PDL::chetrs;





=head2 cpotrs

=for sig

  Signature: ([phys]A(2,n,n); int uplo(); [io,phys]B(2,n,m); int [o,phys]info())



=for ref

Complex version of potrs for Hermitian positive definite matrix



=for bad

cpotrs ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cpotrs = \&PDL::cpotrs;





=head2 ctrtrs

=for sig

  Signature: ([phys]A(2,n,n); int uplo(); int trans(); int diag();[io,phys]B(2,n,m); int [o,phys]info())



=for ref

Complex version of trtrs

    Arguments   
    =========   
	trans:   = 0:  No transpose;
            	 = 1:  Transpose; 
            	 = 2:  Conjugate transpose;



=for bad

ctrtrs ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ctrtrs = \&PDL::ctrtrs;





=head2 clatrs

=for sig

  Signature: ([phys]A(2,n,n); int uplo(); int trans(); int diag(); int normin();[io,phys]x(2,n); [o,phys]scale();[io,phys]cnorm(n);int [o,phys]info())



=for ref

Complex version of latrs

    Arguments   
    =========   
	trans:   = 0:  No transpose;
            	 = 1:  Transpose; 
            	 = 2:  Conjugate transpose;



=for bad

clatrs ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*clatrs = \&PDL::clatrs;





=head2 cgecon

=for sig

  Signature: ([phys]A(2,n,n); int norm(); [phys]anorm(); [o,phys]rcond();int [o,phys]info())



=for ref

Complex version of gecon



=for bad

cgecon ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cgecon = \&PDL::cgecon;





=head2 csycon

=for sig

  Signature: ([phys]A(2,n,n); int uplo(); int ipiv(n); [phys]anorm(); [o,phys]rcond();int [o,phys]info())



=for ref

Complex version of sycon



=for bad

csycon ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*csycon = \&PDL::csycon;





=head2 checon

=for sig

  Signature: ([phys]A(2,n,n); int uplo(); int ipiv(n); [phys]anorm(); [o,phys]rcond();int [o,phys]info())



=for ref

Complex version of sycon for Hermitian matrix



=for bad

checon ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*checon = \&PDL::checon;





=head2 cpocon

=for sig

  Signature: ([phys]A(2,n,n); int uplo(); [phys]anorm(); [o,phys]rcond();int [o,phys]info())



=for ref

Complex version of pocon for Hermitian positive definite matrix



=for bad

cpocon ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cpocon = \&PDL::cpocon;





=head2 ctrcon

=for sig

  Signature: ([phys]A(2,n,n); int norm();int uplo();int diag(); [o,phys]rcond();int [o,phys]info())



=for ref

Complex version of trcon



=for bad

ctrcon ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ctrcon = \&PDL::ctrcon;





=head2 cgeqp3

=for sig

  Signature: ([io,phys]A(2,m,n); int [io,phys]jpvt(n); [o,phys]tau(2,k); int [o,phys]info())



=for ref

Complex version of geqp3



=for bad

cgeqp3 ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cgeqp3 = \&PDL::cgeqp3;





=head2 cgeqrf

=for sig

  Signature: ([io,phys]A(2,m,n); [o,phys]tau(2,k); int [o,phys]info())



=for ref

Complex version of geqrf



=for bad

cgeqrf ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cgeqrf = \&PDL::cgeqrf;





=head2 cungqr

=for sig

  Signature: ([io,phys]A(2,m,n); [phys]tau(2,k); int [o,phys]info())



=for ref

Complex version of orgqr



=for bad

cungqr ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cungqr = \&PDL::cungqr;





=head2 cunmqr

=for sig

  Signature: ([phys]A(2,p,k); int side(); int trans(); [phys]tau(2,k); [io,phys]C(2,m,n);int [o,phys]info())



=for ref

Complex version of ormqr. Here trans = 1 means conjugate transpose.



=for bad

cunmqr ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cunmqr = \&PDL::cunmqr;





=head2 cgelqf

=for sig

  Signature: ([io,phys]A(2,m,n); [o,phys]tau(2,k); int [o,phys]info())



=for ref

Complex version of gelqf



=for bad

cgelqf ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cgelqf = \&PDL::cgelqf;





=head2 cunglq

=for sig

  Signature: ([io,phys]A(2,m,n); [phys]tau(2,k); int [o,phys]info())



=for ref

Complex version of orglq



=for bad

cunglq ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cunglq = \&PDL::cunglq;





=head2 cunmlq

=for sig

  Signature: ([phys]A(2,k,p); int side(); int trans(); [phys]tau(2,k); [io,phys]C(2,m,n);int [o,phys]info())



=for ref

Complex version of ormlq. Here trans = 1 means conjugate transpose.



=for bad

cunmlq ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cunmlq = \&PDL::cunmlq;





=head2 cgeqlf

=for sig

  Signature: ([io,phys]A(2,m,n); [o,phys]tau(2,k); int [o,phys]info())



=for ref

Complex version of geqlf



=for bad

cgeqlf ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cgeqlf = \&PDL::cgeqlf;





=head2 cungql

=for sig

  Signature: ([io,phys]A(2,m,n); [phys]tau(2,k); int [o,phys]info())



=for ref

Complex version of orgql.



=for bad

cungql ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cungql = \&PDL::cungql;





=head2 cunmql

=for sig

  Signature: ([phys]A(2,p,k); int side(); int trans(); [phys]tau(2,k); [io,phys]C(2,m,n);int [o,phys]info())



=for ref

Complex version of ormql. Here trans = 1 means conjugate transpose.



=for bad

cunmql ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cunmql = \&PDL::cunmql;





=head2 cgerqf

=for sig

  Signature: ([io,phys]A(2,m,n); [o,phys]tau(2,k); int [o,phys]info())



=for ref

Complex version of gerqf



=for bad

cgerqf ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cgerqf = \&PDL::cgerqf;





=head2 cungrq

=for sig

  Signature: ([io,phys]A(2,m,n); [phys]tau(2,k); int [o,phys]info())



=for ref

Complex version of orgrq.



=for bad

cungrq ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cungrq = \&PDL::cungrq;





=head2 cunmrq

=for sig

  Signature: ([phys]A(2,k,p); int side(); int trans(); [phys]tau(2,k); [io,phys]C(2,m,n);int [o,phys]info())



=for ref

Complex version of ormrq. Here trans = 1 means conjugate transpose.



=for bad

cunmrq ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cunmrq = \&PDL::cunmrq;





=head2 ctzrzf

=for sig

  Signature: ([io,phys]A(2,m,n); [o,phys]tau(2,k); int [o,phys]info())



=for ref

Complex version of tzrzf



=for bad

ctzrzf ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ctzrzf = \&PDL::ctzrzf;





=head2 cunmrz

=for sig

  Signature: ([phys]A(2,k,p); int side(); int trans(); [phys]tau(2,k); [io,phys]C(2,m,n);int [o,phys]info())



=for ref

Complex version of ormrz. Here trans = 1 means conjugate transpose.



=for bad

cunmrz ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cunmrz = \&PDL::cunmrz;





=head2 cgehrd

=for sig

  Signature: ([io,phys]A(2,n,n); int [phys]ilo();int [phys]ihi();[o,phys]tau(2,k); int [o,phys]info())



=for ref

Complex version of gehrd



=for bad

cgehrd ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cgehrd = \&PDL::cgehrd;





=head2 cunghr

=for sig

  Signature: ([io,phys]A(2,n,n); int [phys]ilo();int [phys]ihi();[phys]tau(2,k); int [o,phys]info())



=for ref

Complex version of orghr



=for bad

cunghr ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cunghr = \&PDL::cunghr;





=head2 chseqr

=for sig

  Signature: ([io,phys]H(2,n,n); int job();int compz();int [phys]ilo();int [phys]ihi();[o,phys]w(2,n); [o,phys]Z(2,m,m); int [o,phys]info())



=for ref

Complex version of hseqr



=for bad

chseqr ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*chseqr = \&PDL::chseqr;





=head2 ctrevc

=for sig

  Signature: ([io,phys]T(2,n,n); int side();int howmny();int [phys]select(q);[io,phys]VL(2,m,r); [io,phys]VR(2,p,s);int [o,phys]m(); int [o,phys]info())



=for ref

Complex version of trevc



=for bad

ctrevc ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ctrevc = \&PDL::ctrevc;





=head2 ctgevc

=for sig

  Signature: ([io,phys]A(2,n,n); int side();int howmny(); [io,phys]B(2,n,n);int [phys]select(q);[io,phys]VL(2,m,r); [io,phys]VR(2,p,s);int [o,phys]m(); int [o,phys]info())



=for ref

Complex version of tgevc



=for bad

ctgevc ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ctgevc = \&PDL::ctgevc;





=head2 cgebal

=for sig

  Signature: ([io,phys]A(2,n,n); int job(); int [o,phys]ilo();int [o,phys]ihi();[o,phys]scale(n); int [o,phys]info())



=for ref

Complex version of gebal



=for bad

cgebal ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cgebal = \&PDL::cgebal;





=head2 clange

=for sig

  Signature: ([phys]A(2,n,m); int norm(); [o]b())



=for ref

Complex version of lange



=for bad

clange ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*clange = \&PDL::clange;





=head2 clansy

=for sig

  Signature: ([phys]A(2, n,n); int uplo(); int norm(); [o]b())



=for ref

Complex version of lansy



=for bad

clansy ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*clansy = \&PDL::clansy;





=head2 clantr

=for sig

  Signature: ([phys]A(2,m,n);int uplo();int norm();int diag();[o]b())



=for ref

Complex version of lantr



=for bad

clantr ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*clantr = \&PDL::clantr;





=head2 cgemm

=for sig

  Signature: ([phys]A(2,m,n); int transa(); int transb(); [phys]B(2,p,q);[phys]alpha(2); [phys]beta(2); [io,phys]C(2,r,s))



=for ref

Complex version of gemm. 

    Arguments   
    =========   
	transa:  = 0:  No transpose;
            	 = 1:  Transpose; 
            	 = 2:  Conjugate transpose;

	transb:  = 0:  No transpose;
            	 = 1:  Transpose; 
            	 = 2:  Conjugate transpose;



=for bad

cgemm ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cgemm = \&PDL::cgemm;





=head2 cmmult

=for sig

  Signature: ([phys]A(2,m,n); [phys]B(2,p,m); [o,phys]C(2,p,n))



=for ref

Complex version of mmult



=for bad

cmmult ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cmmult = \&PDL::cmmult;





=head2 ccrossprod

=for sig

  Signature: ([phys]A(2,n,m); [phys]B(2,p,m); [o,phys]C(2,p,n))



=for ref

Complex version of crossprod



=for bad

ccrossprod ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ccrossprod = \&PDL::ccrossprod;





=head2 csyrk

=for sig

  Signature: ([phys]A(2,m,n); int uplo(); int trans(); [phys]alpha(2); [phys]beta(2); [io,phys]C(2,p,p))



=for ref

Complex version of syrk



=for bad

csyrk ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*csyrk = \&PDL::csyrk;





=head2 cdot

=for sig

  Signature: ([phys]a(2,n);int [phys]inca();[phys]b(2,n);int [phys]incb();[o,phys]c(2))



=for ref

Complex version of dot



=for bad

cdot ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cdot = \&PDL::cdot;





=head2 cdotc

=for sig

  Signature: ([phys]a(2,n);int [phys]inca();[phys]b(2,n);int [phys]incb();[o,phys]c(2))



=for ref

Forms the dot product of two vectors, conjugating the first   
vector.



=for bad

cdotc ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cdotc = \&PDL::cdotc;





=head2 caxpy

=for sig

  Signature: ([phys]a(2,n);int [phys]inca();[phys] alpha(2);[io,phys]b(2,n);int [phys]incb())



=for ref

Complex version of axpy



=for bad

caxpy ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*caxpy = \&PDL::caxpy;





=head2 cnrm2

=for sig

  Signature: ([phys]a(2,n);int [phys]inca();[o,phys]b())



=for ref

Complex version of nrm2



=for bad

cnrm2 ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cnrm2 = \&PDL::cnrm2;





=head2 casum

=for sig

  Signature: ([phys]a(2,n);int [phys]inca();[o,phys]b())



=for ref

Complex version of asum



=for bad

casum ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*casum = \&PDL::casum;





=head2 cscal

=for sig

  Signature: ([io,phys]a(2,n);int [phys]inca();[phys]scale(2))



=for ref

Complex version of scal



=for bad

cscal ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cscal = \&PDL::cscal;





=head2 sscal

=for sig

  Signature: ([io,phys]a(2,n);int [phys]inca();[phys]scale())



=for ref

Scales a complex vector by a real constant.



=for bad

sscal ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*sscal = \&PDL::sscal;





=head2 crotg

=for sig

  Signature: ([io,phys]a(2);[phys]b(2);[o,phys]c(); [o,phys]s(2))



=for ref

Complex version of rotg



=for bad

crotg ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*crotg = \&PDL::crotg;





=head2 clacpy

=for sig

  Signature: ([phys]A(2,m,n); int uplo(); [o,phys]B(2,p,n))



=for ref

Complex version of lacpy



=for bad

clacpy ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*clacpy = \&PDL::clacpy;





=head2 claswp

=for sig

  Signature: ([io,phys]A(2,m,n); int [phys]k1(); int [phys]k2(); int [phys]ipiv(p);int [phys]inc())



=for ref

Complex version of laswp



=for bad

claswp ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*claswp = \&PDL::claswp;





=head2 ctricpy

=for sig

  Signature: (A(c=2,m,n);int uplo();[o] C(c=2,m,n))


=for ref

Copy triangular part to another matrix. If uplo == 0 copy upper triangular part.



=for bad

ctricpy does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ctricpy = \&PDL::ctricpy;





=head2 cmstack

=for sig

  Signature: (x(c,n,m);y(c,n,p);[o]out(c,n,q))


=for ref

Combine two 3D piddles into a single piddle.
This routine does backward and forward dataflow automatically.



=for bad

cmstack does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cmstack = \&PDL::cmstack;





=head2 ccharpol

=for sig

  Signature: ([phys]A(c=2,n,n);[phys,o]Y(c=2,n,n);[phys,o]out(c=2,p))



=for ref

Complex version of charpol



=for bad

ccharpol does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ccharpol = \&PDL::ccharpol;



;


=head1 AUTHOR

Copyright (C) Grégory Vanuxem 2005-2007.

This library is free software; you can redistribute it and/or modify
it under the terms of the artistic license as specified in the Artistic
file.

=cut





# Exit with OK status

1;

		   
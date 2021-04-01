
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::LinearAlgebra::Complex;

our @EXPORT_OK = qw(PDL::PP __Ccgtsv PDL::PP __Ncgtsv cgtsv PDL::PP __Ccgesvd PDL::PP __Ncgesvd cgesvd PDL::PP __Ccgesdd PDL::PP __Ncgesdd cgesdd PDL::PP __Ccggsvd PDL::PP __Ncggsvd cggsvd PDL::PP __Ccgeev PDL::PP __Ncgeev cgeev PDL::PP __Ccgeevx PDL::PP __Ncgeevx cgeevx PDL::PP __Ccggev PDL::PP __Ncggev cggev PDL::PP __Ccggevx PDL::PP __Ncggevx cggevx PDL::PP __Ccgees PDL::PP __Ncgees cgees PDL::PP __Ccgeesx PDL::PP __Ncgeesx cgeesx PDL::PP __Ccgges PDL::PP __Ncgges cgges PDL::PP __Ccggesx PDL::PP __Ncggesx cggesx PDL::PP __Ccheev PDL::PP __Ncheev cheev PDL::PP __Ccheevd PDL::PP __Ncheevd cheevd PDL::PP __Ccheevx PDL::PP __Ncheevx cheevx PDL::PP __Ccheevr PDL::PP __Ncheevr cheevr PDL::PP __Cchegv PDL::PP __Nchegv chegv PDL::PP __Cchegvd PDL::PP __Nchegvd chegvd PDL::PP __Cchegvx PDL::PP __Nchegvx chegvx PDL::PP __Ccgesv PDL::PP __Ncgesv cgesv PDL::PP __Ccgesvx PDL::PP __Ncgesvx cgesvx PDL::PP __Ccsysv PDL::PP __Ncsysv csysv PDL::PP __Ccsysvx PDL::PP __Ncsysvx csysvx PDL::PP __Cchesv PDL::PP __Nchesv chesv PDL::PP __Cchesvx PDL::PP __Nchesvx chesvx PDL::PP __Ccposv PDL::PP __Ncposv cposv PDL::PP __Ccposvx PDL::PP __Ncposvx cposvx PDL::PP __Ccgels PDL::PP __Ncgels cgels PDL::PP __Ccgelsy PDL::PP __Ncgelsy cgelsy PDL::PP __Ccgelss PDL::PP __Ncgelss cgelss PDL::PP __Ccgelsd PDL::PP __Ncgelsd cgelsd PDL::PP __Ccgglse PDL::PP __Ncgglse cgglse PDL::PP __Ccggglm PDL::PP __Ncggglm cggglm PDL::PP __Ccgetrf PDL::PP __Ncgetrf cgetrf PDL::PP __Ccgetf2 PDL::PP __Ncgetf2 cgetf2 PDL::PP __Ccsytrf PDL::PP __Ncsytrf csytrf PDL::PP __Ccsytf2 PDL::PP __Ncsytf2 csytf2 PDL::PP __Ccchetrf PDL::PP __Ncchetrf cchetrf PDL::PP __Cchetf2 PDL::PP __Nchetf2 chetf2 PDL::PP __Ccpotrf PDL::PP __Ncpotrf cpotrf PDL::PP __Ccpotf2 PDL::PP __Ncpotf2 cpotf2 PDL::PP __Ccgetri PDL::PP __Ncgetri cgetri PDL::PP __Ccsytri PDL::PP __Ncsytri csytri PDL::PP __Cchetri PDL::PP __Nchetri chetri PDL::PP __Ccpotri PDL::PP __Ncpotri cpotri PDL::PP __Cctrtri PDL::PP __Nctrtri ctrtri PDL::PP __Cctrti2 PDL::PP __Nctrti2 ctrti2 PDL::PP __Ccgetrs PDL::PP __Ncgetrs cgetrs PDL::PP __Ccsytrs PDL::PP __Ncsytrs csytrs PDL::PP __Cchetrs PDL::PP __Nchetrs chetrs PDL::PP __Ccpotrs PDL::PP __Ncpotrs cpotrs PDL::PP __Cctrtrs PDL::PP __Nctrtrs ctrtrs PDL::PP __Cclatrs PDL::PP __Nclatrs clatrs PDL::PP __Ccgecon PDL::PP __Ncgecon cgecon PDL::PP __Ccsycon PDL::PP __Ncsycon csycon PDL::PP __Cchecon PDL::PP __Nchecon checon PDL::PP __Ccpocon PDL::PP __Ncpocon cpocon PDL::PP __Cctrcon PDL::PP __Nctrcon ctrcon PDL::PP __Ccgeqp3 PDL::PP __Ncgeqp3 cgeqp3 PDL::PP __Ccgeqrf PDL::PP __Ncgeqrf cgeqrf PDL::PP __Ccungqr PDL::PP __Ncungqr cungqr PDL::PP __Ccunmqr PDL::PP __Ncunmqr cunmqr PDL::PP __Ccgelqf PDL::PP __Ncgelqf cgelqf PDL::PP __Ccunglq PDL::PP __Ncunglq cunglq PDL::PP __Ccunmlq PDL::PP __Ncunmlq cunmlq PDL::PP __Ccgeqlf PDL::PP __Ncgeqlf cgeqlf PDL::PP __Ccungql PDL::PP __Ncungql cungql PDL::PP __Ccunmql PDL::PP __Ncunmql cunmql PDL::PP __Ccgerqf PDL::PP __Ncgerqf cgerqf PDL::PP __Ccungrq PDL::PP __Ncungrq cungrq PDL::PP __Ccunmrq PDL::PP __Ncunmrq cunmrq PDL::PP __Cctzrzf PDL::PP __Nctzrzf ctzrzf PDL::PP __Ccunmrz PDL::PP __Ncunmrz cunmrz PDL::PP __Ccgehrd PDL::PP __Ncgehrd cgehrd PDL::PP __Ccunghr PDL::PP __Ncunghr cunghr PDL::PP __Cchseqr PDL::PP __Nchseqr chseqr PDL::PP __Cctrevc PDL::PP __Nctrevc ctrevc PDL::PP __Cctgevc PDL::PP __Nctgevc ctgevc PDL::PP __Ccgebal PDL::PP __Ncgebal cgebal PDL::PP __Cclange PDL::PP __Nclange clange PDL::PP __Cclansy PDL::PP __Nclansy clansy PDL::PP __Cclantr PDL::PP __Nclantr clantr PDL::PP __Ccgemm PDL::PP __Ncgemm cgemm PDL::PP __Ccmmult PDL::PP __Ncmmult cmmult PDL::PP __Cccrossprod PDL::PP __Nccrossprod ccrossprod PDL::PP __Ccsyrk PDL::PP __Ncsyrk csyrk PDL::PP __Ccdot PDL::PP __Ncdot cdot PDL::PP __Ccdotc PDL::PP __Ncdotc cdotc PDL::PP __Ccaxpy PDL::PP __Ncaxpy caxpy PDL::PP __Ccnrm2 PDL::PP __Ncnrm2 cnrm2 PDL::PP __Ccasum PDL::PP __Ncasum casum PDL::PP __Ccscal PDL::PP __Ncscal cscal PDL::PP sscal PDL::PP __Ccrotg PDL::PP __Ncrotg crotg PDL::PP __Cclacpy PDL::PP __Nclacpy clacpy PDL::PP __Cclaswp PDL::PP __Nclaswp claswp PDL::PP ctricpy PDL::PP cmstack PDL::PP __Cccharpol PDL::PP __Nccharpol ccharpol );
our %EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   our $VERSION = '0.14';
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
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

 # or, using native complex numbers:
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
These routines accept either float or double piddles.







=head1 FUNCTIONS



=cut






*__Ccgtsv = \&PDL::__Ccgtsv;





*__Ncgtsv = \&PDL::__Ncgtsv;



=head2 cgtsv

=for sig

  Signature: ([phys]DL(2,n); [phys]D(2,n); [phys]DU(2,n); [io,phys]B(2,n,nrhs); int [o,phys]info())



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

 use PDL::Complex;
 $dl = random(float, 9) + random(float, 9) * i;
 $d = random(float, 10) + random(float, 10) * i;
 $du = random(float, 9) + random(float, 9) * i;
 $b = random(10,5) + random(10,5) * i;
 cgtsv($dl, $d, $du, $b, ($info=null));
 print "X is:\n$b" unless $info;



=cut

sub PDL::cgtsv {
  $_[0]->type->real ? goto &PDL::__Ccgtsv : goto &PDL::__Ncgtsv;
}
*cgtsv = \&PDL::cgtsv;





*__Ccgesvd = \&PDL::__Ccgesvd;





*__Ncgesvd = \&PDL::__Ncgesvd;



=head2 cgesvd

=for sig

  Signature: ([io,phys]A(2,m,n); int jobu(); int jobvt(); [o,phys]s(r); [o,phys]U(2,p,q); [o,phys]VT(2,s,t); int [o,phys]info())



=for ref

Complex version of gesvd.

The SVD is written

 A = U * SIGMA * ConjugateTranspose(V)



=cut

sub PDL::cgesvd {
  $_[0]->type->real ? goto &PDL::__Ccgesvd : goto &PDL::__Ncgesvd;
}
*cgesvd = \&PDL::cgesvd;





*__Ccgesdd = \&PDL::__Ccgesdd;





*__Ncgesdd = \&PDL::__Ncgesdd;



=head2 cgesdd

=for sig

  Signature: ([io,phys]A(2,m,n); int job(); [o,phys]s(r); [o,phys]U(2,p,q); [o,phys]VT(2,s,t); int [o,phys]info())



=for ref

Complex version of gesdd.

The SVD is written

 A = U * SIGMA * ConjugateTranspose(V)



=cut

sub PDL::cgesdd {
  $_[0]->type->real ? goto &PDL::__Ccgesdd : goto &PDL::__Ncgesdd;
}
*cgesdd = \&PDL::cgesdd;





*__Ccggsvd = \&PDL::__Ccggsvd;





*__Ncggsvd = \&PDL::__Ncggsvd;



=head2 cggsvd

=for sig

  Signature: ([io,phys]A(2,m,n); int jobu(); int jobv(); int jobq(); [io,phys]B(2,p,n); int [o,phys]k(); int [o,phys]l();[o,phys]alpha(n);[o,phys]beta(n); [o,phys]U(2,q,r); [o,phys]V(2,s,t); [o,phys]Q(2,u,v); int [o,phys]iwork(n); int [o,phys]info())


=for ref

Complex version of ggsvd



=cut

sub PDL::cggsvd {
  $_[0]->type->real ? goto &PDL::__Ccggsvd : goto &PDL::__Ncggsvd;
}
*cggsvd = \&PDL::cggsvd;





*__Ccgeev = \&PDL::__Ccgeev;





*__Ncgeev = \&PDL::__Ncgeev;



=head2 cgeev

=for sig

  Signature: ([phys]A(2,n,n); int jobvl(); int jobvr(); [o,phys]w(2,n); [o,phys]vl(2,m,m); [o,phys]vr(2,p,p); int [o,phys]info())


=for ref

Complex version of geev



=cut

sub PDL::cgeev {
  $_[0]->type->real ? goto &PDL::__Ccgeev : goto &PDL::__Ncgeev;
}
*cgeev = \&PDL::cgeev;





*__Ccgeevx = \&PDL::__Ccgeevx;





*__Ncgeevx = \&PDL::__Ncgeevx;



=head2 cgeevx

=for sig

  Signature: ([io,phys]A(2,n,n);  int jobvl(); int jobvr(); int balance(); int sense(); [o,phys]w(2,n); [o,phys]vl(2,m,m); [o,phys]vr(2,p,p); int [o,phys]ilo(); int [o,phys]ihi(); [o,phys]scale(n); [o,phys]abnrm(); [o,phys]rconde(q); [o,phys]rcondv(r); int [o,phys]info())


=for ref

Complex version of geevx



=cut

sub PDL::cgeevx {
  $_[0]->type->real ? goto &PDL::__Ccgeevx : goto &PDL::__Ncgeevx;
}
*cgeevx = \&PDL::cgeevx;





*__Ccggev = \&PDL::__Ccggev;





*__Ncggev = \&PDL::__Ncggev;



=head2 cggev

=for sig

  Signature: ([phys]A(2,n,n); int jobvl();int jobvr();[phys]B(2,n,n);[o,phys]alpha(2,n);[o,phys]beta(2,n);[o,phys]VL(2,m,m);[o,phys]VR(2,p,p);int [o,phys]info())


=for ref

Complex version of ggev



=cut

sub PDL::cggev {
  $_[0]->type->real ? goto &PDL::__Ccggev : goto &PDL::__Ncggev;
}
*cggev = \&PDL::cggev;





*__Ccggevx = \&PDL::__Ccggevx;





*__Ncggevx = \&PDL::__Ncggevx;



=head2 cggevx

=for sig

  Signature: ([io,phys]A(2,n,n);int balanc();int jobvl();int jobvr();int sense();[io,phys]B(2,n,n);[o,phys]alpha(2,n);[o,phys]beta(2,n);[o,phys]VL(2,m,m);[o,phys]VR(2,p,p);int [o,phys]ilo();int [o,phys]ihi();[o,phys]lscale(n);[o,phys]rscale(n);[o,phys]abnrm();[o,phys]bbnrm();[o,phys]rconde(r);[o,phys]rcondv(s);int [o,phys]info())


=for ref

Complex version of ggevx



=cut

sub PDL::cggevx {
  $_[0]->type->real ? goto &PDL::__Ccggevx : goto &PDL::__Ncggevx;
}
*cggevx = \&PDL::cggevx;





*__Ccgees = \&PDL::__Ccgees;





*__Ncgees = \&PDL::__Ncgees;



=head2 cgees

=for sig

  Signature: ([io,phys]A(2,n,n);  int jobvs(); int sort(); [o,phys]w(2,n); [o,phys]vs(2,p,p); int [o,phys]sdim(); int [o,phys]info())



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
	



=cut

sub PDL::cgees {
  $_[0]->type->real ? goto &PDL::__Ccgees : goto &PDL::__Ncgees;
}
*cgees = \&PDL::cgees;





*__Ccgeesx = \&PDL::__Ccgeesx;





*__Ncgeesx = \&PDL::__Ncgeesx;



=head2 cgeesx

=for sig

  Signature: ([io,phys]A(2,n,n);  int jobvs(); int sort(); int sense(); [o,phys]w(2,n);[o,phys]vs(2,p,p); int [o,phys]sdim(); [o,phys]rconde();[o,phys]rcondv(); int [o,phys]info())



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
	



=cut

sub PDL::cgeesx {
  $_[0]->type->real ? goto &PDL::__Ccgeesx : goto &PDL::__Ncgeesx;
}
*cgeesx = \&PDL::cgeesx;





*__Ccgges = \&PDL::__Ccgges;





*__Ncgges = \&PDL::__Ncgges;



=head2 cgges

=for sig

  Signature: ([io,phys]A(2,n,n); int jobvsl();int jobvsr();int sort();[io,phys]B(2,n,n);[o,phys]alpha(2,n);[o,phys]beta(2,n);[o,phys]VSL(2,m,m);[o,phys]VSR(2,p,p);int [o,phys]sdim();int [o,phys]info())



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




=cut

sub PDL::cgges {
  $_[0]->type->real ? goto &PDL::__Ccgges : goto &PDL::__Ncgges;
}
*cgges = \&PDL::cgges;





*__Ccggesx = \&PDL::__Ccggesx;





*__Ncggesx = \&PDL::__Ncggesx;



=head2 cggesx

=for sig

  Signature: ([io,phys]A(2,n,n); int jobvsl();int jobvsr();int sort();int sense();[io,phys]B(2,n,n);[o,phys]alpha(2,n);[o,phys]beta(2,n);[o,phys]VSL(2,m,m);[o,phys]VSR(2,p,p);int [o,phys]sdim();[o,phys]rconde(q);[o,phys]rcondv(r);int [o,phys]info())



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




=cut

sub PDL::cggesx {
  $_[0]->type->real ? goto &PDL::__Ccggesx : goto &PDL::__Ncggesx;
}
*cggesx = \&PDL::cggesx;





*__Ccheev = \&PDL::__Ccheev;





*__Ncheev = \&PDL::__Ncheev;



=head2 cheev

=for sig

  Signature: ([io,phys]A(2,n,n);  int jobz(); int uplo(); [o,phys]w(n); int [o,phys]info())



=for ref

Complex version of syev for Hermitian matrix



=cut

sub PDL::cheev {
  $_[0]->type->real ? goto &PDL::__Ccheev : goto &PDL::__Ncheev;
}
*cheev = \&PDL::cheev;





*__Ccheevd = \&PDL::__Ccheevd;





*__Ncheevd = \&PDL::__Ncheevd;



=head2 cheevd

=for sig

  Signature: ([io,phys]A(2,n,n);  int jobz(); int uplo(); [o,phys]w(n); int [o,phys]info())



=for ref

Complex version of syevd for Hermitian matrix



=cut

sub PDL::cheevd {
  $_[0]->type->real ? goto &PDL::__Ccheevd : goto &PDL::__Ncheevd;
}
*cheevd = \&PDL::cheevd;





*__Ccheevx = \&PDL::__Ccheevx;





*__Ncheevx = \&PDL::__Ncheevx;



=head2 cheevx

=for sig

  Signature: ([phys]A(2,n,n);  int jobz(); int range(); int uplo(); [phys]vl(); [phys]vu(); int [phys]il(); int [phys]iu(); [phys]abstol(); int [o,phys]m(); [o,phys]w(n); [o,phys]z(2,p,q);int [o,phys]ifail(r); int [o,phys]info())



=for ref

Complex version of syevx for Hermitian matrix



=cut

sub PDL::cheevx {
  $_[0]->type->real ? goto &PDL::__Ccheevx : goto &PDL::__Ncheevx;
}
*cheevx = \&PDL::cheevx;





*__Ccheevr = \&PDL::__Ccheevr;





*__Ncheevr = \&PDL::__Ncheevr;



=head2 cheevr

=for sig

  Signature: ([phys]A(2,n,n);  int jobz(); int range(); int uplo(); [phys]vl(); [phys]vu(); int [phys]il(); int [phys]iu(); [phys]abstol(); int [o,phys]m(); [o,phys]w(n); [o,phys]z(2,p,q);int [o,phys]isuppz(r); int [o,phys]info())



=for ref

Complex version of syevr for Hermitian matrix



=cut

sub PDL::cheevr {
  $_[0]->type->real ? goto &PDL::__Ccheevr : goto &PDL::__Ncheevr;
}
*cheevr = \&PDL::cheevr;





*__Cchegv = \&PDL::__Cchegv;





*__Nchegv = \&PDL::__Nchegv;



=head2 chegv

=for sig

  Signature: ([io,phys]A(2,n,n);int [phys]itype();int jobz(); int uplo();[io,phys]B(2,n,n);[o,phys]w(n); int [o,phys]info())



=for ref

Complex version of sygv for Hermitian matrix



=cut

sub PDL::chegv {
  $_[0]->type->real ? goto &PDL::__Cchegv : goto &PDL::__Nchegv;
}
*chegv = \&PDL::chegv;





*__Cchegvd = \&PDL::__Cchegvd;





*__Nchegvd = \&PDL::__Nchegvd;



=head2 chegvd

=for sig

  Signature: ([io,phys]A(2,n,n);int [phys]itype();int jobz(); int uplo();[io,phys]B(2,n,n);[o,phys]w(n); int [o,phys]info())



=for ref

Complex version of sygvd for Hermitian matrix



=cut

sub PDL::chegvd {
  $_[0]->type->real ? goto &PDL::__Cchegvd : goto &PDL::__Nchegvd;
}
*chegvd = \&PDL::chegvd;





*__Cchegvx = \&PDL::__Cchegvx;





*__Nchegvx = \&PDL::__Nchegvx;



=head2 chegvx

=for sig

  Signature: ([io,phys]A(2,n,n);int [phys]itype();int jobz();int range(); int uplo();[io,phys]B(2,n,n);[phys]vl();[phys]vu();int [phys]il();int [phys]iu();[phys]abstol();int [o,phys]m();[o,phys]w(n); [o,phys]Z(2,p,q);int [o,phys]ifail(r);int [o,phys]info())



=for ref

Complex version of sygvx for Hermitian matrix



=cut

sub PDL::chegvx {
  $_[0]->type->real ? goto &PDL::__Cchegvx : goto &PDL::__Nchegvx;
}
*chegvx = \&PDL::chegvx;





*__Ccgesv = \&PDL::__Ccgesv;





*__Ncgesv = \&PDL::__Ncgesv;



=head2 cgesv

=for sig

  Signature: ([io,phys]A(2,n,n);  [io,phys]B(2,n,m); int [o,phys]ipiv(n); int [o,phys]info())


=for ref

Complex version of gesv



=cut

sub PDL::cgesv {
  $_[0]->type->real ? goto &PDL::__Ccgesv : goto &PDL::__Ncgesv;
}
*cgesv = \&PDL::cgesv;





*__Ccgesvx = \&PDL::__Ccgesvx;





*__Ncgesvx = \&PDL::__Ncgesvx;



=head2 cgesvx

=for sig

  Signature: ([io,phys]A(2,n,n); int trans(); int fact(); [io,phys]B(2,n,m); [io,phys]af(2,n,n); int [io,phys]ipiv(n); int [io]equed(); [io,phys]r(n); [io,phys]c(n); [o,phys]X(2,n,m); [o,phys]rcond(); [o,phys]ferr(m); [o,phys]berr(m); [o,phys]rpvgrw(); int [o,phys]info())



=for ref

Complex version of gesvx.

    trans:  Specifies the form of the system of equations:
            = 0:  A * X = B     (No transpose)   
            = 1:  A' * X = B  (Transpose)   
            = 2:  A**H * X = B  (Conjugate transpose)  



=cut

sub PDL::cgesvx {
  $_[0]->type->real ? goto &PDL::__Ccgesvx : goto &PDL::__Ncgesvx;
}
*cgesvx = \&PDL::cgesvx;





*__Ccsysv = \&PDL::__Ccsysv;





*__Ncsysv = \&PDL::__Ncsysv;



=head2 csysv

=for sig

  Signature: ([io,phys]A(2,n,n);  int uplo(); [io,phys]B(2,n,m); int [o,phys]ipiv(n); int [o,phys]info())


=for ref

Complex version of sysv



=cut

sub PDL::csysv {
  $_[0]->type->real ? goto &PDL::__Ccsysv : goto &PDL::__Ncsysv;
}
*csysv = \&PDL::csysv;





*__Ccsysvx = \&PDL::__Ccsysvx;





*__Ncsysvx = \&PDL::__Ncsysvx;



=head2 csysvx

=for sig

  Signature: ([phys]A(2,n,n); int uplo(); int fact(); [phys]B(2,n,m); [io,phys]af(2,n,n); int [io,phys]ipiv(n); [o,phys]X(2,n,m); [o,phys]rcond(); [o,phys]ferr(m); [o,phys]berr(m); int [o,phys]info())


=for ref

Complex version of sysvx



=cut

sub PDL::csysvx {
  $_[0]->type->real ? goto &PDL::__Ccsysvx : goto &PDL::__Ncsysvx;
}
*csysvx = \&PDL::csysvx;





*__Cchesv = \&PDL::__Cchesv;





*__Nchesv = \&PDL::__Nchesv;



=head2 chesv

=for sig

  Signature: ([io,phys]A(2,n,n);  int uplo(); [io,phys]B(2,n,m); int [o,phys]ipiv(n); int [o,phys]info())



=for ref

Complex version of sysv for Hermitian matrix



=cut

sub PDL::chesv {
  $_[0]->type->real ? goto &PDL::__Cchesv : goto &PDL::__Nchesv;
}
*chesv = \&PDL::chesv;





*__Cchesvx = \&PDL::__Cchesvx;





*__Nchesvx = \&PDL::__Nchesvx;



=head2 chesvx

=for sig

  Signature: ([phys]A(2,n,n); int uplo(); int fact(); [phys]B(2,n,m); [io,phys]af(2,n,n); int [io,phys]ipiv(n); [o,phys]X(2,n,m); [o,phys]rcond(); [o,phys]ferr(m); [o,phys]berr(m); int [o,phys]info())



=for ref

Complex version of sysvx for Hermitian matrix



=cut

sub PDL::chesvx {
  $_[0]->type->real ? goto &PDL::__Cchesvx : goto &PDL::__Nchesvx;
}
*chesvx = \&PDL::chesvx;





*__Ccposv = \&PDL::__Ccposv;





*__Ncposv = \&PDL::__Ncposv;



=head2 cposv

=for sig

  Signature: ([io,phys]A(2,n,n);  int uplo(); [io,phys]B(2,n,m); int [o,phys]info())



=for ref

Complex version of posv for Hermitian positive definite matrix



=cut

sub PDL::cposv {
  $_[0]->type->real ? goto &PDL::__Ccposv : goto &PDL::__Ncposv;
}
*cposv = \&PDL::cposv;





*__Ccposvx = \&PDL::__Ccposvx;





*__Ncposvx = \&PDL::__Ncposvx;



=head2 cposvx

=for sig

  Signature: ([io,phys]A(2,n,n); int uplo(); int fact(); [io,phys]B(2,n,m); [io,phys]af(2,n,n); int [io]equed(); [io,phys]s(n); [o,phys]X(2,n,m); [o,phys]rcond(); [o,phys]ferr(m); [o,phys]berr(m); int [o,phys]info())



=for ref

Complex version of posvx for Hermitian positive definite matrix



=cut

sub PDL::cposvx {
  $_[0]->type->real ? goto &PDL::__Ccposvx : goto &PDL::__Ncposvx;
}
*cposvx = \&PDL::cposvx;





*__Ccgels = \&PDL::__Ccgels;





*__Ncgels = \&PDL::__Ncgels;



=head2 cgels

=for sig

  Signature: ([io,phys]A(2,m,n); int trans(); [io,phys]B(2,p,q);int [o,phys]info())



=for ref

Solves overdetermined or underdetermined complex linear systems   
involving an M-by-N matrix A, or its conjugate-transpose.
Complex version of gels.

    trans:  = 0: the linear system involves A;
            = 1: the linear system involves A**H.



=cut

sub PDL::cgels {
  $_[0]->type->real ? goto &PDL::__Ccgels : goto &PDL::__Ncgels;
}
*cgels = \&PDL::cgels;





*__Ccgelsy = \&PDL::__Ccgelsy;





*__Ncgelsy = \&PDL::__Ncgelsy;



=head2 cgelsy

=for sig

  Signature: ([io,phys]A(2,m,n); [io,phys]B(2,p,q); [phys]rcond(); int [io,phys]jpvt(n); int [o,phys]rank();int [o,phys]info())


=for ref

Complex version of gelsy



=cut

sub PDL::cgelsy {
  $_[0]->type->real ? goto &PDL::__Ccgelsy : goto &PDL::__Ncgelsy;
}
*cgelsy = \&PDL::cgelsy;





*__Ccgelss = \&PDL::__Ccgelss;





*__Ncgelss = \&PDL::__Ncgelss;



=head2 cgelss

=for sig

  Signature: ([io,phys]A(2,m,n); [io,phys]B(2,p,q); [phys]rcond(); [o,phys]s(r); int [o,phys]rank();int [o,phys]info())


=for ref

Complex version of gelss



=cut

sub PDL::cgelss {
  $_[0]->type->real ? goto &PDL::__Ccgelss : goto &PDL::__Ncgelss;
}
*cgelss = \&PDL::cgelss;





*__Ccgelsd = \&PDL::__Ccgelsd;





*__Ncgelsd = \&PDL::__Ncgelsd;



=head2 cgelsd

=for sig

  Signature: ([io,phys]A(2,m,n); [io,phys]B(2,p,q); [phys]rcond(); [o,phys]s(r); int [o,phys]rank();int [o,phys]info())


=for ref

Complex version of gelsd



=cut

sub PDL::cgelsd {
  $_[0]->type->real ? goto &PDL::__Ccgelsd : goto &PDL::__Ncgelsd;
}
*cgelsd = \&PDL::cgelsd;





*__Ccgglse = \&PDL::__Ccgglse;





*__Ncgglse = \&PDL::__Ncgglse;



=head2 cgglse

=for sig

  Signature: ([phys]A(2,m,n); [phys]B(2,p,n);[io,phys]c(2,m);[phys]d(2,p);[o,phys]x(2,n);int [o,phys]info())


=for ref

Complex version of gglse



=cut

sub PDL::cgglse {
  $_[0]->type->real ? goto &PDL::__Ccgglse : goto &PDL::__Ncgglse;
}
*cgglse = \&PDL::cgglse;





*__Ccggglm = \&PDL::__Ccggglm;





*__Ncggglm = \&PDL::__Ncggglm;



=head2 cggglm

=for sig

  Signature: ([phys]A(2,n,m); [phys]B(2,n,p);[phys]d(2,n);[o,phys]x(2,m);[o,phys]y(2,p);int [o,phys]info())


=for ref

Complex version of ggglm



=cut

sub PDL::cggglm {
  $_[0]->type->real ? goto &PDL::__Ccggglm : goto &PDL::__Ncggglm;
}
*cggglm = \&PDL::cggglm;





*__Ccgetrf = \&PDL::__Ccgetrf;





*__Ncgetrf = \&PDL::__Ncgetrf;



=head2 cgetrf

=for sig

  Signature: ([io,phys]A(2,m,n); int [o,phys]ipiv(p); int [o,phys]info())


=for ref

Complex version of getrf



=cut

sub PDL::cgetrf {
  $_[0]->type->real ? goto &PDL::__Ccgetrf : goto &PDL::__Ncgetrf;
}
*cgetrf = \&PDL::cgetrf;





*__Ccgetf2 = \&PDL::__Ccgetf2;





*__Ncgetf2 = \&PDL::__Ncgetf2;



=head2 cgetf2

=for sig

  Signature: ([io,phys]A(2,m,n); int [o,phys]ipiv(p); int [o,phys]info())


=for ref

Complex version of getf2



=cut

sub PDL::cgetf2 {
  $_[0]->type->real ? goto &PDL::__Ccgetf2 : goto &PDL::__Ncgetf2;
}
*cgetf2 = \&PDL::cgetf2;





*__Ccsytrf = \&PDL::__Ccsytrf;





*__Ncsytrf = \&PDL::__Ncsytrf;



=head2 csytrf

=for sig

  Signature: ([io,phys]A(2,n,n); int uplo(); int [o,phys]ipiv(n); int [o,phys]info())


=for ref

Complex version of sytrf



=cut

sub PDL::csytrf {
  $_[0]->type->real ? goto &PDL::__Ccsytrf : goto &PDL::__Ncsytrf;
}
*csytrf = \&PDL::csytrf;





*__Ccsytf2 = \&PDL::__Ccsytf2;





*__Ncsytf2 = \&PDL::__Ncsytf2;



=head2 csytf2

=for sig

  Signature: ([io,phys]A(2,n,n); int uplo(); int [o,phys]ipiv(n); int [o,phys]info())


=for ref

Complex version of sytf2



=cut

sub PDL::csytf2 {
  $_[0]->type->real ? goto &PDL::__Ccsytf2 : goto &PDL::__Ncsytf2;
}
*csytf2 = \&PDL::csytf2;





*__Ccchetrf = \&PDL::__Ccchetrf;





*__Ncchetrf = \&PDL::__Ncchetrf;



=head2 cchetrf

=for sig

  Signature: ([io,phys]A(2,n,n); int uplo(); int [o,phys]ipiv(n); int [o,phys]info())



=for ref

Complex version of sytrf for Hermitian matrix



=cut

sub PDL::cchetrf {
  $_[0]->type->real ? goto &PDL::__Ccchetrf : goto &PDL::__Ncchetrf;
}
*cchetrf = \&PDL::cchetrf;





*__Cchetf2 = \&PDL::__Cchetf2;





*__Nchetf2 = \&PDL::__Nchetf2;



=head2 chetf2

=for sig

  Signature: ([io,phys]A(2,n,n); int uplo(); int [o,phys]ipiv(n); int [o,phys]info())



=for ref

Complex version of sytf2 for Hermitian matrix



=cut

sub PDL::chetf2 {
  $_[0]->type->real ? goto &PDL::__Cchetf2 : goto &PDL::__Nchetf2;
}
*chetf2 = \&PDL::chetf2;





*__Ccpotrf = \&PDL::__Ccpotrf;





*__Ncpotrf = \&PDL::__Ncpotrf;



=head2 cpotrf

=for sig

  Signature: ([io,phys]A(2,n,n); int uplo(); int [o,phys]info())



=for ref

Complex version of potrf for Hermitian positive definite matrix



=cut

sub PDL::cpotrf {
  $_[0]->type->real ? goto &PDL::__Ccpotrf : goto &PDL::__Ncpotrf;
}
*cpotrf = \&PDL::cpotrf;





*__Ccpotf2 = \&PDL::__Ccpotf2;





*__Ncpotf2 = \&PDL::__Ncpotf2;



=head2 cpotf2

=for sig

  Signature: ([io,phys]A(2,n,n); int uplo(); int [o,phys]info())



=for ref

Complex version of potf2 for Hermitian positive definite matrix



=cut

sub PDL::cpotf2 {
  $_[0]->type->real ? goto &PDL::__Ccpotf2 : goto &PDL::__Ncpotf2;
}
*cpotf2 = \&PDL::cpotf2;





*__Ccgetri = \&PDL::__Ccgetri;





*__Ncgetri = \&PDL::__Ncgetri;



=head2 cgetri

=for sig

  Signature: ([io,phys]A(2,n,n); int [phys]ipiv(n); int [o,phys]info())


=for ref

Complex version of getri



=cut

sub PDL::cgetri {
  $_[0]->type->real ? goto &PDL::__Ccgetri : goto &PDL::__Ncgetri;
}
*cgetri = \&PDL::cgetri;





*__Ccsytri = \&PDL::__Ccsytri;





*__Ncsytri = \&PDL::__Ncsytri;



=head2 csytri

=for sig

  Signature: ([io,phys]A(2,n,n); int uplo(); int [phys]ipiv(n); int [o,phys]info())


=for ref

Complex version of sytri



=cut

sub PDL::csytri {
  $_[0]->type->real ? goto &PDL::__Ccsytri : goto &PDL::__Ncsytri;
}
*csytri = \&PDL::csytri;





*__Cchetri = \&PDL::__Cchetri;





*__Nchetri = \&PDL::__Nchetri;



=head2 chetri

=for sig

  Signature: ([io,phys]A(2,n,n); int uplo(); int [phys]ipiv(n); int [o,phys]info())



=for ref

Complex version of sytri for Hermitian matrix



=cut

sub PDL::chetri {
  $_[0]->type->real ? goto &PDL::__Cchetri : goto &PDL::__Nchetri;
}
*chetri = \&PDL::chetri;





*__Ccpotri = \&PDL::__Ccpotri;





*__Ncpotri = \&PDL::__Ncpotri;



=head2 cpotri

=for sig

  Signature: ([io,phys]A(2,n,n); int uplo(); int [o,phys]info())


=for ref

Complex version of potri



=cut

sub PDL::cpotri {
  $_[0]->type->real ? goto &PDL::__Ccpotri : goto &PDL::__Ncpotri;
}
*cpotri = \&PDL::cpotri;





*__Cctrtri = \&PDL::__Cctrtri;





*__Nctrtri = \&PDL::__Nctrtri;



=head2 ctrtri

=for sig

  Signature: ([io,phys]A(2,n,n); int uplo(); int diag(); int [o,phys]info())


=for ref

Complex version of trtri



=cut

sub PDL::ctrtri {
  $_[0]->type->real ? goto &PDL::__Cctrtri : goto &PDL::__Nctrtri;
}
*ctrtri = \&PDL::ctrtri;





*__Cctrti2 = \&PDL::__Cctrti2;





*__Nctrti2 = \&PDL::__Nctrti2;



=head2 ctrti2

=for sig

  Signature: ([io,phys]A(2,n,n); int uplo(); int diag(); int [o,phys]info())


=for ref

Complex version of trti2



=cut

sub PDL::ctrti2 {
  $_[0]->type->real ? goto &PDL::__Cctrti2 : goto &PDL::__Nctrti2;
}
*ctrti2 = \&PDL::ctrti2;





*__Ccgetrs = \&PDL::__Ccgetrs;





*__Ncgetrs = \&PDL::__Ncgetrs;



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



=cut

sub PDL::cgetrs {
  $_[0]->type->real ? goto &PDL::__Ccgetrs : goto &PDL::__Ncgetrs;
}
*cgetrs = \&PDL::cgetrs;





*__Ccsytrs = \&PDL::__Ccsytrs;





*__Ncsytrs = \&PDL::__Ncsytrs;



=head2 csytrs

=for sig

  Signature: ([phys]A(2,n,n); int uplo();[io,phys]B(2,n,m); int [phys]ipiv(n); int [o,phys]info())


=for ref

Complex version of sytrs



=cut

sub PDL::csytrs {
  $_[0]->type->real ? goto &PDL::__Ccsytrs : goto &PDL::__Ncsytrs;
}
*csytrs = \&PDL::csytrs;





*__Cchetrs = \&PDL::__Cchetrs;





*__Nchetrs = \&PDL::__Nchetrs;



=head2 chetrs

=for sig

  Signature: ([phys]A(2,n,n); int uplo();[io,phys]B(2,n,m); int [phys]ipiv(n); int [o,phys]info())



=for ref

Complex version of sytrs for Hermitian matrix



=cut

sub PDL::chetrs {
  $_[0]->type->real ? goto &PDL::__Cchetrs : goto &PDL::__Nchetrs;
}
*chetrs = \&PDL::chetrs;





*__Ccpotrs = \&PDL::__Ccpotrs;





*__Ncpotrs = \&PDL::__Ncpotrs;



=head2 cpotrs

=for sig

  Signature: ([phys]A(2,n,n); int uplo(); [io,phys]B(2,n,m); int [o,phys]info())



=for ref

Complex version of potrs for Hermitian positive definite matrix



=cut

sub PDL::cpotrs {
  $_[0]->type->real ? goto &PDL::__Ccpotrs : goto &PDL::__Ncpotrs;
}
*cpotrs = \&PDL::cpotrs;





*__Cctrtrs = \&PDL::__Cctrtrs;





*__Nctrtrs = \&PDL::__Nctrtrs;



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



=cut

sub PDL::ctrtrs {
  $_[0]->type->real ? goto &PDL::__Cctrtrs : goto &PDL::__Nctrtrs;
}
*ctrtrs = \&PDL::ctrtrs;





*__Cclatrs = \&PDL::__Cclatrs;





*__Nclatrs = \&PDL::__Nclatrs;



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



=cut

sub PDL::clatrs {
  $_[0]->type->real ? goto &PDL::__Cclatrs : goto &PDL::__Nclatrs;
}
*clatrs = \&PDL::clatrs;





*__Ccgecon = \&PDL::__Ccgecon;





*__Ncgecon = \&PDL::__Ncgecon;



=head2 cgecon

=for sig

  Signature: ([phys]A(2,n,n); int norm(); [phys]anorm(); [o,phys]rcond();int [o,phys]info())


=for ref

Complex version of gecon



=cut

sub PDL::cgecon {
  $_[0]->type->real ? goto &PDL::__Ccgecon : goto &PDL::__Ncgecon;
}
*cgecon = \&PDL::cgecon;





*__Ccsycon = \&PDL::__Ccsycon;





*__Ncsycon = \&PDL::__Ncsycon;



=head2 csycon

=for sig

  Signature: ([phys]A(2,n,n); int uplo(); int ipiv(n); [phys]anorm(); [o,phys]rcond();int [o,phys]info())


=for ref

Complex version of sycon



=cut

sub PDL::csycon {
  $_[0]->type->real ? goto &PDL::__Ccsycon : goto &PDL::__Ncsycon;
}
*csycon = \&PDL::csycon;





*__Cchecon = \&PDL::__Cchecon;





*__Nchecon = \&PDL::__Nchecon;



=head2 checon

=for sig

  Signature: ([phys]A(2,n,n); int uplo(); int ipiv(n); [phys]anorm(); [o,phys]rcond();int [o,phys]info())



=for ref

Complex version of sycon for Hermitian matrix



=cut

sub PDL::checon {
  $_[0]->type->real ? goto &PDL::__Cchecon : goto &PDL::__Nchecon;
}
*checon = \&PDL::checon;





*__Ccpocon = \&PDL::__Ccpocon;





*__Ncpocon = \&PDL::__Ncpocon;



=head2 cpocon

=for sig

  Signature: ([phys]A(2,n,n); int uplo(); [phys]anorm(); [o,phys]rcond();int [o,phys]info())



=for ref

Complex version of pocon for Hermitian positive definite matrix



=cut

sub PDL::cpocon {
  $_[0]->type->real ? goto &PDL::__Ccpocon : goto &PDL::__Ncpocon;
}
*cpocon = \&PDL::cpocon;





*__Cctrcon = \&PDL::__Cctrcon;





*__Nctrcon = \&PDL::__Nctrcon;



=head2 ctrcon

=for sig

  Signature: ([phys]A(2,n,n); int norm();int uplo();int diag(); [o,phys]rcond();int [o,phys]info())


=for ref

Complex version of trcon



=cut

sub PDL::ctrcon {
  $_[0]->type->real ? goto &PDL::__Cctrcon : goto &PDL::__Nctrcon;
}
*ctrcon = \&PDL::ctrcon;





*__Ccgeqp3 = \&PDL::__Ccgeqp3;





*__Ncgeqp3 = \&PDL::__Ncgeqp3;



=head2 cgeqp3

=for sig

  Signature: ([io,phys]A(2,m,n); int [io,phys]jpvt(n); [o,phys]tau(2,k); int [o,phys]info())


=for ref

Complex version of geqp3



=cut

sub PDL::cgeqp3 {
  $_[0]->type->real ? goto &PDL::__Ccgeqp3 : goto &PDL::__Ncgeqp3;
}
*cgeqp3 = \&PDL::cgeqp3;





*__Ccgeqrf = \&PDL::__Ccgeqrf;





*__Ncgeqrf = \&PDL::__Ncgeqrf;



=head2 cgeqrf

=for sig

  Signature: ([io,phys]A(2,m,n); [o,phys]tau(2,k); int [o,phys]info())


=for ref

Complex version of geqrf



=cut

sub PDL::cgeqrf {
  $_[0]->type->real ? goto &PDL::__Ccgeqrf : goto &PDL::__Ncgeqrf;
}
*cgeqrf = \&PDL::cgeqrf;





*__Ccungqr = \&PDL::__Ccungqr;





*__Ncungqr = \&PDL::__Ncungqr;



=head2 cungqr

=for sig

  Signature: ([io,phys]A(2,m,n); [phys]tau(2,k); int [o,phys]info())



=for ref

Complex version of orgqr



=cut

sub PDL::cungqr {
  $_[0]->type->real ? goto &PDL::__Ccungqr : goto &PDL::__Ncungqr;
}
*cungqr = \&PDL::cungqr;





*__Ccunmqr = \&PDL::__Ccunmqr;





*__Ncunmqr = \&PDL::__Ncunmqr;



=head2 cunmqr

=for sig

  Signature: ([phys]A(2,p,k); int side(); int trans(); [phys]tau(2,k); [io,phys]C(2,m,n);int [o,phys]info())



=for ref

Complex version of ormqr. Here trans = 1 means conjugate transpose.



=cut

sub PDL::cunmqr {
  $_[0]->type->real ? goto &PDL::__Ccunmqr : goto &PDL::__Ncunmqr;
}
*cunmqr = \&PDL::cunmqr;





*__Ccgelqf = \&PDL::__Ccgelqf;





*__Ncgelqf = \&PDL::__Ncgelqf;



=head2 cgelqf

=for sig

  Signature: ([io,phys]A(2,m,n); [o,phys]tau(2,k); int [o,phys]info())


=for ref

Complex version of gelqf



=cut

sub PDL::cgelqf {
  $_[0]->type->real ? goto &PDL::__Ccgelqf : goto &PDL::__Ncgelqf;
}
*cgelqf = \&PDL::cgelqf;





*__Ccunglq = \&PDL::__Ccunglq;





*__Ncunglq = \&PDL::__Ncunglq;



=head2 cunglq

=for sig

  Signature: ([io,phys]A(2,m,n); [phys]tau(2,k); int [o,phys]info())



=for ref

Complex version of orglq



=cut

sub PDL::cunglq {
  $_[0]->type->real ? goto &PDL::__Ccunglq : goto &PDL::__Ncunglq;
}
*cunglq = \&PDL::cunglq;





*__Ccunmlq = \&PDL::__Ccunmlq;





*__Ncunmlq = \&PDL::__Ncunmlq;



=head2 cunmlq

=for sig

  Signature: ([phys]A(2,k,p); int side(); int trans(); [phys]tau(2,k); [io,phys]C(2,m,n);int [o,phys]info())



=for ref

Complex version of ormlq. Here trans = 1 means conjugate transpose.



=cut

sub PDL::cunmlq {
  $_[0]->type->real ? goto &PDL::__Ccunmlq : goto &PDL::__Ncunmlq;
}
*cunmlq = \&PDL::cunmlq;





*__Ccgeqlf = \&PDL::__Ccgeqlf;





*__Ncgeqlf = \&PDL::__Ncgeqlf;



=head2 cgeqlf

=for sig

  Signature: ([io,phys]A(2,m,n); [o,phys]tau(2,k); int [o,phys]info())


=for ref

Complex version of geqlf



=cut

sub PDL::cgeqlf {
  $_[0]->type->real ? goto &PDL::__Ccgeqlf : goto &PDL::__Ncgeqlf;
}
*cgeqlf = \&PDL::cgeqlf;





*__Ccungql = \&PDL::__Ccungql;





*__Ncungql = \&PDL::__Ncungql;



=head2 cungql

=for sig

  Signature: ([io,phys]A(2,m,n); [phys]tau(2,k); int [o,phys]info())



=for ref

Complex version of orgql.



=cut

sub PDL::cungql {
  $_[0]->type->real ? goto &PDL::__Ccungql : goto &PDL::__Ncungql;
}
*cungql = \&PDL::cungql;





*__Ccunmql = \&PDL::__Ccunmql;





*__Ncunmql = \&PDL::__Ncunmql;



=head2 cunmql

=for sig

  Signature: ([phys]A(2,p,k); int side(); int trans(); [phys]tau(2,k); [io,phys]C(2,m,n);int [o,phys]info())



=for ref

Complex version of ormql. Here trans = 1 means conjugate transpose.



=cut

sub PDL::cunmql {
  $_[0]->type->real ? goto &PDL::__Ccunmql : goto &PDL::__Ncunmql;
}
*cunmql = \&PDL::cunmql;





*__Ccgerqf = \&PDL::__Ccgerqf;





*__Ncgerqf = \&PDL::__Ncgerqf;



=head2 cgerqf

=for sig

  Signature: ([io,phys]A(2,m,n); [o,phys]tau(2,k); int [o,phys]info())


=for ref

Complex version of gerqf



=cut

sub PDL::cgerqf {
  $_[0]->type->real ? goto &PDL::__Ccgerqf : goto &PDL::__Ncgerqf;
}
*cgerqf = \&PDL::cgerqf;





*__Ccungrq = \&PDL::__Ccungrq;





*__Ncungrq = \&PDL::__Ncungrq;



=head2 cungrq

=for sig

  Signature: ([io,phys]A(2,m,n); [phys]tau(2,k); int [o,phys]info())



=for ref

Complex version of orgrq.



=cut

sub PDL::cungrq {
  $_[0]->type->real ? goto &PDL::__Ccungrq : goto &PDL::__Ncungrq;
}
*cungrq = \&PDL::cungrq;





*__Ccunmrq = \&PDL::__Ccunmrq;





*__Ncunmrq = \&PDL::__Ncunmrq;



=head2 cunmrq

=for sig

  Signature: ([phys]A(2,k,p); int side(); int trans(); [phys]tau(2,k); [io,phys]C(2,m,n);int [o,phys]info())



=for ref

Complex version of ormrq. Here trans = 1 means conjugate transpose.



=cut

sub PDL::cunmrq {
  $_[0]->type->real ? goto &PDL::__Ccunmrq : goto &PDL::__Ncunmrq;
}
*cunmrq = \&PDL::cunmrq;





*__Cctzrzf = \&PDL::__Cctzrzf;





*__Nctzrzf = \&PDL::__Nctzrzf;



=head2 ctzrzf

=for sig

  Signature: ([io,phys]A(2,m,n); [o,phys]tau(2,k); int [o,phys]info())


=for ref

Complex version of tzrzf



=cut

sub PDL::ctzrzf {
  $_[0]->type->real ? goto &PDL::__Cctzrzf : goto &PDL::__Nctzrzf;
}
*ctzrzf = \&PDL::ctzrzf;





*__Ccunmrz = \&PDL::__Ccunmrz;





*__Ncunmrz = \&PDL::__Ncunmrz;



=head2 cunmrz

=for sig

  Signature: ([phys]A(2,k,p); int side(); int trans(); [phys]tau(2,k); [io,phys]C(2,m,n);int [o,phys]info())



=for ref

Complex version of ormrz. Here trans = 1 means conjugate transpose.



=cut

sub PDL::cunmrz {
  $_[0]->type->real ? goto &PDL::__Ccunmrz : goto &PDL::__Ncunmrz;
}
*cunmrz = \&PDL::cunmrz;





*__Ccgehrd = \&PDL::__Ccgehrd;





*__Ncgehrd = \&PDL::__Ncgehrd;



=head2 cgehrd

=for sig

  Signature: ([io,phys]A(2,n,n); int [phys]ilo();int [phys]ihi();[o,phys]tau(2,k); int [o,phys]info())


=for ref

Complex version of gehrd



=cut

sub PDL::cgehrd {
  $_[0]->type->real ? goto &PDL::__Ccgehrd : goto &PDL::__Ncgehrd;
}
*cgehrd = \&PDL::cgehrd;





*__Ccunghr = \&PDL::__Ccunghr;





*__Ncunghr = \&PDL::__Ncunghr;



=head2 cunghr

=for sig

  Signature: ([io,phys]A(2,n,n); int [phys]ilo();int [phys]ihi();[phys]tau(2,k); int [o,phys]info())



=for ref

Complex version of orghr



=cut

sub PDL::cunghr {
  $_[0]->type->real ? goto &PDL::__Ccunghr : goto &PDL::__Ncunghr;
}
*cunghr = \&PDL::cunghr;





*__Cchseqr = \&PDL::__Cchseqr;





*__Nchseqr = \&PDL::__Nchseqr;



=head2 chseqr

=for sig

  Signature: ([io,phys]H(2,n,n); int job();int compz();int [phys]ilo();int [phys]ihi();[o,phys]w(2,n); [o,phys]Z(2,m,m); int [o,phys]info())


=for ref

Complex version of hseqr



=cut

sub PDL::chseqr {
  $_[0]->type->real ? goto &PDL::__Cchseqr : goto &PDL::__Nchseqr;
}
*chseqr = \&PDL::chseqr;





*__Cctrevc = \&PDL::__Cctrevc;





*__Nctrevc = \&PDL::__Nctrevc;



=head2 ctrevc

=for sig

  Signature: ([io,phys]T(2,n,n); int side();int howmny();int [phys]select(q);[io,phys]VL(2,m,r); [io,phys]VR(2,p,s);int [o,phys]m(); int [o,phys]info())


=for ref

Complex version of trevc



=cut

sub PDL::ctrevc {
  $_[0]->type->real ? goto &PDL::__Cctrevc : goto &PDL::__Nctrevc;
}
*ctrevc = \&PDL::ctrevc;





*__Cctgevc = \&PDL::__Cctgevc;





*__Nctgevc = \&PDL::__Nctgevc;



=head2 ctgevc

=for sig

  Signature: ([io,phys]A(2,n,n); int side();int howmny(); [io,phys]B(2,n,n);int [phys]select(q);[io,phys]VL(2,m,r); [io,phys]VR(2,p,s);int [o,phys]m(); int [o,phys]info())


=for ref

Complex version of tgevc



=cut

sub PDL::ctgevc {
  $_[0]->type->real ? goto &PDL::__Cctgevc : goto &PDL::__Nctgevc;
}
*ctgevc = \&PDL::ctgevc;





*__Ccgebal = \&PDL::__Ccgebal;





*__Ncgebal = \&PDL::__Ncgebal;



=head2 cgebal

=for sig

  Signature: ([io,phys]A(2,n,n); int job(); int [o,phys]ilo();int [o,phys]ihi();[o,phys]scale(n); int [o,phys]info())


=for ref

Complex version of gebal



=cut

sub PDL::cgebal {
  $_[0]->type->real ? goto &PDL::__Ccgebal : goto &PDL::__Ncgebal;
}
*cgebal = \&PDL::cgebal;





*__Cclange = \&PDL::__Cclange;





*__Nclange = \&PDL::__Nclange;



=head2 clange

=for sig

  Signature: ([phys]A(2,n,m); int norm(); [o]b())


=for ref

Complex version of lange



=cut

sub PDL::clange {
  $_[0]->type->real ? goto &PDL::__Cclange : goto &PDL::__Nclange;
}
*clange = \&PDL::clange;





*__Cclansy = \&PDL::__Cclansy;





*__Nclansy = \&PDL::__Nclansy;



=head2 clansy

=for sig

  Signature: ([phys]A(2, n,n); int uplo(); int norm(); [o]b())


=for ref

Complex version of lansy



=cut

sub PDL::clansy {
  $_[0]->type->real ? goto &PDL::__Cclansy : goto &PDL::__Nclansy;
}
*clansy = \&PDL::clansy;





*__Cclantr = \&PDL::__Cclantr;





*__Nclantr = \&PDL::__Nclantr;



=head2 clantr

=for sig

  Signature: ([phys]A(2,m,n);int uplo();int norm();int diag();[o]b())


=for ref

Complex version of lantr



=cut

sub PDL::clantr {
  $_[0]->type->real ? goto &PDL::__Cclantr : goto &PDL::__Nclantr;
}
*clantr = \&PDL::clantr;





*__Ccgemm = \&PDL::__Ccgemm;





*__Ncgemm = \&PDL::__Ncgemm;



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



=cut

sub PDL::cgemm {
  $_[0]->type->real ? goto &PDL::__Ccgemm : goto &PDL::__Ncgemm;
}
*cgemm = \&PDL::cgemm;





*__Ccmmult = \&PDL::__Ccmmult;





*__Ncmmult = \&PDL::__Ncmmult;



=head2 cmmult

=for sig

  Signature: ([phys]A(2,m,n); [phys]B(2,p,m); [o,phys]C(2,p,n))


=for ref

Complex version of mmult



=cut

sub PDL::cmmult {
  $_[0]->type->real ? goto &PDL::__Ccmmult : goto &PDL::__Ncmmult;
}
*cmmult = \&PDL::cmmult;





*__Cccrossprod = \&PDL::__Cccrossprod;





*__Nccrossprod = \&PDL::__Nccrossprod;



=head2 ccrossprod

=for sig

  Signature: ([phys]A(2,n,m); [phys]B(2,p,m); [o,phys]C(2,p,n))


=for ref

Complex version of crossprod



=cut

sub PDL::ccrossprod {
  $_[0]->type->real ? goto &PDL::__Cccrossprod : goto &PDL::__Nccrossprod;
}
*ccrossprod = \&PDL::ccrossprod;





*__Ccsyrk = \&PDL::__Ccsyrk;





*__Ncsyrk = \&PDL::__Ncsyrk;



=head2 csyrk

=for sig

  Signature: ([phys]A(2,m,n); int uplo(); int trans(); [phys]alpha(2); [phys]beta(2); [io,phys]C(2,p,p))


=for ref

Complex version of syrk



=cut

sub PDL::csyrk {
  $_[0]->type->real ? goto &PDL::__Ccsyrk : goto &PDL::__Ncsyrk;
}
*csyrk = \&PDL::csyrk;





*__Ccdot = \&PDL::__Ccdot;





*__Ncdot = \&PDL::__Ncdot;



=head2 cdot

=for sig

  Signature: ([phys]a(2,n);int [phys]inca();[phys]b(2,n);int [phys]incb();[o,phys]c(2))


=for ref

Complex version of dot



=cut

sub PDL::cdot {
  $_[0]->type->real ? goto &PDL::__Ccdot : goto &PDL::__Ncdot;
}
*cdot = \&PDL::cdot;





*__Ccdotc = \&PDL::__Ccdotc;





*__Ncdotc = \&PDL::__Ncdotc;



=head2 cdotc

=for sig

  Signature: ([phys]a(2,n);int [phys]inca();[phys]b(2,n);int [phys]incb();[o,phys]c(2))



=for ref

Forms the dot product of two vectors, conjugating the first   
vector.



=cut

sub PDL::cdotc {
  $_[0]->type->real ? goto &PDL::__Ccdotc : goto &PDL::__Ncdotc;
}
*cdotc = \&PDL::cdotc;





*__Ccaxpy = \&PDL::__Ccaxpy;





*__Ncaxpy = \&PDL::__Ncaxpy;



=head2 caxpy

=for sig

  Signature: ([phys]a(2,n);int [phys]inca();[phys] alpha(2);[io,phys]b(2,n);int [phys]incb())


=for ref

Complex version of axpy



=cut

sub PDL::caxpy {
  $_[0]->type->real ? goto &PDL::__Ccaxpy : goto &PDL::__Ncaxpy;
}
*caxpy = \&PDL::caxpy;





*__Ccnrm2 = \&PDL::__Ccnrm2;





*__Ncnrm2 = \&PDL::__Ncnrm2;



=head2 cnrm2

=for sig

  Signature: ([phys]a(2,n);int [phys]inca();[o,phys]b())


=for ref

Complex version of nrm2



=cut

sub PDL::cnrm2 {
  $_[0]->type->real ? goto &PDL::__Ccnrm2 : goto &PDL::__Ncnrm2;
}
*cnrm2 = \&PDL::cnrm2;





*__Ccasum = \&PDL::__Ccasum;





*__Ncasum = \&PDL::__Ncasum;



=head2 casum

=for sig

  Signature: ([phys]a(2,n);int [phys]inca();[o,phys]b())


=for ref

Complex version of asum



=cut

sub PDL::casum {
  $_[0]->type->real ? goto &PDL::__Ccasum : goto &PDL::__Ncasum;
}
*casum = \&PDL::casum;





*__Ccscal = \&PDL::__Ccscal;





*__Ncscal = \&PDL::__Ncscal;



=head2 cscal

=for sig

  Signature: ([io,phys]a(2,n);int [phys]inca();[phys]scale(2))


=for ref

Complex version of scal



=cut

sub PDL::cscal {
  $_[0]->type->real ? goto &PDL::__Ccscal : goto &PDL::__Ncscal;
}
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





*__Ccrotg = \&PDL::__Ccrotg;





*__Ncrotg = \&PDL::__Ncrotg;



=head2 crotg

=for sig

  Signature: ([io,phys]a(2);[phys]b(2);[o,phys]c(); [o,phys]s(2))


=for ref

Complex version of rotg



=cut

sub PDL::crotg {
  $_[0]->type->real ? goto &PDL::__Ccrotg : goto &PDL::__Ncrotg;
}
*crotg = \&PDL::crotg;





*__Cclacpy = \&PDL::__Cclacpy;





*__Nclacpy = \&PDL::__Nclacpy;



=head2 clacpy

=for sig

  Signature: ([phys]A(2,m,n); int uplo(); [o,phys]B(2,p,n))


=for ref

Complex version of lacpy



=cut

sub PDL::clacpy {
  $_[0]->type->real ? goto &PDL::__Cclacpy : goto &PDL::__Nclacpy;
}
*clacpy = \&PDL::clacpy;





*__Cclaswp = \&PDL::__Cclaswp;





*__Nclaswp = \&PDL::__Nclaswp;



=head2 claswp

=for sig

  Signature: ([io,phys]A(2,m,n); int [phys]k1(); int [phys]k2(); int [phys]ipiv(p);int [phys]inc())


=for ref

Complex version of laswp



=cut

sub PDL::claswp {
  $_[0]->type->real ? goto &PDL::__Cclaswp : goto &PDL::__Nclaswp;
}
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





*__Cccharpol = \&PDL::__Cccharpol;





*__Nccharpol = \&PDL::__Nccharpol;



=head2 ccharpol

=for sig

  Signature: ([phys]A(c=2,n,n);[phys,o]Y(c=2,n,n);[phys,o]out(c=2,p);)


=for ref

Complex version of charpol



=cut

sub PDL::ccharpol {
  $_[0]->type->real ? goto &PDL::__Cccharpol : goto &PDL::__Nccharpol;
}
*ccharpol = \&PDL::ccharpol;



;


=head1 AUTHOR

Copyright (C) Grégory Vanuxem 2005-2018.

This library is free software; you can redistribute it and/or modify
it under the terms of the Perl Artistic License as in the file Artistic_2
in this distribution.

=cut





# Exit with OK status

1;

		   
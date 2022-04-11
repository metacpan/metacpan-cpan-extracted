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
These routines accept either float or double ndarrays.
#line 80 "Complex.pm"






=head1 FUNCTIONS

=cut




#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccgtsv = \&PDL::__Ccgtsv;
#line 97 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncgtsv = \&PDL::__Ncgtsv;
#line 104 "Complex.pm"



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

 use PDL::Complex;
 $dl = random(float, 9) + random(float, 9) * i;
 $d = random(float, 10) + random(float, 10) * i;
 $du = random(float, 9) + random(float, 9) * i;
 $b = random(10,5) + random(10,5) * i;
 cgtsv($dl, $d, $du, $b, ($info=null));
 print "X is:\n$b" unless $info;



=cut

sub PDL::cgtsv {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccgtsv : goto &PDL::__Ncgtsv;
}
*cgtsv = \&PDL::cgtsv;
#line 179 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccgesvd = \&PDL::__Ccgesvd;
#line 186 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncgesvd = \&PDL::__Ncgesvd;
#line 193 "Complex.pm"



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
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccgesvd : goto &PDL::__Ncgesvd;
}
*cgesvd = \&PDL::cgesvd;
#line 223 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccgesdd = \&PDL::__Ccgesdd;
#line 230 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncgesdd = \&PDL::__Ncgesdd;
#line 237 "Complex.pm"



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
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccgesdd : goto &PDL::__Ncgesdd;
}
*cgesdd = \&PDL::cgesdd;
#line 267 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccggsvd = \&PDL::__Ccggsvd;
#line 274 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncggsvd = \&PDL::__Ncggsvd;
#line 281 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cggsvd

=for sig

  Signature: (complex [io]A(m,n); int jobu(); int jobv(); int jobq();complex  [io]B(p,n); int [o]k(); int [o]l();[o]alpha(n);[o]beta(n);complex  [o]U(q,q);complex  [o]V(r,r);complex  [o]Q(s,s); int [o]iwork(n); int [o]info(); [t]rwork(rworkn))


=for ref

Complex version of L<PDL::LinearAlgebra::Real/ggsvd>



=cut

sub PDL::cggsvd {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccggsvd : goto &PDL::__Ncggsvd;
}
*cggsvd = \&PDL::cggsvd;
#line 306 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccgeev = \&PDL::__Ccgeev;
#line 313 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncgeev = \&PDL::__Ncgeev;
#line 320 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cgeev

=for sig

  Signature: (complex A(n,n); int jobvl(); int jobvr();complex  [o]w(n);complex  [o]vl(m,m);complex  [o]vr(p,p); int [o]info(); [t]rwork(rworkn))


=for ref

Complex version of L<PDL::LinearAlgebra::Real/geev>



=cut

sub PDL::cgeev {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccgeev : goto &PDL::__Ncgeev;
}
*cgeev = \&PDL::cgeev;
#line 345 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccgeevx = \&PDL::__Ccgeevx;
#line 352 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncgeevx = \&PDL::__Ncgeevx;
#line 359 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cgeevx

=for sig

  Signature: (complex [io]A(n,n);  int jobvl(); int jobvr(); int balance(); int sense();complex  [o]w(n);complex  [o]vl(m,m);complex  [o]vr(p,p); int [o]ilo(); int [o]ihi(); [o]scale(n); [o]abnrm(); [o]rconde(q); [o]rcondv(r); int [o]info(); [t]rwork(rworkn))


=for ref

Complex version of L<PDL::LinearAlgebra::Real/geevx>



=cut

sub PDL::cgeevx {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccgeevx : goto &PDL::__Ncgeevx;
}
*cgeevx = \&PDL::cgeevx;
#line 384 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccggev = \&PDL::__Ccggev;
#line 391 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncggev = \&PDL::__Ncggev;
#line 398 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cggev

=for sig

  Signature: (complex A(n,n); int [phys]jobvl();int [phys]jobvr();complex B(n,n);complex [o]alpha(n);complex [o]beta(n);complex [o]VL(m,m);complex [o]VR(p,p);int [o]info(); [t]rwork(rworkn))


=for ref

Complex version of L<PDL::LinearAlgebra::Real/ggev>



=cut

sub PDL::cggev {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccggev : goto &PDL::__Ncggev;
}
*cggev = \&PDL::cggev;
#line 423 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccggevx = \&PDL::__Ccggevx;
#line 430 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncggevx = \&PDL::__Ncggevx;
#line 437 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cggevx

=for sig

  Signature: (complex [io,phys]A(n,n);int balanc();int jobvl();int jobvr();int sense();complex [io,phys]B(n,n);complex [o]alpha(n);complex [o]beta(n);complex [o]VL(m,m);complex [o]VR(p,p);int [o]ilo();int [o]ihi();[o]lscale(n);[o]rscale(n);[o]abnrm();[o]bbnrm();[o]rconde(r);[o]rcondv(s);int [o]info(); [t]rwork(rworkn); int [t]bwork(bworkn); int [t]iwork(iworkn))


=for ref

Complex version of L<PDL::LinearAlgebra::Real/ggevx>



=cut

sub PDL::cggevx {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccggevx : goto &PDL::__Ncggevx;
}
*cggevx = \&PDL::cggevx;
#line 462 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccgees = \&PDL::__Ccgees;
#line 469 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncgees = \&PDL::__Ncgees;
#line 476 "Complex.pm"



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
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccgees : goto &PDL::__Ncgees;
}
*cgees = \&PDL::cgees;
#line 514 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccgeesx = \&PDL::__Ccgeesx;
#line 521 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncgeesx = \&PDL::__Ncgeesx;
#line 528 "Complex.pm"



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
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccgeesx : goto &PDL::__Ncgeesx;
}
*cgeesx = \&PDL::cgeesx;
#line 564 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccgges = \&PDL::__Ccgges;
#line 571 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncgges = \&PDL::__Ncgges;
#line 578 "Complex.pm"



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
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccgges : goto &PDL::__Ncgges;
}
*cgges = \&PDL::cgges;
#line 617 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccggesx = \&PDL::__Ccggesx;
#line 624 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncggesx = \&PDL::__Ncggesx;
#line 631 "Complex.pm"



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
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccggesx : goto &PDL::__Ncggesx;
}
*cggesx = \&PDL::cggesx;
#line 670 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccheev = \&PDL::__Ccheev;
#line 677 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncheev = \&PDL::__Ncheev;
#line 684 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cheev

=for sig

  Signature: (complex [io]A(n,n); int jobz(); int uplo(); [o]w(n); int [o]info(); [t]rwork(rworkn))



=for ref

Complex version of L<PDL::LinearAlgebra::Real/syev> for Hermitian matrix



=cut

sub PDL::cheev {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccheev : goto &PDL::__Ncheev;
}
*cheev = \&PDL::cheev;
#line 710 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccheevd = \&PDL::__Ccheevd;
#line 717 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncheevd = \&PDL::__Ncheevd;
#line 724 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cheevd

=for sig

  Signature: (complex [io,phys]A(n,n);  int jobz(); int uplo(); [o,phys]w(n); int [o,phys]info())



=for ref

Complex version of L<PDL::LinearAlgebra::Real/syevd> for Hermitian matrix



=cut

sub PDL::cheevd {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccheevd : goto &PDL::__Ncheevd;
}
*cheevd = \&PDL::cheevd;
#line 750 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccheevx = \&PDL::__Ccheevx;
#line 757 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncheevx = \&PDL::__Ncheevx;
#line 764 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cheevx

=for sig

  Signature: (complex A(n,n);  int jobz(); int range(); int uplo(); vl(); vu(); int il(); int iu(); abstol(); int [o]m(); [o]w(n);complex  [o]z(p,p);int [o]ifail(n); int [o]info(); [t]rwork(rworkn); int [t]iwork(iworkn))



=for ref

Complex version of L<PDL::LinearAlgebra::Real/syevx> for Hermitian matrix



=cut

sub PDL::cheevx {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccheevx : goto &PDL::__Ncheevx;
}
*cheevx = \&PDL::cheevx;
#line 790 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccheevr = \&PDL::__Ccheevr;
#line 797 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncheevr = \&PDL::__Ncheevr;
#line 804 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cheevr

=for sig

  Signature: (complex [phys]A(n,n);  int jobz(); int range(); int uplo(); [phys]vl(); [phys]vu(); int [phys]il(); int [phys]iu(); [phys]abstol(); int [o,phys]m(); [o,phys]w(n);complex  [o,phys]z(p,q);int [o,phys]isuppz(r); int [o,phys]info())



=for ref

Complex version of L<PDL::LinearAlgebra::Real/syevr> for Hermitian matrix



=cut

sub PDL::cheevr {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccheevr : goto &PDL::__Ncheevr;
}
*cheevr = \&PDL::cheevr;
#line 830 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Cchegv = \&PDL::__Cchegv;
#line 837 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Nchegv = \&PDL::__Nchegv;
#line 844 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 chegv

=for sig

  Signature: (complex [io]A(n,n);int itype();int jobz(); int uplo();complex [io]B(n,n);[o]w(n); int [o]info(); [t]rwork(rworkn))


=for ref

Complex version of L<PDL::LinearAlgebra::Real/sygv> for Hermitian matrix


=cut

sub PDL::chegv {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Cchegv : goto &PDL::__Nchegv;
}
*chegv = \&PDL::chegv;
#line 868 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Cchegvd = \&PDL::__Cchegvd;
#line 875 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Nchegvd = \&PDL::__Nchegvd;
#line 882 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 chegvd

=for sig

  Signature: (complex [io,phys]A(n,n);int [phys]itype();int jobz(); int uplo();complex [io,phys]B(n,n);[o,phys]w(n); int [o,phys]info())



=for ref

Complex version of L<PDL::LinearAlgebra::Real/sygvd> for Hermitian matrix



=cut

sub PDL::chegvd {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Cchegvd : goto &PDL::__Nchegvd;
}
*chegvd = \&PDL::chegvd;
#line 908 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Cchegvx = \&PDL::__Cchegvx;
#line 915 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Nchegvx = \&PDL::__Nchegvx;
#line 922 "Complex.pm"



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
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Cchegvx : goto &PDL::__Nchegvx;
}
*chegvx = \&PDL::chegvx;
#line 952 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccgesv = \&PDL::__Ccgesv;
#line 959 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncgesv = \&PDL::__Ncgesv;
#line 966 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cgesv

=for sig

  Signature: (complex [io,phys]A(n,n);complex   [io,phys]B(n,m); int [o,phys]ipiv(n); int [o,phys]info())


=for ref

Complex version of L<PDL::LinearAlgebra::Real/gesv>



=cut

sub PDL::cgesv {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccgesv : goto &PDL::__Ncgesv;
}
*cgesv = \&PDL::cgesv;
#line 991 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccgesvx = \&PDL::__Ccgesvx;
#line 998 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncgesvx = \&PDL::__Ncgesvx;
#line 1005 "Complex.pm"



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
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccgesvx : goto &PDL::__Ncgesvx;
}
*cgesvx = \&PDL::cgesvx;
#line 1034 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccsysv = \&PDL::__Ccsysv;
#line 1041 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncsysv = \&PDL::__Ncsysv;
#line 1048 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 csysv

=for sig

  Signature: (complex [io,phys]A(n,n);  int uplo();complex  [io,phys]B(n,m); int [o]ipiv(n); int [o]info())


=for ref

Complex version of L<PDL::LinearAlgebra::Real/sysv>



=cut

sub PDL::csysv {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccsysv : goto &PDL::__Ncsysv;
}
*csysv = \&PDL::csysv;
#line 1073 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccsysvx = \&PDL::__Ccsysvx;
#line 1080 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncsysvx = \&PDL::__Ncsysvx;
#line 1087 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 csysvx

=for sig

  Signature: (complex [phys]A(n,n); int uplo(); int fact();complex  [phys]B(n,m);complex  [io,phys]af(n,n); int [io,phys]ipiv(n);complex  [o]X(n,m); [o]rcond(); [o]ferr(m); [o]berr(m); int [o]info(); [t]rwork(n))


=for ref

Complex version of L<PDL::LinearAlgebra::Real/sysvx>



=cut

sub PDL::csysvx {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccsysvx : goto &PDL::__Ncsysvx;
}
*csysvx = \&PDL::csysvx;
#line 1112 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Cchesv = \&PDL::__Cchesv;
#line 1119 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Nchesv = \&PDL::__Nchesv;
#line 1126 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 chesv

=for sig

  Signature: (complex [io,phys]A(n,n);  int uplo();complex  [io,phys]B(n,m); int [o,phys]ipiv(n); int [o,phys]info())


=for ref

Complex version of L<PDL::LinearAlgebra::Real/sysv> for Hermitian matrix


=cut

sub PDL::chesv {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Cchesv : goto &PDL::__Nchesv;
}
*chesv = \&PDL::chesv;
#line 1150 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Cchesvx = \&PDL::__Cchesvx;
#line 1157 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Nchesvx = \&PDL::__Nchesvx;
#line 1164 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 chesvx

=for sig

  Signature: (complex A(n,n); int uplo(); int fact();complex  B(n,m);complex  [io]af(n,n); int [io]ipiv(n);complex  [o]X(n,m); [o]rcond(); [o]ferr(m); [o]berr(m); int [o]info(); [t]rwork(n))


=for ref

Complex version of L<PDL::LinearAlgebra::Real/sysvx> for Hermitian matrix


=cut

sub PDL::chesvx {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Cchesvx : goto &PDL::__Nchesvx;
}
*chesvx = \&PDL::chesvx;
#line 1188 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccposv = \&PDL::__Ccposv;
#line 1195 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncposv = \&PDL::__Ncposv;
#line 1202 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cposv

=for sig

  Signature: (complex [io,phys]A(n,n);  int uplo();complex  [io,phys]B(n,m); int [o,phys]info())



=for ref

Complex version of L<PDL::LinearAlgebra::Real/posv> for Hermitian positive definite matrix



=cut

sub PDL::cposv {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccposv : goto &PDL::__Ncposv;
}
*cposv = \&PDL::cposv;
#line 1228 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccposvx = \&PDL::__Ccposvx;
#line 1235 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncposvx = \&PDL::__Ncposvx;
#line 1242 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cposvx

=for sig

  Signature: (complex [io]A(n,n); int uplo(); int fact();complex  [io]B(n,m);complex  [io]af(n,n); int [io]equed(); [o]s(p);complex  [o]X(n,m); [o]rcond(); [o]ferr(m); [o]berr(m); int [o]info(); [t]rwork(rworkn); [t]work(workn))


=for ref

Complex version of L<PDL::LinearAlgebra::Real/posvx> for Hermitian positive definite matrix


=cut

sub PDL::cposvx {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccposvx : goto &PDL::__Ncposvx;
}
*cposvx = \&PDL::cposvx;
#line 1266 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccgels = \&PDL::__Ccgels;
#line 1273 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncgels = \&PDL::__Ncgels;
#line 1280 "Complex.pm"



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
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccgels : goto &PDL::__Ncgels;
}
*cgels = \&PDL::cgels;
#line 1309 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccgelsy = \&PDL::__Ccgelsy;
#line 1316 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncgelsy = \&PDL::__Ncgelsy;
#line 1323 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cgelsy

=for sig

  Signature: (complex [io]A(m,n);complex  [io]B(p,q); rcond(); int [io]jpvt(n); int [o]rank();int [o]info(); [t]rwork(rworkn))


=for ref

Complex version of L<PDL::LinearAlgebra::Real/gelsy>



=cut

sub PDL::cgelsy {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccgelsy : goto &PDL::__Ncgelsy;
}
*cgelsy = \&PDL::cgelsy;
#line 1348 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccgelss = \&PDL::__Ccgelss;
#line 1355 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncgelss = \&PDL::__Ncgelss;
#line 1362 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cgelss

=for sig

  Signature: (complex [io]A(m,n);complex  [io]B(p,q); rcond(); [o]s(r); int [o]rank();int [o]info(); [t]rwork(rworkn))


=for ref

Complex version of L<PDL::LinearAlgebra::Real/gelss>



=cut

sub PDL::cgelss {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccgelss : goto &PDL::__Ncgelss;
}
*cgelss = \&PDL::cgelss;
#line 1387 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccgelsd = \&PDL::__Ccgelsd;
#line 1394 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncgelsd = \&PDL::__Ncgelsd;
#line 1401 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cgelsd

=for sig

  Signature: (complex [io]A(m,n);complex  [io]B(p,q); rcond(); [o]s(minmn); int [o]rank();int [o]info(); int [t]iwork(iworkn); [t]rwork(rworkn))


=for ref

Complex version of L<PDL::LinearAlgebra::Real/gelsd>



=cut

sub PDL::cgelsd {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccgelsd : goto &PDL::__Ncgelsd;
}
*cgelsd = \&PDL::cgelsd;
#line 1426 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccgglse = \&PDL::__Ccgglse;
#line 1433 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncgglse = \&PDL::__Ncgglse;
#line 1440 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cgglse

=for sig

  Signature: (complex [phys]A(m,n);complex  [phys]B(p,n);complex [io,phys]c(m);complex [phys]d(p);complex [o,phys]x(n);int [o,phys]info())


=for ref

Complex version of L<PDL::LinearAlgebra::Real/gglse>



=cut

sub PDL::cgglse {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccgglse : goto &PDL::__Ncgglse;
}
*cgglse = \&PDL::cgglse;
#line 1465 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccggglm = \&PDL::__Ccggglm;
#line 1472 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncggglm = \&PDL::__Ncggglm;
#line 1479 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cggglm

=for sig

  Signature: (complex [phys]A(n,m);complex  [phys]B(n,p);complex [phys]d(n);complex [o,phys]x(m);complex [o,phys]y(p);int [o,phys]info())


=for ref

Complex version of L<PDL::LinearAlgebra::Real/ggglm>



=cut

sub PDL::cggglm {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccggglm : goto &PDL::__Ncggglm;
}
*cggglm = \&PDL::cggglm;
#line 1504 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccgetrf = \&PDL::__Ccgetrf;
#line 1511 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncgetrf = \&PDL::__Ncgetrf;
#line 1518 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cgetrf

=for sig

  Signature: (complex [io]A(m,n); int [o]ipiv(p); int [o]info())


=for ref

Complex version of L<PDL::LinearAlgebra::Real/getrf>



=cut

sub PDL::cgetrf {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccgetrf : goto &PDL::__Ncgetrf;
}
*cgetrf = \&PDL::cgetrf;
#line 1543 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccgetf2 = \&PDL::__Ccgetf2;
#line 1550 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncgetf2 = \&PDL::__Ncgetf2;
#line 1557 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cgetf2

=for sig

  Signature: (complex [io]A(m,n); int [o]ipiv(p); int [o]info())


=for ref

Complex version of L<PDL::LinearAlgebra::Real/getf2>



=cut

sub PDL::cgetf2 {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccgetf2 : goto &PDL::__Ncgetf2;
}
*cgetf2 = \&PDL::cgetf2;
#line 1582 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccsytrf = \&PDL::__Ccsytrf;
#line 1589 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncsytrf = \&PDL::__Ncsytrf;
#line 1596 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 csytrf

=for sig

  Signature: (complex [io,phys]A(n,n); int uplo(); int [o,phys]ipiv(n); int [o,phys]info())


=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytrf>



=cut

sub PDL::csytrf {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccsytrf : goto &PDL::__Ncsytrf;
}
*csytrf = \&PDL::csytrf;
#line 1621 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccsytf2 = \&PDL::__Ccsytf2;
#line 1628 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncsytf2 = \&PDL::__Ncsytf2;
#line 1635 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 csytf2

=for sig

  Signature: (complex [io,phys]A(n,n); int uplo(); int [o,phys]ipiv(n); int [o,phys]info())


=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytf2>



=cut

sub PDL::csytf2 {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccsytf2 : goto &PDL::__Ncsytf2;
}
*csytf2 = \&PDL::csytf2;
#line 1660 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccchetrf = \&PDL::__Ccchetrf;
#line 1667 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncchetrf = \&PDL::__Ncchetrf;
#line 1674 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cchetrf

=for sig

  Signature: (complex [io]A(n,n); int uplo(); int [o]ipiv(n); int [o]info(); [t]work(workn))


=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytrf> for Hermitian matrix


=cut

sub PDL::cchetrf {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccchetrf : goto &PDL::__Ncchetrf;
}
*cchetrf = \&PDL::cchetrf;
#line 1698 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Cchetf2 = \&PDL::__Cchetf2;
#line 1705 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Nchetf2 = \&PDL::__Nchetf2;
#line 1712 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 chetf2

=for sig

  Signature: (complex [io]A(n,n); int uplo(); int [o]ipiv(n); int [o]info())


=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytf2> for Hermitian matrix


=cut

sub PDL::chetf2 {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Cchetf2 : goto &PDL::__Nchetf2;
}
*chetf2 = \&PDL::chetf2;
#line 1736 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccpotrf = \&PDL::__Ccpotrf;
#line 1743 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncpotrf = \&PDL::__Ncpotrf;
#line 1750 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cpotrf

=for sig

  Signature: (complex [io,phys]A(n,n); int uplo(); int [o,phys]info())



=for ref

Complex version of L<PDL::LinearAlgebra::Real/potrf> for Hermitian positive definite matrix



=cut

sub PDL::cpotrf {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccpotrf : goto &PDL::__Ncpotrf;
}
*cpotrf = \&PDL::cpotrf;
#line 1776 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccpotf2 = \&PDL::__Ccpotf2;
#line 1783 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncpotf2 = \&PDL::__Ncpotf2;
#line 1790 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cpotf2

=for sig

  Signature: (complex [io,phys]A(n,n); int uplo(); int [o,phys]info())



=for ref

Complex version of L<PDL::LinearAlgebra::Real/potf2> for Hermitian positive definite matrix



=cut

sub PDL::cpotf2 {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccpotf2 : goto &PDL::__Ncpotf2;
}
*cpotf2 = \&PDL::cpotf2;
#line 1816 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccgetri = \&PDL::__Ccgetri;
#line 1823 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncgetri = \&PDL::__Ncgetri;
#line 1830 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cgetri

=for sig

  Signature: (complex [io,phys]A(n,n); int [phys]ipiv(n); int [o,phys]info())


=for ref

Complex version of L<PDL::LinearAlgebra::Real/getri>



=cut

sub PDL::cgetri {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccgetri : goto &PDL::__Ncgetri;
}
*cgetri = \&PDL::cgetri;
#line 1855 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccsytri = \&PDL::__Ccsytri;
#line 1862 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncsytri = \&PDL::__Ncsytri;
#line 1869 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 csytri

=for sig

  Signature: (complex [io]A(n,n); int uplo(); int ipiv(n); int [o]info(); [t]work(workn))


=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytri>



=cut

sub PDL::csytri {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccsytri : goto &PDL::__Ncsytri;
}
*csytri = \&PDL::csytri;
#line 1894 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Cchetri = \&PDL::__Cchetri;
#line 1901 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Nchetri = \&PDL::__Nchetri;
#line 1908 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 chetri

=for sig

  Signature: (complex [io]A(n,n); int uplo(); int ipiv(n); int [o]info(); [t]work(workn))


=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytri> for Hermitian matrix


=cut

sub PDL::chetri {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Cchetri : goto &PDL::__Nchetri;
}
*chetri = \&PDL::chetri;
#line 1932 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccpotri = \&PDL::__Ccpotri;
#line 1939 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncpotri = \&PDL::__Ncpotri;
#line 1946 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cpotri

=for sig

  Signature: (complex [io,phys]A(n,n); int uplo(); int [o,phys]info())


=for ref

Complex version of L<PDL::LinearAlgebra::Real/potri>



=cut

sub PDL::cpotri {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccpotri : goto &PDL::__Ncpotri;
}
*cpotri = \&PDL::cpotri;
#line 1971 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Cctrtri = \&PDL::__Cctrtri;
#line 1978 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Nctrtri = \&PDL::__Nctrtri;
#line 1985 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 ctrtri

=for sig

  Signature: (complex [io,phys]A(n,n); int uplo(); int diag(); int [o,phys]info())


=for ref

Complex version of L<PDL::LinearAlgebra::Real/trtri>



=cut

sub PDL::ctrtri {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Cctrtri : goto &PDL::__Nctrtri;
}
*ctrtri = \&PDL::ctrtri;
#line 2010 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Cctrti2 = \&PDL::__Cctrti2;
#line 2017 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Nctrti2 = \&PDL::__Nctrti2;
#line 2024 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 ctrti2

=for sig

  Signature: (complex [io,phys]A(n,n); int uplo(); int diag(); int [o,phys]info())


=for ref

Complex version of L<PDL::LinearAlgebra::Real/trti2>



=cut

sub PDL::ctrti2 {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Cctrti2 : goto &PDL::__Nctrti2;
}
*ctrti2 = \&PDL::ctrti2;
#line 2049 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccgetrs = \&PDL::__Ccgetrs;
#line 2056 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncgetrs = \&PDL::__Ncgetrs;
#line 2063 "Complex.pm"



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
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccgetrs : goto &PDL::__Ncgetrs;
}
*cgetrs = \&PDL::cgetrs;
#line 2095 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccsytrs = \&PDL::__Ccsytrs;
#line 2102 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncsytrs = \&PDL::__Ncsytrs;
#line 2109 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 csytrs

=for sig

  Signature: (complex [phys]A(n,n); int uplo();complex [io,phys]B(n,m); int [phys]ipiv(n); int [o,phys]info())


=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytrs>



=cut

sub PDL::csytrs {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccsytrs : goto &PDL::__Ncsytrs;
}
*csytrs = \&PDL::csytrs;
#line 2134 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Cchetrs = \&PDL::__Cchetrs;
#line 2141 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Nchetrs = \&PDL::__Nchetrs;
#line 2148 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 chetrs

=for sig

  Signature: (complex [phys]A(n,n); int uplo();complex [io,phys]B(n,m); int [phys]ipiv(n); int [o,phys]info())



=for ref

Complex version of L<PDL::LinearAlgebra::Real/sytrs> for Hermitian matrix



=cut

sub PDL::chetrs {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Cchetrs : goto &PDL::__Nchetrs;
}
*chetrs = \&PDL::chetrs;
#line 2174 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccpotrs = \&PDL::__Ccpotrs;
#line 2181 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncpotrs = \&PDL::__Ncpotrs;
#line 2188 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cpotrs

=for sig

  Signature: (complex [phys]A(n,n); int uplo();complex  [io,phys]B(n,m); int [o,phys]info())



=for ref

Complex version of L<PDL::LinearAlgebra::Real/potrs> for Hermitian positive definite matrix



=cut

sub PDL::cpotrs {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccpotrs : goto &PDL::__Ncpotrs;
}
*cpotrs = \&PDL::cpotrs;
#line 2214 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Cctrtrs = \&PDL::__Cctrtrs;
#line 2221 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Nctrtrs = \&PDL::__Nctrtrs;
#line 2228 "Complex.pm"



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
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Cctrtrs : goto &PDL::__Nctrtrs;
}
*ctrtrs = \&PDL::ctrtrs;
#line 2260 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Cclatrs = \&PDL::__Cclatrs;
#line 2267 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Nclatrs = \&PDL::__Nclatrs;
#line 2274 "Complex.pm"



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
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Cclatrs : goto &PDL::__Nclatrs;
}
*clatrs = \&PDL::clatrs;
#line 2305 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccgecon = \&PDL::__Ccgecon;
#line 2312 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncgecon = \&PDL::__Ncgecon;
#line 2319 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cgecon

=for sig

  Signature: (complex A(n,n); int norm(); anorm(); [o]rcond();int [o]info(); [t]rwork(rworkn); [t]work(workn))


=for ref

Complex version of L<PDL::LinearAlgebra::Real/gecon>



=cut

sub PDL::cgecon {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccgecon : goto &PDL::__Ncgecon;
}
*cgecon = \&PDL::cgecon;
#line 2344 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccsycon = \&PDL::__Ccsycon;
#line 2351 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncsycon = \&PDL::__Ncsycon;
#line 2358 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 csycon

=for sig

  Signature: (complex A(n,n); int uplo(); int ipiv(n); anorm(); [o]rcond();int [o]info(); [t]work(workn))


=for ref

Complex version of L<PDL::LinearAlgebra::Real/sycon>



=cut

sub PDL::csycon {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccsycon : goto &PDL::__Ncsycon;
}
*csycon = \&PDL::csycon;
#line 2383 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Cchecon = \&PDL::__Cchecon;
#line 2390 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Nchecon = \&PDL::__Nchecon;
#line 2397 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 checon

=for sig

  Signature: (complex A(n,n); int uplo(); int ipiv(n); anorm(); [o]rcond();int [o]info(); [t]work(workn))


=for ref

Complex version of L<PDL::LinearAlgebra::Real/sycon> for Hermitian matrix


=cut

sub PDL::checon {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Cchecon : goto &PDL::__Nchecon;
}
*checon = \&PDL::checon;
#line 2421 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccpocon = \&PDL::__Ccpocon;
#line 2428 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncpocon = \&PDL::__Ncpocon;
#line 2435 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cpocon

=for sig

  Signature: (complex A(n,n); int uplo(); anorm(); [o]rcond();int [o]info(); [t]work(workn); [t]rwork(n))


=for ref

Complex version of L<PDL::LinearAlgebra::Real/pocon> for Hermitian positive definite matrix


=cut

sub PDL::cpocon {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccpocon : goto &PDL::__Ncpocon;
}
*cpocon = \&PDL::cpocon;
#line 2459 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Cctrcon = \&PDL::__Cctrcon;
#line 2466 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Nctrcon = \&PDL::__Nctrcon;
#line 2473 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 ctrcon

=for sig

  Signature: (complex A(n,n); int norm();int uplo();int diag(); [o]rcond();int [o]info(); [t]work(workn); [t]rwork(n))


=for ref

Complex version of L<PDL::LinearAlgebra::Real/trcon>



=cut

sub PDL::ctrcon {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Cctrcon : goto &PDL::__Nctrcon;
}
*ctrcon = \&PDL::ctrcon;
#line 2498 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccgeqp3 = \&PDL::__Ccgeqp3;
#line 2505 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncgeqp3 = \&PDL::__Ncgeqp3;
#line 2512 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cgeqp3

=for sig

  Signature: (complex [io]A(m,n); int [io]jpvt(n);complex  [o]tau(k); int [o]info(); [t]rwork(rworkn))


=for ref

Complex version of L<PDL::LinearAlgebra::Real/geqp3>



=cut

sub PDL::cgeqp3 {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccgeqp3 : goto &PDL::__Ncgeqp3;
}
*cgeqp3 = \&PDL::cgeqp3;
#line 2537 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccgeqrf = \&PDL::__Ccgeqrf;
#line 2544 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncgeqrf = \&PDL::__Ncgeqrf;
#line 2551 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cgeqrf

=for sig

  Signature: (complex [io,phys]A(m,n);complex  [o,phys]tau(k); int [o,phys]info())


=for ref

Complex version of L<PDL::LinearAlgebra::Real/geqrf>



=cut

sub PDL::cgeqrf {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccgeqrf : goto &PDL::__Ncgeqrf;
}
*cgeqrf = \&PDL::cgeqrf;
#line 2576 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccungqr = \&PDL::__Ccungqr;
#line 2583 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncungqr = \&PDL::__Ncungqr;
#line 2590 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cungqr

=for sig

  Signature: (complex [io,phys]A(m,n);complex  [phys]tau(k); int [o,phys]info())



=for ref

Complex version of L<PDL::LinearAlgebra::Real/orgqr>



=cut

sub PDL::cungqr {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccungqr : goto &PDL::__Ncungqr;
}
*cungqr = \&PDL::cungqr;
#line 2616 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccunmqr = \&PDL::__Ccunmqr;
#line 2623 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncunmqr = \&PDL::__Ncunmqr;
#line 2630 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cunmqr

=for sig

  Signature: (complex [phys]A(p,k); int side(); int trans();complex  [phys]tau(k);complex  [io,phys]C(m,n);int [o,phys]info())


=for ref

Complex version of L<PDL::LinearAlgebra::Real/ormqr>. Here trans = 1 means conjugate transpose.


=cut

sub PDL::cunmqr {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccunmqr : goto &PDL::__Ncunmqr;
}
*cunmqr = \&PDL::cunmqr;
#line 2654 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccgelqf = \&PDL::__Ccgelqf;
#line 2661 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncgelqf = \&PDL::__Ncgelqf;
#line 2668 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cgelqf

=for sig

  Signature: (complex [io,phys]A(m,n);complex  [o,phys]tau(k); int [o,phys]info())


=for ref

Complex version of L<PDL::LinearAlgebra::Real/gelqf>



=cut

sub PDL::cgelqf {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccgelqf : goto &PDL::__Ncgelqf;
}
*cgelqf = \&PDL::cgelqf;
#line 2693 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccunglq = \&PDL::__Ccunglq;
#line 2700 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncunglq = \&PDL::__Ncunglq;
#line 2707 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cunglq

=for sig

  Signature: (complex [io,phys]A(m,n);complex  [phys]tau(k); int [o,phys]info())


=for ref

Complex version of L<PDL::LinearAlgebra::Real/orglq>


=cut

sub PDL::cunglq {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccunglq : goto &PDL::__Ncunglq;
}
*cunglq = \&PDL::cunglq;
#line 2731 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccunmlq = \&PDL::__Ccunmlq;
#line 2738 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncunmlq = \&PDL::__Ncunmlq;
#line 2745 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cunmlq

=for sig

  Signature: (complex [phys]A(k,p); int side(); int trans();complex  [phys]tau(k);complex  [io,phys]C(m,n);int [o,phys]info())



=for ref

Complex version of L<PDL::LinearAlgebra::Real/ormlq>. Here trans = 1 means conjugate transpose.



=cut

sub PDL::cunmlq {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccunmlq : goto &PDL::__Ncunmlq;
}
*cunmlq = \&PDL::cunmlq;
#line 2771 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccgeqlf = \&PDL::__Ccgeqlf;
#line 2778 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncgeqlf = \&PDL::__Ncgeqlf;
#line 2785 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cgeqlf

=for sig

  Signature: (complex [io,phys]A(m,n);complex  [o,phys]tau(k); int [o,phys]info())


=for ref

Complex version of L<PDL::LinearAlgebra::Real/geqlf>



=cut

sub PDL::cgeqlf {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccgeqlf : goto &PDL::__Ncgeqlf;
}
*cgeqlf = \&PDL::cgeqlf;
#line 2810 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccungql = \&PDL::__Ccungql;
#line 2817 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncungql = \&PDL::__Ncungql;
#line 2824 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cungql

=for sig

  Signature: (complex [io,phys]A(m,n);complex  [phys]tau(k); int [o,phys]info())



=for ref
Complex version of L<PDL::LinearAlgebra::Real/orgql>.


=cut

sub PDL::cungql {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccungql : goto &PDL::__Ncungql;
}
*cungql = \&PDL::cungql;
#line 2848 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccunmql = \&PDL::__Ccunmql;
#line 2855 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncunmql = \&PDL::__Ncunmql;
#line 2862 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cunmql

=for sig

  Signature: (complex [phys]A(p,k); int side(); int trans();complex  [phys]tau(k);complex  [io,phys]C(m,n);int [o,phys]info())


=for ref

Complex version of L<PDL::LinearAlgebra::Real/ormql>. Here trans = 1 means conjugate transpose.


=cut

sub PDL::cunmql {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccunmql : goto &PDL::__Ncunmql;
}
*cunmql = \&PDL::cunmql;
#line 2886 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccgerqf = \&PDL::__Ccgerqf;
#line 2893 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncgerqf = \&PDL::__Ncgerqf;
#line 2900 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cgerqf

=for sig

  Signature: (complex [io,phys]A(m,n);complex  [o,phys]tau(k); int [o,phys]info())


=for ref

Complex version of L<PDL::LinearAlgebra::Real/gerqf>



=cut

sub PDL::cgerqf {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccgerqf : goto &PDL::__Ncgerqf;
}
*cgerqf = \&PDL::cgerqf;
#line 2925 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccungrq = \&PDL::__Ccungrq;
#line 2932 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncungrq = \&PDL::__Ncungrq;
#line 2939 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cungrq

=for sig

  Signature: (complex [io,phys]A(m,n);complex  [phys]tau(k); int [o,phys]info())


=for ref

Complex version of L<PDL::LinearAlgebra::Real/orgrq>.


=cut

sub PDL::cungrq {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccungrq : goto &PDL::__Ncungrq;
}
*cungrq = \&PDL::cungrq;
#line 2963 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccunmrq = \&PDL::__Ccunmrq;
#line 2970 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncunmrq = \&PDL::__Ncunmrq;
#line 2977 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cunmrq

=for sig

  Signature: (complex [phys]A(k,p); int side(); int trans();complex  [phys]tau(k);complex  [io,phys]C(m,n);int [o,phys]info())



=for ref

Complex version of L<PDL::LinearAlgebra::Real/ormrq>. Here trans = 1 means conjugate transpose.



=cut

sub PDL::cunmrq {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccunmrq : goto &PDL::__Ncunmrq;
}
*cunmrq = \&PDL::cunmrq;
#line 3003 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Cctzrzf = \&PDL::__Cctzrzf;
#line 3010 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Nctzrzf = \&PDL::__Nctzrzf;
#line 3017 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 ctzrzf

=for sig

  Signature: (complex [io,phys]A(m,n);complex  [o,phys]tau(k); int [o,phys]info())


=for ref

Complex version of L<PDL::LinearAlgebra::Real/tzrzf>



=cut

sub PDL::ctzrzf {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Cctzrzf : goto &PDL::__Nctzrzf;
}
*ctzrzf = \&PDL::ctzrzf;
#line 3042 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccunmrz = \&PDL::__Ccunmrz;
#line 3049 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncunmrz = \&PDL::__Ncunmrz;
#line 3056 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cunmrz

=for sig

  Signature: (complex [phys]A(k,p); int side(); int trans();complex  [phys]tau(k);complex  [io,phys]C(m,n);int [o,phys]info())


=for ref

Complex version of L<PDL::LinearAlgebra::Real/ormrz>. Here trans = 1 means conjugate transpose.


=cut

sub PDL::cunmrz {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccunmrz : goto &PDL::__Ncunmrz;
}
*cunmrz = \&PDL::cunmrz;
#line 3080 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccgehrd = \&PDL::__Ccgehrd;
#line 3087 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncgehrd = \&PDL::__Ncgehrd;
#line 3094 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cgehrd

=for sig

  Signature: (complex [io,phys]A(n,n); int [phys]ilo();int [phys]ihi();complex [o,phys]tau(k); int [o,phys]info())


=for ref

Complex version of L<PDL::LinearAlgebra::Real/gehrd>



=cut

sub PDL::cgehrd {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccgehrd : goto &PDL::__Ncgehrd;
}
*cgehrd = \&PDL::cgehrd;
#line 3119 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccunghr = \&PDL::__Ccunghr;
#line 3126 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncunghr = \&PDL::__Ncunghr;
#line 3133 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cunghr

=for sig

  Signature: (complex [io,phys]A(n,n); int [phys]ilo();int [phys]ihi();complex [phys]tau(k); int [o,phys]info())


=for ref

Complex version of L<PDL::LinearAlgebra::Real/orghr>


=cut

sub PDL::cunghr {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccunghr : goto &PDL::__Ncunghr;
}
*cunghr = \&PDL::cunghr;
#line 3157 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Cchseqr = \&PDL::__Cchseqr;
#line 3164 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Nchseqr = \&PDL::__Nchseqr;
#line 3171 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 chseqr

=for sig

  Signature: (complex [io,phys]H(n,n); int job();int compz();int [phys]ilo();int [phys]ihi();complex [o,phys]w(n);complex  [o,phys]Z(m,m); int [o,phys]info())


=for ref

Complex version of L<PDL::LinearAlgebra::Real/hseqr>



=cut

sub PDL::chseqr {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Cchseqr : goto &PDL::__Nchseqr;
}
*chseqr = \&PDL::chseqr;
#line 3196 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Cctrevc = \&PDL::__Cctrevc;
#line 3203 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Nctrevc = \&PDL::__Nctrevc;
#line 3210 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 ctrevc

=for sig

  Signature: (complex [io]T(n,n); int side();int howmny();int select(q);complex [o]VL(m,m);complex  [o]VR(p,p);int [o]m(); int [o]info(); [t]work(workn))


=for ref

Complex version of L<PDL::LinearAlgebra::Real/trevc>



=cut

sub PDL::ctrevc {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Cctrevc : goto &PDL::__Nctrevc;
}
*ctrevc = \&PDL::ctrevc;
#line 3235 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Cctgevc = \&PDL::__Cctgevc;
#line 3242 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Nctgevc = \&PDL::__Nctgevc;
#line 3249 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 ctgevc

=for sig

  Signature: (complex [io]A(n,n); int side();int howmny();complex  [io]B(n,n);int select(q);complex [o]VL(m,m);complex  [o]VR(p,p);int [o]m(); int [o]info(); [t]work(workn))


=for ref

Complex version of L<PDL::LinearAlgebra::Real/tgevc>



=cut

sub PDL::ctgevc {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Cctgevc : goto &PDL::__Nctgevc;
}
*ctgevc = \&PDL::ctgevc;
#line 3274 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccgebal = \&PDL::__Ccgebal;
#line 3281 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncgebal = \&PDL::__Ncgebal;
#line 3288 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cgebal

=for sig

  Signature: (complex [io,phys]A(n,n); int job(); int [o,phys]ilo();int [o,phys]ihi();[o,phys]scale(n); int [o,phys]info())


=for ref

Complex version of L<PDL::LinearAlgebra::Real/gebal>



=cut

sub PDL::cgebal {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccgebal : goto &PDL::__Ncgebal;
}
*cgebal = \&PDL::cgebal;
#line 3313 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Cclange = \&PDL::__Cclange;
#line 3320 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Nclange = \&PDL::__Nclange;
#line 3327 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 clange

=for sig

  Signature: (complex A(n,m); int norm(); [o]b(); [t]work(workn))


=for ref

Complex version of L<PDL::LinearAlgebra::Real/lange>



=cut

sub PDL::clange {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Cclange : goto &PDL::__Nclange;
}
*clange = \&PDL::clange;
#line 3352 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Cclansy = \&PDL::__Cclansy;
#line 3359 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Nclansy = \&PDL::__Nclansy;
#line 3366 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 clansy

=for sig

  Signature: (complex A(n,n); int uplo(); int norm(); [o]b(); [t]work(workn))


=for ref

Complex version of L<PDL::LinearAlgebra::Real/lansy>



=cut

sub PDL::clansy {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Cclansy : goto &PDL::__Nclansy;
}
*clansy = \&PDL::clansy;
#line 3391 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Cclantr = \&PDL::__Cclantr;
#line 3398 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Nclantr = \&PDL::__Nclantr;
#line 3405 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 clantr

=for sig

  Signature: (complex A(m,n); int uplo(); int norm();int diag(); [o]b(); [t]work(workn))


=for ref

Complex version of L<PDL::LinearAlgebra::Real/lantr>



=cut

sub PDL::clantr {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Cclantr : goto &PDL::__Nclantr;
}
*clantr = \&PDL::clantr;
#line 3430 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccgemm = \&PDL::__Ccgemm;
#line 3437 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncgemm = \&PDL::__Ncgemm;
#line 3444 "Complex.pm"



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
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccgemm : goto &PDL::__Ncgemm;
}
*cgemm = \&PDL::cgemm;
#line 3480 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccmmult = \&PDL::__Ccmmult;
#line 3487 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncmmult = \&PDL::__Ncmmult;
#line 3494 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cmmult

=for sig

  Signature: (complex [phys]A(m,n);complex  [phys]B(p,m);complex  [o,phys]C(p,n))


=for ref

Complex version of L<PDL::LinearAlgebra::Real/mmult>



=cut

sub PDL::cmmult {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccmmult : goto &PDL::__Ncmmult;
}
*cmmult = \&PDL::cmmult;
#line 3519 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Cccrossprod = \&PDL::__Cccrossprod;
#line 3526 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Nccrossprod = \&PDL::__Nccrossprod;
#line 3533 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 ccrossprod

=for sig

  Signature: (complex [phys]A(n,m);complex  [phys]B(p,m);complex  [o,phys]C(p,n))


=for ref

Complex version of L<PDL::LinearAlgebra::Real/crossprod>



=cut

sub PDL::ccrossprod {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Cccrossprod : goto &PDL::__Nccrossprod;
}
*ccrossprod = \&PDL::ccrossprod;
#line 3558 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccsyrk = \&PDL::__Ccsyrk;
#line 3565 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncsyrk = \&PDL::__Ncsyrk;
#line 3572 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 csyrk

=for sig

  Signature: (complex [phys]A(m,n); int uplo(); int trans();complex  [phys]alpha();complex  [phys]beta();complex  [io,phys]C(p,p))


=for ref

Complex version of L<PDL::LinearAlgebra::Real/syrk>



=cut

sub PDL::csyrk {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccsyrk : goto &PDL::__Ncsyrk;
}
*csyrk = \&PDL::csyrk;
#line 3597 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccdot = \&PDL::__Ccdot;
#line 3604 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncdot = \&PDL::__Ncdot;
#line 3611 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cdot

=for sig

  Signature: (complex [phys]a(n);complex [phys]b(n);complex [o]c())


=for ref

Complex version of L<PDL::LinearAlgebra::Real/dot>



=cut

sub PDL::cdot {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccdot : goto &PDL::__Ncdot;
}
*cdot = \&PDL::cdot;
#line 3636 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccdotc = \&PDL::__Ccdotc;
#line 3643 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncdotc = \&PDL::__Ncdotc;
#line 3650 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cdotc

=for sig

  Signature: (complex [phys]a(n);complex [phys]b(n);complex [o,phys]c())


=for ref

Forms the dot product of two vectors, conjugating the first   
vector.


=cut

sub PDL::cdotc {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccdotc : goto &PDL::__Ncdotc;
}
*cdotc = \&PDL::cdotc;
#line 3675 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccaxpy = \&PDL::__Ccaxpy;
#line 3682 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncaxpy = \&PDL::__Ncaxpy;
#line 3689 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 caxpy

=for sig

  Signature: (complex [phys]a(n);complex [phys] alpha();complex [io,phys]b(n))


=for ref

Complex version of L<PDL::LinearAlgebra::Real/axpy>



=cut

sub PDL::caxpy {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccaxpy : goto &PDL::__Ncaxpy;
}
*caxpy = \&PDL::caxpy;
#line 3714 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccnrm2 = \&PDL::__Ccnrm2;
#line 3721 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncnrm2 = \&PDL::__Ncnrm2;
#line 3728 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cnrm2

=for sig

  Signature: (complex [phys]a(n);[o]b())


=for ref

Complex version of L<PDL::LinearAlgebra::Real/nrm2>



=cut

sub PDL::cnrm2 {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccnrm2 : goto &PDL::__Ncnrm2;
}
*cnrm2 = \&PDL::cnrm2;
#line 3753 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccasum = \&PDL::__Ccasum;
#line 3760 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncasum = \&PDL::__Ncasum;
#line 3767 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 casum

=for sig

  Signature: (complex [phys]a(n);[o]b())


=for ref

Complex version of L<PDL::LinearAlgebra::Real/asum>



=cut

sub PDL::casum {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccasum : goto &PDL::__Ncasum;
}
*casum = \&PDL::casum;
#line 3792 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccscal = \&PDL::__Ccscal;
#line 3799 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncscal = \&PDL::__Ncscal;
#line 3806 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 cscal

=for sig

  Signature: (complex [io,phys]a(n);complex scale())


=for ref

Complex version of L<PDL::LinearAlgebra::Real/scal>



=cut

sub PDL::cscal {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccscal : goto &PDL::__Ncscal;
}
*cscal = \&PDL::cscal;
#line 3831 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccsscal = \&PDL::__Ccsscal;
#line 3838 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncsscal = \&PDL::__Ncsscal;
#line 3845 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 csscal

=for sig

  Signature: (complex [io,phys]a(n);scale())



=for ref

Scales a complex vector by a real constant.



=cut

sub PDL::csscal {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccsscal : goto &PDL::__Ncsscal;
}
*csscal = \&PDL::csscal;
#line 3871 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ccrotg = \&PDL::__Ccrotg;
#line 3878 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Ncrotg = \&PDL::__Ncrotg;
#line 3885 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 crotg

=for sig

  Signature: (complex [io,phys]a();complex [phys]b();[o,phys]c();complex  [o,phys]s())


=for ref

Complex version of L<PDL::LinearAlgebra::Real/rotg>



=cut

sub PDL::crotg {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Ccrotg : goto &PDL::__Ncrotg;
}
*crotg = \&PDL::crotg;
#line 3910 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Cclacpy = \&PDL::__Cclacpy;
#line 3917 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Nclacpy = \&PDL::__Nclacpy;
#line 3924 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 clacpy

=for sig

  Signature: (complex [phys]A(m,n); int uplo();complex  [o,phys]B(p,n))


=for ref

Complex version of L<PDL::LinearAlgebra::Real/lacpy>



=cut

sub PDL::clacpy {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Cclacpy : goto &PDL::__Nclacpy;
}
*clacpy = \&PDL::clacpy;
#line 3949 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Cclaswp = \&PDL::__Cclaswp;
#line 3956 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Nclaswp = \&PDL::__Nclaswp;
#line 3963 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 claswp

=for sig

  Signature: (complex [io,phys]A(m,n); int [phys]k1(); int [phys]k2(); int [phys]ipiv(p))


=for ref

Complex version of L<PDL::LinearAlgebra::Real/laswp>



=cut

sub PDL::claswp {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Cclaswp : goto &PDL::__Nclaswp;
}
*claswp = \&PDL::claswp;
#line 3988 "Complex.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 ctricpy

=for sig

  Signature: (A(c=2,m,n);int uplo();[o] C(c=2,m,n))


=for ref

Copy triangular part to another matrix. If uplo == 0 copy upper triangular part.



=for bad

ctricpy does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4016 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*ctricpy = \&PDL::ctricpy;
#line 4023 "Complex.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



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
#line 4052 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*cmstack = \&PDL::cmstack;
#line 4059 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Cccharpol = \&PDL::__Cccharpol;
#line 4066 "Complex.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*__Nccharpol = \&PDL::__Nccharpol;
#line 4073 "Complex.pm"



#line 23 "../pp_defc.pl"

=head2 ccharpol

=for sig

  Signature: (A(c=2,n,n);[o]Y(c=2,n,n);[o]out(c=2,p); [t]rwork(rworkn))


=for ref

Complex version of L<PDL::LinearAlgebra::Real/charpol>



=cut

sub PDL::ccharpol {
  ref $_[0] eq 'PDL::Complex' || $_[0]->type->real ? goto &PDL::__Cccharpol : goto &PDL::__Nccharpol;
}
*ccharpol = \&PDL::ccharpol;
#line 4098 "Complex.pm"





#line 5153 "complex.pd"

=head1 AUTHOR

Copyright (C) Grégory Vanuxem 2005-2018.

This library is free software; you can redistribute it and/or modify
it under the terms of the Perl Artistic License as in the file Artistic_2
in this distribution.

=cut
#line 4115 "Complex.pm"




# Exit with OK status

1;

package SPVM::Math::Complex;

our $VERSION = '0.01';

1;

=head1 NAME

SPVM::Math::Complex - Math Functions

=head1 CAUTHION

B<The SPVM::Math::Complex module depends on the L<SPVM> module. The L<SPVM> module is yet before 1.0 released. The beta tests are doing. There will be a little reasonable changes yet.>

=head1 SYNOPSYS

=head2 SPVM

  use Math;
  
  my $sin = Math->sin(Math->PI / 4);

=head2 Perl
  
  use SPVM 'Math';
  
  my $sin = SPVM::Math::Complex->sin(SPVM::Math::Complex->PI / 4);

=head1 DESCRIPTION

The C<Math> class defines mathmatical functions that contains C99 math functions.

=head1 CLASS METHODS

The list of class methods of C<Math> class.

=head2 cabs

  static method cabs : double ($z : Complex_2d)

The binding to the C<cabs> function of C language. This function is declared in C<complex.h>.

=head2 cabsf

  static method cabsf : float ($z : Complex_2f)

The binding to the C<cabsf> function of C language. This function is declared in C<complex.h>.

=head2 cacos

  static method cacos : Complex_2d ($z : Complex_2d)

The binding to the C<cacos> function of C language. This function is declared in C<complex.h>.

=head2 cacosf

  static method cacosf : Complex_2f ($z : Complex_2f)

The binding to the C<cacosf> function of C language. This function is declared in C<complex.h>.

=head2 cacosh

  static method cacosh : Complex_2d ($z : Complex_2d)

The binding to the C<cacosh> function of C language. This function is declared in C<complex.h>.

=head2 cacoshf

  static method cacoshf : Complex_2f ($z : Complex_2f)

The binding to the C<cacoshf> function of C language. This function is declared in C<complex.h>.

=head2 cadd

  static method cadd : Complex_2d ($z1 : Complex_2d, $z2 : Complex_2d)

The binding to the C<cadd> function of C language. This function is declared in C<complex.h>.

=head2 caddf

  static method caddf : Complex_2f ($z1 : Complex_2f, $z2 : Complex_2f)

The binding to the C<caddf> function of C language. This function is declared in C<complex.h>.

=head2 carg

  static method carg : double ($z : Complex_2d)

The binding to the C<carg> function of C language. This function is declared in C<complex.h>.

=head2 cargf

  static method cargf : float ($z : Complex_2f)

The binding to the C<cargf> function of C language. This function is declared in C<complex.h>.

=head2 casin

  static method casin : Complex_2d ($z : Complex_2d)

The binding to the C<casin> function of C language. This function is declared in C<complex.h>.

=head2 casinf

  static method casinf : Complex_2f ($z : Complex_2f)

The binding to the C<casinf> function of C language. This function is declared in C<complex.h>.

=head2 casinh

  static method casinh : Complex_2d ($z : Complex_2d)

The binding to the C<casinh> function of C language. This function is declared in C<complex.h>.

=head2 casinhf

  static method casinhf : Complex_2f ($z : Complex_2f)

The binding to the C<casinhf> function of C language. This function is declared in C<complex.h>.

=head2 catan

  static method catan : Complex_2d ($z : Complex_2d)

The binding to the C<catan> function of C language. This function is declared in C<complex.h>.

=head2 catanf

  static method catanf : Complex_2f ($z : Complex_2f)

The binding to the C<catanf> function of C language. This function is declared in C<complex.h>.

=head2 catanh

  static method catanh : Complex_2d ($z : Complex_2d)

The binding to the C<catanh> function of C language. This function is declared in C<complex.h>.

=head2 catanhf

  static method catanhf : Complex_2f ($z : Complex_2f)

The binding to the C<catanhf> function of C language. This function is declared in C<complex.h>.

=head2 cbrtf

  static method cbrtf : float ($x : float)

The binding to the C<cbrtf> function of C language. This function is declared in C<math.h>.

=head2 ccos

  static method ccos : Complex_2d ($z : Complex_2d)

The binding to the C<ccos> function of C language. This function is declared in C<complex.h>.

=head2 ccosf

  static method ccosf : Complex_2f ($z : Complex_2f)

The binding to the C<ccosf> function of C language. This function is declared in C<complex.h>.

=head2 ccosh

  static method ccosh : Complex_2d ($z : Complex_2d)

The binding to the C<ccosh> function of C language. This function is declared in C<complex.h>.

=head2 ccoshf

  static method ccoshf : Complex_2f ($z : Complex_2f)

The binding to the C<ccoshf> function of C language. This function is declared in C<complex.h>.

=head2 cdiv

  static method cdiv : Complex_2d ($z1 : Complex_2d, $z2 : Complex_2d)

double complex division.

=head2 cdivf

  static method cdivf : Complex_2f ($z1 : Complex_2f, $z2 : Complex_2f)

float complex division.

=head2 cexp

  static method cexp : Complex_2d ($z : Complex_2d)

The binding to the C<cexp> function of C language. This function is declared in C<complex.h>.

=head2 cexpf

  static method cexpf : Complex_2f ($z : Complex_2f)

The binding to the C<cexpf> function of C language. This function is declared in C<complex.h>.

=head2 clog

  static method clog : Complex_2d ($z : Complex_2d)

The binding to the C<clog> function of C language. This function is declared in C<complex.h>.

=head2 clogf

  static method clogf : Complex_2f ($z : Complex_2f)

The binding to the C<clogf> function of C language. This function is declared in C<complex.h>.

=head2 cmul

  static method cmul : Complex_2d ($z1 : Complex_2d, $z2 : Complex_2d)

double complex multiplication.

=head2 cmulf

  static method cmulf : Complex_2f ($z1 : Complex_2f, $z2 : Complex_2f)

float complex multiplication.

=head2 complex

  static method complex : Complex_2d ($x : double, $y : double)

Create double complex value. This value is defined in L<Complex_2d|SPVM::Complex_2d>.

=head2 complexf

  static method complexf : Complex_2f ($x : float, $y : float)

Create float complex value. This value is defined in L<Complex_2f|SPVM::Complex_2f>.

=head2 conj

  static method conj : Complex_2d ($z : Complex_2d)

The binding to the C<conj> function of C language. This function is declared in C<complex.h>.

=head2 conjf

  static method conjf : Complex_2f ($z : Complex_2f)

The binding to the C<conjf> function of C language. This function is declared in C<complex.h>.

=head2 copysignf

  static method copysignf : float ($x1 : float, $x2 : float)

The binding to the C<copysignf> function of C language. This function is declared in C<math.h>.

=head2 cpow

  static method cpow : Complex_2d ($z1 : Complex_2d, $z2 : Complex_2d)

The binding to the C<cpow> function of C language. This function is declared in C<complex.h>.

=head2 cpowf

  static method cpowf : Complex_2f ($z1 : Complex_2f, $z2 : Complex_2f)

The binding to the C<cpowf> function of C language. This function is declared in C<complex.h>.

=head2 cscamul

  static method cscamul : Complex_2d ($c : double, $z : Complex_2d)

double complex scalar multiplication.

=head2 cscamulf

  static method cscamulf : Complex_2f ($c : float, $z : Complex_2f)

float complex scalar multiplication.

=head2 csin

  static method csin : Complex_2d ($z : Complex_2d)

The binding to the C<csin> function of C language. This function is declared in C<complex.h>.

=head2 csinf

  static method csinf : Complex_2f ($z : Complex_2f)

The binding to the C<csinf> function of C language. This function is declared in C<complex.h>.

=head2 csinh

  static method csinh : Complex_2d ($z : Complex_2d)

The binding to the C<csinh> function of C language. This function is declared in C<complex.h>.

=head2 csinhf

  static method csinhf : Complex_2f ($z : Complex_2f)

The binding to the C<csinhf> function of C language. This function is declared in C<complex.h>.

=head2 csqrt

  static method csqrt : Complex_2d ($z : Complex_2d)

The binding to the C<csqrt> function of C language. This function is declared in C<complex.h>.

=head2 csqrtf

  static method csqrtf : Complex_2f ($z : Complex_2f)

The binding to the C<csqrtf> function of C language. This function is declared in C<complex.h>.

=head2 csub

  static method csub : Complex_2d ($z1 : Complex_2d, $z2 : Complex_2d)

The binding to the C<csub> function of C language. This function is declared in C<complex.h>.

=head2 csubf

  static method csubf : Complex_2f ($z1 : Complex_2f, $z2 : Complex_2f)

The binding to the C<csubf> function of C language. This function is declared in C<complex.h>.

=head2 ctan

  static method ctan : Complex_2d ($z : Complex_2d)

The binding to the C<ctan> function of C language. This function is declared in C<complex.h>.

=head2 ctanf

  static method ctanf : Complex_2f ($z : Complex_2f)

The binding to the C<ctanf> function of C language. This function is declared in C<complex.h>.

=head2 ctanh

  static method ctanh : Complex_2d ($z : Complex_2d)

The binding to the C<ctanh> function of C language. This function is declared in C<complex.h>.

=head2 ctanhf

  static method ctanhf : Complex_2f ($z : Complex_2f)

The binding to the C<ctanhf> function of C language. This function is declared in C<complex.h>.

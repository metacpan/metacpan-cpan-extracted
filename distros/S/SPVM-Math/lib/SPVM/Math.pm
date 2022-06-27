package SPVM::Math;

our $VERSION = '0.11';

1;

=head1 NAME

SPVM::Math - Math Functions

=head1 CAUTHION

B<The SPVM::Math module depends on the L<SPVM> module. The L<SPVM> module is yet before 1.0 released. The beta tests are doing. There will be a little reasonable changes yet.>

=head1 SYNOPSYS

=head2 SPVM

  use Math;
  
  my $sin = Math->sin(Math->PI / 4);

=head2 Perl
  
  use SPVM 'Math';
  
  my $sin = SPVM::Math->sin(SPVM::Math->PI / 4);

=head1 DESCRIPTION

The C<Math> class defines mathmatical functions that contains C99 math functions.

=head1 CLASS METHODS

The list of class methods of C<Math> class.

=head2 abs

  static method abs : int ($x : int);

Get the abusolute value of a int value.

=head2 acos

  static method acos : double ($x : double)

The binding to the C<acos> function of C language. This function is declared in C<math.h>.

=head2 acosf

  static method acosf : float ($x : float)

The binding to the C<acosf> function of C language. This function is declared in C<math.h>.

=head2 acosh

  static method acosh : double ($x : double)

The binding to the C<acosh> function of C language. This function is declared in C<math.h>.

=head2 acoshf

  static method acoshf : float ($x : float)

The binding to the C<acoshf> function of C language. This function is declared in C<math.h>.

=head2 asin

  static method asin : double ($x : double)

The binding to the C<asin> function of C language. This function is declared in C<math.h>.

=head2 asinf

  static method asinf : float ($x : float)

The binding to the C<asinf> function of C language. This function is declared in C<math.h>.

=head2 asinh

  static method asinh : double ($x : double)

The binding to the C<asinh> function of C language. This function is declared in C<math.h>.

=head2 asinhf

  static method asinhf : float ($x : float)

The binding to the C<asinhf> function of C language. This function is declared in C<math.h>.

=head2 atan

  static method atan : double ($x : double)

The binding to the C<atan> function of C language. This function is declared in C<math.h>.

=head2 atan2

  static method atan2 : double ($y : double, $x : double)

The binding to the C<atan2> function of C language. This function is declared in C<math.h>.

=head2 atanf

  static method atanf : float ($x : float)

The binding to the C<atanf> function of C language. This function is declared in C<math.h>.

=head2 atanh

  static method atanh : double ($x : double)

The binding to the C<atanh> function of C language. This function is declared in C<math.h>.

=head2 atanhf

  static method atanhf : float ($x : float)

The binding to the C<atanhf> function of C language. This function is declared in C<math.h>.

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

=head2 cbrt

  static method cbrt : double ($x : double)

The binding to the C<cbrt> function of C language. This function is declared in C<math.h>.

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

=head2 ceil

  static method ceil : double ($x : double)

The binding to the C<ceil> function of C language. This function is declared in C<math.h>.

=head2 ceilf

  static method ceilf : float ($x : float)

The binding to the C<ceilf> function of C language. This function is declared in C<math.h>.

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

=head2 copysign

  static method copysign : double ($x1 : double, $x2 : double)

The binding to the C<copysign> function of C language. This function is declared in C<math.h>.

=head2 copysignf

  static method copysignf : float ($x1 : float, $x2 : float)

The binding to the C<copysignf> function of C language. This function is declared in C<math.h>.

=head2 cos

  static method cos : double ($x : double)

The binding to the C<cos> function of C language. This function is declared in C<math.h>.

=head2 cosf

  static method cosf : float ($x : float)

The binding to the C<cosf> function of C language. This function is declared in C<math.h>.

=head2 cosh

  static method cosh : double ($x : double)

The binding to the C<cosh> function of C language. This function is declared in C<math.h>.

=head2 coshf

  static method coshf : float ($x : float)

The binding to the C<coshf> function of C language. This function is declared in C<math.h>.

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

=head2 E

  static method E : double ()

Euler's Number e. This value is C<0x1.5bf0a8b145769p+1>.

=head2 erf

  static method erf : double ($x : double)

The binding to the C<erf> function of C language. This function is declared in C<math.h>.

=head2 erfc

  static method erfc : double ($x : double)

The binding to the C<erfc> function of C language. This function is declared in C<math.h>.

=head2 erfcf

  static method erfcf : float ($x : float)

The binding to the C<erfcf> function of C language. This function is declared in C<math.h>.

=head2 erff

  static method erff : float ($x : float)

The binding to the C<erff> function of C language. This function is declared in C<math.h>.

=head2 exp

  static method exp : double ($x : double)

The binding to the C<exp> function of C language. This function is declared in C<math.h>.

=head2 exp2

  static method exp2 : double ($x : double)

The binding to the C<exp2> function of C language. This function is declared in C<math.h>.

=head2 exp2f

  static method exp2f : float ($x : float)

The binding to the C<exp2f> function of C language. This function is declared in C<math.h>.

=head2 expf

  static method expf : float ($x : float)

The binding to the C<expf> function of C language. This function is declared in C<math.h>.

=head2 expm1

  static method expm1 : double ($x : double)

The binding to the C<expm1> function of C language. This function is declared in C<math.h>.

=head2 expm1f

  static method expm1f : float ($x : float)

The binding to the C<expm1f> function of C language. This function is declared in C<math.h>.

=head2 fabs

  static method fabs : double ($x : double)

The binding to the C<fabs> function of C language. This function is declared in C<math.h>.

=head2 fabsf

  static method fabsf : float ($x : float)

The binding to the C<fabsf> function of C language. This function is declared in C<math.h>.

=head2 fdim

  static method fdim : double ($x1 : double, $x2 : double)

The binding to the C<fdim> function of C language. This function is declared in C<math.h>.

=head2 fdimf

  static method fdimf : float ($x1 : float, $x2 : float)

The binding to the C<fdimf> function of C language. This function is declared in C<math.h>.

=head2 FE_DOWNWARD

  static method FE_DOWNWARD : int ()

The binding to the C<FE_DOWNWARD> macro of C language. This macro is defined in fenv.h.

=head2 FE_TONEAREST

  static method FE_TONEAREST : int ()

The binding to the C<FE_TONEAREST> macro of C language. This macro is defined in fenv.h.

=head2 FE_TOWARDZERO

  static method FE_TOWARDZERO : int ()

The binding to the C<FE_TOWARDZERO> macro of C language. This macro is defined in fenv.h.

=head2 FE_UPWARD

  static method FE_UPWARD : int ()

The binding to the C<FE_UPWARD> macro of C language. This macro is defined in fenv.h.

=head2 fesetround

  static method fesetround : int ($round : int)

The binding to the C<fesetround> function of C language. This function is declared in C<math.h>.

=head2 floor

  static method floor : double ($x : double)

The binding to the C<floor> function of C language. This function is declared in C<math.h>.

=head2 floorf

  static method floorf : float ($x : float)

The binding to the C<floorf> function of C language. This function is declared in C<math.h>.

=head2 fma

  static method fma : double ($x1 : double, $x2 : double, $x3 : double)

The binding to the C<fma> function of C language. This function is declared in C<math.h>.

=head2 fmaf

  static method fmaf : float ($x1 : float, $x2 : float, $x3 : float)

The binding to the C<fmaf> function of C language. This function is declared in C<math.h>.

=head2 fmax

  static method fmax : double ($x1 : double, $x2 : double)

The binding to the C<fmax> function of C language. This function is declared in C<math.h>.

=head2 fmaxf

  static method fmaxf : float ($x1 : float, $x2 : float)

The binding to the C<fmaxf> function of C language. This function is declared in C<math.h>.

=head2 fmin

  static method fmin : double ($x1 : double, $x2 : double)

The binding to the C<fmin> function of C language. This function is declared in C<math.h>.

=head2 fminf

  static method fminf : float ($x1 : float, $x2 : float)

The binding to the C<fminf> function of C language. This function is declared in C<math.h>.

=head2 fmod

  static method fmod : double ($x1 : double, $x2 : double)

The binding to the C<fmod> function of C language. This function is declared in C<math.h>.

=head2 fmodf

  static method fmodf : float ($x1 : float, $x2 : float)

The binding to the C<fmodf> function of C language. This function is declared in C<math.h>.

=head2 FP_ILOGB0

  static method FP_ILOGB0 : int ()

The binding to the C<FP_ILOGB0> macro of C language. This macro is defined in fenv.h.

=head2 FP_ILOGBNAN

  static method FP_ILOGBNAN : int ()

The binding to the C<FP_ILOGBNAN> macro of C language. This macro is defined in fenv.h.

=head2 FP_INFINITE

  static method FP_INFINITE : int ()

The binding to the C<FP_INFINITE> macro of C language. This macro is defined in fenv.h.

=head2 FP_NAN

  static method FP_NAN : int ()

The binding to the C<FP_NAN> macro of C language. This macro is defined in fenv.h.

=head2 FP_ZERO

  static method FP_ZERO : int ()

The binding to the C<FP_ZERO> macro of C language. This macro is defined in fenv.h.

=head2 fpclassify

  static method fpclassify : int ($x : double)

The binding to the C<fpclassify> macro of C language. This macro is defined in C<math.h>. This method receives a double value.

=head2 fpclassifyf

  static method fpclassifyf : int ($x : float)

The binding to the C<fpclassify> macro of C language. This macro is defined in C<math.h> for float type. This method receives a float value.

=head2 frexp

  static method frexp : double ($x : double, $exp : int*)

The binding to the C<frexp> function of C language. This function is declared in C<math.h>.

=head2 frexpf

  static method frexpf : float ($x : float, $exp : int*)

The binding to the C<frexpf> function of C language. This function is declared in C<math.h>.

=head2 HUGE_VAL

  static method HUGE_VAL : double ()

The binding to the C<HUGE_VAL> macro of C language. This macro is defined in C<math.h>.

=head2 HUGE_VALF

  static method HUGE_VALF : float ()

The binding to the C<HUGE_VALF> macro of C language. This macro is defined in C<math.h>.

=head2 hypot

  static method hypot : double ($x : double, $y : double)

The binding to the C<hypot> function of C language. This function is declared in C<math.h>.

=head2 hypotf

  static method hypotf : float ($x : float, $y : float)

The binding to the C<hypotf> function of C language. This function is declared in C<math.h>.

=head2 ilogb

  static method ilogb : int ($x : double)

The binding to the C<ilogb> function of C language. This function is declared in C<math.h>.

=head2 ilogbf

  static method ilogbf : int ($x : float)

The binding to the C<ilogbf> function of C language. This function is declared in C<math.h>.

=head2 INFINITY

  static method INFINITY : double ()

The binding to the C<INFINITY> macro of C language. This macro is defined in C<math.h>. This method returns a double value.

=head2 INFINITYF

  static method INFINITYF : float ()

INFINITY macro for float type defined in C language C<math.h>. This method returns a float value.

=head2 isfinite

  static method isfinite : int ($x : double)

The binding to the C<isfinite> macro of C language. This macro is defined in C<math.h>. This method receives a double value.

=head2 isfinitef

  static method isfinitef : int($x : float)

The binding to the C<isfinite> macro of C language. This macro is defined in C<math.h> for float type. This method receives a float value.

=head2 isgreater

  static method isgreater : int ($x1 : double, $x2 : double)

The binding to the C<isgreater> macro of C language. This macro is defined in C<math.h>. This method receives two double values.

=head2 isgreaterequal

  static method isgreaterequal : int ($x1 : double, $x2 : double)

The binding to the C<isgreaterequal> macro of C language. This macro is defined in C<math.h>. This method receives two double values.

=head2 isgreaterequalf

  static method isgreaterequalf : int ($x1 : float, $x2 : float)

The binding to the C<isgreaterequal> macro of C language. This macro is defined in C<math.h>. This method receives two float values.

=head2 isgreaterf

  static method isgreaterf : int ($x1 : float, $x2 : float)

The binding to the C<isgreater> macro of C language. This macro is defined in C<math.h>. This method receives two float values.

=head2 isinf

  static method isinf : int ($x : double)

The binding to the C<isinf> macro of C language. This macro is defined in C<math.h>. This method receives a double value.

=head2 isinff

  static method isinff : int($x : float)

The binding to the C<isinf> macro of C language. This macro is defined in C<math.h>. This method receives a float value.

=head2 isless

  static method isless : int ($x1 : double, $x2 : double)

The binding to the C<isless> macro of C language. This macro is defined in C<math.h>. This method receives two double values.

=head2 islessequal

  static method islessequal : int ($x1 : double, $x2 : double)

The binding to the C<islessequal> macro of C language. This macro is defined in C<math.h>. This method receives two double values.

=head2 islessequalf

  static method islessequalf : int ($x1 : float, $x2 : float)

The binding to the C<islessequalf> macro of C language. This macro is defined in C<math.h>. This method receives two float values.

=head2 islessf

  static method islessf : int ($x1 : float, $x2 : float)

The binding to the C<islessf> macro of C language. This macro is defined in C<math.h>. This method receives two float values.

=head2 islessgreater

  static method islessgreater : int ($x1 : double, $x2 : double)

The binding to the C<islessgreater> macro of C language. This macro is defined in C<math.h>. This method receives two double values.

=head2 islessgreaterf

  static method islessgreaterf : int ($x1 : float, $x2 : float)

The binding to the C<islessgreater> macro of C language. This macro is defined in C<math.h>. This method receives two float values.

=head2 isnan

  static method isnan : int ($x : double)

The binding to the C<isnan> macro of C language. This macro is defined in C<math.h>. This method receives a double value.

=head2 isnanf

  static method isnanf : int ($x : float)

The binding to the C<isnanf> macro of C language. This macro is defined in C<math.h>. This method receives a float value.

=head2 isunordered

  static method isunordered : int ($x1 : double, $x2 : double)

The binding to the C<isunordered> macro of C language. This macro is defined in C<math.h>. This method receives two double values.

=head2 isunorderedf

  static method isunorderedf : int ($x1 : float, $x2 : float)

The binding to the C<isunorderedf> macro of C language. This macro is defined in C<math.h>. This method receives two float values.

=head2 labs

  static method labs : long ($x : long);

Get the abusolute value of a long value.

=head2 ldexp

  static method ldexp : double ($x : double, $exp : int)

The binding to the C<ldexp> function of C language. This function is declared in C<math.h>.

=head2 ldexpf

  static method ldexpf : float ($x : float, $exp : int)

The binding to the C<ldexpf> function of C language. This function is declared in C<math.h>.

=head2 lgamma

  static method lgamma : double ($x : double)

The binding to the C<lgamma> function of C language. This function is declared in C<math.h>.

=head2 lgammaf

  static method lgammaf : float ($x : float)

The binding to the C<lgammaf> function of C language. This function is declared in C<math.h>.

=head2 log

  static method log : double ($x : double)

The binding to the C<log> function of C language. This function is declared in C<math.h>.

=head2 log10

  static method log10 : double ($x : double)

The binding to the C<log10> function of C language. This function is declared in C<math.h>.

=head2 log10f

  static method log10f : float ($x : float)

The binding to the C<log10f> function of C language. This function is declared in C<math.h>.

=head2 log1p

  static method log1p : double ($x : double)

The binding to the C<log1p> function of C language. This function is declared in C<math.h>.

=head2 log1pf

  static method log1pf : float ($x : float)

The binding to the C<log1pf> function of C language. This function is declared in C<math.h>.

=head2 log2

  static method log2 : double ($x : double)

The binding to the C<log2> function of C language. This function is declared in C<math.h>.

=head2 log2f

  static method log2f : float ($x : float)

The binding to the C<log2f> function of C language. This function is declared in C<math.h>.

=head2 logb

  static method logb : double ($x : double)

The binding to the C<logb> function of C language. This function is declared in C<math.h>.

=head2 logbf

  static method logbf : float ($x : float)

The binding to the C<logbf> function of C language. This function is declared in C<math.h>.

=head2 logf

  static method logf : float ($x : float)

The binding to the C<logf> function of C language. This function is declared in C<math.h>.

=head2 lround

  static method lround : long ($x : double)

The binding to the C<llround> function of C language. This function is declared in C<math.h>. Note that call llround instead of lround in C level.

=head2 lroundf

  static method lroundf : long ($x : float)

The binding to the C<llroundf> function of C language. This function is declared in C<math.h>. Note that call llroundf instead of lroundf in C level.

=head2 modf

  static method modf : double ($x : double, $intpart : double*)

The binding to the C<modf> function of C language. This function is declared in C<math.h>.

=head2 modff

  static method modff : float ($x : float, $intpart : float*)

The binding to the C<modff> function of C language. This function is declared in C<math.h>.

=head2 NAN

  static method NAN : double ()

The binding to the C<NAN> macro of C language. This macro is defined in C<math.h>. This method return a double value.

=head2 nan

  static method nan : double ($str : string)

The binding to the C<nan> function of C language. This function is declared in C<math.h>.

String must be defined, otherwise a exception occurs.

=head2 NANF

  static method NANF : float ()

The binding to the C<NAN> macro of C language. This macro is defined in C<math.h>. This method return a float value.

=head2 nanf

  static method nanf : float ($str : string)

The binding to the C<nanf> function of C language. This function is declared in C<math.h>.

String must be defined, otherwise a exception occurs.

=head2 nearbyint

  static method nearbyint : double ($x : double)

The binding to the C<nearbyint> function of C language. This function is declared in C<math.h>.

=head2 nearbyintf

  static method nearbyintf : float ($x : float)

The binding to the C<nearbyintf> function of C language. This function is declared in C<math.h>.

=head2 nextafter

  static method nextafter : double ($x1 : double, $x2 : double)

The binding to the C<nextafter> function of C language. This function is declared in C<math.h>.

=head2 nextafterf

  static method nextafterf : float ($x1 : float, $x2 : float)

The binding to the C<nextafterf> function of C language. This function is declared in C<math.h>.

=head2 nexttoward

  static method nexttoward : double ($x1 : double, $x2 : double)

The binding to the C<nexttoward> function of C language. This function is declared in C<math.h>.

=head2 nexttowardf

  static method nexttowardf : float ($x1 : float, $x2 : double)

The binding to the C<nexttowardf> function of C language. This function is declared in C<math.h>.

=head2 PI

  static method PI : double ()

pi. This value is 0x1.921fb54442d18p+1.

=head2 pow

  static method pow : double ($x : double, $y : double)

The binding to the C<pow> function of C language. This function is declared in C<math.h>.

=head2 powf

  static method powf : float ($x : float, $y : float)

The binding to the C<powf> function of C language. This function is declared in C<math.h>.

=head2 remainder

  static method remainder : double ($x1 : double, $x2 : double)

The binding to the C<remainder> function of C language. This function is declared in C<math.h>.

=head2 remainderf

  static method remainderf : float ($x1 : float, $x2 : float)

The binding to the C<remainderf> function of C language. This function is declared in C<math.h>.

=head2 remquo

  static method remquo : double ($x1 : double, $x2 : double, $quo : int*)

The binding to the C<remquo> function of C language. This function is declared in C<math.h>.

=head2 remquof

  static method remquof : float ($x1 : float, $x2 : float, $quo : int*)

The binding to the C<remquof> function of C language. This function is declared in C<math.h>.

=head2 round

  static method round : double ($x : double)

The binding to the C<round> function of C language. This function is declared in C<math.h>.

=head2 roundf

  static method roundf : float ($x : float)

The binding to the C<roundf> function of C language. This function is declared in C<math.h>.

=head2 scalbln

  static method scalbln : double ($x : double, $exp : long)

The binding to the C<scalbln> function of C language. This function is declared in C<math.h>.

=head2 scalblnf

  static method scalblnf : float ($x : float, $exp : long)

The binding to the C<scalblnf> function of C language. This function is declared in C<math.h>.

=head2 scalbn

  static method scalbn : double ($x : double, $exp : int)

The binding to the C<scalbn> function of C language. This function is declared in C<math.h>.

=head2 scalbnf

  static method scalbnf : float ($x : float, $exp : int)

The binding to the C<scalbnf> function of C language. This function is declared in C<math.h>.

=head2 signbit

  static method signbit : int ($x : double)

The binding to the C<signbit> function of C language. This function is declared in C<math.h>.

=head2 signbitf

  static method signbitf : int ($x : float)

The binding to the C<signbitf> function of C language. This function is declared in C<math.h>.

=head2 sin

  static method sin : double ($x : double)

The binding to the C<sin> function of C language. This function is declared in C<math.h>.

=head2 sinf

  static method sinf : float ($x : float)

The binding to the C<sinf> function of C language. This function is declared in C<math.h>.

=head2 sinh

  static method sinh : double ($x : double)

The binding to the C<sinh> function of C language. This function is declared in C<math.h>.

=head2 sinhf

  static method sinhf : float ($x : float)

The binding to the C<sinhf> function of C language. This function is declared in C<math.h>.

=head2 sqrt

  static method sqrt : double ($x : double)

The binding to the C<sqrt> function of C language. This function is declared in C<math.h>.

=head2 sqrtf

The binding to the C<sqrtf> function of C language. This function is declared in C<math.h>.

=head2 tan

  static method tan : double ($x : double)

The binding to the C<tan> function of C language. This function is declared in C<math.h>.

=head2 tanf

  static method tanf : float ($x : float)

The binding to the C<tanf> function of C language. This function is declared in C<math.h>.

=head2 tanh

  static method tanh : double ($x : double)

The binding to the C<tanh> function of C language. This function is declared in C<math.h>.

=head2 tanhf

  static method tanhf : float ($x : float)

The binding to the C<tanhf> function of C language. This function is declared in C<math.h>.

=head2 tgamma

  static method tgamma : double ($x : double)

The binding to the C<tgamma> function of C language. This function is declared in C<math.h>.

=head2 tgammaf

  static method tgammaf : float ($x : float)

The binding to the C<tgammaf> function of C language. This function is declared in C<math.h>.

=head2 trunc

  static method trunc : double ($x : double)

The binding to the C<trunc> function of C language. This function is declared in C<math.h>.

=head2 truncf

  static method truncf : float ($x : float)

The binding to the C<truncf> function of C language. This function is declared in C<math.h>.

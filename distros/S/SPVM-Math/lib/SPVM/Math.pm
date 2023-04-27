package SPVM::Math;

our $VERSION = '1.001';

1;

=head1 Name

SPVM::Math - Mathematical Functions

=head1 Description

The Math class of L<SPVM> has methods for mathematical functions.

=head1 Usage

  use Math;
  
  my $sin = Math->sin(Math->PI / 4);

=head1 Class Methods

=head2 abs

  static method abs : int ($x : int);

Gets the abusolute value of the int value $x.

=head2 acos

  static method acos : double ($x : double);

Calls the C<acos> function of the C language defined in C<math.h>.

=head2 acosf

  static method acosf : float ($x : float);

Calls the C<acosf> function of the C language defined in C<math.h>.

=head2 acosh

  static method acosh : double ($x : double);

Calls the C<acosh> function of the C language defined in C<math.h>.

=head2 acoshf

  static method acoshf : float ($x : float);

Calls the C<acoshf> function of the C language defined in C<math.h>.

=head2 asin

  static method asin : double ($x : double);

Calls the C<asin> function of the C language defined in C<math.h>.

=head2 asinf

  static method asinf : float ($x : float);

Calls the C<asinf> function of the C language defined in C<math.h>.

=head2 asinh

  static method asinh : double ($x : double);

Calls the C<asinh> function of the C language defined in C<math.h>.

=head2 asinhf

  static method asinhf : float ($x : float);

Calls the C<asinhf> function of the C language defined in C<math.h>.

=head2 atan

  static method atan : double ($x : double);

Calls the C<atan> function of the C language defined in C<math.h>.

=head2 atan2

  static method atan2 : double ($y : double, $x : double);

Calls the C<atan2> function of the C language defined in C<math.h>.

=head2 atanf

  static method atanf : float ($x : float);

Calls the C<atanf> function of the C language defined in C<math.h>.

=head2 atanh

  static method atanh : double ($x : double);

Calls the C<atanh> function of the C language defined in C<math.h>.

=head2 atanhf

  static method atanhf : float ($x : float);

Calls the C<atanhf> function of the C language defined in C<math.h>.

=head2 cabs

  static method cabs : double ($z : Complex_2d);

Calls the C<cabs> function of the C language defined in C<complex.h>.

=head2 cabsf

  static method cabsf : float ($z : Complex_2f);

Calls the C<cabsf> function of the C language defined in C<complex.h>.

=head2 cacos

  static method cacos : Complex_2d ($z : Complex_2d);

Calls the C<cacos> function of the C language defined in C<complex.h>.

=head2 cacosf

  static method cacosf : Complex_2f ($z : Complex_2f);

Calls the C<cacosf> function of the C language defined in C<complex.h>.

=head2 cacosh

  static method cacosh : Complex_2d ($z : Complex_2d);

Calls the C<cacosh> function of the C language defined in C<complex.h>.

=head2 cacoshf

  static method cacoshf : Complex_2f ($z : Complex_2f);

Calls the C<cacoshf> function of the C language defined in C<complex.h>.

=head2 cadd

  static method cadd : Complex_2d ($z1 : Complex_2d, $z2 : Complex_2d);

Calls the C<cadd> function of the C language defined in C<complex.h>.

=head2 caddf

  static method caddf : Complex_2f ($z1 : Complex_2f, $z2 : Complex_2f);

Calls the C<caddf> function of the C language defined in C<complex.h>.

=head2 carg

  static method carg : double ($z : Complex_2d);

Calls the C<carg> function of the C language defined in C<complex.h>.

=head2 cargf

  static method cargf : float ($z : Complex_2f);

Calls the C<cargf> function of the C language defined in C<complex.h>.

=head2 casin

  static method casin : Complex_2d ($z : Complex_2d);

Calls the C<casin> function of the C language defined in C<complex.h>.

=head2 casinf

  static method casinf : Complex_2f ($z : Complex_2f);

Calls the C<casinf> function of the C language defined in C<complex.h>.

=head2 casinh

  static method casinh : Complex_2d ($z : Complex_2d);

Calls the C<casinh> function of the C language defined in C<complex.h>.

=head2 casinhf

  static method casinhf : Complex_2f ($z : Complex_2f);

Calls the C<casinhf> function of the C language defined in C<complex.h>.

=head2 catan

  static method catan : Complex_2d ($z : Complex_2d);

Calls the C<catan> function of the C language defined in C<complex.h>.

=head2 catanf

  static method catanf : Complex_2f ($z : Complex_2f);

Calls the C<catanf> function of the C language defined in C<complex.h>.

=head2 catanh

  static method catanh : Complex_2d ($z : Complex_2d);

Calls the C<catanh> function of the C language defined in C<complex.h>.

=head2 catanhf

  static method catanhf : Complex_2f ($z : Complex_2f);

Calls the C<catanhf> function of the C language defined in C<complex.h>.

=head2 cbrt

  static method cbrt : double ($x : double);

Calls the C<cbrt> function of the C language defined in C<math.h>.

=head2 cbrtf

  static method cbrtf : float ($x : float);

Calls the C<cbrtf> function of the C language defined in C<math.h>.

=head2 ccos

  static method ccos : Complex_2d ($z : Complex_2d);

Calls the C<ccos> function of the C language defined in C<complex.h>.

=head2 ccosf

  static method ccosf : Complex_2f ($z : Complex_2f);

Calls the C<ccosf> function of the C language defined in C<complex.h>.

=head2 ccosh

  static method ccosh : Complex_2d ($z : Complex_2d);

Calls the C<ccosh> function of the C language defined in C<complex.h>.

=head2 ccoshf

  static method ccoshf : Complex_2f ($z : Complex_2f);

Calls the C<ccoshf> function of the C language defined in C<complex.h>.

=head2 cdiv

  static method cdiv : Complex_2d ($z1 : Complex_2d, $z2 : Complex_2d);

double complex division.

=head2 cdivf

  static method cdivf : Complex_2f ($z1 : Complex_2f, $z2 : Complex_2f);

float complex division.

=head2 ceil

  static method ceil : double ($x : double);

Calls the C<ceil> function of the C language defined in C<math.h>.

=head2 ceilf

  static method ceilf : float ($x : float);

Calls the C<ceilf> function of the C language defined in C<math.h>.

=head2 cexp

  static method cexp : Complex_2d ($z : Complex_2d);

Calls the C<cexp> function of the C language defined in C<complex.h>.

=head2 cexpf

  static method cexpf : Complex_2f ($z : Complex_2f);

Calls the C<cexpf> function of the C language defined in C<complex.h>.

=head2 clog

  static method clog : Complex_2d ($z : Complex_2d);

Calls the C<clog> function of the C language defined in C<complex.h>.

=head2 clogf

  static method clogf : Complex_2f ($z : Complex_2f);

Calls the C<clogf> function of the C language defined in C<complex.h>.

=head2 cmul

  static method cmul : Complex_2d ($z1 : Complex_2d, $z2 : Complex_2d);

Calculates the product($z1 * $z2) of double complex numbers.

=head2 cmulf

  static method cmulf : Complex_2f ($z1 : Complex_2f, $z2 : Complex_2f);

Calculates the product($z1 * $z2) of float complex numbers.

=head2 complex

  static method complex : Complex_2d ($x : double, $y : double);

Creates a double complex value of the L<Complex_2d|SPVM::Complex_2d> type.

=head2 complexf

  static method complexf : Complex_2f ($x : float, $y : float);

Creates a float complex value of the L<Complex_2f|SPVM::Complex_2f> type.

=head2 conj

  static method conj : Complex_2d ($z : Complex_2d);

Calls the C<conj> function of the C language defined in C<complex.h>.

=head2 conjf

  static method conjf : Complex_2f ($z : Complex_2f);

Calls the C<conjf> function of the C language defined in C<complex.h>.

=head2 copysign

  static method copysign : double ($x : double, $y : double);

Calls the C<copysign> function of the C language defined in C<math.h>.

=head2 copysignf

  static method copysignf : float ($x : float, $y : float);

Calls the C<copysignf> function of the C language defined in C<math.h>.

=head2 cos

  static method cos : double ($x : double);

Calls the C<cos> function of the C language defined in C<math.h>.

=head2 cosf

  static method cosf : float ($x : float);

Calls the C<cosf> function of the C language defined in C<math.h>.

=head2 cosh

  static method cosh : double ($x : double);

Calls the C<cosh> function of the C language defined in C<math.h>.

=head2 coshf

  static method coshf : float ($x : float);

Calls the C<coshf> function of the C language defined in C<math.h>.

=head2 cpow

  static method cpow : Complex_2d ($z1 : Complex_2d, $z2 : Complex_2d);

Calls the C<cpow> function of the C language defined in C<complex.h>.

=head2 cpowf

  static method cpowf : Complex_2f ($z1 : Complex_2f, $z2 : Complex_2f);

Calls the C<cpowf> function of the C language defined in C<complex.h>.

=head2 cscamul

  static method cscamul : Complex_2d ($c : double, $z : Complex_2d);

Calculates the scalar product($c * $z) of the double complex, and returns it.

=head2 cscamulf

  static method cscamulf : Complex_2f ($c : float, $z : Complex_2f);

Calculates the scalar product($c * $z) of the float complex, and returns it.

=head2 csin

  static method csin : Complex_2d ($z : Complex_2d);

Calls the C<csin> function of the C language defined in C<complex.h>.

=head2 csinf

  static method csinf : Complex_2f ($z : Complex_2f);

Calls the C<csinf> function of the C language defined in C<complex.h>.

=head2 csinh

  static method csinh : Complex_2d ($z : Complex_2d);

Calls the C<csinh> function of the C language defined in C<complex.h>.

=head2 csinhf

  static method csinhf : Complex_2f ($z : Complex_2f);

Calls the C<csinhf> function of the C language defined in C<complex.h>.

=head2 csqrt

  static method csqrt : Complex_2d ($z : Complex_2d);

Calls the C<csqrt> function of the C language defined in C<complex.h>.

=head2 csqrtf

  static method csqrtf : Complex_2f ($z : Complex_2f);

Calls the C<csqrtf> function of the C language defined in C<complex.h>.

=head2 csub

  static method csub : Complex_2d ($z1 : Complex_2d, $z2 : Complex_2d);

Calls the C<csub> function of the C language defined in C<complex.h>.

=head2 csubf

  static method csubf : Complex_2f ($z1 : Complex_2f, $z2 : Complex_2f);

Calls the C<csubf> function of the C language defined in C<complex.h>.

=head2 ctan

  static method ctan : Complex_2d ($z : Complex_2d);

Calls the C<ctan> function of the C language defined in C<complex.h>.

=head2 ctanf

  static method ctanf : Complex_2f ($z : Complex_2f);

Calls the C<ctanf> function of the C language defined in C<complex.h>.

=head2 ctanh

  static method ctanh : Complex_2d ($z : Complex_2d);

Calls the C<ctanh> function of the C language defined in C<complex.h>.

=head2 ctanhf

  static method ctanhf : Complex_2f ($z : Complex_2f);

Calls the C<ctanhf> function of the C language defined in C<complex.h>.

=head2 E

  static method E : double ();

Returns the Euler's number C<e>. This value is C<0x1.5bf0a8b145769p+1>.

=head2 erf

  static method erf : double ($x : double);

Calls the C<erf> function of the C language defined in C<math.h>.

=head2 erfc

  static method erfc : double ($x : double);

Calls the C<erfc> function of the C language defined in C<math.h>.

=head2 erfcf

  static method erfcf : float ($x : float);

Calls the C<erfcf> function of the C language defined in C<math.h>.

=head2 erff

  static method erff : float ($x : float);

Calls the C<erff> function of the C language defined in C<math.h>.

=head2 exp

  static method exp : double ($x : double);

Calls the C<exp> function of the C language defined in C<math.h>.

=head2 exp2

  static method exp2 : double ($x : double);

Calls the C<exp2> function of the C language defined in C<math.h>.

=head2 exp2f

  static method exp2f : float ($x : float);

Calls the C<exp2f> function of the C language defined in C<math.h>.

=head2 expf

  static method expf : float ($x : float);

Calls the C<expf> function of the C language defined in C<math.h>.

=head2 expm1

  static method expm1 : double ($x : double);

Calls the C<expm1> function of the C language defined in C<math.h>.

=head2 expm1f

  static method expm1f : float ($x : float);

Calls the C<expm1f> function of the C language defined in C<math.h>.

=head2 fabs

  static method fabs : double ($x : double);

Calls the C<fabs> function of the C language defined in C<math.h>.

=head2 fabsf

  static method fabsf : float ($x : float);

Calls the C<fabsf> function of the C language defined in C<math.h>.

=head2 fdim

  static method fdim : double ($x : double, $y : double);

Calls the C<fdim> function of the C language defined in C<math.h>.

=head2 fdimf

  static method fdimf : float ($x : float, $y : float);

Calls the C<fdimf> function of the C language defined in C<math.h>.

=head2 FE_DOWNWARD

  static method FE_DOWNWARD : int ();

Calls the C<FE_DOWNWARD> macro of the C language defined in C<fenv.h>.

=head2 FE_TONEAREST

  static method FE_TONEAREST : int ();

Calls the C<FE_TONEAREST> macro of the C language defined in C<fenv.h>.

=head2 FE_TOWARDZERO

  static method FE_TOWARDZERO : int ();

Calls the C<FE_TOWARDZERO> macro of the C language defined in C<fenv.h>.

=head2 FE_UPWARD

  static method FE_UPWARD : int ();

Calls the C<FE_UPWARD> macro of the C language defined in C<fenv.h>.

=head2 fesetround

  static method fesetround : int ($round : int);

Calls the C<fesetround> function of the C language defined in C<math.h>.

=head2 floor

  static method floor : double ($x : double);

Calls the C<floor> function of the C language defined in C<math.h>.

=head2 floorf

  static method floorf : float ($x : float);

Calls the C<floorf> function of the C language defined in C<math.h>.

=head2 fma

  static method fma : double ($x : double, $y : double, $x3 : double);

Calls the C<fma> function of the C language defined in C<math.h>.

=head2 fmaf

  static method fmaf : float ($x : float, $y : float, $x3 : float);

Calls the C<fmaf> function of the C language defined in C<math.h>.

=head2 fmax

  static method fmax : double ($x : double, $y : double);

Calls the C<fmax> function of the C language defined in C<math.h>.

=head2 fmaxf

  static method fmaxf : float ($x : float, $y : float);

Calls the C<fmaxf> function of the C language defined in C<math.h>.

=head2 fmin

  static method fmin : double ($x : double, $y : double);

Calls the C<fmin> function of the C language defined in C<math.h>.

=head2 fminf

  static method fminf : float ($x : float, $y : float);

Calls the C<fminf> function of the C language defined in C<math.h>.

=head2 fmod

  static method fmod : double ($x : double, $y : double);

Calls the C<fmod> function of the C language defined in C<math.h>.

=head2 fmodf

  static method fmodf : float ($x : float, $y : float);

Calls the C<fmodf> function of the C language defined in C<math.h>.

=head2 FP_ILOGB0

  static method FP_ILOGB0 : int ();

Calls the C<FP_ILOGB0> macro of the C language defined in C<fenv.h>.

=head2 FP_ILOGBNAN

  static method FP_ILOGBNAN : int ();

Calls the C<FP_ILOGBNAN> macro of the C language defined in C<fenv.h>.

=head2 FP_INFINITE

  static method FP_INFINITE : int ();

Calls the C<FP_INFINITE> macro of the C language defined in C<fenv.h>.

=head2 FP_NAN

  static method FP_NAN : int ();

Calls the C<FP_NAN> macro of the C language defined in C<fenv.h>.

=head2 FP_ZERO

  static method FP_ZERO : int ();

Calls the C<FP_ZERO> macro of the C language defined in C<fenv.h>.

=head2 fpclassify

  static method fpclassify : int ($x : double);

Calls the C<fpclassify> macro of the C language defined in C<math.h> with the double argument $x.

=head2 fpclassifyf

  static method fpclassifyf : int ($x : float);

Calls the C<fpclassify> macro of the C language defined in C<math.h> with the float argument $x.

=head2 frexp

  static method frexp : double ($x : double, $exp : int*);

Calls the C<frexp> function of the C language defined in C<math.h>.

=head2 frexpf

  static method frexpf : float ($x : float, $exp : int*);

Calls the C<frexpf> function of the C language defined in C<math.h>.

=head2 HUGE_VAL

  static method HUGE_VAL : double ();

Calls the C<HUGE_VAL> macro of the C language defined in C<math.h>.

=head2 HUGE_VALF

  static method HUGE_VALF : float ();

Calls the C<HUGE_VALF> macro of the C language defined in C<math.h>.

=head2 hypot

  static method hypot : double ($x : double, $y : double);

Calls the C<hypot> function of the C language defined in C<math.h>.

=head2 hypotf

  static method hypotf : float ($x : float, $y : float);

Calls the C<hypotf> function of the C language defined in C<math.h>.

=head2 ilogb

  static method ilogb : int ($x : double);

Calls the C<ilogb> function of the C language defined in C<math.h>.

=head2 ilogbf

  static method ilogbf : int ($x : float);

Calls the C<ilogbf> function of the C language defined in C<math.h>.

=head2 INFINITY

  static method INFINITY : double ();

Calls the C<INFINITY> macro of the C language defined in C<math.h>, and returns the return value as a dobule value.

=head2 INFINITYF

  static method INFINITYF : float ();

Calls the C<INFINITY> macro of the C language defined in C<math.h>, and the return value as a float value.

=head2 isfinite

  static method isfinite : int ($x : double);

Calls the C<isfinite> macro of the C language defined in C<math.h> with the double argument $x.

=head2 isfinitef

  static method isfinitef : int ($x : float);

Calls the C<isfinite> macro of the C language defined in C<math.h> with the float argument $x.

=head2 isgreater

  static method isgreater : int ($x : double, $y : double);

Calls the C<isgreater> macro of the C language defined in C<math.h> with the double arguments $x and $y.

=head2 isgreaterequal

  static method isgreaterequal : int ($x : double, $y : double);

Calls the C<isgreaterequal> macro of the C language defined in C<math.h> with the double arguments $x and $y.

=head2 isgreaterequalf

  static method isgreaterequalf : int ($x : float, $y : float);

Calls the C<isgreaterequal> macro of the C language defined in C<math.h> with the float arguments $x and $y.

=head2 isgreaterf

  static method isgreaterf : int ($x : float, $y : float);

Calls the C<isgreater> macro of the C language defined in C<math.h> with the float arguments $x and $y.

=head2 isinf

  static method isinf : int ($x : double);

Calls the C<isinf> macro of the C language defined in C<math.h> with the double argument $x.

=head2 isinff

  static method isinff : int($x : float);

Calls the C<isinf> macro of the C language defined in C<math.h> with the float argument $x.

=head2 isless

  static method isless : int ($x : double, $y : double);

Calls the C<isless> macro of the C language defined in C<math.h> with the double arguments $x and $y.

=head2 islessequal

  static method islessequal : int ($x : double, $y : double);

Calls the C<islessequal> macro of the C language defined in C<math.h> with the double arguments $x and $y.

=head2 islessequalf

  static method islessequalf : int ($x : float, $y : float);

Calls the C<islessequalf> macro of the C language defined in C<math.h> with the float arguments $x and $y.

=head2 islessf

  static method islessf : int ($x : float, $y : float);

Calls the C<islessf> macro of the C language defined in C<math.h> with the float arguments $x and $y.

=head2 islessgreater

  static method islessgreater : int ($x : double, $y : double);

Calls the C<islessgreater> macro of the C language defined in C<math.h> with the double arguments $x and $y.

=head2 islessgreaterf

  static method islessgreaterf : int ($x : float, $y : float);

Calls the C<islessgreater> macro of the C language defined in C<math.h> with the float arguments $x and $y.

=head2 isnan

  static method isnan : int ($x : double);

Calls the C<isnan> macro of the C language defined in C<math.h> with the double argument $x.

=head2 isnanf

  static method isnanf : int ($x : float);

Calls the C<isnanf> macro of the C language defined in C<math.h> with the float argument $x.

=head2 isunordered

  static method isunordered : int ($x : double, $y : double);

Calls the C<isunordered> macro of the C language defined in C<math.h> with the double arguments $x and $y.

=head2 isunorderedf

  static method isunorderedf : int ($x : float, $y : float);

Calls the C<isunorderedf> macro of the C language defined in C<math.h> with the float arguments $x and $y.

=head2 labs

  static method labs : long ($x : long);

Returns the abusolute value of the long value $x.

=head2 ldexp

  static method ldexp : double ($x : double, $exp : int);

Calls the C<ldexp> function of the C language defined in C<math.h>.

=head2 ldexpf

  static method ldexpf : float ($x : float, $exp : int);

Calls the C<ldexpf> function of the C language defined in C<math.h>.

=head2 lgamma

  static method lgamma : double ($x : double);

Calls the C<lgamma> function of the C language defined in C<math.h>.

=head2 lgammaf

  static method lgammaf : float ($x : float);

Calls the C<lgammaf> function of the C language defined in C<math.h>.

=head2 log

  static method log : double ($x : double);

Calls the C<log> function of the C language defined in C<math.h>.

=head2 log10

  static method log10 : double ($x : double);

Calls the C<log10> function of the C language defined in C<math.h>.

=head2 log10f

  static method log10f : float ($x : float);

Calls the C<log10f> function of the C language defined in C<math.h>.

=head2 log1p

  static method log1p : double ($x : double);

Calls the C<log1p> function of the C language defined in C<math.h>.

=head2 log1pf

  static method log1pf : float ($x : float);

Calls the C<log1pf> function of the C language defined in C<math.h>.

=head2 log2

  static method log2 : double ($x : double);

Calls the C<log2> function of the C language defined in C<math.h>.

=head2 log2f

  static method log2f : float ($x : float);

Calls the C<log2f> function of the C language defined in C<math.h>.

=head2 logb

  static method logb : double ($x : double);

Calls the C<logb> function of the C language defined in C<math.h>.

=head2 logbf

  static method logbf : float ($x : float);

Calls the C<logbf> function of the C language defined in C<math.h>.

=head2 logf

  static method logf : float ($x : float);

Calls the C<logf> function of the C language defined in C<math.h>.

=head2 lround

  static method lround : long ($x : double);

Calls the C<llround> function of the C language defined in C<math.h>.

=head2 lroundf

  static method lroundf : long ($x : float);

Calls the C<llroundf> function of the C language defined in C<math.h>.

=head2 modf

  static method modf : double ($x : double, $intpart : double*);

Calls the C<modf> function of the C language defined in C<math.h>.

=head2 modff

  static method modff : float ($x : float, $intpart : float*);

Calls the C<modff> function of the C language defined in C<math.h>.

=head2 NAN

  static method NAN : double ();

Calls the C<NAN> macro of the C language defined in C<math.h>, and return the return value as a double type.

=head2 nan

  static method nan : double ($string : string);

Calls the C<nan> function of the C language defined in C<math.h>.

Exceptions:

The $string must be defined. Otherwise an exception is thrown.

=head2 NANF

  static method NANF : float ();

Calls the C<NAN> macro of the C language defined in C<math.h>, and return the return value as a float type.

=head2 nanf

  static method nanf : float ($string : string);

Calls the C<nanf> function of the C language defined in C<math.h>.

Exceptions:

The $string must be defined. Otherwise an exception is thrown.

=head2 nearbyint

  static method nearbyint : double ($x : double);

Calls the C<nearbyint> function of the C language defined in C<math.h>.

=head2 nearbyintf

  static method nearbyintf : float ($x : float);

Calls the C<nearbyintf> function of the C language defined in C<math.h>.

=head2 nextafter

  static method nextafter : double ($x : double, $y : double);

Calls the C<nextafter> function of the C language defined in C<math.h>.

=head2 nextafterf

  static method nextafterf : float ($x : float, $y : float);

Calls the C<nextafterf> function of the C language defined in C<math.h>.

=head2 nexttoward

  static method nexttoward : double ($x : double, $y : double);

Calls the C<nexttoward> function of the C language defined in C<math.h>.

=head2 nexttowardf

  static method nexttowardf : float ($x : float, $y : double);

Calls the C<nexttowardf> function of the C language defined in C<math.h>.

=head2 PI

  static method PI : double ();

Returns pi. This value is C<0x1.921fb54442d18p+1>.

=head2 pow

  static method pow : double ($x : double, $y : double);

Calls the C<pow> function of the C language defined in C<math.h>.

=head2 powf

  static method powf : float ($x : float, $y : float);

Calls the C<powf> function of the C language defined in C<math.h>.

=head2 remainder

  static method remainder : double ($x : double, $y : double);

Calls the C<remainder> function of the C language defined in C<math.h>.

=head2 remainderf

  static method remainderf : float ($x : float, $y : float);

Calls the C<remainderf> function of the C language defined in C<math.h>.

=head2 remquo

  static method remquo : double ($x : double, $y : double, $quo : int*);

Calls the C<remquo> function of the C language defined in C<math.h>.

=head2 remquof

  static method remquof : float ($x : float, $y : float, $quo : int*);

Calls the C<remquof> function of the C language defined in C<math.h>.

=head2 round

  static method round : double ($x : double);

Calls the C<round> function of the C language defined in C<math.h>.

=head2 roundf

  static method roundf : float ($x : float);

Calls the C<roundf> function of the C language defined in C<math.h>.

=head2 scalbln

  static method scalbln : double ($x : double, $exp : long);

Calls the C<scalbln> function of the C language defined in C<math.h>.

=head2 scalblnf

  static method scalblnf : float ($x : float, $exp : long);

Calls the C<scalblnf> function of the C language defined in C<math.h>.

=head2 scalbn

  static method scalbn : double ($x : double, $exp : int);

Calls the C<scalbn> function of the C language defined in C<math.h>.

=head2 scalbnf

  static method scalbnf : float ($x : float, $exp : int);

Calls the C<scalbnf> function of the C language defined in C<math.h>.

=head2 signbit

  static method signbit : int ($x : double);

Calls the C<signbit> function of the C language defined in C<math.h>.

=head2 signbitf

  static method signbitf : int ($x : float);

Calls the C<signbitf> function of the C language defined in C<math.h>.

=head2 sin

  static method sin : double ($x : double);

Calls the C<sin> function of the C language defined in C<math.h>.

=head2 sinf

  static method sinf : float ($x : float);

Calls the C<sinf> function of the C language defined in C<math.h>.

=head2 sinh

  static method sinh : double ($x : double);

Calls the C<sinh> function of the C language defined in C<math.h>.

=head2 sinhf

  static method sinhf : float ($x : float);

Calls the C<sinhf> function of the C language defined in C<math.h>.

=head2 sqrt

  static method sqrt : double ($x : double);

Calls the C<sqrt> function of the C language defined in C<math.h>.

=head2 sqrtf

  static method sqrtf : float ($x : float);

Calls the C<sqrtf> function of the C language defined in C<math.h>.

=head2 tan

  static method tan : double ($x : double);

Calls the C<tan> function of the C language defined in C<math.h>.

=head2 tanf

  static method tanf : float ($x : float);

Calls the C<tanf> function of the C language defined in C<math.h>.

=head2 tanh

  static method tanh : double ($x : double);

Calls the C<tanh> function of the C language defined in C<math.h>.

=head2 tanhf

  static method tanhf : float ($x : float);

Calls the C<tanhf> function of the C language defined in C<math.h>.

=head2 tgamma

  static method tgamma : double ($x : double);

Calls the C<tgamma> function of the C language defined in C<math.h>.

=head2 tgammaf

  static method tgammaf : float ($x : float);

Calls the C<tgammaf> function of the C language defined in C<math.h>.

=head2 trunc

  static method trunc : double ($x : double);

Calls the C<trunc> function of the C language defined in C<math.h>.

=head2 truncf

  static method truncf : float ($x : float);

Calls the C<truncf> function of the C language defined in C<math.h>.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

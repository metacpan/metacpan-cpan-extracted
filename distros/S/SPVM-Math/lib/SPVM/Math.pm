package SPVM::Math;

our $VERSION = "1.003";

1;

=head1 Name

SPVM::Math - Mathematical Calculations

=head1 Description

Math class in L<SPVM> has methods for mathematical calculations.

=head1 Usage

  use Math;
  
  my $sin = Math->sin(Math->PI / 4);
  
  my $cos = Math->cos(Math->PI / 4);
  
  my $tan = Math->tan(Math->PI / 4);
  
  # 1 + 2i
  my $z = Math->complex(1, 2);
  
  # i
  my $i = Math->complex(0, 1);
  
  # Euler's equation
  my $euler_left = Math->cexp(Math->cmul($i, $z));
  my $euler_right = Math->ccos($z) + Math->cmul($i, Math->csin($z));

=head1 Class Methods

=head2 abs

C<static method abs : int ($x : int);>

Calculates the abusolute value of $x and return it.

=head2 acos

C<static method acos : double ($x : double);>

Calls L<acos|https://linux.die.net/man/3/acos> function defined in C<math.h> in the C language and returns its return value.

=head2 acosf

C<static method acosf : float ($x : float);>

Calls L<acosf|https://linux.die.net/man/3/acosf> function defined in C<math.h> in the C language and returns its return value.

=head2 acosh

C<static method acosh : double ($x : double);>

Calls L<acosh|https://linux.die.net/man/3/acosh> function defined in C<math.h> in the C language and returns its return value.

=head2 acoshf

C<static method acoshf : float ($x : float);>

Calls L<acoshf|https://linux.die.net/man/3/acoshf> function defined in C<math.h> in the C language and returns its return value.

=head2 asin

C<static method asin : double ($x : double);>

Calls L<asin|https://linux.die.net/man/3/asin> function defined in C<math.h> in the C language and returns its return value.

=head2 asinf

C<static method asinf : float ($x : float);>

Calls L<asinf|https://linux.die.net/man/3/asinf> function defined in C<math.h> in the C language and returns its return value.

=head2 asinh

C<static method asinh : double ($x : double);>

Calls L<asinh|https://linux.die.net/man/3/asinh> function defined in C<math.h> in the C language and returns its return value.

=head2 asinhf

C<static method asinhf : float ($x : float);>

Calls L<asinhf|https://linux.die.net/man/3/asinhf> function defined in C<math.h> in the C language and returns its return value.

=head2 atan

C<static method atan : double ($x : double);>

Calls L<atan|https://linux.die.net/man/3/atan> function defined in C<math.h> in the C language and returns its return value.

=head2 atan2

C<static method atan2 : double ($y : double, $x : double);>

Calls L<atan2|https://linux.die.net/man/3/atan2> function defined in C<math.h> in the C language and returns its return value.

=head2 atan2f

C<static method atan2f : float ($y : float, $x : float);>

Calls L<atan2f|https://linux.die.net/man/3/atan2f> function defined in C<math.h> in the C language and returns its return value.

=head2 atanf

C<static method atanf : float ($x : float);>

Calls L<atanf|https://linux.die.net/man/3/atanf> function defined in C<math.h> in the C language and returns its return value.

=head2 atanh

C<static method atanh : double ($x : double);>

Calls L<atanh|https://linux.die.net/man/3/atanh> function defined in C<math.h> in the C language and returns its return value.

=head2 atanhf

C<static method atanhf : float ($x : float);>

Calls L<atanhf|https://linux.die.net/man/3/atanhf> function defined in C<math.h> in the C language and returns its return value.

=head2 cabs

C<static method cabs : double ($z : L<Complex_2d|SPVM::Complex_2d>);>

Calls L<cabs|https://linux.die.net/man/3/cabs> function defined in C<complex.h> in the C language and returns its return value.

=head2 cabsf

C<static method cabsf : float ($z : L<Complex_2f|SPVM::Complex_2f>);>

Calls L<cabsf|https://linux.die.net/man/3/cabsf> function defined in C<complex.h> in the C language and returns its return value.

=head2 cacos

C<static method cacos : L<Complex_2d|SPVM::Complex_2d> ($z : L<Complex_2d|SPVM::Complex_2d>);>

Calls L<cacos|https://linux.die.net/man/3/cacos> function defined in C<complex.h> in the C language and returns its return value.

=head2 cacosf

C<static method cacosf : L<Complex_2f|SPVM::Complex_2f> ($z : L<Complex_2f|SPVM::Complex_2f>);>

Calls L<cacosf|https://linux.die.net/man/3/cacosf> function defined in C<complex.h> in the C language and returns its return value.

=head2 cacosh

C<static method cacosh : L<Complex_2d|SPVM::Complex_2d> ($z : L<Complex_2d|SPVM::Complex_2d>);>

Calls L<cacosh|https://linux.die.net/man/3/cacosh> function defined in C<complex.h> in the C language and returns its return value.

=head2 cacoshf

C<static method cacoshf : L<Complex_2f|SPVM::Complex_2f> ($z : L<Complex_2f|SPVM::Complex_2f>);>

Calls L<cacoshf|https://linux.die.net/man/3/cacoshf> function defined in C<complex.h> in the C language and returns its return value.

=head2 cadd

C<static method cadd : L<Complex_2d|SPVM::Complex_2d> ($z1 : L<Complex_2d|SPVM::Complex_2d>, $z2 : L<Complex_2d|SPVM::Complex_2d>);>

Performs the addition operation on $z1 and $z2, and returns the resulting value.

=head2 caddf

C<static method caddf : L<Complex_2f|SPVM::Complex_2f> ($z1 : L<Complex_2f|SPVM::Complex_2f>, $z2 : L<Complex_2f|SPVM::Complex_2f>);>

Performs the addition operation on $z1 and $z2, and returns the resulting value.

=head2 carg

C<static method carg : double ($z : L<Complex_2d|SPVM::Complex_2d>);>

Calls L<carg|https://linux.die.net/man/3/carg> function defined in C<complex.h> in the C language and returns its return value.

=head2 cargf

C<static method cargf : float ($z : L<Complex_2f|SPVM::Complex_2f>);>

Calls L<cargf|https://linux.die.net/man/3/cargf> function defined in C<complex.h> in the C language and returns its return value.

=head2 casin

C<static method casin : L<Complex_2d|SPVM::Complex_2d> ($z : L<Complex_2d|SPVM::Complex_2d>);>

Calls L<casin|https://linux.die.net/man/3/casin> function defined in C<complex.h> in the C language and returns its return value.

=head2 casinf

C<static method casinf : L<Complex_2f|SPVM::Complex_2f> ($z : L<Complex_2f|SPVM::Complex_2f>);>

Calls L<casinf|https://linux.die.net/man/3/casinf> function defined in C<complex.h> in the C language and returns its return value.

=head2 casinh

C<static method casinh : L<Complex_2d|SPVM::Complex_2d> ($z : L<Complex_2d|SPVM::Complex_2d>);>

Calls L<casinh|https://linux.die.net/man/3/casinh> function defined in C<complex.h> in the C language and returns its return value.

=head2 casinhf

C<static method casinhf : L<Complex_2f|SPVM::Complex_2f> ($z : L<Complex_2f|SPVM::Complex_2f>);>

Calls L<casinhf|https://linux.die.net/man/3/casinhf> function defined in C<complex.h> in the C language and returns its return value.

=head2 catan

C<static method catan : L<Complex_2d|SPVM::Complex_2d> ($z : L<Complex_2d|SPVM::Complex_2d>);>

Calls L<catan|https://linux.die.net/man/3/catan> function defined in C<complex.h> in the C language and returns its return value.

=head2 catanf

C<static method catanf : L<Complex_2f|SPVM::Complex_2f> ($z : L<Complex_2f|SPVM::Complex_2f>);>

Calls L<catanf|https://linux.die.net/man/3/catanf> function defined in C<complex.h> in the C language and returns its return value.

=head2 catanh

C<static method catanh : L<Complex_2d|SPVM::Complex_2d> ($z : L<Complex_2d|SPVM::Complex_2d>);>

Calls L<catanh|https://linux.die.net/man/3/catanh> function defined in C<complex.h> in the C language and returns its return value.

=head2 catanhf

C<static method catanhf : L<Complex_2f|SPVM::Complex_2f> ($z : L<Complex_2f|SPVM::Complex_2f>);>

Calls L<catanhf|https://linux.die.net/man/3/catanhf> function defined in C<complex.h> in the C language and returns its return value.

=head2 cbrt

C<static method cbrt : double ($x : double);>

Calls L<cbrt|https://linux.die.net/man/3/cbrt> function defined in C<math.h> in the C language and returns its return value.

=head2 cbrtf

C<static method cbrtf : float ($x : float);>

Calls L<cbrtf|https://linux.die.net/man/3/cbrtf> function defined in C<math.h> in the C language and returns its return value.

=head2 ccos

C<static method ccos : L<Complex_2d|SPVM::Complex_2d> ($z : L<Complex_2d|SPVM::Complex_2d>);>

Calls L<ccos|https://linux.die.net/man/3/ccos> function defined in C<complex.h> in the C language and returns its return value.

=head2 ccosf

C<static method ccosf : L<Complex_2f|SPVM::Complex_2f> ($z : L<Complex_2f|SPVM::Complex_2f>);>

Calls L<ccosf|https://linux.die.net/man/3/ccosf> function defined in C<complex.h> in the C language and returns its return value.

=head2 ccosh

C<static method ccosh : L<Complex_2d|SPVM::Complex_2d> ($z : L<Complex_2d|SPVM::Complex_2d>);>

Calls L<ccosh|https://linux.die.net/man/3/ccosh> function defined in C<complex.h> in the C language and returns its return value.

=head2 ccoshf

C<static method ccoshf : L<Complex_2f|SPVM::Complex_2f> ($z : L<Complex_2f|SPVM::Complex_2f>);>

Calls L<ccoshf|https://linux.die.net/man/3/ccoshf> function defined in C<complex.h> in the C language and returns its return value.

=head2 cdiv

C<static method cdiv : L<Complex_2d|SPVM::Complex_2d> ($z1 : L<Complex_2d|SPVM::Complex_2d>, $z2 : L<Complex_2d|SPVM::Complex_2d>);>

Performs the divison operation on $z1 and $z2, and returns the resulting value.

=head2 cdivf

C<static method cdivf : L<Complex_2f|SPVM::Complex_2f> ($z1 : L<Complex_2f|SPVM::Complex_2f>, $z2 : L<Complex_2f|SPVM::Complex_2f>);>

Performs the divison operation on $z1 and $z2, and returns the resulting value.

=head2 ceil

C<static method ceil : double ($x : double);>

Calls L<ceil|https://linux.die.net/man/3/ceil> function defined in C<math.h> in the C language and returns its return value.

=head2 ceilf

C<static method ceilf : float ($x : float);>

Calls L<ceilf|https://linux.die.net/man/3/ceilf> function defined in C<math.h> in the C language and returns its return value.

=head2 cexp

C<static method cexp : L<Complex_2d|SPVM::Complex_2d> ($z : L<Complex_2d|SPVM::Complex_2d>);>

Calls L<cexp|https://linux.die.net/man/3/cexp> function defined in C<complex.h> in the C language and returns its return value.

=head2 cexpf

C<static method cexpf : L<Complex_2f|SPVM::Complex_2f> ($z : L<Complex_2f|SPVM::Complex_2f>);>

Calls L<cexpf|https://linux.die.net/man/3/cexpf> function defined in C<complex.h> in the C language and returns its return value.

=head2 clog

C<static method clog : L<Complex_2d|SPVM::Complex_2d> ($z : L<Complex_2d|SPVM::Complex_2d>);>

Calls L<clog|https://linux.die.net/man/3/clog> function defined in C<complex.h> in the C language and returns its return value.

=head2 clogf

C<static method clogf : L<Complex_2f|SPVM::Complex_2f> ($z : L<Complex_2f|SPVM::Complex_2f>);>

Calls L<clogf|https://linux.die.net/man/3/clogf> function defined in C<complex.h> in the C language and returns its return value.

=head2 cmul

C<static method cmul : L<Complex_2d|SPVM::Complex_2d> ($z1 : L<Complex_2d|SPVM::Complex_2d>, $z2 : L<Complex_2d|SPVM::Complex_2d>);>

Performs the multiplication operation on $z1 and $z2, and returns the resulting value.

=head2 cmulf

C<static method cmulf : L<Complex_2f|SPVM::Complex_2f> ($z1 : L<Complex_2f|SPVM::Complex_2f>, $z2 : L<Complex_2f|SPVM::Complex_2f>);>

Performs the multiplication operation on $z1 and $z2, and returns the resulting value.

=head2 complex

C<static method complex : L<Complex_2d|SPVM::Complex_2d> ($re : double, $im : double);>

Creates a double complex value given the real number $re and the imaginary number $im and returns it.

=head2 complexf

C<static method complexf : L<Complex_2f|SPVM::Complex_2f> ($re : float, $im : float);>

Creates a float complex value given the real number $re and the imaginary number $im and returns it.

=head2 conj

C<static method conj : L<Complex_2d|SPVM::Complex_2d> ($z : L<Complex_2d|SPVM::Complex_2d>);>

Calls L<conj|https://linux.die.net/man/3/conj> function defined in C<complex.h> in the C language and returns its return value.

=head2 conjf

C<static method conjf : L<Complex_2f|SPVM::Complex_2f> ($z : L<Complex_2f|SPVM::Complex_2f>);>

Calls L<conjf|https://linux.die.net/man/3/conjf> function defined in C<complex.h> in the C language and returns its return value.

=head2 copysign

C<static method copysign : double ($x : double, $y : double);>

Calls L<copysign|https://linux.die.net/man/3/copysign> function defined in C<math.h> in the C language and returns its return value.

=head2 copysignf

C<static method copysignf : float ($x : float, $y : float);>

Calls L<copysignf|https://linux.die.net/man/3/copysignf> function defined in C<math.h> in the C language and returns its return value.

=head2 cos

C<static method cos : double ($x : double);>

Calls L<cos|https://linux.die.net/man/3/cos> function defined in C<math.h> in the C language and returns its return value.

=head2 cosf

C<static method cosf : float ($x : float);>

Calls L<cosf|https://linux.die.net/man/3/cosf> function defined in C<math.h> in the C language and returns its return value.

=head2 cosh

C<static method cosh : double ($x : double);>

Calls L<cosh|https://linux.die.net/man/3/cosh> function defined in C<math.h> in the C language and returns its return value.

=head2 coshf

C<static method coshf : float ($x : float);>

Calls L<coshf|https://linux.die.net/man/3/coshf> function defined in C<math.h> in the C language and returns its return value.

=head2 cpow

C<static method cpow : L<Complex_2d|SPVM::Complex_2d> ($z1 : L<Complex_2d|SPVM::Complex_2d>, $z2 : L<Complex_2d|SPVM::Complex_2d>);>

Calls L<cpow|https://linux.die.net/man/3/cpow> function defined in C<complex.h> in the C language and returns its return value.

=head2 cpowf

C<static method cpowf : L<Complex_2f|SPVM::Complex_2f> ($z1 : L<Complex_2f|SPVM::Complex_2f>, $z2 : L<Complex_2f|SPVM::Complex_2f>);>

Calls L<cpowf|https://linux.die.net/man/3/cpowf> function defined in C<complex.h> in the C language and returns its return value.

=head2 cscamul

C<static method cscamul : L<Complex_2d|SPVM::Complex_2d> ($c : double, $z : L<Complex_2d|SPVM::Complex_2d>);>

Perlforms the multiplication operation on the real number $c and the complex number $z, and returns the resulting value.

=head2 cscamulf

C<static method cscamulf : L<Complex_2f|SPVM::Complex_2f> ($c : float, $z : L<Complex_2f|SPVM::Complex_2f>);>

Perlforms the multiplication operation on the real number $c and the complex number $z, and returns the resulting value.

=head2 csin

C<static method csin : L<Complex_2d|SPVM::Complex_2d> ($z : L<Complex_2d|SPVM::Complex_2d>);>

Calls L<csin|https://linux.die.net/man/3/csin> function defined in C<complex.h> in the C language and returns its return value.

=head2 csinf

C<static method csinf : L<Complex_2f|SPVM::Complex_2f> ($z : L<Complex_2f|SPVM::Complex_2f>);>

Calls L<csinf|https://linux.die.net/man/3/csinf> function defined in C<complex.h> in the C language and returns its return value.

=head2 csinh

C<static method csinh : L<Complex_2d|SPVM::Complex_2d> ($z : L<Complex_2d|SPVM::Complex_2d>);>

Calls L<csinh|https://linux.die.net/man/3/csinh> function defined in C<complex.h> in the C language and returns its return value.

=head2 csinhf

C<static method csinhf : L<Complex_2f|SPVM::Complex_2f> ($z : L<Complex_2f|SPVM::Complex_2f>);>

Calls L<csinhf|https://linux.die.net/man/3/csinhf> function defined in C<complex.h> in the C language and returns its return value.

=head2 csqrt

C<static method csqrt : L<Complex_2d|SPVM::Complex_2d> ($z : L<Complex_2d|SPVM::Complex_2d>);>

Calls L<csqrt|https://linux.die.net/man/3/csqrt> function defined in C<complex.h> in the C language and returns its return value.

=head2 csqrtf

C<static method csqrtf : L<Complex_2f|SPVM::Complex_2f> ($z : L<Complex_2f|SPVM::Complex_2f>);>

Calls L<csqrtf|https://linux.die.net/man/3/csqrtf> function defined in C<complex.h> in the C language and returns its return value.

=head2 csub

C<static method csub : L<Complex_2d|SPVM::Complex_2d> ($z1 : L<Complex_2d|SPVM::Complex_2d>, $z2 : L<Complex_2d|SPVM::Complex_2d>);>

Performs the subtraction operation on $z1 and $z2, and returns the resulting value.

=head2 csubf

C<static method csubf : L<Complex_2f|SPVM::Complex_2f> ($z1 : L<Complex_2f|SPVM::Complex_2f>, $z2 : L<Complex_2f|SPVM::Complex_2f>);>

Performs the subtraction operation on $z1 and $z2, and returns the resulting value.

=head2 cneg

C<static method cneg : L<Complex_2d|SPVM::Complex_2d> ($z : L<Complex_2d|SPVM::Complex_2d>);>

Negates the sign of $z and returns it.

=head2 cnegf

C<static method cnegf : L<Complex_2f|SPVM::Complex_2f> ($z : L<Complex_2f|SPVM::Complex_2f>);>

Negates the sign of $z and returns it.

=head2 ctan

C<static method ctan : L<Complex_2d|SPVM::Complex_2d> ($z : L<Complex_2d|SPVM::Complex_2d>);>

Calls L<ctan|https://linux.die.net/man/3/ctan> function defined in C<complex.h> in the C language and returns its return value.

=head2 ctanf

C<static method ctanf : L<Complex_2f|SPVM::Complex_2f> ($z : L<Complex_2f|SPVM::Complex_2f>);>

Calls L<ctanf|https://linux.die.net/man/3/ctanf> function defined in C<complex.h> in the C language and returns its return value.

=head2 ctanh

C<static method ctanh : L<Complex_2d|SPVM::Complex_2d> ($z : L<Complex_2d|SPVM::Complex_2d>);>

Calls L<ctanh|https://linux.die.net/man/3/ctanh> function defined in C<complex.h> in the C language and returns its return value.

=head2 ctanhf

C<static method ctanhf : L<Complex_2f|SPVM::Complex_2f> ($z : L<Complex_2f|SPVM::Complex_2f>);>

Calls L<ctanhf|https://linux.die.net/man/3/ctanhf> function defined in C<complex.h> in the C language and returns its return value.

=head2 E

C<static method E : double ();>

Returns the Euler's number C<e>. This value is C<0x1.5bf0a8b145769p+1>.

=head2 erf

C<static method erf : double ($x : double);>

Calls L<erf|https://linux.die.net/man/3/erf> function defined in C<math.h> in the C language and returns its return value.

=head2 erfc

C<static method erfc : double ($x : double);>

Calls L<erfc|https://linux.die.net/man/3/erfc> function defined in C<math.h> in the C language and returns its return value.

=head2 erfcf

C<static method erfcf : float ($x : float);>

Calls L<erfcf|https://linux.die.net/man/3/erfcf> function defined in C<math.h> in the C language and returns its return value.

=head2 erff

C<static method erff : float ($x : float);>

Calls L<erff|https://linux.die.net/man/3/erff> function defined in C<math.h> in the C language and returns its return value.

=head2 exp

C<static method exp : double ($x : double);>

Calls L<exp|https://linux.die.net/man/3/exp> function defined in C<math.h> in the C language and returns its return value.

=head2 exp2

C<static method exp2 : double ($x : double);>

Calls L<exp2|https://linux.die.net/man/3/exp2> function defined in C<math.h> in the C language and returns its return value.

=head2 exp2f

C<static method exp2f : float ($x : float);>

Calls L<exp2f|https://linux.die.net/man/3/exp2f> function defined in C<math.h> in the C language and returns its return value.

=head2 expf

C<static method expf : float ($x : float);>

Calls L<expf|https://linux.die.net/man/3/expf> function defined in C<math.h> in the C language and returns its return value.

=head2 expm1

C<static method expm1 : double ($x : double);>

Calls L<expm1|https://linux.die.net/man/3/expm1> function defined in C<math.h> in the C language and returns its return value.

=head2 expm1f

C<static method expm1f : float ($x : float);>

Calls L<expm1f|https://linux.die.net/man/3/expm1f> function defined in C<math.h> in the C language and returns its return value.

=head2 fabs

C<static method fabs : double ($x : double);>

Calls L<fabs|https://linux.die.net/man/3/fabs> function defined in C<math.h> in the C language and returns its return value.

=head2 fabsf

C<static method fabsf : float ($x : float);>

Calls L<fabsf|https://linux.die.net/man/3/fabsf> function defined in C<math.h> in the C language and returns its return value.

=head2 fdim

C<static method fdim : double ($x : double, $y : double);>

Calls L<fdim|https://linux.die.net/man/3/fdim> function defined in C<math.h> in the C language and returns its return value.

=head2 fdimf

C<static method fdimf : float ($x : float, $y : float);>

Calls L<fdimf|https://linux.die.net/man/3/fdimf> function defined in C<math.h> in the C language and returns its return value.

=head2 FE_DOWNWARD

C<static method FE_DOWNWARD : int ();>

Returns the value of C<FE_DOWNWARD> macro defined in C<fenv.h> in the C language.

=head2 FE_TONEAREST

C<static method FE_TONEAREST : int ();>

Returns the value of C<FE_TONEAREST> macro defined in C<fenv.h> in the C language.

=head2 FE_TOWARDZERO

C<static method FE_TOWARDZERO : int ();>

Returns the value of C<FE_TOWARDZERO> macro defined in C<fenv.h> in the C language.

=head2 FE_UPWARD

C<static method FE_UPWARD : int ();>

Returns the value of C<FE_UPWARD> macro defined in C<fenv.h> in the C language.

=head2 fesetround

C<static method fesetround : int ($round : int);>

Calls L<fesetround|https://linux.die.net/man/3/fesetround> function defined in C<math.h> in the C language and returns its return value.

=head2 floor

C<static method floor : double ($x : double);>

Calls L<floor|https://linux.die.net/man/3/floor> function defined in C<math.h> in the C language and returns its return value.

=head2 floorf

C<static method floorf : float ($x : float);>

Calls L<floorf|https://linux.die.net/man/3/floorf> function defined in C<math.h> in the C language and returns its return value.

=head2 fma

C<static method fma : double ($x : double, $y : double, $x3 : double);>

Calls L<fma|https://linux.die.net/man/3/fma> function defined in C<math.h> in the C language and returns its return value.

=head2 fmaf

C<static method fmaf : float ($x : float, $y : float, $x3 : float);>

Calls L<fmaf|https://linux.die.net/man/3/fmaf> function defined in C<math.h> in the C language and returns its return value.

=head2 fmax

C<static method fmax : double ($x : double, $y : double);>

Calls L<fmax|https://linux.die.net/man/3/fmax> function defined in C<math.h> in the C language and returns its return value.

=head2 fmaxf

C<static method fmaxf : float ($x : float, $y : float);>

Calls L<fmaxf|https://linux.die.net/man/3/fmaxf> function defined in C<math.h> in the C language and returns its return value.

=head2 fmin

C<static method fmin : double ($x : double, $y : double);>

Calls L<fmin|https://linux.die.net/man/3/fmin> function defined in C<math.h> in the C language and returns its return value.

=head2 fminf

C<static method fminf : float ($x : float, $y : float);>

Calls L<fminf|https://linux.die.net/man/3/fminf> function defined in C<math.h> in the C language and returns its return value.

=head2 fmod

C<static method fmod : double ($x : double, $y : double);>

Calls L<fmod|https://linux.die.net/man/3/fmod> function defined in C<math.h> in the C language and returns its return value.

=head2 fmodf

C<static method fmodf : float ($x : float, $y : float);>

Calls L<fmodf|https://linux.die.net/man/3/fmodf> function defined in C<math.h> in the C language and returns its return value.

=head2 FP_ILOGB0

C<static method FP_ILOGB0 : int ();>

Return the value of C<FP_ILOGB0> macro defined in C<fenv.h> in the C language.

=head2 FP_ILOGBNAN

C<static method FP_ILOGBNAN : int ();>

Return the value of C<FP_ILOGBNAN> macro defined in C<fenv.h> in the C language.

=head2 FP_INFINITE

C<static method FP_INFINITE : int ();>

Return the value of C<FP_INFINITE> macro defined in C<fenv.h> in the C language.

=head2 FP_NAN

C<static method FP_NAN : int ();>

Return the value of C<FP_NAN> macro defined in C<fenv.h> in the C language.

=head2 FP_ZERO

C<static method FP_ZERO : int ();>

Return the value of C<FP_ZERO> macro defined in C<fenv.h> in the C language.

=head2 fpclassify

C<static method fpclassify : int ($x : double);>

Calls L<fpclassify|https://linux.die.net/man/3/fpclassify> function defined in C<math.h> in the C language.

=head2 fpclassifyf

C<static method fpclassifyf : int ($x : float);>

Calls L<fpclassify|https://linux.die.net/man/3/fpclassify> function defined in C<math.h> in the C language.

=head2 frexp

C<static method frexp : double ($x : double, $exp : int*);>

Calls L<frexp|https://linux.die.net/man/3/frexp> function defined in C<math.h> in the C language and returns its return value.

=head2 frexpf

C<static method frexpf : float ($x : float, $exp : int*);>

Calls L<frexpf|https://linux.die.net/man/3/frexpf> function defined in C<math.h> in the C language and returns its return value.

=head2 HUGE_VAL

C<static method HUGE_VAL : double ();>

Returns the value of C<HUGE_VAL> macro defined in C<math.h> in the C language and returns its return value.

=head2 HUGE_VALF

C<static method HUGE_VALF : float ();>

Returns the value of C<HUGE_VALF> macro defined in C<math.h> in the C language and returns its return value.

=head2 hypot

C<static method hypot : double ($x : double, $y : double);>

Calls L<hypot|https://linux.die.net/man/3/hypot> function defined in C<math.h> in the C language and returns its return value.

=head2 hypotf

C<static method hypotf : float ($x : float, $y : float);>

Calls L<hypotf|https://linux.die.net/man/3/hypotf> function defined in C<math.h> in the C language and returns its return value.

=head2 ilogb

C<static method ilogb : int ($x : double);>

Calls L<ilogb|https://linux.die.net/man/3/ilogb> function defined in C<math.h> in the C language and returns its return value.

=head2 ilogbf

C<static method ilogbf : int ($x : float);>

Calls L<ilogbf|https://linux.die.net/man/3/ilogbf> function defined in C<math.h> in the C language and returns its return value.

=head2 INFINITY

C<static method INFINITY : double ();>

Returns the value of C<INFINITY> macro defined in C<math.h> in the C language, and returns the return value as a dobule value.

=head2 INFINITYF

C<static method INFINITYF : float ();>

Returns the value of C<INFINITY> macro defined in C<math.h> in the C language, and the return value as a float value.

=head2 isfinite

C<static method isfinite : int ($x : double);>

Calls L<isfinite|https://linux.die.net/man/3/isfinite> function defined in C<math.h> in the C language.

=head2 isfinitef

C<static method isfinitef : int ($x : float);>

Calls L<isfinite|https://linux.die.net/man/3/isfinite> function defined in C<math.h> in the C language.

=head2 isgreater

C<static method isgreater : int ($x : double, $y : double);>

Calls L<isgreater|https://linux.die.net/man/3/isgreater> function defined in C<math.h> in the C language.

=head2 isgreaterequal

C<static method isgreaterequal : int ($x : double, $y : double);>

Calls L<isgreaterequal|https://linux.die.net/man/3/isgreaterequal> function defined in C<math.h> in the C language.

=head2 isgreaterequalf

C<static method isgreaterequalf : int ($x : float, $y : float);>

Calls L<isgreaterequal|https://linux.die.net/man/3/isgreaterequal> function defined in C<math.h> in the C language.

=head2 isgreaterf

C<static method isgreaterf : int ($x : float, $y : float);>

Calls L<isgreater|https://linux.die.net/man/3/isgreater> function defined in C<math.h> in the C language.

=head2 isinf

C<static method isinf : int ($x : double);>

Calls L<isinf|https://linux.die.net/man/3/isinf> function defined in C<math.h> in the C language.

=head2 isinff

C<static method isinff : int($x : float);>

Calls L<isinf|https://linux.die.net/man/3/isinf> function defined in C<math.h> in the C language.

=head2 isless

C<static method isless : int ($x : double, $y : double);>

Calls L<isless|https://linux.die.net/man/3/isless> function defined in C<math.h> in the C language.

=head2 islessequal

C<static method islessequal : int ($x : double, $y : double);>

Calls L<islessequal|https://linux.die.net/man/3/islessequal> function defined in C<math.h> in the C language.

=head2 islessequalf

C<static method islessequalf : int ($x : float, $y : float);>

Calls L<islessequal|https://linux.die.net/man/3/islessequal> function defined in C<math.h> in the C language.

=head2 islessf

C<static method islessf : int ($x : float, $y : float);>

Calls L<isless|https://linux.die.net/man/3/isless> function defined in C<math.h> in the C language.

=head2 islessgreater

C<static method islessgreater : int ($x : double, $y : double);>

Calls L<islessgreater|https://linux.die.net/man/3/islessgreater> function defined in C<math.h> in the C language.

=head2 islessgreaterf

C<static method islessgreaterf : int ($x : float, $y : float);>

Calls L<islessgreater|https://linux.die.net/man/3/islessgreater> function defined in C<math.h> in the C language.

=head2 isnan

C<static method isnan : int ($x : double);>

Calls L<isnan|https://linux.die.net/man/3/isnan> function defined in C<math.h> in the C language.

=head2 isnanf

C<static method isnanf : int ($x : float);>

Calls L<isnanf|https://linux.die.net/man/3/isnan> function defined in C<math.h> in the C language.

=head2 isunordered

C<static method isunordered : int ($x : double, $y : double);>

Calls L<isunordered|https://linux.die.net/man/3/isunordered> function defined in C<math.h> in the C language.

=head2 isunorderedf

C<static method isunorderedf : int ($x : float, $y : float);>

Calls L<isunordered|https://linux.die.net/man/3/isunordered> function defined in C<math.h> in the C language.

=head2 labs

C<static method labs : long ($x : long);>

Returns the abusolute value of $x.

=head2 ldexp

C<static method ldexp : double ($x : double, $exp : int);>

Calls L<ldexp|https://linux.die.net/man/3/ldexp> function defined in C<math.h> in the C language and returns its return value.

=head2 ldexpf

C<static method ldexpf : float ($x : float, $exp : int);>

Calls L<ldexpf|https://linux.die.net/man/3/ldexpf> function defined in C<math.h> in the C language and returns its return value.

=head2 lgamma

C<static method lgamma : double ($x : double);>

Calls L<lgamma|https://linux.die.net/man/3/lgamma> function defined in C<math.h> in the C language and returns its return value.

=head2 lgammaf

C<static method lgammaf : float ($x : float);>

Calls L<lgammaf|https://linux.die.net/man/3/lgammaf> function defined in C<math.h> in the C language and returns its return value.

=head2 log

C<static method log : double ($x : double);>

Calls L<log|https://linux.die.net/man/3/log> function defined in C<math.h> in the C language and returns its return value.

=head2 log10

C<static method log10 : double ($x : double);>

Calls L<log10|https://linux.die.net/man/3/log10> function defined in C<math.h> in the C language and returns its return value.

=head2 log10f

C<static method log10f : float ($x : float);>

Calls L<log10f|https://linux.die.net/man/3/log10f> function defined in C<math.h> in the C language and returns its return value.

=head2 log1p

C<static method log1p : double ($x : double);>

Calls L<log1p|https://linux.die.net/man/3/log1p> function defined in C<math.h> in the C language and returns its return value.

=head2 log1pf

C<static method log1pf : float ($x : float);>

Calls L<log1pf|https://linux.die.net/man/3/log1pf> function defined in C<math.h> in the C language and returns its return value.

=head2 log2

C<static method log2 : double ($x : double);>

Calls L<log2|https://linux.die.net/man/3/log2> function defined in C<math.h> in the C language and returns its return value.

=head2 log2f

C<static method log2f : float ($x : float);>

Calls L<log2f|https://linux.die.net/man/3/log2f> function defined in C<math.h> in the C language and returns its return value.

=head2 logb

C<static method logb : double ($x : double);>

Calls L<logb|https://linux.die.net/man/3/logb> function defined in C<math.h> in the C language and returns its return value.

=head2 logbf

C<static method logbf : float ($x : float);>

Calls L<logbf|https://linux.die.net/man/3/logbf> function defined in C<math.h> in the C language and returns its return value.

=head2 logf

C<static method logf : float ($x : float);>

Calls L<logf|https://linux.die.net/man/3/logf> function defined in C<math.h> in the C language and returns its return value.

=head2 lround

C<static method lround : long ($x : double);>

Calls L<llround|https://linux.die.net/man/3/llround> function defined in C<math.h> in the C language and returns its return value.

=head2 lroundf

C<static method lroundf : long ($x : float);>

Calls L<llroundf|https://linux.die.net/man/3/llroundf> function defined in C<math.h> in the C language and returns its return value.

=head2 modf

C<static method modf : double ($x : double, $intpart : double*);>

Calls L<modf|https://linux.die.net/man/3/modf> function defined in C<math.h> in the C language and returns its return value.

=head2 modff

C<static method modff : float ($x : float, $intpart : float*);>

Calls L<modff|https://linux.die.net/man/3/modff> function defined in C<math.h> in the C language and returns its return value.

=head2 NAN

C<static method NAN : double ();>

Returns the value of C<NAN> macro defined in C<math.h> in the C language.

=head2 nan

C<static method nan : double ($string : string);>

Calls L<nan|https://linux.die.net/man/3/nan> function defined in C<math.h> in the C language and returns its return value.

Exceptions:

The $string must be defined. Otherwise an exception is thrown.

=head2 NANF

C<static method NANF : float ();>

Returns the value of C<NAN> macro defined in C<math.h> in the C language, and return the return value as a float type.

=head2 nanf

C<static method nanf : float ($string : string);>

Calls L<nanf|https://linux.die.net/man/3/nanf> function defined in C<math.h> in the C language and returns its return value.

Exceptions:

The $string must be defined. Otherwise an exception is thrown.

=head2 nearbyint

C<static method nearbyint : double ($x : double);>

Calls L<nearbyint|https://linux.die.net/man/3/nearbyint> function defined in C<math.h> in the C language and returns its return value.

=head2 nearbyintf

C<static method nearbyintf : float ($x : float);>

Calls L<nearbyintf|https://linux.die.net/man/3/nearbyintf> function defined in C<math.h> in the C language and returns its return value.

=head2 nextafter

C<static method nextafter : double ($x : double, $y : double);>

Calls L<nextafter|https://linux.die.net/man/3/nextafter> function defined in C<math.h> in the C language and returns its return value.

=head2 nextafterf

C<static method nextafterf : float ($x : float, $y : float);>

Calls L<nextafterf|https://linux.die.net/man/3/nextafterf> function defined in C<math.h> in the C language and returns its return value.

=head2 nexttoward

C<static method nexttoward : double ($x : double, $y : double);>

Calls L<nexttoward|https://linux.die.net/man/3/nexttoward> function defined in C<math.h> in the C language and returns its return value.

=head2 nexttowardf

C<static method nexttowardf : float ($x : float, $y : double);>

Calls L<nexttowardf|https://linux.die.net/man/3/nexttowardf> function defined in C<math.h> in the C language and returns its return value.

=head2 PI

C<static method PI : double ();>

Returns pi. This value is C<0x1.921fb54442d18p+1>.

=head2 pow

C<static method pow : double ($x : double, $y : double);>

Calls L<pow|https://linux.die.net/man/3/pow> function defined in C<math.h> in the C language and returns its return value.

=head2 powf

C<static method powf : float ($x : float, $y : float);>

Calls L<powf|https://linux.die.net/man/3/powf> function defined in C<math.h> in the C language and returns its return value.

=head2 remainder

C<static method remainder : double ($x : double, $y : double);>

Calls L<remainder|https://linux.die.net/man/3/remainder> function defined in C<math.h> in the C language and returns its return value.

=head2 remainderf

C<static method remainderf : float ($x : float, $y : float);>

Calls L<remainderf|https://linux.die.net/man/3/remainderf> function defined in C<math.h> in the C language and returns its return value.

=head2 remquo

C<static method remquo : double ($x : double, $y : double, $quo : int*);>

Calls L<remquo|https://linux.die.net/man/3/remquo> function defined in C<math.h> in the C language and returns its return value.

=head2 remquof

C<static method remquof : float ($x : float, $y : float, $quo : int*);>

Calls L<remquof|https://linux.die.net/man/3/remquof> function defined in C<math.h> in the C language and returns its return value.

=head2 round

C<static method round : double ($x : double);>

Calls L<round|https://linux.die.net/man/3/round> function defined in C<math.h> in the C language and returns its return value.

=head2 roundf

C<static method roundf : float ($x : float);>

Calls L<roundf|https://linux.die.net/man/3/roundf> function defined in C<math.h> in the C language and returns its return value.

=head2 scalbln

C<static method scalbln : double ($x : double, $exp : long);>

Calls L<scalbln|https://linux.die.net/man/3/scalbln> function defined in C<math.h> in the C language and returns its return value.

=head2 scalblnf

C<static method scalblnf : float ($x : float, $exp : long);>

Calls L<scalblnf|https://linux.die.net/man/3/scalblnf> function defined in C<math.h> in the C language and returns its return value.

=head2 scalbn

C<static method scalbn : double ($x : double, $exp : int);>

Calls L<scalbn|https://linux.die.net/man/3/scalbn> function defined in C<math.h> in the C language and returns its return value.

=head2 scalbnf

C<static method scalbnf : float ($x : float, $exp : int);>

Calls L<scalbnf|https://linux.die.net/man/3/scalbnf> function defined in C<math.h> in the C language and returns its return value.

=head2 signbit

C<static method signbit : int ($x : double);>

Calls L<signbit|https://linux.die.net/man/3/signbit> function defined in C<math.h> in the C language and returns its return value.

=head2 signbitf

C<static method signbitf : int ($x : float);>

Calls L<signbit|https://linux.die.net/man/3/signbit> function defined in C<math.h> in the C language and returns its return value.

=head2 sin

C<static method sin : double ($x : double);>

Calls L<sin|https://linux.die.net/man/3/sin> function defined in C<math.h> in the C language and returns its return value.

=head2 sinf

C<static method sinf : float ($x : float);>

Calls L<sinf|https://linux.die.net/man/3/sinf> function defined in C<math.h> in the C language and returns its return value.

=head2 sinh

C<static method sinh : double ($x : double);>

Calls L<sinh|https://linux.die.net/man/3/sinh> function defined in C<math.h> in the C language and returns its return value.

=head2 sinhf

C<static method sinhf : float ($x : float);>

Calls L<sinhf|https://linux.die.net/man/3/sinhf> function defined in C<math.h> in the C language and returns its return value.

=head2 sqrt

C<static method sqrt : double ($x : double);>

Calls L<sqrt|https://linux.die.net/man/3/sqrt> function defined in C<math.h> in the C language and returns its return value.

=head2 sqrtf

C<static method sqrtf : float ($x : float);>

Calls L<sqrtf|https://linux.die.net/man/3/sqrtf> function defined in C<math.h> in the C language and returns its return value.

=head2 tan

C<static method tan : double ($x : double);>

Calls L<tan|https://linux.die.net/man/3/tan> function defined in C<math.h> in the C language and returns its return value.

=head2 tanf

C<static method tanf : float ($x : float);>

Calls L<tanf|https://linux.die.net/man/3/tanf> function defined in C<math.h> in the C language and returns its return value.

=head2 tanh

C<static method tanh : double ($x : double);>

Calls L<tanh|https://linux.die.net/man/3/tanh> function defined in C<math.h> in the C language and returns its return value.

=head2 tanhf

C<static method tanhf : float ($x : float);>

Calls L<tanhf|https://linux.die.net/man/3/tanhf> function defined in C<math.h> in the C language and returns its return value.

=head2 tgamma

C<static method tgamma : double ($x : double);>

Calls L<tgamma|https://linux.die.net/man/3/tgamma> function defined in C<math.h> in the C language and returns its return value.

=head2 tgammaf

C<static method tgammaf : float ($x : float);>

Calls L<tgammaf|https://linux.die.net/man/3/tgammaf> function defined in C<math.h> in the C language and returns its return value.

=head2 trunc

C<static method trunc : double ($x : double);>

Calls L<trunc|https://linux.die.net/man/3/trunc> function defined in C<math.h> in the C language and returns its return value.

=head2 truncf

C<static method truncf : float ($x : float);>

Calls L<truncf|https://linux.die.net/man/3/truncf> function defined in C<math.h> in the C language and returns its return value.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

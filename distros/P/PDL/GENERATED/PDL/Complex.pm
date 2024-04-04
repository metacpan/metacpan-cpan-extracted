#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::Complex;

our @EXPORT_OK = qw(Ctan Catan re im i cplx real r2C i2C Cr2p Cp2r Cadd Csub Cmul Cprodover Cscale Cdiv Ceq Cconj Cabs Cabs2 Carg Csin Ccos Cexp Clog Cpow Csqrt Casin Cacos Csinh Ccosh Ctanh Casinh Cacosh Catanh Cproj Croots rCpolynomial );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core();
use PDL::Exporter;
use DynaLoader;

BEGIN {
   
   our @ISA = ( 'PDL::Exporter','DynaLoader','PDL' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Complex ;
}






#line 18 "complex.pd"

use strict;
use warnings;
use Carp;
our $VERSION = '2.009';

=encoding iso-8859-1

=head1 NAME

PDL::Complex - handle complex numbers (DEPRECATED - use native complex)

=head1 SYNOPSIS

  use PDL;
  use PDL::Complex;

=head1 DESCRIPTION

This module is deprecated in favour of using "native complex" data types, e.g.:

  use PDL;
  my $complex_pdl = cdouble('[1+3i]');
  print $complex_pdl * pdl('i'); # [-3+i]

This module features a growing number of functions manipulating complex
numbers. These are usually represented as a pair C<[ real imag ]> or
C<[ magnitude phase ]>. If not explicitly mentioned, the functions can work
inplace (not yet implemented!!!) and require rectangular form.

While there is a procedural interface available (C<< $x/$y*$c <=> Cmul
(Cdiv ($x, $y), $c) >>), you can also opt to cast your pdl's into the
C<PDL::Complex> datatype, which works just like your normal ndarrays, but
with all the normal perl operators overloaded.

The latter means that C<sin($x) + $y/$c> will be evaluated using the
normal rules of complex numbers, while other pdl functions (like C<max>)
just treat the ndarray as a real-valued ndarray with a lowest dimension of
size 2, so C<max> will return the maximum of all real and imaginary parts,
not the "highest" (for some definition)

=head2 Native complex support

2.027 added changes in complex number handling, with support for C99
complex floating-point types, and most functions and modules in the core
distribution support these as well.

PDL can now handle complex numbers natively as scalars. This has
the advantage that real and complex valued ndarrays have the same
dimensions. Consider this when writing code in the future.

See L<PDL::Ops/re>, L<PDL::Ops/im>, L<PDL::Ops/abs>, L<PDL::Ops/carg>,
L<PDL::Ops/conj> for more.

=head1 TIPS, TRICKS & CAVEATS

=over 4

=item *

C<i> is a function (not, as of 2.047, a constant) exported by this module,
which represents C<-1**0.5>, i.e. the imaginary unit. it can be used to
quickly and conveniently write complex constants like this: C<4+3*i>.

B<NB> This will override the PDL::Core function of the same name, which
returns a native complex value.

=item *

Use C<r2C(real-values)> to convert from real to complex, as in C<$r
= Cpow $cplx, r2C 2>. The overloaded operators automatically do that for
you, all the other functions, do not. So C<Croots 1, 5> will return all
the fifths roots of 1+1*i (due to broadcasting).

=item *

use C<cplx(real-valued-ndarray)> to cast from normal ndarrays into the
complex datatype. Use C<real(complex-valued-ndarray)> to cast back. This
requires a copy, though.

=back

=head1 EXAMPLE WALK-THROUGH

The complex constant five is equal to C<pdl(1,0)>:

   pdl> p $x = r2C 5
   5 +0i

Now calculate the three cubic roots of five:

   pdl> p $r = Croots $x, 3
   [1.70998 +0i  -0.854988 +1.48088i  -0.854988 -1.48088i]

Check that these really are the roots:

   pdl> p $r ** 3
   [5 +0i  5 -1.22465e-15i  5 -7.65714e-15i]

Duh! Could be better. Now try by multiplying C<$r> three times with itself:

   pdl> p $r*$r*$r
   [5 +0i  5 -4.72647e-15i  5 -7.53694e-15i]

Well... maybe C<Cpow> (which is used by the C<**> operator) isn't as
bad as I thought. Now multiply by C<i> and negate, then take the complex
conjugate, which is just a very expensive way of swapping real and
imaginary parts.

   pdl> p Cconj(-($r*i))
   [0 +1.70998i  1.48088 -0.854988i  -1.48088 -0.854988i]

Now plot the magnitude of (part of) the complex sine. First generate the
coefficients:

   pdl> $sin = i * zeroes(50)->xlinvals(2,4) + zeroes(50)->xlinvals(0,7)

Now plot the imaginary part, the real part and the magnitude of the sine
into the same diagram:

   pdl> use PDL::Graphics::Gnuplot
   pdl> gplot( with => 'lines',
              PDL::cat(im ( sin $sin ),
                       re ( sin $sin ),
                       abs( sin $sin ) ))

An ASCII version of this plot looks like this:

  30 ++-----+------+------+------+------+------+------+------+------+-----++
     +      +      +      +      +      +      +      +      +      +      +
     |                                                                   $$|
     |                                                                  $  |
  25 ++                                                               $$  ++
     |                                                              ***    |
     |                                                            **   *** |
     |                                                         $$*        *|
  20 ++                                                       $**         ++
     |                                                     $$$*           #|
     |                                                  $$$   *          # |
     |                                                $$     *           # |
  15 ++                                            $$$       *          # ++
     |                                          $$$        **           #  |
     |                                      $$$$          *            #   |
     |                                  $$$$              *            #   |
  10 ++                            $$$$$                 *            #   ++
     |                        $$$$$                     *             #    |
     |                 $$$$$$$                         *             #     |
   5 ++       $$$############                          *             #    ++
     |*****$$$###            ###                      *             #      |
     *    #*****                #                     *             #      |
     | ###      ***              ###                **              #      |
   0 ##            ***              #              *               #      ++
     |                *              #             *              #        |
     |                 ***            #          **               #        |
     |                    *            #        *                #         |
  -5 ++                    **           #      *                 #        ++
     |                       ***         ##  **                 #          |
     |                          *          #*                  #           |
     |                           ****    ***##                #            |
 -10 ++                              ****     #              #            ++
     |                                         #             #             |
     |                                          ##         ##              |
     +      +      +      +      +      +      +  ### + ###  +      +      +
 -15 ++-----+------+------+------+------+------+-----###-----+------+-----++
     0      5      10     15     20     25     30     35     40     45     50

=head1 OPERATORS

The following operators are overloaded:

=over 4

=item +, += (addition)

=item -, -= (subtraction)

=item *, *= (multiplication; L</Cmul>)

=item /, /= (division; L</Cdiv>)

=item **, **= (exponentiation; L</Cpow>)

=item atan2 (4-quadrant arc tangent)

=item sin (L</Csin>)

=item cos (L</Ccos>)

=item exp (L</Cexp>)

=item abs (L</Cabs>)

=item log (L</Clog>)

=item sqrt (L</Csqrt>)

=item ++, -- (increment, decrement; they affect the real part of the complex number only)

=item "" (stringification)

=back

Comparing complex numbers other than for equality is a fatal error.

=cut

my $i;
BEGIN { $i = bless PDL->pdl(0,1) }
{
no warnings 'redefine';
sub i { $i->copy + (@_ ? $_[0] : 0) };
}

# sensible aliases from PDL::LinearAlgebra
*r2p = \&Cr2p;
*p2r = \&Cp2r;
*conj = \&Cconj;
*abs = \&Cabs;
*abs2 = \&Cabs2;
*arg = \&Carg;
*tan = \&Ctan;
*proj = \&Cproj;
*asin = \&Casin;
*acos = \&Cacos;
*atan = \&Catan;
*sinh = \&Csinh;
*cosh = \&Ccosh;
*tanh = \&Ctanh;
*asinh = \&Casinh;
*acosh = \&Cacosh;
*atanh = \&Catanh;
#line 258 "Complex.pm"


=head1 FUNCTIONS

=cut





#line 330 "complex.pd"

=head2 from_native

=for ref

Class method to convert a native-complex ndarray to a PDL::Complex object.

=for usage

 PDL::Complex->from_native($native_complex_ndarray)

=cut

sub from_native {
  my ($class, $ndarray) = @_;
  return $ndarray if UNIVERSAL::isa($ndarray,'PDL::Complex'); # NOOP if P:C
  croak "not an ndarray" if !UNIVERSAL::isa($ndarray,'PDL');
  croak "not a native complex ndarray" if $ndarray->type->real;
  bless PDL::append($ndarray->re->dummy(0),$ndarray->im->dummy(0)), $class;
}

=head2 as_native

=for ref

Object method to convert a PDL::Complex object to a native-complex ndarray.

=for usage

 $pdl_complex_obj->as_native

=cut

sub as_native {
  PDL::Ops::czip(map $_[0]->slice("($_)"), 0..1);
}

=head2 cplx

=for ref

Cast a real-valued ndarray to the complex datatype.

The first dimension of the ndarray must be of size 2. After this the
usual (complex) arithmetic operators are applied to this pdl, rather
than the normal elementwise pdl operators.  Dataflow to the complex
parent works. Use C<sever> on the result if you don't want this.

=for usage

 cplx($real_valued_pdl)

=head2 complex

=for ref

Cast a real-valued ndarray to the complex datatype I<without> dataflow
and I<inplace>.

Achieved by merely reblessing an ndarray. The first dimension of the
ndarray must be of size 2.

=for usage

 complex($real_valued_pdl)

=head2 real

=for ref

Cast a complex valued pdl back to the "normal" pdl datatype.

Afterwards the normal elementwise pdl operators are used in
operations. Dataflow to the real parent works. Use C<sever> on the
result if you don't want this.

=for usage

 real($cplx_valued_pdl)

=cut

sub cplx($) {
   return $_[0] if UNIVERSAL::isa($_[0],'PDL::Complex'); # NOOP if just ndarray
   croak "first dimsize must be 2" unless $_[0]->dims > 0 && $_[0]->dim(0) == 2;
   bless $_[0]->slice('');
}

sub complex($) {
   return $_[0] if UNIVERSAL::isa($_[0],'PDL::Complex'); # NOOP if just ndarray
   croak "first dimsize must be 2" unless $_[0]->dims > 0 && $_[0]->dim(0) == 2;
   bless $_[0];
}

*PDL::cplx = \&cplx;
*PDL::complex = \&complex;

sub real($) {
   return $_[0] unless UNIVERSAL::isa($_[0],'PDL::Complex'); # NOOP unless complex
   bless $_[0]->slice(''), 'PDL';
}
#line 371 "Complex.pm"


=head2 r2C

=for sig

  Signature: (r(); [o]c(m=2))

=for ref

convert real to complex, assuming an imaginary part of zero

=for bad

r2C does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





undef &PDL::r2C;
*PDL::r2C = \&PDL::Complex::r2C;
sub PDL::Complex::r2C {
  return $_[0] if UNIVERSAL::isa($_[0],'PDL::Complex');
  my $r = __PACKAGE__->initialize;
  &PDL::Complex::_r2C_int($_[0], $r);
  $r }




BEGIN {*r2C = \&PDL::Complex::r2C;
}





=head2 i2C

=for sig

  Signature: (r(); [o]c(m=2))

=for ref

convert imaginary to complex, assuming a real part of zero

=for bad

i2C does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




undef &PDL::i2C; *PDL::i2C = \&PDL::Complex::i2C; sub PDL::Complex::i2C { my $r = __PACKAGE__->initialize; &PDL::Complex::_i2C_int($_[0], $r); $r }


BEGIN {*i2C = \&PDL::Complex::i2C;
}





=head2 Cr2p

=for sig

  Signature: (r(m=2); float+ [o]p(m=2))

=for ref

convert complex numbers in rectangular form to polar (mod,arg) form. Works inplace

=for bad

Cr2p does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




BEGIN {*Cr2p = \&PDL::Complex::Cr2p;
}





=head2 Cp2r

=for sig

  Signature: (r(m=2); [o]p(m=2))

=for ref

convert complex numbers in polar (mod,arg) form to rectangular form. Works inplace

=for bad

Cp2r does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




BEGIN {*Cp2r = \&PDL::Complex::Cp2r;
}



BEGIN {*Cadd = \&PDL::Complex::Cadd;
}



BEGIN {*Csub = \&PDL::Complex::Csub;
}





=head2 Cmul

=for sig

  Signature: (a(m=2); b(m=2); [o]c(m=2))

=for ref

complex multiplication

=for bad

Cmul does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




BEGIN {*Cmul = \&PDL::Complex::Cmul;
}





=head2 Cprodover

=for sig

  Signature: (a(m=2,n); [o]c(m=2))

=for ref

Project via product to N-1 dimension

=for bad

Cprodover does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




BEGIN {*Cprodover = \&PDL::Complex::Cprodover;
}





=head2 Cscale

=for sig

  Signature: (a(m=2); b(); [o]c(m=2))

=for ref

mixed complex/real multiplication

=for bad

Cscale does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




BEGIN {*Cscale = \&PDL::Complex::Cscale;
}





=head2 Cdiv

=for sig

  Signature: (a(m=2); b(m=2); [o]c(m=2))

=for ref

complex division

=for bad

Cdiv does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




BEGIN {*Cdiv = \&PDL::Complex::Cdiv;
}





=head2 Ceq

=for sig

  Signature: (a(m=2); b(m=2); [o]c())

=for ref

Complex equality operator.

=for bad

Ceq does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




sub PDL::Complex::Ceq {
    my @args = !$_[2] ? @_[1,0] : @_[0,1];
    $args[1] = r2C($args[1]) if ref $args[1] ne __PACKAGE__;
    PDL::Complex::_Ceq_int($args[0], $args[1], my $r = PDL->null);
    $r;
}



BEGIN {*Ceq = \&PDL::Complex::Ceq;
}





=head2 Cconj

=for sig

  Signature: (a(m=2); [o]c(m=2))

=for ref

complex conjugation. Works inplace

=for bad

Cconj does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




BEGIN {*Cconj = \&PDL::Complex::Cconj;
}





=head2 Cabs

=for sig

  Signature: (a(m=2); [o]c())

=for ref

complex C<abs()> (also known as I<modulus>)

=for bad

Cabs does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




sub PDL::Complex::Cabs($) {
           my $pdl= shift;
           my $abs = PDL->null;
           &PDL::Complex::_Cabs_int($pdl, $abs);
           $abs;
        }


BEGIN {*Cabs = \&PDL::Complex::Cabs;
}





=head2 Cabs2

=for sig

  Signature: (a(m=2); [o]c())

=for ref

complex squared C<abs()> (also known I<squared modulus>)

=for bad

Cabs2 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




sub PDL::Complex::Cabs2($) {
           my $pdl= shift;
           my $abs2 = PDL->null;
           &PDL::Complex::_Cabs2_int($pdl, $abs2);
           $abs2;
        }


BEGIN {*Cabs2 = \&PDL::Complex::Cabs2;
}





=head2 Carg

=for sig

  Signature: (a(m=2); [o]c())

=for ref

complex argument function ("angle")

=for bad

Carg does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




sub PDL::Complex::Carg($) {
           my $pdl= shift;
           my $arg = PDL->null;
           &PDL::Complex::_Carg_int($pdl, $arg);
           $arg;
        }


BEGIN {*Carg = \&PDL::Complex::Carg;
}





=head2 Csin

=for sig

  Signature: (a(m=2); [o]c(m=2))

=for ref

  sin (a) = 1/(2*i) * (exp (a*i) - exp (-a*i)). Works inplace

=for bad

Csin does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




BEGIN {*Csin = \&PDL::Complex::Csin;
}





=head2 Ccos

=for sig

  Signature: (a(m=2); [o]c(m=2))

=for ref

  cos (a) = 1/2 * (exp (a*i) + exp (-a*i)). Works inplace

=for bad

Ccos does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




BEGIN {*Ccos = \&PDL::Complex::Ccos;
}




#line 683 "complex.pd"

=head2 Ctan

=for ref

Complex tangent

  tan (a) = -i * (exp (a*i) - exp (-a*i)) / (exp (a*i) + exp (-a*i))

Does not work inplace.

=cut

sub Ctan($) { Csin($_[0]) / Ccos($_[0]) }
#line 851 "Complex.pm"


=head2 Cexp

=for sig

  Signature: (a(m=2); [o]c(m=2))

=for ref

  exp (a) = exp (real (a)) * (cos (imag (a)) + i * sin (imag (a))). Works inplace

=for bad

Cexp does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




BEGIN {*Cexp = \&PDL::Complex::Cexp;
}





=head2 Clog

=for sig

  Signature: (a(m=2); [o]c(m=2))

=for ref

  log (a) = log (cabs (a)) + i * carg (a). Works inplace

=for bad

Clog does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




BEGIN {*Clog = \&PDL::Complex::Clog;
}





=head2 Cpow

=for sig

  Signature: (a(m=2); b(m=2); [o]c(m=2))

=for ref

complex C<pow()> (C<**>-operator)

=for bad

Cpow does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




BEGIN {*Cpow = \&PDL::Complex::Cpow;
}





=head2 Csqrt

=for sig

  Signature: (a(m=2); [o]c(m=2))

=for ref

Works inplace

=for bad

Csqrt does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




BEGIN {*Csqrt = \&PDL::Complex::Csqrt;
}





=head2 Casin

=for sig

  Signature: (a(m=2); [o]c(m=2))

=for ref

Works inplace

=for bad

Casin does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




BEGIN {*Casin = \&PDL::Complex::Casin;
}





=head2 Cacos

=for sig

  Signature: (a(m=2); [o]c(m=2))

=for ref

Works inplace

=for bad

Cacos does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




BEGIN {*Cacos = \&PDL::Complex::Cacos;
}




#line 830 "complex.pd"

=head2 Catan

=for ref

Return the complex C<atan()>.

Does not work inplace.

=cut

sub Catan($) {
   my $z = shift;
   Cmul Clog(Cdiv (PDL::Complex::i()+$z, PDL::Complex::i()-$z)), PDL->pdl(0, 0.5);
}
#line 1031 "Complex.pm"


=head2 Csinh

=for sig

  Signature: (a(m=2); [o]c(m=2))

=for ref

  sinh (a) = (exp (a) - exp (-a)) / 2. Works inplace

=for bad

Csinh does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




BEGIN {*Csinh = \&PDL::Complex::Csinh;
}





=head2 Ccosh

=for sig

  Signature: (a(m=2); [o]c(m=2))

=for ref

  cosh (a) = (exp (a) + exp (-a)) / 2. Works inplace

=for bad

Ccosh does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




BEGIN {*Ccosh = \&PDL::Complex::Ccosh;
}





=head2 Ctanh

=for sig

  Signature: (a(m=2); [o]c(m=2))

=for ref

Works inplace

=for bad

Ctanh does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




BEGIN {*Ctanh = \&PDL::Complex::Ctanh;
}





=head2 Casinh

=for sig

  Signature: (a(m=2); [o]c(m=2))

=for ref

Works inplace

=for bad

Casinh does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




BEGIN {*Casinh = \&PDL::Complex::Casinh;
}





=head2 Cacosh

=for sig

  Signature: (a(m=2); [o]c(m=2))

=for ref

Works inplace

=for bad

Cacosh does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




BEGIN {*Cacosh = \&PDL::Complex::Cacosh;
}





=head2 Catanh

=for sig

  Signature: (a(m=2); [o]c(m=2))

=for ref

Works inplace

=for bad

Catanh does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




BEGIN {*Catanh = \&PDL::Complex::Catanh;
}





=head2 Cproj

=for sig

  Signature: (a(m=2); [o]c(m=2))

=for ref

compute the projection of a complex number to the riemann sphere. Works inplace

=for bad

Cproj does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




BEGIN {*Cproj = \&PDL::Complex::Cproj;
}





=head2 Croots

=for sig

  Signature: (a(m=2); [o]c(m=2,n); int n => n)

=for ref

Compute the C<n> roots of C<a>. C<n> must be a positive integer. The result will always be a complex type!

=for bad

Croots does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




sub PDL::Complex::Croots($$) {
           my ($pdl, $n) = @_;
           my $r = PDL->null;
           &PDL::Complex::_Croots_int($pdl, $r, $n);
           bless $r;
        }


BEGIN {*Croots = \&PDL::Complex::Croots;
}




#line 998 "complex.pd"

=head2 re, im

Return the real or imaginary part of the complex number(s) given.

These are slicing operators, so data flow works. The real and
imaginary parts are returned as ndarrays (ref eq PDL).

=cut

sub re($) { $_[0]->slice("(0)") }
sub im($) { $_[0]->slice("(1)") }

{
no warnings 'redefine';
# if the argument does anything other than pass through 0-th dim, re-bless
sub slice :lvalue {
  my $first = ref $_[1] ? $_[1][0] : (split ',', $_[1])[0];
  my $class = ($first//'') =~ /^[:x]?$/i ? ref($_[0]) : 'PDL';
  my $ret = bless $_[0]->SUPER::slice(@_[1..$#_]), $class;
  $ret;
}
}
#line 1281 "Complex.pm"


=head2 rCpolynomial

=for sig

  Signature: (coeffs(n); x(c=2,m); [o]out(c=2,m))

=for ref

evaluate the polynomial with (real) coefficients C<coeffs> at the (complex) position(s) C<x>. C<coeffs[0]> is the constant term.

=for bad

rCpolynomial does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub rCpolynomial {
    my $coeffs = shift;
    my $x = shift;
    my $out = $x->copy;
    _rCpolynomial_int($coeffs,$x,$out);
    return PDL::complex($out);
    }



BEGIN {*rCpolynomial = \&PDL::Complex::rCpolynomial;
}






#line 1063 "complex.pd"

# undocumented compatibility functions (thanks to Luis Mochan!)
sub Catan2 { Clog( $_[1] + i()*$_[0])/i }
sub atan2 { Clog( $_[1] + i()*$_[0])/i }

=begin comment

In _gen_biop, the '+' or '-' between the operator (e.g., '*') and the
function that it overloads (e.g., 'Cmul') flags whether the operation
is ('+') or is not ('-') commutative. See the discussion of argument
swapping in the section "Calling Conventions and Magic Autogeneration"
in "perldoc overload".

=end comment

=cut

my %NO_MUTATE; BEGIN { @NO_MUTATE{qw(atan2 .= ==)} = (); }
sub _gen_biop {
   local $_ = shift;
   my $sub;
   die if !(my ($op, $commutes, $func) = /(\S+)([-+])(\w+)/);
   $sub = eval 'sub {
      my ($x, $y) = '.($commutes eq '+' ? '' : '$_[2] ? @_[1,0] : ').'@_[0,1];
      $_ = r2C $_ for grep ref $_ ne __PACKAGE__, $x, $y;
      '.$func.'($x, $y);
   }'; #need to swap?
   die if $@;
   ($op, $sub, exists $NO_MUTATE{$op} ? () : ("$op=", $sub));
}

sub _gen_unop {
   my ($op, $func) = split '@', $_[0];
   no strict 'refs';
   *$op = \&$func if $op =~ /\w+/; # create an alias
   ($op, eval 'sub { '.$func.' $_[0] }');
}

sub initialize {
   # Bless a null PDL into the supplied 1st arg package
   #   If 1st arg is a ref, get the package from it
   bless PDL->null, ref($_[0]) || $_[0];
}

# so broadcasting doesn't also assign the real value into the imaginary
sub Cassgn {
    my @args = !$_[2] ? @_[1,0] : @_[0,1];
    $args[1] = r2C($args[1]) if ref $args[1] ne __PACKAGE__;
    PDL::Ops::assgn(@args);
    $args[1];
}

use overload
   (map _gen_biop($_), qw(++Cadd --Csub *+Cmul /-Cdiv **-Cpow atan2-Catan2 ==+Ceq .=-Cassgn)),
   (map _gen_unop($_), qw(sin@Csin cos@Ccos exp@Cexp abs@Cabs log@Clog sqrt@Csqrt)),
   (map +($_ => sub { confess "Can't compare complex numbers" }), qw(< > <= >=)),
   "!=" => sub { !($_[0] == $_[1]) },
   '""' => sub { $_[0]->isnull ? "PDL::Complex->null" : $_[0]->as_native->string },
;

sub sum {
  my($x) = @_;
  return $x if $x->dims==1;
  my $tmp = $x->mv(0,-1)->clump(-2)->mv(1,0)->sumover;
  return $tmp;
}

sub sumover{
  my $m = shift;
  PDL::Ufunc::sumover($m->transpose);
}

*PDL::Complex::Csumover=\&sumover; # define through alias

*PDL::Complex::prodover=\&Cprodover; # define through alias

sub prod {
  my($x) = @_;
  return $x if $x->dims==1;
  my $tmp = $x->mv(0,-1)->clump(-2)->mv(1,0)->prodover;
  return $tmp;
}

=head1 AUTHOR

Copyright (C) 2000 Marc Lehmann <pcg@goof.com>.
All rights reserved. There is no warranty. You are allowed
to redistribute this software / documentation as described
in the file COPYING in the PDL distribution.

=head1 SEE ALSO

perl(1), L<PDL>.

=cut
#line 1419 "Complex.pm"

# Exit with OK status

1;

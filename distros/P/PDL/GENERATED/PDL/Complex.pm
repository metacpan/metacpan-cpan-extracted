
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::Complex;

@EXPORT_OK  = qw(  Ctan  Catan  re  im  i  cplx  real PDL::PP r2C PDL::PP i2C PDL::PP Cr2p PDL::PP Cp2r PDL::PP Cadd PDL::PP Csub PDL::PP Cmul PDL::PP Cprodover PDL::PP Cscale PDL::PP Cdiv PDL::PP Ccmp PDL::PP Cconj PDL::PP Cabs PDL::PP Cabs2 PDL::PP Carg PDL::PP Csin PDL::PP Ccos PDL::PP Cexp PDL::PP Clog PDL::PP Cpow PDL::PP Csqrt PDL::PP Casin PDL::PP Cacos PDL::PP Csinh PDL::PP Ccosh PDL::PP Ctanh PDL::PP Casinh PDL::PP Cacosh PDL::PP Catanh PDL::PP Cproj PDL::PP Croots PDL::PP rCpolynomial );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


BEGIN {
   
   @ISA    = ( 'PDL::Exporter','DynaLoader','PDL' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Complex ;
}



our $VERSION = '2.009';
   use PDL::Slices;
   use PDL::Types;
   use PDL::Bad;

   use vars qw($sep $sep2);



=encoding iso-8859-1

=head1 NAME

PDL::Complex - handle complex numbers

=head1 SYNOPSIS

  use PDL;
  use PDL::Complex;

=head1 DESCRIPTION

This module features a growing number of functions manipulating complex
numbers. These are usually represented as a pair C<[ real imag ]> or
C<[ magnitude phase ]>. If not explicitly mentioned, the functions can work
inplace (not yet implemented!!!) and require rectangular form.

While there is a procedural interface available (C<< $x/$y*$c <=> Cmul
(Cdiv ($x, $y), $c) >>), you can also opt to cast your pdl's into the
C<PDL::Complex> datatype, which works just like your normal piddles, but
with all the normal perl operators overloaded.

The latter means that C<sin($x) + $y/$c> will be evaluated using the
normal rules of complex numbers, while other pdl functions (like C<max>)
just treat the piddle as a real-valued piddle with a lowest dimension of
size 2, so C<max> will return the maximum of all real and imaginary parts,
not the "highest" (for some definition)

=head1 TIPS, TRICKS & CAVEATS

=over 4

=item *

C<i> is a constant exported by this module, which represents
C<-1**0.5>, i.e. the imaginary unit. it can be used to quickly and
conveniently write complex constants like this: C<4+3*i>.

=item *

Use C<r2C(real-values)> to convert from real to complex, as in C<$r
= Cpow $cplx, r2C 2>. The overloaded operators automatically do that for
you, all the other functions, do not. So C<Croots 1, 5> will return all
the fifths roots of 1+1*i (due to threading).

=item *

use C<cplx(real-valued-piddle)> to cast from normal piddles into the
complex datatype. Use C<real(complex-valued-piddle)> to cast back. This
requires a copy, though.

=item *

This module has received some testing by Vanuxem Grégory
(g.vanuxem at wanadoo dot fr). Please report any other errors you
come across!

=back

=head1 EXAMPLE WALK-THROUGH

The complex constant five is equal to C<pdl(1,0)>:

   pdl> p $x = r2C 5
   5 +0i

Now calculate the three cubic roots of of five:

   pdl> p $r = Croots $x, 3
   [1.70998 +0i  -0.854988 +1.48088i  -0.854988 -1.48088i]

Check that these really are the roots:

   pdl> p $r ** 3
   [5 +0i  5 -1.22465e-15i  5 -7.65714e-15i]

Duh! Could be better. Now try by multiplying C<$r> three times with itself:

   pdl> p $r*$r*$r
   [5 +0i  5 -4.72647e-15i  5 -7.53694e-15i]

Well... maybe C<Cpow> (which is used by the C<**> operator) isn't as
bad as I thought. Now multiply by C<i> and negate, which is just a very
expensive way of swapping real and imaginary parts.

   pdl> p -($r*i)
   [0 -1.70998i  1.48088 +0.854988i  -1.48088 +0.854988i]

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

=item *, *= (multiplication; L<Cmul|/Cmul>)

=item /, /= (division; L<Cdiv|/Cdiv>)

=item **, **= (exponentiation; L<Cpow|/Cpow>)

=item atan2 (4-quadrant arc tangent)

=item <=> (nonsensical comparison operator; L<Ccmp|/Ccmp>)

=item sin (L<Csin|/Csin>)

=item cos (L<Ccos|/Ccos>)

=item exp (L<Cexp|/Cexp>)

=item abs (L<Cabs|/Cabs>)

=item log (L<Clog|/Clog>)

=item sqrt (L<Csqrt|/Csqrt>)

=item <, <=, ==, !=, >=, > (just as nonsensical as L<Ccmp|/Ccmp>)

=item ++, -- (increment, decrement; they affect the real part of the complex number only)

=item "" (stringification)

=back

=cut

my $i;
BEGIN { $i = bless pdl 0,1 }
sub i () { $i->copy };






=head1 FUNCTIONS



=cut





=head2 cplx

=for ref

Cast a real-valued piddle to the complex datatype.

The first dimension of the piddle must be of size 2. After this the
usual (complex) arithmetic operators are applied to this pdl, rather
than the normal elementwise pdl operators.  Dataflow to the complex
parent works. Use C<sever> on the result if you don't want this.

=for usage

 cplx($real_valued_pdl)

=head2 complex

=for ref

Cast a real-valued piddle to the complex datatype I<without> dataflow
and I<inplace>.

Achieved by merely reblessing a piddle. The first dimension of the
piddle must be of size 2.

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

use Carp;
sub cplx($) {
   return $_[0] if UNIVERSAL::isa($_[0],'PDL::Complex'); # NOOP if just piddle
   croak "first dimsize must be 2" unless $_[0]->dims > 0 && $_[0]->dim(0) == 2;
   bless $_[0]->slice('');
}

sub complex($) {
   return $_[0] if UNIVERSAL::isa($_[0],'PDL::Complex'); # NOOP if just piddle
   croak "first dimsize must be 2" unless $_[0]->dims > 0 && $_[0]->dim(0) == 2;
   bless $_[0];
}

*PDL::cplx = \&cplx;
*PDL::complex = \&complex;

sub real($) {
   return $_[0] unless UNIVERSAL::isa($_[0],'PDL::Complex'); # NOOP unless complex
   bless $_[0]->slice(''), 'PDL';
}





=head2 r2C

=for sig

  Signature: (r(); [o]c(m=2))

=for ref

convert real to complex, assuming an imaginary part of zero

=for bad

r2C does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut





*PDL::r2C = \&PDL::Complex::r2C;
sub PDL::Complex::r2C($) {
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
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut




*PDL::i2C = \&PDL::Complex::i2C; sub PDL::Complex::i2C($) { my $r = __PACKAGE__->initialize; &PDL::Complex::_i2C_int($_[0], $r); $r }

BEGIN {*i2C = \&PDL::Complex::i2C;
}




=head2 Cr2p

=for sig

  Signature: (r(m=2); float+ [o]p(m=2))

=for ref

convert complex numbers in rectangular form to polar (mod,arg) form. Works inplace

=for bad

Cr2p does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


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
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


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
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


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
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


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
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


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
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






BEGIN {*Cdiv = \&PDL::Complex::Cdiv;
}




=head2 Ccmp

=for sig

  Signature: (a(m=2); b(m=2); [o]c())

=for ref

Complex comparison operator (spaceship).

Ccmp orders by real first, then by imaginary. Hm, but it is mathematical nonsense! Complex numbers cannot be ordered.

=for bad

Ccmp does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






BEGIN {*Ccmp = \&PDL::Complex::Ccmp;
}




=head2 Cconj

=for sig

  Signature: (a(m=2); [o]c(m=2))

=for ref

complex conjugation. Works inplace

=for bad

Cconj does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


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
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


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
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


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
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


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
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


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
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






BEGIN {*Ccos = \&PDL::Complex::Ccos;
}



=head2 Ctan

=for ref

Complex tangent

  tan (a) = -i * (exp (a*i) - exp (-a*i)) / (exp (a*i) + exp (-a*i))

Does not work inplace.

=cut

sub Ctan($) { Csin($_[0]) / Ccos($_[0]) }






=head2 Cexp

=for sig

  Signature: (a(m=2); [o]c(m=2))

=for ref

  exp (a) = exp (real (a)) * (cos (imag (a)) + i * sin (imag (a))). Works inplace

=for bad

Cexp does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


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
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


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
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


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
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


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
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


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
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






BEGIN {*Cacos = \&PDL::Complex::Cacos;
}



=head2 Catan

=for ref

Return the complex C<atan()>.

Does not work inplace.

=cut

sub Catan($) {
   my $z = shift;
   Cmul Clog(Cdiv (PDL::Complex::i+$z, PDL::Complex::i-$z)), pdl(0, 0.5);
}





=head2 Csinh

=for sig

  Signature: (a(m=2); [o]c(m=2))

=for ref

  sinh (a) = (exp (a) - exp (-a)) / 2. Works inplace

=for bad

Csinh does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


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
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


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
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


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
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


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
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


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
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


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
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


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
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut




sub PDL::Complex::Croots($$) {
           my ($pdl, $n) = @_;
           my $r = PDL->null;
           &PDL::Complex::_Croots_int($pdl, $r, $n);
           bless $r;
        }

BEGIN {*Croots = \&PDL::Complex::Croots;
}



=head2 re, im

Return the real or imaginary part of the complex number(s) given.

These are slicing operators, so data flow works. The real and
imaginary parts are returned as piddles (ref eq PDL).

=cut

sub re($) { bless $_[0]->slice("(0)"), 'PDL'; }
sub im($) { bless $_[0]->slice("(1)"), 'PDL'; }

*PDL::Complex::re = \&re;
*PDL::Complex::im = \&im;





=head2 rCpolynomial

=for sig

  Signature: (coeffs(n); x(c=2,m); [o]out(c=2,m))

=for ref

evaluate the polynomial with (real) coefficients C<coeffs> at the (complex) position(s) C<x>. C<coeffs[0]> is the constant term.

=for bad

rCpolynomial does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


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


;


# overload must be here, so that all the functions can be seen

# undocumented compatibility functions (thanks to Luis Mochan!)
sub Catan2($$) { Clog( $_[1] + i*$_[0])/i }
sub atan2($$) { Clog( $_[1] + i*$_[0])/i }


=begin comment

In _gen_biop, the '+' or '-' between the operator (e.g., '*') and the
function that it overloads (e.g., 'Cmul') flags whether the operation
is ('+') or is not ('-') commutative. See the discussion of argument
swapping in the section "Calling Conventions and Magic Autogeneration"
in "perldoc overload".

This is a great example of taking almost as many lines to write cute
generating code as it would take to just clearly and explicitly write
down the overload.

=end comment

=cut

sub _gen_biop {
   local $_ = shift;
   my $sub;
   if (/(\S+)\+(\w+)/) { #commutes
      $sub = eval 'sub { '.$2.' $_[0], ref $_[1] eq __PACKAGE__ ? $_[1] : r2C $_[1] }';
   } elsif (/(\S+)\-(\w+)/) { #does not commute
      $sub = eval 'sub { my $y = ref $_[1] eq __PACKAGE__ ? $_[1] : r2C $_[1];
                       $_[2] ? '.$2.' $y, $_[0] : '.$2.' $_[0], $y }'; #need to swap?
   } else {
      die;
   }
   if($1 eq "atan2" || $1 eq "<=>") { return ($1, $sub) }
   ($1, $sub, "$1=", $sub);
}

sub _gen_unop {
   my ($op, $func) = ($_[0] =~ /(.+)@(\w+)/);
   *$op = \&$func if $op =~ /\w+/; # create an alias
   ($op, eval 'sub { '.$func.' $_[0] }');
}

#sub _gen_cpop {
#   ($_[0], eval 'sub { my $y = ref $_[1] eq __PACKAGE__ ? $_[1] : r2C $_[1];
#                 ($_[2] ? $y <=> $_[0] : $_[0] <=> $y) '.$_[0].' 0 }');
#}

sub initialize {
   # Bless a null PDL into the supplied 1st arg package
   #   If 1st arg is a ref, get the package from it
   bless PDL->null, ref($_[0]) ? ref($_[0]) : $_[0];
}

use overload
   (map _gen_biop($_), qw(++Cadd --Csub *+Cmul /-Cdiv **-Cpow atan2-Catan2 <=>-Ccmp)),
   (map _gen_unop($_), qw(sin@Csin cos@Ccos exp@Cexp abs@Cabs log@Clog sqrt@Csqrt)),
#   (map _gen_cpop($_), qw(< <= == != >= >)), #segfaults with infinite recursion of the operator.
#final ternary used to make result a scalar, not a PDL:::Complex (thx CED!)
    "<" => sub { my $y = ref $_[1] eq __PACKAGE__ ? $_[1] : r2C $_[1];
		 PDL::lt( ($_[2] ? $y <=> $_[0] : $_[0] <=> $y), 0, 0) ? 1 : 0;},
    "<=" => sub { my $y = ref $_[1] eq __PACKAGE__ ? $_[1] : r2C $_[1];
                 PDL::le( ($_[2] ? $y <=> $_[0] : $_[0] <=> $y), 0, 0) ? 1 : 0;},
    "==" => sub { my $y = ref $_[1] eq __PACKAGE__ ? $_[1] : r2C $_[1];
                 PDL::eq( ($_[2] ? $y <=> $_[0] : $_[0] <=> $y), 0, 0) ? 1 : 0;},
    "!=" => sub { my $y = ref $_[1] eq __PACKAGE__ ? $_[1] : r2C $_[1];
                 PDL::ne( ($_[2] ? $y <=> $_[0] : $_[0] <=> $y), 0, 0) ? 1 : 0;},
    ">=" => sub { my $y = ref $_[1] eq __PACKAGE__ ? $_[1] : r2C $_[1];
                 PDL::ge( ($_[2] ? $y <=> $_[0] : $_[0] <=> $y), 0, 0) ? 1 : 0;},
    ">" => sub { my $y = ref $_[1] eq __PACKAGE__ ? $_[1] : r2C $_[1];
                 PDL::gt( ($_[2] ? $y <=> $_[0] : $_[0] <=> $y), 0, 0) ? 1 : 0;},
   '++' => sub { $_[0] += 1 },
   '--' => sub { $_[0] -= 1 },
   '""' => \&PDL::Complex::string
;

# overwrite PDL's overloading to honour subclass methods in + - * /
{ package PDL;
        my $warningFlag;
        # This strange usage of BEGINs is to ensure the
        # warning messages get disabled and enabled in the
        # proper order. Without the BEGIN's the 'use overload'
        #  would be called first.
        BEGIN {$warningFlag = $^W; # Temporarily disable warnings caused by
               $^W = 0;            # redefining PDL's subs
              }


sub cp(;@) {
	my $foo;
	if (ref $_[1]
		&& (ref $_[1] ne 'PDL')
		&& defined ($foo = overload::Method($_[1],'+')))
		{ &$foo($_[1], $_[0], !$_[2])}
	else { PDL::plus (@_)}
}

sub cm(;@) {
	my $foo;
	if (ref $_[1]
		&& (ref $_[1] ne 'PDL')
		&& defined ($foo = overload::Method($_[1],'*')))
		{ &$foo($_[1], $_[0], !$_[2])}
	else { PDL::mult (@_)}
}

sub cmi(;@) {
	my $foo;
	if (ref $_[1]
		&& (ref $_[1] ne 'PDL')
		&& defined ($foo = overload::Method($_[1],'-')))
		{ &$foo($_[1], $_[0], !$_[2])}
	else { PDL::minus (@_)}
}

sub cd(;@) {
	my $foo;
	if (ref $_[1]
		&& (ref $_[1] ne 'PDL')
		&& defined ($foo = overload::Method($_[1],'/')))
		{ &$foo($_[1], $_[0], !$_[2])}
	else { PDL::divide (@_)}
}


  # Used in overriding standard PDL +, -, *, / ops in the complex subclass.
  use overload (
		 '+' => \&cp,
		 '*' => \&cm,
	         '-' => \&cmi,
		 '/' => \&cd,
		);



        BEGIN{ $^W = $warningFlag;} # Put Back Warnings
};


{

   our $floatformat  = "%4.4g";    # Default print format for long numbers
   our $doubleformat = "%6.6g";

   $PDL::Complex::_STRINGIZING = 0;

   sub PDL::Complex::string {
      my($self,$format1,$format2)=@_;
      my @dims = $self->dims;
      return PDL::string($self) if ($dims[0] != 2);

      if($PDL::Complex::_STRINGIZING) {
         return "ALREADY_STRINGIZING_NO_LOOPS";
      }
      local $PDL::Complex::_STRINGIZING = 1;
      my $ndims = $self->getndims;
      if($self->nelem > $PDL::toolongtoprint) {
         return "TOO LONG TO PRINT";
      }
      if ($ndims==0){
         PDL::Core::string($self,$format1);
      }
      return "Null" if $self->isnull;
      return "Empty" if $self->isempty; # Empty piddle
      local $sep  = $PDL::use_commas ? ", " : "  ";
      local $sep2 = $PDL::use_commas ? ", " : "";
      if ($ndims < 3) {
         return str1D($self,$format1,$format2);
      }
      else{
         return strND($self,$format1,$format2,0);
      }
   }


   sub sum {
      my($x) = @_;
      return $x if $x->dims==1;
      my $tmp = $x->mv(0,-1)->clump(-2)->mv(1,0)->sumover;
      return $tmp;
   }

   sub sumover{
      my $m = shift;
      PDL::Ufunc::sumover($m->xchg(0,1));
   }

   *PDL::Complex::Csumover=\&sumover; # define through alias

   *PDL::Complex::prodover=\&Cprodover; # define through alias

   sub prod {
      my($x) = @_;
      return $x if $x->dims==1;
      my $tmp = $x->mv(0,-1)->clump(-2)->mv(1,0)->prodover;
      return $tmp;
   }



   sub strND {
      my($self,$format1,$format2,$level)=@_;
      my @dims = $self->dims;

      if ($#dims==2) {
         return str2D($self,$format1,$format2,$level);
      }
      else {
         my $secbas = join '',map {":,"} @dims[0..$#dims-1];
         my $ret="\n"." "x$level ."["; my $j;
         for ($j=0; $j<$dims[$#dims]; $j++) {
            my $sec = $secbas . "($j)";

            $ret .= strND($self->slice($sec),$format1,$format2, $level+1);
            chop $ret; $ret .= $sep2;
         }
         chop $ret if $PDL::use_commas;
         $ret .= "\n" ." "x$level ."]\n";
         return $ret;
      }
   }


   # String 1D array in nice format
   #
   sub str1D {
      my($self,$format1,$format2)=@_;
      barf "Not 1D" if $self->getndims() > 2;
      my $x = PDL::Core::listref_c($self);
      my ($ret,$dformat,$t, $i);

      my $dtype = $self->get_datatype();
      $dformat = $PDL::Complex::floatformat  if $dtype == $PDL_F;
      $dformat = $PDL::Complex::doubleformat if $dtype == $PDL_D;

      $ret = "[" if $self->getndims() > 1;
      my $badflag = $self->badflag();
      for($i=0; $i<=$#$x; $i++){
         $t = $$x[$i];
         if ( $badflag and $t eq "BAD" ) {
            # do nothing
         } elsif ($format1) {
            $t =  sprintf $format1,$t;
         } else{ # Default
            if ($dformat && length($t)>7) { # Try smaller
               $t = sprintf $dformat,$t;
            }
         }
         $ret .= $i % 2 ?
         $i<$#$x ? $t."i$sep" : $t."i"
         : substr($$x[$i+1],0,1) eq "-" ?  "$t " : $t." +";
      }
      $ret.="]" if $self->getndims() > 1;
      return $ret;
   }


   sub str2D {
      my($self,$format1,$format2,$level)=@_;
      my @dims = $self->dims();
      barf "Not 2D" if scalar(@dims)!=3;
      my $x = PDL::Core::listref_c($self);
      my ($i, $f, $t, $len1, $len2, $ret);

      my $dtype = $self->get_datatype();
      my $badflag = $self->badflag();

      my $findmax = 0;

      if (!defined $format1 || !defined $format2 ||
         $format1 eq '' || $format2 eq '') {
         $len1= $len2 = 0;

         if ( $badflag ) {
            for ($i=0; $i<=$#$x; $i++) {
               if ( $$x[$i] eq "BAD" ) {
                  $f = 3;
               }
               else {
                  $f = length($$x[$i]);
               }
               if ($i % 2) {
                  $len2 = $f if $f > $len2;
               }
               else {
                  $len1 = $f if $f > $len1;
               }
            }
         } else {
            for ($i=0; $i<=$#$x; $i++) {
               $f = length($$x[$i]);
               if ($i % 2){
                  $len2 = $f if $f > $len2;
               }
               else{
                  $len1 = $f if $f > $len1;
               }
            }
         }

         $format1 = '%'.$len1.'s';
         $format2 = '%'.$len2.'s';

         if ($len1 > 5){
            if ($dtype == $PDL_F) {
               $format1 = $PDL::Complex::floatformat;
               $findmax = 1;
            } elsif ($dtype == $PDL_D) {
               $format1 = $PDL::Complex::doubleformat;
               $findmax = 1;
            } else {
               $findmax = 0;
            }
         }
         if($len2 > 5){
            if ($dtype == $PDL_F) {
               $format2 = $PDL::Complex::floatformat;
               $findmax = 1;
            } elsif ($dtype == $PDL_D) {
               $format2 = $PDL::Complex::doubleformat;
               $findmax = 1;
            } else {
               $findmax = 0 unless $findmax;
            }
         }
      }

      if($findmax) {
         $len1 = $len2=0;

         if ( $badflag ) {
            for($i=0; $i<=$#$x; $i++){
               $findmax = $i % 2;
               if ( $$x[$i] eq 'BAD' ){
                  $f = 3;
               }
               else{
                  $f = $findmax ? length(sprintf $format2,$$x[$i]) :
                  length(sprintf $format1,$$x[$i]);
               }
               if ($findmax){
                  $len2 = $f if $f > $len2;
               }
               else{
                  $len1 = $f if $f > $len1;
               }
            }
         } else {
            for ($i=0; $i<=$#$x; $i++) {
               if ($i % 2){
                  $f = length(sprintf $format2,$$x[$i]);
                  $len2 = $f if $f > $len2;
               }
               else{
                  $f = length(sprintf $format1,$$x[$i]);
                  $len1 = $f if $f > $len1;
               }
            }
         }


      } # if: $findmax

      $ret = "\n" . ' 'x$level . "[\n";
      {
         my $level = $level+1;
         $ret .= ' 'x$level .'[';
         $len2 += 2;

         for ($i=0; $i<=$#$x; $i++) {
            $findmax = $i % 2;
            if ($findmax){
               if ( $badflag and  $$x[$i] eq 'BAD' ){
                  #||
                  #($findmax && $$x[$i - 1 ] eq 'BAD') ||
                  #(!$findmax && $$x[$i +1 ] eq 'BAD')){
                  $f = "BAD";
               }
               else{
                  $f = sprintf $format2, $$x[$i];
                  if (substr($$x[$i],0,1) eq '-'){
                     $f.='i';
                  }
                  else{
                     $f =~ s/(\s*)(.*)/+$2i/;
                  }
               }
               $t = $len2-length($f);
            }
            else{
               if ( $badflag and  $$x[$i] eq 'BAD' ){
                  $f = "BAD";
               }
               else{
                  $f = sprintf $format1, $$x[$i];
                  $t =  $len1-length($f);
               }
            }

            $f = ' 'x$t.$f if $t>0;

            $ret .= $f;
            if (($i+1)%($dims[1]*2)) {
               $ret.=$sep if $findmax;
            }
            else{ # End of output line
               $ret.=']';
               if ($i==$#$x) { # very last number
                  $ret.="\n";
               }
               else{
                  $ret.= $sep2."\n" . ' 'x$level .'[';
               }
            }
         }
      }
      $ret .= ' 'x$level."]\n";
      return $ret;
   }

}

=head1 AUTHOR

Copyright (C) 2000 Marc Lehmann <pcg@goof.com>.
All rights reserved. There is no warranty. You are allowed
to redistribute this software / documentation as described
in the file COPYING in the PDL distribution.

=head1 SEE ALSO

perl(1), L<PDL>.

=cut






# Exit with OK status

1;

		   
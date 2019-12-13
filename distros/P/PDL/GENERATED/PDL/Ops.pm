
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::Ops;

@EXPORT_OK  = qw(  PDL::PP log10 PDL::PP assgn PDL::PP ipow );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Ops ;





=head1 NAME

PDL::Ops - Fundamental mathematical operators

=head1 DESCRIPTION

This module provides the functions used by PDL to
overload the basic mathematical operators (C<+ - / *>
etc.) and functions (C<sin sqrt> etc.)

It also includes the function C<log10>, which should
be a perl function so that we can overload it!

Matrix multiplication (the operator C<x>) is handled
by the module L<PDL::Primitive|PDL::Primitive>.

=head1 SYNOPSIS

none

=cut







=head1 FUNCTIONS



=cut






=head2 plus

=for sig

  Signature: (a(); b(); [o]c(); int swap)

=for ref

add two piddles

=for example

   $c = plus $x, $y, 0;     # explicit call with trailing 0
   $c = $x + $y;           # overloaded call
   $x->inplace->plus($y,0);  # modify $x inplace

It can be made to work inplace with the C<$x-E<gt>inplace> syntax.
This function is used to overload the binary C<+> operator.
Note that when calling this function explicitly you need to supply
a third argument that should generally be zero (see first example).
This restriction is expected to go away in future releases.



=for bad

plus processes bad values.
The state of the bad-value flag of the output piddles is unknown.


=cut






*plus = \&PDL::plus;





=head2 mult

=for sig

  Signature: (a(); b(); [o]c(); int swap)

=for ref

multiply two piddles

=for example

   $c = mult $x, $y, 0;     # explicit call with trailing 0
   $c = $x * $y;           # overloaded call
   $x->inplace->mult($y,0);  # modify $x inplace

It can be made to work inplace with the C<$x-E<gt>inplace> syntax.
This function is used to overload the binary C<*> operator.
Note that when calling this function explicitly you need to supply
a third argument that should generally be zero (see first example).
This restriction is expected to go away in future releases.



=for bad

mult processes bad values.
The state of the bad-value flag of the output piddles is unknown.


=cut






*mult = \&PDL::mult;





=head2 minus

=for sig

  Signature: (a(); b(); [o]c(); int swap)

=for ref

subtract two piddles

=for example

   $c = minus $x, $y, 0;     # explicit call with trailing 0
   $c = $x - $y;           # overloaded call
   $x->inplace->minus($y,0);  # modify $x inplace

It can be made to work inplace with the C<$x-E<gt>inplace> syntax.
This function is used to overload the binary C<-> operator.
Note that when calling this function explicitly you need to supply
a third argument that should generally be zero (see first example).
This restriction is expected to go away in future releases.



=for bad

minus processes bad values.
The state of the bad-value flag of the output piddles is unknown.


=cut






*minus = \&PDL::minus;





=head2 divide

=for sig

  Signature: (a(); b(); [o]c(); int swap)

=for ref

divide two piddles

=for example

   $c = divide $x, $y, 0;     # explicit call with trailing 0
   $c = $x / $y;           # overloaded call
   $x->inplace->divide($y,0);  # modify $x inplace

It can be made to work inplace with the C<$x-E<gt>inplace> syntax.
This function is used to overload the binary C</> operator.
Note that when calling this function explicitly you need to supply
a third argument that should generally be zero (see first example).
This restriction is expected to go away in future releases.



=for bad

divide processes bad values.
The state of the bad-value flag of the output piddles is unknown.


=cut






*divide = \&PDL::divide;





=head2 gt

=for sig

  Signature: (a(); b(); [o]c(); int swap)

=for ref

the binary E<gt> (greater than) operation

=for example

   $c = gt $x, $y, 0;     # explicit call with trailing 0
   $c = $x > $y;           # overloaded call
   $x->inplace->gt($y,0);  # modify $x inplace

It can be made to work inplace with the C<$x-E<gt>inplace> syntax.
This function is used to overload the binary C<E<gt>> operator.
Note that when calling this function explicitly you need to supply
a third argument that should generally be zero (see first example).
This restriction is expected to go away in future releases.



=for bad

gt processes bad values.
The state of the bad-value flag of the output piddles is unknown.


=cut






*gt = \&PDL::gt;





=head2 lt

=for sig

  Signature: (a(); b(); [o]c(); int swap)

=for ref

the binary E<lt> (less than) operation

=for example

   $c = lt $x, $y, 0;     # explicit call with trailing 0
   $c = $x < $y;           # overloaded call
   $x->inplace->lt($y,0);  # modify $x inplace

It can be made to work inplace with the C<$x-E<gt>inplace> syntax.
This function is used to overload the binary C<E<lt>> operator.
Note that when calling this function explicitly you need to supply
a third argument that should generally be zero (see first example).
This restriction is expected to go away in future releases.



=for bad

lt processes bad values.
The state of the bad-value flag of the output piddles is unknown.


=cut






*lt = \&PDL::lt;





=head2 le

=for sig

  Signature: (a(); b(); [o]c(); int swap)

=for ref

the binary E<lt>= (less equal) operation

=for example

   $c = le $x, $y, 0;     # explicit call with trailing 0
   $c = $x <= $y;           # overloaded call
   $x->inplace->le($y,0);  # modify $x inplace

It can be made to work inplace with the C<$x-E<gt>inplace> syntax.
This function is used to overload the binary C<E<lt>=> operator.
Note that when calling this function explicitly you need to supply
a third argument that should generally be zero (see first example).
This restriction is expected to go away in future releases.



=for bad

le processes bad values.
The state of the bad-value flag of the output piddles is unknown.


=cut






*le = \&PDL::le;





=head2 ge

=for sig

  Signature: (a(); b(); [o]c(); int swap)

=for ref

the binary E<gt>= (greater equal) operation

=for example

   $c = ge $x, $y, 0;     # explicit call with trailing 0
   $c = $x >= $y;           # overloaded call
   $x->inplace->ge($y,0);  # modify $x inplace

It can be made to work inplace with the C<$x-E<gt>inplace> syntax.
This function is used to overload the binary C<E<gt>=> operator.
Note that when calling this function explicitly you need to supply
a third argument that should generally be zero (see first example).
This restriction is expected to go away in future releases.



=for bad

ge processes bad values.
The state of the bad-value flag of the output piddles is unknown.


=cut






*ge = \&PDL::ge;





=head2 eq

=for sig

  Signature: (a(); b(); [o]c(); int swap)

=for ref

binary I<equal to> operation (C<==>)

=for example

   $c = eq $x, $y, 0;     # explicit call with trailing 0
   $c = $x == $y;           # overloaded call
   $x->inplace->eq($y,0);  # modify $x inplace

It can be made to work inplace with the C<$x-E<gt>inplace> syntax.
This function is used to overload the binary C<==> operator.
Note that when calling this function explicitly you need to supply
a third argument that should generally be zero (see first example).
This restriction is expected to go away in future releases.



=for bad

eq processes bad values.
The state of the bad-value flag of the output piddles is unknown.


=cut






*eq = \&PDL::eq;





=head2 ne

=for sig

  Signature: (a(); b(); [o]c(); int swap)

=for ref

binary I<not equal to> operation (C<!=>)

=for example

   $c = ne $x, $y, 0;     # explicit call with trailing 0
   $c = $x != $y;           # overloaded call
   $x->inplace->ne($y,0);  # modify $x inplace

It can be made to work inplace with the C<$x-E<gt>inplace> syntax.
This function is used to overload the binary C<!=> operator.
Note that when calling this function explicitly you need to supply
a third argument that should generally be zero (see first example).
This restriction is expected to go away in future releases.



=for bad

ne processes bad values.
The state of the bad-value flag of the output piddles is unknown.


=cut






*ne = \&PDL::ne;





=head2 shiftleft

=for sig

  Signature: (a(); b(); [o]c(); int swap)

=for ref

leftshift C<$a> by C<$b>

=for example

   $c = shiftleft $x, $y, 0;     # explicit call with trailing 0
   $c = $x << $y;           # overloaded call
   $x->inplace->shiftleft($y,0);  # modify $x inplace

It can be made to work inplace with the C<$x-E<gt>inplace> syntax.
This function is used to overload the binary C<E<lt>E<lt>> operator.
Note that when calling this function explicitly you need to supply
a third argument that should generally be zero (see first example).
This restriction is expected to go away in future releases.



=for bad

shiftleft processes bad values.
The state of the bad-value flag of the output piddles is unknown.


=cut






*shiftleft = \&PDL::shiftleft;





=head2 shiftright

=for sig

  Signature: (a(); b(); [o]c(); int swap)

=for ref

rightshift C<$a> by C<$b>

=for example

   $c = shiftright $x, $y, 0;     # explicit call with trailing 0
   $c = $x >> $y;           # overloaded call
   $x->inplace->shiftright($y,0);  # modify $x inplace

It can be made to work inplace with the C<$x-E<gt>inplace> syntax.
This function is used to overload the binary C<E<gt>E<gt>> operator.
Note that when calling this function explicitly you need to supply
a third argument that should generally be zero (see first example).
This restriction is expected to go away in future releases.



=for bad

shiftright processes bad values.
The state of the bad-value flag of the output piddles is unknown.


=cut






*shiftright = \&PDL::shiftright;





=head2 or2

=for sig

  Signature: (a(); b(); [o]c(); int swap)

=for ref

binary I<or> of two piddles

=for example

   $c = or2 $x, $y, 0;     # explicit call with trailing 0
   $c = $x | $y;           # overloaded call
   $x->inplace->or2($y,0);  # modify $x inplace

It can be made to work inplace with the C<$x-E<gt>inplace> syntax.
This function is used to overload the binary C<|> operator.
Note that when calling this function explicitly you need to supply
a third argument that should generally be zero (see first example).
This restriction is expected to go away in future releases.



=for bad

or2 processes bad values.
The state of the bad-value flag of the output piddles is unknown.


=cut






*or2 = \&PDL::or2;





=head2 and2

=for sig

  Signature: (a(); b(); [o]c(); int swap)

=for ref

binary I<and> of two piddles

=for example

   $c = and2 $x, $y, 0;     # explicit call with trailing 0
   $c = $x & $y;           # overloaded call
   $x->inplace->and2($y,0);  # modify $x inplace

It can be made to work inplace with the C<$x-E<gt>inplace> syntax.
This function is used to overload the binary C<&> operator.
Note that when calling this function explicitly you need to supply
a third argument that should generally be zero (see first example).
This restriction is expected to go away in future releases.



=for bad

and2 processes bad values.
The state of the bad-value flag of the output piddles is unknown.


=cut






*and2 = \&PDL::and2;





=head2 xor

=for sig

  Signature: (a(); b(); [o]c(); int swap)

=for ref

binary I<exclusive or> of two piddles

=for example

   $c = xor $x, $y, 0;     # explicit call with trailing 0
   $c = $x ^ $y;           # overloaded call
   $x->inplace->xor($y,0);  # modify $x inplace

It can be made to work inplace with the C<$x-E<gt>inplace> syntax.
This function is used to overload the binary C<^> operator.
Note that when calling this function explicitly you need to supply
a third argument that should generally be zero (see first example).
This restriction is expected to go away in future releases.



=for bad

xor processes bad values.
The state of the bad-value flag of the output piddles is unknown.


=cut






*xor = \&PDL::xor;





=head2 bitnot

=for sig

  Signature: (a(); [o]b())

=for ref

unary bit negation

=for example

   $y = ~ $x;
   $x->inplace->bitnot;  # modify $x inplace

It can be made to work inplace with the C<$x-E<gt>inplace> syntax.
This function is used to overload the unary C<~> operator/function.



=for bad

bitnot processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*bitnot = \&PDL::bitnot;





=head2 power

=for sig

  Signature: (a(); b(); [o]c(); int swap)

=for ref

raise piddle C<$a> to the power C<$b>

=for example

   $c = $x->power($y,0); # explicit function call
   $c = $a ** $b;    # overloaded use
   $x->inplace->power($y,0);     # modify $x inplace

It can be made to work inplace with the C<$x-E<gt>inplace> syntax.
This function is used to overload the binary C<**> function.
Note that when calling this function explicitly you need to supply
a third argument that should generally be zero (see first example).
This restriction is expected to go away in future releases.



=for bad

power processes bad values.
The state of the bad-value flag of the output piddles is unknown.


=cut






*power = \&PDL::power;





=head2 atan2

=for sig

  Signature: (a(); b(); [o]c(); int swap)

=for ref

elementwise C<atan2> of two piddles

=for example

   $c = $x->atan2($y,0); # explicit function call
   $c = atan2 $a, $b;    # overloaded use
   $x->inplace->atan2($y,0);     # modify $x inplace

It can be made to work inplace with the C<$x-E<gt>inplace> syntax.
This function is used to overload the binary C<atan2> function.
Note that when calling this function explicitly you need to supply
a third argument that should generally be zero (see first example).
This restriction is expected to go away in future releases.



=for bad

atan2 processes bad values.
The state of the bad-value flag of the output piddles is unknown.


=cut






*atan2 = \&PDL::atan2;





=head2 modulo

=for sig

  Signature: (a(); b(); [o]c(); int swap)

=for ref

elementwise C<modulo> operation

=for example

   $c = $x->modulo($y,0); # explicit function call
   $c = $a % $b;    # overloaded use
   $x->inplace->modulo($y,0);     # modify $x inplace

It can be made to work inplace with the C<$x-E<gt>inplace> syntax.
This function is used to overload the binary C<%> function.
Note that when calling this function explicitly you need to supply
a third argument that should generally be zero (see first example).
This restriction is expected to go away in future releases.



=for bad

modulo processes bad values.
The state of the bad-value flag of the output piddles is unknown.


=cut






*modulo = \&PDL::modulo;





=head2 spaceship

=for sig

  Signature: (a(); b(); [o]c(); int swap)

=for ref

elementwise "<=>" operation

=for example

   $c = $x->spaceship($y,0); # explicit function call
   $c = $a <=> $b;    # overloaded use
   $x->inplace->spaceship($y,0);     # modify $x inplace

It can be made to work inplace with the C<$x-E<gt>inplace> syntax.
This function is used to overload the binary C<E<lt>=E<gt>> function.
Note that when calling this function explicitly you need to supply
a third argument that should generally be zero (see first example).
This restriction is expected to go away in future releases.



=for bad

spaceship processes bad values.
The state of the bad-value flag of the output piddles is unknown.


=cut






*spaceship = \&PDL::spaceship;





=head2 sqrt

=for sig

  Signature: (a(); [o]b())

=for ref

elementwise square root

=for example

   $y = sqrt $x;
   $x->inplace->sqrt;  # modify $x inplace

It can be made to work inplace with the C<$x-E<gt>inplace> syntax.
This function is used to overload the unary C<sqrt> operator/function.



=for bad

sqrt processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*sqrt = \&PDL::sqrt;





=head2 abs

=for sig

  Signature: (a(); [o]b())

=for ref

elementwise absolute value

=for example

   $y = abs $x;
   $x->inplace->abs;  # modify $x inplace

It can be made to work inplace with the C<$x-E<gt>inplace> syntax.
This function is used to overload the unary C<abs> operator/function.



=for bad

abs processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*abs = \&PDL::abs;





=head2 sin

=for sig

  Signature: (a(); [o]b())

=for ref

the sin function

=for example

   $y = sin $x;
   $x->inplace->sin;  # modify $x inplace

It can be made to work inplace with the C<$x-E<gt>inplace> syntax.
This function is used to overload the unary C<sin> operator/function.



=for bad

sin processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*sin = \&PDL::sin;





=head2 cos

=for sig

  Signature: (a(); [o]b())

=for ref

the cos function

=for example

   $y = cos $x;
   $x->inplace->cos;  # modify $x inplace

It can be made to work inplace with the C<$x-E<gt>inplace> syntax.
This function is used to overload the unary C<cos> operator/function.



=for bad

cos processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cos = \&PDL::cos;





=head2 not

=for sig

  Signature: (a(); [o]b())

=for ref

the elementwise I<not> operation

=for example

   $y = ! $x;
   $x->inplace->not;  # modify $x inplace

It can be made to work inplace with the C<$x-E<gt>inplace> syntax.
This function is used to overload the unary C<!> operator/function.



=for bad

not processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*not = \&PDL::not;





=head2 exp

=for sig

  Signature: (a(); [o]b())

=for ref

the exponential function

=for example

   $y = exp $x;
   $x->inplace->exp;  # modify $x inplace

It can be made to work inplace with the C<$x-E<gt>inplace> syntax.
This function is used to overload the unary C<exp> operator/function.



=for bad

exp processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*exp = \&PDL::exp;





=head2 log

=for sig

  Signature: (a(); [o]b())

=for ref

the natural logarithm

=for example

   $y = log $x;
   $x->inplace->log;  # modify $x inplace

It can be made to work inplace with the C<$x-E<gt>inplace> syntax.
This function is used to overload the unary C<log> operator/function.



=for bad

log processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*log = \&PDL::log;





=head2 log10

=for sig

  Signature: (a(); [o]b())

=for ref

the base 10 logarithm

=for example

   $y = log10 $x;
   $x->inplace->log10;  # modify $x inplace

It can be made to work inplace with the C<$x-E<gt>inplace> syntax.
This function is used to overload the unary C<log10> operator/function.



=for bad

log10 processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut





sub PDL::log10 {
    my $x = shift;
    if ( ! UNIVERSAL::isa($x,"PDL") ) { return log($x) / log(10); }
    my $y;
    if ( $x->is_inplace ) { $x->set_inplace(0); $y = $x; }
    elsif( ref($x) eq "PDL"){
    	#PDL Objects, use nullcreate:
	$y = PDL->nullcreate($x);
    }else{
    	#PDL-Derived Object, use copy: (Consistent with
	#  Auto-creation docs in Objects.pod)
	$y = $x->copy;
    }
    &PDL::_log10_int( $x, $y );
    return $y;
};


*log10 = \&PDL::log10;





=head2 assgn

=for sig

  Signature: (a(); [o]b())

=for ref

Plain numerical assignment. This is used to implement the ".=" operator

=for bad

If C<a> is a child piddle (e.g., the result of a slice) and bad values are generated in C<b>,
the bad value flag is set in C<b>, but it is B<NOT> automatically propagated back to the parent of C<a>.
The following idiom ensures that the badflag is propagated back to the parent of C<a>:

 $pdl->slice(":,(1)") .= PDL::Bad_aware_func();
 $pdl->badflag(1);
 $pdl->check_badflag();

This is unnecessary if $pdl->badflag is known to be 1 before the slice is performed.

See http://pdl.perl.org/PDLdocs/BadValues.html#dataflow_of_the_badflag for details.

=cut






*assgn = \&PDL::assgn;





=head2 ipow

=for sig

  Signature: (a(); b(); [o] ans())


=for ref

raise piddle C<$a> to integer power C<$b>

=for example

   $c = $x->ipow($y,0);     # explicit function call
   $c = ipow $x, $y;
   $x->inplace->ipow($y,0);  # modify $x inplace

It can be made to work inplace with the C<$x-E<gt>inplace> syntax.
Note that when calling this function explicitly you need to supply
a third argument that should generally be zero (see first example).
This restriction is expected to go away in future releases.

Algorithm from L<Wikipedia|http://en.wikipedia.org/wiki/Exponentiation_by_squaring>



=for bad

ipow does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ipow = \&PDL::ipow;



;


=head1 AUTHOR

Tuomas J. Lukka (lukka@fas.harvard.edu),
Karl Glazebrook (kgb@aaoepp.aao.gov.au),
Doug Hunt (dhunt@ucar.edu),
Christian Soeller (c.soeller@auckland.ac.nz),
Doug Burke (burke@ifa.hawaii.edu),
and Craig DeForest (deforest@boulder.swri.edu).

=cut





# Exit with OK status

1;

		   
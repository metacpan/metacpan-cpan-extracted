
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::Ops;

our @EXPORT_OK = qw( PDL::PP log10 PDL::PP assgn PDL::PP carg PDL::PP conj PDL::PP czip PDL::PP ipow PDL::PP r2C PDL::PP i2C );
our %EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Ops ;





use strict;
use warnings;

my %OVERLOADS;

=head1 NAME

PDL::Ops - Fundamental mathematical operators

=head1 DESCRIPTION

This module provides the functions used by PDL to
overload the basic mathematical operators (C<+ - / *>
etc.) and functions (C<sin sqrt> etc.)

It also includes the function C<log10>, which should
be a perl function so that we can overload it!

Matrix multiplication (the operator C<x>) is handled
by the module L<PDL::Primitive>.

=head1 SYNOPSIS

none

=cut







=head1 FUNCTIONS



=cut




{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'+'} = $overload_sub = sub(;@) {
      return PDL::plus(@_) unless ref $_[1]
              && (ref $_[1] ne 'PDL')
              && defined($foo = overload::Method($_[1], '+'))
              && $foo != $overload_sub; # recursion guard
      $foo->($_[1], $_[0], !$_[2]);
  }; }
}
BEGIN {
# in1, in2, out, swap if true
$OVERLOADS{'+='} = sub { PDL::plus($_[0], $_[1], $_[0], 0); $_[0] };
}




=head2 plus

=for sig

  Signature: (a(); b(); [o]c(); int swap)

=for ref

add two ndarrays

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
The state of the bad-value flag of the output ndarrays is unknown.


=cut






*plus = \&PDL::plus;



{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'*'} = $overload_sub = sub(;@) {
      return PDL::mult(@_) unless ref $_[1]
              && (ref $_[1] ne 'PDL')
              && defined($foo = overload::Method($_[1], '*'))
              && $foo != $overload_sub; # recursion guard
      $foo->($_[1], $_[0], !$_[2]);
  }; }
}
BEGIN {
# in1, in2, out, swap if true
$OVERLOADS{'*='} = sub { PDL::mult($_[0], $_[1], $_[0], 0); $_[0] };
}




=head2 mult

=for sig

  Signature: (a(); b(); [o]c(); int swap)

=for ref

multiply two ndarrays

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
The state of the bad-value flag of the output ndarrays is unknown.


=cut






*mult = \&PDL::mult;



{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'-'} = $overload_sub = sub(;@) {
      return PDL::minus(@_) unless ref $_[1]
              && (ref $_[1] ne 'PDL')
              && defined($foo = overload::Method($_[1], '-'))
              && $foo != $overload_sub; # recursion guard
      $foo->($_[1], $_[0], !$_[2]);
  }; }
}
BEGIN {
# in1, in2, out, swap if true
$OVERLOADS{'-='} = sub { PDL::minus($_[0], $_[1], $_[0], 0); $_[0] };
}




=head2 minus

=for sig

  Signature: (a(); b(); [o]c(); int swap)

=for ref

subtract two ndarrays

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
The state of the bad-value flag of the output ndarrays is unknown.


=cut






*minus = \&PDL::minus;



{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'/'} = $overload_sub = sub(;@) {
      return PDL::divide(@_) unless ref $_[1]
              && (ref $_[1] ne 'PDL')
              && defined($foo = overload::Method($_[1], '/'))
              && $foo != $overload_sub; # recursion guard
      $foo->($_[1], $_[0], !$_[2]);
  }; }
}
BEGIN {
# in1, in2, out, swap if true
$OVERLOADS{'/='} = sub { PDL::divide($_[0], $_[1], $_[0], 0); $_[0] };
}




=head2 divide

=for sig

  Signature: (a(); b(); [o]c(); int swap)

=for ref

divide two ndarrays

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
The state of the bad-value flag of the output ndarrays is unknown.


=cut






*divide = \&PDL::divide;



{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'>'} = $overload_sub = sub(;@) {
      return PDL::gt(@_) unless ref $_[1]
              && (ref $_[1] ne 'PDL')
              && defined($foo = overload::Method($_[1], '>'))
              && $foo != $overload_sub; # recursion guard
      $foo->($_[1], $_[0], !$_[2]);
  }; }
}




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
The state of the bad-value flag of the output ndarrays is unknown.


=cut






*gt = \&PDL::gt;



{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'<'} = $overload_sub = sub(;@) {
      return PDL::lt(@_) unless ref $_[1]
              && (ref $_[1] ne 'PDL')
              && defined($foo = overload::Method($_[1], '<'))
              && $foo != $overload_sub; # recursion guard
      $foo->($_[1], $_[0], !$_[2]);
  }; }
}




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
The state of the bad-value flag of the output ndarrays is unknown.


=cut






*lt = \&PDL::lt;



{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'<='} = $overload_sub = sub(;@) {
      return PDL::le(@_) unless ref $_[1]
              && (ref $_[1] ne 'PDL')
              && defined($foo = overload::Method($_[1], '<='))
              && $foo != $overload_sub; # recursion guard
      $foo->($_[1], $_[0], !$_[2]);
  }; }
}




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
The state of the bad-value flag of the output ndarrays is unknown.


=cut






*le = \&PDL::le;



{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'>='} = $overload_sub = sub(;@) {
      return PDL::ge(@_) unless ref $_[1]
              && (ref $_[1] ne 'PDL')
              && defined($foo = overload::Method($_[1], '>='))
              && $foo != $overload_sub; # recursion guard
      $foo->($_[1], $_[0], !$_[2]);
  }; }
}




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
The state of the bad-value flag of the output ndarrays is unknown.


=cut






*ge = \&PDL::ge;



{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'=='} = $overload_sub = sub(;@) {
      return PDL::eq(@_) unless ref $_[1]
              && (ref $_[1] ne 'PDL')
              && defined($foo = overload::Method($_[1], '=='))
              && $foo != $overload_sub; # recursion guard
      $foo->($_[1], $_[0], !$_[2]);
  }; }
}




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
The state of the bad-value flag of the output ndarrays is unknown.


=cut






*eq = \&PDL::eq;



{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'!='} = $overload_sub = sub(;@) {
      return PDL::ne(@_) unless ref $_[1]
              && (ref $_[1] ne 'PDL')
              && defined($foo = overload::Method($_[1], '!='))
              && $foo != $overload_sub; # recursion guard
      $foo->($_[1], $_[0], !$_[2]);
  }; }
}




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
The state of the bad-value flag of the output ndarrays is unknown.


=cut






*ne = \&PDL::ne;



{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'<<'} = $overload_sub = sub(;@) {
      return PDL::shiftleft(@_) unless ref $_[1]
              && (ref $_[1] ne 'PDL')
              && defined($foo = overload::Method($_[1], '<<'))
              && $foo != $overload_sub; # recursion guard
      $foo->($_[1], $_[0], !$_[2]);
  }; }
}
BEGIN {
# in1, in2, out, swap if true
$OVERLOADS{'<<='} = sub { PDL::shiftleft($_[0], $_[1], $_[0], 0); $_[0] };
}




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
The state of the bad-value flag of the output ndarrays is unknown.


=cut






*shiftleft = \&PDL::shiftleft;



{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'>>'} = $overload_sub = sub(;@) {
      return PDL::shiftright(@_) unless ref $_[1]
              && (ref $_[1] ne 'PDL')
              && defined($foo = overload::Method($_[1], '>>'))
              && $foo != $overload_sub; # recursion guard
      $foo->($_[1], $_[0], !$_[2]);
  }; }
}
BEGIN {
# in1, in2, out, swap if true
$OVERLOADS{'>>='} = sub { PDL::shiftright($_[0], $_[1], $_[0], 0); $_[0] };
}




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
The state of the bad-value flag of the output ndarrays is unknown.


=cut






*shiftright = \&PDL::shiftright;



{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'|'} = $overload_sub = sub(;@) {
      return PDL::or2(@_) unless ref $_[1]
              && (ref $_[1] ne 'PDL')
              && defined($foo = overload::Method($_[1], '|'))
              && $foo != $overload_sub; # recursion guard
      $foo->($_[1], $_[0], !$_[2]);
  }; }
}
BEGIN {
# in1, in2, out, swap if true
$OVERLOADS{'|='} = sub { PDL::or2($_[0], $_[1], $_[0], 0); $_[0] };
}




=head2 or2

=for sig

  Signature: (a(); b(); [o]c(); int swap)

=for ref

binary I<or> of two ndarrays

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
The state of the bad-value flag of the output ndarrays is unknown.


=cut






*or2 = \&PDL::or2;



{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'&'} = $overload_sub = sub(;@) {
      return PDL::and2(@_) unless ref $_[1]
              && (ref $_[1] ne 'PDL')
              && defined($foo = overload::Method($_[1], '&'))
              && $foo != $overload_sub; # recursion guard
      $foo->($_[1], $_[0], !$_[2]);
  }; }
}
BEGIN {
# in1, in2, out, swap if true
$OVERLOADS{'&='} = sub { PDL::and2($_[0], $_[1], $_[0], 0); $_[0] };
}




=head2 and2

=for sig

  Signature: (a(); b(); [o]c(); int swap)

=for ref

binary I<and> of two ndarrays

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
The state of the bad-value flag of the output ndarrays is unknown.


=cut






*and2 = \&PDL::and2;



{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'^'} = $overload_sub = sub(;@) {
      return PDL::xor(@_) unless ref $_[1]
              && (ref $_[1] ne 'PDL')
              && defined($foo = overload::Method($_[1], '^'))
              && $foo != $overload_sub; # recursion guard
      $foo->($_[1], $_[0], !$_[2]);
  }; }
}
BEGIN {
# in1, in2, out, swap if true
$OVERLOADS{'^='} = sub { PDL::xor($_[0], $_[1], $_[0], 0); $_[0] };
}




=head2 xor

=for sig

  Signature: (a(); b(); [o]c(); int swap)

=for ref

binary I<exclusive or> of two ndarrays

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
The state of the bad-value flag of the output ndarrays is unknown.


=cut






*xor = \&PDL::xor;



BEGIN { $OVERLOADS{'~'} = sub { PDL::bitnot($_[0]) } }




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
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut






*bitnot = \&PDL::bitnot;



{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'**'} = $overload_sub = sub(;@) {
      return PDL::power(@_) unless ref $_[1]
              && (ref $_[1] ne 'PDL')
              && defined($foo = overload::Method($_[1], '**'))
              && $foo != $overload_sub; # recursion guard
      $foo->($_[1], $_[0], !$_[2]);
  }; }
}
BEGIN {
# in1, in2, out, swap if true
$OVERLOADS{'**='} = sub { PDL::power($_[0], $_[1], $_[0], 0); $_[0] };
}




=head2 power

=for sig

  Signature: (a(); b(); [o]c(); int swap)

=for ref

raise ndarray C<$a> to the power C<$b>

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
The state of the bad-value flag of the output ndarrays is unknown.


=cut






*power = \&PDL::power;



{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'atan2'} = $overload_sub = sub(;@) {
      return PDL::atan2(@_) unless ref $_[1]
              && (ref $_[1] ne 'PDL')
              && defined($foo = overload::Method($_[1], 'atan2'))
              && $foo != $overload_sub; # recursion guard
      $foo->($_[1], $_[0], !$_[2]);
  }; }
}




=head2 atan2

=for sig

  Signature: (a(); b(); [o]c(); int swap)

=for ref

elementwise C<atan2> of two ndarrays

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
The state of the bad-value flag of the output ndarrays is unknown.


=cut






*atan2 = \&PDL::atan2;



{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'%'} = $overload_sub = sub(;@) {
      return PDL::modulo(@_) unless ref $_[1]
              && (ref $_[1] ne 'PDL')
              && defined($foo = overload::Method($_[1], '%'))
              && $foo != $overload_sub; # recursion guard
      $foo->($_[1], $_[0], !$_[2]);
  }; }
}
BEGIN {
# in1, in2, out, swap if true
$OVERLOADS{'%='} = sub { PDL::modulo($_[0], $_[1], $_[0], 0); $_[0] };
}




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
The state of the bad-value flag of the output ndarrays is unknown.


=cut






*modulo = \&PDL::modulo;



{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'<=>'} = $overload_sub = sub(;@) {
      return PDL::spaceship(@_) unless ref $_[1]
              && (ref $_[1] ne 'PDL')
              && defined($foo = overload::Method($_[1], '<=>'))
              && $foo != $overload_sub; # recursion guard
      $foo->($_[1], $_[0], !$_[2]);
  }; }
}




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
The state of the bad-value flag of the output ndarrays is unknown.


=cut






*spaceship = \&PDL::spaceship;



BEGIN { $OVERLOADS{'sqrt'} = sub { PDL::sqrt($_[0]) } }




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
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut






*sqrt = \&PDL::sqrt;



BEGIN { $OVERLOADS{'sin'} = sub { PDL::sin($_[0]) } }




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
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut






*sin = \&PDL::sin;



BEGIN { $OVERLOADS{'cos'} = sub { PDL::cos($_[0]) } }




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
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut






*cos = \&PDL::cos;



BEGIN { $OVERLOADS{'!'} = sub { PDL::not($_[0]) } }




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
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut






*not = \&PDL::not;



BEGIN { $OVERLOADS{'exp'} = sub { PDL::exp($_[0]) } }




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
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut






*exp = \&PDL::exp;



BEGIN { $OVERLOADS{'log'} = sub { PDL::log($_[0]) } }




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
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut






*log = \&PDL::log;





=head2 re

=for sig

  Signature: (complexv(); real [o]b())

=for ref

Returns the real part of a complex number.

=for bad

re processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut






*re = \&PDL::re;





=head2 im

=for sig

  Signature: (complexv(); real [o]b())

=for ref

Returns the imaginary part of a complex number.

=for bad

im processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut






*im = \&PDL::im;





=head2 _cabs

=for sig

  Signature: (complexv(); real [o]b())

=for ref

Returns the absolute (length) of a complex number.

=for bad

_cabs processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
















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
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


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

If C<a> is a child ndarray (e.g., the result of a slice) and bad values are generated in C<b>,
the bad value flag is set in C<b>, but it is B<NOT> automatically propagated back to the parent of C<a>.
The following idiom ensures that the badflag is propagated back to the parent of C<a>:

 $pdl->slice(":,(1)") .= PDL::Bad_aware_func();
 $pdl->badflag(1);
 $pdl->check_badflag();

This is unnecessary if $pdl->badflag is known to be 1 before the slice is performed.

See http://pdl.perl.org/PDLdocs/BadValues.html#dataflow_of_the_badflag for details.

=cut






*assgn = \&PDL::assgn;





=head2 carg

=for sig

  Signature: (complexv(); real [o]b())

=for ref

Returns the polar angle of a complex number.

=for bad

carg processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut






*carg = \&PDL::carg;





=head2 conj

=for sig

  Signature: (complexv();  [o]b())

=for ref

complex conjugate.

=for bad

conj processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut






*conj = \&PDL::conj;





=head2 czip

=for sig

  Signature: (r(); i(); complex [o]c())

convert real, imaginary to native complex, (sort of) like LISP zip
function. Will add the C<r> ndarray to "i" times the C<i> ndarray. Only
takes real ndarrays as input.


=for bad

czip does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut






*czip = \&PDL::czip;





=head2 ipow

=for sig

  Signature: (a(); indx b(); [o] ans())


=for ref

raise ndarray C<$a> to integer power C<$b>

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
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut






*ipow = \&PDL::ipow;




=head2 abs

=for ref

Returns the absolute value of a number.

=cut

sub PDL::abs { $_[0]->type->real ? goto &PDL::_rabs : goto &PDL::_cabs }


BEGIN { $OVERLOADS{'abs'} = sub { PDL::abs($_[0]) } }



=head2 abs2

=for ref

Returns the square of the absolute value of a number.

=cut

sub PDL::abs2 ($) { my $r = &PDL::abs; $r * $r }




=head2 r2C

=for sig

  Signature: (r(); complex [o]c())

=for ref

convert real to native complex, with an imaginary part of zero

=for bad

r2C does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut




sub PDL::r2C ($) {
  return $_[0] if UNIVERSAL::isa($_[0], 'PDL') and !$_[0]->type->real;
  my $r = $_[1] // PDL->nullcreate($_[0]);
  PDL::_r2C_int($_[0], $r);
  $r;
}


*r2C = \&PDL::r2C;





=head2 i2C

=for sig

  Signature: (i(); complex [o]c())

=for ref

convert imaginary to native complex, with a real part of zero

=for bad

i2C does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut




sub PDL::i2C ($) {
  return $_[0] if UNIVERSAL::isa($_[0], 'PDL') and !$_[0]->type->real;
  my $r = $_[1] // PDL->nullcreate($_[0]);
  PDL::_i2C_int($_[0], $r);
  $r;
}


*i2C = \&PDL::i2C;



# This is to used warn if an operand is non-numeric or non-PDL.
sub warn_non_numeric_op_wrapper {
  require Scalar::Util;
  my ($cb, $op_name) = @_;
  return sub {
    my ($op1, $op2) = @_;
    warn "'$op2' is not numeric nor a PDL in operator $op_name"
      unless Scalar::Util::looks_like_number($op2)
            || ( Scalar::Util::blessed($op2) && $op2->isa('PDL') );
    $cb->(@_);
  }
}

{ package PDL;
  use Carp;
  use overload %OVERLOADS,
    "eq"    => PDL::Ops::warn_non_numeric_op_wrapper(\&PDL::eq, 'eq'),
    "="     => sub {$_[0]},          # Don't deep copy, just copy reference
    ".="    => sub {
      my @args = !$_[2] ? @_[1,0] : @_[0,1];
      PDL::Ops::assgn(@args);
      return $args[1];
    },
    'bool'  => sub {
      return 0 if $_[0]->isnull;
      croak("multielement ndarray in conditional expression (see PDL::FAQ questions 6-10 and 6-11)")
        unless $_[0]->nelem == 1;
      $_[0]->clump(-1)->at(0);
    },
    '++' => sub { $_[0] += 1 },
    '--' => sub { $_[0] -= 1 },
  ;
}


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

		   
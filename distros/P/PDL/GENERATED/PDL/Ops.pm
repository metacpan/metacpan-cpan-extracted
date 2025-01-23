#
# GENERATED WITH PDL::PP from lib/PDL/Ops.pd! Don't modify!
#
package PDL::Ops;

our @EXPORT_OK = qw( log10 assgn carg conj czip ipow abs2 r2C i2C );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Ops ;

{ package # hide from MetaCPAN
 PDL;

#line 1437 "/home/osboxes/pdl-code/lib/PDL/PP.pm"
{
  my ($foo, $overload_sub);
  use overload '+' => $overload_sub = sub {
    Carp::confess("PDL::plus: overloaded '+' given undef")
      if grep !defined, @_[0,1];
    return PDL::plus(@_) unless ref $_[1]
            && (ref $_[1] ne 'PDL')
            && defined($foo = overload::Method($_[1], '+'))
            && $foo != $overload_sub; # recursion guard
    goto &$foo;
  };
}

#line 1452 "/home/osboxes/pdl-code/lib/PDL/PP.pm"
# in1, in2, out, swap if true
use overload '+=' => sub {
  Carp::confess("PDL::plus: overloaded '+=' given undef")
    if grep !defined, @_[0,1];
  PDL::plus($_[0]->inplace, $_[1]); $_[0]
};
#line 44 "lib/PDL/Ops.pm"
}
{ package # hide from MetaCPAN
 PDL;

#line 1437 "/home/osboxes/pdl-code/lib/PDL/PP.pm"
{
  my ($foo, $overload_sub);
  use overload '*' => $overload_sub = sub {
    Carp::confess("PDL::mult: overloaded '*' given undef")
      if grep !defined, @_[0,1];
    return PDL::mult(@_) unless ref $_[1]
            && (ref $_[1] ne 'PDL')
            && defined($foo = overload::Method($_[1], '*'))
            && $foo != $overload_sub; # recursion guard
    goto &$foo;
  };
}

#line 1452 "/home/osboxes/pdl-code/lib/PDL/PP.pm"
# in1, in2, out, swap if true
use overload '*=' => sub {
  Carp::confess("PDL::mult: overloaded '*=' given undef")
    if grep !defined, @_[0,1];
  PDL::mult($_[0]->inplace, $_[1]); $_[0]
};
#line 70 "lib/PDL/Ops.pm"
}
{ package # hide from MetaCPAN
 PDL;

#line 1437 "/home/osboxes/pdl-code/lib/PDL/PP.pm"
{
  my ($foo, $overload_sub);
  use overload '-' => $overload_sub = sub {
    Carp::confess("PDL::minus: overloaded '-' given undef")
      if grep !defined, @_[0,1];
    return PDL::minus(@_) unless ref $_[1]
            && (ref $_[1] ne 'PDL')
            && defined($foo = overload::Method($_[1], '-'))
            && $foo != $overload_sub; # recursion guard
    goto &$foo;
  };
}

#line 1452 "/home/osboxes/pdl-code/lib/PDL/PP.pm"
# in1, in2, out, swap if true
use overload '-=' => sub {
  Carp::confess("PDL::minus: overloaded '-=' given undef")
    if grep !defined, @_[0,1];
  PDL::minus($_[0]->inplace, $_[1]); $_[0]
};
#line 96 "lib/PDL/Ops.pm"
}
{ package # hide from MetaCPAN
 PDL;

#line 1437 "/home/osboxes/pdl-code/lib/PDL/PP.pm"
{
  my ($foo, $overload_sub);
  use overload '/' => $overload_sub = sub {
    Carp::confess("PDL::divide: overloaded '/' given undef")
      if grep !defined, @_[0,1];
    return PDL::divide(@_) unless ref $_[1]
            && (ref $_[1] ne 'PDL')
            && defined($foo = overload::Method($_[1], '/'))
            && $foo != $overload_sub; # recursion guard
    goto &$foo;
  };
}

#line 1452 "/home/osboxes/pdl-code/lib/PDL/PP.pm"
# in1, in2, out, swap if true
use overload '/=' => sub {
  Carp::confess("PDL::divide: overloaded '/=' given undef")
    if grep !defined, @_[0,1];
  PDL::divide($_[0]->inplace, $_[1]); $_[0]
};
#line 122 "lib/PDL/Ops.pm"
}
{ package # hide from MetaCPAN
 PDL;

#line 1437 "/home/osboxes/pdl-code/lib/PDL/PP.pm"
{
  my ($foo, $overload_sub);
  use overload '>' => $overload_sub = sub {
    Carp::confess("PDL::gt: overloaded '>' given undef")
      if grep !defined, @_[0,1];
    return PDL::gt(@_) unless ref $_[1]
            && (ref $_[1] ne 'PDL')
            && defined($foo = overload::Method($_[1], '>'))
            && $foo != $overload_sub; # recursion guard
    goto &$foo;
  };
}
#line 140 "lib/PDL/Ops.pm"
}
{ package # hide from MetaCPAN
 PDL;

#line 1437 "/home/osboxes/pdl-code/lib/PDL/PP.pm"
{
  my ($foo, $overload_sub);
  use overload '<' => $overload_sub = sub {
    Carp::confess("PDL::lt: overloaded '<' given undef")
      if grep !defined, @_[0,1];
    return PDL::lt(@_) unless ref $_[1]
            && (ref $_[1] ne 'PDL')
            && defined($foo = overload::Method($_[1], '<'))
            && $foo != $overload_sub; # recursion guard
    goto &$foo;
  };
}
#line 158 "lib/PDL/Ops.pm"
}
{ package # hide from MetaCPAN
 PDL;

#line 1437 "/home/osboxes/pdl-code/lib/PDL/PP.pm"
{
  my ($foo, $overload_sub);
  use overload '<=' => $overload_sub = sub {
    Carp::confess("PDL::le: overloaded '<=' given undef")
      if grep !defined, @_[0,1];
    return PDL::le(@_) unless ref $_[1]
            && (ref $_[1] ne 'PDL')
            && defined($foo = overload::Method($_[1], '<='))
            && $foo != $overload_sub; # recursion guard
    goto &$foo;
  };
}
#line 176 "lib/PDL/Ops.pm"
}
{ package # hide from MetaCPAN
 PDL;

#line 1437 "/home/osboxes/pdl-code/lib/PDL/PP.pm"
{
  my ($foo, $overload_sub);
  use overload '>=' => $overload_sub = sub {
    Carp::confess("PDL::ge: overloaded '>=' given undef")
      if grep !defined, @_[0,1];
    return PDL::ge(@_) unless ref $_[1]
            && (ref $_[1] ne 'PDL')
            && defined($foo = overload::Method($_[1], '>='))
            && $foo != $overload_sub; # recursion guard
    goto &$foo;
  };
}
#line 194 "lib/PDL/Ops.pm"
}
{ package # hide from MetaCPAN
 PDL;

#line 1437 "/home/osboxes/pdl-code/lib/PDL/PP.pm"
{
  my ($foo, $overload_sub);
  use overload '==' => $overload_sub = sub {
    Carp::confess("PDL::eq: overloaded '==' given undef")
      if grep !defined, @_[0,1];
    return PDL::eq(@_) unless ref $_[1]
            && (ref $_[1] ne 'PDL')
            && defined($foo = overload::Method($_[1], '=='))
            && $foo != $overload_sub; # recursion guard
    goto &$foo;
  };
}
#line 212 "lib/PDL/Ops.pm"
}
{ package # hide from MetaCPAN
 PDL;

#line 1437 "/home/osboxes/pdl-code/lib/PDL/PP.pm"
{
  my ($foo, $overload_sub);
  use overload '!=' => $overload_sub = sub {
    Carp::confess("PDL::ne: overloaded '!=' given undef")
      if grep !defined, @_[0,1];
    return PDL::ne(@_) unless ref $_[1]
            && (ref $_[1] ne 'PDL')
            && defined($foo = overload::Method($_[1], '!='))
            && $foo != $overload_sub; # recursion guard
    goto &$foo;
  };
}
#line 230 "lib/PDL/Ops.pm"
}
{ package # hide from MetaCPAN
 PDL;

#line 1437 "/home/osboxes/pdl-code/lib/PDL/PP.pm"
{
  my ($foo, $overload_sub);
  use overload '<<' => $overload_sub = sub {
    Carp::confess("PDL::shiftleft: overloaded '<<' given undef")
      if grep !defined, @_[0,1];
    return PDL::shiftleft(@_) unless ref $_[1]
            && (ref $_[1] ne 'PDL')
            && defined($foo = overload::Method($_[1], '<<'))
            && $foo != $overload_sub; # recursion guard
    goto &$foo;
  };
}

#line 1452 "/home/osboxes/pdl-code/lib/PDL/PP.pm"
# in1, in2, out, swap if true
use overload '<<=' => sub {
  Carp::confess("PDL::shiftleft: overloaded '<<=' given undef")
    if grep !defined, @_[0,1];
  PDL::shiftleft($_[0]->inplace, $_[1]); $_[0]
};
#line 256 "lib/PDL/Ops.pm"
}
{ package # hide from MetaCPAN
 PDL;

#line 1437 "/home/osboxes/pdl-code/lib/PDL/PP.pm"
{
  my ($foo, $overload_sub);
  use overload '>>' => $overload_sub = sub {
    Carp::confess("PDL::shiftright: overloaded '>>' given undef")
      if grep !defined, @_[0,1];
    return PDL::shiftright(@_) unless ref $_[1]
            && (ref $_[1] ne 'PDL')
            && defined($foo = overload::Method($_[1], '>>'))
            && $foo != $overload_sub; # recursion guard
    goto &$foo;
  };
}

#line 1452 "/home/osboxes/pdl-code/lib/PDL/PP.pm"
# in1, in2, out, swap if true
use overload '>>=' => sub {
  Carp::confess("PDL::shiftright: overloaded '>>=' given undef")
    if grep !defined, @_[0,1];
  PDL::shiftright($_[0]->inplace, $_[1]); $_[0]
};
#line 282 "lib/PDL/Ops.pm"
}
{ package # hide from MetaCPAN
 PDL;

#line 1437 "/home/osboxes/pdl-code/lib/PDL/PP.pm"
{
  my ($foo, $overload_sub);
  use overload '|' => $overload_sub = sub {
    Carp::confess("PDL::or2: overloaded '|' given undef")
      if grep !defined, @_[0,1];
    return PDL::or2($_[2]?@_[1,0]:@_[0,1]) unless ref $_[1]
            && (ref $_[1] ne 'PDL')
            && defined($foo = overload::Method($_[1], '|'))
            && $foo != $overload_sub; # recursion guard
    goto &$foo;
  };
}

#line 1452 "/home/osboxes/pdl-code/lib/PDL/PP.pm"
# in1, in2, out, swap if true
use overload '|=' => sub {
  Carp::confess("PDL::or2: overloaded '|=' given undef")
    if grep !defined, @_[0,1];
  PDL::or2($_[0]->inplace, $_[1]); $_[0]
};
#line 308 "lib/PDL/Ops.pm"
}
{ package # hide from MetaCPAN
 PDL;

#line 1437 "/home/osboxes/pdl-code/lib/PDL/PP.pm"
{
  my ($foo, $overload_sub);
  use overload '&' => $overload_sub = sub {
    Carp::confess("PDL::and2: overloaded '&' given undef")
      if grep !defined, @_[0,1];
    return PDL::and2($_[2]?@_[1,0]:@_[0,1]) unless ref $_[1]
            && (ref $_[1] ne 'PDL')
            && defined($foo = overload::Method($_[1], '&'))
            && $foo != $overload_sub; # recursion guard
    goto &$foo;
  };
}

#line 1452 "/home/osboxes/pdl-code/lib/PDL/PP.pm"
# in1, in2, out, swap if true
use overload '&=' => sub {
  Carp::confess("PDL::and2: overloaded '&=' given undef")
    if grep !defined, @_[0,1];
  PDL::and2($_[0]->inplace, $_[1]); $_[0]
};
#line 334 "lib/PDL/Ops.pm"
}
{ package # hide from MetaCPAN
 PDL;

#line 1437 "/home/osboxes/pdl-code/lib/PDL/PP.pm"
{
  my ($foo, $overload_sub);
  use overload '^' => $overload_sub = sub {
    Carp::confess("PDL::xor: overloaded '^' given undef")
      if grep !defined, @_[0,1];
    return PDL::xor($_[2]?@_[1,0]:@_[0,1]) unless ref $_[1]
            && (ref $_[1] ne 'PDL')
            && defined($foo = overload::Method($_[1], '^'))
            && $foo != $overload_sub; # recursion guard
    goto &$foo;
  };
}

#line 1452 "/home/osboxes/pdl-code/lib/PDL/PP.pm"
# in1, in2, out, swap if true
use overload '^=' => sub {
  Carp::confess("PDL::xor: overloaded '^=' given undef")
    if grep !defined, @_[0,1];
  PDL::xor($_[0]->inplace, $_[1]); $_[0]
};
#line 360 "lib/PDL/Ops.pm"
}
{ package # hide from MetaCPAN
 PDL;

#line 1429 "/home/osboxes/pdl-code/lib/PDL/PP.pm"
use overload '~' => sub {
  Carp::confess("PDL::bitnot: overloaded '~' given undef")
    if grep !defined, $_[0];
  PDL::bitnot($_[0]);
};
#line 371 "lib/PDL/Ops.pm"
}
{ package # hide from MetaCPAN
 PDL;

#line 1437 "/home/osboxes/pdl-code/lib/PDL/PP.pm"
{
  my ($foo, $overload_sub);
  use overload '**' => $overload_sub = sub {
    Carp::confess("PDL::power: overloaded '**' given undef")
      if grep !defined, @_[0,1];
    return PDL::power(@_) unless ref $_[1]
            && (ref $_[1] ne 'PDL')
            && defined($foo = overload::Method($_[1], '**'))
            && $foo != $overload_sub; # recursion guard
    goto &$foo;
  };
}

#line 1452 "/home/osboxes/pdl-code/lib/PDL/PP.pm"
# in1, in2, out, swap if true
use overload '**=' => sub {
  Carp::confess("PDL::power: overloaded '**=' given undef")
    if grep !defined, @_[0,1];
  PDL::power($_[0]->inplace, $_[1]); $_[0]
};
#line 397 "lib/PDL/Ops.pm"
}
{ package # hide from MetaCPAN
 PDL;

#line 1437 "/home/osboxes/pdl-code/lib/PDL/PP.pm"
{
  my ($foo, $overload_sub);
  use overload 'atan2' => $overload_sub = sub {
    Carp::confess("PDL::atan2: overloaded 'atan2' given undef")
      if grep !defined, @_[0,1];
    return PDL::atan2(@_) unless ref $_[1]
            && (ref $_[1] ne 'PDL')
            && defined($foo = overload::Method($_[1], 'atan2'))
            && $foo != $overload_sub; # recursion guard
    goto &$foo;
  };
}
#line 415 "lib/PDL/Ops.pm"
}
{ package # hide from MetaCPAN
 PDL;

#line 1437 "/home/osboxes/pdl-code/lib/PDL/PP.pm"
{
  my ($foo, $overload_sub);
  use overload '%' => $overload_sub = sub {
    Carp::confess("PDL::modulo: overloaded '%' given undef")
      if grep !defined, @_[0,1];
    return PDL::modulo(@_) unless ref $_[1]
            && (ref $_[1] ne 'PDL')
            && defined($foo = overload::Method($_[1], '%'))
            && $foo != $overload_sub; # recursion guard
    goto &$foo;
  };
}

#line 1452 "/home/osboxes/pdl-code/lib/PDL/PP.pm"
# in1, in2, out, swap if true
use overload '%=' => sub {
  Carp::confess("PDL::modulo: overloaded '%=' given undef")
    if grep !defined, @_[0,1];
  PDL::modulo($_[0]->inplace, $_[1]); $_[0]
};
#line 441 "lib/PDL/Ops.pm"
}
{ package # hide from MetaCPAN
 PDL;

#line 1437 "/home/osboxes/pdl-code/lib/PDL/PP.pm"
{
  my ($foo, $overload_sub);
  use overload '<=>' => $overload_sub = sub {
    Carp::confess("PDL::spaceship: overloaded '<=>' given undef")
      if grep !defined, @_[0,1];
    return PDL::spaceship(@_) unless ref $_[1]
            && (ref $_[1] ne 'PDL')
            && defined($foo = overload::Method($_[1], '<=>'))
            && $foo != $overload_sub; # recursion guard
    goto &$foo;
  };
}
#line 459 "lib/PDL/Ops.pm"
}
{ package # hide from MetaCPAN
 PDL;

#line 1429 "/home/osboxes/pdl-code/lib/PDL/PP.pm"
use overload 'sqrt' => sub {
  Carp::confess("PDL::sqrt: overloaded 'sqrt' given undef")
    if grep !defined, $_[0];
  PDL::sqrt($_[0]);
};
#line 470 "lib/PDL/Ops.pm"
}
{ package # hide from MetaCPAN
 PDL;

#line 1429 "/home/osboxes/pdl-code/lib/PDL/PP.pm"
use overload 'sin' => sub {
  Carp::confess("PDL::sin: overloaded 'sin' given undef")
    if grep !defined, $_[0];
  PDL::sin($_[0]);
};
#line 481 "lib/PDL/Ops.pm"
}
{ package # hide from MetaCPAN
 PDL;

#line 1429 "/home/osboxes/pdl-code/lib/PDL/PP.pm"
use overload 'cos' => sub {
  Carp::confess("PDL::cos: overloaded 'cos' given undef")
    if grep !defined, $_[0];
  PDL::cos($_[0]);
};
#line 492 "lib/PDL/Ops.pm"
}
{ package # hide from MetaCPAN
 PDL;

#line 1429 "/home/osboxes/pdl-code/lib/PDL/PP.pm"
use overload '!' => sub {
  Carp::confess("PDL::not: overloaded '!' given undef")
    if grep !defined, $_[0];
  PDL::not($_[0]);
};
#line 503 "lib/PDL/Ops.pm"
}
{ package # hide from MetaCPAN
 PDL;

#line 1429 "/home/osboxes/pdl-code/lib/PDL/PP.pm"
use overload 'exp' => sub {
  Carp::confess("PDL::exp: overloaded 'exp' given undef")
    if grep !defined, $_[0];
  PDL::exp($_[0]);
};
#line 514 "lib/PDL/Ops.pm"
}
{ package # hide from MetaCPAN
 PDL;

#line 1429 "/home/osboxes/pdl-code/lib/PDL/PP.pm"
use overload 'log' => sub {
  Carp::confess("PDL::log: overloaded 'log' given undef")
    if grep !defined, $_[0];
  PDL::log($_[0]);
};
#line 525 "lib/PDL/Ops.pm"
}







#line 20 "lib/PDL/Ops.pd"

use strict;
use warnings;

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
#line 560 "lib/PDL/Ops.pm"


=head1 FUNCTIONS

=cut






=head2 plus

=for sig

 Signature: (a(); b(); [o]c(); int $swap)
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble cfloat cdouble cldouble)

=for usage

 $c = $a + $b;                # overloads the Perl '+' operator
 $a += $b;
 $c = plus($a, $b);           # using default value of swap=0
 $c = plus($a, $b, $swap);    # overriding default
 plus($a, $b, $c, $swap);     # all arguments given
 $c = $a->plus($b);           # method call
 $c = $a->plus($b, $swap);
 $a->plus($b, $c, $swap);
 $a->inplace->plus($b,$swap); # can be used inplace
 plus($a->inplace,$b,$swap);

=for ref

add two ndarrays

=pod

Broadcasts over its inputs.

=for bad

C<plus> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*plus = \&PDL::plus;






=head2 mult

=for sig

 Signature: (a(); b(); [o]c(); int $swap)
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble cfloat cdouble cldouble)

=for usage

 $c = $a * $b;                # overloads the Perl '*' operator
 $a *= $b;
 $c = mult($a, $b);           # using default value of swap=0
 $c = mult($a, $b, $swap);    # overriding default
 mult($a, $b, $c, $swap);     # all arguments given
 $c = $a->mult($b);           # method call
 $c = $a->mult($b, $swap);
 $a->mult($b, $c, $swap);
 $a->inplace->mult($b,$swap); # can be used inplace
 mult($a->inplace,$b,$swap);

=for ref

multiply two ndarrays

=pod

Broadcasts over its inputs.

=for bad

C<mult> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*mult = \&PDL::mult;






=head2 minus

=for sig

 Signature: (a(); b(); [o]c(); int $swap)
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble cfloat cdouble cldouble)

=for usage

 $c = $a - $b;                 # overloads the Perl '-' operator
 $a -= $b;
 $c = minus($a, $b);           # using default value of swap=0
 $c = minus($a, $b, $swap);    # overriding default
 minus($a, $b, $c, $swap);     # all arguments given
 $c = $a->minus($b);           # method call
 $c = $a->minus($b, $swap);
 $a->minus($b, $c, $swap);
 $a->inplace->minus($b,$swap); # can be used inplace
 minus($a->inplace,$b,$swap);

=for ref

subtract two ndarrays

=pod

Broadcasts over its inputs.

=for bad

C<minus> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*minus = \&PDL::minus;






=head2 divide

=for sig

 Signature: (a(); b(); [o]c(); int $swap)
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble cfloat cdouble cldouble)

=for usage

 $c = $a / $b;                  # overloads the Perl '/' operator
 $a /= $b;
 $c = divide($a, $b);           # using default value of swap=0
 $c = divide($a, $b, $swap);    # overriding default
 divide($a, $b, $c, $swap);     # all arguments given
 $c = $a->divide($b);           # method call
 $c = $a->divide($b, $swap);
 $a->divide($b, $c, $swap);
 $a->inplace->divide($b,$swap); # can be used inplace
 divide($a->inplace,$b,$swap);

=for ref

divide two ndarrays

=pod

Broadcasts over its inputs.

=for bad

C<divide> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*divide = \&PDL::divide;






=head2 gt

=for sig

 Signature: (a(); b(); [o]c(); int $swap)
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 $c = $a > $b;              # overloads the Perl '>' operator
 $c = gt($a, $b);           # using default value of swap=0
 $c = gt($a, $b, $swap);    # overriding default
 gt($a, $b, $c, $swap);     # all arguments given
 $c = $a->gt($b);           # method call
 $c = $a->gt($b, $swap);
 $a->gt($b, $c, $swap);
 $a->inplace->gt($b,$swap); # can be used inplace
 gt($a->inplace,$b,$swap);

=for ref

the binary E<gt> (greater than) operation

=pod

Broadcasts over its inputs.

=for bad

C<gt> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gt = \&PDL::gt;






=head2 lt

=for sig

 Signature: (a(); b(); [o]c(); int $swap)
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 $c = $a < $b;              # overloads the Perl '<' operator
 $c = lt($a, $b);           # using default value of swap=0
 $c = lt($a, $b, $swap);    # overriding default
 lt($a, $b, $c, $swap);     # all arguments given
 $c = $a->lt($b);           # method call
 $c = $a->lt($b, $swap);
 $a->lt($b, $c, $swap);
 $a->inplace->lt($b,$swap); # can be used inplace
 lt($a->inplace,$b,$swap);

=for ref

the binary E<lt> (less than) operation

=pod

Broadcasts over its inputs.

=for bad

C<lt> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*lt = \&PDL::lt;






=head2 le

=for sig

 Signature: (a(); b(); [o]c(); int $swap)
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 $c = $a <= $b;             # overloads the Perl '<=' operator
 $c = le($a, $b);           # using default value of swap=0
 $c = le($a, $b, $swap);    # overriding default
 le($a, $b, $c, $swap);     # all arguments given
 $c = $a->le($b);           # method call
 $c = $a->le($b, $swap);
 $a->le($b, $c, $swap);
 $a->inplace->le($b,$swap); # can be used inplace
 le($a->inplace,$b,$swap);

=for ref

the binary E<lt>= (less equal) operation

=pod

Broadcasts over its inputs.

=for bad

C<le> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*le = \&PDL::le;






=head2 ge

=for sig

 Signature: (a(); b(); [o]c(); int $swap)
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 $c = $a >= $b;             # overloads the Perl '>=' operator
 $c = ge($a, $b);           # using default value of swap=0
 $c = ge($a, $b, $swap);    # overriding default
 ge($a, $b, $c, $swap);     # all arguments given
 $c = $a->ge($b);           # method call
 $c = $a->ge($b, $swap);
 $a->ge($b, $c, $swap);
 $a->inplace->ge($b,$swap); # can be used inplace
 ge($a->inplace,$b,$swap);

=for ref

the binary E<gt>= (greater equal) operation

=pod

Broadcasts over its inputs.

=for bad

C<ge> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*ge = \&PDL::ge;






=head2 eq

=for sig

 Signature: (a(); b(); [o]c(); int $swap)
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble cfloat cdouble cldouble)

=for usage

 $c = $a == $b;             # overloads the Perl '==' operator
 $c = eq($a, $b);           # using default value of swap=0
 $c = eq($a, $b, $swap);    # overriding default
 eq($a, $b, $c, $swap);     # all arguments given
 $c = $a->eq($b);           # method call
 $c = $a->eq($b, $swap);
 $a->eq($b, $c, $swap);
 $a->inplace->eq($b,$swap); # can be used inplace
 eq($a->inplace,$b,$swap);

=for ref

binary I<equal to> operation (C<==>)

=pod

Broadcasts over its inputs.

=for bad

C<eq> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*eq = \&PDL::eq;






=head2 ne

=for sig

 Signature: (a(); b(); [o]c(); int $swap)
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble cfloat cdouble cldouble)

=for usage

 $c = $a != $b;             # overloads the Perl '!=' operator
 $c = ne($a, $b);           # using default value of swap=0
 $c = ne($a, $b, $swap);    # overriding default
 ne($a, $b, $c, $swap);     # all arguments given
 $c = $a->ne($b);           # method call
 $c = $a->ne($b, $swap);
 $a->ne($b, $c, $swap);
 $a->inplace->ne($b,$swap); # can be used inplace
 ne($a->inplace,$b,$swap);

=for ref

binary I<not equal to> operation (C<!=>)

=pod

Broadcasts over its inputs.

=for bad

C<ne> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*ne = \&PDL::ne;






=head2 shiftleft

=for sig

 Signature: (a(); b(); [o]c(); int $swap)
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong)

=for usage

 $c = $a << $b;                    # overloads the Perl '<<' operator
 $a <<= $b;
 $c = shiftleft($a, $b);           # using default value of swap=0
 $c = shiftleft($a, $b, $swap);    # overriding default
 shiftleft($a, $b, $c, $swap);     # all arguments given
 $c = $a->shiftleft($b);           # method call
 $c = $a->shiftleft($b, $swap);
 $a->shiftleft($b, $c, $swap);
 $a->inplace->shiftleft($b,$swap); # can be used inplace
 shiftleft($a->inplace,$b,$swap);

=for ref

bitwise leftshift C<$a> by C<$b>

=pod

Broadcasts over its inputs.

=for bad

C<shiftleft> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*shiftleft = \&PDL::shiftleft;






=head2 shiftright

=for sig

 Signature: (a(); b(); [o]c(); int $swap)
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong)

=for usage

 $c = $a >> $b;                     # overloads the Perl '>>' operator
 $a >>= $b;
 $c = shiftright($a, $b);           # using default value of swap=0
 $c = shiftright($a, $b, $swap);    # overriding default
 shiftright($a, $b, $c, $swap);     # all arguments given
 $c = $a->shiftright($b);           # method call
 $c = $a->shiftright($b, $swap);
 $a->shiftright($b, $c, $swap);
 $a->inplace->shiftright($b,$swap); # can be used inplace
 shiftright($a->inplace,$b,$swap);

=for ref

bitwise rightshift C<$a> by C<$b>

=pod

Broadcasts over its inputs.

=for bad

C<shiftright> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*shiftright = \&PDL::shiftright;






=head2 or2

=for sig

 Signature: (a(); b(); [o]c(); int $swap)
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong)

=for usage

 $c = $a | $b;               # overloads the Perl '|' operator
 $a |= $b;
 $c = or2($a, $b);           # using default value of swap=0
 $c = or2($a, $b, $swap);    # overriding default
 or2($a, $b, $c, $swap);     # all arguments given
 $c = $a->or2($b);           # method call
 $c = $a->or2($b, $swap);
 $a->or2($b, $c, $swap);
 $a->inplace->or2($b,$swap); # can be used inplace
 or2($a->inplace,$b,$swap);

=for ref

bitwise I<or> of two ndarrays

=pod

Broadcasts over its inputs.

=for bad

C<or2> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*or2 = \&PDL::or2;






=head2 and2

=for sig

 Signature: (a(); b(); [o]c(); int $swap)
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong)

=for usage

 $c = $a & $b;                # overloads the Perl '&' operator
 $a &= $b;
 $c = and2($a, $b);           # using default value of swap=0
 $c = and2($a, $b, $swap);    # overriding default
 and2($a, $b, $c, $swap);     # all arguments given
 $c = $a->and2($b);           # method call
 $c = $a->and2($b, $swap);
 $a->and2($b, $c, $swap);
 $a->inplace->and2($b,$swap); # can be used inplace
 and2($a->inplace,$b,$swap);

=for ref

bitwise I<and> of two ndarrays

=pod

Broadcasts over its inputs.

=for bad

C<and2> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*and2 = \&PDL::and2;






=head2 xor

=for sig

 Signature: (a(); b(); [o]c(); int $swap)
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong)

=for usage

 $c = $a ^ $b;               # overloads the Perl '^' operator
 $a ^= $b;
 $c = xor($a, $b);           # using default value of swap=0
 $c = xor($a, $b, $swap);    # overriding default
 xor($a, $b, $c, $swap);     # all arguments given
 $c = $a->xor($b);           # method call
 $c = $a->xor($b, $swap);
 $a->xor($b, $c, $swap);
 $a->inplace->xor($b,$swap); # can be used inplace
 xor($a->inplace,$b,$swap);

=for ref

bitwise I<exclusive or> of two ndarrays

=pod

Broadcasts over its inputs.

=for bad

C<xor> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*xor = \&PDL::xor;






=head2 bitnot

=for sig

 Signature: (a(); [o]b())
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong)

=for usage

 $b = ~$a;            # overloads the Perl '~' operator
 $b = bitnot($a);
 bitnot($a, $b);      # all arguments given
 $b = $a->bitnot;     # method call
 $a->bitnot($b);
 $a->inplace->bitnot; # can be used inplace
 bitnot($a->inplace);

=for ref

unary bitwise negation

=pod

Broadcasts over its inputs.

=for bad

C<bitnot> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*bitnot = \&PDL::bitnot;






=head2 power

=for sig

 Signature: (a(); b(); [o]c(); int $swap)
 Types: (cfloat cdouble cldouble float ldouble double)

=for usage

 $c = $a ** $b;                # overloads the Perl '**' operator
 $a **= $b;
 $c = power($a, $b);           # using default value of swap=0
 $c = power($a, $b, $swap);    # overriding default
 power($a, $b, $c, $swap);     # all arguments given
 $c = $a->power($b);           # method call
 $c = $a->power($b, $swap);
 $a->power($b, $c, $swap);
 $a->inplace->power($b,$swap); # can be used inplace
 power($a->inplace,$b,$swap);

=for ref

raise ndarray C<$a> to the power C<$b>

=pod

Broadcasts over its inputs.

=for bad

C<power> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*power = \&PDL::power;






=head2 atan2

=for sig

 Signature: (a(); b(); [o]c(); int $swap)
 Types: (float ldouble double)

=for usage

 $c = $a atan2 $b;             # overloads the Perl 'atan2' operator
 $c = atan2($a, $b);           # using default value of swap=0
 $c = atan2($a, $b, $swap);    # overriding default
 atan2($a, $b, $c, $swap);     # all arguments given
 $c = $a->atan2($b);           # method call
 $c = $a->atan2($b, $swap);
 $a->atan2($b, $c, $swap);
 $a->inplace->atan2($b,$swap); # can be used inplace
 atan2($a->inplace,$b,$swap);

=for ref

elementwise C<atan2> of two ndarrays

=pod

Broadcasts over its inputs.

=for bad

C<atan2> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*atan2 = \&PDL::atan2;






=head2 modulo

=for sig

 Signature: (a(); b(); [o]c(); int $swap)
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 $c = $a % $b;                  # overloads the Perl '%' operator
 $a %= $b;
 $c = modulo($a, $b);           # using default value of swap=0
 $c = modulo($a, $b, $swap);    # overriding default
 modulo($a, $b, $c, $swap);     # all arguments given
 $c = $a->modulo($b);           # method call
 $c = $a->modulo($b, $swap);
 $a->modulo($b, $c, $swap);
 $a->inplace->modulo($b,$swap); # can be used inplace
 modulo($a->inplace,$b,$swap);

=for ref

elementwise C<modulo> operation

=pod

Broadcasts over its inputs.

=for bad

C<modulo> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*modulo = \&PDL::modulo;






=head2 spaceship

=for sig

 Signature: (a(); b(); [o]c(); int $swap)
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 $c = $a <=> $b;                   # overloads the Perl '<=>' operator
 $c = spaceship($a, $b);           # using default value of swap=0
 $c = spaceship($a, $b, $swap);    # overriding default
 spaceship($a, $b, $c, $swap);     # all arguments given
 $c = $a->spaceship($b);           # method call
 $c = $a->spaceship($b, $swap);
 $a->spaceship($b, $c, $swap);
 $a->inplace->spaceship($b,$swap); # can be used inplace
 spaceship($a->inplace,$b,$swap);

=for ref

elementwise "<=>" operation

=pod

Broadcasts over its inputs.

=for bad

C<spaceship> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*spaceship = \&PDL::spaceship;






=head2 sqrt

=for sig

 Signature: (a(); [o]b())
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble cfloat cdouble cldouble)

=for usage

 $b = sqrt $a;      # overloads the Perl 'sqrt' operator
 $b = sqrt($a);
 sqrt($a, $b);      # all arguments given
 $b = $a->sqrt;     # method call
 $a->sqrt($b);
 $a->inplace->sqrt; # can be used inplace
 sqrt($a->inplace);

=for ref

elementwise square root

=pod

Broadcasts over its inputs.

=for bad

C<sqrt> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*sqrt = \&PDL::sqrt;






=head2 sin

=for sig

 Signature: (a(); [o]b())
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble cfloat cdouble cldouble)

=for usage

 $b = sin $a;      # overloads the Perl 'sin' operator
 $b = sin($a);
 sin($a, $b);      # all arguments given
 $b = $a->sin;     # method call
 $a->sin($b);
 $a->inplace->sin; # can be used inplace
 sin($a->inplace);

=for ref

the sin function

=pod

Broadcasts over its inputs.

=for bad

C<sin> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*sin = \&PDL::sin;






=head2 cos

=for sig

 Signature: (a(); [o]b())
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble cfloat cdouble cldouble)

=for usage

 $b = cos $a;      # overloads the Perl 'cos' operator
 $b = cos($a);
 cos($a, $b);      # all arguments given
 $b = $a->cos;     # method call
 $a->cos($b);
 $a->inplace->cos; # can be used inplace
 cos($a->inplace);

=for ref

the cos function

=pod

Broadcasts over its inputs.

=for bad

C<cos> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*cos = \&PDL::cos;






=head2 not

=for sig

 Signature: (a(); [o]b())
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 $b = !$a;         # overloads the Perl '!' operator
 $b = not($a);
 not($a, $b);      # all arguments given
 $b = $a->not;     # method call
 $a->not($b);
 $a->inplace->not; # can be used inplace
 not($a->inplace);

=for ref

the elementwise I<not> operation

=pod

Broadcasts over its inputs.

=for bad

C<not> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*not = \&PDL::not;






=head2 exp

=for sig

 Signature: (a(); [o]b())
 Types: (cfloat cdouble cldouble float ldouble double)

=for usage

 $b = exp $a;      # overloads the Perl 'exp' operator
 $b = exp($a);
 exp($a, $b);      # all arguments given
 $b = $a->exp;     # method call
 $a->exp($b);
 $a->inplace->exp; # can be used inplace
 exp($a->inplace);

=for ref

the exponential function

=pod

Broadcasts over its inputs.

=for bad

C<exp> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*exp = \&PDL::exp;






=head2 log

=for sig

 Signature: (a(); [o]b())
 Types: (cfloat cdouble cldouble float ldouble double)

=for usage

 $b = log $a;      # overloads the Perl 'log' operator
 $b = log($a);
 log($a, $b);      # all arguments given
 $b = $a->log;     # method call
 $a->log($b);
 $a->inplace->log; # can be used inplace
 log($a->inplace);

=for ref

the natural logarithm

=pod

Broadcasts over its inputs.

=for bad

C<log> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*log = \&PDL::log;






=head2 re

=for sig

 Signature: (complexv(); real [o]b())
 Types: (cfloat cdouble cldouble)

=for usage

 $b = re($complexv);
 re($complexv, $b);  # all arguments given
 $b = $complexv->re; # method call
 $complexv->re($b);

=for ref

Returns the real part of a complex number. Flows data back & forth.

=pod

Broadcasts over its inputs.
Creates data-flow back and forth by default.

=for bad

C<re> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*re = \&PDL::re;






=head2 im

=for sig

 Signature: (complexv(); real [o]b())
 Types: (cfloat cdouble cldouble)

=for usage

 $b = im($complexv);
 im($complexv, $b);  # all arguments given
 $b = $complexv->im; # method call
 $complexv->im($b);

=for ref

Returns the imaginary part of a complex number. Flows data back & forth.

=pod

Broadcasts over its inputs.
Creates data-flow back and forth by default.

=for bad

C<im> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*im = \&PDL::im;






=head2 _cabs

=for sig

 Signature: (complexv(); real [o]b())
 Types: (cfloat cdouble cldouble)

=for usage

 $b = _cabs($complexv);
 _cabs($complexv, $b);  # all arguments given
 $b = $complexv->_cabs; # method call
 $complexv->_cabs($b);

=for ref

Returns the absolute (length) of a complex number.

=pod

Broadcasts over its inputs.

=for bad

C<_cabs> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut














=head2 log10

=for sig

 Signature: (a(); [o]b())
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble cfloat cdouble cldouble)

=for usage

 $b = log10($a);
 log10($a, $b);      # all arguments given
 $b = $a->log10;     # method call
 $a->log10($b);
 $a->inplace->log10; # can be used inplace
 log10($a->inplace);

=for ref

the base 10 logarithm

=pod

Broadcasts over its inputs.

=for bad

C<log10> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




sub PDL::log10 {
    my ($x, $y) = @_;
    return log($x) / log(10) if !UNIVERSAL::isa($x,"PDL");
    barf "inplace but output given" if $x->is_inplace and defined $y;
    if ($x->is_inplace) { $x->set_inplace(0); $y = $x; }
    elsif (!defined $y) { $y = $x->initialize; }
    &PDL::_log10_int( $x, $y );
    $y;
};



*log10 = \&PDL::log10;






=head2 assgn

=for sig

 Signature: (a(); [o]b())
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble cfloat cdouble cldouble)

=for usage

 $b = assgn($a);
 assgn($a, $b);  # all arguments given
 $b = $a->assgn; # method call
 $a->assgn($b);

=for ref

Plain numerical assignment. This is used to implement the ".=" operator

=pod

Broadcasts over its inputs.

=for bad

C<assgn> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*assgn = \&PDL::assgn;






=head2 carg

=for sig

 Signature: (!real complexv(); real [o]b())
 Types: (cfloat cdouble cldouble)

=for usage

 $b = carg($complexv);
 carg($complexv, $b);  # all arguments given
 $b = $complexv->carg; # method call
 $complexv->carg($b);

=for ref

Returns the polar angle of a complex number.

=pod

Broadcasts over its inputs.

=for bad

C<carg> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*carg = \&PDL::carg;






=head2 conj

=for sig

 Signature: (complexv();  [o]b())
 Types: (cfloat cdouble cldouble)

=for usage

 $b = conj($complexv);
 conj($complexv, $b);      # all arguments given
 $b = $complexv->conj;     # method call
 $complexv->conj($b);
 $complexv->inplace->conj; # can be used inplace
 conj($complexv->inplace);

=for ref

complex conjugate.

=pod

Broadcasts over its inputs.

=for bad

C<conj> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*conj = \&PDL::conj;






=head2 czip

=for sig

 Signature: (!complex r(); !complex i(); complex [o]c())
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble)

=for usage

 $c = czip($r, $i);
 czip($r, $i, $c);  # all arguments given
 $c = $r->czip($i); # method call
 $r->czip($i, $c);

convert real, imaginary to native complex, (sort of) like LISP zip
function. Will add the C<r> ndarray to "i" times the C<i> ndarray. Only
takes real ndarrays as input.

=pod

Broadcasts over its inputs.

=for bad

C<czip> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*czip = \&PDL::czip;






=head2 ipow

=for sig

 Signature: (a(); longlong b(); [o] ans())
 Types: (ulonglong longlong float ldouble cfloat cdouble cldouble
   double)

=for usage

 $ans = ipow($a, $b);
 ipow($a, $b, $ans);    # all arguments given
 $ans = $a->ipow($b);   # method call
 $a->ipow($b, $ans);
 $a->inplace->ipow($b); # can be used inplace
 ipow($a->inplace,$b);

=for ref

raise ndarray C<$a> to integer power C<$b>

Algorithm from L<Wikipedia|http://en.wikipedia.org/wiki/Exponentiation_by_squaring>

=pod

Broadcasts over its inputs.

=for bad

C<ipow> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*ipow = \&PDL::ipow;





#line 460 "lib/PDL/Ops.pd"

=head2 abs

=for ref

Returns the absolute value of a number.

=cut

sub PDL::abs { $_[0]->type->real ? goto &PDL::_rabs : goto &PDL::_cabs }
#line 2119 "lib/PDL/Ops.pm"


=head2 abs2

=for sig

 Signature: (a(); real [o]b())
 Types: (sbyte byte short ushort long ulong indx ulonglong longlong
   float double ldouble cfloat cdouble cldouble)

=for usage

 $b = abs2($a);
 abs2($a, $b);  # all arguments given
 $b = $a->abs2; # method call
 $a->abs2($b);

=for ref

Returns the square of the absolute value of a number.

=pod

Broadcasts over its inputs.

=for bad

C<abs2> processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*abs2 = \&PDL::abs2;






=head2 r2C

=for sig

 Signature: (r(); complex [o]c())
 Types: (float ldouble cfloat cdouble cldouble double)

=for usage

 $c = r2C($r);
 r2C($r, $c);  # all arguments given
 $c = $r->r2C; # method call
 $r->r2C($c);

=for ref

convert real to native complex, with an imaginary part of zero

=pod

Broadcasts over its inputs.

=for bad

C<r2C> does not process bad values.
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
 Types: (float ldouble cfloat cdouble cldouble double)

=for usage

 $c = i2C($i);
 i2C($i, $c);  # all arguments given
 $c = $i->i2C; # method call
 $i->i2C($c);

=for ref

convert imaginary to native complex, with a real part of zero

=pod

Broadcasts over its inputs.

=for bad

C<i2C> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




sub PDL::i2C ($) {
  return $_[0] if UNIVERSAL::isa($_[0], 'PDL') and !$_[0]->type->real;
  my $r = $_[1] // PDL->nullcreate($_[0]);
  PDL::_i2C_int($_[0], $r);
  $r;
}



*i2C = \&PDL::i2C;





#line 517 "lib/PDL/Ops.pd"

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

{ package # hide from MetaCPAN
    PDL;
  use overload
    "eq"    => PDL::Ops::warn_non_numeric_op_wrapper(\&PDL::eq, 'eq'),
    ".="    => sub {
      my @args = !$_[2] ? @_[1,0] : @_[0,1];
      PDL::Ops::assgn(@args);
      return $args[1];
    },
    'abs' => sub { PDL::abs($_[0]) },
    '++' => sub { $_[0] += ($PDL::Core::pdl_ones[$_[0]->get_datatype]//barf "Couldn't find 'one' for type ", $_[0]->get_datatype) },
    '--' => sub { $_[0] -= ($PDL::Core::pdl_ones[$_[0]->get_datatype]//barf "Couldn't find 'one' for type ", $_[0]->get_datatype) },
    ;
}

#line 49 "lib/PDL/Ops.pd"

=head1 AUTHOR

Tuomas J. Lukka (lukka@fas.harvard.edu),
Karl Glazebrook (kgb@aaoepp.aao.gov.au),
Doug Hunt (dhunt@ucar.edu),
Christian Soeller (c.soeller@auckland.ac.nz),
Doug Burke (burke@ifa.hawaii.edu),
and Craig DeForest (deforest@boulder.swri.edu).

=cut
#line 2299 "lib/PDL/Ops.pm"

# Exit with OK status

1;

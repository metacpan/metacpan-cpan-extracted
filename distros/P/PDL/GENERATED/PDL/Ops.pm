#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::Ops;

our @EXPORT_OK = qw( log10 assgn carg conj czip ipow r2C i2C );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Ops ;







#line 18 "ops.pd"

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
#line 54 "Ops.pm"

=head1 FUNCTIONS

=cut





#line 130 "ops.pd"

#line 180 "ops.pd"
{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'+'} = $overload_sub = sub(;@) {
      goto &PDL::plus unless ref $_[1]
              && (ref $_[1] ne 'PDL')
              && defined($foo = overload::Method($_[1], '+'))
              && $foo != $overload_sub; # recursion guard
      goto &$foo;
  }; }
}

#line 193 "ops.pd"
BEGIN {
# in1, in2, out, swap if true
$OVERLOADS{'+='} = sub { PDL::plus($_[0]->inplace, $_[1]); $_[0] };
}
#line 83 "Ops.pm"

=head2 plus

=for sig

  Signature: (a(); b(); [o]c(); int $swap)

=for ref

add two ndarrays

=for example

   $c = $x + $y;        # overloaded call
   $c = plus $x, $y;     # explicit call with default swap of 0
   $c = plus $x, $y, 1;  # explicit call with trailing 1 to swap args
   $x->inplace->plus($y); # modify $x inplace

It can be made to work inplace with the C<< $x->inplace >> syntax.
This function is used to overload the binary C<+> operator.
As of 2.065, when calling this function explicitly you can omit
the third argument (see second example), or supply it (see third one).

=for bad

plus processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*plus = \&PDL::plus;





#line 130 "ops.pd"

#line 180 "ops.pd"
{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'*'} = $overload_sub = sub(;@) {
      goto &PDL::mult unless ref $_[1]
              && (ref $_[1] ne 'PDL')
              && defined($foo = overload::Method($_[1], '*'))
              && $foo != $overload_sub; # recursion guard
      goto &$foo;
  }; }
}

#line 193 "ops.pd"
BEGIN {
# in1, in2, out, swap if true
$OVERLOADS{'*='} = sub { PDL::mult($_[0]->inplace, $_[1]); $_[0] };
}
#line 142 "Ops.pm"

=head2 mult

=for sig

  Signature: (a(); b(); [o]c(); int $swap)

=for ref

multiply two ndarrays

=for example

   $c = $x * $y;        # overloaded call
   $c = mult $x, $y;     # explicit call with default swap of 0
   $c = mult $x, $y, 1;  # explicit call with trailing 1 to swap args
   $x->inplace->mult($y); # modify $x inplace

It can be made to work inplace with the C<< $x->inplace >> syntax.
This function is used to overload the binary C<*> operator.
As of 2.065, when calling this function explicitly you can omit
the third argument (see second example), or supply it (see third one).

=for bad

mult processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*mult = \&PDL::mult;





#line 130 "ops.pd"

#line 180 "ops.pd"
{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'-'} = $overload_sub = sub(;@) {
      goto &PDL::minus unless ref $_[1]
              && (ref $_[1] ne 'PDL')
              && defined($foo = overload::Method($_[1], '-'))
              && $foo != $overload_sub; # recursion guard
      goto &$foo;
  }; }
}

#line 193 "ops.pd"
BEGIN {
# in1, in2, out, swap if true
$OVERLOADS{'-='} = sub { PDL::minus($_[0]->inplace, $_[1]); $_[0] };
}
#line 201 "Ops.pm"

=head2 minus

=for sig

  Signature: (a(); b(); [o]c(); int $swap)

=for ref

subtract two ndarrays

=for example

   $c = $x - $y;        # overloaded call
   $c = minus $x, $y;     # explicit call with default swap of 0
   $c = minus $x, $y, 1;  # explicit call with trailing 1 to swap args
   $x->inplace->minus($y); # modify $x inplace

It can be made to work inplace with the C<< $x->inplace >> syntax.
This function is used to overload the binary C<-> operator.
As of 2.065, when calling this function explicitly you can omit
the third argument (see second example), or supply it (see third one).

=for bad

minus processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*minus = \&PDL::minus;





#line 130 "ops.pd"

#line 180 "ops.pd"
{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'/'} = $overload_sub = sub(;@) {
      goto &PDL::divide unless ref $_[1]
              && (ref $_[1] ne 'PDL')
              && defined($foo = overload::Method($_[1], '/'))
              && $foo != $overload_sub; # recursion guard
      goto &$foo;
  }; }
}

#line 193 "ops.pd"
BEGIN {
# in1, in2, out, swap if true
$OVERLOADS{'/='} = sub { PDL::divide($_[0]->inplace, $_[1]); $_[0] };
}
#line 260 "Ops.pm"

=head2 divide

=for sig

  Signature: (a(); b(); [o]c(); int $swap)

=for ref

divide two ndarrays

=for example

   $c = $x / $y;        # overloaded call
   $c = divide $x, $y;     # explicit call with default swap of 0
   $c = divide $x, $y, 1;  # explicit call with trailing 1 to swap args
   $x->inplace->divide($y); # modify $x inplace

It can be made to work inplace with the C<< $x->inplace >> syntax.
This function is used to overload the binary C</> operator.
As of 2.065, when calling this function explicitly you can omit
the third argument (see second example), or supply it (see third one).

=for bad

divide processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*divide = \&PDL::divide;





#line 130 "ops.pd"

#line 180 "ops.pd"
{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'>'} = $overload_sub = sub(;@) {
      goto &PDL::gt unless ref $_[1]
              && (ref $_[1] ne 'PDL')
              && defined($foo = overload::Method($_[1], '>'))
              && $foo != $overload_sub; # recursion guard
      goto &$foo;
  }; }
}
#line 313 "Ops.pm"

=head2 gt

=for sig

  Signature: (a(); b(); [o]c(); int $swap)

=for ref

the binary E<gt> (greater than) operation

=for example

   $c = $x > $y;        # overloaded call
   $c = gt $x, $y;     # explicit call with default swap of 0
   $c = gt $x, $y, 1;  # explicit call with trailing 1 to swap args
   $x->inplace->gt($y); # modify $x inplace

It can be made to work inplace with the C<< $x->inplace >> syntax.
This function is used to overload the binary C<E<gt>> operator.
As of 2.065, when calling this function explicitly you can omit
the third argument (see second example), or supply it (see third one).

=for bad

gt processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gt = \&PDL::gt;





#line 130 "ops.pd"

#line 180 "ops.pd"
{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'<'} = $overload_sub = sub(;@) {
      goto &PDL::lt unless ref $_[1]
              && (ref $_[1] ne 'PDL')
              && defined($foo = overload::Method($_[1], '<'))
              && $foo != $overload_sub; # recursion guard
      goto &$foo;
  }; }
}
#line 366 "Ops.pm"

=head2 lt

=for sig

  Signature: (a(); b(); [o]c(); int $swap)

=for ref

the binary E<lt> (less than) operation

=for example

   $c = $x < $y;        # overloaded call
   $c = lt $x, $y;     # explicit call with default swap of 0
   $c = lt $x, $y, 1;  # explicit call with trailing 1 to swap args
   $x->inplace->lt($y); # modify $x inplace

It can be made to work inplace with the C<< $x->inplace >> syntax.
This function is used to overload the binary C<E<lt>> operator.
As of 2.065, when calling this function explicitly you can omit
the third argument (see second example), or supply it (see third one).

=for bad

lt processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*lt = \&PDL::lt;





#line 130 "ops.pd"

#line 180 "ops.pd"
{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'<='} = $overload_sub = sub(;@) {
      goto &PDL::le unless ref $_[1]
              && (ref $_[1] ne 'PDL')
              && defined($foo = overload::Method($_[1], '<='))
              && $foo != $overload_sub; # recursion guard
      goto &$foo;
  }; }
}
#line 419 "Ops.pm"

=head2 le

=for sig

  Signature: (a(); b(); [o]c(); int $swap)

=for ref

the binary E<lt>= (less equal) operation

=for example

   $c = $x <= $y;        # overloaded call
   $c = le $x, $y;     # explicit call with default swap of 0
   $c = le $x, $y, 1;  # explicit call with trailing 1 to swap args
   $x->inplace->le($y); # modify $x inplace

It can be made to work inplace with the C<< $x->inplace >> syntax.
This function is used to overload the binary C<E<lt>=> operator.
As of 2.065, when calling this function explicitly you can omit
the third argument (see second example), or supply it (see third one).

=for bad

le processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*le = \&PDL::le;





#line 130 "ops.pd"

#line 180 "ops.pd"
{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'>='} = $overload_sub = sub(;@) {
      goto &PDL::ge unless ref $_[1]
              && (ref $_[1] ne 'PDL')
              && defined($foo = overload::Method($_[1], '>='))
              && $foo != $overload_sub; # recursion guard
      goto &$foo;
  }; }
}
#line 472 "Ops.pm"

=head2 ge

=for sig

  Signature: (a(); b(); [o]c(); int $swap)

=for ref

the binary E<gt>= (greater equal) operation

=for example

   $c = $x >= $y;        # overloaded call
   $c = ge $x, $y;     # explicit call with default swap of 0
   $c = ge $x, $y, 1;  # explicit call with trailing 1 to swap args
   $x->inplace->ge($y); # modify $x inplace

It can be made to work inplace with the C<< $x->inplace >> syntax.
This function is used to overload the binary C<E<gt>=> operator.
As of 2.065, when calling this function explicitly you can omit
the third argument (see second example), or supply it (see third one).

=for bad

ge processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*ge = \&PDL::ge;





#line 130 "ops.pd"

#line 180 "ops.pd"
{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'=='} = $overload_sub = sub(;@) {
      goto &PDL::eq unless ref $_[1]
              && (ref $_[1] ne 'PDL')
              && defined($foo = overload::Method($_[1], '=='))
              && $foo != $overload_sub; # recursion guard
      goto &$foo;
  }; }
}
#line 525 "Ops.pm"

=head2 eq

=for sig

  Signature: (a(); b(); [o]c(); int $swap)

=for ref

binary I<equal to> operation (C<==>)

=for example

   $c = $x == $y;        # overloaded call
   $c = eq $x, $y;     # explicit call with default swap of 0
   $c = eq $x, $y, 1;  # explicit call with trailing 1 to swap args
   $x->inplace->eq($y); # modify $x inplace

It can be made to work inplace with the C<< $x->inplace >> syntax.
This function is used to overload the binary C<==> operator.
As of 2.065, when calling this function explicitly you can omit
the third argument (see second example), or supply it (see third one).

=for bad

eq processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*eq = \&PDL::eq;





#line 130 "ops.pd"

#line 180 "ops.pd"
{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'!='} = $overload_sub = sub(;@) {
      goto &PDL::ne unless ref $_[1]
              && (ref $_[1] ne 'PDL')
              && defined($foo = overload::Method($_[1], '!='))
              && $foo != $overload_sub; # recursion guard
      goto &$foo;
  }; }
}
#line 578 "Ops.pm"

=head2 ne

=for sig

  Signature: (a(); b(); [o]c(); int $swap)

=for ref

binary I<not equal to> operation (C<!=>)

=for example

   $c = $x != $y;        # overloaded call
   $c = ne $x, $y;     # explicit call with default swap of 0
   $c = ne $x, $y, 1;  # explicit call with trailing 1 to swap args
   $x->inplace->ne($y); # modify $x inplace

It can be made to work inplace with the C<< $x->inplace >> syntax.
This function is used to overload the binary C<!=> operator.
As of 2.065, when calling this function explicitly you can omit
the third argument (see second example), or supply it (see third one).

=for bad

ne processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*ne = \&PDL::ne;





#line 130 "ops.pd"

#line 180 "ops.pd"
{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'<<'} = $overload_sub = sub(;@) {
      goto &PDL::shiftleft unless ref $_[1]
              && (ref $_[1] ne 'PDL')
              && defined($foo = overload::Method($_[1], '<<'))
              && $foo != $overload_sub; # recursion guard
      goto &$foo;
  }; }
}

#line 193 "ops.pd"
BEGIN {
# in1, in2, out, swap if true
$OVERLOADS{'<<='} = sub { PDL::shiftleft($_[0]->inplace, $_[1]); $_[0] };
}
#line 637 "Ops.pm"

=head2 shiftleft

=for sig

  Signature: (a(); b(); [o]c(); int $swap)

=for ref

leftshift C<$a> by C<$b>

=for example

   $c = $x << $y;        # overloaded call
   $c = shiftleft $x, $y;     # explicit call with default swap of 0
   $c = shiftleft $x, $y, 1;  # explicit call with trailing 1 to swap args
   $x->inplace->shiftleft($y); # modify $x inplace

It can be made to work inplace with the C<< $x->inplace >> syntax.
This function is used to overload the binary C<E<lt>E<lt>> operator.
As of 2.065, when calling this function explicitly you can omit
the third argument (see second example), or supply it (see third one).

=for bad

shiftleft processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*shiftleft = \&PDL::shiftleft;





#line 130 "ops.pd"

#line 180 "ops.pd"
{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'>>'} = $overload_sub = sub(;@) {
      goto &PDL::shiftright unless ref $_[1]
              && (ref $_[1] ne 'PDL')
              && defined($foo = overload::Method($_[1], '>>'))
              && $foo != $overload_sub; # recursion guard
      goto &$foo;
  }; }
}

#line 193 "ops.pd"
BEGIN {
# in1, in2, out, swap if true
$OVERLOADS{'>>='} = sub { PDL::shiftright($_[0]->inplace, $_[1]); $_[0] };
}
#line 696 "Ops.pm"

=head2 shiftright

=for sig

  Signature: (a(); b(); [o]c(); int $swap)

=for ref

rightshift C<$a> by C<$b>

=for example

   $c = $x >> $y;        # overloaded call
   $c = shiftright $x, $y;     # explicit call with default swap of 0
   $c = shiftright $x, $y, 1;  # explicit call with trailing 1 to swap args
   $x->inplace->shiftright($y); # modify $x inplace

It can be made to work inplace with the C<< $x->inplace >> syntax.
This function is used to overload the binary C<E<gt>E<gt>> operator.
As of 2.065, when calling this function explicitly you can omit
the third argument (see second example), or supply it (see third one).

=for bad

shiftright processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*shiftright = \&PDL::shiftright;





#line 130 "ops.pd"

#line 180 "ops.pd"
{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'|'} = $overload_sub = sub(;@) {
      goto &PDL::or2 unless ref $_[1]
              && (ref $_[1] ne 'PDL')
              && defined($foo = overload::Method($_[1], '|'))
              && $foo != $overload_sub; # recursion guard
      goto &$foo;
  }; }
}

#line 193 "ops.pd"
BEGIN {
# in1, in2, out, swap if true
$OVERLOADS{'|='} = sub { PDL::or2($_[0]->inplace, $_[1]); $_[0] };
}
#line 755 "Ops.pm"

=head2 or2

=for sig

  Signature: (a(); b(); [o]c(); int $swap; SV *$ign; int $ign2)

=for ref

binary I<or> of two ndarrays

=for example

   $c = $x | $y;        # overloaded call
   $c = or2 $x, $y;     # explicit call with default swap of 0
   $c = or2 $x, $y, 1;  # explicit call with trailing 1 to swap args
   $x->inplace->or2($y); # modify $x inplace

It can be made to work inplace with the C<< $x->inplace >> syntax.
This function is used to overload the binary C<|> operator.
As of 2.065, when calling this function explicitly you can omit
the third argument (see second example), or supply it (see third one).

=for bad

or2 processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*or2 = \&PDL::or2;





#line 130 "ops.pd"

#line 180 "ops.pd"
{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'&'} = $overload_sub = sub(;@) {
      goto &PDL::and2 unless ref $_[1]
              && (ref $_[1] ne 'PDL')
              && defined($foo = overload::Method($_[1], '&'))
              && $foo != $overload_sub; # recursion guard
      goto &$foo;
  }; }
}

#line 193 "ops.pd"
BEGIN {
# in1, in2, out, swap if true
$OVERLOADS{'&='} = sub { PDL::and2($_[0]->inplace, $_[1]); $_[0] };
}
#line 814 "Ops.pm"

=head2 and2

=for sig

  Signature: (a(); b(); [o]c(); int $swap; SV *$ign; int $ign2)

=for ref

binary I<and> of two ndarrays

=for example

   $c = $x & $y;        # overloaded call
   $c = and2 $x, $y;     # explicit call with default swap of 0
   $c = and2 $x, $y, 1;  # explicit call with trailing 1 to swap args
   $x->inplace->and2($y); # modify $x inplace

It can be made to work inplace with the C<< $x->inplace >> syntax.
This function is used to overload the binary C<&> operator.
As of 2.065, when calling this function explicitly you can omit
the third argument (see second example), or supply it (see third one).

=for bad

and2 processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*and2 = \&PDL::and2;





#line 130 "ops.pd"

#line 180 "ops.pd"
{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'^'} = $overload_sub = sub(;@) {
      goto &PDL::xor unless ref $_[1]
              && (ref $_[1] ne 'PDL')
              && defined($foo = overload::Method($_[1], '^'))
              && $foo != $overload_sub; # recursion guard
      goto &$foo;
  }; }
}

#line 193 "ops.pd"
BEGIN {
# in1, in2, out, swap if true
$OVERLOADS{'^='} = sub { PDL::xor($_[0]->inplace, $_[1]); $_[0] };
}
#line 873 "Ops.pm"

=head2 xor

=for sig

  Signature: (a(); b(); [o]c(); int $swap; SV *$ign; int $ign2)

=for ref

binary I<exclusive or> of two ndarrays

=for example

   $c = $x ^ $y;        # overloaded call
   $c = xor $x, $y;     # explicit call with default swap of 0
   $c = xor $x, $y, 1;  # explicit call with trailing 1 to swap args
   $x->inplace->xor($y); # modify $x inplace

It can be made to work inplace with the C<< $x->inplace >> syntax.
This function is used to overload the binary C<^> operator.
As of 2.065, when calling this function explicitly you can omit
the third argument (see second example), or supply it (see third one).

=for bad

xor processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*xor = \&PDL::xor;





#line 307 "ops.pd"

#line 176 "ops.pd"
BEGIN { $OVERLOADS{'~'} = sub { PDL::bitnot($_[0]) } }
#line 917 "Ops.pm"

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





#line 239 "ops.pd"

#line 180 "ops.pd"
{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'**'} = $overload_sub = sub(;@) {
      goto &PDL::power unless ref $_[1]
              && (ref $_[1] ne 'PDL')
              && defined($foo = overload::Method($_[1], '**'))
              && $foo != $overload_sub; # recursion guard
      goto &$foo;
  }; }
}

#line 193 "ops.pd"
BEGIN {
# in1, in2, out, swap if true
$OVERLOADS{'**='} = sub { PDL::power($_[0]->inplace, $_[1]); $_[0] };
}
#line 972 "Ops.pm"

=head2 power

=for sig

  Signature: (a(); b(); [o]c(); int $swap)

=for ref

raise ndarray C<$a> to the power C<$b>

=for example

   $c = $x->power($y);    # explicit call with default swap of 0
   $c = $x->power($y, 1); # explicit call with trailing 1 to swap args
   $c = $a ** $b;    # overloaded use
   $x->inplace->power($y,0);     # modify $x inplace

It can be made to work inplace with the C<$x-E<gt>inplace> syntax.
This function is used to overload the binary C<**> function.
As of 2.065, when calling this function explicitly you can omit
the third argument (see first example), or supply it (see second one).

=for bad

power processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*power = \&PDL::power;





#line 239 "ops.pd"

#line 180 "ops.pd"
{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'atan2'} = $overload_sub = sub(;@) {
      goto &PDL::atan2 unless ref $_[1]
              && (ref $_[1] ne 'PDL')
              && defined($foo = overload::Method($_[1], 'atan2'))
              && $foo != $overload_sub; # recursion guard
      goto &$foo;
  }; }
}
#line 1025 "Ops.pm"

=head2 atan2

=for sig

  Signature: (a(); b(); [o]c(); int $swap)

=for ref

elementwise C<atan2> of two ndarrays

=for example

   $c = $x->atan2($y);    # explicit call with default swap of 0
   $c = $x->atan2($y, 1); # explicit call with trailing 1 to swap args
   $c = atan2 $a, $b;    # overloaded use
   $x->inplace->atan2($y,0);     # modify $x inplace

It can be made to work inplace with the C<$x-E<gt>inplace> syntax.
This function is used to overload the binary C<atan2> function.
As of 2.065, when calling this function explicitly you can omit
the third argument (see first example), or supply it (see second one).

=for bad

atan2 processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*atan2 = \&PDL::atan2;





#line 239 "ops.pd"

#line 180 "ops.pd"
{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'%'} = $overload_sub = sub(;@) {
      goto &PDL::modulo unless ref $_[1]
              && (ref $_[1] ne 'PDL')
              && defined($foo = overload::Method($_[1], '%'))
              && $foo != $overload_sub; # recursion guard
      goto &$foo;
  }; }
}

#line 193 "ops.pd"
BEGIN {
# in1, in2, out, swap if true
$OVERLOADS{'%='} = sub { PDL::modulo($_[0]->inplace, $_[1]); $_[0] };
}
#line 1084 "Ops.pm"

=head2 modulo

=for sig

  Signature: (a(); b(); [o]c(); int $swap)

=for ref

elementwise C<modulo> operation

=for example

   $c = $x->modulo($y);    # explicit call with default swap of 0
   $c = $x->modulo($y, 1); # explicit call with trailing 1 to swap args
   $c = $a % $b;    # overloaded use
   $x->inplace->modulo($y,0);     # modify $x inplace

It can be made to work inplace with the C<$x-E<gt>inplace> syntax.
This function is used to overload the binary C<%> function.
As of 2.065, when calling this function explicitly you can omit
the third argument (see first example), or supply it (see second one).

=for bad

modulo processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*modulo = \&PDL::modulo;





#line 239 "ops.pd"

#line 180 "ops.pd"
{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'<=>'} = $overload_sub = sub(;@) {
      goto &PDL::spaceship unless ref $_[1]
              && (ref $_[1] ne 'PDL')
              && defined($foo = overload::Method($_[1], '<=>'))
              && $foo != $overload_sub; # recursion guard
      goto &$foo;
  }; }
}
#line 1137 "Ops.pm"

=head2 spaceship

=for sig

  Signature: (a(); b(); [o]c(); int $swap)

=for ref

elementwise "<=>" operation

=for example

   $c = $x->spaceship($y);    # explicit call with default swap of 0
   $c = $x->spaceship($y, 1); # explicit call with trailing 1 to swap args
   $c = $a <=> $b;    # overloaded use
   $x->inplace->spaceship($y,0);     # modify $x inplace

It can be made to work inplace with the C<$x-E<gt>inplace> syntax.
This function is used to overload the binary C<E<lt>=E<gt>> function.
As of 2.065, when calling this function explicitly you can omit
the third argument (see first example), or supply it (see second one).

=for bad

spaceship processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*spaceship = \&PDL::spaceship;





#line 307 "ops.pd"

#line 176 "ops.pd"
BEGIN { $OVERLOADS{'sqrt'} = sub { PDL::sqrt($_[0]) } }
#line 1181 "Ops.pm"

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





#line 307 "ops.pd"

#line 176 "ops.pd"
BEGIN { $OVERLOADS{'sin'} = sub { PDL::sin($_[0]) } }
#line 1221 "Ops.pm"

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





#line 307 "ops.pd"

#line 176 "ops.pd"
BEGIN { $OVERLOADS{'cos'} = sub { PDL::cos($_[0]) } }
#line 1261 "Ops.pm"

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





#line 307 "ops.pd"

#line 176 "ops.pd"
BEGIN { $OVERLOADS{'!'} = sub { PDL::not($_[0]) } }
#line 1301 "Ops.pm"

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





#line 307 "ops.pd"

#line 176 "ops.pd"
BEGIN { $OVERLOADS{'exp'} = sub { PDL::exp($_[0]) } }
#line 1341 "Ops.pm"

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





#line 307 "ops.pd"

#line 176 "ops.pd"
BEGIN { $OVERLOADS{'log'} = sub { PDL::log($_[0]) } }
#line 1381 "Ops.pm"

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

Returns the real part of a complex number. Flows data back & forth.

=for bad

re processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*re = \&PDL::re;






=head2 im

=for sig

  Signature: (complexv(); real [o]b())

=for ref

Returns the imaginary part of a complex number. Flows data back & forth.

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

assgn processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

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

   $c = $x->ipow($y);     # as method
   $c = ipow $x, $y;
   $x->inplace->ipow($y);  # modify $x inplace

It can be made to work inplace with the C<$x-E<gt>inplace> syntax.

Algorithm from L<Wikipedia|http://en.wikipedia.org/wiki/Exponentiation_by_squaring>

=for bad

ipow does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*ipow = \&PDL::ipow;





#line 567 "ops.pd"

=head2 abs

=for ref

Returns the absolute value of a number.

=cut

sub PDL::abs { $_[0]->type->real ? goto &PDL::_rabs : goto &PDL::_cabs }

#line 176 "ops.pd"
BEGIN { $OVERLOADS{'abs'} = sub { PDL::abs($_[0]) } }
#line 581 "ops.pd"

=head2 abs2

=for ref

Returns the square of the absolute value of a number.

=cut

sub PDL::abs2 ($) { my $r = &PDL::abs; $r * $r }
#line 1726 "Ops.pm"

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





#line 624 "ops.pd"

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
  use overload %OVERLOADS,
    "eq"    => PDL::Ops::warn_non_numeric_op_wrapper(\&PDL::eq, 'eq'),
    ".="    => sub {
      my @args = !$_[2] ? @_[1,0] : @_[0,1];
      PDL::Ops::assgn(@args);
      return $args[1];
    },
    '++' => sub { $_[0] += 1 },
    '--' => sub { $_[0] -= 1 },
    ;
}

#line 49 "ops.pd"
=head1 AUTHOR

Tuomas J. Lukka (lukka@fas.harvard.edu),
Karl Glazebrook (kgb@aaoepp.aao.gov.au),
Doug Hunt (dhunt@ucar.edu),
Christian Soeller (c.soeller@auckland.ac.nz),
Doug Burke (burke@ifa.hawaii.edu),
and Craig DeForest (deforest@boulder.swri.edu).

=cut
#line 1838 "Ops.pm"

# Exit with OK status

1;

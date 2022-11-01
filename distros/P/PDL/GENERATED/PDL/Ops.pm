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




#line 132 "ops.pd"

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
#line 84 "Ops.pm"



#line 949 "../../blib/lib/PDL/PP.pm"



=head2 plus

=for sig

  Signature: (a(); b(); [o]c(); int swap)

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
#line 123 "Ops.pm"



#line 951 "../../blib/lib/PDL/PP.pm"

*plus = \&PDL::plus;
#line 130 "Ops.pm"



#line 132 "ops.pd"

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
#line 150 "Ops.pm"



#line 949 "../../blib/lib/PDL/PP.pm"



=head2 mult

=for sig

  Signature: (a(); b(); [o]c(); int swap)

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
#line 189 "Ops.pm"



#line 951 "../../blib/lib/PDL/PP.pm"

*mult = \&PDL::mult;
#line 196 "Ops.pm"



#line 132 "ops.pd"

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
#line 216 "Ops.pm"



#line 949 "../../blib/lib/PDL/PP.pm"



=head2 minus

=for sig

  Signature: (a(); b(); [o]c(); int swap)

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
#line 255 "Ops.pm"



#line 951 "../../blib/lib/PDL/PP.pm"

*minus = \&PDL::minus;
#line 262 "Ops.pm"



#line 132 "ops.pd"

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
#line 282 "Ops.pm"



#line 949 "../../blib/lib/PDL/PP.pm"



=head2 divide

=for sig

  Signature: (a(); b(); [o]c(); int swap)

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
#line 321 "Ops.pm"



#line 951 "../../blib/lib/PDL/PP.pm"

*divide = \&PDL::divide;
#line 328 "Ops.pm"



#line 132 "ops.pd"

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
#line 344 "Ops.pm"



#line 949 "../../blib/lib/PDL/PP.pm"



=head2 gt

=for sig

  Signature: (a(); b(); [o]c(); int swap)

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
#line 383 "Ops.pm"



#line 951 "../../blib/lib/PDL/PP.pm"

*gt = \&PDL::gt;
#line 390 "Ops.pm"



#line 132 "ops.pd"

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
#line 406 "Ops.pm"



#line 949 "../../blib/lib/PDL/PP.pm"



=head2 lt

=for sig

  Signature: (a(); b(); [o]c(); int swap)

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
#line 445 "Ops.pm"



#line 951 "../../blib/lib/PDL/PP.pm"

*lt = \&PDL::lt;
#line 452 "Ops.pm"



#line 132 "ops.pd"

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
#line 468 "Ops.pm"



#line 949 "../../blib/lib/PDL/PP.pm"



=head2 le

=for sig

  Signature: (a(); b(); [o]c(); int swap)

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
#line 507 "Ops.pm"



#line 951 "../../blib/lib/PDL/PP.pm"

*le = \&PDL::le;
#line 514 "Ops.pm"



#line 132 "ops.pd"

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
#line 530 "Ops.pm"



#line 949 "../../blib/lib/PDL/PP.pm"



=head2 ge

=for sig

  Signature: (a(); b(); [o]c(); int swap)

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
#line 569 "Ops.pm"



#line 951 "../../blib/lib/PDL/PP.pm"

*ge = \&PDL::ge;
#line 576 "Ops.pm"



#line 132 "ops.pd"

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
#line 592 "Ops.pm"



#line 949 "../../blib/lib/PDL/PP.pm"



=head2 eq

=for sig

  Signature: (a(); b(); [o]c(); int swap)

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
#line 631 "Ops.pm"



#line 951 "../../blib/lib/PDL/PP.pm"

*eq = \&PDL::eq;
#line 638 "Ops.pm"



#line 132 "ops.pd"

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
#line 654 "Ops.pm"



#line 949 "../../blib/lib/PDL/PP.pm"



=head2 ne

=for sig

  Signature: (a(); b(); [o]c(); int swap)

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
#line 693 "Ops.pm"



#line 951 "../../blib/lib/PDL/PP.pm"

*ne = \&PDL::ne;
#line 700 "Ops.pm"



#line 132 "ops.pd"

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
#line 720 "Ops.pm"



#line 949 "../../blib/lib/PDL/PP.pm"



=head2 shiftleft

=for sig

  Signature: (a(); b(); [o]c(); int swap)

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
#line 759 "Ops.pm"



#line 951 "../../blib/lib/PDL/PP.pm"

*shiftleft = \&PDL::shiftleft;
#line 766 "Ops.pm"



#line 132 "ops.pd"

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
#line 786 "Ops.pm"



#line 949 "../../blib/lib/PDL/PP.pm"



=head2 shiftright

=for sig

  Signature: (a(); b(); [o]c(); int swap)

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
#line 825 "Ops.pm"



#line 951 "../../blib/lib/PDL/PP.pm"

*shiftright = \&PDL::shiftright;
#line 832 "Ops.pm"



#line 132 "ops.pd"

{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'|'} = $overload_sub = sub(;@) {
      return PDL::or2($_[2]?@_[1,0]:@_[0,1]) unless ref $_[1]
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
#line 852 "Ops.pm"



#line 949 "../../blib/lib/PDL/PP.pm"



=head2 or2

=for sig

  Signature: (a(); b(); [o]c(); int swap)

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
#line 891 "Ops.pm"



#line 951 "../../blib/lib/PDL/PP.pm"

*or2 = \&PDL::or2;
#line 898 "Ops.pm"



#line 132 "ops.pd"

{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'&'} = $overload_sub = sub(;@) {
      return PDL::and2($_[2]?@_[1,0]:@_[0,1]) unless ref $_[1]
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
#line 918 "Ops.pm"



#line 949 "../../blib/lib/PDL/PP.pm"



=head2 and2

=for sig

  Signature: (a(); b(); [o]c(); int swap)

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
#line 957 "Ops.pm"



#line 951 "../../blib/lib/PDL/PP.pm"

*and2 = \&PDL::and2;
#line 964 "Ops.pm"



#line 132 "ops.pd"

{
  my ($foo, $overload_sub);
  BEGIN { $OVERLOADS{'^'} = $overload_sub = sub(;@) {
      return PDL::xor($_[2]?@_[1,0]:@_[0,1]) unless ref $_[1]
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
#line 984 "Ops.pm"



#line 949 "../../blib/lib/PDL/PP.pm"



=head2 xor

=for sig

  Signature: (a(); b(); [o]c(); int swap)

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
#line 1023 "Ops.pm"



#line 951 "../../blib/lib/PDL/PP.pm"

*xor = \&PDL::xor;
#line 1030 "Ops.pm"



#line 308 "ops.pd"

BEGIN { $OVERLOADS{'~'} = sub { PDL::bitnot($_[0]) } }
#line 1037 "Ops.pm"



#line 949 "../../blib/lib/PDL/PP.pm"



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
#line 1072 "Ops.pm"



#line 951 "../../blib/lib/PDL/PP.pm"

*bitnot = \&PDL::bitnot;
#line 1079 "Ops.pm"



#line 241 "ops.pd"

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
#line 1099 "Ops.pm"



#line 949 "../../blib/lib/PDL/PP.pm"



=head2 power

=for sig

  Signature: (a(); b(); [o]c(); int swap)

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
#line 1138 "Ops.pm"



#line 951 "../../blib/lib/PDL/PP.pm"

*power = \&PDL::power;
#line 1145 "Ops.pm"



#line 241 "ops.pd"

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
#line 1161 "Ops.pm"



#line 949 "../../blib/lib/PDL/PP.pm"



=head2 atan2

=for sig

  Signature: (a(); b(); [o]c(); int swap)

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
#line 1200 "Ops.pm"



#line 951 "../../blib/lib/PDL/PP.pm"

*atan2 = \&PDL::atan2;
#line 1207 "Ops.pm"



#line 241 "ops.pd"

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
#line 1227 "Ops.pm"



#line 949 "../../blib/lib/PDL/PP.pm"



=head2 modulo

=for sig

  Signature: (a(); b(); [o]c(); int swap)

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
#line 1266 "Ops.pm"



#line 951 "../../blib/lib/PDL/PP.pm"

*modulo = \&PDL::modulo;
#line 1273 "Ops.pm"



#line 241 "ops.pd"

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
#line 1289 "Ops.pm"



#line 949 "../../blib/lib/PDL/PP.pm"



=head2 spaceship

=for sig

  Signature: (a(); b(); [o]c(); int swap)

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
#line 1328 "Ops.pm"



#line 951 "../../blib/lib/PDL/PP.pm"

*spaceship = \&PDL::spaceship;
#line 1335 "Ops.pm"



#line 308 "ops.pd"

BEGIN { $OVERLOADS{'sqrt'} = sub { PDL::sqrt($_[0]) } }
#line 1342 "Ops.pm"



#line 949 "../../blib/lib/PDL/PP.pm"



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
#line 1377 "Ops.pm"



#line 951 "../../blib/lib/PDL/PP.pm"

*sqrt = \&PDL::sqrt;
#line 1384 "Ops.pm"



#line 308 "ops.pd"

BEGIN { $OVERLOADS{'sin'} = sub { PDL::sin($_[0]) } }
#line 1391 "Ops.pm"



#line 949 "../../blib/lib/PDL/PP.pm"



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
#line 1426 "Ops.pm"



#line 951 "../../blib/lib/PDL/PP.pm"

*sin = \&PDL::sin;
#line 1433 "Ops.pm"



#line 308 "ops.pd"

BEGIN { $OVERLOADS{'cos'} = sub { PDL::cos($_[0]) } }
#line 1440 "Ops.pm"



#line 949 "../../blib/lib/PDL/PP.pm"



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
#line 1475 "Ops.pm"



#line 951 "../../blib/lib/PDL/PP.pm"

*cos = \&PDL::cos;
#line 1482 "Ops.pm"



#line 308 "ops.pd"

BEGIN { $OVERLOADS{'!'} = sub { PDL::not($_[0]) } }
#line 1489 "Ops.pm"



#line 949 "../../blib/lib/PDL/PP.pm"



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
#line 1524 "Ops.pm"



#line 951 "../../blib/lib/PDL/PP.pm"

*not = \&PDL::not;
#line 1531 "Ops.pm"



#line 308 "ops.pd"

BEGIN { $OVERLOADS{'exp'} = sub { PDL::exp($_[0]) } }
#line 1538 "Ops.pm"



#line 949 "../../blib/lib/PDL/PP.pm"



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
#line 1573 "Ops.pm"



#line 951 "../../blib/lib/PDL/PP.pm"

*exp = \&PDL::exp;
#line 1580 "Ops.pm"



#line 308 "ops.pd"

BEGIN { $OVERLOADS{'log'} = sub { PDL::log($_[0]) } }
#line 1587 "Ops.pm"



#line 949 "../../blib/lib/PDL/PP.pm"



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
#line 1622 "Ops.pm"



#line 951 "../../blib/lib/PDL/PP.pm"

*log = \&PDL::log;
#line 1629 "Ops.pm"



#line 949 "../../blib/lib/PDL/PP.pm"



=head2 re

=for sig

  Signature: (complexv(); real [o]b())

=for ref

Returns the real part of a complex number.

=for bad

re processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1654 "Ops.pm"



#line 951 "../../blib/lib/PDL/PP.pm"

*re = \&PDL::re;
#line 1661 "Ops.pm"



#line 949 "../../blib/lib/PDL/PP.pm"



=head2 im

=for sig

  Signature: (complexv(); real [o]b())

=for ref

Returns the imaginary part of a complex number.

=for bad

im processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1686 "Ops.pm"



#line 951 "../../blib/lib/PDL/PP.pm"

*im = \&PDL::im;
#line 1693 "Ops.pm"



#line 949 "../../blib/lib/PDL/PP.pm"



=head2 _cabs

=for sig

  Signature: (complexv(); real [o]b())

=for ref

Returns the absolute (length) of a complex number.

=for bad

_cabs processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1718 "Ops.pm"



#line 951 "../../blib/lib/PDL/PP.pm"
#line 1723 "Ops.pm"



#line 951 "../../blib/lib/PDL/PP.pm"
#line 1728 "Ops.pm"



#line 949 "../../blib/lib/PDL/PP.pm"



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
#line 1763 "Ops.pm"



#line 950 "../../blib/lib/PDL/PP.pm"


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
#line 1786 "Ops.pm"



#line 951 "../../blib/lib/PDL/PP.pm"

*log10 = \&PDL::log10;
#line 1793 "Ops.pm"



#line 949 "../../blib/lib/PDL/PP.pm"



=head2 assgn

=for sig

  Signature: (a(); [o]b())

=for ref

Plain numerical assignment. This is used to implement the ".=" operator

=for bad

assgn processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1818 "Ops.pm"



#line 951 "../../blib/lib/PDL/PP.pm"

*assgn = \&PDL::assgn;
#line 1825 "Ops.pm"



#line 949 "../../blib/lib/PDL/PP.pm"



=head2 carg

=for sig

  Signature: (complexv(); real [o]b())

=for ref

Returns the polar angle of a complex number.

=for bad

carg processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1850 "Ops.pm"



#line 951 "../../blib/lib/PDL/PP.pm"

*carg = \&PDL::carg;
#line 1857 "Ops.pm"



#line 949 "../../blib/lib/PDL/PP.pm"



=head2 conj

=for sig

  Signature: (complexv();  [o]b())

=for ref

complex conjugate.

=for bad

conj processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 1882 "Ops.pm"



#line 951 "../../blib/lib/PDL/PP.pm"

*conj = \&PDL::conj;
#line 1889 "Ops.pm"



#line 949 "../../blib/lib/PDL/PP.pm"



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
#line 1915 "Ops.pm"



#line 951 "../../blib/lib/PDL/PP.pm"

*czip = \&PDL::czip;
#line 1922 "Ops.pm"



#line 949 "../../blib/lib/PDL/PP.pm"



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
#line 1960 "Ops.pm"



#line 951 "../../blib/lib/PDL/PP.pm"

*ipow = \&PDL::ipow;
#line 1967 "Ops.pm"



#line 567 "ops.pd"


=head2 abs

=for ref

Returns the absolute value of a number.

=cut

sub PDL::abs { $_[0]->type->real ? goto &PDL::_rabs : goto &PDL::_cabs }
#line 1983 "Ops.pm"



#line 579 "ops.pd"

BEGIN { $OVERLOADS{'abs'} = sub { PDL::abs($_[0]) } }
#line 1990 "Ops.pm"



#line 581 "ops.pd"


=head2 abs2

=for ref

Returns the square of the absolute value of a number.

=cut

sub PDL::abs2 ($) { my $r = &PDL::abs; $r * $r }
#line 2006 "Ops.pm"



#line 949 "../../blib/lib/PDL/PP.pm"



=head2 r2C

=for sig

  Signature: (r(); complex [o]c())

=for ref

convert real to native complex, with an imaginary part of zero

=for bad

r2C does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2031 "Ops.pm"



#line 950 "../../blib/lib/PDL/PP.pm"

sub PDL::r2C ($) {
  return $_[0] if UNIVERSAL::isa($_[0], 'PDL') and !$_[0]->type->real;
  my $r = $_[1] // PDL->nullcreate($_[0]);
  PDL::_r2C_int($_[0], $r);
  $r;
}
#line 2043 "Ops.pm"



#line 951 "../../blib/lib/PDL/PP.pm"

*r2C = \&PDL::r2C;
#line 2050 "Ops.pm"



#line 949 "../../blib/lib/PDL/PP.pm"



=head2 i2C

=for sig

  Signature: (i(); complex [o]c())

=for ref

convert imaginary to native complex, with a real part of zero

=for bad

i2C does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2075 "Ops.pm"



#line 950 "../../blib/lib/PDL/PP.pm"

sub PDL::i2C ($) {
  return $_[0] if UNIVERSAL::isa($_[0], 'PDL') and !$_[0]->type->real;
  my $r = $_[1] // PDL->nullcreate($_[0]);
  PDL::_i2C_int($_[0], $r);
  $r;
}
#line 2087 "Ops.pm"



#line 951 "../../blib/lib/PDL/PP.pm"

*i2C = \&PDL::i2C;
#line 2094 "Ops.pm"



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
#line 2125 "Ops.pm"





#line 49 "ops.pd"


=head1 AUTHOR

Tuomas J. Lukka (lukka@fas.harvard.edu),
Karl Glazebrook (kgb@aaoepp.aao.gov.au),
Doug Hunt (dhunt@ucar.edu),
Christian Soeller (c.soeller@auckland.ac.nz),
Doug Burke (burke@ifa.hawaii.edu),
and Craig DeForest (deforest@boulder.swri.edu).

=cut
#line 2144 "Ops.pm"




# Exit with OK status

1;

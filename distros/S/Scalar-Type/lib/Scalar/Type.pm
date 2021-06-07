package Scalar::Type;

use strict;
use warnings;

use Carp qw(croak);

our $VERSION = '0.1.1';

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

use Scalar::Util qw(blessed);

use base qw(Exporter);

=head1 NAME

Scalar::Type

=head1 DESCRIPTION

Figure out what type a scalar is

=head1 SYNOPSIS

  use Scalar::Type qw(is_number);

  if(is_number(2)) {
      # yep, 2 is a number
      # it is_integer too
  }

  if(is_number("2")) {
      # no, "2" is a string
  }

=head1 OVERVIEW

Perl scalars can be either strings or numbers, and normally you don't really
care which is which as it will do all the necessary type conversions automagically.
This means that you can perform numeric operations on strings and provided that they
B<looks like> a number you'll get a sensible result:

    my $string = "4";
    my $number = 1;
    my $result = $string + $number; # 5

But in some rare cases, generally when you are serialising data, the difference
matters. This package provides some useful functions to help you figure out what's
what. The following functions are available. None of them are exported by default.
If you want them all, export ':all':

    use Scalar::Type qw(:all);

and if you just want the 'is_*' functions you can get them all in one go:

    use Scalar::Type qw(is_*);

For Reasons, C<:is_*> is equivalent.

=cut

our @EXPORT_OK = qw(
    type is_integer is_number
);
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
    'is_*' => [grep { /^is_/ } @EXPORT_OK]
);

sub import {
    __PACKAGE__->export_to_level(1, map { $_ eq 'is_*' ? ':is_*' : $_ } @_);
}

=head1 FUNCTIONS

All of these functions require an argument. It is a fatal error to call
them without.

=head2 type

Returns the type of its argument. If the argument is a reference then it
returns either C<blessed($argument)> (if it's an object),
C<'REF_TO_'.ref($argument)>, or C<'UNDEF'> for undefined values. Otherwise it
looks for the IOK or NOK flags on the underlying SV (see <L/"GORY DETAILS"> for
the exact mechanics) and returns C<INTEGER> or C<NUMBER> as appropriate.
Finally, if neither of those are set it returns C<SCALAR>.

=cut

sub type {
    croak(__PACKAGE__."::type requires an argument") if($#_ == -1);
    my $arg = shift;
    return blessed($arg)  ? blessed($arg)       :
           ref($arg)      ? 'REF_TO_'.ref($arg) :
           !defined($arg) ? 'UNDEF'             :
                            _scalar_type($arg);
}

=head2 is_integer

Returns true if its argument is an integer. Note that "1" is not an integer, it
is a string. 1 is an integer. 1.1 is obviously not an integer. 1.0 is also not
an integer, as it makes a different statement about precision - 1 is *exactly*
one, but 1.0 is only one to two significant figures.

All integers are of course also numbers.

=cut

sub is_integer {
    croak(__PACKAGE__."::is_integer requires an argument") if($#_ == -1);
    type(@_) eq 'INTEGER' ? 1 : 0;
}

=head2 is_number

Returns true if its argument is a number. "1" is not a number, it is a string.
1 is a number. 1.0 and 1.1 are numbers too.

=cut

sub is_number {
    croak(__PACKAGE__."::is_number requires an argument") if($#_ == -1);
    is_integer(@_) || type(@_) eq 'NUMBER' ? 1 : 0;
}

=head1 GORY DETAILS

=head2 PERL VARIABLE INTERNALS

As far as Perl code is concerned scalars will present themselves as integers,
floats or strings on demand. Internally scalars are stored in a C structure,
called an SV (scalar value), which contains several slots. The important ones
for our purposes are:

=over

=item IV

an integer value

=item NV

a numeric value (ie a float)

=item PV

a pointer value (ie a string)

=back

When a value is created one of those slots will be filled. As various
operations are done on a value the slot's contents may change, and other
slots may be filled.

For example:

    my $foo = "4";        # fill $foo's PV slot, as "4" is a string

    my $bar = $foo + 1;   # fill $bar's IV slot, as 4 + 1 is an int,
                          # and fill $foo's IV slot, as we had to figure
                          # out the numeric value of the string

    $foo = "lemon";       # fill $foo's PV slot, as "lemon" is a string

That last operation immediately shows a problem. C<$foo>'s IV slot was
filled with the integer value C<4>, but the assignment of the string
C<"lemon"> only filled the PV slot. So what's in the IV slot? There's a
handy tool for that, L<Devel::Peek>, which is distributed with perl.
Here's part of Devel::Peek's output:

    $ perl -MDevel::Peek -E 'my $foo = 4; $foo = "lemon"; Dump($foo);'
      IV = 4
      PV = 0x7fe6e6c04c90 "lemon"\0

So how, then, does perl know that even thought there's a value in the IV
slot it shouldn't be used? Because once you've assigned C<"lemon"> to
the variable you can't get that C<4> to show itself ever again, at least
not from pure perl code.

The SV also has a flags field, which I missed out above. (I've also missed
out some of the flags here, I'm only showing you the relevant ones):

    $ perl -MDevel::Peek -E 'my $foo = 4; $foo = "lemon"; Dump($foo);'
      FLAGS = (POK)
      IV = 4
      PV = 0x7fe6e6c04c90 "lemon"\0

The C<POK> flag means, as you might have guessed, that the C<PV> slot has
valid contents - in case you're wondering, the C<PV> slot there contains
a pointer to the memory address C<0x7fe6e6c04c90>, at which can be found
the word C<lemon>.

It's possible to have multiple flags set. That's the case in the second
line of code in the example. In that example a variable contains the
string C<"4">, so the C<PV> slot is filled and the C<POK> flag is set. We
then take the value of that variable, add 1, and assign the result to
another variable. Obviously adding 1 to a string is meaningless, so the
string has to first be converted to a number. That fills the C<IV> slot:

    $ perl -MDevel::Peek -E 'my $foo = "4"; my $bar = $foo + 1; Dump($foo);'
      FLAGS = (IOK,POK)
      IV = 4
      PV = 0x7fd6e7d05210 "4"\0

Notice that there are now two flags. C<IOK> means that the C<IV> slot's
contents are valid, and C<POK> that the C<PV> slot's contents are valid.
Why do we need both slots in this case? Because a non-numeric string such
as C<"lemon"> is treated as the integer C<0> if you perform numeric
operations on it.

All that I have said above about C<IV>s also applies to C<NV>s, and you
will sometimes come across a variable with both the C<IV> and C<NV> slots
filled, or even all three:

    $ perl -MDevel::Peek -E 'my $foo = 1e2; my $bar = $foo + 0; $bar = $foo . ""; Dump($foo)'
      FLAGS = (IOK,NOK,POK)
      IV = 100
      NV = 100
      PV = 0x7f9ee9d12790 "100"\0

Finally, it's possible to have multiple flags set even though the slots
contain what looks (to a human) like different values:

    $ perl -MDevel::Peek -E 'my $foo = "007"; $foo + 0; Dump($foo)'
      FLAGS = (IOK,POK)
      IV = 7
      PV = 0x7fcf425046c0 "007"\0

That code initialises the variable to the string C<"007">, then uses it
in a numeric operation. That causes the string to be numified, the C<IV>
slot to be filled, and the C<IOK> flag set. It should, of course, be clear
to any fan of classic literature that "007" and 7 are very different things.
"007" is not an integer.

=head2 WHAT Scalar::Type DOES (at least in version 0.1.0)

NB that this section documents an internal function that is not intended
for public use. The interface of C<_scalar_type> should be considered to
be unstable, not fit for human consumption, and subject to change without
notice. This documentation is correct as of version 0.1.0 but may not be
updated for future versions - its purpose is pedagogical only.

The C<is_*> functions are just wrappers around the C<type> function. That
in turn delegates most of the work to a few lines of C code which grovel
around looking at the contents of the individual slots and flags. That
function isn't exported, but if you really want to call it directly it's
called C<_scalar_type> and will return one of four strings, C<INTEGER>,
C<NUMBER>, or C<SCALAR>. It will return C<SCALAR> even for a reference or
undef, which is why I said that the C<type> function only *mostly* wraps
around it :-)

The first thing that C<_scalar_type> does is look at the C<IOK> flag.
If it's set, and the C<POK> flag is not set, the it returns C<INTEGER>.
If C<IOK> and C<POK> are set it stringifies the contents of the C<IV> slot,
compares to the contents of the C<PV> slot, and returns C<INTEGER> if
they are the same, or C<SCALAR> otherwise.

The reason for jumping through those hoops is so that we can correctly
divine the type of C<"007"> in the last example above.

If C<IOK> isn't set we then look at C<NOK>. That follows exactly the same
logic, looking also at C<POK>, and returning either C<NUMBER> or C<SCALAR>,
being careful about strings like C<"007.5">.

If neither C<IOK> nor C<NOK> is set then we return C<SCALAR>.

=head1 SEE ALSO

L<Scalar::Util> in particular its C<blessed> function.

=head1 BUGS

If you find any bugs please report them on Github, preferably with a test case.

Integers that are specifed using exponential notation, such as if you say 1e2
instead of 100, are *not* internally treated as integers. The perl parser is
lazy and only bothers to convert them into an integer after you perform int-ish
operations on them, such as adding 0. Likewise if you add 0 to the thoroughly
non-numeric "100" perl will convert it to an integer. These edge cases are partly
why you almost certainly don't care about what this module does. If they irk
you, complain to p5p.

=head1 FEEDBACK

I welcome feedback about my code, especially constructive criticism.

=head1 AUTHOR, COPYRIGHT and LICENCE

Copyright 2021 David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

This software is free-as-in-speech software, and may be used,
distributed, and modified under the terms of either the GNU
General Public Licence version 2 or the Artistic Licence. It's
up to you which one you use. The full text of the licences can
be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

1;

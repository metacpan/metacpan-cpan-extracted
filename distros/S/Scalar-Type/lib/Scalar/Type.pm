package Scalar::Type;

use strict;
use warnings;

use Scalar::Util qw(blessed);

use base qw(Exporter);

our $VERSION = '0.0.2';

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
    type is_integer is_number is_string
);
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
    'is_*' => [grep { /^is_/ } @EXPORT_OK]
);

sub import {
    __PACKAGE__->export_to_level(1, map { $_ eq 'is_*' ? ':is_*' : $_ } @_);
}

=head1 FUNCTIONS

=head2 type

Returns the type of its argument. If the argument is a reference then it returns
either C<blessed($argument)> (if it's an object) or C<'REF_TO_'.ref($argument)>.
Otherwise it looks for the IOK or NOK flags on the underlying SV and returns
C<INTEGER> or C<NUMBER> as appropriate. Finally, if neither of those are set it
returns C<SCALAR>.

=cut

sub type {
    my $arg = shift || undef;
    return blessed($arg) ? blessed($arg)       :
           ref($arg)     ? 'REF_TO_'.ref($arg) :
                           _scalar_type($arg);
}

use Inline C => <<'END_OF_C';

// Unfortunately this would also promote 1.0 to an int, which we don't want.
// We want to only do that for 1e2 and friends, and that means we have to get
// our oar in rather earlier, in toke.c
// 
// void _attempt_int_promote(SV* argument) {
//     if(SvNOK(argument) && !SvIOK(argument)) {
//         /* retrieve the 'double' value from the NV slot and get an
//            equivalent int, losing anything after the decimal point
//         */
//         NV nv = SvNVX(argument);
//         IV potential_iv = (IV)nv;
//         
//         int SV_is_readonly = SvREADONLY(argument);
// 
//         /* now turn the int back into a double and if it's the same
//            as what we started with, fill in the IV slot
//         */
//         if((NV)potential_iv == nv) {
//             if(SV_is_readonly) { SvREADONLY_off(argument); }
//             SvIV_set(argument, potential_iv);
//             SvIOK_on(argument);
//             if(SV_is_readonly) { SvREADONLY_on(argument); }
//         }
//     }
// }

SV* _scalar_type(SV* argument) {
    // /* handle nonsense like 1e2 being recognised by perl as a number but not an int */
    // _attempt_int_promote(argument);

    return SvIOK(argument) ? newSVpv("INTEGER", 7) :
           SvNOK(argument) ? newSVpv("NUMBER",  6) : 
                             newSVpv("SCALAR",  6);
}

END_OF_C

=head2 is_integer

Returns true if its argument is an integer. Note that "1" is not an integer, it
is a string. 1 is an integer. 1.1 is obviously not an integer. 1.0 is also not
an integer, as it makes a different statement about precision - 1 is *exactly*
one, but 1.0 is only one to two significant figures.

All integers are of course also numbers.

=cut

sub is_integer {
    my $candidate = shift;
    type($candidate) eq 'INTEGER' ? 1 : 0;
}

=head2 is_number

Returns true if its argument is a number. "1" is not a number, it is a string.
1 is a number. 1.0 and 1.1 are numbers too.

=cut

sub is_number {
    my $candidate = shift;
    is_integer($candidate) || type($candidate) eq 'NUMBER' ? 1 : 0;
}

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

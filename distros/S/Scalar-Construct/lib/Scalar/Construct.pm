=head1 NAME

Scalar::Construct - build custom kinds of scalar

=head1 SYNOPSIS

	use Scalar::Construct qw(constant variable aliasref aliasobj);

	$ref = constant($value);
	$ref = variable($value);
	$ref = aliasref(\$array[0]);
	$ref = aliasobj($array[0]);

=head1 DESCRIPTION

This module supplies functions to construct Perl scalar objects.
While writable (variable) scalars can easily be constructed using the
ordinary facilities of the Perl language, immutable (constant) scalars
require a library such as this.

=cut

package Scalar::Construct;

{ use 5.006; }
use warnings;
use strict;

our $VERSION = "0.000";

use parent "Exporter";
our @EXPORT_OK = qw(constant ro variable rw aliasref ar aliasobj ao);

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

*ro = \&constant;
*rw = \&variable;
*ar = \&aliasref;
*ao = \&aliasobj;

=head1 FUNCTIONS

Each function has two names.  There is a longer descriptive name, and
a shorter name to spare screen space and the programmer's fingers.

=over

=item constant(VALUE)

=item ro(VALUE)

Creates a fresh immutable scalar, with value I<VALUE>, and returns a
reference to it.

If I<VALUE> is actually a compile-time constant that can be expressed
as a literal, such as C<123>, it would appear that a reference to a
constant object with that value can be created by a Perl expression
such as C<\123>.  However, Perl has some bugs relating to compile-time
constants that prevent this working as intended.  On Perls built for
threading (even if threading is not actually used), such a scalar will
be copied at surprising times, losing both its object identity and its
immutability.  The function supplied by this module avoids these problems.

=item variable(VALUE)

=item rw(VALUE)

Creates a fresh writable scalar, initialised to value I<VALUE>, and
returns a reference to it.

=item aliasref(OBJECT_REF)

=item ar(OBJECT_REF)

I<OBJECT_REF> must be a reference to a scalar.  Returns another reference
to the same scalar.  (This is effectively an identity function, included
for completeness.)

Due to the Perl bugs discussed above for L</constant>, it is unwise
to attempt to alias a compile-time constant.  Instead use L</constant>
to create a well-behaved constant scalar.

=item aliasobj(OBJECT)

=item ao(OBJECT)

Returns a reference to I<OBJECT>.

Due to the Perl bugs discussed above for L</constant>, it is unwise
to attempt to alias a compile-time constant.  Instead use L</constant>
to create a well-behaved constant scalar.

=back

=head1 SEE ALSO

L<Lexical::Var>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2012 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

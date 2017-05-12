=head1 NAME

String::Base - string index offseting

=head1 SYNOPSIS

	use String::Base +1;

	no String::Base;

=head1 DESCRIPTION

This module implements automatic offsetting of string indices.  In normal
Perl, the first character of a string has index 0, the second character
has index 1, and so on.  This module allows string indexes to start at
some other value.  Most commonly it is used to give the first character
of a string the index 1 (and the second 2, and so on), to imitate the
indexing behaviour of FORTRAN and many other languages.  It is usually
considered poor style to do this.

The string index offset is controlled at compile time, in a
lexically-scoped manner.  Each block of code, therefore, is subject to
a fixed offset.  It is expected that the affected code is written with
knowledge of what that offset is.

=head2 Using a string index offset

A string index offset is set up by a C<use String::Base> directive, with
the desired offset specified as an argument.  Beware that a bare, unsigned
number in that argument position, such as "C<use String::Base 1>", will
be interpreted as a version number to require of C<String::Base>.  It is
therefore necessary to give the offset a leading sign, or parenthesise
it, or otherwise decorate it.  The offset may be any integer (positive,
zero, or negative) within the range of Perl's integer arithmetic.

A string index offset declaration is in effect from immediately after the
C<use> line, until the end of the enclosing block or until overridden
by another string index offset declaration.  A declared offset always
replaces the previous offset: they do not add.  "C<no String::Base>"
is equivalent to "C<use String::Base +0>": it returns to the Perlish
state with zero offset.

A declared string index offset influences these types of operation:

=over

=item *

substring extraction (C<substr($a, 3, 2)>)

=item *

substring splicing (C<substr $a, 3, 2, "x">)

=item *

substring searching (C<index($a, "x")>, C<index($a, "x", 3)>,
C<rindex($a, "x")>, C<rindex($a, "x", 3)>)

=item *

string iterator position (C<pos($a)>)

=back

Only forwards indexing, relative to the start of the string, is supported.
End-relative indexing, normally done using negative index values, is
not supported when an index offset is in effect.  Use of an index that
is numerically less than the index offset will have unpredictable results.

=head2 Differences from C<$[>

This module is a replacement for the historical L<C<$[>|perlvar/$[>
variable.  In early Perl that variable was a runtime global, affecting all
array and string indexing in the program.  In Perl 5, assignment to C<$[>
acts as a lexically-scoped pragma.  C<$[> is deprecated.  The original
C<$[> was removed in Perl 5.15.3, and later replaced in Perl 5.15.5 by
an automatically-loaded L<arybase> module.  This module reimplements
the index offset feature without any specific support from the core.

Unlike C<$[>, this module does not affect indexing into arrays.  This
module is concerned only with strings.  To influence array indexing,
see L<Array::Base>.

This module does not show the offset value in C<$[> or any other
accessible variable.  With the string offset being lexically scoped,
there should be no need to write code to handle a variable offset.

C<$[> has some predictable, but somewhat strange, behaviour for indexes
less than the offset.  The behaviour differs between substring extraction
and iterator positioning.  This module does not attempt to replicate it,
and does not support end-relative indexing at all.

The string iterator position operator (C<pos($a)>), as implemented
by the Perl core, generates a magical scalar which is linked to the
underlying string.  The numerical value of the scalar varies if the
iterator position of the string is changed, and code with different C<$[>
settings will see accordingly different values.  The scalar can also be
written to, to change the position of the string's iterator, and again
the interpretation of the value written varies according to the C<$[>
setting of the code that is doing the writing.  This module does not
replicate any of that behaviour.  With a string index offset from this
module in effect, C<pos($a)> evaluates to an ordinary rvalue scalar,
giving the position of the string's iterator as it was at the time the
operator was evaluated, according to the string index offset in effect
where the operator appears.

=cut

package String::Base;

{ use 5.008001; }
use Lexical::SealRequireHints 0.006;
use warnings;
use strict;

our $VERSION = "0.001";

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

=head1 PACKAGE METHODS

These methods are meant to be invoked on the C<String::Base> package.

=over

=item String::Base->import(BASE)

Sets up a string index offset of I<BASE>, in the lexical environment
that is currently compiling.

=item String::Base->unimport

Clears the string index offset, in the lexical environment that is
currently compiling.

=back

=head1 BUGS

L<B::Deparse> will generate incorrect source when deparsing code that
uses a string index offset.  It will include both the pragma to set up
the offset and the munged form of the affected operators.  Either the
pragma or the munging is required to get the index offset effect; using
both will double the offset.  Also, the code generated for a string
iterator position (C<pos($a)>) operation involves a custom operator,
which B::Deparse can't understand, so the source it emits in that case
is completely wrong.

The additional operators generated by this module cause spurious warnings
if some of the affected string operations are used in void context.

Prior to Perl 5.9.3, the lexical state of string index offset does not
propagate into string eval.

=head1 SEE ALSO

L<Array::Base>,
L<arybase>,
L<perlvar/$[>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2011, 2012 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

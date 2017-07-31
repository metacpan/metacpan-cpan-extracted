=head1 NAME

Sub::Metadata - read and write subroutine metadata

=head1 SYNOPSIS

    use Sub::Metadata qw(
	sub_body_type
	sub_closure_role
	sub_is_lvalue
	sub_is_constant
	sub_is_method mutate_sub_is_method
	sub_is_debuggable mutate_sub_is_debuggable
	sub_prototype mutate_sub_prototype
	sub_package mutate_sub_package);

    $type = sub_body_type($sub);
    $type = sub_closure_role($sub);
    if(sub_is_lvalue($sub)) { ...
    if(sub_is_constant($sub)) { ...
    if(sub_is_method($sub)) { ...
    mutate_sub_is_method($sub, 1);
    if(sub_is_debuggable($sub)) { ...
    mutate_sub_is_debuggable($sub, 0);
    $proto = sub_prototype($sub);
    mutate_sub_prototype($sub, $proto);
    $pkg = sub_package($sub);
    mutate_sub_package($sub, $pkg);

=head1 DESCRIPTION

This module contains functions that examine and modify data that Perl
attaches to subroutines.

=cut

package Sub::Metadata;

{ use 5.006; }
use warnings;
use strict;

our $VERSION = "0.002";

use parent "Exporter";
our @EXPORT_OK = qw(
	sub_body_type
	sub_closure_role
	sub_is_lvalue
	sub_is_constant
	sub_is_method mutate_sub_is_method
	sub_is_debuggable mutate_sub_is_debuggable
	sub_prototype mutate_sub_prototype
	sub_package mutate_sub_package
);

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

=head1 FUNCTIONS

Each of these functions takes an argument I<SUB>, which must be a
reference to a subroutine.  The function operates on the subroutine
referenced by I<SUB>.

The C<mutate_> functions modify a subroutine in place.  The subroutine's
identity is not changed, but the attributes of the existing subroutine
object are changed.  All references to the existing subroutine will see
the new attributes.  Beware of action at a distance.

=over

=item sub_body_type(SUB)

Returns a keyword indicating the general nature of the implementation
of I<SUB>:

=over

=item B<PERL>

The subroutine's body consists of a network of op nodes for the Perl
interpreter.  Subroutines written in Perl are almost always of this form.

=item B<UNDEF>

The subroutine has no body, and so cannot be successfully called.

=item B<XSUB>

The subroutine's body consists of native machine code.  Usually these
subroutines have been mainly written in C.  Constant-valued subroutines
written in Perl can also acquire this type of body.

=back

=item sub_closure_role(SUB)

Returns a keyword indicating the status of I<SUB> with respect to the
generation of closures in the Perl language:

=over

=item B<CLOSURE>

The subroutine is a closure: it was generated from Perl code referencing
external lexical variables, and now references a particular set of those
variables to make up a complete subroutine.

=item B<PROTOTYPE>

The subroutine is a prototype for closures: it consists of Perl code
referencing external lexical variables, and has not been attached to a
particular set of those variables.  This is not a complete subroutine
and cannot be successfully called.  It is an oddity of Perl that this
type of object is represented as if it were a subroutine, and the
situations where one can get access to this kind of object are rare.
Prototype subroutines will mainly be encountered by attribute handlers.

=item B<STANDALONE>

The subroutine is independent of external lexical variables.

=back

=item sub_is_lvalue(SUB)

Returns a truth value indicating whether I<SUB> is expected to return an
lvalue.  An lvalue subroutine is usually created by using the C<:lvalue>
attribute, which affects how the subroutine body is compiled and also
sets the flag that this function extracts.

=item sub_is_constant(SUB)

Returns a truth value indicating whether I<SUB> returns a constant
value and can therefore be inlined.  It is possible for a subroutine
to actually be constant-valued without the compiler detecting it and
setting this flag.

=item sub_is_method(SUB)

Returns a truth value indicating whether I<SUB> is marked as a method.
This marker can be applied by use of the C<:method> attribute, and
(as of Perl 5.10) affects almost nothing.

=item mutate_sub_is_method(SUB, NEW_METHODNESS)

Marks or unmarks I<SUB> as a method, depending on the truth value of
I<NEW_METHODNESS>.

=item sub_is_debuggable(SUB)

Returns a truth value indicating whether, when the Perl debugger
is activated, calls to I<SUB> can be intercepted by C<DB::sub> (see
L<perldebguts>).  Normally this is true for all subroutines, but note
that whether a particular call is intercepted also depends on the nature
of the calling site.

=item mutate_sub_is_debuggable(SUB, NEW_DEBUGGABILITY)

Changes whether the Perl debugger will intercept calls to I<SUB>,
depending on the truth value of I<NEW_DEBUGGABILITY>.

=item sub_prototype(SUB)

Returns the prototype of I<SUB>, which is a string, or C<undef> if the
subroutine has no prototype.  (No prototype is different from the empty
string prototype.)  Prototypes affect the compilation of calls to the
subroutine, where the identity of the called subroutine can be resolved
at compile time.  (This is unrelated to the closure prototypes described
for L</sub_closure_role>.)

=item mutate_sub_prototype(SUB, NEW_PROTOTYPE)

Sets or deletes the prototype of I<SUB>, to match I<NEW_PROTOTYPE>,
which must be either a string or C<undef>.

=item sub_package(SUB)

Returns the name of the package within which I<SUB> is defined, or
C<undef> if there is none.  For a subroutine written in Perl, this
is normally the package that is selected in the lexical scope of the
subroutine definition.  For a subroutine written in C it is normally
not set.  Where set, this is not necessarily a package containing a name
by which the subroutine can be referenced.  It is also (for subroutines
written in Perl) not necessarily the selected package in any lexical
scope within the subroutine.  This association of each subroutine with
a package affects almost nothing: the main effect is that subroutines
in the C<DB> package are normally not subject to debugging, even when
flagged as debuggable (see L</sub_is_debuggable>).

=item mutate_sub_package(SUB, NEW_PACKAGE)

Sets or deletes the package of I<SUB>, to match I<NEW_PACKAGE>, which
must be either a string or C<undef>.

=back

=head1 SEE ALSO

L<B::CallChecker>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2009, 2010, 2011, 2013, 2015, 2017
Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

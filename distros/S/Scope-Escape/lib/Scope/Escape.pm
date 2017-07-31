=head1 NAME

Scope::Escape - reified escape continuations

=head1 SYNOPSIS

    use Scope::Escape qw(current_escape_function);

    $escape = current_escape_function;
    ...
    $escape->($result);

    use Scope::Escape::Continuation qw(current_escape_continuation);

    $escape = current_escape_continuation;
    ...
    $escape->go($result);

=head1 DESCRIPTION

This module provides a generalised facility for non-local control transfer
(jumping between stack frames), based on the well-thought-out semantics
of Common Lisp.  It provides operators that will capture and reify the
escape (return) continuation of the current stack frame.  The stack frame
can then be returned from, at (nearly) any time while it still exists,
via the reified continuation.  This applies not only to subroutine stack
frames, but also to intermediate frames for code blocks, and other kinds
of stack frame.  This facility can be used directly, or wrapped up to
build a more structured facility, as is done by L<Scope::Escape::Sugar>.

The system of reified escape continuations is fundamentally different
from Perl's native C<eval>/C<die> exception facility.  With C<die>,
the code initiating the non-local transfer has no control over where
it will go to.  Each C<eval> frame gets to decide whether it wants
to act as the target of the thrown exception, but it must make this
decision based almost entirely on what was recorded in the exception
object, because the stack frames between the C<die> and the C<eval>
have already been unwound by that time.  With reified continuations,
however, the code initiating the transfer determines where it will go to
(by choosing which continuation to use), and that decision can be made
with all information about the circumstances still available.

A reified escape continuation appears in Perl as a function object.
Calling the function results in returning from the stack frame that is the
target of the continuation.  Values passed to the function are returned
from the target stack frame.  Optionally, the continuation may be blessed
into the L<Scope::Escape::Continuation> class.  This class provides a
method-based interface to the continuation: transferring through the
continuation, and querying its state, can be performed by method calls
on the continuation object.  The methods can also be called directly,
as functions, on unblessed continuation functions.

=head1 CONTINUATION TARGETS

The operators supplied by this module generate continuations targeting
the "current scope".  It is not always obvious what that is.  Here are
the types of scope that occur in Perl and which can be escaped from by
means of the reified continuations supplied by this module:

=over

=item block

Any braced block of code is a scope.  Escaping from it jumps to the end
of the block.  If the block is in a context where it supplies a value,
then using the escape continuation supplies that value, as if it had been
the value of the last statement executed in the block.

In the case of the C<do> block syntax, the value returned from the block
is used directly in the surrounding expression.  Blocks in C<sort>,
C<map>, and C<grep> also supply a value.  Some other kinds of block
are mentioned specially below.  In most other cases a block is in void
context.

=item loop statement

In a loop statement, the loop body is a block, with its own scope.
The C<continue> block, if any, is likewise a separate block scope.  A loop
iteration is also a scope, and the test expression is evaluated within it,
so escaping from the test expression just skips to the next iteration.
None of these scopes return values.

=item subroutine

A subroutine call is a scope.  It corresponds to the block scope of
the body of the subroutine.  Escaping from that scope returns from the
subroutine.  Values may be returned, depending on the context of the call.

=item format

A call to a format, via C<write>, is a scope.  The main activity of
a format is to output formatted text.  Escaping early terminates the
outputting activity from the format, but page end processing still occurs
before C<write> returns.  No value is returned from the format.

=item substitution

The replacement part of a substitution (C<s///>) expression is evaluated
in its own scope.  The scope supplies the (scalar) substring to be
inserted in place of what was matched.

=item block eval

The block form of C<eval>, used to catch C<die> exceptions, provides
a scope, just like any other block.  However, when the block returns
normally, C<$@> is cleared to indicate that there was no exception.
C<eval> is a type of expression, so the block commonly supplies a value.

=item string eval

The string form of C<eval>, used to parse code at runtime, provides a
scope in which the parsed code executes.  In addition to parsing code
at runtime, this has the exception handling behaviour of block eval.
When the scope returns normally, C<$@> is cleared to indicate that there
was no exception.  C<eval> is a type of expression, so the scope commonly
supplies a value.

=item file

If a file is parsed and executed, by C<do> or C<require>, the entire
file is a scope.  Values may be returned, depending on the nature of
the calling site.

=back

These things are I<not> scopes:

=over

=item conditional statement

The test expression of a conditional statement executes in the scope
surrounding the conditional statement: there is no scope enclosing
just the conditional statement.  The blocks that execute conditionally,
however, are each a scope, as normal for a code block.

=item loop/conditional modifier

Statements involving postfix modifiers for looping or conditionals do
not introduce any additional scopes.  They are in this respect completely
unlike the loop and conditional statements where the keyword comes first.

=back

=head1 INACCESSIBLE STACK FRAMES

Using Perl's native control constructs, an C<eval> block (or one of
its several equivalents) sets a limit on how far a non-local control
transfer can travel.  Except when exiting the entire process, the only
way to non-locally transfer past the boundary of a single subroutine
call is C<die>.  An C<eval> block always stops the progress of a C<die>,
and gives the catching code a choice about whether to set the C<die>
going again through more stack frames.  Some parts of Perl rely on
the result of this: that with an C<eval> frame it is impossible for a
non-local control transfer to pass one by.

As a result of this, it is not possible, in the general case, to use an
escape continuation to cross over an C<eval> stack frame.  These frames
are effectively impervious to non-local returns.  This module currently
doesn't attempt to work around this limitation even in the cases where
it would have a fair chance of success.  When there is an C<eval> frame
between the current code and the target of an escape continuation, the
target is said to be "inaccessible".  The continuation remains valid when
this is the case, even though it will reject any attempt to actually
transfer through it.  Once the last intervening C<eval> frame has been
exited, the target becomes accessible again, and the continuation can
be used normally.  The details of this may change in the future, though
it is likely that there will always be some types of stack frame that
are impervious.

=head1 CONTINUATION VALIDITY

The continuations implemented by this module are not first-class.
That is, the existence of a continuation object does not keep its
target stack frame in existence.  A continuation has a limited period of
validity, based on the treatment of its target, and so if a continuation
object is retained long enough it will refer to a continuation that is no
longer valid.  Transfer through a continuation, and some other operations,
are not permitted when the continuation is invalid.  This implemenatation
cannot always reliably detect that a continuation has become invalid,
so the prohibited operations invoke undefined behaviour.

A continuation generally becomes invalid when its target stack frame is
unwound.  The simplest case of this is when the target block completes
normal execution and returns normally.  In that case, the continuation
becomes invalid as soon as the block has completed execution and unwinding
of the stack frame begins.

When a non-local control transfer occurs (such as C<return>, C<die>,
or use of an escape continuation from this module), continuations
referencing stack frames higher than the target become invalid.  They do
this as soon as the control transfer is initiated, before any of the stack
frames are actually unwound.  However, if the non-local control transfer
is the use of an escape continuation, that continuation itself remains
valid during unwinding, until its target is unwound at the completion of
the control transfer.  Thus cleanup code executed during unwinding can
itself perform non-local control transfers, provided that its target is
at least as low as the target of the current unwinding, except on some
Perl versions suffering from a core bug (see L</BUGS> below).

If multiple continuations appear to target the same stack frame, such
as the frame established by a subroutine call, they are always actually
nested in some particular order.  The earlier-established continuation
is always the outer one.  Effectively, the remainder of a block is
nested inside the complete block.  This corresponds to the way that
(both lexically and dynamically) things later in a block can shadow
things earlier in the block.

Nominally, local returns from stack frames don't have the complications of
non-local control transfers.  However, the way Perl performs them isn't
quite as local as it should be, in part because of the facility for a
block to set up several dynamic things in sequence.  In continuation
terminology, reaching the end of the block acts much like a non-local
return to where the block was invoked, during which all of the block's
cleanup code will run in sequence.  Continuations for those intermediate
scopes are all invalidated as soon as the interior of the block is
complete, rather than (as would be the case with a truly local return)
when the corresponding cleanup code runs.  Also, the target continuation
of a normal Perl return is invalidated when the return commences,
so it is not valid to attempt a normal Perl return to the same target
during unwinding.

=cut

package Scope::Escape;

{ use 5.008001; }
use warnings;
use strict;

use Devel::CallChecker 0.003 ();

our $VERSION = "0.005";

use parent "Exporter";
our @EXPORT_OK = qw(current_escape_function current_escape_continuation);

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

{
	package Scope::Escape::Continuation;
	our $VERSION = "0.005";
}

=head1 OPERATORS

These operators should be used through bareword function call syntax,
as if they were functions.  However, they cannot otherwise be called as
functions in the normal manner.  Attempting to take a reference to them
will result in a code reference that does not have any of the behaviour
described.

=over

=item current_escape_function

Reifies the current scope's escape continuation, returning it as a
reference to an unblessed function.  The function can be called through
this reference in order to return from the current scope.  The function
can also be manually passed to the L<Scope::Escape::Continuation> methods.

This operator is to be preferred if you want to treat the continuation
as a plain function.  If access to the L<Scope::Escape::Continuation>
methods is a priority, prefer L</current_escape_continuation>.

=item current_escape_continuation

Reifies the current scope's escape continuation, returning it as a
reference to a L<Scope::Escape::Continuation> object.  The methods of
that class can be called through it.  The object can also be called as
a function in order to return from the current scope (the action of the
L<go|Scope::Escape::Continuation/go> method).

This operator is to be preferred if you want to treat the continuation
as an opaque object and want to use the L<Scope::Escape::Continuation>
methods.  If you want to treat the continuation as a plain function,
prefer L</current_escape_function>.

=back

=head1 BUGS

Continuations can't currently be generated correctly in code embedded
in a regexp via C</(?{...})/>.

Perl versions 5.19.4 up to 5.21.11 suffer bug [perl #124156], which
prevents non-local control transfers initiated during unwinding from
working properly.  The problem mainly affects code that uses either C<die>
or an escape continuation from within a cleanup subroutine established
by L<Scope::Cleanup>.  It strikes when the cleanup executes as part of
unwinding for another non-local control transfer.  The effect is usually
that the Perl process crashes.  There is no way for this module to work
around the problem; this kind of convoluted control transfer just can't
be used on those Perl versions.  Perl 5.22.0 fixed the bug.

=head1 SEE ALSO

L<Scope::Cleanup>,
L<Scope::Escape::Continuation>,
L<Scope::Escape::Sugar>,
L<Scope::Upper>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2010, 2011, 2017 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

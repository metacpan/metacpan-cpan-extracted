=head1 NAME

Scope::Cleanup - reliably run code upon exit of dynamic scope

=head1 SYNOPSIS

	use Scope::Cleanup qw(establish_cleanup);

	establish_cleanup sub { ... };
	establish_cleanup \&do_cleanup;
	establish_cleanup $cleanup_code_ref;

=head1 DESCRIPTION

This module provides a facility for automatically running cleanup code
when exiting a dynamic scope.  The cleanup code is attached to the stack
frame directly, rather than being attached to an object that must then
be managed separately.  The cleanup code reliably runs when the stack
frame unwinds, regardless of the reason for unwinding: it may be a normal
return, exception throwing, program exit, or any kind of non-local return.

Cleanup code established through this module has direct access to Perl's
dynamic state.  It can do things such as C<die> to change the course of
execution outside the cleanup.

=head1 STACK UNWINDING

While returning (locally or non-locally) to an outer stack frame,
things must be done automatically at each stage, depending on the
circumstances in which the stack frames were created.  Variables that
were given dynamically-local values (with C<local>) are restored to
their previous values.  Objects used by the stack frames, that are
not referenced elsewhere, are destroyed.  These things happen in the
reverse of the order in which their stack frames were established.
This is referred to as "unwinding the stack".

It is sometimes desired to establish some code that will be automatically
executed during unwinding, for example to release resources that are not
reified as objects.  A common way of doing this in Perl, implemented
in the L<End> module, is to create a blessed object whose C<DESTROY>
method will perform the desired action, and hold a reference to it in
a lexical variable.  If the object is not otherwise touched, then upon
unwinding its destructor will fire.  This isn't really a clean approach
for arbitrary cleanup code, which is more concerned with its specific
stack frame than with a specific object.  This module provides a better
way to run arbitrary cleanup code, registering code directly to run
during unwinding, without any intermediation.

An object destructor is run inside an implicit C<eval> block.  This
prevents it from making any non-local control transfer outside the
confines of the destructor.  This is an appropriate limitation to put
on object destructors, but is not so appropriate for code associated
with a specific stack frame.  Code run directly is not so wrapped, and
is free to make non-local control transfers.  However, when the stack
unwinding is due to one of Perl's native mechanisms, critical parts of
the stack can be seen in an inconsistent state, which interferes with some
non-local transfers that ought to be valid.  This is because Perl doesn't
expect arbitrary code to run without an C<eval> block during unwinding.
The unwinding performed by L<Scope::Escape>'s non-local control transfers
is better behaved.

=head1 VULNERABLE STATE VARIABLES

Cleanup code must be especially careful about certain global state
variables.  The five variables C<$.>, C<$@>, C<$!>, C<$^E>, and C<$?>
are all set as a side effect by relevant operations, indicating part of
the result of that operation.  They are expected to be examined by code
run subsequently, before the next operation relevant to the variable
overwrites it.  (For C<$.> the value itself does not behave like this,
because that is actually part of an I/O handle's persistent state.
However, the choice of which I/O handle the variable looks at is such
temporary status.)

If some code that incidentally overwrites one of the status variables
is somehow executed between a relevant operation and the code that
expected to read the variable, then the wrong value will be read.
The most serious type of problem occurs with C<eval> setting C<$@>,
where reading the correct value from C<$@> is almost always critical to
the next bit of program logic.  Also, prior to Perl 5.13.1, C<die> is
much more vulnerable to having the variable clobbered than are operations
involving the other variables.  When C<die>ing on an older Perl, C<$@>
gets set first, then the stack unwinds to the eval frame, and only
then does C<eval> complete.  So there is a large window of opportunity
during unwinding for C<$@> to lose the exception that is being thrown.
From Perl 5.13.1 onwards that particular vulnerability has been fixed,
but C<$@> can still potentially be clobbered after C<eval> completes.

There are three main ways that lexically remote code could get run
unexpectedly: signal handlers, object destructors, and scope cleanup code.
Signal handlers can be run at essentially any time.  Not knowing what
code they might be interrupting, it is vital that they avoid changing
any of the status variables.  It must also be careful not to C<die>
or otherwise exit non-locally.  (Though it can validly use exceptions
internally.)  Object destructors are a bit more predictable, and in fact
predictable destruction time is often used as a hack to achieve a scope
cleanup effect, but basically destructors can run at nearly any time.
Destructors should also, therefore, always avoid changing any of the
status variables.

Scope cleanup code is in a different position.  Because it is guaranteed
to run when a particular scope exits, the code around that scope may be
expecting the effects of the cleanup code.  That might include performing
operations that set status variables, for code running just outside the
scope to read.  It is permitted to do this sort of thing, but liable to
be confusing, so it is recommended that you not pass information out of
cleanup code in this way.  (You should read the status variable inside the
cleanup code, and put the result in an ordinary well-behaved variable.)
Cleanup code might also intentionally C<die> or perform another kind of
non-local control transfer.

Where automatically-run code does not intend to set the global status
variables for other code to read, it should consistently localise them,
with "C<local($., $@, $!, $^E, $?);>".  This should be done as early as
possible in the signal handler, destructor, or cleanup function.

If a scope cleanup function intends to exit by C<die>, there is a
complication.  Prior to Perl 5.13.1, localising C<$@> prevents the C<die>
from working normally: the restoration of the previous value will itself
clobber C<$@> for the purposes of that C<die>.  (This is due to C<$@>
being set early in the C<die>, as described above.)  In this case, the
cleanup function must not localise C<$@>, and must make other arrangements
to avoid clobbering C<$@> in the event that it does not exit by C<die>.

There is ongoing discussion about changing some of the Perl core's
semantics, to make the above more tractable.  The changes to C<$@>
behaviour in Perl 5.13.1 were a result of these concerns, and further
change is likely.

=cut

package Scope::Cleanup;

{ use 5.008001; }
use warnings;
use strict;

use Devel::CallChecker 0.003 ();

our $VERSION = "0.002";

use parent "Exporter";
our @EXPORT_OK = qw(establish_cleanup);

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

=head1 OPERATORS

These operators should be used through bareword function call syntax,
as if they were functions.  However, they cannot otherwise be called as
functions in the normal manner.  Attempting to take a reference to them
will result in a code reference that does not have any of the behaviour
described.

=over

=item establish_cleanup(CLEANUP_CODE)

I<CLEANUP_CODE> must be a reference to a subroutine.  A cleanup handler
is established, such that the referenced subroutine will be called during
unwinding of the current stack frame.

=back

=head1 SEE ALSO

L<Scope::Escape>,
L<Scope::Upper>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2010, 2012 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
